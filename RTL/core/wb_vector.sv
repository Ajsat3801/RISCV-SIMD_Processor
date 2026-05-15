/*  -----------------------------------------------------------------------------------------------
 *                                ARBITER FOR VECTOR WRITEBACK
 *  -----------------------------------------------------------------------------------------------
 *  Behavior / Functionality
 *  ->  Arbitrates between results of vector ALU and vector load store operations to send a single
        result into the vector data bus for writeback.
 *  ->  Contains 2 circular fifos with FWFT, one supporting a single push, and second supporting
        two simultaneous pushes. (see FIFO RTL in lib directory for details)
 *  ->  Hardcoded arbitration policy - see implementation below for details
 *
 *  Inputs:
 *  ->  clock, reset, flush
 *  ->  array of vector ex results
 *  ->  separate input for forwarded load-store results
 *
 *  Outputs:
 *  ->  array of ready bits, one for each ex unit
 *  ->  vector data bus for writeback
 *
 *  Notes:
 *  ->  Forwarded load-store results have a separate input because it is a special case of load-
        store instruction which come directly from the LSU and not from the DMEM. 
 *  ->  Index 0 is vector ALU, Index 1 is LSU.
 *  -----------------------------------------------------------------------------------------------
*/

//import config_pkg::*;

module wb_vector (
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    input packet_pkg::vc_ex_result_t ex_result_i[VECTOR_EX_COUNT-1:0],
    input packet_pkg::vc_ex_result_t lsu_result_i,
    output logic wb_ready_o[VECTOR_EX_COUNT-1:0],

    if_data_bus.writeback data_bus_o
);

    packet_pkg::vc_ex_result_t fifo_heads[VECTOR_EX_COUNT-1:0]; 

    logic choice;
    logic[VECTOR_EX_COUNT-1:0] empty, full, next_full;
    logic[VECTOR_EX_COUNT-1:0] dequeue;

    logic wb_chosen, reset_wb_n;

    /* FIFOS
     *  ->  One FIFO with 1 push for vector ALU and second with 2 pushes for LSU
     *  ->  Fifo heads, dequeue, empty, full, next_full are all stored in packed array
     */
    lib_fifo_fwft_1push #(
        .BUFFER_SIZE(4), 
        .T(packet_pkg::vc_ex_result_t) 
    ) valu_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(ex_result_i[0].valid),
        .push_data_i(ex_result_i[0]),
        .pop_i(dequeue[0]),
        .data_o(fifo_heads[0]),
        .empty_o(empty[0]),
        .full_o(full[0]),
        .next_full_o(next_full[0])
    );

    lib_fifo_fwft_2push #(
        .BUFFER_SIZE(4),
        .T(packet_pkg::vc_ex_result_t)
    ) lsu_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push0_i(ex_result_i[1].valid),
        .push0_data_i(ex_result_i[1]),
        .push1_i(lsu_result_i.valid),
        .push1_data_i(lsu_result_i),
        .pop_i(dequeue[1]),
        .data_o(fifo_heads[1]),
        .empty_o(empty[1]),
        .full_o(full[1]),
        .next_full_o(next_full[1])
    );

    
    always_comb begin

        wb_chosen = 1'b0;

        /*  HARD-CODED ARBITRATION BETWEEN 2 QUEUES.  
         *  ->  If any queue is full, it gets priority.
         *  ->  If any queue is empty, the other queue gets priority.
         *  ->  Otherwise LSU gets priority
         */
        if(full[0] || (!full[1] && !empty[0] && empty[1])) begin
            choice    = 1'b0;
            wb_chosen = (empty[0]) ? 1'b0 : 1'b1;
            dequeue   = (empty[0]) ? 2'b00 : 2'b01;
        end
        else begin
            choice    = 1'b1;
            wb_chosen = (empty[1]) ? 1'b0 : 1'b1;
            dequeue   = (empty[1]) ? 2'b00 : 2'b10;
        end

        // Writeback outputs
        data_bus_o.valid   = wb_chosen;
        data_bus_o.prf_tag = fifo_heads[choice].prf_tag;
        data_bus_o.rob_id  = fifo_heads[choice].rob_id;
        data_bus_o.data    = fifo_heads[choice].data;

        // Reset and flush are treated as the same inside the FIFOs
        reset_wb_n = reset_ni && !flush_i;

        // Ready bits for each vector EX unit, sent to RS
        wb_ready_o[0] = ~(full[0] | next_full[0]);
        wb_ready_o[1] = ~(full[1] | next_full[1]);
        
    end

endmodule