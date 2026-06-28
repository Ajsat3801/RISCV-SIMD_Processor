/* ------------------------------------------------------------------------------------------------ 
 *                                    CONTROLLER FOR DATA MEMORY
 * ------------------------------------------------------------------------------------------------
 *  
 *  Functions/Behavior:
 *  ->  Acts as an interface between the core and the data memory
 *  ->  Compiles memory request combinatorially from the LSU output each cycle.
 *  ->  Asserts write enable for store instructions
 *  ->  registers ROB ID, PRF tag and bank index on the clock edge, and forwards memory read data
 *      to scalar or vector writeback arbiters in next cycle for loads.
 *  ->  Scalar loads slice one 32-bit word from the 128-bit dmem output using the registered bank
 *      index. Vector loads forward the full 128-bit read data.
 *
 *  Inputs:
 *  ->  clock, reset_n
 *  ->  lsu_output — Output packet from the load-store unit.
 *  ->  dmem_dout (128 bits) — Read data returned by data memory on the cycle after a request.
 *
 *  Outputs:
 *  ->  dmem_req_o — Request to data memory each cycle.
 *  ->  sc_wb_o — Scalar writeback result.
 *  ->  vc_wb_o — Vector writeback result.
 *
 *  Notes:
 *  ->  For scalar stores, write enable is one-hot encoded using addr[1:0] (byte lane select). For
 *      vector stores, all write-enable lanes are asserted (write_enable = '1).
 *  ->  Stores and loads with forwarded values are not written back through this module, handled
 *      directly by the LSU. Writeback valids here are only asserted for non-forwarded loads.
 *  ->  The data memory always returns a read value regardless of whether a write occurred. This
 *      module forwards that (potentially garbage) data to the writeback arbiters every cycle, but
 *      valid signals gate whether arbiters accept it.
 *  ->  There is an inherent one-cycle latency: address & write-enable go to dmem combinatorially,
 *      but ROB ID, PRF tag, bank index, and valids are registered, aligning with the memory's
 *      one-cycle read latency.
 *  ->  sc_wb_valid and vc_wb_valid are mutually exclusive.
 *
 * ------------------------------------------------------------------------------------------------
 */

module data_dmem_controller (
    input  logic clk_i,
    input  logic reset_ni,

    input  packet_pkg::load_store_entry_t lsu_output,

    input  signal_pkg::vector_data_t dmem_dout_i,
    output packet_pkg::dmem_request_t dmem_req_o,

    output packet_pkg::sc_ex_result_t sc_wb_o,
    output packet_pkg::vc_ex_result_t vc_wb_o
);

    signal_pkg::rob_address_t rob_id_q;
    signal_pkg::prf_tag_t prf_tag_q;
    logic [1:0] idx;
    logic sc_wb_valid, vc_wb_valid;

    always_comb begin
        /* 
         *  COMPUTING INPUTS AND OUTPUTS FROM DMEM
         *  ->  dmem_dout_i is stored into a vector_data_t format
         *  ->  lsb 2 bits of dmem address removed as it determines bank
         *  ->  write enable is set as 1111 if vector store, else one hot for bank of store
         */ 

        dmem_req_o.data = lsu_output.data;
        dmem_req_o.address = lsu_output.mem_addr[9:2];

        if (!lsu_output.valid || !lsu_output.is_store) dmem_req_o.write_enable = '0;
        else if (lsu_output.is_vector) dmem_req_o.write_enable = '1;
        else begin
            dmem_req_o.write_enable = '0;
            dmem_req_o.write_enable[lsu_output.mem_addr[1:0]] = 1'b1;
        end
        
    end

    always_comb begin
        /*
         *  COMPUTING OUTPUTS TO WRITEBACK
         *  ->  valids computed in always_ff block, 
         *  ->  rob id and prf tag are registered from the input and sent to output
         *  ->  send the whole vector data to vector output and slice of data to scalar output 
         */
        
        vc_wb_o.valid   = vc_wb_valid;
        vc_wb_o.rob_id  = rob_id_q;
        vc_wb_o.prf_tag = prf_tag_q;
        vc_wb_o.data    = dmem_dout_i;
        
        sc_wb_o.valid   = sc_wb_valid;
        sc_wb_o.rob_id  = rob_id_q;
        sc_wb_o.prf_tag = prf_tag_q;
        sc_wb_o.data    = dmem_dout_i[idx];

    end

    always @(posedge clk_i) begin
        /*
         *  REGISTERING INPUTS
         *  ->  stores values in registers from the input which is required by the output data
                structures such as ROB ID, PRF tag etc
         */
        if(!reset_ni) begin
            rob_id_q <= '0;
            prf_tag_q <= '0;
            idx <= '0;
            sc_wb_valid <= 1'b0;
            vc_wb_valid <= 1'b0;
        end
        else begin
            rob_id_q  <= lsu_output.rob_id;
            prf_tag_q <= lsu_output.prf_tag;
        
            idx <= lsu_output.mem_addr[1:0];

            sc_wb_valid <= lsu_output.valid && !lsu_output.is_vector && !lsu_output.is_store;
            vc_wb_valid <= lsu_output.valid && lsu_output.is_vector && !lsu_output.is_store;
        end
        
    end

endmodule