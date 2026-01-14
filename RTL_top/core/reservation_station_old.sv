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
    
    // inputs from ROB
    input logic[4:0] dest_ROB_ID,
    input chip_select_e ROB_chip_select,
    input logic ROB_inputs_valid,

    // inputs from Registers
    input logic[31:0] operand_a,
    input logic[31:0] operand_b,
    input chip_select_e register_chip_select,
    input logic register_input_valid,

    // inputs from RAT
    input operations_e operation,
    input chip_select_e RAT_chip_select,
    input logic[4:0] src1_ROB_ID,
    input logic[4:0] src2_ROB_ID,
    input logic src1_ready,
    input logic src2_ready,
    input logic RAT_inputs_valid,

    // inputs from common data bus
    input logic [4:0] cdb_ROB_ID,
    input logic[31:0] cdb_data,
    input logic CDB_data_valid,

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

        buffer[0].occupied <= 0;
        buffer[0].ready_to_dispatch <= 0;
        buffer[0].operation <= 0;
        buffer[0].instr_ROB_ID <= 0;
        buffer[0].operand_a <= 0;
        buffer[0].operand_b <= 0;
        buffer[0].operand_a_ready <= 0;
        buffer[0].operand_b_ready <= 0;

        buffer[1].occupied <= 0;
        buffer[1].ready_to_dispatch <= 0;
        buffer[1].operation <= 0;
        buffer[1].instr_ROB_ID <= 0;
        buffer[1].operand_a <= 0;
        buffer[1].operand_b <= 0;
        buffer[1].operand_a_ready <= 0;
        buffer[1].operand_b_ready <= 0;

        new_buffer.occupied <= 0;
        new_buffer.ready_to_dispatch <= 0;
        new_buffer.operation <= 0;
        new_buffer.instr_ROB_ID <= 0;
        new_buffer.operand_a <= 0;
        new_buffer.operand_b <= 0;
        new_buffer.operand_a_ready <= 0;
        new_buffer.operand_b_ready <= 0;

        rs_full <= 0;
        newest <= 1; // we want the first entry to go to 0
        dispatched_op_valid_q <= 0;

        dispatched_op_q.operation <= 0;
        dispatched_op_q.operand_a <= 0;
        dispatched_op_q.operand_b <= 0;
        dispatched_op_q.Rob_ID <= 0;

    end

    // snoop data from CDB and update if needed
    if(CDB_data_valid) begin
        if(cdb_ROB_ID == buffer[0].operand_a) begin
            buffer[0].operand_a <= cdb_data;
            buffer[0].operand_a_ready <= 1;
            if(buffer[0].operand_b_ready) buffer[0].ready_to_dispatch = 1;
        end

        if(cdb_ROB_ID == buffer[0].operand_b) begin
            buffer[0].operand_b <= cdb_data;
            buffer[0].operand_b_ready <= 1;
            if(buffer[0].operand_a_ready) buffer[0].ready_to_dispatch = 1;
        end

        if(cdb_ROB_ID == buffer[1].operand_a) begin
            buffer[1].operand_a <= cdb_data;
            buffer[1].operand_a_ready <= 1;
            if(buffer[1].operand_b_ready) buffer[1].ready_to_dispatch = 1;
        end

        if(cdb_ROB_ID == buffer[1].operand_b) begin
            buffer[1].operand_b <= cdb_data;
            buffer[1].operand_b_ready <= 1;
            if(buffer[1].operand_a_ready) buffer[1].ready_to_dispatch = 1;
        end

    end

    // dispatch instruction to ex unit
    if(buffer[!newest].ready_to_dispatch) begin

        // build RS entry into instruction
        dispatched_op_q.operation = buffer[!newest].operation;
        dispatched_op_q.operand_a = buffer[!newest].operand_a;
        dispatched_op_q.operand_b = buffer[!newest].operand_b;
        dispatched_op_q.Rob_ID = buffer[!newest].instr_ROB_ID;
        dispatched_op_valid_q = 1;
        
        // Free RS entry
        buffer[!newest].occupied = 0;

    end
    else if(buffer[newest].ready_to_dispatch) begin
        
        // build RS entry into instruction
        dispatched_op_q.operation = buffer[newest].operation;
        dispatched_op_q.operand_a = buffer[newest].operand_a;
        dispatched_op_q.operand_b = buffer[newest].operand_b;
        dispatched_op_q.Rob_ID = buffer[newest].instr_ROB_ID;
        dispatched_op_valid_q = 1;

        // free RS entry
        buffer[newest].occupied = 0;
        newest = ~newest; // newest instruction removed so other must be the newest
    end
    else dispatched_op_valid_q = 0;


    // Add new instructions to Reservation stations
    if(register_input_valid && RAT_inputs_valid && ROB_inputs_valid) begin
        
        
        if(RAT_chip_select == CHIP_SELECT && ROB_chip_select == CHIP_SELECT && register_chip_select == CHIP_SELECT) begin
            // build RS entry
            new_buffer.operation <= operation;
            new_buffer.instr_ROB_ID <= dest_ROB_ID;
            new_buffer.operand_a_ready <= src1_ready;
            new_buffer.operand_b_ready <= src2_ready;
            new_buffer.operand_a <= (src1_ready) ? operand_a : {27'b0,src1_ROB_ID};
            new_buffer.operand_b <= (src2_ready) ? operand_b : {27'b0,src2_ROB_ID};
            new_buffer.ready_to_dispatch <= src1_ready && src2_ready;
            new_buffer.occupied <= 1;

            // Assign entry to one of the slots, map the assigned slot as newest
            if(!buffer[!newest].occupied) newest = ~newest;
            buffer[newest] <= new_buffer;
            
        end

    end

    rs_full = buffer[0].occupied && buffer[1].occupied;

end

assign dispatched_op = dispatched_op_q;
assign dispatched_op_valid = dispatched_op_valid_q;

assign rs_full_to_queue = rs_full;
assign rs_full_to_ROB = rs_full;
assign rs_full_to_RAT = rs_full;
assign rs_full_to_registers = rs_full;


endmodule