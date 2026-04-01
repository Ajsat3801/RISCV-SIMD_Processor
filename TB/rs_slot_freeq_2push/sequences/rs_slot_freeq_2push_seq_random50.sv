
class rs_slot_freeq_2push_seq_random50 extends rs_slot_freeq_2push_base_seq;

    `uvm_object_utils(rs_slot_freeq_2push_seq_random50);

    rs_slot_freeq_2push_tr tr;

    function new(string name="rs_slot_freeq_2push_seq_random50");
        super.new(name);
    endfunction

    task generate_sequence();

        repeat(50) begin
            tr = rs_slot_freeq_2push_tr::type_id::create("tr");
            
            start_item(tr);
            if(!tr.randomize()) `uvm_fatal("SEQ", "Transaction Randomization failed");
            finish_item(tr);
        end

    endtask

endclass