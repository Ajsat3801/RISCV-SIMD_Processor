/*

Reservation Station (RS) - 2-slots only for simplicity

Behavior
1) Allocation / Fill:
   - Accepts an incoming rs_entry from the operation bus when rs_data.rs_entry.occupied == 1 AND rs_data.cs matches this RS's CHIP_SELECT.
   - Places the entry into the first free slot (buffer[0] preferred, else buffer[1]).

2) Wakeup (CDB snoop):
   - If CDB_data.valid, compare CDB_data.ROB_id against each slot’s operand tags.
   - When matched, latch CDB_data.data into the operand and mark operand_*_ready.
   - ready_to_dispatch becomes 1 when both operands are ready.

3) Dispatch:
   - If a slot is ready_to_dispatch and ex_ready is asserted, build dispatched_op_q and assert dispatched_op_valid_q for that cycle.
   - The dispatched slot is freed (occupied=0).
   - If an incoming rs_entry is present, it is written into the just-freed slot (priority is given to dispatch path).

Notes and Assumptions: 
- NO_OF_SLOTS parameter is present but buffer is hard-coded to 2 slots. Provision given for future increase
- ROB ID of the instruction is used for tag compare
- Occupied bit of incoming rs_entry used as a valid tag for input
- rs_data will never provide a new entry when rs_full = 1

*/

module reservation_station #(
    parameter NO_OF_SLOTS = 2, 
    parameter CHIP_SELECT = 1
    )(
    input logic clk,
    input logic reset_n,
    
    // connection with operation bus 
    operation_bus_if.RS rs_data,
    output logic rs_full,

    // connection with common data bus
    common_data_bus_if.snoop CDB_data,

    // output to execution unit
    input ex_ready,
    output rs_dispatch_t dispatched_op,
    output logic dispatched_op_valid
);

rs_entry_t buffer[1:0];
logic rs_full, dispatched_op_valid_q;
rs_dispatch_t dispatched_op_q;


always @(posedge clk) begin
    
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

        buffer[1] <= buffer[0];

        rs_full <= 0;
        dispatched_op_valid_q <= 0;

        dispatched_op_q.operation <= 0;
        dispatched_op_q.operand_a <= 0;
        dispatched_op_q.operand_b <= 0;
        dispatched_op_q.ROB_id <= 0;

    end

    // snoop data from CDB and update if needed
    if(CDB_data.valid) begin
        if(buffer[0].occupied) begin
            if(CDB_data.ROB_id == buffer[0].operand_a_tag && !buffer[0].operand_a_ready) begin
                buffer[0].operand_a <= CDB_data.data;
                buffer[0].operand_a_ready <= 1;
                if(buffer[0].operand_b_ready) buffer[0].ready_to_dispatch <= 1;
            end

            if(CDB_data.ROB_id == buffer[0].operand_b_tag && !buffer[0].operand_b_ready) begin
                buffer[0].operand_b <= CDB_data.data;
                buffer[0].operand_b_ready <= 1;
                if(buffer[0].operand_a_ready) buffer[0].ready_to_dispatch <= 1;
            end
        end
        if(buffer[1].occupied) begin
            if(CDB_data.ROB_id == buffer[1].operand_a_tag && !buffer[1].operand_a_ready) begin
                buffer[1].operand_a <= CDB_data.data;
                buffer[1].operand_a_ready <= 1;
                if(buffer[1].operand_b_ready) buffer[1].ready_to_dispatch <= 1;
            end

            if(CDB_data.ROB_id == buffer[1].operand_b_tag && !buffer[1].operand_b_ready) begin
                buffer[1].operand_b <= CDB_data.data;
                buffer[1].operand_b_ready <= 1;
                if(buffer[1].operand_a_ready) buffer[1].ready_to_dispatch <= 1;
            end
        end

    end

    // dispatch instruction to ex unit
    if(buffer[0].ready_to_dispatch && ex_ready) begin // dispatch at 0 if ready

        // build RS entry into instruction
        dispatched_op_q.operation <= buffer[0].operation;
        dispatched_op_q.operand_a <= buffer[0].operand_a;
        dispatched_op_q.operand_b <= buffer[0].operand_b;
        dispatched_op_q.ROB_id <= buffer[0].instr_ROB_ID;
        dispatched_op_valid_q <= 1;
        
        buffer[0].occupied <= 0; // Free RS entry
        // if instruction dispatched and new instruction present, replace
        if(rs_data.rs_entry.occupied && rs_data.cs == CHIP_SELECT) buffer[0] <= rs_data.rs_entry; // if 

    end
    else if(buffer[1].ready_to_dispatch && ex_ready) begin // dispatch at 1 if ready
        
        // build RS entry into instruction
        dispatched_op_q.operation <= buffer[1].operation;
        dispatched_op_q.operand_a <= buffer[1].operand_a;
        dispatched_op_q.operand_b <= buffer[1].operand_b;
        dispatched_op_q.ROB_id <= buffer[1].instr_ROB_ID;
        dispatched_op_valid_q <= 1;

        buffer[1].occupied <= 0; // free RS entry
        // if instruction dispatched and new instruction present, replace
        if(rs_data.rs_entry.occupied && rs_data.cs == CHIP_SELECT) buffer[1] <= rs_data.rs_entry;

    end

    else if(rs_data.rs_entry.occupied && rs_data.cs == CHIP_SELECT) begin // if no instruction is dispatched

        // Assign entry to one of the slots, map the assigned slot as newest
        if(buffer[0].occupied == 0) buffer[0] <= rs_data.rs_entry;
        else buffer[1] <= rs_data.rs_entry;
        dispatched_op_valid_q <= 0;

    end
    else dispatched_op_valid_q <= 0;
    

    rs_full <= buffer[0].occupied && buffer[1].occupied;

end

assign dispatched_op = dispatched_op_q;
assign dispatched_op_valid = dispatched_op_valid_q;

assign rs_data.rs_full = rs_full;


endmodule