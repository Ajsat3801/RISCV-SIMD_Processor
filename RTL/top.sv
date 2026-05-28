/* ------------------------------------------------------------------------------------------------
 *                                      TOP MODULE OF THE PROCESSOR
 * ------------------------------------------------------------------------------------------------
 *  Function/Behavior:
 *  ->  Integrates core with Instruction memory and data memory.
 *  ->  MUX to send preload data into both memories.
 *  
 *  Inputs:
 *  Outputs:
 *  Notes:
 *  -----------------------------------------------------------------------------------------------
 */

module top(
    input logic clk_i,
    input logic reset_ni,

    input logic compute_i,

    input logic imem_preload_en_i,
    input packet_pkg::imem_request_t preload_imem_request_i,

    input logic dmem_preload_en_i,
    input packet_pkg::dmem_request_t preload_dmem_request_i,

    input  logic sc_prf_preload_en_i,
    input  signal_pkg::data_t sc_prf_preload_data_i,
    input  signal_pkg::prf_tag_t sc_prf_preload_addr_i, 

    input  logic vc_prf_preload_en_i,
    input  signal_pkg::vector_data_t vc_prf_preload_data_i,
    input  signal_pkg::prf_tag_t vc_prf_preload_addr_i
    
);

    logic [31:0] imem_dout;
    logic [7:0] imem_addr;
    signal_pkg::vector_data_t dmem_dout;
    packet_pkg::imem_request_t imem_request, core_imem_request;
    packet_pkg::dmem_request_t dmem_request, core_dmem_request;

    core u_core (
        .clk_i(clk_i),
        .reset_ni(reset_ni),

        .compute_i(compute_i),

        .sc_prf_preload_en_i(sc_prf_preload_en_i),
        .sc_prf_preload_data_i(sc_prf_preload_data_i),
        .sc_prf_preload_addr_i(sc_prf_preload_addr_i), 

        .vc_prf_preload_en_i(vc_prf_preload_en_i),
        .vc_prf_preload_data_i(vc_prf_preload_data_i),
        .vc_prf_preload_addr_i(vc_prf_preload_addr_i), 

        .imem_dout_i(imem_dout),
        .imem_addr_i(imem_addr),
        .imem_request_o(core_imem_request),

        .dmem_dout_i(dmem_dout),
        .dmem_request_o(core_dmem_request)

    );

    imem u_imem (
        .clk_i(clk_i),
        .imem_request_i(imem_request),
        .data_o(imem_dout),
        .address_o(imem_addr)
    );

    dmem u_dmem (
        .clk_i(clk_i),
        .dmem_request_i(dmem_request),
        .data_o(dmem_dout)
    );

    always_comb begin
        imem_request = (imem_preload_en_i) ? preload_imem_request_i : core_imem_request;
        dmem_request = (dmem_preload_en_i) ? preload_dmem_request_i : core_dmem_request;
    end

endmodule