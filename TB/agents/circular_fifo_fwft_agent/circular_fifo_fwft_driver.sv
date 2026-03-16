
class circular_fifo_fwft_driver #(
    parameter BUFFER_SIZE = 8,
    parameter type T = logic[31:0]
) extends uvm_driver #(
    circular_fifo_fwft_transaction #(T)
);

virtual circular_fifo_fwft_if #(BUFFER_SIZE, T) vif;

uvm_analysis_port #(circular_fifo_fwft_transaction #(T)) sent_input;
    circular_fifo_fwft_transaction #(T) tr;
    `uvm_component_param_utils(circular_fifo_fwft_driver #(BUFFER_SIZE,T))

//constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        sent_input = new("sent_input", this);
    endfunction
  
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual circular_fifo_fwft_if #(BUFFER_SIZE, T))::get(this, "", "vif", vif)) begin
            `uvm_fatal("DRV/NOVIF", "virtual interface vif not set for circular_fifo_fwft_driver")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);

        // get rid of dont care cases
        vif.cb.push <= 1'b0;
        vif.cb.pop <= 1'b0;

        forever begin
            seq_item_port.get_next_item(tr); // get next transaction from sequencer
            drive_to_interface(tr); // send it to interface, code below
            seq_item_port.item_done(); // mark as done so that next gets ready
        end
    endtask

    virtual task drive_to_interface(circular_fifo_fwft_transaction #(T) tr);

        @(vif.cb);

        // you send all the things to the interface.
        // handle hardware state determined constraints herw
    
        if(vif.cb.full && tr.push) begin // illegal scenario
            vif.cb.push <= 1'b0;
            `uvm_info("DRV","Blocked push: full==1 && push==1", UVM_HIGH)
        end else begin
            vif.cb.push <= tr.push;
        end;
        
        vif.cb.push_data <= tr.push_data;
        vif.cb.pop <= tr.pop;

        `uvm_info("DRV", $sformatf("data=%h,push=%b,pop=%b sent to DUT",tr.push_data, tr.push, tr.pop),UVM_HIGH);
        sent_input.write(tr);
endtask

endclass