
class circular_fifo_fwft_test #(
    parameter int BUFFER_SIZE = 8,
    parameter type T = logic[31:0]
) extends uvm_test;

        `uvm_component_param_utils(circular_fifo_fwft_test #(BUFFER_SIZE, T))

  circular_fifo_fwft_unit_env #(BUFFER_SIZE,T) env;

  function new(string name ="circular_fifo_fwft_test", uvm_component parent = null);
            super.new(name,parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
          super.build_phase(phase);
            env = circular_fifo_fwft_unit_env#(BUFFER_SIZE,T)::type_id::create("env",this);
        endfunction

        virtual task run_phase(uvm_phase phase);
          circular_fifo_fwft_sequence #(BUFFER_SIZE,T) seq;
            seq = circular_fifo_fwft_sequence #(BUFFER_SIZE,T)::type_id::create("seq");

            phase.raise_objection(this);
            `uvm_info("TEST","Starting Sequence", UVM_LOW)
          	#60ns;
            seq.start(env.agt.sqr);
            #100ns;
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