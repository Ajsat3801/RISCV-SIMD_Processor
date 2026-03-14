
class circular_fifo_fwft_sequence #(
    parameter int BUFFER_SIZE = 8,
  parameter type T = logic[31:0]
) extends uvm_sequence;

    `uvm_object_param_utils(circular_fifo_fwft_sequence #(BUFFER_SIZE, T))

    function new(string name = "circular_fifo_fwft_sequence");
        super.new(name);
    endfunction

    virtual task body();

        circular_fifo_fwft_transaction #(T) tr;

        `uvm_info("SEQ","Starting randomized FIFO sequence", UVM_LOW)

        repeat(50) begin

          tr = circular_fifo_fwft_transaction #(T)::type_id::create("tr");

            start_item(tr); // wait for sequencer/driver to be ready
            
            if(!tr.randomize()) `uvm_error("SEQ","Randomization Failed")

            finish_item(tr); //send to driver and wait for completion

        end

        `uvm_info("SEQ","Sequence complete", UVM_LOW)

    endtask
endclass