/*
    Scalar registers for the processor

    32x32 registers
    2 reads and 1 write in each cycle

    Characteristics:
    ->  sychronous operation; returns output in next cycle
    ->  register 0 will always be 0 and cannot be touched
    ->  forwarding of RD data done if RS1 or RS2 is same as RD

    TODO: Integrate Busyboard with scalar regfile

*/
`include "typedefs.sv"
import instr_desc::*;

module regfile_scalar(
    input logic clk,
    input logic resetn,

    // FROM WRITEBACK
    input logic write_enable,
    input wb_desc_t wb_data,

    // FROM DECODE
    input logic[4:0] rs1_addr,
    input logic[4:0] rs2_addr,
    output logic[31:0] rs1_data,
    output logic[31:0] rs2_data
);

logic[31:0] reg_arr[32];
logic[31:0] rs1_data_q, rs2_data_q;

always_ff @(  posedge clk ) begin
    
    if(!resetn) begin
        for(int i=0; i<32; i=i+1) reg_arr[i] <=32'b0;
        rs1_data_q <= 32'b0;
        rs2_data_q <= 32'b0;
    end
    
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

end

assign rs1_data = rs1_data_q;
assign rs2_data = rs2_data_q;

endmodule