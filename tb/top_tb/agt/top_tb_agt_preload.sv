/*  -----------------------------------------------------------------------------------------------
 *                   Active agent to drive instructions and pre-load data
 *  -----------------------------------------------------------------------------------------------
 *  <Todo: add documentation here
 */

class top_tb_agt_preload extends uvm_agent;

    top_tb_sqr sqr;
    top_tb_drv drv;
    top_tb_mon_preload mon_preload;

    `uvm_component_utils(top_tb_agt_preload)

    function new(string name="top_tb_agt_preload", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    //  -------------------------------------------------------------------------------------------
    //                                          Phases
    //  -------------------------------------------------------------------------------------------

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        mon_preload = top_tb_mon_preload::type_id::create("mon_preload", this);

        if (get_is_active() == UVM_ACTIVE) begin
            sqr = top_tb_sqr::type_id::create("sqr", this);
            drv = top_tb_drv::type_id::create("drv", this);
        end

    endfunction : build_phase
    

    virtual function void connect_phase(uvm_phase phase);

        super.connect_phase(phase);

        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end

    endfunction : connect_phase

endclass : top_tb_agt_preload