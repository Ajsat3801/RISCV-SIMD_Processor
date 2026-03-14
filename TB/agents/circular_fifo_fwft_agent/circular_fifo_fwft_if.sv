
interface circular_fifo_fwft_if #(
    parameter int BUFFER_SIZE = 8,
    parameter type T = logic[31:0]
) (
    input logic clk
);

logic reset_n;
logic push, pop;
T push_data, data_out;
logic full, empty;

clocking cb @(posedge clk);
    default input #1ns output #1ns;

    output reset_n;

    output push;
    output push_data;
    output pop;

    input data_out;
    input full;
    input empty;

endclocking

modport driver (clocking cb, input reset_n);

modport monitor (input clk, reset_n, push, pop, push_data,
                data_out, full, empty);


endinterface