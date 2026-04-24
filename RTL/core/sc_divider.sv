
module sc_divider (
    input logic clk_i,
    input logic reset_ni,
    input logic [31:0] dividend_i,
    input logic [31:0] divisor_i,
    input logic unsigned_div,
    input logic valid_i,
    output logic[63:0] result_o,
    output logic valid_o
);

endmodule