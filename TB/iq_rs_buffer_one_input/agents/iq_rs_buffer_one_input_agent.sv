
class iq_rs_buffer_one_input_agent #(
    parameter int BUFFER_SIZE = 8,
    parameter type T = logic[31:0]
) extends uvm_agent;

    iq_rs_buffer_one_input_monitor #(BUFFER_SIZE, T) mon;
    iq_rs_buffer_one_input_driver #(BUFFER_SIZE, T) drv;
    iq_rs_buffer_one_input_sequencer #(T) sqr;

    virtual iq_rs_buffer_one_input_if #(BUFFER_SIZE, T) vif;

    `uvm_component_param_utils(iq_rs_buffer_one_input_agent #(BUFFER_SIZE, T))

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    virtual function build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = iq_rs_buffer_one_input_monitor #(BUFFER_SIZE, T)::type_id::create("mon");
        drv = iq_rs_buffer_one_input_driver #(BUFFER_SIZE, T)::type_id::create("drv");
        seq = iq_rs_buffer_one_input_sequencer #(BUFFER_SIZE, T)::type_id::create("sqr");

        if(!uvm_config_db#(virtual iq_rs_buffer_one_input_if #(BUFFER_SIZE, T))::get(this,"","vif",vif)) begin
            `uvm_fatal("AGT","Unable to fetch VIF from config database")
        end

        uvm_config_db #(virtual iq_rs_buffer_one_input_if #(BUFFER_SIZE, T))::set(this,"*","vif",vif);

    endfunction

    virtual function connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass