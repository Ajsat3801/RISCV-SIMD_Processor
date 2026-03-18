
class circular_fifo_fwft_sequence #(
    parameter int BUFFER_SIZE = 8,
    parameter type T = logic[31:0]
) extends uvm_sequence #(circular_fifo_fwft_transaction #(T));

    `uvm_object_param_utils(circular_fifo_fwft_sequence #(BUFFER_SIZE, T))

    function new(string name = "circular_fifo_fwft_sequence");
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