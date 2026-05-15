/* ------------------------------------------------------------------------------------------------ 
 *                                    CONTROLLER FOR DATA MEMORY
 * ------------------------------------------------------------------------------------------------  
 *  Behavior/Functionality:
 *  ->  Acts as an interface between the core and the data memory
 *  ->  Sends data memory output directly to writeback abiters for load instructions
 *
 *  Inputs:
 *  ->  clock, reset
 *  ->  signal from load-store for memory operations
 *  ->  Value of data to be loaded from data memory (128 bits)
 *
 *  Outputs:
 *  ->  signals to data memory
 *      ->  write enable for each bank
 *      ->  memory address
 *      ->  data to be stored (128 bits)
 *  ->  signal to scalar writeback for loads
 *  ->  signal to vector writeback for loads
 *
 *  Notes:
 *  ->  stores and loads with forwarded values are not written back. They are handled directly by
        the load-store unit. Refer LSU implementation for details
    ->  the memory always returns a read value unless write enable is 1. this module forwards the
        garbage values to the arbiters, but the valids are set only if there was a valid signal 
        from the load-store unit.
 *
 * ------------------------------------------------------------------------------------------------
 */
module data_dmem_controller (
    input  logic clk_i,
    input  logic reset_ni,

    input  logic [127:0] dmem_data_i,

    input  packet_pkg::load_store_entry_t lsu_output,

    output logic [3:0] write_enable_o,
    output logic [7:0] mem_addr_o,
    output logic [127:0] dmem_data_o,

    output packet_pkg::sc_ex_result_t sc_wb_o,
    output packet_pkg::vc_ex_result_t vc_wb_o
);

    signal_pkg::rob_address_t rob_id_q;
    signal_pkg::prf_tag_t prf_tag_q;
    logic [1:0] idx;
    logic sc_wb_valid, vc_wb_valid;
    signal_pkg::vector_data_t dmem_data;

    always_comb begin
        /* 
         *  COMPUTING INPUTS AND OUTPUTS FROM DMEM
         *  ->  dmem_data_i is stored into a vector_data_t format
         *  ->  lsb 2 bits of dmem address removed as it determines bank
         *  ->  write enable is set as 1111 if vector store, else one hot for bank of store
         */ 
        
        dmem_data = dmem_data_i;

        dmem_data_o = lsu_output.data;
        mem_addr_o = lsu_output.mem_addr[9:2];

        if(!lsu_output.valid || !lsu_output.is_store) write_enable_o = '0;
        else if(lsu_output.is_vector) write_enable_o = '1;
        else begin
            write_enable_o =  '0;
            write_enable_o[lsu_output.mem_addr[1:0]] = 1'b1;
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
        vc_wb_o.data    = dmem_data;
        
        sc_wb_o.valid   = sc_wb_valid;
        sc_wb_o.rob_id  = rob_id_q;
        sc_wb_o.prf_tag = prf_tag_q;
        sc_wb_o.data    = dmem_data_i[idx];

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