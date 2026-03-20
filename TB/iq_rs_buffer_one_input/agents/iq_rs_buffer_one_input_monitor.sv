
class iq_rs_buffer_one_input_monitor #(
    parameter int BUFFER_SIZE = 8,
    parameter type T = logic[31:0]
) extends uvm_monitor;

    virtual iq_rs_buffer_one_input_if #(BUFFER_SIZE, T) vif;
    uvm_analysis_port(iq_rs_buffer_one_input_transaction #(T)) item_collected_port;

    `uvm_component_param_utils(iq_rs_buffer_one_input_monitor #(BUFFER_SIZE, T))

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function build_phase(uvm_phase phase);
        if(!uvm_config_db #(virtual iq_rs_buffer_one_input_if #(BUFFER_SIZE, T))::get(this,"","vif",vif)) begin
            `uvm_fatal("MON","Failed to fetch VIF from config database")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            collect_transactions();
        end
    endtask

    task collect_transactions();
        iq_rs_buffer_one_input_transaction #(T) tr;
        
        @(vif.mon_cb.clk)

        tr = iq_rs_buffer_one_input_transaction #(T)::type_id::create("tr");

        tr.push = vif.mon_cb.push;
        tr.pop = vif.mon_cb.pop;
        tr.reset_n = vif.mon_cb.reset_n;
        tr.push_data = vif.mon_cb.push_data;
        tr.data_out = vif.mon_cb.data_out;
        tr.full = vif.mon_cb.full;
        tr.empty = vif.mon_cb.empty;

        item_collected_port.write(tr);

        `uvm_info("MON", $sformatf("push_data: %h data_out: %h", tr.push_data, tr.data_out), UVM_HIGH)

    endtask

endclass