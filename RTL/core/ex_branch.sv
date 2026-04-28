
module ex_branch(
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    input signal_pkg::sc_ex_input_signal_t br_ex_request_i,
    output signal_pkg::br_output_signal_t br_ex_result_o,
    output logic br_ex_ready_o
);
    logic a_lt_b, a_lt_b_u, a_eq_b;
    
    always_comb begin

        a_lt_b   = ($signed(br_ex_request_i.operand_a) < $signed(br_ex_request_i.operand_b)) ? 1'b1 : 1'b0;
        a_lt_b_u = (br_ex_request_i.operand_a < br_ex_request_i.operand_b) ? 1'b1 : 1'b0;
        a_eq_b   = (br_ex_request_i.operand_a == br_ex_request_i.operand_b) ? 1'b1 : 1'b0;
        
    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni || flush_i) begin
            br_ex_result_o <= '0;
        end
        else begin

            br_ex_result_o.valid  <= br_ex_request_i.valid;
            br_ex_result_o.rob_id <= br_ex_request_i.rob_id;

            unique case (br_ex_request_i.operation.br)
                instr_pkg::BR_BEQ  : br_ex_result_o.branch_taken <= a_eq_b;
                instr_pkg::BR_BNE  : br_ex_result_o.branch_taken <= !a_eq_b;
                instr_pkg::BR_BLT  : br_ex_result_o.branch_taken <= a_lt_b;
                instr_pkg::BR_BLTU : br_ex_result_o.branch_taken <= a_lt_b_u;
                instr_pkg::BR_BGE  : br_ex_result_o.branch_taken <= !a_lt_b;
                instr_pkg::BR_BGEU : br_ex_result_o.branch_taken <= !a_lt_b_u;
                default begin
                    br_ex_result_o.branch_taken <= 1'b0;
                end
            endcase
        end
        br_ex_ready_o <= 1'b1;
    end

endmodule