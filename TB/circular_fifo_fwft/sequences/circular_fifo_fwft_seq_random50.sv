
class lib_fifo_fwft_1push_seq_random50 extends lib_fifo_fwft_1push_base_seq;

    `uvm_object_utils(lib_fifo_fwft_1push_seq_random50)

    function new(string name = "lib_fifo_fwft_1push_seq_random50");
        super.new(name);
    endfunction

    task generate_seq();
        
        lib_fifo_fwft_1push_tr tr;

        repeat(50) begin
            tr = lib_fifo_fwft_1push_tr::type_id::create("tr");
            
            start_item(tr); // wait for sequencer/driver to be ready
            if(!tr.randomize()) `uvm_error("SEQ","Randomization Failed")
            finish_item(tr); //send to driver and wait for completion
        end

    endtask
endclass