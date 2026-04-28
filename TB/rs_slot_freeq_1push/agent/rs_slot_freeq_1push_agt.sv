
class lib_rs_slot_freeq_1push_agt extends uvm_agent;

    lib_rs_slot_freeq_1push_mon mon;
    lib_rs_slot_freeq_1push_drv drv;
    lib_rs_slot_freeq_1push_sqr sqr;

    virtual lib_rs_slot_freeq_1push_if vif;

    `uvm_component_utils(lib_rs_slot_freeq_1push_agt)

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = lib_rs_slot_freeq_1push_mon::type_id::create("mon", this);
        drv = lib_rs_slot_freeq_1push_drv::type_id::create("drv", this);
        sqr = lib_rs_slot_freeq_1push_sqr::type_id::create("sqr", this);

        if(!uvm_config_db #(virtual lib_rs_slot_freeq_1push_if)::get(this,"","vif",vif)) begin
            `uvm_fatal("AGT","Unable to fetch VIF from config database")
        end

        uvm_config_db #(virtual lib_rs_slot_freeq_1push_if)::set(this,"*","vif",vif);

    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass