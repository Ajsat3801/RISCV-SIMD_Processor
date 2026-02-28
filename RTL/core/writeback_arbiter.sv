/*  
Arbiter for writeback
Takes inputs from all the EX units and sends one instruction per cycle to CDB

*/
/* 
    xxxx_q_count counts till n-1 values
    xxxx_q_full acts as an overflow as well as a queue full flag
    
    ENQUEUE LOGIC:
        if ( q_full == 0){
            q[tail] <= input;
            tail <= (tail + 1) % 8;
            if (q_count == all ones) q_full = 1;
            else q_count = q_count + 1;
            q_empty = 0;
        } 
    
    DEQUEUE LOGIC:

        if(q_empty == 0){
            output <= queue[head];
            head <= (head + 1) % 8;
            if (q_full  == 1) q_full = 0;
            else q_count = q_count - 1;
            if(q_count == 0) q_empty = 1;
        }
*/

module writeback_arbiter #(parameter NUM_EX=4, parameter NUM_BRANCH=2) (
    input logic clk,
    input logic reset_n,

    // EX units
    input signal_pkg::ex_to_wb_signal_t ex_result[NUM_EX],
    output logic wb_ready[NUM_EX],

    input signal_pkg::alu_to_wb_branch_signal_t branch_result[NUM_BRANCH], 
    output logic wb_ready_branch[NUM_BRANCH];

    common_data_bus_if.writeback cdb_data,

    output signal_pkg::wb_to_rob_branch_t branch_data
);

storage_pkg::wb_queue_entry_t fifo_heads[NUM_EX-1:0]; 
storage_pkg::wb_branch_queue_entry_t branch_fifo_heads[NUM_BRANCH-1:0];

logic[clog2(NUM_EX)-1:0] choice, choice_idx, choice_next;
logic[NUM_EX-1:0] empty, full, dequeue, request;
logic wb_chosen, any_full;

logic[$clog2(NUM_BRANCH)-1:0] branch_choice, branch_choice_idx;
logic[NUM_BRANCH-1:0] branch_empty, branch_full, branch_dequeue, branch_request;
logic branch_chosen, branch_any_full;

int i;

always_comb begin

    wb_chosen = 1'b0;
    choice_idx = choice;
    choice_next = choice;
    dequeue_next = 'd0;

    any_full = |(full & ~empty);
    request = (any_full) ? (full & ~empty) : ~empty;

    for(i = choice;i<NUM_EX;i++) begin
        if(request[i] && !wb_chosen) begin
            choice_idx = i;
            wb_chosen = 1'b1;
        end
    end
    if(!wb_chosen) begin
        for(i = 0;i<choice;i++) begin
            if(request[i] && !wb_chosen) begin
                choice_idx = i;
                wb_chosen = 1'b1;
            end
        end
    end

    if(wb_chosen) begin
        choice_next = choice_idx + 1;
        dequeue_next[choice_idx] = 1'b1;
    end


    branch_chosen = 1'b0;
    branch_choice_idx = branch_choice;
    branch_choice_next = branch_choice;
    branch_dequeue_next = 'd0;

    branch_any_full = |(branch_full & ~branch_empty);
    branch_request = (branch_any_full) ? (branch_full & ~branch_empty) : ~branch_empty;

    for(i=branch_choice; i<NUM_BRANCH; i++) begin
        if(branch_request[i] && !branch_chosen) begin
            branch_choice_idx = i;
            branch_chosen = 1'b1;
        end
    end
    if(!branch_chosen) begin
        for(i=0; i<branch_choice; i++) begin
            if(branch_request[i] && !branch_chosen) begin
                branch_choice_idx = i;
                branch_chosen = 1'b1;
            end
        end
    end

    if(branch_chosen) begin
        branch_choice_next = branch_choice_idx + 1;
        branch_dequeue_next[choice_idx] = 1'b1;
    end
    

end

// circular FIFOs with FWFT, so we know what the head of the queue is immediately

circular_FIFO_fwft  #(.BUFFER_SIZE(4), .T(storage_pkg::wb_queue_entry_t)) alu1_fifo (
    .clk(clk),
    .reset_n(reset_n),
    .enqueue(ex_result[0].valid),
    .enqueue_data(ex_result[0]),
    .dequeue(dequeue[0]),
    .dequeue_data(fifo_heads[0]),
    .empty(empty[0]),
    .full(full[0])
);

circular_FIFO_fwft  #(.BUFFER_SIZE(4), .T(storage_pkg::wb_queue_branch_entry_t)) branch1_fifo (
    .clk(clk),
    .reset_n(reset_n),
    .enqueue(branch_result[0].valid),
    .enqueue_data(branch_result[0]),
    .dequeue(branch_dequeue[0]),
    .dequeue_data(branch_fifo_heads[0]),
    .empty(branch_empty[0]),
    .full(branch_full[0])
);

circular_FIFO_fwft  #(.BUFFER_SIZE(4), .T(storage_pkg::wb_queue_entry_t)) alu2_fifo (
    .clk(clk),
    .reset_n(reset_n),
    .enqueue(ex_result[1].valid),
    .enqueue_data(ex_result[1]),
    .dequeue(dequeue[1]),
    .dequeue_data(fifo_heads[1]),
    .empty(empty[1]),
    .full(full[1])
);

circular_FIFO_fwft  #(.BUFFER_SIZE(4), .T(storage_pkg::wb_queue_branch_entry_t)) branch2_fifo (
    .clk(clk),
    .reset_n(reset_n),
    .enqueue(branch_result[1].valid),
    .enqueue_data(branch_result[1]),
    .dequeue(branch_dequeue[1]),
    .dequeue_data(branch_fifo_heads[1]),
    .empty(branch_empty[1]),
    .full(branch_full[1])
);


circular_FIFO_fwft  #(.BUFFER_SIZE(4), .T(storage_pkg::wb_queue_entry_t)) muldiv_fifo (
    .clk(clk),
    .reset_n(reset_n),
    .enqueue(ex_result[2].valid),
    .enqueue_data(ex_result[2]),
    .dequeue(dequeue[2]),
    .dequeue_data(fifo_heads[2]),
    .empty(empty[2]),
    .full(full[2])
);

circular_FIFO_fwft  #(.BUFFER_SIZE(2), .T(storage_pkg::wb_queue_entry_t)) lsu_fifo (
    .clk(clk),
    .reset_n(reset_n),
    .enqueue(ex_result[3].valid),
    .enqueue_data(ex_result[3]),
    .dequeue(dequeue[3]),
    .dequeue_data(fifo_heads[3]),
    .empty(empty[3]),
    .full(full[3])
);

always_ff @(posedge clk) begin

    if(!reset_n) begin
        choice <= 'd0;
        branch_choice <= 'd0;
        dequeue <= 'd0;
        branch_dequeue <= 'd0;
    end

    else begin
        if(wb_chosen) begin
            cdb_data.valid <= 1'b1;
            cdb_data.rob_id <= fifo_heads[choice_idx].rob_id;
            cdb_data.data <= fifo_heads[choice_idx].data;
            choice <= choice_next;
            dequeue <= dequeue_next;
        end
        else begin
            cdb_data.valid <= 1'b0;
            cdb_data.rob_id <= 'd0;
            cdb_data.data <= 32'b0;
        end

        if(branch_chosen) begin
            branch_data.valid <= 1'b1;
            branch_data.rob_id <= branch_fifo_heads[branch_choice_idx].rob_id;
            branch_data.branch_taken <= branch_fifo_heads[branch_choice_idx].branch_taken;
            branch_dequeue <= branch_dequeue_next;
        end
    end
end

endmodule