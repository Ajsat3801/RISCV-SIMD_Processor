
class circular_fifo_fwft_driver #(
    parameter BUFFER_SIZE = 8,
    parameter type T = logic[31:0]
) extends uvm_driver #(
    circular_fifo_fwft_transaction #(T)
);

virtual circular_fifo_fwft_if #(BUFFER_SIZE, T) vif;

`uvm_component_param_utils(circular_fifo_fwft_driver #(T))

//constructor
function new(string name, uvm_component parent);
    super.new(name, parent);
endfunction

virtual task run_phase(uvm_phase phase);

    // get rid of dont care cases
    vif.cb.push <= 1'b0;
    vif.cb.pop <= 1'b0;

    forever begin
        seq_item_port.get_next_item(req); // get next transaction from sequencer
        drive_to_interface(req); // send it to interface, code below
        seq_item_port.item_done(); // mark as done so that next gets ready
    end
endtask

virtual task drive_to_interface(circular_fifo_fwft_transaction #(T) req);

    @(vif.cb);

    // you send all the things to the interface.
    // handle hardware state determined constraints here

    if(vif.cb.full && req.push) begin // illegal scenario
        vif.cb.push <= 1'b0;
        `uvm_info("DRV","Blocked push: full==1 && push==1", UVM_HIGH)
    end else begin
        vif.cb.push <= req.push;
        vif.cb.push_data <= req.push_data;
    end

    vif.cb.pop <= req.pop;

endtask

endclass