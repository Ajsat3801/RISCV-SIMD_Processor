
module branch_unit(
    input logic clk_i,
    input logic reset_ni,

    input signal_pkg::rs_to_scalar_ex_signal_t br_input_o,
    output signal_pkg::br_to_rob_signal_t br_res_o
);
    logic a_lt_b, a_lt_b_u, a_eq_b;
    
    always_comb begin

        a_lt_b   = ($signed(br_input_o.operand_a) < $signed(br_input_o.operand_b)) ? 1'b1 : 1'b0;
        a_lt_b_u = (br_input_o.operand_a < br_input_o.operand_b) ? 1'b1 : 1'b0;
        a_eq_b   = (br_input_o.operand_a == br_input_o.operand_b) ? 1'b1 : 1'b0;
        
    end

    always_ff @(posedge clk_i) begin
        if (!reset_n) begin
            br_res_o <= '0;
        end
        else begin

            br_res_o.valid  <= alu_input_i.valid;
            br_res_o.rob_id <= alu_input_i.rob_id;

            unique case (br_input_o.operation.br)
                BR_BEQ  : br_res_o.branch_taken = a_eq_b;
                BR_BNE  : br_res_o.branch_taken = !a_eq_b;
                BR_BLT  : br_res_o.branch_taken = a_lt_b;
                BR_BLTU : br_res_o.branch_taken = a_lt_b_u;
                BR_BGE  : br_res_o.branch_taken = !a_lt_b;
                BR_BGEU : br_res_o.branch_taken = !a_lt_b_u;
                default begin
                    br_res_o.branch_taken = 1'b0;
                end
            endcase
        end
    end

endmodule