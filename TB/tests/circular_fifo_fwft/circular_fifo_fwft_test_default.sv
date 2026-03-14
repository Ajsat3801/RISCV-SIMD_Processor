
class circular_fifo_fwft_test_default 
extends circular_fifo_fwft_test #(
  	.BUFFER_SIZE(8),
  	.T(logic[31:0])
);

    `uvm_component_utils(circular_fifo_fwft_test_default);

    function new(string name = "circular_fifo_fwft_test_default", uvm_component parent = null);
        super.new(name,parent);
    endfunction

endclass
