
module rs_slot_freeq_1push_if (
    input logic clk
);

    logic reset_n;
    T push_data, data_out;
    logic push, pop, full, empty;

    clocking drv_cb @(posedge clk);
        defaut input #1ns output #1ns;

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
        input pop;
        input push_data;

        input data_out;
        input full;
        input empty;

    endclocking

    modport driver (clocking drv_cb);
    modport monitor(clocking mon_cb);

endmodule