
class circular_fifo_fwft_sequence_random50 #(
    parameter int BUFFER_SIZE = 8,
    parameter type T = logic[31:0]
) extends circular_fifo_fwft_sequence #(
    .BUFFER_SIZE(BUFFER_SIZE),
    .T(T)
);

    `uvm_object_param_utils(circular_fifo_fwft_sequence_random50 #(BUFFER_SIZE, T))

    function new(string name = "circular_fifo_fwft_sequence_random50");
        super.new(name);
    endfunction

    virtual task generate_sequence();
        
        circular_fifo_fwft_transaction #(T) tr;

        repeat(50) begin
            tr = circular_fifo_fwft_transaction #(T)::type_id::create("tr");
            
            start_item(tr); // wait for sequencer/driver to be ready
            if(!tr.randomize()) `uvm_error("SEQ","Randomization Failed")
            finish_item(tr); //send to driver and wait for completion
        end

    endtask
endclass