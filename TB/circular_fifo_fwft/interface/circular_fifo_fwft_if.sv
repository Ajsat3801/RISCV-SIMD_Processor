import lib_fifo_fwft_1push_tb_config_pkg::*;

interface lib_fifo_fwft_1push_if (
    input logic clk
);

    logic reset_n;
    logic push, pop;
    T push_data, data_out;
    logic full, empty;

    clocking drv_cb @(posedge clk);
        default input #1ns output #1ns;

        output reset_n;

        output push;
        output push_data;
        output pop;

        input data_out;
        input full;
        input empty;

    endclocking

    clocking mon_cb @(posedge clk);
        default input #0;

        input reset_n;
        input push;
        input push_data;
        input pop;

        input data_out;
        input full;
        input empty;

    endclocking

    modport driver (clocking drv_cb, input reset_n);
    modport monitor (clocking mon_cb, input reset_n);

endinterface