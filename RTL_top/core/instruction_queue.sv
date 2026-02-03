/*
    instruction queue - circular FIFO that accumulates and 
    sends one instruction at a time to the ARR pipeline

    Notes:

*/


`include "typedefs.sv"
import instr_desc::*;

module instruction_queue #(parameter QUEUE_LENGTH=8,NUM_RS=2)(
    input logic clk,
    input logic reset_n,

    // inputs from decode

    // control signals from RS

    // outputs to RAT

    // outputs to ROB

    // outputs to registers


);

endmodule