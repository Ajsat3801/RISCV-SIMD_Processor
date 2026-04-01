
class rs_slot_freeq_2push_drv extends uvm_driver #(rs_slot_freeq_2push_tr);

    `uvm_component_utils(rs_slot_freeq_2push_drv)

    virtual rs_slot_freeq_2push_if vif;
    rs_slot_freeq_2push_tr tr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db #(virtual rs_slot_freeq_2push_if)::get(this,"","vif",vif)) begin
            `uvm_fatal("DRV","Failed to get VIF from config database")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        vif.drv_cb.push1 <= 1'b0;
        vif.drv_cb.push2 <= 1'b0;
        vif.drv_cb.push_data1 <= '0;
        vif.drv_cb.push_data2 <= '0;
        vif.drv_cb.pop <= 1'b0;

        forever begin
            
            seq_item_port.get_next_item(tr);
            
            @(vif.drv_cb)

            if(vif.drv_cb.full && tr.push1) begin
                vif.drv_cb.push1 <= 1'b0;
                `uvm_warning("DRV","FIFO full; setting push1 to 0");
            end 
            else vif.drv_cb.push1 <= tr.push1;

            if(vif.drv_cb.full && tr.push2) begin
                vif.drv_cb.push2 <= 1'b0;
                `uvm_warning("DRV","FIFO full; setting push2 to 0");
            end
            else vif.drv_cb.push2 <= tr.push2;

            vif.drv_cb.pop <= tr.pop;
            vif.drv_cb.push_data1 <= tr.push_data1;
            vif.drv_cb.push_data2 <= tr.push_data2;

            `uvm_info("DRV", $sformatf("push_data1=%h,push_data2=%h,push1=%h,push2=%h,pop=%b sent to DUT",tr.push_data1,tr.push_data2, tr.push1, tr.push2, tr.pop),UVM_HIGH);

            seq_item_port.item_done();
        end

    endtask

endclass