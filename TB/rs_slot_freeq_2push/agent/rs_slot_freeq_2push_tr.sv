
import lib_rs_slot_freeq_2push_tb_config_pkg::*;

class lib_rs_slot_freeq_2push_tr extends uvm_sequence_item;

    rand T push_data1, push_data2;
    rand bit push1, push2, pop;

    T data_out;    
    bit reset_n, full, empty;

    `uvm_object_utils(lib_rs_slot_freeq_2push_tr)

    function new(string name="lib_rs_slot_freeq_2push_tr");
        super.new(name);
    endfunction


endclass