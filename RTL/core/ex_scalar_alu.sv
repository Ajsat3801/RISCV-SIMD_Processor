/* ------------------------------------------------------------------------------------------------
 *                                          SCALAR ALU
 * ------------------------------------------------------------------------------------------------
 *
 *  Functions / Behavior:
 *  ->  Single-cycle scalar ALU that executes integer arithmetic & logical operations.
 *  ->  Receives ex request packet from the reservation station each cycle & produces a result
 *      packet for the writeback arbiter.
 *  ->  On reset or flush, the result register is cleared and ex_ready_o is driven high.
 *
 *  Inputs:
 *  ->  clk, reset_n & flush
 *  ->  sc_ex_request_i — Scalar execution request packet from the reservation station.
 *
 *  Outputs:
 *  ->  sc_ex_result_o — Scalar execution result packet forwarded to the writeback arbiter.
 *  ->  sc_ex_ready_o — Indicates the ALU is ready to accept a new request.
 *
 *  Notes:
 *  ->  SLT and SLTU produce a 1-bit result sign-extended to 32 bits.
 *  ->  ex_ready_o is always 1 (the ALU accepts a new request every cycle and never stalls).
 *  ->  SRA not supported by the core, provision given for adding it in the future.
 *  ->  Possiblity to add pipelining for shifts to improve timing in the future.
 *
 * ------------------------------------------------------------------------------------------------
 */


module ex_scalar_alu(
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    // connection to reservation station
    input packet_pkg::sc_ex_request_t sc_ex_request_i,

    //connection to writeback arbitrer
    output packet_pkg::sc_ex_result_t sc_ex_result_o,
    output sc_ex_ready_o
);
    
    packet_pkg::sc_ex_result_t alu_result;
    logic ex_ready;

    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) begin
            alu_result <= 'd0;
            ex_ready   <= 1'b1;
        end
        else begin

            alu_result.valid   <= sc_ex_request_i.valid;
            alu_result.prf_tag <= sc_ex_request_i.prf_tag;
            alu_result.rob_id  <= sc_ex_request_i.rob_id;

            unique case (sc_ex_request_i.operation.alu)
                signal_pkg::ALU_ADD  : alu_result.data <= sc_ex_request_i.operand_a + sc_ex_request_i.operand_b;
                signal_pkg::ALU_SUB  : alu_result.data <= sc_ex_request_i.operand_a - sc_ex_request_i.operand_b;
                signal_pkg::ALU_SLL  : alu_result.data <= sc_ex_request_i.operand_a << sc_ex_request_i.operand_b;
                signal_pkg::ALU_SLT  : begin
                    alu_result.data[0] <= ($signed(sc_ex_request_i.operand_a) < $signed(sc_ex_request_i.operand_b)) ? 1'b1 : 1'b0;
                    alu_result.data[31:1] <= '0;
                end
                signal_pkg::ALU_SLTU : begin
                    alu_result.data[0] <= (sc_ex_request_i.operand_a < sc_ex_request_i.operand_b) ? 1'b1 : 1'b0;
                    alu_result.data[31:1] <= '0;
                end
                signal_pkg::ALU_XOR  : alu_result.data <= sc_ex_request_i.operand_a ^ sc_ex_request_i.operand_b;
                signal_pkg::ALU_SRL  : alu_result.data <= sc_ex_request_i.operand_a >> sc_ex_request_i.operand_b;
                signal_pkg::ALU_OR   : alu_result.data <= sc_ex_request_i.operand_a | sc_ex_request_i.operand_b;
                signal_pkg::ALU_AND  : alu_result.data <= sc_ex_request_i.operand_a & sc_ex_request_i.operand_b;
                default: alu_result.data <= '0;
            endcase
        end

        ex_ready <= 1'b1;
    end

    assign sc_ex_ready_o  = ex_ready;
    assign sc_ex_result_o = alu_result;

endmodule