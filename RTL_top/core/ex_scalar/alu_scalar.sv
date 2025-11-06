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

module scalar_ALU(
    input logic clk,
    input logic resetn,

    // CONNECTIONS BETWEEN SALU AND SALU QUEUE
    input alu_desc_t alu_input,
    input logic alu_input_valid,
    output logic alu_ready,

    // CONNECTIONS BETWEEN SALU AND SCALAR WB
    input logic wb_ready,
    output wb_desc_t alu_result,
    output logic alu_result_valid

);

wb_desc_t alu_result_q, hold_reg;
logic alu_result_valid_q, alu_ready_q, holding_val, valid_instr;



always_ff @(posedge clk) begin
    if(!resetn) begin
        // reset logic
        
        alu_result_q.rd <= 5'b0;
        alu_result_q.wb_data <= 32'b0;
        alu_result_valid_q <= 1'b0;
        alu_ready_q <= 1'b1;

        hold_reg.rd <= 5'b0;
        hold_reg.wb_data <= 32'b0;
        holding_val <= 1'b0;
        valid_instr <= 1'b1;

    end
    else begin
        valid_instr <= 1;
        case(alu_input.operation) 
            ADD: alu_result_q.wb_data <= alu_input.operand_a + alu_input.operand_b;
            SUB: alu_result_q.wb_data <= alu_input.operand_a - alu_input.operand_b;
            SLT: alu_result_q.wb_data <= ($signed(alu_input.operand_a) < $signed(alu_input.operand_b)) ? 32'b1 : 32'b0;
            SLTU: alu_result_q.wb_data <= (alu_input.operand_a < alu_input.operand_b) ? 32'b1 : 32'b0;
            XOR: alu_result_q.wb_data <= alu_input.operand_a ^ alu_input.operand_b;
            OR: alu_result_q.wb_data <= alu_input.operand_a | alu_input.operand_b;
            AND: alu_result_q.wb_data <= alu_input.operand_a & alu_input.operand_b;
            default : begin
                alu_result_q.wb_data <= 32'b0;
                valid_instr <= 0;
            end
        endcase

        if(wb_ready) begin
            
            if(!holding_val) alu_result_valid_q <= alu_input_valid; // send result directly to output if it's valid
            
            else if(!alu_input_valid && holding_val) begin
                alu_result_q <= hold_reg;
                alu_result_valid_q <= 1'b1;
            end
            else alu_result_valid_q <= 0;

            alu_ready_q <= 1;
            holding_val <=0;

        end
        else begin
            if(!alu_input_valid) alu_ready_q <= !holding_val;
            if(alu_input_valid && !holding_val) begin // send result to holding
                hold_reg <= alu_result_q;
                holding_val <= 1;
                alu_ready_q <= 0;
            end
            alu_result_valid_q <= 0;
        end
        
    end
    
end

assign alu_ready = alu_ready_q;
assign alu_result = alu_result_q;
assign alu_result_valid = alu_result_valid_q;


endmodule