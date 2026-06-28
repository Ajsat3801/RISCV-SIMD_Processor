/* ------------------------------------------------------------------------------------------------
 *                                      SCALAR WRITEBACK ARBITER
 * ------------------------------------------------------------------------------------------------
 *
 *  Functions / Behavior
 *  ->  Arbitrates writeback across all scalar execution units, so that only one result per cycle is
 *      sent to the Common Data Bus.
 *  ->  Each EX unit has its own FIFO buffer with First-Word-Fall-Through, ALU0 & ALU1 have depth 4,
 *      Multiply-Divide has depth 2, and LSU has depth 4.
 *  ->  The LSU FIFO supports two simultaneous pushes (push0 from LSU for forwarded loads and push1
 *      from the DMEM for loaded data, while all other FIFOs accept one push at a time.
 *  ->  Arbitration uses modified 2 step round robin policy
 *      ->  FIFOs that are full receive highest priority to prevent stalls.
 *      ->  A rotating mask selects the winner in round-robin order (refer to reservation station 
 *          implementation for details) among eligible non-full units.
 *  ->  On flush or reset, all FIFOs are cleared and the round-robin mask resets to slot 0.
 *
 *
 *  Inputs
 *  ->  clk, reset_ni & flush
 *  ->  ex_result_i — Array of result packets from each scalar EX unit
 *  ->  lsu_result_i — result packet from the LSU (the memory-return path).
 *
 *  Outputs
 *  ->  wb_ready_o — array of ready signals, one per unit
 *  ->  data_bus_o — CDB output port.
 *
 *  Notes
 *  ->  ready signals deasserted when a FIFO has 1 or lesser available slots, ex units do not have
 *      holding capability & handshake happens between RS and WB
 *  ->  Branches & stores bypass this unit to go directly to the ROB as there is no writeback into
 *      the register.
 *
 * ------------------------------------------------------------------------------------------------
 */

module wb_scalar (
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    // EX units
    input packet_pkg::sc_ex_result_t ex_result_i[SCALAR_EX_COUNT-1:0],
    input packet_pkg::sc_ex_result_t lsu_result_i,
    output logic wb_ready_o[SCALAR_EX_COUNT-1:0],

    if_data_bus.writeback data_bus_o
);

    packet_pkg::sc_ex_result_t fifo_heads[SCALAR_EX_COUNT-1:0]; 

    logic[EX_IDX_W-1:0] choice;
    logic[SCALAR_EX_COUNT-1:0] empty, full, next_full, eligible;
    logic[SCALAR_EX_COUNT-1:0] dequeue, dequeue_next;
    logic[SCALAR_EX_COUNT-1:0] mask, mask_upper, mask_next;
    logic[SCALAR_EX_COUNT-1:0] candidates1, candidates2_upper, candidates2_lower;
    logic[SCALAR_EX_COUNT-1:0] winner_upper, winner_lower, winner1, winner2;

    logic reset_wb_n;
    // circular FIFOs with FWFT, so we know what the head of the queue is immediately

    lib_fifo_fwft_1push #(
        .BUFFER_SIZE(4), 
        .T(packet_pkg::sc_ex_result_t) 
    ) alu0_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(ex_result_i[0].valid),
        .push_data_i(ex_result_i[0]),
        .pop_i(dequeue_next[0]),
        .data_o(fifo_heads[0]),
        .empty_o(empty[0]),
        .full_o(full[0]),
        .next_full_o(next_full[0])
    );

    lib_fifo_fwft_1push #(
        .BUFFER_SIZE(4),
        .T(packet_pkg::sc_ex_result_t)
    ) alu1_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(ex_result_i[1].valid),
        .push_data_i(ex_result_i[1]),
        .pop_i(dequeue_next[1]),
        .data_o(fifo_heads[1]),
        .empty_o(empty[1]),
        .full_o(full[1]),
        .next_full_o(next_full[1])
    );

    lib_fifo_fwft_1push #(
        .BUFFER_SIZE(2),
        .T(packet_pkg::sc_ex_result_t)
    ) muldiv_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(ex_result_i[2].valid),
        .push_data_i(ex_result_i[2]),
        .pop_i(dequeue_next[2]),
        .data_o(fifo_heads[2]),
        .empty_o(empty[2]),
        .full_o(full[2]),
        .next_full_o(next_full[2])
    );

    lib_fifo_fwft_2push #(
        .BUFFER_SIZE(4),
        .T(packet_pkg::sc_ex_result_t)
    ) lsu_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push0_i(ex_result_i[3].valid),
        .push0_data_i(ex_result_i[3]),
        .push1_i(lsu_result_i.valid),
        .push1_data_i(lsu_result_i),
        .pop_i(dequeue_next[3]),
        .data_o(fifo_heads[3]),
        .empty_o(empty[3]),
        .full_o(full[3]),
        .next_full_o(next_full[3])
    );

    assign reset_wb_n = reset_ni && !flush_i;

    always_comb begin

        eligible = ~empty;

        mask_upper = mask[0];
        for(int i=1;i<SCALAR_EX_COUNT; i++) begin
            mask_upper[i] = mask_upper[i-1] | mask[i];
        end

        candidates1 = eligible & full;

        winner1 = candidates1 & (~candidates1 + 1'b1);

        candidates2_upper = eligible & mask_upper & ~winner1;
        candidates2_lower = eligible & ~mask_upper & ~winner1;

        winner_upper = candidates2_upper & (~candidates2_upper + 1'b1);
        winner_lower = candidates2_lower & (~candidates2_lower + 1'b1);

        winner2 = (|candidates2_upper) ? winner_upper : winner_lower;

        if(|winner1) begin // something is full
            for(int i=0; i<SCALAR_EX_COUNT; i++) begin
                if(winner1[i]) choice = i[EX_IDX_W-1:0];
            end
            mask_next = {winner1[SCALAR_EX_COUNT-2:0], winner1[SCALAR_EX_COUNT-1]};
            dequeue_next = winner1;
            data_bus_o.valid   = 1'b1;
            data_bus_o.prf_tag = fifo_heads[choice].prf_tag;
            data_bus_o.rob_id  = fifo_heads[choice].rob_id;
            data_bus_o.data    = fifo_heads[choice].data;
        end
        else if(|winner2) begin // nothing full but something empty
            for(int i=0; i<SCALAR_EX_COUNT; i++) begin
                if(winner2[i]) choice = i[EX_IDX_W-1:0];
            end
            mask_next = {winner2[SCALAR_EX_COUNT-2:0], winner2[SCALAR_EX_COUNT-1]};
            dequeue_next = winner2;
            data_bus_o.valid   = 1'b1;
            data_bus_o.prf_tag = fifo_heads[choice].prf_tag;
            data_bus_o.rob_id  = fifo_heads[choice].rob_id;
            data_bus_o.data    = fifo_heads[choice].data;
        end
        else begin // all empty
            data_bus_o.valid   = 1'b0;
            data_bus_o.prf_tag = '0;
            data_bus_o.rob_id  = '0;
            data_bus_o.data    = '0;
            mask_next = mask;
            dequeue_next = '0;
        end

        wb_ready_o[0] = ~(full[0] | next_full[0]);
        wb_ready_o[1] = ~(full[1] | next_full[1]);
        wb_ready_o[2] = ~(full[2] | next_full[2]);
        wb_ready_o[3] = ~(full[3] | next_full[3]);
        
    end

    always_ff @(posedge clk_i) begin

        if(!reset_ni || flush_i) begin
            mask <= {{SCALAR_EX_COUNT-1{1'b0}},1'b1};
            dequeue <= '0;
        end

        else begin
            mask <= mask_next;
            dequeue <= dequeue_next;
        end
    end

endmodule