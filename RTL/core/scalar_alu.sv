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
    input signal_pkg::rs_to_alu_signal_t dispatched_op,
    output logic ex_ready,

    //connection to writeback arbitrer
    input logic wb_ready,
    output signal_pkg::ex_to_wb_signal_t alu_result,

);

signal_pkg::ex_to_wb_signal_t alu_result_q, current_alu_res, hold_reg;
logic ex_ready_q, holding_val;
logic res_to_op, res_to_hold, hold_to_op, op_valid, hold_next, ready;
logic a_lt_b, a_lt_b_u, a_eq_b;

always_comb begin // combinationally building the output
    current_alu_res.valid = dispatched_op.valid;
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
            current_alu_res.valid = 1'b0;
        end
    endcase

    hold_to_op = wb_ready && holding_val; // send holding reg to output if wb is ready
    res_to_op = current_alu_res.valid && !holding_val && wb_ready; // send result to holding reg if writeback is not ready and holding is empty
    res_to_hold = current_alu_res.valid && (hold_to_op || !wb_ready); // send result to holding register if holding instr is out or wb is not ready
    op_valid = hold_to_op || res_to_op;
    hold_next = (holding_val && !hold_to_op) || res_to_hold; // next state of holding reg
    ready = res_to_op || res_to_hold;

end

always_ff @(posedge clk) begin
    if(!reset_n) begin
        
        alu_result_q <= 'd0;
        ex_ready_q <= 1'b1;

        hold_reg <= 'd0;
        holding_val <= 1'b0;

    end
    else begin

        if(hold_to_op) alu_result_q <= hold_reg;
        else if(res_to_op) alu_result_q <= current_alu_res;
        else alu_result_q <= 'd0;

        if(res_to_hold) hold_reg <= current_alu_res;

        holding_val <= hold_next;
        ex_ready_q <= ready;
        alu_result_q.valid <= op_valid;
    end
        
end

assign ex_ready = ex_ready_q;
assign alu_result = alu_result_q;


endmodule