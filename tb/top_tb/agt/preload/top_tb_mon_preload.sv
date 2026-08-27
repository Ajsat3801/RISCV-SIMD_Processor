/*  -----------------------------------------------------------------------------------------------
 *                    Passive agent to monitor preload instructions sent to DUT
 *  -----------------------------------------------------------------------------------------------
 *  <Todo: add documentation here>
 *  Notes: transactions are created and written only if valid
 */

class top_tb_mon_preload extends uvm_monitor;

    virtual top_tb_if_preload vif_preload;

    uvm_analysis_port #(top_tb_tr_preload) ap_preload;
    uvm_analysis_port #(top_tb_tr_compute) ap_compute;

    `uvm_component_utils(top_tb_mon_preload)

    bit compute_prev;

    function new(string name = "top_tb_mon_preload", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if(!uvm_config_db#(virtual top_tb_if_preload)::get(this, "","vif_preload",vif_preload))
            `uvm_fatal("MON/NOVIF","Unable to get vif from UVM config DB for preload monitor")

        ap_preload = new("ap_preload", this);
        ap_compute = new("ap_compute", this);

        compute_prev = 1'b0;

    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);

        super.run_phase(phase);

        forever begin
            @(posedge vif_preload.clk_i);
            #1;

            sample_preload();
            sample_compute();
        end

    endtask : run_phase

    //  -------------------------------------------------------------------------------------------
    //                                      Wrapper Tasks
    //  -------------------------------------------------------------------------------------------

    task sample_preload();

        top_tb_tr_preload tr;

        if(!(vif_preload.imem_preload_en || vif_preload.dmem_preload_en ||
            vif_preload.sc_prf_preload_en || vif_preload.vc_prf_preload_en)) return;

        tr = top_tb_tr_preload::type_id::create("tr", this);

        tr.imem_en = vif_preload.imem_preload_en;
        tr.imem_address = vif_preload.preload_imem_request.address;
        tr.imem_data = vif_preload.preload_imem_request.data;

        tr.dmem_en = vif_preload.dmem_preload_en;
        tr.dmem_write_enable = vif_preload.preload_dmem_request.write_enable;
        tr.dmem_address = vif_preload.preload_dmem_request.address;
        tr.dmem_data = vif_preload.preload_dmem_request.data;

        tr.sc_prf_en = vif_preload.sc_prf_preload_en;
        tr.sc_prf_data = vif_preload.sc_prf_preload_data;
        tr.sc_prf_address = vif_preload.sc_prf_preload_addr;

        tr.vc_prf_en = vif_preload.vc_prf_preload_en;
        tr.vc_prf_data = vif_preload.vc_prf_preload_data;
        tr.vc_prf_address = vif_preload.vc_prf_preload_addr;

        ap_preload.write(tr);

        `uvm_info("MON", $sformatf("Preload sampled: %s", tr.convert2string()), UVM_DEBUG)

    endtask : sample_preload

    task sample_compute();

        top_tb_tr_compute tr;
        
        if(vif_preload.compute === compute_prev) return;

        tr = top_tb_tr_compute::type_id::create("tr", this);

        tr.start = vif_preload.compute;
        
        ap_compute.write(tr);
        compute_prev = vif_preload.compute;

        `uvm_info("MON", $sformatf("Compute sampled: start=%0b", tr.start), UVM_DEBUG)

    endtask : sample_compute


endclass : top_tb_mon_preload