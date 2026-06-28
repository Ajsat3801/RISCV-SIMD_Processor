/* ------------------------------------------------------------------------------------------------
 *                               FUNCTIONAL UNIT FOR BRANCH RESOLUTION
 * ------------------------------------------------------------------------------------------------
 *
 *  Functions/Behavior:
 *  ->  Receives a branch execution request containing two operands and a branch operation type.
 *  ->  Computes three comparison signals combinatorially and uses result to send output based on 
 *      branch operation.
 *
 *  Inputs
 *  ->  clk, reset_n & flush
 *  ->  br_ex_request_i — Branch execution request packet.
 *
 *  Outputs
 *  ->  br_ex_result_o — Branch result packet sent directly to the ROB.
 *  ->  br_ex_ready_o — Ready signal. Always driven to 1.
 *
 *  Notes
 *  ->  Branch result bypasses writeback and sent to ROB since branches dont write to PRF.
 *  ->  Reset and flush are functionally equivalent. No distinction between the two in behavior.
 *  ->  br_ex_ready_o is always 1, regardless of reset or flush. Included for interface uniformity
 *      with multi-cycle functional units.
 *  ->  prf_tag in the request packet unused.
 *  ->  The comparison logic runs every cycle regardless of state. Only gated by reset/flush.
 *
 * ------------------------------------------------------------------------------------------------
 */

module ex_branch(
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    input packet_pkg::sc_ex_request_t br_ex_request_i,
    output packet_pkg::br_result_t br_ex_result_o,
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
                signal_pkg::BR_BEQ  : br_ex_result_o.branch_taken <= a_eq_b;
                signal_pkg::BR_BNE  : br_ex_result_o.branch_taken <= !a_eq_b;
                signal_pkg::BR_BLT  : br_ex_result_o.branch_taken <= a_lt_b;
                signal_pkg::BR_BLTU : br_ex_result_o.branch_taken <= a_lt_b_u;
                signal_pkg::BR_BGE  : br_ex_result_o.branch_taken <= !a_lt_b;
                signal_pkg::BR_BGEU : br_ex_result_o.branch_taken <= !a_lt_b_u;
                default begin
                    br_ex_result_o.branch_taken <= 1'b0;
                end
            endcase
        end
        br_ex_ready_o <= 1'b1;
    end

endmodule