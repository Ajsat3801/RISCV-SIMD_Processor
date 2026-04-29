
module ex_vector_alu (
    input  logic clk_i,
    input  logic reset_ni,
    input  logic flush_i,
    
    input  signal_pkg::vc_ex_input_signal_t vc_ex_request_i,
    output signal_pkg::vc_ex_output_signal_t vc_ex_result_o,

    output logic vc_ex_ready_o
);

    genvar i;
    instr_pkg::vector_data_t valu_operand_a, valu_operand_b, valu_output;
    logic[config_pkg::VECTOR_SIZE-1:0] valid;


    generate

        for(i=0; i<config_pkg::VECTOR_SIZE; i++) begin
            lib_vector_alu_lane alu_instance (
                .operation(vc_ex_request_i.operation),
                .operand_a(valu_operand_a[i]),
                .operand_b(valu_operand_b[i]),
                .valid_i(vc_ex_request_i.valid),
                .result_o(valu_output[i]),
                .valid_o(valid[i])
            );
        end

    endgenerate

    always_comb begin
        valu_operand_a = (vc_ex_request_i.a_is_vector) ? vc_ex_request_i.operand_a : {4{vc_ex_request_i.operand_a[0]}};
        valu_operand_b = (vc_ex_request_i.b_is_vector) ? vc_ex_request_i.operand_b : {4{vc_ex_request_i.operand_b[0]}};
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