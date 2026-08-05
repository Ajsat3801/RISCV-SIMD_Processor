/*  -----------------------------------------------------------------------------------------------
 *                          Passive agent to fetch final state of DUT
 *  -----------------------------------------------------------------------------------------------
 *  <Todo: add documentation here
 */
class top_tb_agt_dut_state extends uvm_agent;

    top_tb_mon_dut_state mon_dut_state;

    `uvm_component_utils(top_tb_agt_dut_state)

    function new(string name = "top_tb_agt_dut_state", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new
    
    //  -------------------------------------------------------------------------------------------
    //                                          Phases
    //  -------------------------------------------------------------------------------------------

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_dut_state = top_tb_mon_dut_state::type_id::create("mon_dut_state", this);
    endfunction : build_phase

endclass : top_tb_agt_dut_state