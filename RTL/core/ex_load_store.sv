
module ex_load_store(
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    // LSU <- PRF connections
    input  packet_pkg::sc_ex_request_t sc_ex_req_i,
    input  signal_pkg::data_t sc_store_data_i,
    input  signal_pkg::vector_data_t vc_store_data_i,

    // LSU <-> ROB connections (for requesting/snooping store retires only)
    if_retirement_bus.lsu retire_instr_i,
    output packet_pkg::store_retire_request_t store_retire_req_o,

    // LSU <-> Dcache connections
    output packet_pkg::load_store_entry_t dcache_req_o,
    input logic dcache_rdy_i,

    // LSU <-> WB connections (for forwards only)
    output packet_pkg::sc_ex_result_t sc_fwd_res_o,
    output packet_pkg::vc_ex_result_t vc_fwd_res_o,

    /// LSU -> RS connections (for backpressure only)
    output logic sc_ex_rdy_o,
    output logic vc_ex_rdy_o
);

    //  -------------------------------------------------------------------------------------------
    //      Typedefs, localparms

    typedef logic[config_pkg::STORE_BUFFER_DEPTH-1:0] store_buf_onehot_t;
    typedef logic [$clog2(config_pkg::STORE_BUFFER_DEPTH)-1:0] store_buf_addr_t;
    typedef struct packed {
        logic epoch;
        store_buf_addr_t addr;
    } store_buf_ptr_t;

    localparam int unsigned WORD_OFFSET_W = $clog2(config_pkg::VECTOR_LEN);
    localparam int unsigned PAD_W = (config_pkg::VECTOR_LEN - 1)* config_pkg::DATA_W;

    //  -------------------------------------------------------------------------------------------
    //      compile input signals

    packet_pkg::load_store_entry_t in;
    logic in_is_load;

    function automatic logic is_vector(signal_pkg::operations_e op);
        // NOTE: this will not work if we start having other than 32 bit values in vector ops
        is_vector = (op[2:0] == 3'b110); 
    endfunction

    always_comb begin
        
        in.valid = sc_ex_req_i.valid && !flush_i;
        in.is_store = in.valid && sc_ex_req_i.operation[3];
        in.is_vector = in.valid && is_vector(sc_ex_req_i.operation);
        in.prf_tag = sc_ex_req_i.prf_tag;
        in.rob_id = sc_ex_req_i.rob_id;
        in.operation = sc_ex_req_i.operation;
        in.mem_addr = signal_pkg::mem_address_t'(sc_ex_req_i.operand_a + sc_ex_req_i.operand_b);
        in.data = (in.is_vector) ? vc_store_data_i : {{PAD_W{1'b0}}, sc_store_data_i};

    end

    assign in_is_load = in.valid && !in.is_store;

    //  -------------------------------------------------------------------------------------------
    //      ROB communications

    logic ret_epoch;

    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) ret_epoch <= 1'b0;
        else if(retire_instr_i.valid) ret_epoch <= retire_instr_i.rob_id.epoch;
    end

    assign store_retire_req_o = '{rob_id:sc_ex_req_i.rob_id, valid: in.is_store};

    //  -------------------------------------------------------------------------------------------
    //      Load holding register - declaration
    
    packet_pkg::load_store_entry_t ld_q, ld_d;
    logic ld_to_dcache, ld_fwd, ld_clear;

    always_comb begin

        ld_clear = (ld_to_dcache && dcache_rdy_i) || ld_fwd;

        // Note: load bypass not possible due to upstream logic, provision given here.
        if (in_is_load && (ld_clear || !ld_q.valid )) ld_d = in;
        else if (ld_clear) ld_d = '0;
        else ld_d = ld_q; 
    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni || flush_i) ld_q <= '0;
        else ld_q <= ld_d;
    end

    //  -------------------------------------------------------------------------------------------
    //      Store buffer - declaration & arbitration logic

    packet_pkg::load_store_entry_t store_buf[config_pkg::STORE_BUFFER_DEPTH];
    store_buf_onehot_t  store_rdy_q;
    logic st_to_dcache;

    function automatic logic ret_match (store_buf_addr_t i);
        ret_match = retire_instr_i.valid && (retire_instr_i.rob_id == store_buf[i].rob_id);
    endfunction

    //  -------------------------------------------------------------------------------------------
    //      Load forwarding - matching and arbitration

    function automatic signal_pkg::rob_address_t norm_epoch(signal_pkg::rob_address_t i);
        // normalizes the epoch of the address such that current epoch of ROB is 0, needed for 
        // comparing ages of instructions
        norm_epoch = {(i.epoch != ret_epoch), i.address}; 
    endfunction
    
    function automatic logic fwd_eligible(store_buf_addr_t i);
        
        fwd_eligible = store_buf[i].is_vector
                     || (!ld_q.is_vector && (store_buf[i].operation.lsu == signal_pkg::LSU_SW));
    endfunction

    function automatic logic match(store_buf_addr_t i);
        logic addr_match, match_sc, match_vc, match_older;

        match_sc = ld_q.mem_addr == store_buf[i].mem_addr;
        match_vc = (ld_q.mem_addr[config_pkg::PHY_MEM_ADDR_W-1:WORD_OFFSET_W]
                == store_buf[i].mem_addr[config_pkg::PHY_MEM_ADDR_W-1:WORD_OFFSET_W]);
        
        addr_match = (ld_q.is_vector || store_buf[i].is_vector) ? match_vc : match_sc;
        match_older = store_rdy_q[i] || norm_epoch(store_buf[i].rob_id) < norm_epoch(ld_q.rob_id);

        match = addr_match && match_older;
    endfunction

    store_buf_onehot_t match_addr; // stores the newest match older than the load irrespective of eligibility
    
    always_comb begin
        match_addr = '0;
        ld_fwd = 1'b0;

        for (int unsigned i=0; i<config_pkg::STORE_BUFFER_DEPTH; i++) begin
            store_buf_addr_t idx;
            idx = head.addr + store_buf_addr_t'(i);

            if (ld_q.valid && store_buf[idx].valid && match(idx)) begin
                match_addr = '0;
                match_addr[idx] = 1'b1;
                ld_fwd = fwd_eligible(idx);
            end
        end

        ld_to_dcache = ld_q.valid && !(|match_addr);

    end

    //  -------------------------------------------------------------------------------------------
    //      Store buffer - FIFO implementation 
    
    packet_pkg::load_store_entry_t store_out;
    store_buf_ptr_t head_nxt, head, tail_nxt, tail;
    store_buf_ptr_t commit, commit_nxt_ptr;
    logic full_nxt, commit_advance;

    assign head_nxt = head + 1'b1;
    assign tail_nxt = tail + 1'b1;

    assign full_nxt = (head.epoch != tail_nxt.epoch) && (head.addr == tail_nxt.addr);

    assign commit_advance = (commit != tail) && ret_match(commit.addr);
    assign commit_nxt_ptr = commit + 1'b1;
    
    assign store_out = store_buf[head.addr];

    always_ff @(posedge clk_i) begin
        if(!reset_ni) begin
            // store_rdy_q reset and flush logic here.
            for(int unsigned i=0; i<config_pkg::STORE_BUFFER_DEPTH; i++) store_buf[i].valid <= 1'b0;
            tail <= '0;
            head <= '0;
            store_rdy_q <= '0;
            commit <= '0;
        end
        else if(flush_i) begin
            for(int unsigned i=0; i<config_pkg::STORE_BUFFER_DEPTH; i++) 
                if(!store_rdy_q[i]) store_buf[i].valid <= 1'b0;
            tail <= commit;
            // head doesn't change
        end
        else begin
            
            if(commit_advance) begin
                store_rdy_q[commit.addr] <= 1'b1; // update ready state
                commit <= commit_nxt_ptr;
            end
            
            if(st_to_dcache && dcache_rdy_i) begin // dequeue
                store_buf[head.addr].valid <= 0;
                head <= head_nxt;
            end
            
            if(in.valid && in.is_store) begin // enqueue
                store_buf[tail.addr] <= in;
                store_rdy_q[tail.addr] <= 1'b0;
                tail <= tail_nxt;
            end
        end
    end

    assign st_to_dcache  = store_buf[head.addr].valid && store_rdy_q[head.addr] && !ld_to_dcache;

    //  -------------------------------------------------------------------------------------------
    //      Forward result

    signal_pkg::vector_data_t fwd_store_data;
    logic fwd_is_vector;
    logic [WORD_OFFSET_W-1:0] block_offset;

    assign block_offset = ld_q.mem_addr[WORD_OFFSET_W-1:0];

    always_comb begin
        fwd_store_data = '0;
        fwd_is_vector = 1'b0;
        for(int i=0; i<config_pkg::STORE_BUFFER_DEPTH; i++) begin
            if(ld_fwd && match_addr[i]) begin
                fwd_store_data = store_buf[i].data;
                fwd_is_vector  = store_buf[i].is_vector;
            end
        end
    end

    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) begin
            sc_fwd_res_o <= '0;
            vc_fwd_res_o <= '0;
        end
        else begin
            sc_fwd_res_o <= '{
                valid : ld_fwd && !ld_q.is_vector,
                prf_tag : ld_q.prf_tag,
                rob_id  : ld_q.rob_id,
                data  : signal_pkg::extract_subword(
                            fwd_store_data[fwd_is_vector ? block_offset : '0],
                            ld_q.mem_addr,
                            ld_q.operation
                        )
            };
            vc_fwd_res_o <= '{
                valid : ld_fwd && ld_q.is_vector,
                prf_tag : ld_q.prf_tag,
                rob_id  : ld_q.rob_id,
                data  : fwd_store_data
            };
        end
    end

    //  -------------------------------------------------------------------------------------------
    //      Outputs

    always_comb begin
        if(flush_i) dcache_req_o = '0;
        else begin
            if(ld_to_dcache) dcache_req_o = ld_q;
            else if(st_to_dcache) dcache_req_o = store_out;
            else dcache_req_o = '0;
        end
    end

    assign sc_ex_rdy_o = !ld_d.valid && (!full_nxt || (st_to_dcache && dcache_rdy_i));
    assign vc_ex_rdy_o = sc_ex_rdy_o;

endmodule