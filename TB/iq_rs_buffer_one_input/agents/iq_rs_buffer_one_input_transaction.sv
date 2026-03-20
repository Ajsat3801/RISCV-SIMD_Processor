
class iq_rs_buffer_one_input_transaction #(
    parameter type T = logic[31:0]
) extends uvm_object;

    rand T push_data;
    rand bit push;
    rand bit pop;
    bit reset_n;

    T data_out;
    bit full;
    bit empty;

    `uvm_object_param_utils(iq_rs_buffer_one_input_transaction #(T))
        `uvm_field_int(push, UVM_ALL_ON)
        `uvm_field_int(pop, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(name="iq_rs_buffer_one_input_transaction");
        super.new(name);
    endfunction

endclass