
module imem #(
    parameter int unsigned NUM_WORDS,
    parameter int unsigned WORD_SIZE
) (
    input logic clk_i,
    input logic reset_ni,

    input logic write_enable,
    input address,
    input logic[31:0] data_in,

);



endmodule