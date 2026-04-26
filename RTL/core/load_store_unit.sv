
module load_store_unit(
    input logic clk_i,
    input logic reset_ni,
    input logic flush,

    signal_pkg::sc_ex_input_signal_t sc_lsu_dispatched_instr_i
    signal_pkg::vc_ex_input_signal_t vc_lsu_dispatched_instr_i

    signal_pkg::sc_ex_output_signal_t sc_lsu_result_o
    signal_pkg::vc_ex_output_signal_t vc_lsu_result_o

    output logic ex_ready_o
);

/* NOTE:
 * Placeholders here, actual logic to be implemented after we figure OpenRAM out
 */
always_comb begin
    sc_lsu_result_o = '0;
    vc_lsu_result_o = '0;
    ex_ready_o = '0;
end

endmodule