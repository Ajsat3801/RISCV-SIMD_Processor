import rs_slot_freeq_2push_tb_config_pkg::*;

interface rs_slot_freeq_2push_if (input logic clk);

T push_data1, push_data2, data_out;
logic reset_n, push1, push2, pop, empty, full;

clocking drv_cb @(posedge clk);

    default input #1step output #0;

    output reset_n;
    
    output push1;
    output push2;
    output push_data1;
    output push_data2;

    output pop;

    input data_out;
    input empty;
    input full;

endclocking

clocking mon_cb @(posedge clk);

    default input #1step output #0;

    input reset_n;
    input push_1;
    input push_2;
    input push_data1;
    input push_data2;
    input pop;
    input data_out;
    input empty;
    input full;

endclocking


endinterface