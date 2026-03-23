
class rs_slot_freeq_1input_seq_random50
extends rs_slot_freeq_1input_base_seq;

    `uvm_object_utils(rs_slot_freeq_1input_seq_random50)

    function new(name="rs_slot_freeq_1input_base_seq");
        super.new(name);
    endfunction

    task generate_seq();

        rs_slot_freeq_1input_tr tr;

        repeat(50) begin

            tr = rs_slot_freeq_1input_tr::type_id::create("tr");
            
            start_item();
            if(!tr.randomize) `uvm_fatal("SEQ", "Transaction Randomization failed")
            finish_item();

        end

    endtask

endclass