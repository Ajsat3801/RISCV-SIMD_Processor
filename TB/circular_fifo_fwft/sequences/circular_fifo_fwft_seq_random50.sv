
class circular_fifo_fwft_seq_random50 extends circular_fifo_fwft_base_seq;

    `uvm_object_utils(circular_fifo_fwft_seq_random50)

    function new(string name = "circular_fifo_fwft_seq_random50");
        super.new(name);
    endfunction

    task generate_seq();
        
        circular_fifo_fwft_tr tr;

        repeat(50) begin
            tr = circular_fifo_fwft_tr::type_id::create("tr");
            
            start_item(tr); // wait for sequencer/driver to be ready
            if(!tr.randomize()) `uvm_error("SEQ","Randomization Failed")
            finish_item(tr); //send to driver and wait for completion
        end

    endtask
endclass