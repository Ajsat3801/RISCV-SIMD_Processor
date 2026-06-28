/* ------------------------------------------------------------------------------------------------
 *                                        VECTOR ALU LANE
 * ------------------------------------------------------------------------------------------------
 *
 *  Functions / Behavior
 *  ->  Implements the per-element arithmetic and logic operations for the vector pipeline.
 *  ->  valid_o is passed through directly from valid_i with no modification.
 *
 *  Inputs
 *  ->  operation — Operation code.
 *  ->  operand_a — First 32-bit operand.
 *  ->  operand_b — Second 32-bit operand.
 *  ->  valid_i — Input valid signal propagated from the request packet.
 *
 *  Outputs
 *  ->  result_o — Computed 32-bit result for this lane element.
 *  ->  valid_o — Passes valid_i through to the parent module for aggregation.
 *
 *  Notes
 *  ->  Module is purely combinatorial with no clock or reset ports.
 *
 * ------------------------------------------------------------------------------------------------
 */

module lib_vector_alu_lane(

    // connection to reservation station
    input signal_pkg::operations_e operation,
    input logic[31:0] operand_a,
    input logic[31:0] operand_b,
    input logic valid_i,

    //connection to writeback arbitrer
    output logic[31:0] result_o,
    output logic valid_o
);

    always_comb begin

        valid_o = valid_i;

        unique case (operation.valu)
            signal_pkg::VALU_ADD  : result_o = operand_a + operand_b;
            signal_pkg::VALU_SUB  : result_o = operand_b - operand_a;
            signal_pkg::VALU_RSUB : result_o = operand_a - operand_b;
            signal_pkg::VALU_XOR  : result_o = operand_a ^ operand_b;
            signal_pkg::VALU_OR   : result_o = operand_a | operand_b;
            signal_pkg::VALU_AND  : result_o = operand_a & operand_b;
            default: result_o = '0;
        endcase

    end

endmodule