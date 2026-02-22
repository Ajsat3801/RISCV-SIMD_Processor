/*
    Instruction memory for the processor
    TODO: Determine size of the IMEM.
*/

module imem(
    parameter DEPTH = 512,
    parameter addr_width = $clog2(DEPTH)
){
    input logic clk,
    input logic[addr_width-1:0] addr,
    output logic instr
}

logic[31:0] PC;
logic[31:0] IMEM[DEPTH]

assign addr
endmodule 