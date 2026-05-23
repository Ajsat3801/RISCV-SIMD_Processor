module ex_scalar_muldiv(
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    // connection to reservation station
    input packet_pkg::sc_ex_request_t sc_ex_request_i,

    //connection to writeback arbitrer
    output packet_pkg::sc_ex_result_t sc_ex_result_o,
    output logic sc_ex_ready_o
);

// radix booth 4 iterative multiplier
// restoring iterative divide

typedef enum logic[2:0] {READY, MUL, DIV} muldiv_state_e;
muldiv_state_e state, state_next;

logic[63:0] mul_result, div_result;
logic mul_valid_i, mul_valid_o;
logic div_valid_i, div_valid_o;
logic unsigned_multiplicand, unsigned_multiplier, unsigned_div;
logic ex_complete;

signal_pkg::prf_tag_t prf_tag;
signal_pkg::rob_address_t rob_id;
signal_pkg::operations_e operation;

lib_scalar_multiplier u_multiplier (
    .clk_i(clk_i),
    .reset_ni(reset_ni),
    .multiplicand_i(sc_ex_request_i.operand_a),
    .multiplier_i(sc_ex_request_i.operand_b),
    .unsigned_multiplicand_i(unsigned_multiplicand),
    .unsigned_multiplier_i(unsigned_multiplier),
    .valid_i(mul_valid_i),
    .result_o (mul_result),
    .valid_o (mul_valid_o)
);

lib_scalar_divider u_divider (
    .clk_i(clk_i),
    .reset_ni(reset_ni),
    .dividend_i(sc_ex_request_i.operand_a),
    .divisor_i(sc_ex_request_i.operand_b),
    .unsigned_div(unsigned_div),
    .valid_i(div_valid_i),
    .result_o(div_result),
    .valid_o(div_valid_o)
);

always_comb begin
    mul_valid_i = 1'b0;
    div_valid_i = 1'b0;
    unsigned_multiplicand = 1'b0;
    unsigned_multiplier = 1'b0;
    unsigned_div = 1'b0;
    state_next = state;

    ex_complete = ((state == MUL) && mul_valid_o) || ((state == DIV) && div_valid_o);
    state_next = (ex_complete) ? READY : state_next;

    if(sc_ex_request_i.valid && state == READY) begin
        unique case (sc_ex_request_i.operation.muldiv) 
            signal_pkg::MULDIV_MUL, signal_pkg::MULDIV_MULH : begin
                mul_valid_i = 1'b1;
                state_next = MUL;
            end
            signal_pkg::MULDIV_MULHSU  : begin
                unsigned_multiplier = 1'b1;
                mul_valid_i = 1'b1;
                state_next = MUL;
            end
            signal_pkg::MULDIV_MULHU : begin
                unsigned_multiplicand = 1'b1;
                unsigned_multiplier = 1'b1;
                mul_valid_i = 1'b1;
                state_next = MUL;
            end
            signal_pkg::MULDIV_DIV, signal_pkg::MULDIV_REM : begin
                div_valid_i = 1'b1;
                state_next = DIV;
            end
            signal_pkg::MULDIV_DIVU, signal_pkg::MULDIV_REMU : begin
                unsigned_div = 1'b1;
                div_valid_i = 1'b1;
                state_next = DIV;
            end
        endcase
    end  

    sc_ex_result_o.valid = ex_complete;
    sc_ex_result_o.prf_tag = prf_tag;
    sc_ex_result_o.rob_id = rob_id;

    unique case (operation.muldiv) 
        signal_pkg::MULDIV_MUL    : sc_ex_result_o.data = mul_result[31:0];
        signal_pkg::MULDIV_MULH   : sc_ex_result_o.data = mul_result[63:32];
        signal_pkg::MULDIV_MULHSU : sc_ex_result_o.data = mul_result[63:32];
        signal_pkg::MULDIV_MULHU  : sc_ex_result_o.data = mul_result[63:32];
        signal_pkg::MULDIV_DIV    : sc_ex_result_o.data = div_result[31:0];
        signal_pkg::MULDIV_DIVU   : sc_ex_result_o.data = div_result[31:0];
        signal_pkg::MULDIV_REM    : sc_ex_result_o.data = div_result[63:32];
        signal_pkg::MULDIV_REMU   : sc_ex_result_o.data = div_result[63:32];
        default: sc_ex_result_o.data = '0;
    endcase

    sc_ex_ready_o = (state_next == READY) && !sc_ex_request_i.valid;

end

always_ff @(posedge clk_i) begin
    if(!reset_ni || flush_i) begin
        prf_tag <= '0;
        rob_id <= '0;
        operation.muldiv <= signal_pkg::MULDIV_MUL;
        state <= READY;
    end
    else begin
        if(state == READY) begin
            if(sc_ex_request_i.valid) begin
                prf_tag <= sc_ex_request_i.prf_tag;
                rob_id <= sc_ex_request_i.rob_id;
                operation <= sc_ex_request_i.operation;
            end 
        end
        if(ex_complete) begin
            prf_tag <= '0;
            rob_id <= '0;
            operation.muldiv <= signal_pkg::MULDIV_MUL;
        end
        state <= state_next;
    end
end

endmodule