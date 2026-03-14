typedef uvm_component_registry #(circular_fifo_fwft_test#(8,logic[31:0]), "circular_fifo_fwft_test") test_reg;

class circular_fifo_fwft_test #(
    parameter int BUFFER_SIZE = 8,
    parameter type T = logic[31:0]
) extends uvm_test;

        `uvm_component_param_utils(circular_fifo_fwft_test #(BUFFER_SIZE, T))

        circular_fifo_fwft_unit_env env;

        function new(string name ="circular_fifo_fwft_test", uvm_component parent = null);
            super.new(name,parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase();
            env = circular_fifo_fwft_unit_env::type_id::create("env",this);
        endfunction

        virtual task run_phase(uvm_phase phase);
            circular_fifo_fwft_sequence seq;
            seq = circular_fifo_fwft_sequence::type_id::create("seq");

            phase.raise_objection(this);
            `uvm_info("TEST","Starting Sequence", UVM_LOW)
            seq.start(env.agt.sqr);
            #100ns;
            phase.drop_objection(this);
        endtask

        virtual function void report_phase(uvm_phase phase);
            uvm_report_server svr;
            svr = uvm_report_mgr::get_report_server();

            if(svr.get_severity_count(UVM_ERROR) > 0) begin
                `uvm_info("TEST_RESULT","------ TEST FAILED ------", UVM_NONE)
            end else begin
                `uvm_info("TEST_RESULT","------ TEST PASSED ------", UVM_NONE)
            end
        endfunction

endclass