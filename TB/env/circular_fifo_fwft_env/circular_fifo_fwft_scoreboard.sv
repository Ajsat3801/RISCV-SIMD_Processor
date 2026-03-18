// define separate named entry points for expected and actual data
`uvm_analysis_imp_decl(_mon)

// max size of DPI call = 160 (4*32 SIMD data + 32 max metadata)
import "DPI-C" function void circular_fifo_fwft_model_create(int size);

import "DPI-C" function void circular_fifo_fwft_model_run(
	input bit[159:0] data,
	output bit[159:0] output_buffer,
	input bit push,
	input bit pop,
    output bit full,
    output bit empty,
  	input int numwords
);

class circular_fifo_fwft_scoreboard #(
    parameter int BUFFER_SIZE = 8,
    parameter type T = logic[31:0]
) extends uvm_scoreboard;

    `uvm_component_param_utils(circular_fifo_fwft_scoreboard #(BUFFER_SIZE, T))
    uvm_analysis_imp_mon #(circular_fifo_fwft_transaction #(T), circular_fifo_fwft_scoreboard#(BUFFER_SIZE, T)) mon_imp;

    localparam int NUM_WORDS = ($bits(T) + 31)/32;
  	bit done_flag = 1'b0;
    bit stimulus_done_flag = 1'b0;
    event done_ev;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    task done(); // sends event to test indicating evaluation is complete
        if(!done_flag) @done_ev;
    endtask
  
    function void stimulus_done(); // called when sequence generation is complete
        stimulus_done_flag = 1'b1;
    endfunction
    
    function void update_scoreboard_status(); // checks if the evaluation is complete after every sequence
        if(!done_flag && stimulus_done_flag) begin
            `uvm_info("SCB","Evaluation Complete",UVM_LOW)
            done_flag = 1'b1;
            ->done_ev;
        end
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        `uvm_info("SCB_BUILD", $sformatf("Scoreboard built"), UVM_HIGH)
        mon_imp = new("mon_imp", this);

        circular_fifo_fwft_model_create(BUFFER_SIZE);
    endfunction

	virtual function void write_mon(circular_fifo_fwft_transaction #(T) tr);

		bit[159:0] push_data = '0;
		bit[159:0] expected_data = '0;
		T expected_val;
        bit full, empty;

		push_data[$bits(T)-1:0] = tr.push_data;

        circular_fifo_fwft_model_run(push_data, expected_data, tr.push, tr.pop, full, empty, NUM_WORDS);

		expected_val = expected_data[$bits(T)-1:0];

        if(tr.data_out === expected_val && tr.empty === empty) begin
            `uvm_info("SCB_MATCH",$sformatf("\t|push_data: %h\t|push: %0d\t|pop: %0d\t|exp_out: %h \t|act_out: %h\t|exp_empty: %0d\t|act_empty: %0d\t",tr.push_data, tr.push, tr.pop, expected_val,tr.data_out,empty,tr.empty),UVM_MEDIUM)
        end else begin
          `uvm_error("SCB_ERROR",$sformatf("\t|push_data: %h\t|push: %0d\t|pop: %0d\t|exp_out: %h \t|act_out: %h\t|exp_empty: %0d\t|act_empty: %0d\t MISMATCH!",tr.push_data, tr.push, tr.pop, expected_val,tr.data_out,empty,tr.empty))
      	end
      
        update_scoreboard_status();
	endfunction

endclass