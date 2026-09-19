
    module ex_load_store(
        input logic clk_i,
        input logic reset_ni,
        input logic flush_i,

        // LSU <- PRF connections
        input  packet_pkg::sc_ex_request_t sc_ex_req_i,
        input  signal_pkg::data_t sc_store_data_i,
        input  signal_pkg::vector_data_t vc_store_data_i,

        // LSU <-> ROB connections (for requesting/snooping store retires only)
        if_retirement_bus.lsu retire_instr_i,
        output packet_pkg::store_retire_request_t store_retire_req_o,

        // LSU <-> Dcache connections
        output packet_pkg::load_store_entry_t dcache_req_o,
        input logic dcache_rdy_i,

        // LSU <-> WB connections (for forwards only)
        output packet_pkg::sc_ex_result_t sc_fwd_res_o,
        output packet_pkg::vc_ex_result_t vc_fwd_res_o,

        /// LSU -> RS connections (for backpressure only)
        output logic sc_ex_rdy_o,
        output logic vc_ex_rdy_o
    );

    

endmodule