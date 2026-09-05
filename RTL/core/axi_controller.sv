
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

    /*// Controller <-> Icache - read only
    input packet_pkg::mem_read_request_t icache_mem_rd_req_i,
    output packet_pkg::mem_read_response_t icache_mem_rd_res_o,
    output logic icache_mem_rd_rdy_o,*/

    // AXI input/output
    if_axi.master axi_connection
);

    always_ff @(posedge clk_i) begin

        if(!reset_ni) begin
            dcache_mem_rd_res_o   <= '0;
            dcache_mem_wrt_done_o <= '0;

            axi_connection.mem_rd_req <= '0;
            axi_connection.mem_wrt_req <= '0;

            dcache_mem_rd_rdy_o  <= 1'b1;
            dcache_mem_wrt_rdy_o <= 1'b1;
        end
        else begin
    
            dcache_mem_rd_res_o   <= axi_connection.mem_rd_res;
            dcache_mem_wrt_done_o <= axi_connection.mem_wrt_ack;

            axi_connection.mem_rd_req <= dcache_mem_rd_req_i;
            axi_connection.mem_wrt_req <= dcache_mem_wrt_req_i;

            // ready falls when request register fills and rises when you forward to AXI
            // always high for now because request is forwarded directly to AXI
            dcache_mem_rd_rdy_o  <= 1'b1;
            dcache_mem_wrt_rdy_o <= 1'b1;
        end

    end
endmodule