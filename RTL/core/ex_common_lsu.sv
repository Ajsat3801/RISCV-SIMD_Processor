
module ex_common_lsu(
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    input packet_pkg::sc_ex_request_t sc_ex_request_i,
    input packet_pkg::vc_ex_request_t vc_ex_request_i,

    if_retirement_bus.lsu retire_instr_i,

    output packet_pkg::sc_ex_result_t sc_ex_result_o,
    output packet_pkg::vc_ex_result_t vc_ex_result_o,

    output logic sc_ex_ready_o,
    output logic vc_ex_ready_o
);

/* NOTE:
 * Placeholders here, actual logic to be implemented after we figure OpenRAM out
 */
always_ff @(posedge clk_i) begin
    sc_ex_result_o <= '0;
    vc_ex_result_o <= '0;
    sc_ex_ready_o  <= '0;
    sc_ex_ready_o  <= '0;
end

endmodule