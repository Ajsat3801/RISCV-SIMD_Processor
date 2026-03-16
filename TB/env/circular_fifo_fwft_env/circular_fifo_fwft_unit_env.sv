
class circular_fifo_fwft_unit_env #(
    parameter int BUFFER_SIZE = 8,
    parameter type T = logic[31:0]
) extends uvm_env;

    `uvm_component_param_utils(circular_fifo_fwft_unit_env#(BUFFER_SIZE, T))

    circular_fifo_fwft_agent #(BUFFER_SIZE, T) agt;
    circular_fifo_fwft_scoreboard #(BUFFER_SIZE, T) scb;

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = circular_fifo_fwft_agent #(BUFFER_SIZE, T)::type_id::create("agt",this);
        scb = circular_fifo_fwft_scoreboard #(BUFFER_SIZE, T)::type_id::create("scb", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.item_collected_port.connect(scb.mon_imp);
    endfunction

endclass