
class lib_circular_fifo_fwft_drv extends uvm_driver #(lib_circular_fifo_fwft_tr);

    virtual lib_circular_fifo_fwft_if vif;
    lib_circular_fifo_fwft_tr tr;

    `uvm_component_utils(lib_circular_fifo_fwft_drv)

    //constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
  
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual lib_circular_fifo_fwft_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("DRV/NOVIF", "virtual interface vif not set for lib_circular_fifo_fwft_drv")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);

        // get rid of dont care cases
        vif.drv_cb.push <= 1'b0;
        vif.drv_cb.pop <= 1'b0;
        vif.drv_cb.push_data <= '0;

        forever begin
            seq_item_port.get_next_item(tr); // get next transaction from sequencer
            drive_to_interface(tr); // send it to interface, code below
            seq_item_port.item_done(); // mark as done so that next gets ready
        end
    endtask

    task drive_to_interface(lib_circular_fifo_fwft_tr tr);

        @(vif.drv_cb);

        // you send all the things to the interface.
        // handle hardware state determined constraints herw
  
        if(vif.drv_cb.full && tr.push) begin // illegal scenario
            vif.drv_cb.push <= 1'b0;
            `uvm_warning("DRV","Blocked push: full==1 && push==1")
        end else begin
            vif.drv_cb.push <= tr.push;
        end;
        
	    vif.drv_cb.push_data <= tr.push_data;
        vif.drv_cb.pop <= tr.pop;

        `uvm_info("DRV", $sformatf("data=%h,push=%b,pop=%b sent to DUT",tr.push_data, tr.push, tr.pop),UVM_HIGH);
    endtask

endclass