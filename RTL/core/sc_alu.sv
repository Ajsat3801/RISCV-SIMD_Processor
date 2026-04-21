/*
    Scalar ALU:

    Inputs: operation, destination registers, 2 operands
    Outputs: if result is valid, destination register, ALU result
*/

module sc_alu(
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    // connection to reservation station
    input signal_pkg::sc_ex_input_signal_t alu_input_i,
    output logic ex_ready_o,

    //connection to writeback arbitrer
    input logic wb_ready_i,
    output signal_pkg::sc_ex_output_signal_t alu_result_o
);

    storage_pkg::alu_result_entry_t  current_alu_res, hold_reg;

    logic ex_ready_d;
    // holding register states
    logic holding_reg_used, holding_reg_used_next;

    /* CONTROL SIGNALS THAT DETERMINE PATH OF ALU RESULT
     * for format a_to_b: 
     * options of a : res: current ALU result, hold: val in holding register
     * options of b : hold: holding register, wb: writeback arbiter
     */
    logic res_to_hold, res_to_wb, hold_to_wb;

    always_comb begin // combinationally building the output
        
        current_alu_res.valid   = alu_input_i.valid;
        current_alu_res.prf_tag = alu_input_i.prf_tag;
        current_alu_res.rob_id  = alu_input_i.rob_id;
        current_alu_res.data    = '0;

        unique case (alu_input_i.operation.alu)
            instr_pkg::ALU_ADD  : current_alu_res.data = alu_input_i.operand_a + alu_input_i.operand_b;
            instr_pkg::ALU_SUB  : current_alu_res.data = alu_input_i.operand_a - alu_input_i.operand_b;
            instr_pkg::ALU_SLL  : current_alu_res.data = alu_input_i.operand_a << alu_input_i.operand_b;
            instr_pkg::ALU_SLT  : current_alu_res.data[0] = ($signed(alu_input_i.operand_a) < $signed(alu_input_i.operand_b)) ? 1'b1 : 1'b0;
            instr_pkg::ALU_SLTU : current_alu_res.data[0] = (alu_input_i.operand_a < alu_input_i.operand_b) ? 1'b1 : 1'b0;
            instr_pkg::ALU_XOR  : current_alu_res.data = alu_input_i.operand_a ^ alu_input_i.operand_b;
            instr_pkg::ALU_SRL  : current_alu_res.data = alu_input_i.operand_a >> alu_input_i.operand_b;
            instr_pkg::ALU_OR   : current_alu_res.data = alu_input_i.operand_a | alu_input_i.operand_b;
            instr_pkg::ALU_AND  : current_alu_res.data = alu_input_i.operand_a & alu_input_i.operand_b;
            default begin
                current_alu_res.data = '0;
            end
        endcase

        // control signals for the result of the current ALU calculation
        res_to_wb   = current_alu_res.valid && !holding_reg_used && wb_ready_i;
        res_to_hold = current_alu_res.valid && !holding_reg_used && !wb_ready_i;

        // control signals for holding reg values & next state of holding reg
        hold_to_wb  = holding_reg_used && wb_ready_i;
        holding_reg_used_next = (holding_reg_used && !hold_to_wb) || res_to_hold;

    end

    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) begin
            
            alu_result_o <= 'd0;
            ex_ready_o   <= 1'b1;

            hold_reg <= 'd0;
            holding_reg_used <= 1'b0;

        end
        else begin

            // writeback port output
            if(hold_to_wb) begin
                alu_result_o.valid   <= hold_reg.valid;
                alu_result_o.prf_tag <= hold_reg.prf_tag;
                alu_result_o.rob_id  <= hold_reg.rob_id;
                alu_result_o.data    <= hold_reg.data;
            end 
            else if(res_to_wb) begin
                alu_result_o.valid   <= current_alu_res.valid;
                alu_result_o.prf_tag <= current_alu_res.prf_tag;
                alu_result_o.rob_id  <= current_alu_res.rob_id;
                alu_result_o.data    <= current_alu_res.data;
            end
            else alu_result_o <= 'd0;

            // updating hold register (if needed)
            if(res_to_hold) hold_reg <= current_alu_res;
            holding_reg_used <= holding_reg_used_next;

            ex_ready_o <= !holding_reg_used_next;
        end
    end

endmodule