
class circular_fifo_fwft_base_test extends uvm_test;

    `uvm_component_utils(circular_fifo_fwft_base_test)

  	circular_fifo_fwft_env env;
  	virtual circular_fifo_fwft_if vif;

  	function new(string name ="circular_fifo_fwft_base_test", uvm_component parent = null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = circular_fifo_fwft_env::type_id::create("env",this);
        if (!uvm_config_db #(virtual circular_fifo_fwft_if)::get(this,"","vif",vif)) begin 
            `uvm_fatal("TEST", "Failed to get vif from uvm_config_db")
        end
    endfunction
  
  	task apply_reset(int unsigned cycles = 5); // reset_n is 0 for 5 cycles and then set
    	vif.reset_n <= 1'b0;
    	repeat (cycles) @(posedge vif.clk);
    	vif.reset_n <= 1'b1;
	endtask

    virtual task run_sequence(); // each indivudual test overrides this task
        `uvm_fatal("TEST","run_sequence() must be overwritten")
    endtask

    virtual task run_phase(uvm_phase phase);
        
        phase.raise_objection(this);
        run_sequence();	

        env.scb.stimulus_done(); // sequence generation complete
        env.scb.done(); // evaluation complete

        phase.drop_objection(this);
    endtask

    virtual function void report_phase(uvm_phase phase);
        uvm_coreservice_t cs;
        uvm_report_server svr;
        
		cs = uvm_coreservice_t::get();
        svr = cs.get_report_server();

        if(svr.get_severity_count(UVM_ERROR) > 0) begin
            `uvm_info("TEST_RESULT","------ TEST FAILED ------", UVM_NONE)
        end else begin
            `uvm_info("TEST_RESULT","------ TEST PASSED ------", UVM_NONE)
        end
    endfunction

endclass