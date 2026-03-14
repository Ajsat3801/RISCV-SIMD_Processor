
class circular_fifo_fwft_agent #(
    parameter int BUFFER_SIZE = 8,
    parameter type T = logic[31:0]
) extends uvm_agent;

    circular_fifo_fwft_sequencer #(T) sqr;
    circular_fifo_fwft_driver #(BUFFER_SIZE, T) drv;
    circular_fifo_fwft_monitor #(BUFFER_SIZE, T) mon;

    virtual circular_fifo_fwft_if #(BUFFER_SIZE, T) vif;

    `uvm_component_param_utils(circular_fifo_fwft_agent #(BUFFER_SIZE, T))

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    // creating the children class of agent i.e. monitor, driver and sequencer
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = circular_fifo_fwft_monitor #(BUFFER_SIZE, T)::type_id::create("mon",this);

        // UVM active means you send inputs and monitor outputs. else you only monitor
        if(get_is_active() == UVM_ACTIVE) begin 
            sqr = circular_fifo_fwft_sequencer#(T)::type_id::create("sqr", this);
            drv = circular_fifo_fwft_driver#(BUFFER_SIZE, T)::type_id::create("drv", this);
        end

        if(!uvm_config_db#(virtual circular_fifo_fwft_if#(BUFFER_SIZE, T))::get(this, "", "vif", vif)) begin
            `uvm_fatal("AGT", "Could not get vif from config_db")
        end
        uvm_config_db #(virtual circular_fifo_fwft_if#(BUFFER_SIZE,T))::set(this,"*",vif, vif);

    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export); // connect driver to sequencer
        end
    endfunction

endclass