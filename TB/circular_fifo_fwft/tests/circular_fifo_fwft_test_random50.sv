
class circular_fifo_fwft_test_random50 extends circular_fifo_fwft_base_test;

    `uvm_component_utils(circular_fifo_fwft_test_random50);

    function new(string name = "circular_fifo_fwft_test_random50", uvm_component parent = null);
        super.new(name,parent);
    endfunction

    task run_seq();
        circular_fifo_fwft_seq_random50 seq;
        seq = circular_fifo_fwft_seq_random50::type_id::create("seq");

        `uvm_info("TEST","Starting Random 50 Test", UVM_LOW)

		super.apply_reset();
        seq.start(env.agt.sqr); // sequencer starts sending values
    endtask

endclass
