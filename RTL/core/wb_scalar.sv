/*  
Arbiter for writeback
Takes inputs from all the EX units and sends one instruction per cycle to CDB
Round robin policy

TODO: IMPROVEMENTS
-> Mask based round robin like RS
-> Remove 1 cycle lag 
*/

//import config_pkg::*;

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
    logic[SCALAR_EX_COUNT-1:0] canditates1, canditates2_upper, canditates2_lower;
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
        .push1_i(lsu_result_i[3].valid),
        .push1_data_i(lsu_result_i[3]),
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

        canditates1 = eligible & full;

        winner1 = canditates1 & (~canditates1 + 1'b1);

        canditates2_upper = eligible & mask_upper & ~winner1;
        canditates2_lower = eligible & ~mask_upper & ~winner1;

        winner_upper = canditates2_upper & (~canditates2_upper + 1'b1);
        winner_lower = canditates2_lower & (~canditates2_lower + 1'b1);

        winner2 = (|canditates2_upper) ? winner_upper : winner_lower;

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

        wb_ready_o = ~(full | next_full);
        
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