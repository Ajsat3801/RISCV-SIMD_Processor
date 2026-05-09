
class lib_fifo_fwft_1push_mon extends uvm_monitor;

    virtual lib_fifo_fwft_1push_if vif;
    uvm_analysis_port #(lib_fifo_fwft_1push_tr) item_collected_port;

    `uvm_component_utils(lib_fifo_fwft_1push_mon);

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction
  
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual lib_fifo_fwft_1push_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MON", "virtual interface vif not set for lib_fifo_fwft_1push_drv")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            collect_transactions();
        end
    endtask

    task collect_transactions();

        lib_fifo_fwft_1push_tr tr;

        @(vif.mon_cb);
      
        if(vif.mon_cb.reset_n) begin
            tr = lib_fifo_fwft_1push_tr::type_id::create("tr");
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