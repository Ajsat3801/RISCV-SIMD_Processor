// define separate named entry points for expected and actual data
`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

// max size of DPI call = 160 (4*32 SIMD data + 32 max metadata)

import "DPI-C" function void circular_fifo_fwft_model_create(int id);
import "DPI-C" function void circular_fifo_fwft_model_push(
  	input int id, 
  	input bit[159:0] data, 
  	input int numwords
);
import "DPI-C" function void circular_fifo_fwft_model_pop(
  	input int id,
  	output bit[159:0] data,
  	input int numwords
);
import "DPI-C" function void circular_fifo_fwft_model_peek(
  	input int id,
  	output bit[159:0] data,
  	input int numwords
);

class circular_fifo_fwft_scoreboard #(
    parameter type T = logic[31:0]
) extends uvm_scoreboard;

    `uvm_component_param_utils(circular_fifo_fwft_scoreboard #(T))

    uvm_analysis_imp_expected #(circular_fifo_fwft_transaction #(T), circular_fifo_fwft_scoreboard#(T)) exp_imp;
    uvm_analysis_imp_actual #(circular_fifo_fwft_transaction #(T), circular_fifo_fwft_scoreboard #(T)) act_imp;

    static int global_id_count = 0; // we are creating unique ID for each instance of queue in the model
    local int m_id;
    localparam int NUM_WORDS = ($bits(T) + 31)/32;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        m_id = global_id_count++;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("SCB_BUILD", $sformatf("Scoreboard built. m_id=%0d", m_id), UVM_NONE)
        exp_imp = new("exp_imp", this);
        act_imp = new("act_imp", this);

        circular_fifo_fwft_model_create(m_id);
    endfunction
  
    virtual function void write_expected(circular_fifo_fwft_transaction #(T) tr);
      
        if(tr.push) begin
			bit[159:0] push_data = '0;
			push_data[$bits(T)-1:0] = tr.push_data;

			`uvm_info("SCB_PUSH",$sformatf("Sent Value=%h [ID:%0d]",tr.push_data,m_id), UVM_NONE)

			circular_fifo_fwft_model_push(m_id, push_data , NUM_WORDS);
        end
    endfunction

    virtual function void write_actual(circular_fifo_fwft_transaction #(T) tr);
      bit[159:0] expected_data;
	  T expected_val;

      //`uvm_info("SCB_ACT", $sformatf("pop=%0b data_out=%h id=%0d",tr.pop, tr.data_out, m_id),UVM_NONE)

      if(tr.pop) begin
        circular_fifo_fwft_model_pop(m_id, expected_data, NUM_WORDS);
        expected_val = expected_data[$bits(T)-1:0];
        `uvm_info("SCB_POP", $sformatf("expected_val=%h | actual_val=%h", expected_val,tr.data_out),UVM_NONE)
      end
      else begin
        circular_fifo_fwft_model_peek(m_id, expected_data, NUM_WORDS);
        expected_val = expected_data[$bits(T)-1:0];
        `uvm_info("SCB_PEEK", $sformatf("PEEK expected_val=%h | actual_val=%h", expected_val, tr.data_out),UVM_NONE)
      end

      if(tr.data_out !== expected_val) begin
        `uvm_error("SCB_MISMATCH", $sformatf("[ID:%0d] Expected: %h | RTL Op: %h", m_id, expected_val, tr.data_out))
      end else begin
        `uvm_info("SCB_MATCH", $sformatf("[ID:%d] Data out: %h",m_id,tr.data_out),UVM_NONE)
      end
        
    endfunction


endclass