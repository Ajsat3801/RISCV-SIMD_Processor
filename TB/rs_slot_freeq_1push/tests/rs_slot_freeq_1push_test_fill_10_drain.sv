
class rs_slot_freeq_1push_test_fill_10_drain extends rs_slot_freeq_1push_base_test;

    `uvm_component_utils(rs_slot_freeq_1push_test_fill_10_drain)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_seq();
        rs_slot_freeq_1push_seq_fill_10_drain seq;

        seq = rs_slot_freeq_1push_seq_fill_10_drain::type_id::create("seq");

        apply_reset(5);
        seq.start(env.agt.sqr);
  
    endtask


endclass