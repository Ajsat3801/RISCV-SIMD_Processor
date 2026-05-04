/* FUNCTIONAL UNIT FOR BRANCH RESOLUTION
 *  Functions/Behavior:
 *  ->  checks for branch condition and returns flag to indicate branch taken or not
 *  Inputs
 *  ->  clock, reset_n and flush
 *  ->  branch request packet (see packet_pkg::sc_ex_request_t for detailed info)
 *  Outputs
 *  ->  branch result packet (see packet_pkg for detailed info)
 *  ->  ready
 *  Notes
 *  ->  result of branch resolution goes directly to the ROB bypassing writeback
 *  ->  flush and reset_n gives 0 as the output, no other functionality
 *  ->  ready out is always 1
 *  ->  flush and ready have functionality in multi-cycle FUs. added here for uniformity
 *  ->  prf_tag from branch packet is dont care. creating a separate packet for branches with prf
        tag removed scalar RS 1 issue model cannot be used for scheduling, so retained.
 *  Potential Optimizations for future
 *  ->  Remove PRF tag from branch request packet
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