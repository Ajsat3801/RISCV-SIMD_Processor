// connects agt to scoreboard - coverage in the future

class lib_rs_slot_freeq_1push_env extends uvm_env;

    `uvm_component_utils(lib_rs_slot_freeq_1push_env)

    lib_rs_slot_freeq_1push_agt agt;
    lib_rs_slot_freeq_1push_scb scb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agt = lib_rs_slot_freeq_1push_agt::type_id::create("agt", this);
        scb = lib_rs_slot_freeq_1push_scb::type_id::create("scb", this);

    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.item_collected_port.connect(scb.mon_imp);
    endfunction

endclass