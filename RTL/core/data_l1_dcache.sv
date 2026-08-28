

module data_l1_dcache (
    input clk_i,
    input reset_ni,
    input flush_i,

    // connection to the cores
    input packet_pkg::load_store_entry_t lsu_output_i,
    input logic l1_dcache_ready_o,
    output packet_pkg::sc_ex_result_t sc_wb_o,
    output packet_pkg::vc_ex_result_t vc_wb_o,

    // connection to AXI contoller
    output packet_pkg::mem_request_t mem_request_o,
    input logic mem_request_ready_i,
    input packet_pkg::mem_response_t mem_response_i

);

    /*typedef struct packed {
        logic valid;
        logic is_store;
        logic is_vector;

        signal_pkg::prf_tag_t prf_tag;
        signal_pkg::rob_address_t rob_id;
        
        signal_pkg::mem_address_t mem_addr;

        signal_pkg::vector_data_t data;

    } load_store_entry_t;*/


endmodule : data_l1_dcache