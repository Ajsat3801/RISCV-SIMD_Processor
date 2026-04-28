
class lib_rs_slot_freeq_1push_base_seq extends uvm_sequence #(lib_rs_slot_freeq_1push_tr);

    `uvm_object_utils(lib_rs_slot_freeq_1push_base_seq)

    function new(string name = "lib_rs_slot_freeq_1push_base_seq");
        super.new(name);
    endfunction

    virtual task generate_seq();
        `uvm_error("SEQ", "Generate_seq() not overwritten");
    endtask

    virtual task body();
        `uvm_info("SEQ", "Starting sequence generation", UVM_HIGH);
        generate_seq();
        `uvm_info("SEQ", "Sequence generation complete", UVM_HIGH);
    endtask

endclass