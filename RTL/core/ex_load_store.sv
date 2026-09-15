
    module ex_load_store(
        input logic clk_i,
        input logic reset_ni,
        input logic flush_i,

        // LSU <- PRF connections
        input  packet_pkg::sc_ex_request_t lsu_request_i,
        input  signal_pkg::data_t sc_store_data_i,
        input  packet_pkg::vc_lsu_ex_request_t vc_lsu_ex_request_i,

        // LSU <-> ROB connections (for requesting/snooping store retires only)
        if_retirement_bus.lsu retire_instr_i,
        output packet_pkg::store_retire_request_t store_retire_req_o,

        // LSU <-> Dcache connections
        output packet_pkg::load_store_entry_t lsu_output_o,
        input logic l1_dcache_ready_i,

        // LSU <-> WB connections (for forwards only)
        output packet_pkg::sc_ex_result_t sc_fwd_load_o,
        output packet_pkg::vc_ex_result_t vc_fwd_load_o,

        /// LSU -> RS connections (for backpressure only)
        output logic sc_ex_ready_o,
        output logic vc_ex_ready_o
    );

    

endmodule