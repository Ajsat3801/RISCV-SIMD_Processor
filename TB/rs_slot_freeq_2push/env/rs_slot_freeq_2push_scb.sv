
class rs_slot_freeq_2push_scb extends uvm_scoreboard;

    `uvm_component_utils(rs_slot_freeq_2push_scb)

    uvm_analysis_imp #(rs_slot_freeq_2push_tr, rs_slot_freeq_2push_scb) mon_imp;
    rs_slot_freeq_2push_ref_model_adapter ref_model;

    bit stimulus_completed_f, simulation_completed_f, test_pass, enable_checking_f;
    event simulation_completed_e;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        test_pass = 1'b1;
        enable_checking_f = 1'b0;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_imp = new("mon_imp",this);
        `uvm_info("SCB","Creating Reference model", UVM_HIGH)
        ref_model = new();
        if(ref_model == null) `uvm_fatal("SCB","Reference Model not constructed properly")
        ref_model.create_model();
        `uvm_info("SCB","Reference model created successfully", UVM_HIGH)
    endfunction

    virtual function void write(rs_slot_freeq_2push_tr tr);

        T data_out;
        bit full, empty;
        bit pass;
        string msg;
        `uvm_info("SCB","Running reference model", UVM_HIGH)
        ref_model.run_model(
            .reset_n(tr.reset_n),
            .push_data1T(tr.push_data1),
            .push_data2T(tr.push_data2),
            .push1(tr.push1),
            .push2(tr.push2),
            .pop(tr.pop),
            .data_outT(data_out),
            .fifo_full(full),
            .fifo_empty(empty)
        );
        `uvm_info("SCB","Reference model ran successfully",UVM_HIGH)

        pass = tr.data_out == data_out && tr.full == full && tr.empty == empty;

        msg = {
            $sformatf("\tctrls( %0d, %0d, %0d) data(%h, %h) ",tr.push1, tr.push2, tr.pop, tr.push_data1, tr.push_data2),
            $sformatf("exp(dt_out: %h, full: %0d, empty: %0d) ", data_out, full, empty),
            $sformatf("act(dt_out: %h, full: %0d, empty: %0d)", tr.data_out, tr.full, tr.empty)
        };

        if(enable_checking_f) begin
            if(pass) `uvm_info("SCB MATCH", msg, UVM_MEDIUM)
            else     `uvm_error("SCB MISMATCH", msg)

            test_pass = test_pass && pass;
        end
        
        update_scoreboard_status();

    endfunction

    task wait_for_done();
        if(!simulation_completed_f) @simulation_completed_e;
    endtask

    function bit obtain_result();
        return test_pass;
    endfunction

    function void stimulus_complete();
        stimulus_completed_f = 1'b1;
    endfunction

    function void start_checking();
        enable_checking_f = 1'b1;
    endfunction

    function void update_scoreboard_status();
        if (stimulus_completed_f && !simulation_completed_f) begin
            simulation_completed_f = 1'b1;
            enable_checking_f = 1'b0;
            ->simulation_completed_e;
        end
    endfunction

endclass