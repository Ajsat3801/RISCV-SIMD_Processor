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

    // Core side 
    input packet_pkg::load_store_entry_t lsu_output_i,
    output logic l1_dcache_ready_o,
    output packet_pkg::sc_ex_result_t sc_wb_o,
    output packet_pkg::vc_ex_result_t vc_wb_o,

    // connection to AXI contoller - read channel
    output packet_pkg::mem_read_request_t mem_read_request_o,
    input logic mem_read_request_ready_i,
    input packet_pkg::mem_read_response_t mem_read_response_i,

    // connection to AXI contoller - write channel
    output packet_pkg::mem_write_request_t mem_write_request_o,
    input logic mem_write_request_ready_i,
    input logic mem_write_done_i

);

    localparam int unsigned DCACHE_BANKS_N = config_pkg::VECTOR_LEN; 

    localparam int unsigned INDEX_W    = $clog2(config_pkg::DCACHE_BANK_DEPTH);
    localparam int unsigned BANK_ID_W  = $clog2(DCACHE_BANKS_N);
    localparam int unsigned LINE_OFF_W = BANK_ID_W;
    localparam int unsigned TAG_W      = config_pkg::PHY_MEM_ADDR_W - INDEX_W - LINE_OFF_W;

    typedef logic [TAG_W-1:0] tag_t;
    typedef logic [INDEX_W-1:0] index_t;
    typedef logic [BANK_ID_W-1:0] bank_id_t;

    typedef enum logic[1:0] {
        IDLE,           // accepting; hits and both forward paths complete here
        EVICT_CAPTURE,  // victim on dout0, load it into the evict register
        FILL_WAIT       // waiting on mem_read_response_i
    } state_e;

    // What cycle 0 does with the incoming request. Priority order below IS the
    // forward-before-anything-else rule — it lives here and nowhere else.
    typedef enum logic [2:0] {
        OP_NONE,
        OP_FWD_LOAD,      // load matches the in-flight evict line: bypass, NO allocate
        OP_FWD_STORE,     // scalar store matches it: merge + install, done in cycle 0
        OP_LOAD_HIT,
        OP_STORE_HIT,
        OP_VSTORE_ALLOC,  // vector store miss, clean victim: full-line overwrite, no fill
        OP_MISS           // load miss, scalar store miss, dirty vector store miss
    } op_e;

    typedef struct packed {
        logic valid;
        logic dirty;
        tag_t tag;
    } dcache_metadata_t;

    typedef struct packed {
        logic valid;
        logic sent;
        tag_t tag;
        index_t index;
        signal_pkg::vector_data_t data;
    } evict_reg_t;

    typedef struct packed {
        logic is_store;
        logic is_vector;
        signal_pkg::prf_tag_t prf_tag;
        signal_pkg::rob_address_t rob_id;
        tag_t tag;
        index_t index;
        bank_id_t bank_id;
        tag_t victim_tag;   // tag of the line this one evicts
        signal_pkg::vector_data_t data;
    } req_ctx_t;

    // --------------------------------------------------------------------------------------------

    dcache_metadata_t meta_q [config_pkg::DCACHE_BANK_DEPTH-1:0]; 
    dcache_metadata_t meta_d;
    
    state_e state_q, state_d;
    
    logic meta_we;
    index_t meta_index;
    
    logic[DCACHE_BANKS_N-1:0] sram_we_n;
    index_t sram_addr;

    signal_pkg::vector_data_t sram_din_line;
    logic[32:0] sram_dout[DCACHE_BANKS_N-1:0];
    
    logic wb_valid_q, wb_valid_d;   // a load result is due on the writeback port this cycle
    logic wb_fwd_q,   wb_fwd_d;     // ...and its source is the evict buffer, not the array
    logic wb_kill_q,  wb_kill_d;    // flush squashed the in-flight miss's writeback
    logic read_sent_q, read_sent_d;

    logic evict_cap_req;
    signal_pkg::vector_data_t evict_cap_data;

    // address decoding and store

    req_ctx_t req_q, req_d;

    tag_t in_tag;
    index_t in_index;
    bank_id_t in_bank_id;
    signal_pkg::mem_address_t in_line_addr, cur_line_addr;

    assign in_tag = lsu_output_i.mem_addr[config_pkg::PHY_MEM_ADDR_W-1 -: TAG_W];
    assign in_index = lsu_output_i.mem_addr[INDEX_W+LINE_OFF_W-1 -: INDEX_W];
    assign in_bank_id  = lsu_output_i.mem_addr[LINE_OFF_W-1 -: BANK_ID_W];

    assign in_line_addr = {in_tag, in_index, {LINE_OFF_W{1'b0}}};
    assign cur_line_addr = {req_q.tag, req_q.index, {LINE_OFF_W{1'b0}}};

    // lookup metadata

    dcache_metadata_t victim;
    assign victim = meta_q[in_index];

    logic hit, needs_evict, needs_fill;
    assign hit = victim.valid && (victim.tag == in_tag);
    assign needs_evict = !hit && victim.valid && victim.dirty;
    assign needs_fill = !hit && !(lsu_output_i.is_store && lsu_output_i.is_vector); // needs data from memory
    
    // lookup evict buffer
    
    evict_reg_t evict_reg_q, evict_reg_d;
    logic evict_match, fwd_load, fwd_store;

    assign evict_match = evict_reg_q.valid && (evict_reg_q.tag   == in_tag) && (evict_reg_q.index == in_index);
    assign fwd_load = evict_match && !hit && !lsu_output_i.is_store;
    // Note : store forward cannot happen if current cache line is dirty
    assign fwd_store = evict_match && !hit && lsu_output_i.is_store && !lsu_output_i.is_vector && !needs_evict;

    // admission gate

    logic accept;
    assign l1_dcache_ready_o = (state_q == IDLE)
                            && !(evict_reg_q.valid && needs_evict && !fwd_load);
    assign accept = lsu_output_i.valid && l1_dcache_ready_o;

    op_e in_op;
    always_comb begin
        if (!accept) in_op = OP_NONE;
        else if (fwd_load) in_op = OP_FWD_LOAD;
        else if (fwd_store) in_op = OP_FWD_STORE;
        else if (hit && !lsu_output_i.is_store) in_op = OP_LOAD_HIT;
        else if (hit) in_op = OP_STORE_HIT;
        else if (lsu_output_i.is_store && lsu_output_i.is_vector && !needs_evict) in_op = OP_VSTORE_ALLOC;
        else in_op = OP_MISS;
    end

    // SRAM inout

    signal_pkg::vector_data_t sram_line, fill_line, wb_line;
    logic resp_here, fill_now;

    genvar gi;
    generate
        for (gi = 0; gi < DCACHE_BANKS_N; gi++) begin : gen_line
            assign sram_line[gi] = sram_dout[gi][31:0];
        end
    endgenerate

    // cycle-1 writeback source: the array, or the evict buffer on a forward
    assign wb_line    = wb_fwd_q ? evict_reg_q.data : sram_line;

    assign resp_here  = read_sent_q && mem_read_response_i.valid;
    assign fill_line  = mem_read_response_i.data;
    assign fill_now   = (state_q == FILL_WAIT) && resp_here;
        
    // helper functions

    function automatic signal_pkg::data_t select_word (
        input signal_pkg::vector_data_t line, input bank_id_t bank
    );
        select_word = line[bank];
    endfunction

    function automatic signal_pkg::vector_data_t merge_word (
        input signal_pkg::vector_data_t line, input bank_id_t bank,
        input signal_pkg::data_t word
    );
        signal_pkg::vector_data_t o;
        o = line;
        o[bank] = word;
        return o;
    endfunction

    // action tasks

    // ---- SRAM port (web0 active low) ----------------------------------------
    task automatic drive_sram_read (
        input index_t addr
    );
        sram_addr = addr;
        sram_we_n = '1;
    endtask

    task automatic drive_sram_write_line (
        input index_t addr,
        input signal_pkg::vector_data_t line
    );
        sram_addr = addr;
        sram_we_n = '0;
        sram_din_line = line;
    endtask

    task automatic drive_sram_write_word (
        input index_t addr,
        input bank_id_t bank,
        input signal_pkg::data_t word
    );
        sram_addr = addr;
        sram_we_n = ~(DCACHE_BANKS_N'(1) << bank);
        // broadcast; only the unmasked bank commits
        for (int unsigned i = 0; i < DCACHE_BANKS_N; i++) sram_din_line[i] = word;
    endtask

    // ---- memory read channel -------------------------------------------------
    task automatic drive_mem_read (
        input signal_pkg::mem_address_t line_addr
    );
        mem_read_request_o.valid = 1'b1;
        mem_read_request_o.addr  = line_addr;
        read_sent_d = mem_read_request_ready_i;
    endtask

    // ---- memory write channel ------------------------------------------------
    task automatic request_evict_capture (
        input signal_pkg::vector_data_t line
    );
        evict_cap_req = 1'b1;
        evict_cap_data = line;
    endtask
    
    // ---- metadata ------------------------------------------------------------
    task automatic sched_metadata (
        input index_t index,
        input tag_t tag,
        input logic valid,
        input logic dirty
    );
        meta_we = 1'b1;
        meta_index = index;
        meta_d = '{valid: valid, dirty: dirty, tag: tag};
    endtask

    // ---- writeback -----------------------------------------------------------
    task automatic drive_sc_writeback (
        input req_ctx_t r,
        input signal_pkg::data_t word
    );
        sc_wb_o.valid   = 1'b1;
        sc_wb_o.prf_tag = r.prf_tag;
        sc_wb_o.rob_id  = r.rob_id;
        sc_wb_o.data    = word;
    endtask

    task automatic drive_vc_writeback (
        input req_ctx_t r,
        input signal_pkg::vector_data_t line
    );
        vc_wb_o.valid   = 1'b1;
        vc_wb_o.prf_tag = r.prf_tag;
        vc_wb_o.rob_id  = r.rob_id;
        vc_wb_o.data    = line;
    endtask

    // ---- FSM bookkeeping -----------------------------------------------------
    task automatic sched_accept ();
        req_d = '{ is_store: lsu_output_i.is_store,
                   is_vector: lsu_output_i.is_vector,
                   prf_tag: lsu_output_i.prf_tag,
                   rob_id: lsu_output_i.rob_id,
                   tag: in_tag,
                   index: in_index,
                   bank_id: in_bank_id,
                   victim_tag: victim.tag,
                   data: lsu_output_i.data };
        wb_kill_d = 1'b0;
    endtask

    task automatic sched_writeback (
        input logic from_evict_reg
    );
        wb_valid_d = 1'b1;
        wb_fwd_d   = from_evict_reg;
    endtask

    task automatic sched_complete ();
        read_sent_d = 1'b0;
    endtask

    // generate SRAM
    generate
        for (gi = 0; gi < DCACHE_BANKS_N; gi++) begin : gen_sram_banks
            sky130_sram_1kbyte_1rw_32x256_32 u_dmem (
                .clk0       (clk_i),
                .csb0       (1'b0),
                .web0       (sram_we_n[gi]),
                .spare_wen0 (1'b0),
                .addr0      ({1'b0, sram_addr}),
                .din0       ({1'b0, sram_din_line[gi]}),
                .dout0      (sram_dout[gi])
            );
        end
    endgenerate

    // FSM

        always_comb begin
        // ---------------- defaults: every owned signal, before any task runs
        state_d     = state_q;
        req_d       = req_q;
        wb_valid_d  = 1'b0;
        wb_fwd_d    = 1'b0;
        wb_kill_d   = wb_kill_q;
        read_sent_d = read_sent_q;

        evict_cap_req  = 1'b0;
        evict_cap_data = '0;

        meta_we    = 1'b0;
        meta_index = in_index;
        meta_d     = '{valid: 1'b1, dirty: 1'b0, tag: in_tag};

        sram_addr     = in_index;
        sram_we_n     = '1;
        sram_din_line = '0;

        mem_read_request_o = '0;

        unique case (state_q)

        IDLE: begin
            if (in_op != OP_NONE) sched_accept();

            unique case (in_op)
                
                OP_FWD_LOAD: sched_writeback(1'b1);

                OP_FWD_STORE: begin
                    drive_sram_write_line(in_index,
                        merge_word(evict_reg_q.data, in_bank_id,
                                   select_word(lsu_output_i.data, in_bank_id)));
                    sched_metadata(in_index, in_tag, 1'b1, 1'b1);
                end

                OP_LOAD_HIT: begin
                    drive_sram_read(in_index);
                    sched_writeback(1'b0);
                end

                OP_STORE_HIT: begin
                    if (lsu_output_i.is_vector) drive_sram_write_line(in_index, lsu_output_i.data);
                    else drive_sram_write_word(in_index, in_bank_id,
                                              select_word(lsu_output_i.data, in_bank_id));
                    sched_metadata(in_index, in_tag, 1'b1, 1'b1);
                        
                end
                OP_VSTORE_ALLOC: begin
                    drive_sram_write_line(in_index, lsu_output_i.data);
                    sched_metadata(in_index, in_tag, 1'b1, 1'b1);
                end

                OP_MISS: begin
                    if (needs_evict) drive_sram_read(in_index);   // victim line
                    if (needs_fill)  drive_mem_read(in_line_addr);
                    state_d = needs_evict ? EVICT_CAPTURE : FILL_WAIT;
                end

                default: ;   // OP_NONE
            endcase
        end


        EVICT_CAPTURE: begin
            request_evict_capture(sram_line);

            if (req_q.is_store && req_q.is_vector) begin
                // dirty vector store miss: install the input line, done
                drive_sram_write_line(req_q.index, req_q.data);
                sched_metadata(req_q.index, req_q.tag, 1'b1, 1'b1);
                sched_complete();
                state_d = IDLE;
            end
            else begin
                state_d = FILL_WAIT;
                if (!read_sent_q) drive_mem_read(cur_line_addr);
            end
        end

        FILL_WAIT: begin

            if (!read_sent_q) drive_mem_read(cur_line_addr);

            if (fill_now) begin
                drive_sram_write_line(req_q.index,
                    req_q.is_store
                        ? merge_word(fill_line, req_q.bank_id,
                                     select_word(req_q.data, req_q.bank_id))
                        : fill_line);
                sched_metadata(req_q.index, req_q.tag, 1'b1, req_q.is_store);
                sched_complete();
                state_d = IDLE;
            end
        end

        endcase

        // ---------------- flush: pipeline squash only.
        // The fill and the evict must still complete -- dropping either loses data.
        if (flush_i) begin
            wb_valid_d = 1'b0;
            wb_fwd_d   = 1'b0;
            wb_kill_d  = 1'b1;
        end
    end

    // WRITEBACK -- independent of the FSM

    always_comb begin
        sc_wb_o = '0;
        vc_wb_o = '0;

        if (wb_valid_q && !flush_i) begin
            // cycle-1 return: load hit off the array, or an evict buffer forward
            if (req_q.is_vector) drive_vc_writeback(req_q, wb_line);
            else                 drive_sc_writeback(req_q, select_word(wb_line, req_q.bank_id));        
        end
        else if (fill_now && !req_q.is_store && !wb_kill_q && !flush_i) begin
            if (req_q.is_vector) drive_vc_writeback(req_q, fill_line);
            else                 drive_sc_writeback(req_q, select_word(fill_line, req_q.bank_id));
        end
    end

    // EVICT REGISTER + WRITE CHANNEL -- sole owner of evict_reg_d

    always_comb begin
        evict_reg_d = evict_reg_q;

        mem_write_request_o.valid = evict_reg_q.valid && !evict_reg_q.sent;
        mem_write_request_o.addr  = {evict_reg_q.tag, evict_reg_q.index, {LINE_OFF_W{1'b0}}};
        mem_write_request_o.data  = evict_reg_q.data;

        if (mem_write_request_o.valid && mem_write_request_ready_i) evict_reg_d.sent = 1'b1;

        if (mem_write_done_i) begin
            evict_reg_d.valid = 1'b0;
            evict_reg_d.sent  = 1'b0;
        end

        if (evict_cap_req) begin            // capture wins over a same-cycle ack
            evict_reg_d.valid = 1'b1;
            evict_reg_d.sent  = 1'b0;
            evict_reg_d.tag   = req_q.victim_tag;
            evict_reg_d.index = req_q.index;
            evict_reg_d.data  = evict_cap_data;
         end
     end

    always_ff @(posedge clk_i) begin
        if (!reset_ni) begin
            state_q     <= IDLE;
            req_q       <= '0;
            evict_reg_q <= '0;
            wb_valid_q  <= 1'b0;
            wb_fwd_q    <= 1'b0;
            wb_kill_q   <= 1'b0;
            read_sent_q <= 1'b0;

            for (int unsigned i = 0; i < config_pkg::DCACHE_BANK_DEPTH; i++) meta_q[i].valid <= 1'b0;
        end
        else begin
            state_q         <= state_d;
            req_q           <= req_d;
            evict_reg_q <= evict_reg_d;
            wb_valid_q  <= wb_valid_d;
            wb_fwd_q    <= wb_fwd_d;
            wb_kill_q   <= wb_kill_d;
            read_sent_q <= read_sent_d;

            if (meta_we) meta_q[meta_index] <= meta_d;
        end
    end

endmodule : data_l1_dcache
