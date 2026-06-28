/* ------------------------------------------------------------------------------------------------
 *                                  VECTOR ARITHMETIC LOGIC UNIT
 * ------------------------------------------------------------------------------------------------
 *
 *  Functions / Behavior
 *  ->  Top-level vector ALU execution unit. Instantiates VECTOR_SIZE parallel ALU lanes, one lane
 *      per vector element.
 *  ->  Scalar operands replicated to perform vector operations for mixed scalar-vector operation. 
 *  ->  On reset or flush, the output cleared to zero and vc_ex_ready_o is driven high.
 *
 *  Inputs
 *  ->  clk, reset_n & flush
 *  ->  vc_ex_request_i — Incoming vector ALU request packet from reservation station/PRF.
 *  ->  sc_operand_i — Scalar operand input used for .vx instructions
 *
 *  Outputs
 *  ->  vc_ex_result_o — Registered result packet.
 *  ->  vc_ex_ready_o — Indicates the unit is ready to accept a new request.
 *
 *  Notes
 *  ->  The result is considered valid only when all lane valid outputs are asserted.
 *  ->  vc_ex_ready_o is always 1 outside of reset/flush.
 *
 * ------------------------------------------------------------------------------------------------
 */
module ex_vector_alu (
    input  logic clk_i,
    input  logic reset_ni,
    input  logic flush_i,
    
    input  packet_pkg::vc_alu_ex_request_t vc_ex_request_i,
    input  signal_pkg::data_t sc_operand_i,
    
    output packet_pkg::vc_ex_result_t vc_ex_result_o,
    output logic vc_ex_ready_o
);

    genvar i;
    signal_pkg::vector_data_t valu_operand_a, valu_operand_b, valu_output;
    logic[config_pkg::VECTOR_SIZE-1:0] valid;

    generate 

        for(i=0; i<config_pkg::VECTOR_SIZE; i++) begin : gen_vector_lanes
            lib_vector_alu_lane alu_instance (
                .operation(vc_ex_request_i.operation),
                .operand_a(valu_operand_a[i]),
                .operand_b(vc_ex_request_i.operand_b[i]),
                .valid_i(vc_ex_request_i.valid),
                .result_o(valu_output[i]),
                .valid_o(valid[i])
            );
        end

    endgenerate

    always_comb begin
        valu_operand_a = (vc_ex_request_i.a_is_vector) ? vc_ex_request_i.operand_a : {VECTOR_SIZE{sc_operand_i}};
    end

    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) begin
            vc_ex_result_o <= '0;
            vc_ex_ready_o <= 1'b1;
        end
        else begin
            vc_ex_result_o.valid   <= (&valid);
            vc_ex_result_o.prf_tag <= vc_ex_request_i.prf_tag;
            vc_ex_result_o.rob_id  <= vc_ex_request_i.rob_id;
            vc_ex_result_o.data    <= valu_output;
            vc_ex_ready_o <= 1'b1;
        end
    end

endmodule