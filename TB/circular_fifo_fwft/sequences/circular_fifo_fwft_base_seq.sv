
class circular_fifo_fwft_base_seq extends uvm_sequence #(circular_fifo_fwft_tr);

    `uvm_object_param_utils(circular_fifo_fwft_base_seq)

    function new(string name = "circular_fifo_fwft_base_seq");
        super.new(name);
    endfunction

    virtual task generate_seq();
        `uvm_fatal("SEQ","Generate_seq() not overwritten")
    endtask

    virtual task body();
        `uvm_info("SEQ","Starting Sequence", UVM_HIGH)
        generate_seq();
        `uvm_info("SEQ","Sequence complete", UVM_HIGH)
    endtask

endclass