
class lib_rs_slot_freeq_2push_base_test extends uvm_test;

    `uvm_component_utils(lib_rs_slot_freeq_2push_base_test)

    virtual lib_rs_slot_freeq_2push_if vif;
    lib_rs_slot_freeq_2push_env env;

    bit test_passed;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = lib_rs_slot_freeq_2push_env::type_id::create("env", this);

        if(!uvm_config_db#(virtual lib_rs_slot_freeq_2push_if)::get(this,"","vif",vif)) begin
            `uvm_fatal("TEST","Unable to get vif from config database")
        end

    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);
        apply_reset(5);
        env.scb.start_checking();
        run_seq();
        env.scb.stimulus_complete();
        env.scb.wait_for_done();
        test_passed = env.scb.obtain_result();
        phase.drop_objection(this);
    endtask

    virtual function void report_phase(uvm_phase phase);
        if(test_passed) `uvm_info("TEST RESULT","----- TEST PASSED -----", UVM_NONE)
        else `uvm_info("TEST RESULT","----- TEST FAILED -----", UVM_NONE)
    endfunction

    virtual task run_seq();
        `uvm_fatal("TEST","run_seq() not overwritten")
    endtask

    virtual task apply_reset(int cycles=5);
        vif.reset_n = 1'b0;
        repeat(cycles) @(posedge vif.clk);
        vif.reset_n = 1'b1;
    endtask
        
endclass