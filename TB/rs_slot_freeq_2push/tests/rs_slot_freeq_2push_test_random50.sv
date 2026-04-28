
class lib_rs_slot_freeq_2push_test_random50 extends lib_rs_slot_freeq_2push_base_test;

    `uvm_component_utils(lib_rs_slot_freeq_2push_test_random50)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_seq();

        lib_rs_slot_freeq_2push_seq_random50 seq;
        seq = lib_rs_slot_freeq_2push_seq_random50::type_id::create("seq", this);

        super.apply_reset(0);
        seq.start(env.agt.sqr);

    endtask
endclass