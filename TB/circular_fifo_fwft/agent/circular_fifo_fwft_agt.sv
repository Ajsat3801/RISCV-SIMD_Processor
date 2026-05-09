
class lib_fifo_fwft_1push_agt extends uvm_agent;

    lib_fifo_fwft_1push_sqr sqr;
    lib_fifo_fwft_1push_drv drv;
    lib_fifo_fwft_1push_mon mon;

    virtual lib_fifo_fwft_1push_if vif;

    `uvm_component_utils(lib_fifo_fwft_1push_agt)

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    // creating the children class of agent i.e. monitor, driver and sequencer
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = lib_fifo_fwft_1push_mon::type_id::create("mon",this);

        if(get_is_active() == UVM_ACTIVE) begin // UVM_ACTIVE = send inputs to DUT, UVM_PASSIVE = only Monitor
            sqr = lib_fifo_fwft_1push_sqr::type_id::create("sqr", this);
            drv = lib_fifo_fwft_1push_drv::type_id::create("drv", this);
        end

        if(!uvm_config_db #(virtual lib_fifo_fwft_1push_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("AGT", "Could not get vif from config_db")
        end
      uvm_config_db #(virtual lib_fifo_fwft_1push_if)::set(this,"*","vif", vif);

    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export); // connect driver to sequencer
        end
    endfunction

endclass