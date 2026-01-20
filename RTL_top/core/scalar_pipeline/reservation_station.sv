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
        newest <= 1; // we want the first entry to go to 0
        dispatched_op_valid_q <= 0;

        dispatched_op_q.operation <= 0;
        dispatched_op_q.operand_a <= 0;
        dispatched_op_q.operand_b <= 0;
        dispatched_op_q.Rob_ID <= 0;

    end

    // snoop data from CDB and update if needed
    if(CDB_data.valid) begin
        if(CDB_data.ROB_id == buffer[0].operand_a_tag && buffer[0].occupied) begin
            buffer[0].operand_a <= CDB_data.data;
            buffer[0].operand_a_ready <= 1;
            if(buffer[0].operand_b_ready) buffer[0].ready_to_dispatch <= 1;
        end

        if(CDB_data.ROB_id == buffer[0].operand_b_tag && buffer[0].occupied) begin
            buffer[0].operand_b <= CDB_data.data;
            buffer[0].operand_b_ready <= 1;
            if(buffer[0].operand_a_ready) buffer[0].ready_to_dispatch <= 1;
        end

        if(CDB_data.ROB_id == buffer[1].operand_a_tag && buffer[1].occupied) begin
            buffer[1].operand_a <= CDB_data.data;
            buffer[1].operand_a_ready <= 1;
            if(buffer[1].operand_b_ready) buffer[1].ready_to_dispatch <= 1;
        end

        if(CDB_data.ROB_id == buffer[1].operand_b_tag && buffer[1].occupied) begin
            buffer[1].operand_b <= CDB_data.data;
            buffer[1].operand_b_ready <= 1;
            if(buffer[1].operand_a_ready) buffer[1].ready_to_dispatch <= 1;
        end

    end

    // dispatch instruction to ex unit
    if(buffer[0].ready_to_dispatch && ex_ready) begin

        // build RS entry into instruction
        dispatched_op_q.operation <= buffer[0].operation;
        dispatched_op_q.operand_a <= buffer[0].operand_a;
        dispatched_op_q.operand_b <= buffer[0].operand_b;
        dispatched_op_q.Rob_ID <= buffer[0].instr_ROB_ID;
        dispatched_op_valid_q <= 1;
        
        buffer[0].occupied <= 0; // Free RS entry

        if(rs_data.rs_entry.occupied && rs_data.cs == CHIP_SELECT) buffer[0] <= rs_data.rs_entry;

    end
    else if(buffer[1].ready_to_dispatch && ex_ready) begin
        
        // build RS entry into instruction
        dispatched_op_q.operation <= buffer[1].operation;
        dispatched_op_q.operand_a <= buffer[1].operand_a;
        dispatched_op_q.operand_b <= buffer[1].operand_b;
        dispatched_op_q.Rob_ID <= buffer[1].instr_ROB_ID;
        dispatched_op_valid_q <= 1;

        buffer[1].occupied <= 0; // free RS entry

        if(rs_data.rs_entry.occupied && rs_data.cs == CHIP_SELECT) buffer[1] <= rs_data.rs_entry;

    end

    else if(rs_data.rs_entry.occupied && rs_data.cs == CHIP_SELECT) begin

        // Assign entry to one of the slots, map the assigned slot as newest
        if(buffer[0].occupied == 0) buffer[0] <= rs_data.rs_entry;
        else buffer[1] <= rs_data.rs_entry;

    end
    else dispatched_op_valid_q <= 0;
    

    rs_full <= buffer[0].occupied && buffer[1].occupied;

end

assign dispatched_op = dispatched_op_q;
assign dispatched_op_valid = dispatched_op_valid_q;

assign rs_data.rs_full = rs_full;


endmodule