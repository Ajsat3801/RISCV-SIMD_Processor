
class lib_rs_slot_freeq_1push_mon extends uvm_monitor;

    virtual lib_rs_slot_freeq_1push_if vif;
    uvm_analysis_port #(lib_rs_slot_freeq_1push_tr) item_collected_port;

    `uvm_component_utils(lib_rs_slot_freeq_1push_mon )

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        item_collected_port = new("item_collected_port",this);
        if(!uvm_config_db #(virtual lib_rs_slot_freeq_1push_if)::get(this,"","vif",vif)) begin
            `uvm_fatal("MON","Failed to fetch VIF from config database")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            collect_transactions();
        end
    endtask

    task collect_transactions();
        lib_rs_slot_freeq_1push_tr tr;
        
        @(vif.mon_cb)

        tr = lib_rs_slot_freeq_1push_tr::type_id::create("tr");

        tr.push = vif.mon_cb.push;
        tr.pop = vif.mon_cb.pop;
        tr.reset_n = vif.mon_cb.reset_n;
        tr.push_data = vif.mon_cb.push_data;
        tr.data_out = vif.mon_cb.data_out;
        tr.full = vif.mon_cb.full;
        tr.empty = vif.mon_cb.empty;

        item_collected_port.write(tr);

        `uvm_info("MON", $sformatf("push_data: %h data_out: %h", tr.push_data, tr.data_out), UVM_HIGH)

    endtask

endclass