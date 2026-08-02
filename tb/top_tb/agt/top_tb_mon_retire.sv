/*
 *  Monitor for snooping retirement bus

*/

class top_tb_mon_retire extends uvm_monitor;

    virtual top_tb_if_retirement vif_retire;

    uvm_analysis_port #(top_tb_tr_retire) ap;
    uvm_event test_complete;

    `uvm_component_utils(top_tb_mon_retire)

    function new(string name = "top_tb_mon_retire", uvm_component parent = null);
        super.new(name, parent);

    endfunction

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if(!uvm_config_db#(virtual top_tb_if_retirement)::get(this,"","vif_retire", vif_retire))
            `uvm_fatal("MON/NOVIF","Unable to get vif_retire from UVM config DB for retirement monitor")

        ap = new("ap", this);

        test_complete = uvm_event_pool::get_global("test_complete");

    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        top_tb_typedef_pkg::retire_snapshot_t snap;
        top_tb_tr_retire tr;

        forever begin

            @(posedge vif_retire.clk_i);

            snap = vif_retire.sample();

            if(snap.valid) begin
                tr = top_tb_tr_retire::type_id::create("tr", this);

                tr.snapshot = snap;
                ap.write(tr);
                `uvm_info("MON", $sformatf("Retirement sampled: %s",tr.convert2string()), UVM_HIGH)

            end

            if(vif_retire.idle_cycles == top_tb_config_pkg::IDLE_CYCLE_THRESHOLD) begin
                `uvm_info("MON", "Idle treshold reach, terminating test", UVM_LOW)
                test_complete.trigger();
            end

        end

    endtask : run_phase

endclass : top_tb_mon_retire