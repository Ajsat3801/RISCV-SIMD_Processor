/*
    Scalar registers for the processor

    32x32 registers
    2 reads and 1 write in each cycle

    Characteristics:
    ->  sychronous operation; returns output in next cycle
    ->  register 0 will always be 0 and cannot be touched
    ->  forwarding of RD data done if RS1 or RS2 is same as RD

*/

module RTL_Registers(
    input logic clk,

    // FROM WRITEBACK
    input logic write_enable,
    input logic[4:0] rd,
    input logic[31:0] rd_data,

    // FROM DECODE
    input logic[4:0] x_rs1,
    input logic[4:0] x_rs2,
    output logic[31:0] rs1_data,
    output logic[31:0] rs2_data
);

logic[31:0] reg_addr[32];

always_ff @(  posedge clk ) begin
    
    // writing to the register
    if(write_enable && rd ! = 0) reg_addr[rd] <= rd_data;

    // reading RS1
    if(x_rs1 != 5'b0) op1 <= 32'b0;
    else if(write_enable && rd == x_rs1) op1 <= rd_data;
    else op1 <= reg_addr[x_rs1];

    // reading RS2
    if(x_rs2 != 5'b0) op2 <= 32'b0;
    else if(write_enable && rd == x_rs2) op2 <= rd_data;
    else op2 <= reg_addr[x_rs2];

end

assign rs1_data = op1;
assign rs2_data = op2;

endmodule