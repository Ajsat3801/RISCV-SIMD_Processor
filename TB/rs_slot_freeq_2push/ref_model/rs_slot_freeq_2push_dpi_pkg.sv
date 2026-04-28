
package lib_rs_slot_freeq_2push_dpi_pkg;

    import "DPI-C" function void lib_rs_slot_freeq_2push_create_model(
        int size,
        int numwords
    );

    import "DPI-C" function void lib_rs_slot_freeq_2push_run_model(
        input bit reset_n,    
        input bit[159:0] push_data1,
        input bit[159:0] push_data2,
        input bit push1,
        input bit push2,
        input bit pop,
        output bit[159:0] data_out,
        output bit fifo_full,
        output bit fifo_empty
    );

endpackage