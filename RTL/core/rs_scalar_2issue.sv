/* ------------------------------------------------------------------------------------------------
 *                                   DUAL ISSUE RESERVATION STATION
 * ------------------------------------------------------------------------------------------------
 *
 * Functions/Behavior:
 * <TODO>
 *
 * Inputs:
 *  ->  clk, reset_n & flush
 *  ->  rs_request_i — Allocation bus carrying the incoming instruction entry
 *  ->  sc_data_bus_i — CDB snoop interface.
 *  ->  sc_ex_ready_i — Ready signal from downstream ex unit.
 *
 * Outputs:
 *  ->  sc_rd_req_o — Read request packet sent to the execution unit.
 *  ->  instr_dispatched_o — Signals whether RS slot was freed or not
 *
 * Notes:
 * <TODO>
 *
 * ------------------------------------------------------------------------------------------------
 */

module rs_scalar_2issue #(
    parameter signal_pkg::chip_select_e CHIP_SELECT = signal_pkg::CS_SALU,
    parameter int unsigned DEPTH = 16
)(
    input  logic clk_i,
    input  logic reset_ni,
    input  logic flush_i,
    
    //  RS <- ARR connection
    if_alloc_bus.rs rs_request_i,

    //  RS <- CDB connection
    if_data_bus.snoop sc_data_bus_i,

    //  RS <- EX connection for backpressure
    input  logic sc_ex0_ready_i,
    input  logic sc_ex1_ready_i,

    //  RS -> PRF connection for dispatched instruction
    output packet_pkg::read_request_t sc_rd_req0_o,
    output packet_pkg::read_request_t sc_rd_req1_o,

    //  RS -> Instruction queue for credit return
    output logic instr_dispatched_o [2]
);

    //  -------------------------------------------------------------------------------------------
    //      Types and localparams

    localparam int unsigned ADDR_W = $clog2(DEPTH);
    typedef logic [ADDR_W-1:0] rs_addr_t;

    //  -------------------------------------------------------------------------------------------
    //      Helper Functions

    function automatic logic tag_match(   // CDB snoop
        input signal_pkg::prf_tag_t rs_tag ,
        input logic sc_cdb_valid, input signal_pkg::prf_tag_t sc_cdb_tag
    );
        tag_match = sc_cdb_valid && (rs_tag == sc_cdb_tag);

    endfunction

    function automatic rs_addr_t oneHot_to_binary(
        logic [DEPTH-1:0] oneHot_addr
    );
        rs_addr_t bin_addr;
        bin_addr = '0;
        for(int unsigned i=0; i<DEPTH; i++) if(oneHot_addr[i]) bin_addr = rs_addr_t'(i);
        return bin_addr;

    endfunction

    function automatic logic[DEPTH-1:0] rr_pick(
        input logic[DEPTH-1:0] req,
        input logic[DEPTH-1:0] mask_up
    );
        logic [DEPTH-1:0] up, lo, winner;
        up = req & mask_up;
        lo = req & ~mask_up;

        winner = (|up) ? (up & (~up + 1'b1)) : (lo & (~lo + 1'b1));
        return winner;

    endfunction

    //  -------------------------------------------------------------------------------------------
    //      Input

    logic in_valid, in_ready;
    packet_pkg::rs_entry_t in_entry_d;

    always_comb begin
        in_valid = rs_request_i.valid && (rs_request_i.chip_select == CHIP_SELECT);

        in_entry_d = rs_request_i.rs_entry;
        in_entry_d.occupied = 1'b1;
        in_entry_d.operand_a_ready = rs_request_i.rs_entry.operand_a_ready || tag_match (
                                     rs_request_i.rs_entry.operand_a_tag,
                                     sc_data_bus_i.valid, sc_data_bus_i.prf_tag );
        in_entry_d.operand_b_ready = rs_request_i.rs_entry.operand_b_ready || tag_match (
                                     rs_request_i.rs_entry.operand_b_tag,
                                     sc_data_bus_i.valid, sc_data_bus_i.prf_tag );

        in_ready = in_valid && in_entry_d.operand_a_ready && in_entry_d.operand_b_ready;
    end

    //  -------------------------------------------------------------------------------------------
    //      Buffer

    packet_pkg::rs_entry_t buffer[DEPTH];
    logic [DEPTH-1:0] occupied, eligible;

    always_comb begin
        for(int unsigned i=0; i<DEPTH; i++) begin
            occupied[i] = buffer[i].occupied;
            eligible[i] = buffer[i].occupied && buffer[i].operand_a_ready && buffer[i].operand_b_ready;
        end
    end

    //  -------------------------------------------------------------------------------------------
    //      Dispatch arbitration (round robin)

    logic [DEPTH-1:0] rr_mask_q, rr_mask_d, mask_upper;
    logic [DEPTH-1:0] winner1, winner2;
    logic winner1_valid, winner2_valid;

    always_comb begin
        mask_upper[0] = rr_mask_q[0];
        for (int unsigned i=1; i<DEPTH; i++) mask_upper[i] = mask_upper[i-1] | rr_mask_q[i];

        winner1 = rr_pick(eligible, mask_upper);
        winner2 = rr_pick(eligible & ~winner1, mask_upper);

        winner1_valid = |winner1;
        winner2_valid = |winner2;
    end

    //  -------------------------------------------------------------------------------------------
    //      Dispatch, Alloc and Bypass decisions

    logic p0_w1, p0_byp, p1_w1, p1_w2, p1_byp;
    logic bypass, alloc;
    logic [DEPTH-1:0] p1_winner, last_winner;
    rs_addr_t p0_addr, p1_addr;

    always_comb begin
        // port 0: winner1, else incoming
        p0_w1  = sc_ex0_ready_i &&  winner1_valid;
        p0_byp = sc_ex0_ready_i && !winner1_valid && in_ready;

        // port 1: next source not taken by port 0
        p1_w1  = sc_ex1_ready_i && !sc_ex0_ready_i && winner1_valid;
        p1_w2  = sc_ex1_ready_i &&  sc_ex0_ready_i && winner2_valid;
        p1_byp = sc_ex1_ready_i && in_ready &&
                 (sc_ex0_ready_i ? (winner1_valid && !winner2_valid) : !winner1_valid);

        bypass = p0_byp || p1_byp;
        alloc  = in_valid && !bypass;

        p1_winner = p1_w2 ? winner2 : winner1;

        p0_addr = oneHot_to_binary(winner1);
        p1_addr = oneHot_to_binary(p1_winner);

        // mask follows the last buffered entry dispatched this cycle
        if (p1_w2) last_winner = winner2;
        else if (p0_w1 || p1_w1) last_winner = winner1;
        else last_winner = '0;

        rr_mask_d = (|last_winner) ? {last_winner[DEPTH-2:0], last_winner[DEPTH-1]} : rr_mask_q;
    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni || flush_i) rr_mask_q <= {{(DEPTH-1){1'b0}}, 1'b1};
        else rr_mask_q <= rr_mask_d;
    end

    //  -------------------------------------------------------------------------------------------
    //      Allocation Address

    logic [DEPTH-1:0] alloc_addr;
    assign alloc_addr = ~occupied & (occupied + 1'b1);

    //  -------------------------------------------------------------------------------------------
    //      CDB Snoop

    logic [DEPTH-1:0] op_a_ready_d, op_b_ready_d;

    always_comb begin
        for (int unsigned i=0; i<DEPTH; i++) begin
            op_a_ready_d[i] = occupied[i] && (buffer[i].operand_a_ready || tag_match(
                              buffer[i].operand_a_tag, sc_data_bus_i.valid, sc_data_bus_i.prf_tag));
            op_b_ready_d[i] = occupied[i] && (buffer[i].operand_b_ready || tag_match(
                              buffer[i].operand_b_tag, sc_data_bus_i.valid, sc_data_bus_i.prf_tag));
        end
    end

    //  -------------------------------------------------------------------------------------------
    //      Buffer next state

    always_ff @(posedge clk_i) begin
        if (!reset_ni || flush_i) begin
            for (int unsigned i=0; i<DEPTH; i++) buffer[i].occupied <= 1'b0;
        end
        else begin
            for (int unsigned i=0; i<DEPTH; i++) begin
                buffer[i].operand_a_ready <= op_a_ready_d[i];
                buffer[i].operand_b_ready <= op_b_ready_d[i];
            end

            if (p0_w1) buffer[p0_addr].occupied <= 1'b0;
            if (p1_w1 || p1_w2) buffer[p1_addr].occupied <= 1'b0;
            
            for (int unsigned i=0; i<DEPTH; i++) 
                if (alloc && alloc_addr[i]) buffer[i] <= in_entry_d;
        end
    end

    //  -------------------------------------------------------------------------------------------
    //      Output

    packet_pkg::rs_entry_t out0_d, out0_q, out1_d, out1_q;
    logic [1:0] out_valid_d, out_valid_q;

    always_comb begin
        out_valid_d[0] = p0_w1 || p0_byp;
        out_valid_d[1] = p1_w1 || p1_w2 || p1_byp;

        if (p0_byp) out0_d = in_entry_d;
        else if (p0_w1) out0_d = buffer[p0_addr];
        else out0_d = '0;

        if (p1_byp) out1_d = in_entry_d;
        else if (p1_w1 || p1_w2) out1_d = buffer[p1_addr];
        else out1_d = '0;
    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni || flush_i) begin
            out0_q <= '0;
            out1_q <= '0;
            out_valid_q <= '0;
        end
        else begin
            out0_q <= out0_d;
            out1_q <= out1_d;
            out_valid_q <= out_valid_d;
        end
    end

    assign sc_rd_req0_o = '{
        valid   : out_valid_q[0],
        prf_tag : out0_q.prf_tag,
        rob_id  : out0_q.rob_id,
        operation : out0_q.operation,
        operand_a_tag : out0_q.operand_a_tag,
        operand_b_tag : out0_q.operand_b_tag,
        imm : out0_q.imm,
        read_src2   : out0_q.read_src2,
        a_is_vector : out0_q.a_is_vector,
        b_is_vector : out0_q.b_is_vector
    };

    assign sc_rd_req1_o = '{
        valid   : out_valid_q[1],
        prf_tag : out1_q.prf_tag,
        rob_id  : out1_q.rob_id,
        operation : out1_q.operation,
        operand_a_tag : out1_q.operand_a_tag,
        operand_b_tag : out1_q.operand_b_tag,
        imm : out1_q.imm,
        read_src2   : out1_q.read_src2,
        a_is_vector : out1_q.a_is_vector,
        b_is_vector : out1_q.b_is_vector
    };

    assign instr_dispatched_o[0] = out_valid_q[0];
    assign instr_dispatched_o[1] = out_valid_q[1];

endmodule
