class top_tb_agt_alloc extends uvm_agent;

    top_tb_mon_alloc mon_alloc;

    `uvm_component_utils(top_tb_agt_alloc)

    function new(string name="top_tb_agt_alloc", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);
        mon_alloc = top_tb_mon_alloc::type_id::create("mon_alloc", this);

    endfunction : build_phase

endclass : top_tb_agt_alloc