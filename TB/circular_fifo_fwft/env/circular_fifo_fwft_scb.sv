// define separate named entry points for expected and actual data
import circular_fifo_fwft_tb_config_pkg::*;

class circular_fifo_fwft_scb extends uvm_scoreboard;

    `uvm_component_utils(circular_fifo_fwft_scb)
    uvm_analysis_imp #(circular_fifo_fwft_tr, circular_fifo_fwft_scb) mon_imp;
    circular_fifo_fwft_ref_model_adapter ref_model;

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
      
        ref_model = new();
        ref_model.create_model();

    endfunction

	virtual function void write(circular_fifo_fwft_tr tr);

		T data_out;
        bit full, empty;
        bit pass;
        string msg;

        ref_model.run_ref_model(
            .push_dataT(tr.push_data),
            .push(tr.push),
            .pop(tr.pop),
            .data_outT(data_out),
            .full(full),
            .empty(empty)
        );

        pass = tr.data_out === data_out && tr.empty === empty && tr.full == full;
        msg = {
            $sformatf("\t|data_in: %h\t|psh: %0d\t|pop: %0d\t||",tr.push_data, tr.push, tr.pop),
            $sformatf("exp_out: %h\t|act_out: %h\t||",data_out, tr.data_out),
            $sformatf("exp_empty: %0d\t|act_empty: %0d\t||",empty, tr.empty),
            $sformatf("exp_full: %0d\t|act_full:%0d", full, tr.full)
        }

        if(pass) begin
            `uvm_info("SCB_MATCH", msg, UVM_MEDIUM)
        end else begin
          `uvm_error("SCB_ERROR", msg)
      	end
      
        update_scoreboard_status();
	endfunction

endclass