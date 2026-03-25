
class rs_slot_freeq_1push_test_drain_10_fill extends rs_slot_freeq_1push_base_test;

    `uvm_component_utils(rs_slot_freeq_1push_test_drain_10_fill)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_seq();

        rs_slot_freeq_1push_seq_drain_10_fill seq;

        seq = rs_slot_freeq_1push_seq_drain_10_fill::type_id::create("seq");

        super.apply_reset(5);
        seq.start(env.agt.sqr);

    endtask

endclass