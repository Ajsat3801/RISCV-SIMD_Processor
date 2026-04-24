module sc_alu(
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    // connection to reservation station
    input signal_pkg::sc_ex_input_signal_t alu_input_i,

    //connection to writeback arbitrer
    output signal_pkg::sc_ex_output_signal_t alu_result_o,
    output ex_ready_o
);

    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) begin
            alu_result_o <= 'd0;
            ex_ready_o <= 1'b1;
        end
        else begin

            alu_result_o.valid   <= alu_input_i.valid;
            alu_result_o.prf_tag <= alu_input_i.prf_tag;
            alu_result_o.rob_id  <= alu_input_i.rob_id;

            unique case (alu_input_i.operation.alu)
                instr_pkg::ALU_ADD  : alu_result_o.data <= alu_input_i.operand_a + alu_input_i.operand_b;
                instr_pkg::ALU_SUB  : alu_result_o.data <= alu_input_i.operand_a - alu_input_i.operand_b;
                instr_pkg::ALU_SLL  : alu_result_o.data <= alu_input_i.operand_a << alu_input_i.operand_b;
                instr_pkg::ALU_SLT  : begin
                    alu_result_o.data[0] <= ($signed(alu_input_i.operand_a) < $signed(alu_input_i.operand_b)) ? 1'b1 : 1'b0;
                    alu_result_o.data[31:1] <= '0;
                end
                instr_pkg::ALU_SLTU : begin
                    alu_result_o.data[0] <= (alu_input_i.operand_a < alu_input_i.operand_b) ? 1'b1 : 1'b0;
                    alu_result_o.data[31:1] <= '0;
                end
                instr_pkg::ALU_XOR  : alu_result_o.data <= alu_input_i.operand_a ^ alu_input_i.operand_b;
                instr_pkg::ALU_SRL  : alu_result_o.data <= alu_input_i.operand_a >> alu_input_i.operand_b;
                instr_pkg::ALU_OR   : alu_result_o.data <= alu_input_i.operand_a | alu_input_i.operand_b;
                instr_pkg::ALU_AND  : alu_result_o.data <= alu_input_i.operand_a & alu_input_i.operand_b;
                default: alu_result_o.data <= '0;
            endcase
        end

        ex_ready_o <= 1'b1;
    end

endmodule