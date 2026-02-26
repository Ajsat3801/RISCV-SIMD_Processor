

module reservation_station #(
    parameter NO_OF_SLOTS = 2,  // ensure always power of 2
    parameter CHIP_SELECT = 1,
    parameter ROB_SIZE = 32
    )(
    input logic clk,
    input logic reset_n,
    
    // connection with operation bus 
    operand_bus_if.rs rs_input,

    // connection with common data bus
    common_data_bus_if.snoop cdb_data,

    // connection with instruction queue
    output logic[$clog2(NO_OF_SLOTS)-1:0] rs_slot_released_id,
    output logic rs_slot_released,

    // output to execution unit
    input ex_ready,
    output rs_to_alu_signal_t dispatched_op
);

localparam ROB_ADDR_W = $clog2(ROB_SIZE);

rs_entry_t buffer[NO_OF_SLOTS-1:0];
logic[$clog2(NO_OF_SLOTS)-1:0] ready_fifo[(NO_OF_SLOTS):0]; //fifo with no of slots + 1
logic dispatch, instr_valid, fifo_empty, bypass, snoop_cdb;
rs_dispatch_t dispatched_op_q;
logic[$clog2(NO_OF_SLOTS)-1:0] ready_fifo_head, released_id_q;
logic[$clog2(NO_OF_SLOTS+1)-1:0] fifo_head, fifo_tail, head_next;
logic[NO_OF_SLOTS-1:0] enqueued, eligible, snoop, ready_to_dispatch;
int unsigned i;

always_comb begin
    
    head_next = (fifo_head==NO_OF_SLOTS) ? 0: fifo_head + 1;

    fifo_empty = (fifo_tail == fifo_head);
    dispatch = ~fifo_empty && ex_ready;
    instr_valid = rs_input.rs_entry.occupied && rs_input.chip_select == CHIP_SELECT;

    ready_fifo_head = ready_fifo[fifo_head];
    bypass = instr_valid && fifo_empty && rs_input.rs_entry.operand_a_ready && rs_input.rs_entry.operand_b_ready && ex_ready;
    snoop_cdb = cdb_data.valid && cdb_data.write_to_reg;
    for(i=0;i<NO_OF_SLOTS;i++) begin
        ready_to_dispatch[i] = buffer[i].operand_a_ready && buffer[i].operand_b_ready;
        snoop[i] = buffer[i].occupied && !ready_to_dispatch[i];
        eligible[i] = buffer[i].occupied && ready_to_dispatch[i] && ~enqueued[i];
    end

end


always_ff @(posedge clk) begin

    logic[$clog2(NO_OF_SLOTS+1)-1:0] tail_w, tail_w_next, head_eff;
    
    if(!reset_n) begin
        
        buffer[0] <= 'd0;
        for(i = 1; i<NO_OF_SLOTS;i++) buffer[i] <= buffer[0];

        fifo_head <= 0;
        fifo_tail <= 0;
        enqueued <= '0;

        released_id_q <= '0;
        dispatched_op_q.valid <= 0;

        dispatched_op_q <= 'd0;

    end
    else begin

        // snoop data from CDB and update if needed
        if(snoop_cdb) begin
            for(i=0;i<NO_OF_SLOTS;i++) begin
                if(snoop[i]) begin
                    if(cdb_data.rob_id == buffer[i].operand_a_tag && !buffer[i].operand_a_ready) begin 
                        buffer[i].operand_a <= cdb_data.data;
                        buffer[i].operand_a_ready <= 1;
                    end
                    if(cdb_data.rob_id == buffer[i].operand_b_tag && !buffer[i].operand_b_ready) begin
                        buffer[i].operand_b <= cdb_data.data;
                        buffer[i].operand_b_ready <= 1;
                    end
                end
            end
        end

        head_eff = dispatch? head_next : fifo_head;
        tail_w = fifo_tail;
        tail_w_next = (tail_w==NO_OF_SLOTS) ? 'd0 : tail_w + 1;

        for(i=0; i<NO_OF_SLOTS; i++) begin
            if(eligible[i] && tail_w_next != head_eff) begin
                ready_fifo[tail_w] = i[$clog2(NO_OF_SLOTS)-1:0];
                tail_w = tail_w_next;
                tail_w_next = (tail_w==NO_OF_SLOTS) ? 'd0 : tail_w + 1;
                enqueued[i] = 1'b1;
            end
        end

        fifo_tail <= tail_w;

        // dequeue instructions
        if(bypass) begin
            
            // send slice of RS input to output, removing the tags and ready
            dispatched_op_q <= rs_input.rs_entry[(72+(3*ROB_ADDR_W)-1):((2*ROB_ADDR_W)+2)];
            released_id_q <= rs_input.rs_slot;
            
        end
        
        else if(dispatch) begin // queue not empty

            // send slice of ROB entry to output, removing the tags and ready
            dispatched_op_q <= buffer[ready_fifo_head][(72+(3*ROB_ADDR_W)-1):((2*ROB_ADDR_W)+2)];
            
            // clearing buffer entry and dequeue from fifo
            buffer[ready_fifo_head] <= 'd0;
            enqueued[ready_fifo_head] <= 1'b0; 
            fifo_head <= head_next;
            released_id_q <= ready_fifo_head;
        end
        else dispatched_op_q <= 'd0;

        // instruction issued
        if(instr_valid && !bypass) begin
            buffer[rs_input.rs_slot] <= rs_input.rs_entry;
            enqueued[rs_input.rs_slot] <= 1'b0;
        end

    end
end

assign dispatched_op = dispatched_op_q;

assign rs_slot_released_id = released_id_q;
assign rs_slot_released = dispatched_op_q.valid;


endmodule