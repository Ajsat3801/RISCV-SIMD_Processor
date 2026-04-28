class lib_circular_fifo_fwft_sqr extends uvm_sequencer #(lib_circular_fifo_fwft_tr);

    `uvm_component_param_utils(lib_circular_fifo_fwft_sqr)

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

endclass