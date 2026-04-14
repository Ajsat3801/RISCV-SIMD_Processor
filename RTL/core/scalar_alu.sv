/*
    Scalar ALU:

    Inputs: operation, destination registers, 2 operands
    Outputs: if result is valid, destination register, ALU result
*/

module scalar_alu(
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    // connection to reservation station
    input signal_pkg::rs_to_alu_signal_t alu_input_i,
    output logic ex_ready_o,

    //connection to writeback arbitrer
    input logic wb_ready_i,
    input logic branch_ready_i,
    output signal_pkg::ex_to_wb_signal_t alu_result_o,
    output signal_pkg::alu_to_wb_branch_signal_t branch_result_o

);

    storage_pkg::alu_holding_reg_t  current_alu_res, hold_reg;
    signal_pkg::alu_to_wb_branch_signal_t branch_result_q;
    signal_pkg::ex_to_wb_signal_t alu_result_q;

    logic ex_ready_q, ex_ready_d;
    // holding register states
    logic holding_reg_used, holding_reg_used_next;

    /* CONTROL SIGNALS THAT DETERMINE PATH OF ALU RESULT
     * for format a_to_b: 
     * options of a : res: current ALU result, hold: val in holding register
     * options of b : hold: holding register, wb: writeback arbiter, branch: branch
     */
    logic res_to_hold, res_to_wb, res_to_branch; 
    logic hold_to_wb, hold_to_branch;

    // valid signals for outputs
    logic wb_valid, branch_valid;

    // intermediate variables for control signals
    logic res_to_wb_int, wb_not_ready, branch_not_ready;

    // intermediate variables for alu calculations
    logic a_lt_b, a_lt_b_u, a_eq_b;
    instr_pkg::data_t operand_b;

    always_comb begin // combinationally building the output
        
        current_alu_res.valid   = alu_input_i.valid && !branch_valid;
        current_alu_res.prf_tag = alu_input_i.prf_tag;
        current_alu_res.rob_id  = alu_input_i.rob_id;
        current_alu_res.data    = '0;
        current_alu_res.branch_taken = 1'b0;
        current_alu_res.branch_valid = alu_input_i.valid && alu_input_i.operation[3];

        a_lt_b   = ($signed(alu_input_i.operand_a) < $signed(alu_input_i.operand_b)) ? 1'b1 : 1'b0;
        a_lt_b_u = (alu_input_i.operand_a < alu_input_i.operand_b) ? 1'b1 : 1'b0;
        a_eq_b   = (alu_input_i.operand_a == alu_input_i.operand_b) ? 1'b1 : 1'b0;

        if (alu_input_i.operation.alu == ALU_ADD && alu_input_i.sign) begin
            operand_b = (~alu_input_i.operand_b) + 1; // 2s complement for subtraction
        end
        else operand_b = alu_input_i.operand_b; // for the rest

        unique case (alu_input_i.operation.alu)
            ALU_ADD : current_alu_res.data = alu_input_i.operand_a + operand_b;
            ALU_SLL : current_alu_res.data = alu_input_i.operand_a << alu_input_i.operand_b;
            ALU_SLT : current_alu_res.data[0] = a_lt_b;
            ALU_SLTU: current_alu_res.data[0] = a_lt_b_u;
            ALU_XOR : current_alu_res.data = alu_input_i.operand_a ^ alu_input_i.operand_b;
            ALU_SRL : current_alu_res.data = alu_input_i.operand_a >> alu_input_i.operand_b;
            ALU_OR  : current_alu_res.data = alu_input_i.operand_a | alu_input_i.operand_b;
            ALU_AND : current_alu_res.data = alu_input_i.operand_a & alu_input_i.operand_b;
            ALU_BEQ : current_alu_res.branch_taken = a_eq_b;
            ALU_BNE : current_alu_res.branch_taken = !a_eq_b;
            ALU_BLT : current_alu_res.branch_taken = a_lt_b;
            ALU_BLTU: current_alu_res.branch_taken = a_lt_b_u;
            ALU_BGE : current_alu_res.branch_taken = !a_lt_b;
            ALU_BGEU: current_alu_res.branch_taken = !a_lt_b_u;
        endcase

        // control signals for holding reg values
        hold_to_wb     = holding_reg_used && wb_ready_i && !hold_reg.branch_valid;
        hold_to_branch = holding_reg_used && branch_ready_i && hold_reg.branch_valid;

        // control signals for the result of the current ALU calculation
        res_to_wb_int = current_alu_res.valid && !holding_reg_used;
        res_to_wb     = res_to_wb_int && (wb_ready_i && !current_alu_res.branch_valid);
        res_to_branch = res_to_wb_int && (branch_ready_i && current_alu_res.branch_valid);

        // send result to holding reg if writeback/branch is not ready and holding is empty
        wb_not_ready = !current_alu_res.branch_valid && (hold_to_wb || !wb_ready_i);
        branch_not_ready = current_alu_res.branch_valid && (hold_to_branch || !branch_ready_i);
        res_to_hold = current_alu_res.valid && (wb_not_ready || branch_not_ready);

        // next state of holding reg
        holding_reg_used_next = (holding_reg_used && !(hold_to_wb || hold_to_branch)) || res_to_hold;

        // valid signals for outputs
        wb_valid     = hold_to_wb || res_to_wb;
        branch_valid = hold_to_branch || res_to_branch;
        ex_ready_d   = !alu_input_i.valid || res_to_wb || res_to_hold;

    end

    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) begin
            
            alu_result_q <= 'd0;
            ex_ready_q   <= 1'b1;

            hold_reg <= 'd0;
            holding_reg_used <= 1'b0;

        end
        else begin

            // registering writeback port output
            if(hold_to_wb) begin
                alu_result_q.valid   <= hold_reg.valid;
                alu_result_q.prf_tag <= hold_reg.prf_tag;
                alu_result_q.rob_id  <= hold_reg.rob_id;
                alu_result_q.data    <= hold_reg.data;
            end 
            else if(res_to_wb) begin
                alu_result_q.valid   <= current_alu_res.valid;
                alu_result_q.prf_tag <= current_alu_res.prf_tag;
                alu_result_q.rob_id  <= current_alu_res.rob_id;
                alu_result_q.data    <= current_alu_res.data;
            end
            else alu_result_q <= 'd0;

            // registering branch port output
            if(hold_to_branch) begin
                branch_result_q.valid  <= hold_reg.valid;
                branch_result_q.rob_id <= hold_reg.rob_id;
                branch_result_q.branch_taken <= hold_reg.branch_taken;
            end
            else if(res_to_branch) begin
                branch_result_q.valid  <= current_alu_res.valid;
                branch_result_q.rob_id <= current_alu_res.rob_id;
                branch_result_q.branch_taken <= current_alu_res.branch_taken;
            end
            else branch_result_q <= 'd0;

            // updating hold register (if needed)
            if(res_to_hold) hold_reg <= current_alu_res;
            holding_reg_used <= holding_reg_used_next;

            ex_ready_q <= ex_ready_d;
        end
            
    end

    assign ex_ready_o   = ex_ready_q;
    assign alu_result_o = alu_result_q;
    assign branch_result_o = branch_result_q;

endmodule