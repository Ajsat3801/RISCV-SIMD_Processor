
class rs_slot_freeq_1push_agt extends uvm_agent;

    rs_slot_freeq_1push_mon mon;
    rs_slot_freeq_1push_drv drv;
    rs_slot_freeq_1push_sqr sqr;

    virtual rs_slot_freeq_1push_if vif;

    `uvm_component_utils(rs_slot_freeq_1push_agt)

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    virtual function build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = rs_slot_freeq_1push_mon::type_id::create("mon");
        drv = rs_slot_freeq_1push_drv::type_id::create("drv");
        seq = rs_slot_freeq_1push_sqr::type_id::create("sqr");

        if(!uvm_config_db #(virtual rs_slot_freeq_1push_if)::get(this,"","vif",vif)) begin
            `uvm_fatal("AGT","Unable to fetch VIF from config database")
        end

        uvm_config_db #(virtual rs_slot_freeq_1push_if)::set(this,"*","vif",vif);

    endfunction

    virtual function connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass