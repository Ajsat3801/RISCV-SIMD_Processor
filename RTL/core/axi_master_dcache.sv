
module axi_controller (
    input logic clk_i,
    input logic reset_ni,
    
    // Controller <-> DCache - read channel
    input packet_pkg::mem_read_request_t dcache_mem_rd_req_i,
    output packet_pkg::mem_read_response_t dcache_mem_rd_res_o,
    
    // Controller <-> Dcache - write channel
    input packet_pkg::mem_write_request_t dcache_mem_wrt_req_i,
    output logic dcache_mem_wrt_done_o,

    // Controller <-> Dcache backpressure
    output logic dcache_mem_rd_rdy_o,
    output logic dcache_mem_wrt_rdy_o,

    // AXI input/output
    //<TODO: AXI Port>
);

endmodule