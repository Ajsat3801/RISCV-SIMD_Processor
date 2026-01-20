/*
    Scalar ALU:

    Inputs: operation, destination registers, 2 operands
    Outputs: if result is valid, destination register, ALU result

    Truth tables
    If(wb_ready){
        if(input && !holding) -> Send input to output
        else if(!input && holding) -> send holding to output
        else if(!input && !holding) -> do nothing
        else -> error condition

    }
    else {
        if(input && !holding) -> send input to holding
        if(!input && holding) -> wait for wb_ready to be 1
        if(!input && !holding) -> do nothing
        else -> error condition
    }

*/

module scalar_alu(
    input logic clk,
    input logic reset_n,

    // connection to reservation station
    input rs_dispatch_t dispatched_op,
    input logic dispatched_op_valid,
    output logic ex_ready,

    // xonnection to writeback arbitrer
    input logic wb_ready,
    output wb_desc_t alu_result,
    output logic alu_result_valid

);

wb_desc_t alu_result_q, current_alu_res, hold_reg;
logic alu_result_valid_q, ex_ready_q, holding_val, valid_instr;

always_comb begin // combinationally building the output
    valid_instr = 1;
    current_alu_res.Rob_ID = dispatched_op.Rob_ID;
    case(dispatched_op.operation.alu) 
        ALU_ADD: current_alu_res.wb_data = dispatched_op.operand_a + dispatched_op.operand_b;
        ALU_SUB: current_alu_res.wb_data = dispatched_op.operand_a - dispatched_op.operand_b;
        ALU_SLT: current_alu_res.wb_data = ($signed(dispatched_op.operand_a) < $signed(dispatched_op.operand_b)) ? 32'b1 : 32'b0;
        ALU_SLTU: current_alu_res.wb_data = (dispatched_op.operand_a < dispatched_op.operand_b) ? 32'b1 : 32'b0;
        ALU_XOR: current_alu_res.wb_data = dispatched_op.operand_a ^ dispatched_op.operand_b;
        ALU_OR: current_alu_res.wb_data = dispatched_op.operand_a | dispatched_op.operand_b;
        ALU_AND: current_alu_res.wb_data = dispatched_op.operand_a & dispatched_op.operand_b;
        default : begin
            current_alu_res.wb_data = 32'b0;
            valid_instr = 0;
        end
    endcase
end

always_ff @(posedge clk) begin
    if(!reset_n) begin
        // reset logic
        
        alu_result_q.Rob_ID <= 5'b0;
        alu_result_q.wb_data <= 32'b0;
        alu_result_valid_q <= 1'b0;
        ex_ready_q <= 1'b1;

        hold_reg.Rob_ID <= 5'b0;
        hold_reg.wb_data <= 32'b0;
        holding_val <= 1'b0;

        ex_ready_q <= 1;

    end
    else if(wb_ready) begin
        alu_result_valid_q <= holding_val || (dispatched_op_valid && valid_instr);

        if(holding_val) begin
            alu_result_q <= hold_reg;
            if(dispatched_op_valid && valid_instr) begin
                hold_reg <= current_alu_res;
                holding_val <= 1;
            end
            else holding_val <= 0;
        end
        else begin
            alu_result_q <= current_alu_res;
            holding_val <=0;
        end

    end 

    else begin
        alu_result_valid_q <= 0;
        if(!dispatched_op_valid) ex_ready_q <= !holding_val;
        if(dispatched_op_valid && valid_instr && !holding_val) begin // send result to holding
            hold_reg <= current_alu_res;
            holding_val <= 1;
        end
    end

    ex_ready_q <= wb_ready || (!dispatched_op_valid && !holding_val);
        
end

assign ex_ready = ex_ready_q;
assign alu_result = alu_result_q;
assign alu_result_valid = alu_result_valid_q;


endmodule