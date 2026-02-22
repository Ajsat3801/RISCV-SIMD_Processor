/*
    Scalar ALU:

    Inputs: operation, destination registers, 2 operands
    Outputs: if result is valid, destination register, ALU result


ALU OPERATIONS CODES
CODE    ALU_OPERATION           INSTRUCTIONS
0 000 - ALL_ADD                 ADD, ADDI, JAL
0 001 -                                             <originally SLL, SLLI>
0 010 - ALU_SLT                 SLT, SLTI
0 011 - ALU_SLTU                SLTU, SLTIU
0 100 - ALU_XOR                 XOR, XORI
0 101 -                                             <originally SRL SRLI>
0 110 - ALU_OR                  OR, ORI
0 111 - ALU_AND                 AND, ANDI
1 000 - ALU_BEQ
1 001 -
1 010 - ALU_BNE
1 011 -                         
1 100 - ALU_BLT
1 101 - ALU_BGE
1 110 - ALU_BLTU
1 111 - ALU_BGEU

Undecided on SUB. Should we do ADD + sign bit or give seperate code.


*/

module scalar_alu(
    input logic clk,
    input logic reset_n,

    // connection to reservation station
    input rs_dispatch_t dispatched_op,
    input logic dispatched_op_valid,
    output logic ex_ready,

    //connection to writeback arbitrer
    input logic wb_ready,
    output wb_desc_t alu_result,
    output logic alu_result_valid

);

wb_desc_t alu_result_q, current_alu_res, hold_reg;
logic alu_result_valid_q, ex_ready_q, holding_val, res_valid;
logic res_to_op, res_to_hold, hold_to_op, op_valid, hold_next, ready;

always_comb begin // combinationally building the output
    res_valid = dispatched_op_valid;
    current_alu_res.ROB_id = dispatched_op.ROB_id;

    a_lt_b = ($signed(dispatched_op.operand_a) < $signed(dispatched_op.operand_b)) ? 32'b1 : 32'b0;
    a_lt_b_u = (dispatched_op.operand_a < dispatched_op.operand_b) ? 32'b1 : 32'b0;
    a_eq_b = (dispatched_op.operand_a == dispatched_op.operand_b) ? 32'b1 : 32'b0;

    unique case (dispatched_op.operation.alu)
        ALU_ADD : current_alu_res.wb_data = dispatched_op.operand_a + dispatched_op.operand_b;
        ALU_SUB : current_alu_res.wb_data = dispatched_op.operand_a - dispatched_op.operand_b;
        ALU_SLT : current_alu_res.wb_data = a_lt_b;
        ALU_SLTU: current_alu_res.wb_data = a_lt_b_u;
        ALU_XOR : current_alu_res.wb_data = dispatched_op.operand_a ^ dispatched_op.operand_b;
        ALU_OR  : current_alu_res.wb_data = dispatched_op.operand_a | dispatched_op.operand_b;
        ALU_AND : current_alu_res.wb_data = dispatched_op.operand_a & dispatched_op.operand_b;
        ALU_BEQ : current_alu_res.wb_data = a_eq_b;
        ALU_BNE : current_alu_res.wb_data = !a_eq_b;
        ALU_BLT : current_alu_res.wb_data = a_lt_b;
        ALU_BLTU: current_alu_res.wb_data = a_lt_b_u;
        ALU_BGE : current_alu_res.wb_data = !a_lt_b;
        ALU_BGEU: current_alu_res.wb_data = !a_lt_b_u;
        
        default : begin
            current_alu_res.wb_data = 32'b0;
            res_valid = 1'b0;
        end
    endcase

    hold_to_op = wb_ready && holding_val; // send holding reg to output if wb is ready
    res_to_op = res_valid && !holding_val && wb_ready; // send result to holding reg if writeback is not ready and holding is empty
    res_to_hold = res_valid && (hold_to_op || !wb_ready); // send result to holding register if holding instr is out or wb is not ready
    op_valid = hold_to_op || res_to_op;
    hold_next = (holding_val && !hold_to_op) || res_to_hold; // next state of holding reg
    ready = res_to_op || res_to_hold;

end

always_ff @(posedge clk) begin
    if(!reset_n) begin
        
        alu_result_q <= 'd0;
        alu_result_valid_q <= 1'b0;
        ex_ready_q <= 1'b1;

        hold_reg <= 'd0;
        holding_val <= 1'b0;

    end
    else begin

        if(hold_to_op) alu_result_q <= hold_reg;
        else if(res_to_op) alu_result_q <= current_alu_res;
        else alu_result_q <= 'd0;

        if(res_to_hold) hold_reg <= current_alu_res;

        holding_val <= hold_valid;
        ex_ready_q <= ready;
        alu_result_valid_q <= op_valid;
    end
        
end

assign ex_ready = ex_ready_q;
assign alu_result = alu_result_q;
assign alu_result_valid = alu_result_valid_q;


endmodule