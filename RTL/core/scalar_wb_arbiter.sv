/*  
Arbiter for writeback
Takes inputs from all the EX units and sends one instruction per cycle to CDB
Round robin policy
branches have separate inputs, fifos and outputs
*/

//import config_pkg::*;

module scalar_wb_arbiter #() (
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    // EX units
    input signal_pkg::ex_to_wb_signal_t ex_result_i[NUMBER_OF_EX-1:0],
    output logic wb_ready_o[NUMBER_OF_EX-1:0],

    input signal_pkg::alu_to_wb_branch_signal_t branch_result_i[NUMBER_OF_BRANCH_EX-1:0], 
    output logic wb_ready_branch_o[NUMBER_OF_BRANCH_EX-1:0],

    data_bus_if.writeback scalar_data_bus_o,

    output signal_pkg::wb_to_rob_branch_t branch_wb_o
);

    storage_pkg::wb_queue_entry_t fifo_heads[NUMBER_OF_EX-1:0]; 
    storage_pkg::wb_queue_branch_entry_t branch_fifo_heads[NUMBER_OF_BRANCH_EX-1:0];

    logic[EX_IDX_W-1:0] choice, choice_idx, choice_next;
    logic[NUMBER_OF_EX-1:0] empty, full;
    logic[NUMBER_OF_EX-1:0] dequeue, dequeue_next, request;
    logic wb_chosen, any_full;

    logic[BRANCH_IDX_W-1:0] branch_choice, branch_choice_idx, branch_choice_next;
    logic[NUMBER_OF_BRANCH_EX-1:0] branch_empty, branch_full, branch_dequeue, branch_dequeue_next, branch_request;
    logic branch_chosen, branch_any_full;

    logic reset_wb_n;

    int i;

    // circular FIFOs with FWFT, so we know what the head of the queue is immediately

    circular_fifo_fwft #(
        .BUFFER_SIZE(4), 
        .T(storage_pkg::wb_queue_entry_t) 
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
        .BUFFER_SIZE(2),
        .T(storage_pkg::wb_queue_branch_entry_t)
    ) branch0_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(branch_result_i[0].valid),
        .push_data_i(branch_result_i[0]),
        .pop_i(branch_dequeue_next[0]),
        .data_o(branch_fifo_heads[0]),
        .empty_o(branch_empty[0]),
        .full_o(branch_full[0])
    );

    circular_fifo_fwft #(
        .BUFFER_SIZE(4),
        .T(storage_pkg::wb_queue_entry_t)
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
        .T(storage_pkg::wb_queue_branch_entry_t)
    ) branch1_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(branch_result_i[1].valid),
        .push_data_i(branch_result_i[1]),
        .pop_i(branch_dequeue_next[1]),
        .data_o(branch_fifo_heads[1]),
        .empty_o(branch_empty[1]),
        .full_o(branch_full[1])
    );

    /* FIFOS which will cater to future EX units

    circular_fifo_fwft #(
        .BUFFER_SIZE(2),
        .T(storage_pkg::wb_queue_entry_t)
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
        .T(storage_pkg::wb_queue_entry_t)
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
    */

    always_comb begin

        wb_chosen    = 1'b0;
        choice_idx   = choice;
        choice_next  = choice;
        dequeue_next = '0;

        any_full = |(full & ~empty);
        request  = (any_full) ? (full & ~empty) : ~empty;

        for(i = choice;i<NUMBER_OF_EX;i++) begin
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

        branch_chosen = 1'b0;
        branch_choice_idx   = branch_choice;
        branch_choice_next  = branch_choice;
        branch_dequeue_next = '0;

        branch_any_full = |(branch_full & ~branch_empty);
        branch_request  = (branch_any_full) ? (branch_full & ~branch_empty) : ~branch_empty;

        for(i=branch_choice; i<NUMBER_OF_BRANCH_EX; i++) begin
            if(branch_request[i] && !branch_chosen) begin
                branch_choice_idx = i;
                branch_chosen     = 1'b1;
            end
        end
        if(!branch_chosen) begin
            for(i=0; i<branch_choice; i++) begin
                if(branch_request[i] && !branch_chosen) begin
                    branch_choice_idx = i;
                    branch_chosen     = 1'b1;
                end
            end
        end

        if(branch_chosen) begin
            branch_choice_next = branch_choice_idx + 1'b1;
            branch_dequeue_next[branch_choice_idx] = 1'b1;
        end

        reset_wb_n = reset_ni && !flush_i;

        for(i=0; i<NUMBER_OF_EX; i++) wb_ready_o[i] = !full[i];
        for(i=0; i<NUMBER_OF_BRANCH_EX; i++) wb_ready_branch_o[i] = !branch_full[i];
        
    end

    always_ff @(posedge clk_i) begin

        if(!reset_ni || flush_i) begin
            choice  <= '0;
            dequeue <= '0;
            branch_choice  <= '0;
            branch_dequeue <= '0;
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

            if(branch_chosen) begin
                branch_wb_o.valid  <= 1'b1;
                branch_wb_o.rob_id <= branch_fifo_heads[branch_choice_idx].rob_id;
                branch_dequeue     <= branch_dequeue_next;
                branch_wb_o.branch_taken <= branch_fifo_heads[branch_choice_idx].branch_taken;
                branch_choice <= branch_choice_next;
            end
            else begin
                branch_wb_o.valid        <= 1'b0;
                branch_wb_o.rob_id       <= '0;
                branch_wb_o.branch_taken <= '0;
                branch_dequeue           <= '0;
            end
        end
    end

endmodule