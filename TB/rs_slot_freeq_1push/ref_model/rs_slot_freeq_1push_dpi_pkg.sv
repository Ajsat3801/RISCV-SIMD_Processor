package rs_slot_freeq_1push_dpi_pkg;

    import "DPI-C" function void rs_slot_freeq_1push_model_create(
        int size,
        int numwords
    );
    
    import "DPI-C" function void rs_slot_freeq_1push_model_run(
        input bit[159:0] push_data,
        output bit[159:0] data_out,
        input bit push,
        input bit pop,
        output bit full,
        output bit empty,
        input bit reset_n,
        input int numwords
    );

endpackage