class top_tb_mon_alloc extends uvm_monitor;

    virtual top_tb_if_alloc vif_alloc;

    uvm_analysis_port #(top_tb_tr_alloc) ap;

    `uvm_component_utils(top_tb_mon_alloc)

    function new(string name = "top_tb_mon_alloc", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if(!uvm_config_db#(virtual top_tb_if_alloc)::get(this,"","vif_alloc", vif_alloc))
            `uvm_fatal("MON/NOVIF","Unable to get vif_alloc from UVM config DB for alloc-bus monitor")

        ap = new("ap", this);

    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);

        top_tb_typedef_pkg::alloc_snapshot_t snap;
        top_tb_tr_alloc tr;

        super.run_phase(phase);

        forever begin

            @(posedge vif_alloc.clk_i);

            snap = vif_alloc.sample();

            if(snap.valid) begin
                tr = top_tb_tr_alloc::type_id::create("tr", this);
                tr.snapshot = snap;
                ap.write(tr);
                `uvm_info("MON", $sformatf("Allocation sampled: %s", tr.convert2string()), UVM_DEBUG)
            end

        end

    endtask : run_phase

endclass : top_tb_mon_alloc