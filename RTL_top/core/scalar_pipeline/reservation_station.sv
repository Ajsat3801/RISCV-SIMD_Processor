/*
    RESERVATION STATIONS    
    -   Contains 2 slots - for simplicitys sake

*/

module reservation_station #(
    parameter NO_OF_SLOTS = 2, 
    parameter CHIP_SELECT = 1
    )(
    input logic clk,
    input logic reset_n,
    
    // snoop from operation bus
    operation_bus_if.RS rs_data,

    // inputs from common data bus
    common_data_bus_if.RS cdb_data,

    // output to execution unit
    output rs_dispatch_t dispatched_op,
    output logic dispatched_op_valid,

    // output to instruction queue
    output logic rs_full_to_queue
    output logic rs_full_to_ROB,
    output logic rs_full_to_RAT,
    output logic rs_full_to_registers
);

// 
rs_entry_t buffer[1:0];
rs_entry_t new_buffer;

logic rs_full, newest, dispatched_op_valid_q;

rs_dispatch_t dispatched_op_q;


always @(posedge clk) begin
    
    if(!reset_n) begin
        // reset buffer[0], buffer[1] & new_buffer

        new_buffer.occupied <= 0;
        new_buffer.ready_to_dispatch <= 0;
        new_buffer.operation <= 0;
        new_buffer.instr_ROB_ID <= 0;
        new_buffer.operand_a <= 0;
        new_buffer.operand_b <= 0;
        new_buffer.operand_a_ready <= 0;
        new_buffer.operand_b_ready <= 0;

        buffer[0] <= new_buffer;
        buffer[1] <= new_buffer;

        rs_full <= 0;
        newest <= 1; // we want the first entry to go to 0
        dispatched_op_valid_q <= 0;

        dispatched_op_q.operation <= 0;
        dispatched_op_q.operand_a <= 0;
        dispatched_op_q.operand_b <= 0;
        dispatched_op_q.Rob_ID <= 0;

    end

    // snoop data from CDB and update if needed
    if(CDB_data.CDB_data_valid) begin
        if(CDB_data.cdb_ROB_ID == buffer[0].operand_a) begin
            buffer[0].operand_a <= CDB_data.cdb_data;
            buffer[0].operand_a_ready <= 1;
            if(buffer[0].operand_b_ready) buffer[0].ready_to_dispatch = 1;
        end

        if(CDB_data.cdb_ROB_ID == buffer[0].operand_b) begin
            buffer[0].operand_b <= CDB_data.cdb_data;
            buffer[0].operand_b_ready <= 1;
            if(buffer[0].operand_a_ready) buffer[0].ready_to_dispatch = 1;
        end

        if(CDB_data.cdb_ROB_ID == buffer[1].operand_a) begin
            buffer[1].operand_a <= CDB_data.cdb_data;
            buffer[1].operand_a_ready <= 1;
            if(buffer[1].operand_b_ready) buffer[1].ready_to_dispatch = 1;
        end

        if(cCDB_data.db_ROB_ID == buffer[1].operand_b) begin
            buffer[1].operand_b <= CDB_data.cdb_data;
            buffer[1].operand_b_ready <= 1;
            if(buffer[1].operand_a_ready) buffer[1].ready_to_dispatch = 1;
        end

    end

    // dispatch instruction to ex unit
    if(buffer[!newest].ready_to_dispatch) begin

        // build RS entry into instruction
        dispatched_op_q.operation <= buffer[!newest].operation;
        dispatched_op_q.operand_a <= buffer[!newest].operand_a;
        dispatched_op_q.operand_b <= buffer[!newest].operand_b;
        dispatched_op_q.Rob_ID <= buffer[!newest].instr_ROB_ID;
        dispatched_op_valid_q <= 1;
        
        // Free RS entry
        buffer[!newest].occupied <= 0;

    end
    else if(buffer[newest].ready_to_dispatch) begin
        
        // build RS entry into instruction
        dispatched_op_q.operation <= buffer[newest].operation;
        dispatched_op_q.operand_a <= buffer[newest].operand_a;
        dispatched_op_q.operand_b <= buffer[newest].operand_b;
        dispatched_op_q.Rob_ID <= buffer[newest].instr_ROB_ID;
        dispatched_op_valid_q <= 1;

        // free RS entry
        buffer[newest].occupied <= 0;
        newest <= ~newest; // newest instruction removed so other must be the newest
    end
    else dispatched_op_valid_q <= 0;


    // Add new instructions to Reservation stations
    if(rs_data.ops_valid && rs_data.cs == CHIP_SELECT) begin
        
        // build RS entry
        new_buffer.operation <= rs_data.operation;
        new_buffer.instr_ROB_ID <= rs_data.instr_ROB_ID;
        new_buffer.operand_a_ready <= rs_data.operand_a_ready;
        new_buffer.operand_b_ready <= rs_data.operand_b_ready;
        new_buffer.operand_a <= rs_data.operand_a;
        new_buffer.operand_b <= rs_data.operand_b;
        new_buffer.ready_to_dispatch <= rs_data.operand_a_ready && rs_data.operand_b_ready;
        new_buffer.occupied <= 1;

        // Assign entry to one of the slots, map the assigned slot as newest
        if(!buffer[!newest].occupied) newest = ~newest;
        buffer[newest] <= new_buffer;

    end

    rs_full <= buffer[0].occupied && buffer[1].occupied;

end

assign dispatched_op = dispatched_op_q;
assign dispatched_op_valid = dispatched_op_valid_q;

assign rs_full_to_queue = rs_full;
assign rs_full_to_ROB = rs_full;
assign rs_full_to_RAT = rs_full;
assign rs_full_to_registers = rs_full;


endmodule