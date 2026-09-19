/* ------------------------------------------------------------------------------------------------
 *                            RESERVATION STATION FOR LOAD-STORE UNIT
 * ------------------------------------------------------------------------------------------------
 *
 *  Functions / Behavior
 *  <TODO>
 *  Inputs
 *  ->  clk, reset_n & flush
 *  ->  rs_req_i — Allocation bus carrying the incoming RS entry.
 *  ->  sc_data_bus_i — Scalar common data bus snoop port.
 *  ->  vc_data_bus_i — Vector common data bus snoop port.
 *  ->  lsu_rdy_i — Handshake from LSU indicating LSU can accept a new instruction.
 *
 *  Outputs
 *  ->  ls_read_req_o — Scalar LSU read request driven to PRF
 *  ->  vc_lsu_rd_req_o — Vector LSU read request driven to PRF
 *  ->  ld_released_o — Pulse to instruction queue indicating a load left the RS
 *  ->  st_released_o — Pulse to instruction queue indicating a store left the RS 
 *
 *  Notes
 *  ->  Priority order when load and store is ready to dispatch -> if(load or store is full), the
 *      buffer that is full gets dispatched. else load gets priority over store
 *  <TODO>
 * ------------------------------------------------------------------------------------------------
 */

module rs_load_store (
    input clk_i,
    input reset_ni,
    input flush_i,

    //  RS <- ARR connection
    if_alloc_bus.rs rs_req_i,

    //  RS <- WB connection
    if_data_bus.snoop sc_data_bus_i,
    if_data_bus.snoop vc_data_bus_i,
    
    //  RS -> PRF connection
    output packet_pkg::read_request_t ls_read_req_o,
    output signal_pkg::prf_tag_t vc_lsu_rd_req_o,

    //  RS <- LSU ready connection for backpressure
    input  logic sc_lsu_rdy_i,
    input  logic vc_lsu_rdy_i,

    // RS -> Instruction Queue connection for credit return
    output logic ld_released_o,
    output logic st_released_o

);

    //  -------------------------------------------------------------------------------------------
    //      Types & local params

    localparam int unsigned RS_LSU_LDQ_ADDR_W = $clog2(config_pkg::RS_LSU_LOAD_DEPTH);
    localparam int unsigned RS_LSU_STQ_ADDR_W = $clog2(config_pkg::RS_LSU_STORE_DEPTH);

    typedef struct packed {
        logic epoch;
        logic[RS_LSU_STQ_ADDR_W-1:0] addr;
    } lsu_rs_store_q_addr_t;

    typedef logic[RS_LSU_LDQ_ADDR_W-1:0] lsu_rs_load_addr_t;


    //  -------------------------------------------------------------------------------------------
    //      Helper Function
    
    function automatic logic tag_match( // CDB snoop
        input logic rs_is_vec, input signal_pkg::prf_tag_t rs_tag ,
        input logic sc_cdb_valid, input signal_pkg::prf_tag_t sc_cdb_tag,
        input logic vc_cdb_valid, input signal_pkg::prf_tag_t vc_cdb_tag
    );
        if(rs_is_vec) tag_match = vc_cdb_valid && (rs_tag == vc_cdb_tag);
        else tag_match = sc_cdb_valid && (rs_tag == sc_cdb_tag);

    endfunction

    function automatic lsu_rs_load_addr_t oneHot_to_binary(
        input logic [config_pkg::RS_LSU_LOAD_DEPTH-1:0] addr_oh
    );
        lsu_rs_load_addr_t addr;
        addr = '0;
        for(int i=0; i<config_pkg::RS_LSU_LOAD_DEPTH; i++) begin
                if(addr_oh[i]) addr = i;
        end
        return addr;
    endfunction

    //  -------------------------------------------------------------------------------------------
    //      Input Output declaration

    logic in_valid, in_is_store, in_ready, lsu_ready;
    packet_pkg::rs_entry_t in_entry_d;
    
    assign lsu_ready = sc_lsu_rdy_i && vc_lsu_rdy_i;

    assign in_valid =   rs_req_i.valid
                    && (rs_req_i.chip_select == signal_pkg::CS_SLSU
                    ||  rs_req_i.chip_select == signal_pkg::CS_VLSU);

    assign in_is_store = rs_req_i.rs_entry.operation[3];

    always_comb begin
        in_entry_d = rs_req_i.rs_entry;
        in_entry_d.operand_a_ready = rs_req_i.rs_entry.operand_a_ready || tag_match (
                                    rs_req_i.rs_entry.a_is_vector, rs_req_i.rs_entry.operand_a_tag,
                                    sc_data_bus_i.valid, sc_data_bus_i.prf_tag,
                                    vc_data_bus_i.valid, vc_data_bus_i.prf_tag );
        in_entry_d.operand_b_ready = rs_req_i.rs_entry.operand_b_ready || tag_match (
                                    rs_req_i.rs_entry.b_is_vector, rs_req_i.rs_entry.operand_b_tag,
                                    sc_data_bus_i.valid, sc_data_bus_i.prf_tag,
                                    vc_data_bus_i.valid, vc_data_bus_i.prf_tag );
        in_ready = in_entry_d.operand_a_ready && in_entry_d.operand_b_ready;
    end

    //  -------------------------------------------------------------------------------------------
    //      Store queue

    packet_pkg::rs_entry_t store_queue [config_pkg::RS_LSU_STORE_DEPTH];
    
    lsu_rs_store_q_addr_t stq_head, stq_tail;
    logic st_eligible, store_q_empty, store_q_full;

    assign store_q_full  =  (stq_head.addr == stq_tail.addr) 
                        &&  (stq_head.epoch != stq_tail.epoch);

    assign store_q_empty =  (stq_head.addr == stq_tail.addr)
                        &&  (stq_head.epoch == stq_tail.epoch);

    assign st_eligible =  !store_q_empty
                        &&  store_queue [stq_head.addr].operand_a_ready
                        &&  store_queue [stq_head.addr].operand_b_ready;

    //  -------------------------------------------------------------------------------------------
    //      Load Buffer

    packet_pkg::rs_entry_t load_buf [config_pkg::RS_LSU_LOAD_DEPTH];
    lsu_rs_store_q_addr_t alloc_tail [config_pkg::RS_LSU_LOAD_DEPTH]; // tail when load was allocated
    logic [config_pkg::RS_LSU_LOAD_DEPTH-1:0] occupied, ld_eligible;
    logic [config_pkg::RS_LSU_LOAD_DEPTH-1:0] no_prev_store_q, no_prev_store_d;

    logic ld_buf_full, ld_buf_empty;

    assign ld_buf_full  = (occupied == '1);
    assign ld_buf_empty = (occupied == '0);

    always_comb begin
        for(int i=0; i<config_pkg::RS_LSU_LOAD_DEPTH; i++) begin
            ld_eligible[i] = occupied[i] && no_prev_store_q[i]
                            && load_buf[i].operand_a_ready && load_buf[i].operand_b_ready;
        end
    end

    //  -------------------------------------------------------------------------------------------
    //      Dispatch, allocate and bypass decisions

    logic eligible_bypass;  
    logic store_alloc, store_dispatch, store_bypass;
    logic load_alloc, load_dispatch, load_bypass;

    always_comb begin
        /*  Decisions to dispatch, allocate or bypass.
            Scenarios possible
            1) Load dispatched - a load is eligible and no prior store present
            2) Store dispatched - head of store is ready and no load dispatched
            3) Load bypassed - load input, store queue is empty and no loads eligible
            4) Store bypassed - store input, store queue is empty and no loads eligible
            5) Load Allocated - load input and not eligible to bypass
            6) Store Allocated - store input and not eligible to bypass
        */

        eligible_bypass = store_q_empty && !(|ld_eligible);

        load_bypass  = lsu_ready && in_valid && in_ready && !(in_is_store) && eligible_bypass;
        store_bypass = lsu_ready && in_valid && in_ready && in_is_store && eligible_bypass;

        store_dispatch = lsu_ready && st_eligible && (store_q_full || !(|ld_eligible));
        load_dispatch  = lsu_ready && (|ld_eligible) && !store_dispatch;
        
        load_alloc = in_valid && !in_is_store && !load_bypass;
        store_alloc = in_valid && in_is_store && !store_bypass;    
    end

    //  -------------------------------------------------------------------------------------------
    //      Load allocate and dispatch arbitration

    logic [config_pkg::RS_LSU_LOAD_DEPTH-1:0] rr_mask_q, rr_mask_d;
    logic [config_pkg::RS_LSU_LOAD_DEPTH-1:0] mask_upper, rr_upper, rr_lower, ld_winner;
    lsu_rs_load_addr_t load_dispatch_addr;
    logic [config_pkg::RS_LSU_LOAD_DEPTH-1:0] load_alloc_addr;

    always_comb begin
        // round robin arbitation

        mask_upper[0] = rr_mask_q[0];
        for(int i=1; i<config_pkg::RS_LSU_LOAD_DEPTH; i++) begin
            mask_upper[i] = mask_upper[i-1] | rr_mask_q[i];
        end

        rr_upper = ld_eligible & mask_upper;
        rr_lower = ld_eligible & ~mask_upper;

        ld_winner = (|rr_upper)
                  ? (rr_upper & (~rr_upper + 1'b1))
                  : (rr_lower & (~rr_lower + 1'b1));

        rr_mask_d = load_dispatch
                  ? { ld_winner[config_pkg::RS_LSU_LOAD_DEPTH-2:0],
                      ld_winner[config_pkg::RS_LSU_LOAD_DEPTH-1]}
                  : rr_mask_q;

    end

    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) rr_mask_q <= {{(config_pkg::RS_LSU_LOAD_DEPTH-1){1'b0}}, 1'b1};
        else rr_mask_q <= rr_mask_d;

    end

    always_comb load_dispatch_addr = oneHot_to_binary(ld_winner);
    always_comb load_alloc_addr = ~occupied & (occupied + 1'b1);
    
    //  -------------------------------------------------------------------------------------------
    //      CDB Snoop

    logic [config_pkg::RS_LSU_STORE_DEPTH-1:0] st_op_a_ready_d, st_op_b_ready_d;
    logic [config_pkg::RS_LSU_LOAD_DEPTH-1:0] ld_op_a_ready_d, ld_op_b_ready_d;

    always_comb begin
        // snoop for store queue entries
        for(int i=0; i<config_pkg::RS_LSU_STORE_DEPTH; i++) begin
            st_op_a_ready_d[i] = store_queue[i].occupied && (store_queue[i].operand_a_ready || 
                                tag_match ( store_queue[i].a_is_vector, store_queue[i].operand_a_tag,
                                            sc_data_bus_i.valid, sc_data_bus_i.prf_tag,
                                            vc_data_bus_i.valid, vc_data_bus_i.prf_tag ));
            st_op_b_ready_d[i] = store_queue[i].occupied && (store_queue[i].operand_b_ready ||
                                tag_match ( store_queue[i].b_is_vector, store_queue[i].operand_b_tag,
                                            sc_data_bus_i.valid, sc_data_bus_i.prf_tag,
                                            vc_data_bus_i.valid, vc_data_bus_i.prf_tag ));
        end
    end

    always_comb begin
        // snoop for load buffer entries
        for(int i=0; i<config_pkg::RS_LSU_LOAD_DEPTH; i++) begin
            ld_op_a_ready_d[i] = occupied[i] && (load_buf[i].operand_a_ready ||
                                tag_match ( load_buf[i].a_is_vector, load_buf[i].operand_a_tag,
                                            sc_data_bus_i.valid, sc_data_bus_i.prf_tag,
                                            vc_data_bus_i.valid, vc_data_bus_i.prf_tag ));
            ld_op_b_ready_d[i] = occupied[i] && (load_buf[i].operand_b_ready ||
                                tag_match ( load_buf[i].b_is_vector, load_buf[i].operand_b_tag,
                                            sc_data_bus_i.valid, sc_data_bus_i.prf_tag,
                                            vc_data_bus_i.valid, vc_data_bus_i.prf_tag ));

        end
    end

    //  -------------------------------------------------------------------------------------------
    //      Store queue - next state
    
    packet_pkg::rs_entry_t store_out;
    
    assign store_out = store_queue[stq_head.addr];
    
    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) begin
            stq_head <= '0;
            stq_tail <= '0;
            for(int i=0; i<config_pkg::RS_LSU_STORE_DEPTH; i++) begin
                store_queue[i].occupied <= '0;
                store_queue[i].operand_a_ready <= '0;
                store_queue[i].operand_b_ready <= '0;
            end
        end
        else begin
            // update snoop results
            for(int i=0; i<config_pkg::RS_LSU_STORE_DEPTH; i++) begin
                store_queue[i].operand_a_ready <= st_op_a_ready_d[i];
                store_queue[i].operand_b_ready <= st_op_b_ready_d[i];
            end
            if(store_dispatch) begin // pop_queue (read combinational)
                store_queue[stq_head.addr].occupied <= 1'b0;
                stq_head  <= stq_head + 1'b1;
            end

            if(store_alloc) begin // push_queue
                store_queue[stq_tail.addr] <= in_entry_d;
                store_queue[stq_tail.addr].occupied <= 1'b1;
                stq_tail <= stq_tail + 1'b1;
            end
        end
    end

    //  -------------------------------------------------------------------------------------------
    //      Load buffer - next state

    packet_pkg::rs_entry_t load_out;
    lsu_rs_store_q_addr_t stq_head_d;
    
    assign stq_head_d = store_dispatch ? stq_head + 1'b1 : stq_head;

    assign load_out = load_buf[load_dispatch_addr];

    always_comb begin
        // ensure there is no older store waiting to be dispatched
        for (int i=0; i<config_pkg::RS_LSU_LOAD_DEPTH; i++)
            no_prev_store_d[i] = occupied[i] ? no_prev_store_q[i] | (stq_head_d == alloc_tail[i]): 1'b0;

        for(int unsigned i=0; i<config_pkg::RS_LSU_LOAD_DEPTH; i++) begin
            if (load_alloc && load_alloc_addr[i]) 
                no_prev_store_d[i] = (stq_head_d == stq_tail);
        end

    end

    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) begin
            occupied <= '0;
            no_prev_store_q <= '0;
        end
        else begin
            // snoop
            for(int i=0; i<config_pkg::RS_LSU_LOAD_DEPTH; i++) begin
                load_buf[i].operand_a_ready <= ld_op_a_ready_d[i];
                load_buf[i].operand_b_ready <= ld_op_b_ready_d[i];
            end

            if(load_dispatch) begin // remove from buffer (read combinational)
                occupied[load_dispatch_addr] <= 1'b0;
            end

            for(int unsigned i=0; i<config_pkg::RS_LSU_LOAD_DEPTH; i++) begin
                if(load_alloc && load_alloc_addr[i]) begin // add to buffer
                    load_buf[i] <= in_entry_d;
                    alloc_tail[i] <= stq_tail;
                    occupied[i] <= 1'b1;
                end
            end

            no_prev_store_q <= no_prev_store_d;
        end
    end

    //  -------------------------------------------------------------------------------------------
    //      Output
    
    packet_pkg::rs_entry_t out_d, out_q;
    logic out_valid_d, out_valid_q;

    always_comb begin
        out_valid_d = (load_bypass || store_bypass || load_dispatch || store_dispatch);
        if(load_bypass || store_bypass) out_d = in_entry_d;
        else if(load_dispatch) out_d = load_out;
        else if(store_dispatch) out_d = store_out;
        else out_d = '0;
    end

    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) begin
            out_q <= '0;
            out_valid_q <= '0;
            ld_released_o <= 1'b0;
            st_released_o <= 1'b0;
        end
        else begin
            out_q <= out_d;
            out_valid_q <= out_valid_d;
            ld_released_o <= load_dispatch || load_bypass;
            st_released_o <= store_dispatch || store_bypass;
        end
    end

    assign ls_read_req_o = '{
        valid   : out_valid_q,
        prf_tag : out_q.prf_tag,
        rob_id  : out_q.rob_id,
        operation : out_q.operation,
        operand_a_tag : out_q.operand_a_tag,
        operand_b_tag : out_q.operand_b_tag,
        imm : out_q.imm,
        read_src2   : out_q.read_src2,
        a_is_vector : out_q.a_is_vector,
        b_is_vector : out_q.b_is_vector
    };
    
    assign vc_lsu_rd_req_o = out_q.operand_b_tag;

endmodule