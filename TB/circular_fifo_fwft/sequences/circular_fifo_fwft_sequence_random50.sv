
class circular_fifo_fwft_sequence_random50 extends circular_fifo_fwft_base_sequence;

    `uvm_object_utils(circular_fifo_fwft_sequence_random50)

    function new(string name = "circular_fifo_fwft_sequence_random50");
        super.new(name);
    endfunction

    virtual task generate_sequence();
        
        circular_fifo_fwft_transaction tr;

        repeat(50) begin
            tr = circular_fifo_fwft_transaction::type_id::create("tr");
            
            start_item(tr); // wait for sequencer/driver to be ready
            if(!tr.randomize()) `uvm_error("SEQ","Randomization Failed")
            finish_item(tr); //send to driver and wait for completion
        end

    endtask
endclass