/*  
Arbiter for writeback
Takes inputs from all the EX units and sends one instruction per cycle to CDB
Round robin policy
*/

//import config_pkg::*;

module sc_wb_arbiter #() (
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    // EX units
    input signal_pkg::ex_to_wb_signal_t ex_result_i[SCALAR_EX_COUNT-1:0],
    output logic wb_ready_o[SCALAR_EX_COUNT-1:0],

    data_bus_if.writeback scalar_data_bus_o
);

    storage_pkg::alu_result_entry_t fifo_heads[SCALAR_EX_COUNT-1:0]; 

    logic[EX_IDX_W-1:0] choice, choice_idx, choice_next;
    logic[SCALAR_EX_COUNT-1:0] empty, full;
    logic[SCALAR_EX_COUNT-1:0] dequeue, dequeue_next, request;
    logic wb_chosen, any_full;

    logic reset_wb_n;

    int i;

    // circular FIFOs with FWFT, so we know what the head of the queue is immediately

    circular_fifo_fwft #(
        .BUFFER_SIZE(4), 
        .T(storage_pkg::alu_result_entry_t) 
    ) alu0_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(ex_result_i[0].valid),
        .push_data_i(ex_result_i[0]),
        .pop_i(dequeue_next[0]),
        .data_o(fifo_heads[0]),
        .empty_o(empty[0]),
        .full_o(full[0])
    );

    circular_fifo_fwft #(
        .BUFFER_SIZE(4),
        .T(storage_pkg::alu_result_entry_t)
    ) alu1_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(ex_result_i[1].valid),
        .push_data_i(ex_result_i[1]),
        .pop_i(dequeue_next[1]),
        .data_o(fifo_heads[1]),
        .empty_o(empty[1]),
        .full_o(full[1])
    );

    circular_fifo_fwft #(
        .BUFFER_SIZE(2),
        .T(storage_pkg::alu_result_entry_t)
    ) muldiv_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(ex_result_i[2].valid),
        .push_data_i(ex_result_i[2]),
        .pop_i(dequeue_next[2]),
        .data_o(fifo_heads[2]),
        .empty_o(empty[2]),
        .full_o(full[2])
    );

    circular_fifo_fwft #(
        .BUFFER_SIZE(4),
        .T(storage_pkg::alu_result_entry_t)
    ) lsu_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(ex_result_i[3].valid),
        .push_data_i(ex_result_i[3]),
        .pop_i(dequeue_next[3]),
        .data_o(fifo_heads[3]),
        .empty_o(empty[3]),
        .full_o(full[3])
    );

    always_comb begin

        wb_chosen    = 1'b0;
        choice_idx   = choice;
        choice_next  = choice;
        dequeue_next = '0;

        any_full = |(full & ~empty);
        request  = (any_full) ? (full & ~empty) : ~empty;

        for(i = choice;i<SCALAR_EX_COUNT;i++) begin
            if(request[i] && !wb_chosen) begin
                choice_idx = i;
                wb_chosen  = 1'b1;
            end
        end
        if(!wb_chosen) begin
            for(i = 0;i<choice;i++) begin
                if(request[i] && !wb_chosen) begin
                    choice_idx = i;
                    wb_chosen  = 1'b1;
                end
            end
        end

        if(wb_chosen) begin
            choice_next = choice_idx + 1'b1;
            dequeue_next[choice_idx] = 1'b1;
        end

        reset_wb_n = reset_ni && !flush_i;

        for(i=0; i<SCALAR_EX_COUNT; i++) wb_ready_o[i] = !full[i];
        
    end

    always_ff @(posedge clk_i) begin

        if(!reset_ni || flush_i) begin
            choice  <= '0;
            dequeue <= '0;
        end

        else begin
            if(wb_chosen) begin
                scalar_data_bus_o.valid   <= 1'b1;
                scalar_data_bus_o.prf_tag <= fifo_heads[choice_idx].prf_tag;
                scalar_data_bus_o.rob_id  <= fifo_heads[choice_idx].rob_id;
                scalar_data_bus_o.data    <= fifo_heads[choice_idx].data;
                choice  <= choice_next;
                dequeue <= dequeue_next;
            end
            else begin
                scalar_data_bus_o.valid   <= 1'b0;
                scalar_data_bus_o.prf_tag <= '0;
                scalar_data_bus_o.rob_id  <= '0;
                scalar_data_bus_o.data    <= '0;
                dequeue <= '0; //sus
            end
        end
    end

endmodule