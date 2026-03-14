class circular_fifo_fwft_sequencer #(
    parameter type T = logic[31:0]
) extends uvm_sequencer #(circular_fifo_fwft_transaction #(T));

    `uvm_component_param_utils(circular_fifo_fwft_sequencer #(T))

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

endclass