/* ------------------------------------------------------------------------------------------------
 *                                   SINGLE ISSUE RESERVATION STATION
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
 *  <TODO>
 *
 * ------------------------------------------------------------------------------------------------
 */

module rs_scalar_1issue #(
    parameter signal_pkg::chip_select_e CHIP_SELECT = signal_pkg::CS_SALU,
    parameter int unsigned DEPTH = 8
)(
    input  logic clk_i,
    input  logic reset_ni,
    input  logic flush_i,
     
    //  RS <- ARR connection
    if_alloc_bus.rs rs_request_i,

    //  RS <- Scalar WB connection
    if_data_bus.snoop sc_data_bus_i,

    //  RS <- EX connection for ready backpressure
    input  logic sc_ex_ready_i,

    //  RS -> PRF connection for dispatched instruction
    output packet_pkg::read_request_t sc_rd_req_o,

    //  RS -> Instruction queue connection for credit return
    output logic instr_dispatched_o
);

    //  -------------------------------------------------------------------------------------------
    //      Types and localparams

    localparam int unsigned ADDR_W = $clog2(DEPTH);
    typedef logic [ADDR_W-1:0] rs_addr_t;

    //  -------------------------------------------------------------------------------------------
    //      Helper Functions

    function automatic logic tag_match( // CDB snoop
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

        in_ready = in_entry_d.operand_a_ready && in_entry_d.operand_b_ready;
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
    //      Dispatch, Alloc and Bypass desicions

    logic dispatch, alloc, bypass;
    
    always_comb begin
        dispatch = sc_ex_ready_i && (|eligible);
        bypass = sc_ex_ready_i && in_valid && in_ready && !(|eligible);
        alloc = in_valid && !bypass;
    end

    //  -------------------------------------------------------------------------------------------
    //      Dispatch arbitration

    logic [DEPTH-1:0] rr_mask_q, rr_mask_d;
    logic [DEPTH-1:0] mask_upper, rr_upper, rr_lower, winner;
    rs_addr_t dispatch_addr;

    always_comb begin
        mask_upper[0] = rr_mask_q[0];

        for(int unsigned i=1; i<DEPTH; i++) mask_upper[i] = mask_upper[i-1] | rr_mask_q[i];

        rr_upper = eligible & mask_upper;
        rr_lower = eligible & ~mask_upper;

        winner = (|rr_upper)    ? (rr_upper & (~rr_upper + 1'b1))
                                : (rr_lower & (~rr_lower + 1'b1));

        rr_mask_d = dispatch ? {winner[DEPTH-2:0], winner[DEPTH-1]} : rr_mask_q;

        dispatch_addr = oneHot_to_binary(winner);
    
    end

    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) rr_mask_q <= {{(DEPTH-1){1'b0}}, 1'b1};
        else rr_mask_q <= rr_mask_d;
    end

    //  -------------------------------------------------------------------------------------------
    //      Allocation Address

    logic[DEPTH-1:0] alloc_addr;
    assign alloc_addr = ~occupied & (occupied + 1'b1);

    //  -------------------------------------------------------------------------------------------
    //      CDB Snoop

    logic [DEPTH-1:0] op_a_ready_d, op_b_ready_d;

    always_comb begin
        for(int unsigned i=0; i<DEPTH; i++) begin
            op_a_ready_d[i] =  occupied[i] && (buffer[i].operand_a_ready || tag_match (
                                        buffer[i].operand_a_tag, 
                                        sc_data_bus_i.valid, sc_data_bus_i.prf_tag));
            op_b_ready_d[i] =  occupied[i] && (buffer[i].operand_b_ready || tag_match (
                                        buffer[i].operand_b_tag, 
                                        sc_data_bus_i.valid, sc_data_bus_i.prf_tag));
        end
    end

    //  -------------------------------------------------------------------------------------------
    //      Buffer next state

    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) begin
            for(int unsigned i=0; i<DEPTH; i++) buffer[i].occupied <= 1'b0;
        end
        else begin
            for(int unsigned i=0; i<DEPTH; i++) begin
                buffer[i].operand_a_ready <= op_a_ready_d[i];
                buffer[i].operand_b_ready <= op_b_ready_d[i];
            end

            if(dispatch) buffer[dispatch_addr].occupied <= 1'b0;
            for(int unsigned i=0; i<DEPTH; i++)
                if(alloc && alloc_addr[i]) buffer[i] <= in_entry_d;
        end
    end

    //  -------------------------------------------------------------------------------------------
    //      Output

    packet_pkg::rs_entry_t out_d, out_q;
    logic out_valid_d, out_valid_q;

    always_comb begin
        out_valid_d = bypass || dispatch;

        if(bypass) out_d = in_entry_d;
        else if(dispatch) out_d = buffer[dispatch_addr];
        else out_d = '0;

    end

    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) begin
            out_q <= '0;
            out_valid_q <= 1'b0;
        end
        else begin
            out_q <= out_d;
            out_valid_q <= out_valid_d;
        end
    end

    assign sc_rd_req_o = '{
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

    assign instr_dispatched_o = out_valid_q;

endmodule
