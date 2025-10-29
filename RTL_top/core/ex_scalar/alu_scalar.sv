/*
    Scalar ALU:

    Inputs: operation, destination registers, 2 operands
    Outputs: if result is valid, destination register, ALU result

    TODO: 
    1) ADD BUSY LOGIC TO SEND TO QUEUES
    2) ADD VALID AS INPUT FOR ALU

    Understanding the behavior:
    If alu_input_valid is 0 -> do nothing
    else:
        set alu_ready to 0
        do the ops
        if wb_ready is 1:
            assign output to current values
            set alu_ready to 1
        else :
            send values to holding registers
            alu_ready has to be 1



*/

/*
Code for the ALU Ops
case(alu_input.operation) 
    ADD: result <= alu_input.operand_a + alu_input.operand_b;
    SUB: result <= alu_input.operand_a - alu_input.operand_b;
    SLT: result <= ($signed(alu_input.operand_a) < $signed(alu_input.operand_b)) ? 32'b1 : 32'b0;
    SLTU: result <= (alu_input.operand_a < alu_input.operand_b) ? 32'b1 : 32'b0;
    XOR: result <= alu_input.operand_a ^ alu_input.operand_b;
    OR: result <= alu_input.operand_a | alu_input.operand_b;
    AND: result <= alu_input.operand_a & alu_input.operand_b;
    default : begin
        result <= 32'b0;
        valid <= 0;
    end
endcase
*/

module scalar_ALU(
    input logic clk,

    // CONNECTIONS BETWEEN SALU AND SALU QUEUE
    input alu_desc_t alu_input,
    input logic alu_input_valid,
    output logic alu_ready,

    // CONNECTIONS BETWEEN SALU AND SCALAR WB
    input logic wb_ready,
    output wb_desc_t alu_result,
    output logic alu_result_valid

);


always_ff @(posedge clk) begin
    
    
end




endmodule