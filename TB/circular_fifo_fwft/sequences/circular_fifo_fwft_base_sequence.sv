
class circular_fifo_fwft_base_sequence extends uvm_sequence #(circular_fifo_fwft_transaction);

    `uvm_object_param_utils(circular_fifo_fwft_base_sequence)

    function new(string name = "circular_fifo_fwft_base_sequence");
        super.new(name);
    endfunction

    virtual task generate_sequence();
        `uvm_fatal("SEQ","Generate_sequence() not overwritten")
    endtask

    virtual task body();
        `uvm_info("SEQ","Starting Sequence", UVM_HIGH)
        generate_sequence();
        `uvm_info("SEQ","Sequence complete", UVM_HIGH)
    endtask

endclass