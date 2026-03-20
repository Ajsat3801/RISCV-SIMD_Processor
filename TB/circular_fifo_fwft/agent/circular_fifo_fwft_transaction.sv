import circular_fifo_fwft_tb_config_pkg::*;

class circular_fifo_fwft_transaction extends uvm_sequence_item;

    // Randomizable Fields
    rand T    push_data;
    rand bit  push;
    rand bit  pop;

    T data_out;
  	bit full;
  	bit empty;

    `uvm_object_utils(circular_fifo_fwft_transaction)

    function new(string name = "circular_fifo_fwft_transaction");
        super.new(name);
    endfunction

    // Constraints come here if any. No constraints in this case
    
endclass