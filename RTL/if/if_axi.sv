interface if_axi #(

)(
    input logic clk_i,
    input logic reset_ni
);

    // NOTE - THIS IS CURRENTLY A WRAPPER FOR PREVIOUSLY IMPLEMENTED PRELOADS

    packet_pkg::mem_read_request_t mem_rd_req;
    packet_pkg::mem_write_request_t mem_wrt_req;
    packet_pkg::mem_read_response_t mem_rd_res;
    logic mem_wrt_ack;

    modport master (
        input clk_i, reset_ni,
        output mem_rd_req, mem_wrt_req,
        input mem_rd_res, mem_wrt_ack
    );

endinterface
