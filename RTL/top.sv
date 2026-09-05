/* ------------------------------------------------------------------------------------------------
 *                                      TOP MODULE OF THE PROCESSOR
 * ------------------------------------------------------------------------------------------------
 *  Function/Behavior:
 *  ->  Integrates the core, instruction memory, and data memory.
 *  ->  Arbitrates between the core's memory requests and externally supplied preload requests.
 *  ->  Provides preload path so IMEM, DMEM and both scalar and vector PRFs can be initialized directly
 *      from testbenchinputs before or during simulation, bypassing normal core-driven requests.
 *  
 *  Inputs:
 *  ->  clk & reset_n
 *  ->  compute_i – Enables/starts core computation (passed straight through to the core).
 *  ->  imem_preload_en_i – preloads instruction from input into imem instead of executing the
 *      core's own instruction request.
 *  ->  preload_imem_request_i – Preload request packet when imem_preload_en_i is asserted.
 *  ->  dmem_preload_en_i – preloads into data memory instead of the core's own data request.
 *  ->  preload_dmem_request_i – Preload request packet when dmem_preload_en_i is asserted.
 *  ->  sc_prf_preload_en_i – Enables direct preload of the scalar physical register file
 *  ->  sc_prf_preload_data_i – Data value written into the scalar PRF during preload.
 *  ->  sc_prf_preload_addr_i – Physical register tag/address targeted by the scalar PRF preload.
 *  ->  vc_prf_preload_en_i – Enables direct preload of the vector physical register file.
 *  ->  vc_prf_preload_data_i – Data value written into the vector PRF during preload.
 *  ->  vc_prf_preload_addr_i – Physical register tag/address targeted by the vector PRF preload.
 *
 *  Notes:
 *  ->  Module contains no outputs. All results stay in the DMEM. To read DMEM outputs call
 *      directly from the test environment
 *
 *  -----------------------------------------------------------------------------------------------
 */

module top(
    input logic clk_i,
    input logic reset_ni,

    input logic compute_i,

    input logic imem_preload_en_i,
    input packet_pkg::imem_request_t preload_imem_request_i,

    if_axi.master axi_connection
    
);

    logic [31:0] imem_dout;
    logic [7:0] imem_addr;
    packet_pkg::imem_request_t imem_request, core_imem_request;

    core u_core (
        .clk_i(clk_i),
        .reset_ni(reset_ni),

        .compute_i(compute_i),

        .imem_dout_i(imem_dout),
        .imem_addr_i(imem_addr),
        .imem_request_o(core_imem_request),

        .axi_connection(axi_connection)
    );

    imem u_imem (
        .clk_i(clk_i),
        .imem_request_i(imem_request),
        .data_o(imem_dout),
        .address_o(imem_addr)
    );

    always_comb begin
        imem_request = (imem_preload_en_i) ? preload_imem_request_i : core_imem_request;
    end

endmodule