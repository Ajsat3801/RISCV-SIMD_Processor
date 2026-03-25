import rs_slot_freeq_1push_tb_config_pkg::*;

class rs_slot_freeq_1push_tr extends uvm_sequence_item;

    rand T push_data;
    rand bit push;
    rand bit pop;
    bit reset_n;

    T data_out;
    bit full;
    bit empty;

    `uvm_object_utils(rs_slot_freeq_1push_tr)

    function new(string name="rs_slot_freeq_1push_tr");
        super.new(name);
    endfunction

endclass