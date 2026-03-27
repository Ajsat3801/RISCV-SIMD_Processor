
class rs_slot_freeq_2push_mon extends uvm_monitor;

    `uvm_component_utils(rs_slot_freeq_2push_mon)
    virtual rs_slot_freeq_2push_if vif;
    `uvm_analysis_port #(rs_slot_freeq_2push_tr) item_collected_port;
    rs_slot_freeq_2_push_tr tr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        item_collected_port = new("item_collected_port", this);
        if(!uvm_config_db #(virtual rs_slot_freeq_2push_if)::get(this,"","vif",vif)) begin
            `uvm_fatal("MON", "Failed to get vif from config db")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        forever begin

            @(vif.mon_cb) 

            tr = rs_slot_freeq_2_push_tr::type_id::create("tr");

            tr.reset_n = vif.mon_cb.reset_n;
            tr.push1 = vif.mon_cb.push1;
            tr.push2 = vif.mon_cb.push2;
            tr.push_data1 = vif.mon_cb.push_data1;
            tr.push_data2 = vif.mon_cb.push_data2;
            tr.pop = vif.mon_cb.pop;
            tr.data_out = vif.mon_cb.data_out;
            tr.empty = vif.mon_cb.empty;
            tr.full = vif.mon_cb.full;

            item_collected_port.write(tr)

            `uvm_info("MON", $sformatf("push_data1: %h | push_data2: %h | data_out: %h", tr.push_data1, tr.push_data2, tr.data_out), UVM_HIGH)

        end
    endtask

endclass