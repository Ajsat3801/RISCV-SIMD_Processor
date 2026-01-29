`include "typedefs.sv"
import instr_desc::*;

module scalar_registers(
    input logic clk,
    input logic reset_n,

    // From ROB
    input logic write_enable,
    input wb_desc_t wb_data,

    // From Instruction Queue
    instr_to_reg_t instr,

    // To Issue logic
    operation_bus_if.Registers rs_data_reg
);

logic[31:0] reg_arr[31:0];
logic[31:0] operand_a_q, operand_b_q;
logic reg_input_valid_q;
chip_select_e cs_reg_q;

always_ff @(  posedge clk ) begin
    
    if(!reset_n) begin
        for(int i=0; i<32; i=i+1) begin
            reg_arr[i] <= 32'b0;
        end
        operand_a_q <= 32'b0;
        operand_b_q <= 32'b0;
        cs_reg_q <= 0;
        reg_input_valid_q <= 1;
    end
    
    else begin
        // writing to the register
        if(write_enable && wb_data.rd != 0) reg_arr[wb_data.rd] <= wb_data.wb_data;

        // reading RS1
        if(instr.read_operand_a) begin
            if(instr.operand_a_addr == 5'b0) operand_a_q <= 32'b0;
            else if(write_enable && wb_data.rd == instr.operand_a_addr) operand_a_q <= wb_data.wb_data;
            else operand_a_q <= reg_arr[instr.operand_a_addr];
        end

        // reading RS2
        if(instr.read_operand_b) begin
            if(instr.operand_b_addr == 5'b0) operand_b_q <= 32'b0;
            else if(write_enable && wb_data.rd == instr.operand_b_addr) operand_b_q <= wb_data.wb_data;
            else operand_b_q <= reg_arr[instr.operand_b_addr];
        end
        else if(instr.bypass_operand_b) begin
            operand_b_q <= instr.operand_b_in;
        end

        cs_reg_q <= instr.cs_reg;
        reg_input_valid_q <= instr.read_operand_a || instr.read_operand_b || instr.bypass_operand_b;
    end
    
end

assign rs_data_reg.operand_a = operand_a_q;
assign rs_data_reg.instr.operand_b = operand_b_q;
assign rs_data_reg.reg_chip_select = cs_reg_q;
assign rs_data_reg.reg_input_valid = reg_input_valid_q;

endmodule