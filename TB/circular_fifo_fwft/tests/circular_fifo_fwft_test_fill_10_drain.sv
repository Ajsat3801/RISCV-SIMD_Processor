
class circular_fifo_fwft_test_fill_10_drain extends circular_fifo_fwft_base_test;

    `uvm_component_utils(circular_fifo_fwft_test_fill_10_drain)

    function new(string name="circular_fifo_fwft_test_fill_10_drain", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    task run_sequence();
        circular_fifo_fwft_sequence_fill_10_drain seq;
        seq = circular_fifo_fwft_sequence_fill_10_drain::type_id::create("seq");
        
        `uvm_info("TEST","Starting Fill 10 Drain Test", UVM_LOW)

        super.apply_reset();
        seq.start(env.agt.sqr);
    endtask

endclass