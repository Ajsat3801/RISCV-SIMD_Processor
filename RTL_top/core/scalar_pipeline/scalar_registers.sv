/*
    Scalar registers for the processor

    32x32 registers
    2 reads and 1 write in each cycle

    Characteristics:
    ->  sychronous operation; returns output in next cycle
    ->  register 0 will always be 0 and cannot be touched
    ->  forwarding of RD data done if RS1 or RS2 is same as RD

    TODO:
    1) Bypass logic for chip select, rd_address and operation
    2) Integrate busyboard into the registers
    3) Holding registers for 
*/
`include "typedefs.sv"
import instr_desc::*;

module scalar_registers(
    input logic clk,
    input logic reset_n,

    // From ROB
    input logic write_enable,
    input wb_desc_t wb_data,

    // From Instruction Queue
    input logic[4:0] rs1_addr,
    input logic[4:0] rs2_addr,
    chip_select_e cs_input,

    // To Issue logic
    output logic[31:0] rs1_data,
    output logic[31:0] rs2_data,
    output chip_select_e cs_registers,
);

logic[31:0] reg_arr[31:0];
logic[31:0] rs1_data_q, rs2_data_q;
chip_select_e cs_registers_q;

always_ff @(  posedge clk ) begin
    
    if(!reset_n) begin
        for(int i=0; i<32; i=i+1) begin
            reg_arr[i] <= 32'b0;
        end
        rs1_data_q <= 32'b0;
        rs2_data_q <= 32'b0;
        cs_registers_q <= 0;
    end
    
    else begin
        // writing to the register
        if(write_enable && wb_data.rd != 0) reg_arr[wb_data.rd] <= wb_data.wb_data;

        // reading RS1
        if(rs1_addr == 5'b0) rs1_data_q <= 32'b0;
        else if(write_enable && wb_data.rd == rs1_addr) rs1_data_q <= wb_data.wb_data;
        else rs1_data_q <= reg_arr[rs1_addr];

        // reading RS2
        if(rs2_addr == 5'b0) rs2_data_q <= 32'b0;
        else if(write_enable && wb_data.rd == rs2_addr) rs2_data_q <= wb_data.wb_data;
        else rs2_data_q <= reg_arr[rs2_addr];

        cs_registers_q <= cs_input;
    end
    
end

assign rs1_data = rs1_data_q;
assign rs2_data = rs2_data_q;
assign cs_registers = cs_registers_q;

endmodule