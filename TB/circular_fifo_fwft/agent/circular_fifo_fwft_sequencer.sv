class circular_fifo_fwft_sequencer extends uvm_sequencer #(circular_fifo_fwft_transaction);

    `uvm_component_param_utils(circular_fifo_fwft_sequencer)

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

endclass