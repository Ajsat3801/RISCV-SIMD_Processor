
class circular_fifo_fwft_test #(
    parameter int BUFFER_SIZE = 8,
    parameter type T = logic[31:0]
) extends uvm_test;

    `uvm_component_param_utils(circular_fifo_fwft_test #(BUFFER_SIZE, T))

  	circular_fifo_fwft_unit_env #(BUFFER_SIZE,T) env;
  	virtual circular_fifo_fwft_if #(BUFFER_SIZE, T) vif;

  	function new(string name ="circular_fifo_fwft_test", uvm_component parent = null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = circular_fifo_fwft_unit_env#(BUFFER_SIZE,T)::type_id::create("env",this);
        if (!uvm_config_db #(virtual circular_fifo_fwft_if#(BUFFER_SIZE,T))::get(this,"","vif",vif)) begin 
            `uvm_fatal("TEST", "Failed to get vif from uvm_config_db")
        end
    endfunction
  
  	task apply_reset(int unsigned cycles = 5); // reset_n is 0 for 5 cycles and then set
    	vif.reset_n <= 1'b0;
    	repeat (cycles) @(posedge vif.clk);
    	vif.reset_n <= 1'b1;
	endtask

    virtual task run_phase(uvm_phase phase);
        circular_fifo_fwft_sequence #(BUFFER_SIZE,T) seq;
        seq = circular_fifo_fwft_sequence #(BUFFER_SIZE,T)::type_id::create("seq");

        phase.raise_objection(this);	
        `uvm_info("TEST","Starting Random Test", UVM_LOW)

		apply_reset();  	
        seq.start(env.agt.sqr); // sequencer starts sending values

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