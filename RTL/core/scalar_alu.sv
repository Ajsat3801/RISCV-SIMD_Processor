/*
    Scalar ALU:

    Inputs: operation, destination registers, 2 operands
    Outputs: if result is valid, destination register, ALU result
*/

module scalar_alu(
    input logic clk,
    input logic reset_n,
    input logic flush_i,

    // connection to reservation station
    input signal_pkg::rs_to_alu_signal_t dispatched_op,
    output logic ex_ready,

    //connection to writeback arbitrer
    input logic wb_ready,
    input logic branch_ready,
    output signal_pkg::ex_to_wb_signal_t alu_result,
    output signal_pkg::alu_to_wb_branch_signal_t branch_result

);

    storage_pkg::alu_holding_reg_t  current_alu_res, hold_reg;
    signal_pkg::alu_to_wb_branch_signal_t branch_result_q;
    signal_pkg::ex_to_wb_signal_t alu_result_q;

    logic ex_ready_q, holding_val, holding_branch;
    logic res_to_op, res_to_hold, hold_to_op, op_valid, hold_next, ready;
    logic a_lt_b, a_lt_b_u, a_eq_b;
    instr_pkg::data_t operand_b;

    always_comb begin // combinationally building the output
        
        current_alu_res.valid = dispatched_op.valid && !branch_valid;
        current_alu_res.prf_tag = dispatched_op.prf_tag;
        current_alu_res.rob_id = dispatched_op.rob_id;
        current_alu_res.data = '0;
        current_alu_res.branch_taken = 1'b0;
        current_alu_res.branch_valid = dispatched_op.valid && dispatched_op.operation[3];

        a_lt_b = ($signed(dispatched_op.operand_a) < $signed(dispatched_op.operand_b)) ? 1'b1 : 1'b0;
        a_lt_b_u = (dispatched_op.operand_a < dispatched_op.operand_b) ? 1'b1 : 1'b0;
        a_eq_b = (dispatched_op.operand_a == dispatched_op.operand_b) ? 1'b1 : 1'b0;

        if (dispatched_op.operation.alu == ALU_ADD && dispatched_op.sign) begin
            operand_b = (~dispatched_op.operand_b) + 1; // 2s complement for subtraction
        end
        else operand_b = dispatched_op.operand_b; // for the rest

        unique case (dispatched_op.operation.alu)
            ALU_ADD : current_alu_res.data = dispatched_op.operand_a + operand_b;
            ALU_SLL : current_alu_res.data = dispatched_op.operand_a << dispatched_op.operand_b;
            ALU_SLT : current_alu_res.data[0] = a_lt_b;
            ALU_SLTU: current_alu_res.data[0] = a_lt_b_u;
            ALU_XOR : current_alu_res.data = dispatched_op.operand_a ^ dispatched_op.operand_b;
            ALU_SRL : current_alu_res.data = dispatched_op.operand_a >> dispatched_op.operand_b;
            ALU_OR  : current_alu_res.data = dispatched_op.operand_a | dispatched_op.operand_b;
            ALU_AND : current_alu_res.data = dispatched_op.operand_a & dispatched_op.operand_b;
            ALU_BEQ : current_alu_res.branch_taken = a_eq_b;
            ALU_BNE : current_alu_res.branch_taken = !a_eq_b;
            ALU_BLT : current_alu_res.branch_taken = a_lt_b;
            ALU_BLTU: current_alu_res.branch_taken = a_lt_b_u;
            ALU_BGE : current_alu_res.branch_taken = !a_lt_b;
            ALU_BGEU: current_alu_res.branch_taken = !a_lt_b_u;
        endcase

        // control signals
        // send value from holding register to writeback or branch
        hold_to_wb = holding_val && wb_ready && !holding_val.branch_valid; // send holding reg to output if wb is ready
        hold_to_branch = holding_val && branch_ready && holding_val.branch_valid // send holding reg to branch output

        // send current results directly to writeback or branch
        res_to_op = current_alu_res.valid && !holding_val;
        res_to_wb = res_to_op && (wb_ready && !current_alu_res.branch_valid);
        res_to_branch = res_to_op && (branch_ready && current_alu_res.branch_valid);

        // send result to holding reg if writeback/branch is not ready and holding is empty

        wb_not_ready = !current_alu_res.branch_valid && (hold_to_wb || !wb_ready);
        branch_not_ready = current_alu_res.branch_valid && (hold_to_branch || !branch_ready);
        res_to_hold = current_alu_res.valid && (wb_not_ready || branch_not_ready);

        wb_valid = hold_to_wb || res_to_wb;
        branch_valid = hold_to_branch || res_to_branch;
        hold_next = (holding_val && !(hold_to_wb || hold_to_branch)) || res_to_hold; // next state of holding reg
        ready = res_to_op || res_to_hold;

    end

    always_ff @(posedge clk) begin
        if(!reset_n || flush_i) begin
            
            alu_result_q <= 'd0;
            ex_ready_q <= 1'b1;

            hold_reg <= 'd0;
            holding_val <= 1'b0;

        end
        else begin

            // registering writeback port output
            if(hold_to_wb) begin
                alu_result_q.valid <= hold_reg.valid;
                alu_result_q.rob_id <= hold_reg.rob_id;
                alu_result_q.data <= hold_reg.data;
            end 
            else if(res_to_wb) begin
                alu_result_q.valid <= current_alu_res.valid;
                alu_result_q.rob_id <= current_alu_res.rob_id;
                alu_result_q.data <= current_alu_res.data;
            end
            else alu_result_q <= 'd0;

            // registering branch port output
            if(hold_to_branch) begin
                branch_result_q.valid <= hold_reg.valid;
                branch_result_q.rob_id <= hold_reg.rob_id;
                branch_result_q.branch_taken <= hold_reg.branch_taken;
            end
            else if(res_to_branch) begin
                branch_result_q.valid <= current_alu_res.valid;
                branch_result_q.rob_id <= current_alu_res.rob_id;
                branch_result_q.branch_taken <= current_alu_res.branch_taken;
            end
            else branch_result_q <= 'd0;

            // updating hold register (if needed)
            if(res_to_hold) hold_reg <= current_alu_res;
            holding_val <= hold_next;

            ex_ready_q <= ready;
        end
            
    end

    assign ex_ready = ex_ready_q;
    assign alu_result = alu_result_q;
    assign branch_result = branch_result_q;

endmodule