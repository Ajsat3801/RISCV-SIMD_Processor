/*  
Arbiter for writeback
Takes inputs from all the EX units and sends one instruction per cycle to CDB
Round robin policy
TODO: integrate vector from scalar
*/

//import config_pkg::*;

module sc_wb_arbiter (
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    // EX units
    input signal_pkg::sc_ex_output_signal_t ex_result_i[VECTOR_EX_COUNT-1:0],
    output logic wb_ready_o[VECTOR_EX_COUNT-1:0],

    data_bus_if.writeback vector_data_bus_o
);

    storage_pkg::vc_result_entry_t fifo_heads[VECTOR_EX_COUNT-1:0]; 

    logic choice, choice_idx, choice_next;
    logic[VECTOR_EX_COUNT-1:0] empty, full, next_full;
    logic[VECTOR_EX_COUNT-1:0] dequeue, dequeue_next;

    logic reset_wb_n;

    // circular FIFOs with FWFT, so we know what the head of the queue is immediately

    circular_fifo_fwft #(
        .BUFFER_SIZE(4), 
        .T(storage_pkg::vc_result_entry_t) 
    ) valu_fifo (
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

    circular_fifo_fwft #(
        .BUFFER_SIZE(4),
        .T(storage_pkg::vc_result_entry_t)
    ) lsu_fifo (
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

    always_comb begin

        choice_next  = choice;
        dequeue_next = '0;

        if(full[1]) choice_idx  = 1'b1;
        else if(full[0]) choice_idx  = 1'b0;
        else choice_idx = (empty == 2'b00) ? choice : empty[1];
        
        dequeue_next[choice_idx] = (empty != 2'b11);
        choice_next = ~choice_idx;
        
        reset_wb_n = reset_ni && !flush_i;

        wb_ready_o = ~(full | next_full);
        
    end

    always_ff @(posedge clk_i) begin

        if(!reset_ni || flush_i) begin
            choice  <= '0;
            dequeue <= '0;
        end

        else begin
            if(wb_chosen) begin
                vector_data_bus_o.valid   <= 1'b1;
                vector_data_bus_o.prf_tag <= fifo_heads[choice_idx].prf_tag;
                vector_data_bus_o.rob_id  <= fifo_heads[choice_idx].rob_id;
                vector_data_bus_o.data    <= fifo_heads[choice_idx].data;
                choice  <= choice_next;
                dequeue <= dequeue_next;
            end
            else begin
                vector_data_bus_o.valid   <= 1'b0;
                vector_data_bus_o.prf_tag <= '0;
                vector_data_bus_o.rob_id  <= '0;
                vector_data_bus_o.data    <= '0;
                dequeue <= '0; //sus
            end
        end
    end

endmodule