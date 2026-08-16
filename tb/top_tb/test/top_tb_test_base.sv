

class top_tb_test_base extends uvm_test;

    `uvm_component_utils(top_tb_test_base)

    top_tb_env env;
    top_tb_run_status status;

    protected top_tb_seq_program_base seq;

    function new(string name = "top_tb_test_base" , uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        status = top_tb_run_status::type_id::create("status");
        uvm_config_db #(top_tb_run_status)::set(this, "*", "run_status", status);

        env = top_tb_env::type_id::create("env", this);

        //uvm_top.set_timeout(top_tb_config_pkg::TEST_TIMEOUT, 1);

    endfunction : build_phase


    virtual task main_phase(uvm_phase phase);

        phase.raise_objection(this, "top_tb_test_base: stimulus running");

        create_sequence();
        if(seq == null) `uvm_fatal("TEST/NOSEQ", "no sequence created in test")
        seq.start(env.agt_preload.sqr); // returns when sequence is complete

        status.ev_check_complete.wait_ptrigger();
        phase.drop_objection(this, "top_tb_test_base: run complete");

    endtask : main_phase

    virtual function void report_phase(uvm_phase phase);

        uvm_report_server svr;
        int unsigned n_err, n_fatal;

        super.report_phase(phase);

        svr     = uvm_report_server::get_server();
        n_err   = svr.get_severity_count(UVM_ERROR);
        n_fatal = svr.get_severity_count(UVM_FATAL);

        if(n_err == 0 && n_fatal == 0)
            `uvm_info("TEST/RESULT", "\n\n\t****  TEST PASSED  ****\n", UVM_NONE)
        else
            `uvm_info("TEST/RESULT",
                      $sformatf("\n\n\t****  TEST FAILED : %0d errors, %0d fatals  ****\n",
                                n_err, n_fatal),
                      UVM_NONE)

    endfunction : report_phase

    virtual function void create_sequence();
        `uvm_fatal("TEST/NO_SEQ_HOOK", "create_sequence() not overridden by the derived test")
    endfunction : create_sequence

endclass : top_tb_test_base