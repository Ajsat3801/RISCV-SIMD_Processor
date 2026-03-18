
class circular_fifo_fwft_monitor #(
    parameter int BUFFER_SIZE = 16,
    parameter type T = logic[31:0]
) extends uvm_monitor;

    virtual circular_fifo_fwft_if #(BUFFER_SIZE, T) vif;

    uvm_analysis_port #(circular_fifo_fwft_transaction #(T)) item_collected_port;

    `uvm_component_param_utils(circular_fifo_fwft_monitor #(BUFFER_SIZE, T));

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction
  
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual circular_fifo_fwft_if #(BUFFER_SIZE, T))::get(this, "", "vif", vif)) begin
            `uvm_fatal("MON", "virtual interface vif not set for circular_fifo_fwft_driver")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            collect_transactions();
        end
    endtask

    virtual task collect_transactions();

        circular_fifo_fwft_transaction #(T) tr;

        @(vif.mon_cb);
      
        if(vif.mon_cb.reset_n) begin
            tr = circular_fifo_fwft_transaction#(T)::type_id::create("tr");
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