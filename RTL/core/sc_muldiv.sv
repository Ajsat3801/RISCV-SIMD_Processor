module sc_muldiv(
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    // connection to reservation station
    input signal_pkg::sc_ex_input_signal_t muldiv_input_i,
    output logic ex_ready_o,

    //connection to writeback arbitrer
    input logic wb_ready_i,
    output signal_pkg::sc_ex_output_signal_t muldiv_result_o
);

// radix booth 4 iterative multiplier
// restoring iterative divide


endmodule