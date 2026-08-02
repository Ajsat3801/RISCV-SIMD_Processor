/*  -----------------------------------------------------------------------------------------------
 *                        Monitor for sampling final PRF and DMEM state
 *  -----------------------------------------------------------------------------------------------
 *  <Todo: add additional documentation here>
 */


class top_tb_mon_dut_state extends uvm_monitor;

    virtual top_tb_if_prf_sample vif_prf;
    virtual top_tb_if_dmem_sample vif_dmem;

    uvm_analysis_port #(top_tb_tr_dut_state) ap;
    uvm_event test_complete;

    `uvm_component_utils(top_tb_mon_dut_state)

    function new(string name = "top_tb_mon_dut_state", uvm_component parent = null);
        super.new(name, parent);

    endfunction

    //  -------------------------------------------------------------------------------------------
    //                                        Phases
    //  -------------------------------------------------------------------------------------------

    virtual function void build_phase (uvm_phase phase);

        super.build_phase(phase);

        if(!uvm_config_db#(virtual top_tb_if_prf_sample)::get(this, "", "vif_prf", vif_prf))
            `uvm_fatal("MON/NOVIF","Unable to get vif from UVM config DB for PRF final state monitor")

        if(!uvm_config_db#(virtual top_tb_if_dmem_sample)::get(this,"","vif_dmem", vif_dmem))
            `uvm_fatal("MON/NOVIF","Unable to get vif from UVM config DB for DMEM final monitor")

        ap = new("ap", this);

        test_complete = uvm_event_pool::get_global("test_complete");

    endfunction : build_phase


    virtual task run_phase(uvm_phase phase);

        forever begin
            test_complete.wait_trigger();
            capture_snapshot();
        end

    endtask : run_phase

    //  -------------------------------------------------------------------------------------------
    //                                      Wrapper tasks
    //  -------------------------------------------------------------------------------------------

    task capture_snapshot();

        top_tb_tr_dut_state tr;

        tr = top_tb_tr_dut_state::type_id::create("tr", this);

        vif_prf.dump_sc_regs(tr.sc_reg_sample, tr.sc_replicas_match);
        vif_prf.dump_vc_regs(tr.vc_reg_sample);

        vif_dmem.dump_dmem(tr.dmem_sample);

        ap.write(tr);

        `uvm_info("MON", $sformatf("DUT state snapshot captured\n%s", tr.convert2string()), UVM_MEDIUM)

    endtask : capture_snapshot

endclass : top_tb_mon_dut_state