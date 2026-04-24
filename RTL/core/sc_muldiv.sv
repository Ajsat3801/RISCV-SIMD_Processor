module sc_muldiv(
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    // connection to reservation station
    input signal_pkg::sc_ex_input_signal_t muldiv_input_i,
    output logic ex_ready_o,

    //connection to writeback arbitrer
    output signal_pkg::sc_ex_output_signal_t muldiv_result_o
);

// radix booth 4 iterative multiplier
// restoring iterative divide

typedef enum logic[2:0] {READY, MUL, DIV} muldiv_state_e;
muldiv_state_e state, state_next;

logic[63:0] result;
logic mul_valid_i, mul_valid_o;
logic div_valid_i, div_valid_o;
logic unsigned_mul, unsigned_div;

instr_pkg::prf_tag_t prf_tag;
instr_pkg::rob_address_t rob_id;
instr_pkg::operations_e operation;

sc_multiplier u_multiplier (
    .clk_i(clk_i),
    .reset_ni(reset_ni),
    .multiplicand_i(muldiv_input_i.operand_a),
    .multiplier_i(muldiv_input_i.operand_b),
    .unsigned_multiplicand(unsigned_mul),
    .valid_i(mul_valid_i),
    .result_o (result),
    .valid_o (mul_valid_o)
);

sc_divider u_divider (
    .clk_i(clk_i),
    .reset_ni(reset_ni),
    .dividend_i(muldiv_input_i.operand_a),
    .divisor_i(muldiv_input_i.operand_b),
    .unsigned_div(unsigned_div),
    .valid_i(div_valid_i),
    .result_o(result),
    .valid_o(div_valid_o)
)

always_comb begin
    mul_valid_i = 1'b0;
    div_valid_i = 1'b0;
    unsigned_mul = 1'b0;
    state_next = state;

    if(muldiv_input_i.valid) begin
        unique case (muldiv_input_i.operation.muldiv) 
            MULDIV_MUL : begin
                unsigned_mul = 1'b0;
                mul_valid_i = 1'b1;
                state_next = MUL;
            end
            MULDIV_MULH : begin
                unsigned_mul = 1'b0;
                mul_valid_i = 1'b1;
                state_next = MUL;
            end
            MULDIV_MULHSU  : begin
                unsigned_mul = 1'b1;
                mul_valid_i = 1'b1;
                state_next = MUL;
            end
            MULDIV_MULHU : begin
                unsigned_mul = 1'b1;
                mul_valid_i = 1'b1;
                state_next = MUL;
            end
            MULDIV_DIV : begin
                unsigned_div = 1'b0;
                div_valid_i = 1'b1;
                state_next = DIV;
            end
            MULDIV_DIVU : begin
                unsigned_div = 1'b1;
                div_valid_i = 1'b1;
                state_next = DIV;
            end
            MULDIV_REM : begin
                unsigned_div = 1'b0;
                div_valid_i = 1'b1;
                state_next = DIV;
            end
            MULDIV_REMU : begin
                unsigned_div = 1'b1;
                div_valid_i = 1'b1;
                state_next = DIV;
            end
            default:
                mul_valid_i = 1'b0;
                div_valid_i = 1'b0;
                unsigned_mul = 1'b0;
                state_next = state;
        endcase
    end 

    muldiv_result_o <= '0;
    ex_ready_o <= 1'b0;

    unique case (operation.muldiv) 
        MULDIV_MUL    : muldiv_result_o.data <= result[31:0];
        MULDIV_MULH   : muldiv_result_o.data <= result[63:32];
        MULDIV_MULHSU : muldiv_result_o.data <= result[63:32];
        MULDIV_MULHU  : muldiv_result_o.data <= result[63:32];
        MULDIV_DIV    : muldiv_result_o.data <= result[31:0];
        MULDIV_DIVU   : muldiv_result_o.data <= result[31:0];
        MULDIV_REM    : muldiv_result_o.data <= result[63:32];
        MULDIV_REMU   : muldiv_result_o.data <= result[63:32];
        default: muldiv_result_o.data <= '0;
    endcase

    ex_complete = ((state == MUL) && mul_valid_o) || ((state == DIV) && div_valid_o);

    if (ex_complete) begin
        muldiv_result_o.valid = 1'b1;
        state_next = READY;
        ex_ready_o = 1'b1;
    end
    else if(state == READY) ex_ready_o = 1'b1;

end

always_ff begin
    if(!reset_ni || flush_i) begin
        prf_tag <= '0;
        rob_id <= '0;
        operation.muldiv <= MULDIV_MUL;
        state <= READY;
    end
    else begin
        if(state == READY) begin
            if(muldiv_input_i.valid) begin
                prf_tag <= muldiv_input_i.prf_tag;
                rob_id <= muldiv_input_i.rob_id;
                operation <= muldiv_input_i.operation;
            end 
        end
        if(ex_complete) begin
            prf_tag <= '0;
            rob_id <= '0;
            operation.muldiv <= MULDIV_MUL;
        end
        state <= state_next;
    end
end

endmodule