
class rs_slot_freeq_1push_base_seq extends uvm_sequence #(rs_slot_freeq_1push_tr);

    `uvm_object_utils(rs_slot_freeq_1push_base_seq)

    function void new(string name);
        super.new(name);
    endfunction

    virtual task generate_seq();
        `uvm_error("SEQ", "Generate_seq() not overwritten");
    endtask

    virtual task body()l
        `uvm_info("SEQ", "Starting sequence generation", UVM_HIGH);
        generate_seq();
        `uvm_info("SEQ", "Sequence generation complete", UVM_HIGH);
    endtask

endclass