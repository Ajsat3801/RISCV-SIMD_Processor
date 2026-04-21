
module imem #(
    parameter int unsigned NUM_WORDS,
    parameter int unsigned WORD_SIZE
) (
    input logic clk_i,
    input logic reset_ni,

    input logic write_enable,
    input logic[$clog2(NUM_WORDS)-1:0] address,
    input logic[WORD_SIZE:0] data_in,

);



endmodule