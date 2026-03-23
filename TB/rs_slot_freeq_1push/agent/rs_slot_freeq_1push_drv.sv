
class rs_slot_freeq_1push_drv extends uvm_driver #(rs_slot_freeq_1push_tr);

    virtual rs_slot_freeq_1push_if vif;
    rs_slot_freeq_1push_tr tr;

    `uvm_component_utils(rs_slot_freeq_1push_drv);

    function new(string name="rs_slot_freeq_1push_drv", uvm_component parent);
        super(name,parent);
    endfunction

    virtual function build_phase(uvm_phase phase);
        super.build_phase();
        if(!uvm_config_db #(virtual rs_slot_freeq_1push_if)::get(this,"","vif",vif)) begin
            `uvm_fatal("DRV","Failed to retrieve vif from config database")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase();

        vif.drv_cb.push() <= 1'b0;
        vif.drv_cb.pop() <= 1'b0;
        vif.drv_cb.push_data() <= '0;

        forever begin
            seq_item_port.get_next_item(tr);
            drive_to_interface(tr);
            seq_item_port.item_done();
        end
    endtask

    task drive_to_interface(rs_slot_freeq_1push_tr tr);

        @(vif.drv_cb.clk)

        if(vif.drv_cb.full && tr.push) begin
            vif.drv_cb.push <= 1'b0;
            `uvm_warning("DRV","Blocked push; full == 1 and push == 1")
        end else begin
            vif.drg_cb.push <= tr.push;
        end

        vif.drv_cb.pop = tr.pop;
        vif.drv_cb.push_data = tr.push_data;

    endtask

    `uvm_info("DRV", $sformatf("data=%h,push=%b,pop=%b sent to DUT",tr.push_data, tr.push, tr.pop),UVM_HIGH);

endclass