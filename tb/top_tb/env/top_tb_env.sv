
class top_tb_env extends uvm_env;

    `uvm_component_utils(top_tb_env)

    top_tb_agt_preload agt_preload;
    top_tb_agt_retire agt_retire;
    top_tb_agt_dut_state agt_dut_state;

    top_tb_cov cov;
    top_tb_scb scb;

    function new(string name="top_tb_env", uvm_component parent=null);
        super.new(name, parent);
    endfunction : new

    //  -------------------------------------------------------------------------------------------
    //                                      Phases
    //  -------------------------------------------------------------------------------------------

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        agt_preload = top_tb_agt_preload::type_id::create("agt_preload", this);
        agt_retire  = top_tb_agt_retire::type_id::create("agt_retire", this);
        agt_dut_state = top_tb_agt_dut_state::type_id::create("agt_dut_state", this);

        cov = top_tb_cov::type_id::create("cov", this);
        scb = top_tb_scb::type_id::create("scb", this);

    endfunction : build_phase


    virtual function void connect_phase(uvm_phase phase);
        
        super.connect_phase(phase);

        agt_preload.mon_preload.ap_preload.connect(scb.imp_preload);
        agt_preload.mon_preload.ap_compute.connect(scb.imp_compute);
        agt_dut_state.mon_dut_state.ap.connect(scb.imp_dut_state);

        agt_preload.mon_preload.ap_preload.connect(cov.imp_preload);
        agt_retire.mon_retire.ap.connect(cov.imp_retire);

        // Note: cov and scb logic pending, current statements are placeholders
    
    endfunction : connect_phase
    
endclass : top_tb_env