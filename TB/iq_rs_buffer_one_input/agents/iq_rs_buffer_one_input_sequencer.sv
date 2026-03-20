
class iq_rs_buffer_one_input_sequencer #(
    parameter type T = logic[31:0]
) extends uvm_sequencer (iq_rs_buffer_one_input_transaction #(T));

    `uvm_component_param_utils(iq_rs_buffer_one_input_sequencer #(T))

    function new(string name, uvm_component parent)
        super.new(name,parent);
    endfunction

endclass