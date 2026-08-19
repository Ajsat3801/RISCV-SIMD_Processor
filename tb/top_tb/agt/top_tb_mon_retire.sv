/*
 *  Monitor for snooping retirement bus

*/

class top_tb_mon_retire extends uvm_monitor;

    virtual top_tb_if_retirement vif_retire;
    top_tb_run_status status;

    uvm_analysis_port #(top_tb_tr_retire) ap;

    `uvm_component_utils(top_tb_mon_retire)

    function new(string name = "top_tb_mon_retire", uvm_component parent = null);
        super.new(name, parent);

    endfunction

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if(!uvm_config_db#(virtual top_tb_if_retirement)::get(this,"","vif_retire", vif_retire))
            `uvm_fatal("MON/NOVIF","Unable to get vif_retire from UVM config DB for retirement monitor")

        if(!uvm_config_db#(top_tb_run_status)::get(this,"","run_status", status))
            `uvm_fatal("MON/NOSTATUS","Unable to get run status from UVM config DB for retirement monitor")

        ap = new("ap", this);

    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        
        top_tb_typedef_pkg::retire_snapshot_t snap;
        top_tb_tr_retire tr;
        bit complete_q;

        super.run_phase(phase);

        complete_q = 1'b0;

        forever begin

            @(posedge vif_retire.clk_i);

            snap = vif_retire.sample();

            if(snap.valid) begin
                tr = top_tb_tr_retire::type_id::create("tr", this);

                tr.snapshot = snap;
                ap.write(tr);
                `uvm_info("MON", $sformatf("Retirement sampled: %s",tr.convert2string()), UVM_HIGH)

            end

            status.retire_count = vif_retire.retire_count;
            status.idle_cycles = vif_retire.idle_cycles;
            status.complete = vif_retire.complete();

            if(status.complete && !complete_q) begin
                `uvm_info("MON", "Idle threshold reach, terminating test", UVM_LOW)
                status.ev_dut_complete.trigger();
            end

            complete_q = status.complete;

        end

    endtask : run_phase

endclass : top_tb_mon_retire