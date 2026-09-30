/*
    Scope for improvement
    1) use set associative mapping
    2) evict buffer deeper than 1
    3) merge a store into a not-yet-accepted evict (true write combining)
 */

module data_l1_dcache (
    input clk_i,
    input reset_ni,
    input flush_i,

    // Dcache <-> LSU
    input packet_pkg::load_store_entry_t dcache_req_i,
    output logic dcache_rdy_o,

    // Dcache <-> Writeback
    output packet_pkg::sc_ex_result_t sc_wb_o,
    output packet_pkg::vc_ex_result_t vc_wb_o,

    // Dcache <-> AXI contoller - read channel
    output packet_pkg::mem_read_request_t mem_rd_req_o,
    input packet_pkg::mem_read_response_t mem_rd_res_i,
    input logic mem_rd_rdy_i,

    // Dcache <-> AXI contoller - write channel
    output packet_pkg::mem_write_request_t mem_wrt_req_o,
    input logic mem_wrt_done_i,
    input logic mem_wrt_rdy_i
    
);

    //  -------------------------------------------------------------------------------------------
    //      Localparams and typedefs

    localparam int unsigned DCACHE_BANKS_N = config_pkg::VECTOR_LEN;
    localparam int unsigned DATA_BYTES_N   = config_pkg::DATA_W/8; 

    localparam int unsigned BYTE_OFF_W = $clog2(DATA_BYTES_N);
    localparam int unsigned BANK_ID_W  = $clog2(DCACHE_BANKS_N);
    localparam int unsigned LINE_OFF_W = BANK_ID_W + BYTE_OFF_W;

    localparam int unsigned INDEX_W = $clog2(config_pkg::DCACHE_BANK_DEPTH);   
    localparam int unsigned TAG_W   = config_pkg::PHY_MEM_ADDR_W - INDEX_W - LINE_OFF_W;

    typedef logic [TAG_W-1:0] tag_t;
    typedef logic [INDEX_W-1:0] index_t;
    typedef logic [BANK_ID_W-1:0] bank_id_t;
    typedef logic [BYTE_OFF_W-1:0] byte_off_t;


    typedef enum logic[1:0] {
        IDLE,           // accepting; hits and both forward paths complete here
        SUBWORD_MERGE,   // subword store hit, old word on dout0, modify the bits and write back
        EVICT_CAPTURE,  // victim on dout0, load it into the evict register
        FILL_WAIT       // waiting on mem_rd_res_i
    } state_e;

    // data state, follows MESI format even tho coherence not supported
    // E means data present and clean, M means data present and dirty, S not reachable
    typedef enum logic[1:0] { CS_I = 2'b00, CS_S = 2'b01, CS_E = 2'b10, CS_M = 2'b11 } cache_state_e;

    // What cycle 0 does with the incoming request. Priority order below IS the
    // forward-before-anything-else rule — it lives here and nowhere else.
    typedef enum logic [2:0] {
        OP_NONE,
        OP_FWD_LOAD,      // load matches the in-flight evict line: bypass, NO allocate
        OP_FWD_STORE,     // scalar store matches it: merge + install, done in cycle 0
        OP_LOAD_HIT,
        OP_STORE_HIT,
        OP_SUBWORD_HIT,    // SB/SH - need to fetch word from SRAM, modify and write back
        OP_VSTORE_ALLOC,  // vector store miss, clean victim: full-line overwrite, no fill
        OP_MISS           // load miss, scalar store miss, dirty vector store miss
    } op_e;

    typedef enum logic [1:0] { BYTE = 2'b00, H_WORD = 2'b01, WORD = 2'b10, ERR = 2'b11 } op_size_e;

    typedef struct packed { cache_state_e state; tag_t tag; } dcache_metadata_t;

    typedef struct packed {
        logic valid; logic sent;
        tag_t tag; index_t index;
        signal_pkg::vector_data_t data;
    } evict_reg_t;

    typedef struct packed {
        logic is_store; logic is_vector; logic is_unsigned; op_size_e op_size;
        signal_pkg::prf_tag_t prf_tag;
        signal_pkg::rob_address_t rob_id;
        tag_t tag; index_t index;
        bank_id_t bank_id; byte_off_t byte_off;
        tag_t victim_tag;   // tag of the line this one evicts
        signal_pkg::vector_data_t data;
    } request_t;

    //  -------------------------------------------------------------------------------------------
    //      State storage

    state_e state_q, state_d;
    request_t req_q, req_d;
    evict_reg_t evict_reg_q, evict_reg_d;
    dcache_metadata_t meta_q [config_pkg::DCACHE_BANK_DEPTH-1:0]; 
    
    logic wb_valid_q, wb_valid_d;   // 1= load result on the writeback port this cycle
    logic wb_fwd_q, wb_fwd_d;       // 1 = source is evict buffer, not array
    logic wb_kill_q, wb_kill_d;     // flush squashed the in-flight miss's writeback
    logic read_sent_q, read_sent_d;

    //  -------------------------------------------------------------------------------------------
    //      Input decode

    tag_t in_tag;
    index_t in_index;
    dcache_metadata_t victim;
    request_t in_req;

    assign in_tag = dcache_req_i.mem_addr[config_pkg::PHY_MEM_ADDR_W-1 -: TAG_W];
    assign in_index = dcache_req_i.mem_addr[INDEX_W+LINE_OFF_W-1 -: INDEX_W];
    assign victim = meta_q[in_index];

    assign in_req = '{
        is_store  : dcache_req_i.is_store,
        is_vector : dcache_req_i.is_vector,
        is_unsigned : dcache_req_i.operation[2],
        op_size : op_size_e'(dcache_req_i.operation[1:0]),
        prf_tag : dcache_req_i.prf_tag,
        rob_id  : dcache_req_i.rob_id,
        tag : in_tag,
        index : in_index,
        bank_id  : dcache_req_i.mem_addr[BYTE_OFF_W +: BANK_ID_W],
        byte_off : dcache_req_i.mem_addr[0+:BYTE_OFF_W],
        victim_tag : victim.tag,
        data : dcache_req_i.data
    };

    //  -------------------------------------------------------------------------------------------
    //      Lookup - Metadata and evict buffer

    logic hit, needs_evict, needs_fill;
    logic evict_match, fwd_load, fwd_store;
    
    assign hit = (victim.state != CS_I) && (victim.tag == in_tag);
    assign needs_evict = !hit && (victim.state == CS_M);
    assign needs_fill = !hit && !(in_req.is_store && in_req.is_vector); // needs data from memory

    assign evict_match = evict_reg_q.valid && (evict_reg_q.tag == in_tag) && (evict_reg_q.index == in_index);
    assign fwd_load = evict_match && !hit && !in_req.is_store;
    // Note : store forward cannot happen if current cache line is dirty
    assign fwd_store = evict_match && !hit && in_req.is_store && !in_req.is_vector && !needs_evict;

    //  -------------------------------------------------------------------------------------------
    //      Request accept and classify

    logic accept;
    op_e in_op;

    assign dcache_rdy_o = (state_q == IDLE) && !(evict_reg_q.valid && needs_evict && !fwd_load);
    assign accept = dcache_req_i.valid && dcache_rdy_o;
    
    always_comb begin
        if (!accept) in_op = OP_NONE;
        else if (fwd_load) in_op = OP_FWD_LOAD;
        else if (fwd_store) in_op = OP_FWD_STORE;
        else if (hit && !in_req.is_store) in_op = OP_LOAD_HIT;
        else if (hit && (victim.state inside {CS_E, CS_M}))
            in_op = (!in_req.is_vector && (in_req.op_size != WORD)) ? OP_SUBWORD_HIT : OP_STORE_HIT;
        else if (in_req.is_store && in_req.is_vector && !needs_evict) in_op = OP_VSTORE_ALLOC;
        else in_op = OP_MISS;
        // hit && state == CS_S  ==  store to a SHARED line if coherence implemented in future
    end

    //  -------------------------------------------------------------------------------------------
    //      In-flight request tracking

    signal_pkg::vector_data_t  fill_line;
    logic capture_now, vstore_install, fill_now, miss_done;

    assign fill_line = mem_rd_res_i.data;
    assign capture_now = (state_q == EVICT_CAPTURE);
    assign vstore_install = capture_now && req_q.is_store && req_q.is_vector;
    assign fill_now = (state_q == FILL_WAIT) && read_sent_q && mem_rd_res_i.valid;
    assign miss_done = vstore_install || fill_now;

    //  -------------------------------------------------------------------------------------------
    //      State and request management

    always_comb begin
        // next state calculation
        unique case (state_q)
            IDLE: begin
                if(in_op == OP_SUBWORD_HIT) state_d = SUBWORD_MERGE;
                else if(in_op == OP_MISS) state_d = needs_evict ? EVICT_CAPTURE : FILL_WAIT;
                else state_d = state_q;
            end
            SUBWORD_MERGE: state_d = IDLE;
            EVICT_CAPTURE: state_d = vstore_install ? IDLE : FILL_WAIT;
            FILL_WAIT:  state_d = (fill_now) ? IDLE : state_q;
            default: state_d = state_q; 
        endcase
    end

    // update req_q in case in_op is valid
    assign req_d = (in_op != OP_NONE) ? in_req : req_q;

    always_ff @(posedge clk_i) begin
        if(!reset_ni) begin
            state_q <= IDLE;
            req_q <= '0;
        end
        else begin
            state_q <= state_d;
            req_q <= req_d;
        end
    end

    //  -------------------------------------------------------------------------------------------
    //      SRAM compilation and declaration

    logic sram_wrt_en;
    request_t sram_req;
    index_t sram_addr;
    logic [DCACHE_BANKS_N-1:0] sram_wrt_mask, sram_wrt_en_n;
    signal_pkg::vector_data_t sram_din_line, sram_dout_line;
    logic [32:0] sram_dout [DCACHE_BANKS_N-1:0];

    function automatic logic[DCACHE_BANKS_N-1:0] calc_mask(input logic is_vector,input bank_id_t bank_id);
        return is_vector ? '1 : (DCACHE_BANKS_N'(1) << bank_id);
    endfunction

    function automatic signal_pkg::vector_data_t update_store_line(
        input signal_pkg::vector_data_t line,
        input request_t r
    );
        signal_pkg::vector_data_t line_d;

        if(r.is_vector) line_d = r.data;
        else begin
            line_d = line;
            unique case(r.op_size)
                BYTE   : line_d[r.bank_id][(r.byte_off*8)+:8]  = r.data[0][7:0];
                H_WORD : line_d[r.bank_id][(r.byte_off[1]*16)+:16] = r.data[0][15:0];
                WORD   : line_d[r.bank_id] = r.data[0];
                default:;
            endcase
        end

        return line_d;
    endfunction

    always_comb begin
        sram_wrt_en = 1'b0;
        sram_req = in_req;
        sram_wrt_mask = '1;
        sram_din_line = '0;

        unique case (state_q)
            IDLE : begin
                unique case (in_op)
                    OP_FWD_STORE : begin
                        sram_wrt_en = 1'b1;
                        sram_din_line = update_store_line(evict_reg_q.data, in_req);
                    end
                    OP_STORE_HIT, OP_VSTORE_ALLOC : begin
                        sram_wrt_en = 1'b1;
                        sram_wrt_mask = calc_mask(in_req.is_vector, in_req.bank_id);
                        sram_din_line = update_store_line(0, in_req);
                    end
                    default :;
                endcase
            end
            SUBWORD_MERGE : begin
                sram_wrt_en = 1'b1;
                sram_req = req_q;
                sram_wrt_mask = calc_mask(req_q.is_vector, req_q.bank_id);
                sram_din_line = update_store_line(sram_dout_line, req_q);
            end
            EVICT_CAPTURE : begin
                if(vstore_install) begin
                    sram_wrt_en = 1'b1;
                    sram_req = req_q;
                    sram_din_line = update_store_line('0, req_q);
                end
            end
            FILL_WAIT :
                if(fill_now) begin
                    sram_wrt_en = 1'b1;
                    sram_req = req_q;
                    sram_din_line = update_store_line(fill_line, req_q);
                end
            default :;
        endcase
    end

    assign sram_wrt_en_n = sram_wrt_en ? ~sram_wrt_mask : '1;
    assign sram_addr = sram_wrt_en ? sram_req.index : in_index;

    genvar gi;
    generate
        for (gi = 0; gi < DCACHE_BANKS_N; gi++) begin : gen_sram_banks
            sky130_sram_1kbyte_1rw_32x256_32 u_dmem (
                .clk0 (clk_i),
                .csb0 (1'b0),
                .web0 (sram_wrt_en_n[gi]),
                .spare_wen0 (1'b0),
                .addr0 ({1'b0, sram_addr}),
                .din0 ({1'b0, sram_din_line[gi]}),
                .dout0 (sram_dout[gi])
            );

            assign sram_dout_line[gi] = sram_dout[gi][31:0];
        end
    endgenerate

    //  -------------------------------------------------------------------------------------------
    //      Update cache metadata

    always_ff @(posedge clk_i) begin
        if(!reset_ni) begin
            for(int unsigned i=0; i<config_pkg::DCACHE_BANK_DEPTH; i++)
                meta_q[i].state <= CS_I;
        end
        else if(sram_wrt_en) begin
            meta_q[sram_req.index] <= '{state:sram_req.is_store? CS_M : CS_E, tag: sram_req.tag};
        end
    end

    //  -------------------------------------------------------------------------------------------
    //      Memory read port (fill request)

    function automatic signal_pkg::mem_address_t line_addr (input tag_t tag, input index_t index);
        return {tag, index, {LINE_OFF_W{1'b0}}};
    endfunction
    
    logic rd_issue;

    always_comb begin
        rd_issue = ((state_q == IDLE) && (in_op == OP_MISS) && needs_fill)
                || (!read_sent_q && ((capture_now && !vstore_install) || (state_q == FILL_WAIT)));

        mem_rd_req_o.valid = rd_issue;
        mem_rd_req_o.addr  = (state_q == IDLE) ? line_addr(in_tag, in_index)
                                               : line_addr(req_q.tag, req_q.index);

        if (miss_done) read_sent_d = 1'b0;
        else if (rd_issue) read_sent_d = mem_rd_rdy_i;
        else  read_sent_d = read_sent_q;
    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni) read_sent_q <= 1'b0;
        else read_sent_q <= read_sent_d;
    end

    //  -------------------------------------------------------------------------------------------
    //      Evict register & memory write port

    always_comb begin
        evict_reg_d = evict_reg_q;

        mem_wrt_req_o.valid = evict_reg_q.valid && !evict_reg_q.sent;
        mem_wrt_req_o.addr  = line_addr(evict_reg_q.tag, evict_reg_q.index);
        mem_wrt_req_o.data  = evict_reg_q.data;

        if (mem_wrt_req_o.valid && mem_wrt_rdy_i) evict_reg_d.sent = 1'b1;

        if (mem_wrt_done_i) begin
            evict_reg_d.valid = 1'b0;
            evict_reg_d.sent  = 1'b0;
        end

        if (capture_now) begin // capture wins over a same-cycle ack
            evict_reg_d = '{valid: 1'b1, sent: 1'b0, tag: req_q.victim_tag,
                            index: req_q.index, data: sram_dout_line};
        end
    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni) evict_reg_q <= '0;
        else evict_reg_q <= evict_reg_d;
    end

    //  -------------------------------------------------------------------------------------------
    //      Writeback

    function automatic signal_pkg::data_t compile_subword(
        input signal_pkg::vector_data_t dcache_line,
        input request_t req
    );

        signal_pkg::data_t w;

        logic [7:0] byte_sel;
        logic [15:0] hword_sel;

        w = dcache_line[req.bank_id];

        byte_sel = w[8*req.byte_off +: 8]; // byte from word slected by addr[1:0]
        hword_sel = w[16*req.byte_off[1] +: 16]; // halfword from word selected by addr[1]

        case ({req.is_unsigned, req.op_size})
            {1'b0, BYTE} :  return {{24{byte_sel[7]}}, byte_sel};
            {1'b0, H_WORD} :  return {{16{hword_sel[15]}}, hword_sel};
            {1'b1, BYTE}: return {24'b0, byte_sel};
            {1'b1, H_WORD}: return {16'b0, hword_sel};
            default: return w;
        endcase

    endfunction

    always_comb begin
        if (flush_i) begin
            wb_valid_d = 1'b0;
            wb_fwd_d   = 1'b0;
            wb_kill_d  = 1'b1;
        end
        else begin
            wb_valid_d = (in_op == OP_LOAD_HIT) || (in_op == OP_FWD_LOAD);
            wb_fwd_d   = (in_op == OP_FWD_LOAD);
            wb_kill_d  = (in_op != OP_NONE) ? 1'b0 : wb_kill_q;
        end
    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni) begin
            wb_valid_q <= 1'b0;
            wb_fwd_q   <= 1'b0;
            wb_kill_q  <= 1'b0;
        end
        else begin
            wb_valid_q <= wb_valid_d;
            wb_fwd_q   <= wb_fwd_d;
            wb_kill_q  <= wb_kill_d;
        end
    end

    signal_pkg::vector_data_t wb_line;
    logic wb_valid;

    // cycle-1 return (array / evict buffer) and fill return never coincide
    assign wb_line  = !wb_valid_q ? fill_line : (wb_fwd_q ? evict_reg_q.data : sram_dout_line);
    assign wb_valid = !flush_i && (wb_valid_q || (fill_now && !req_q.is_store && !wb_kill_q));

    always_comb begin
        sc_wb_o = '{valid : wb_valid && !req_q.is_vector,
                    prf_tag : req_q.prf_tag,
                    rob_id  : req_q.rob_id,
                    data : compile_subword(wb_line, req_q)};

        vc_wb_o = '{valid : wb_valid && req_q.is_vector,
                    prf_tag : req_q.prf_tag,
                    rob_id  : req_q.rob_id,
                    data : wb_line};
    end

endmodule : data_l1_dcache
