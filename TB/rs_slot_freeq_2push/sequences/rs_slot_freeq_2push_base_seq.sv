

class rs_slot_freeq_2push_base_seq extends uvm_sequence;

    `uvm_object_utils(rs_slot_freeq_2push_base_seq);

    function new(string name="rs_slot_freeq_2push_base_seq");
        super.new(name);
    endfunction

    virtual task generate_sequence();
        `uvm_fatal("SEQ","generate_sequence not overwritten")
    endtask

    virtual task body();
        `uvm_info("SEQ", "Starting Sequence", UVM_LOW)
        generate_sequence();
        `uvm_info("SEQ", "Sequence Complete", UVM_LOW)
    endtask
endclass
