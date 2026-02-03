/*
Reservation Station — slot-directed + ready-FIFO scheduler (NO_OF_SLOTS parameterized)

Behavior
    1) Allocation / Fill (IQ-directed):
    - Accepts an incoming rs_entry when rs_data.rs_entry.occupied==1 AND rs_data.cs==CHIP_SELECT.
    - IQ provides rs_data.rs_slot; RS writes buffer[rs_slot] directly (no internal “find free slot” logic).
    - If the issued entry is already ready_to_dispatch, RS enqueues rs_slot into ready_fifo immediately.

    2) Wakeup (CDB snoop):
    - On CDB_data.valid, scan all buffer entries where occupied==1 and ready_to_dispatch==0.
    - Compare CDB_data.ROB_id against operand_a_tag / operand_b_tag; on match, latch CDB_data.data and 
      set operand_*_ready.
    - When both operands are ready, set ready_to_dispatch=1 and enqueue the slot ID (special-case handles tagA==tagB
      to avoid double-enqueue).

    3) Dispatch:
    - If ready_fifo is non-empty (fifo_tail!=fifo_head) and ex_ready==1, pop slot_id=ready_fifo[fifo_head] and drive
      dispatched_op_q from buffer[slot_id].
    - Free the slot (occupied=0, ready_to_dispatch=0, operand_*_ready=0) and return rs_slot_released_id=slot_id with
      rs_slot_released asserted for that cycle.

Notes / Assumptions:
    - no of slots is always a power of 2.
    - IQ never reuses a slot ID until it observes rs_slot_released for that slot;
    - flush/state-clearing means reset fifo and the reservation stations.
    - ready_fifo depth is 2*NO_OF_SLOTS to simplify pointer wrap; design assumes outstanding ready slot IDs never
      exceed NO_OF_SLOTS in correct operation.
*/

module reservation_station #(
    parameter NO_OF_SLOTS = 2,  // ensure always power of 2
    parameter CHIP_SELECT = 1
    )(
    input logic clk,
    input logic reset_n,
    
    // connection with operation bus 
    operation_bus_if.RS rs_data,

    // connection with common data bus
    common_data_bus_if.snoop CDB_data,

    // connection with instruction queue
    output logic[$clog2(NO_OF_SLOTS)-1:0] rs_slot_released_id,
    output logic rs_slot_released,

    // output to execution unit
    input ex_ready,
    output rs_dispatch_t dispatched_op,
    output logic dispatched_op_valid
);

rs_entry_t buffer[NO_OF_SLOTS-1:0];
logic[$clog2(NO_OF_SLOTS)-1:0] ready_fifo[(NO_OF_SLOTS*2)-1:0]; //fifo with 2x no of slots
logic dispatched_op_valid_q;
rs_dispatch_t dispatched_op_q;
int unsigned i;
logic[$clog2(NO_OF_SLOTS)-1:0] rs_slot_released_q;
logic[$clog2(2*NO_OF_SLOTS)-1:0] fifo_head, fifo_tail;


always_ff @(posedge clk) begin
    
    if(!reset_n) begin

        buffer[0].occupied <= 0;
        buffer[0].ready_to_dispatch <= 0;
        buffer[0].operation <= 0;
        buffer[0].instr_ROB_ID <= 0;
        buffer[0].operand_a <= 0;
        buffer[0].operand_b <= 0;
        buffer[0].operand_a_ready <= 0;
        buffer[0].operand_b_ready <= 0;
        buffer[0].operand_a_tag <= 0;
        buffer[0].operand_b_tag <= 0;

        fifo_head <= 0;
        fifo_tail <= 0;

        for(i = 1; i<NO_OF_SLOTS;i++) buffer[i]<=buffer[0];

        dispatched_op_valid_q <= 0;

        dispatched_op_q.operation <= 0;
        dispatched_op_q.operand_a <= 0;
        dispatched_op_q.operand_b <= 0;
        dispatched_op_q.ROB_id <= 0;

    end
    else begin

        // snoop data from CDB and update if needed
        // also handle adding to ready_fifo if instruction is ready
        if(CDB_data.valid) begin
            for(i=0;i<NO_OF_SLOTS;i++) begin
                if(buffer[i].occupied && !buffer[i].ready_to_dispatch) begin
                    if(buffer[i].operand_a_tag != buffer[i].operand_b_tag) begin
                        if(CDB_data.ROB_id == buffer[i].operand_a_tag && !buffer[i].operand_a_ready) begin 
                            buffer[i].operand_a <= CDB_data.data;
                            buffer[i].operand_a_ready <= 1;
                            if(buffer[i].operand_b_ready) begin
                                buffer[i].ready_to_dispatch <= 1;
                                ready_fifo[fifo_tail] <= i[$clog2(NO_OF_SLOTS)-1:0];
                                fifo_tail++;
                            end
                        end
                        if(CDB_data.ROB_id == buffer[i].operand_b_tag && !buffer[i].operand_b_ready) begin
                            buffer[i].operand_b <= CDB_data.data;
                            buffer[i].operand_b_ready <= 1;
                            if(buffer[i].operand_a_ready) begin
                                buffer[i].ready_to_dispatch <= 1;
                                ready_fifo[fifo_tail] <= i[$clog2(NO_OF_SLOTS)-1:0];
                                fifo_tail++; 
                            end
                        end
                    end
                    else if(CDB_data.ROB_id == buffer[i].operand_a_tag) begin
                        if (!buffer[i].operand_a_ready && !buffer[i].operand_b_ready) begin
                            buffer[i].operand_a <= CDB_data.data;
                            buffer[i].operand_a_ready <= 1;
                            buffer[i].operand_b <= CDB_data.data;
                            buffer[i].operand_b_ready <= 1;

                            buffer[i].ready_to_dispatch <= 1;
                            ready_fifo[fifo_tail] <= i[$clog2(NO_OF_SLOTS)-1:0];
                            fifo_tail++;
                        end
                    end
                end
            end
        end


        // dispatch instructions
        if((fifo_tail != fifo_head) && ex_ready) begin // queue not empty
            dispatched_op_q.operation <= buffer[ready_fifo[fifo_head]].operation;
            dispatched_op_q.operand_a <= buffer[ready_fifo[fifo_head]].operand_a;
            dispatched_op_q.operand_b <= buffer[ready_fifo[fifo_head]].operand_b;
            dispatched_op_q.ROB_id <= buffer[ready_fifo[fifo_head]].instr_ROB_ID;
            buffer[ready_fifo[fifo_head]].occupied <= 0;
            buffer[ready_fifo[fifo_head]].ready_to_dispatch <= 1'b0;
            buffer[ready_fifo[fifo_head]].operand_a_ready   <= 1'b0;
            buffer[ready_fifo[fifo_head]].operand_b_ready   <= 1'b0;
            dispatched_op_valid_q <=1;
            rs_slot_released_q <= ready_fifo[fifo_head];
            
            fifo_head++;
        end
        else dispatched_op_valid_q <= 0;

        // instruction issued
        if(rs_data.rs_entry.occupied && rs_data.cs == CHIP_SELECT) begin
            buffer[rs_data.rs_slot] <= rs_data.rs_entry;
            if(rs_data.rs_entry.ready_to_dispatch) begin
                ready_fifo[fifo_tail] <= rs_data.rs_slot;
                fifo_tail++;
            end
        end

    end
end

assign dispatched_op = dispatched_op_q;
assign dispatched_op_valid = dispatched_op_valid_q;

assign rs_slot_released_id = rs_slot_released_q;
assign rs_slot_released = dispatched_op_valid_q;


endmodule