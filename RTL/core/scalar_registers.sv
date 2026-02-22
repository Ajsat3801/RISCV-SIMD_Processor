`include "typedefs.sv"
import instr_desc::*;

module scalar_registers(
    input logic clk,
    input logic reset_n,

    // From ROB
    retirement_bus_if.Reg write_data,

    // From Instruction Queue
    input IQ_Reg_t read_data,

    // To Issue logic
    operand_bus_if.Registers rs_data_reg
);

logic[31:0] reg_arr[31:0];
logic[31:0] operand_a_q, operand_b_q, operand_a, operand_b;
logic reg_input_valid_q;

always_comb begin
    operand_a = 32'b0;
    operand_b = 32'b0;

    // combinational read and registered outputs
    if(read_data.valid) begin

        if(read_data.src1_address == 0) operand_a = 32'b0;
        else if(read_data.src1_address == write_data.rd && write_data.instr_valid) operand_a = write_data.data;
        else operand_a = reg_arr[read_data.src1_address];

        if(!read_data.read_src2) operand_b = read_data.imm;
        else if(read_data.src2_address == 0) operand_b = 32'b0;
        else if(read_data.src2_address == write_data.rd && write_data.instr_valid) operand_b = write_data.data;
        else operand_b = reg_arr[read_data.src2_address];

    end


end

always_ff @( posedge clk ) begin
    
    if(!reset_n) begin
        reg_arr[0] <= 32'b0;
        operand_a_q <= 32'b0;
        operand_b_q <= 32'b0;
        reg_input_valid_q <= 0;
    end
    
    else begin
        // writing to the register
        if(write_data.instr_valid && write_data.rd != 0) reg_arr[write_data.rd] <= write_data.data;

        operand_a_q <= operand_a;
        operand_b_q <= operand_b;
        reg_input_valid_q <= read_data.valid;
    end
    
end

assign rs_data_reg.operand_a = operand_a_q;
assign rs_data_reg.operand_b = operand_b_q;
assign rs_data_reg.reg_input_valid = reg_input_valid_q;

endmodule