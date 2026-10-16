
module axi_controller (
    input logic clk_i,
    input logic reset_ni,


    // Controller <-> Icache - read & backpressure only
    input packet_pkg::mem_read_request_t icache_mem_rd_req_i,
    output packet_pkg::mem_read_response_t icache_mem_rd_res_o,
    output logic icache_mem_rd_rdy_o,

    // AXI input/output
    // <TODO> AXI connection
);

endmodule