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
                instr_pkg::ALU_ADD  : alu_result.data <= sc_ex_request_i.operand_a + sc_ex_request_i.operand_b;
                instr_pkg::ALU_SUB  : alu_result.data <= sc_ex_request_i.operand_a - sc_ex_request_i.operand_b;
                instr_pkg::ALU_SLL  : alu_result.data <= sc_ex_request_i.operand_a << sc_ex_request_i.operand_b;
                instr_pkg::ALU_SLT  : begin
                    alu_result.data[0] <= ($signed(sc_ex_request_i.operand_a) < $signed(sc_ex_request_i.operand_b)) ? 1'b1 : 1'b0;
                    alu_result.data[31:1] <= '0;
                end
                instr_pkg::ALU_SLTU : begin
                    alu_result.data[0] <= (sc_ex_request_i.operand_a < sc_ex_request_i.operand_b) ? 1'b1 : 1'b0;
                    alu_result.data[31:1] <= '0;
                end
                instr_pkg::ALU_XOR  : alu_result.data <= sc_ex_request_i.operand_a ^ sc_ex_request_i.operand_b;
                instr_pkg::ALU_SRL  : alu_result.data <= sc_ex_request_i.operand_a >> sc_ex_request_i.operand_b;
                instr_pkg::ALU_OR   : alu_result.data <= sc_ex_request_i.operand_a | sc_ex_request_i.operand_b;
                instr_pkg::ALU_AND  : alu_result.data <= sc_ex_request_i.operand_a & sc_ex_request_i.operand_b;
                default: alu_result.data <= '0;
            endcase
        end

        ex_ready <= 1'b1;
    end

    assign sc_ex_ready_o   = ex_ready;
    assign sc_ex_result_o = alu_result;

endmodule