
class lib_fifo_fwft_1push_base_seq extends uvm_sequence #(lib_fifo_fwft_1push_tr);

    `uvm_object_param_utils(lib_fifo_fwft_1push_base_seq)

    function new(string name = "lib_fifo_fwft_1push_base_seq");
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