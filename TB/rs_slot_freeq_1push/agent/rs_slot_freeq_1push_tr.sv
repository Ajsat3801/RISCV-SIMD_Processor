
class rs_slot_freeq_1push_tr extends uvm_object;

    rand T push_data;
    rand bit push;
    rand bit pop;
    bit reset_n;

    T data_out;
    bit full;
    bit empty;

    `uvm_object_utils(rs_slot_freeq_1push_tr)

    function new(name="rs_slot_freeq_1push_tr");
        super.new(name);
    endfunction

endclass