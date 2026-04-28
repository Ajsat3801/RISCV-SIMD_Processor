
class lib_rs_slot_freeq_1push_seq_random50 extends lib_rs_slot_freeq_1push_base_seq;

    `uvm_object_utils(lib_rs_slot_freeq_1push_seq_random50)

    function new(string name="lib_rs_slot_freeq_1push_seq_random50");
        super.new(name);
    endfunction

    task generate_seq();

        lib_rs_slot_freeq_1push_tr tr;

        repeat(50) begin
            tr = lib_rs_slot_freeq_1push_tr::type_id::create("tr");
            
            start_item(tr);
            if(!tr.randomize()) `uvm_fatal("SEQ", "Transaction Randomization failed")
            finish_item(tr);

        end

    endtask
endclass