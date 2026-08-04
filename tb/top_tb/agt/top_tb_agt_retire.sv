/*  -----------------------------------------------------------------------------------------------
 *                              Passive agent to monitor retirement bus
 *  -----------------------------------------------------------------------------------------------
 *  <Todo: add documentation here
 */

class top_tb_agt_retire extends uvm_agent;

    top_tb_mon_retire mon_retire;

    `uvm_component_utils(top_tb_agt_retire)

    function new(string name="top_tb_agt_retire", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new
    
    //  -------------------------------------------------------------------------------------------
    //                                          Phases
    //  -------------------------------------------------------------------------------------------

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        mon_retire = top_tb_mon_retire::type_id::create("mon_retire", this);

    endfunction : build_phase

endclass : top_tb_agt_retire
