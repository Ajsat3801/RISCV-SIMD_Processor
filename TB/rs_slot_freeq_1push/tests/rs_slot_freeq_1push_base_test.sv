
class lib_rs_slot_freeq_1push_base_test extends uvm_test;

    `uvm_component_utils(lib_rs_slot_freeq_1push_base_test)

    lib_rs_slot_freeq_1push_env env;
    virtual lib_rs_slot_freeq_1push_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = lib_rs_slot_freeq_1push_env::type_id::create("env", this);

        if(!uvm_config_db #(virtual lib_rs_slot_freeq_1push_if)::get(this,"","vif",vif)) begin
            `uvm_fatal("TEST","Failed to fetch vif from configuration dataase")
        end

    endfunction

    task apply_reset(int cycles = 5);
        vif.reset_n = 0;
        repeat(cycles) @(posedge vif.clk)
        vif.reset_n = 1;
    endtask
    
    virtual task run_seq();
        `uvm_fatal("TEST", "run_seq() not overwritten")
    endtask

    virtual task run_phase(uvm_phase phase);
        
        phase.raise_objection(this);

        run_seq();

        env.scb.stimulus_done();
        env.scb.done();

        phase.drop_objection(this);

    endtask

    virtual function void report_phase(uvm_phase phase);
        uvm_coreservice_t cs;
        uvm_report_server svr;
        
		cs = uvm_coreservice_t::get();
        svr = cs.get_report_server();

        if(svr.get_severity_count(UVM_ERROR) > 0) begin
            `uvm_info("TEST_RESULT","------ TEST FAILED ------", UVM_NONE)
        end else begin
            `uvm_info("TEST_RESULT","------ TEST PASSED ------", UVM_NONE)
        end
    endfunction



endclass