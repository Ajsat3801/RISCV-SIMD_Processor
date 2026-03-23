
class circular_fifo_fwft_mon extends uvm_monitor;

    virtual circular_fifo_fwft_if vif;
    uvm_analysis_port #(circular_fifo_fwft_tr) item_collected_port;

    `uvm_component_utils(circular_fifo_fwft_mon);

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction
  
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual circular_fifo_fwft_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MON", "virtual interface vif not set for circular_fifo_fwft_drv")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            collect_transactions();
        end
    endtask

    virtual task collect_transactions();

        circular_fifo_fwft_tr tr;

        @(vif.mon_cb);
      
        if(vif.mon_cb.reset_n) begin
            tr = circular_fifo_fwft_tr::type_id::create("tr");
            tr.push = vif.mon_cb.push;
            tr.push_data = vif.mon_cb.push_data;
            tr.pop = vif.mon_cb.pop;
          
            tr.data_out = vif.mon_cb.data_out;
            tr.full = vif.mon_cb.full;
            tr.empty = vif.mon_cb.empty;
          	
            item_collected_port.write(tr); // broadcast txn to scoreboard
        
            `uvm_info("MON", $sformatf("push_data: %h data_out: %h", tr.push_data, tr.data_out), UVM_HIGH)
        end
    endtask

endclass