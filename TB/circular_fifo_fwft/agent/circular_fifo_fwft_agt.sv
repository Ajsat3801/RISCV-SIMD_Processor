
class circular_fifo_fwft_agt extends uvm_agent;

    circular_fifo_fwft_sqr sqr;
    circular_fifo_fwft_drv drv;
    circular_fifo_fwft_mon mon;

    virtual circular_fifo_fwft_if vif;

    `uvm_component_utils(circular_fifo_fwft_agt)

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    // creating the children class of agent i.e. monitor, driver and sequencer
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = circular_fifo_fwft_mon::type_id::create("mon",this);

        if(get_is_active() == UVM_ACTIVE) begin // UVM_ACTIVE = send inputs to DUT, UVM_PASSIVE = only Monitor
            sqr = circular_fifo_fwft_sqr::type_id::create("sqr", this);
            drv = circular_fifo_fwft_drv::type_id::create("drv", this);
        end

        if(!uvm_config_db #(virtual circular_fifo_fwft_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("AGT", "Could not get vif from config_db")
        end
      uvm_config_db #(virtual circular_fifo_fwft_if)::set(this,"*","vif", vif);

    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export); // connect driver to sequencer
        end
    endfunction

endclass