/*  -----------------------------------------------------------------------------------------------
 *                        Monitor for sampling final PRF and DMEM state
 *  -----------------------------------------------------------------------------------------------
 *  <Todo: add additional documentation here>
 */


class top_tb_mon_dut_state extends uvm_monitor;

    virtual top_tb_if_dut_state vif_dut_state;
    top_tb_run_status status;

    uvm_analysis_port #(top_tb_tr_dut_state) ap;

    `uvm_component_utils(top_tb_mon_dut_state)

    function new(string name = "top_tb_mon_dut_state", uvm_component parent = null);
        super.new(name, parent);

    endfunction

    //  -------------------------------------------------------------------------------------------
    //                                        Phases
    //  -------------------------------------------------------------------------------------------

    virtual function void build_phase (uvm_phase phase);

        super.build_phase(phase);

        if(!uvm_config_db#(virtual top_tb_if_dut_state)::get(this, "", "vif_dut_state", vif_dut_state))
            `uvm_fatal("MON/NOVIF","Unable to get vif from UVM config DB for DUT final state monitor")

        if(!uvm_config_db#(top_tb_run_status)::get(this, "", "run_status", status))
            `uvm_fatal("MON/NOSTATUS", "Unable to get run_status from UVM config DB for DUT final state monitor")
        
        ap = new("ap", this);

    endfunction : build_phase


    virtual task run_phase(uvm_phase phase);

        forever begin
            status.ev_snapshot.wait_trigger();
            capture_snapshot();
            status.snapshot_taken = 1'b1;
        end

    endtask : run_phase

    //  -------------------------------------------------------------------------------------------
    //                                      Wrapper tasks
    //  -------------------------------------------------------------------------------------------

    task capture_snapshot();

        top_tb_tr_dut_state tr;

        tr = top_tb_tr_dut_state::type_id::create("tr", this);

        vif_dut_state.dump_sc_regs(tr.sc_reg_sample, tr.sc_replicas_match);
        vif_dut_state.dump_vc_regs(tr.vc_reg_sample);

        vif_dut_state.dump_dmem(tr.dmem_sample);

        ap.write(tr);

        `uvm_info("MON", $sformatf("DUT state snapshot captured\n%s", tr.convert2string()), UVM_MEDIUM)

    endtask : capture_snapshot

endclass : top_tb_mon_dut_state