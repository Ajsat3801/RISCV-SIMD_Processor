module lib_vector_alu_lane(

    // connection to reservation station
    input instr_pkg::operations_e operation,
    input logic[31:0] operand_a,
    input logic[31:0] operand_b,
    input logic valid_i,

    //connection to writeback arbitrer
    output logic[31:0] result_o,
    output logic valid_o
);

    always_comb begin

        valid_o <= valid_i;

        unique case (operation.valu)
            instr_pkg::VALU_ADD  : result_o <= operand_a + operand_b;
            instr_pkg::VALU_SUB  : result_o <= operand_a - operand_b;
            instr_pkg::VALU_RSUB : result_o <= operand_b - operand_a;
            instr_pkg::VALU_XOR  : result_o <= operand_a ^ operand_b;
            instr_pkg::VALU_OR   : result_o <= operand_a | operand_b;
            instr_pkg::VALU_AND  : result_o <= operand_a & operand_b;
            default: result_o <= '0;
        endcase

    end

endmodule