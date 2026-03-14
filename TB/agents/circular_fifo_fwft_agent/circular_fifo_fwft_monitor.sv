
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

    virtual task run_phase(uvm_phase phase);
        forever begin
            collect_transactions();
        end
    endtask

    virtual task collect_transactions();

        circular_fifo_fwft_transaction #(T) tr;

        @(vif.cb);

        if(!vif.cb.empty) begin
            tr = circular_fifo_fwft_transaction#(T)::type_id::create("tr");

            tr.push_data = vif.cb.push_data; // write hardware pin to txn
            item_collected_port.write(tr); // broadcast txn to scoreboard

            `uvm_info("MON", $sformatf("Sampled Data: %h", tr.data_out), UVM_HIGH)
        end
    endtask

endclass