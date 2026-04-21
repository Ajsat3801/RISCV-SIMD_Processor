
module vc_rs (
    input clk_i,
    input reset_ni,
    input flush_i,

    operand_bus_if.rs sc_operand_bus,
    dispatch_bus_if.rs vc_dispatch_bus,

    signal_pkg::vc_dispatched_instr_t dispatched_instr_o,
);

endmodule