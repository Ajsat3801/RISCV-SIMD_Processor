import lib_circular_fifo_fwft_tb_config_pkg::*;

class lib_circular_fifo_fwft_tr extends uvm_sequence_item;

    // Randomizable Fields
    rand T    push_data;
    rand bit  push;
    rand bit  pop;

    T data_out;
  	bit full;
  	bit empty;

    `uvm_object_utils(lib_circular_fifo_fwft_tr)

    function new(string name = "lib_circular_fifo_fwft_tr");
        super.new(name);
    endfunction

    // Constraints come here if any. No constraints in this case
    
endclass