import lib_rs_slot_freeq_2push_tb_config_pkg::*;
import lib_rs_slot_freeq_2push_dpi_pkg::*;

class lib_rs_slot_freeq_2push_ref_model_adapter;

    local int numwords = ($bits(T)+31)/32;

    function new();
    endfunction

    virtual function void create_model();
        lib_rs_slot_freeq_2push_create_model(BUFFER_SIZE, numwords);
    endfunction

    virtual function void run_model(
        input bit reset_n,
        input T push_data1T,
        input T push_data2T,
        input bit push1,
        input bit push2,
        input bit pop,
        output T data_outT,
        output bit fifo_full,
        output bit fifo_empty
    );

        bit[159:0] push_data1, push_data2, data_out;

        push_data1[$bits(T)-1:0] = push_data1T;
        push_data2[$bits(T)-1:0] = push_data2T;

        lib_rs_slot_freeq_2push_run_model(
            .reset_n(reset_n),
            .push_data1(push_data1),
            .push_data2(push_data2),
            .push1(push1),
            .push2(push2),
            .pop(pop),
            .data_out(data_out),
            .fifo_full(fifo_full),
            .fifo_empty(fifo_empty)
        );

        data_outT = data_out[$bits(T)-1:0];

    endfunction

endclass