/* ------------------------------------------------------------------------------------------------
 *                              VECTOR SINGLE ISSUE RESERVATION STATION
 * ------------------------------------------------------------------------------------------------
 *
 *   Functions/Behavior
 *  <TODO>
 *
 *  Inputs:
 *  ->  clk, reset_n & flush
 *  ->  rs_request_i — Instruction to be allocated.
 *  ->  sc_data_bus_i — Snoop scalar CDB
 *  ->  vc_data_bus_i — Snoop vector CDB 
 *  ->  vc_ex_ready_i — Ready signal from vector execution unit
 *
 *  Outputs:
 *  ->  vc_read_request_o — Read request sent to the vector execution unit. 
 *  ->  sc_read_request_tag_o — The PRF tag for the scalar source operand A.
 *  ->  instr_dispatched_o — signal indicating slot has been released
 *
 * ------------------------------------------------------------------------------------------------
 */


module rs_vector_1issue #(
    parameter signal_pkg::chip_select_e CHIP_SELECT = signal_pkg::CS_VALU,
    parameter int unsigned DEPTH = 8
)(
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    // RS <- ARR connection
    if_alloc_bus.rs rs_request_i,

    // RS <- CDB connection for snoop
    if_data_bus.snoop sc_data_bus_i,
    if_data_bus.snoop vc_data_bus_i,
    
    // RS <- EX connection for backpressure
    input logic vc_ex_ready_i,

    // RS -> PRF connection for scalar and vector reads
    output packet_pkg::read_request_t vc_read_request_o,
    output signal_pkg::prf_tag_t sc_read_request_tag_o,

    // RS -> Instruction queue for credit return
    output logic instr_dispatched_o
);

    //  -------------------------------------------------------------------------------------------
    //      Types and localparams

    localparam int unsigned ADDR_W = $clog2(DEPTH);
    typedef logic [ADDR_W-1:0] rs_addr_t;

    //  -------------------------------------------------------------------------------------------
    //      Helper functions

    function automatic logic tag_match(  // CDB snoop, bus selected by operand type
        input signal_pkg::prf_tag_t rs_tag, input logic is_vector,
        input logic sc_cdb_valid, input signal_pkg::prf_tag_t sc_cdb_tag,
        input logic vc_cdb_valid, input signal_pkg::prf_tag_t vc_cdb_tag
    );
        tag_match = is_vector ? (vc_cdb_valid && (rs_tag == vc_cdb_tag))
                           : (sc_cdb_valid && (rs_tag == sc_cdb_tag));
    endfunction

    function automatic rs_addr_t oneHot_to_binary(input logic [DEPTH-1:0] oneHot_addr);
        rs_addr_t bin_addr;
        bin_addr = '0;
        for (int unsigned i=0; i<DEPTH; i++) if (oneHot_addr[i]) bin_addr = rs_addr_t'(i);
        return bin_addr;
    endfunction

    function automatic logic [DEPTH-1:0] rr_pick(       // lowest request at/above mask, else wrap
        input logic [DEPTH-1:0] req, input logic [DEPTH-1:0] mask_up
    );
        logic [DEPTH-1:0] up, lo;
        up = req &  mask_up;
        lo = req & ~mask_up;
        return (|up) ? (up & (~up + 1'b1)) : (lo & (~lo + 1'b1));
    endfunction

    //  -------------------------------------------------------------------------------------------
    //      Input

    logic in_valid, in_ready;
    packet_pkg::rs_entry_t in_entry_d;

    always_comb begin
        in_valid = rs_request_i.valid && (rs_request_i.chip_select == CHIP_SELECT);

        in_entry_d = rs_request_i.rs_entry;
        in_entry_d.occupied = 1'b1;
        in_entry_d.operand_a_ready = rs_request_i.rs_entry.operand_a_ready || tag_match(
                                     rs_request_i.rs_entry.operand_a_tag, rs_request_i.rs_entry.a_is_vector,
                                     sc_data_bus_i.valid, sc_data_bus_i.prf_tag,
                                     vc_data_bus_i.valid, vc_data_bus_i.prf_tag);
        in_entry_d.operand_b_ready = rs_request_i.rs_entry.operand_b_ready || tag_match(
                                     rs_request_i.rs_entry.operand_b_tag, rs_request_i.rs_entry.b_is_vector,
                                     sc_data_bus_i.valid, sc_data_bus_i.prf_tag,
                                     vc_data_bus_i.valid, vc_data_bus_i.prf_tag);

        in_ready = in_valid && in_entry_d.operand_a_ready && in_entry_d.operand_b_ready;
    end

    //  -------------------------------------------------------------------------------------------
    //      Buffer

    packet_pkg::rs_entry_t buffer[DEPTH];
    logic [DEPTH-1:0] occupied, eligible;

    always_comb begin
        for (int unsigned i=0; i<DEPTH; i++) begin
            occupied[i] = buffer[i].occupied;
            eligible[i] = buffer[i].occupied && buffer[i].operand_a_ready && buffer[i].operand_b_ready;
        end
    end

    //  -------------------------------------------------------------------------------------------
    //      Dispatch, Alloc and Bypass decisions

    logic dispatch, bypass, alloc;

    always_comb begin
        dispatch = vc_ex_ready_i && (|eligible);
        bypass = vc_ex_ready_i && in_ready && !(|eligible);
        alloc  = in_valid && !bypass;
    end

    //  -------------------------------------------------------------------------------------------
    //      Dispatch arbitration (round robin)

    logic [DEPTH-1:0] rr_mask_q, rr_mask_d, mask_upper, winner;
    rs_addr_t dispatch_addr;

    always_comb begin
        mask_upper[0] = rr_mask_q[0];
        for (int unsigned i=1; i<DEPTH; i++) mask_upper[i] = mask_upper[i-1] | rr_mask_q[i];

        winner = rr_pick(eligible, mask_upper);
        rr_mask_d = dispatch ? {winner[DEPTH-2:0], winner[DEPTH-1]} : rr_mask_q;
        dispatch_addr = oneHot_to_binary(winner);
    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni || flush_i) rr_mask_q <= {{(DEPTH-1){1'b0}}, 1'b1};
        else rr_mask_q <= rr_mask_d;
    end

    //  -------------------------------------------------------------------------------------------
    //      Allocation Address

    logic [DEPTH-1:0] first_free;
    rs_addr_t alloc_addr;

    always_comb begin
        first_free = ~occupied & (occupied + 1'b1);
        alloc_addr = oneHot_to_binary(first_free);
    end

    //  -------------------------------------------------------------------------------------------
    //      CDB Snoop

    logic [DEPTH-1:0] op_a_ready_d, op_b_ready_d;

    always_comb begin
        for (int unsigned i=0; i<DEPTH; i++) begin
            op_a_ready_d[i] = occupied[i] && (buffer[i].operand_a_ready || tag_match(
                              buffer[i].operand_a_tag, buffer[i].a_is_vector,
                              sc_data_bus_i.valid, sc_data_bus_i.prf_tag,
                              vc_data_bus_i.valid, vc_data_bus_i.prf_tag));
            op_b_ready_d[i] = occupied[i] && (buffer[i].operand_b_ready || tag_match(
                              buffer[i].operand_b_tag, buffer[i].b_is_vector,
                              sc_data_bus_i.valid, sc_data_bus_i.prf_tag,
                              vc_data_bus_i.valid, vc_data_bus_i.prf_tag));
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

            if (dispatch) buffer[dispatch_addr].occupied <= 1'b0;
            if (alloc) buffer[alloc_addr] <= in_entry_d;
        end
    end

    //  -------------------------------------------------------------------------------------------
    //      Output

    packet_pkg::rs_entry_t out_d, out_q;
    logic out_valid_d, out_valid_q;

    always_comb begin
        out_valid_d = bypass || dispatch;
        if (bypass) out_d = in_entry_d;
        else if (dispatch) out_d = buffer[dispatch_addr];
        else out_d = '0;
    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni || flush_i) begin
            out_q <= '0;
            out_valid_q <= 1'b0;
        end
        else begin
            out_q <= out_d;
            out_valid_q <= out_valid_d;
        end
    end

    assign vc_read_request_o = '{
        valid   : out_valid_q,
        prf_tag : out_q.prf_tag,
        rob_id  : out_q.rob_id,
        operation : out_q.operation,
        operand_a_tag : out_q.operand_a_tag,
        operand_b_tag : out_q.operand_b_tag,
        imm : out_q.imm,
        read_src2 : out_q.read_src2,
        a_is_vector : out_q.a_is_vector,
        b_is_vector : out_q.b_is_vector
    };

    assign sc_read_request_tag_o = out_q.operand_a_tag;
    assign instr_dispatched_o = out_valid_q;
  
endmodule
