/*  
Arbiter for writeback
Takes inputs from all the EX units and sends one instruction per cycle to CDB
Round robin policy
*/

//import config_pkg::*;

module wb_vector (
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    // EX units
    input packet_pkg::vc_ex_result_t ex_result_i[VECTOR_EX_COUNT-1:0],
    output logic wb_ready_o[VECTOR_EX_COUNT-1:0],

    if_data_bus.writeback data_bus_o
);

    packet_pkg::vc_ex_result_t fifo_heads[VECTOR_EX_COUNT-1:0]; 

    logic choice;
    logic[VECTOR_EX_COUNT-1:0] empty, full, next_full;
    logic[VECTOR_EX_COUNT-1:0] dequeue;

    logic wb_chosen, reset_wb_n;

    // circular FIFOs with FWFT, so we know what the head of the queue is immediately

    lib_circular_fifo_fwft #(
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

    lib_circular_fifo_fwft #(
        .BUFFER_SIZE(4),
        .T(packet_pkg::vc_ex_result_t)
    ) lsu_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(ex_result_i[1].valid),
        .push_data_i(ex_result_i[1]),
        .pop_i(dequeue[1]),
        .data_o(fifo_heads[1]),
        .empty_o(empty[1]),
        .full_o(full[1]),
        .next_full_o(next_full[1])
    );

    assign reset_wb_n = reset_ni && !flush_i;

    always_comb begin

        wb_chosen = 1'b0;

        if(full[0] || (!full[1] && !empty[0] && empty[1])) begin
            choice = 1'b0;
            wb_chosen = (empty[0]) ? 1'b0 : 1'b1;
            dequeue = (empty[0]) ? 2'b00 : 2'b01;
        end
        else begin
            choice = 1'b1;
            wb_chosen = (empty[1]) ? 1'b0 : 1'b1;
            dequeue = (empty[1]) ? 2'b00 : 2'b10;
        end

        if(wb_chosen) begin
            data_bus_o.valid   <= 1'b1;
            data_bus_o.prf_tag <= fifo_heads[choice].prf_tag;
            data_bus_o.rob_id  <= fifo_heads[choice].rob_id;
            data_bus_o.data    <= fifo_heads[choice].data;
        end
        else begin
            data_bus_o.valid   <= 1'b0;
            data_bus_o.prf_tag <= '0;
            data_bus_o.rob_id  <= '0;
            data_bus_o.data    <= '0;
        end
    end

    generate
        for (genvar i=0; i<VECTOR_EX_COUNT; i++) begin
            assign wb_ready_o[i] = ~(full[i] | next_full[i]);
        end
    endgenerate

endmodule