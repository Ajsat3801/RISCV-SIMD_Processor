/*
    Stores key value pairs for mapping architectural register with ROB ID
    Behaviour:
    -   Gets issue and dispatch control signals from ROB
    -   If an instruction is issued, RAT updates that value
    -   If an instruction is dispatched, RAT resets the value to the architectural register if the 
        dispatched instruction is the latest
    -   Passes on chip select and operation variable without any modifications
    -   Sends source and destination ROB IDs (or register values) depending on "in_use" variable
    -   in_use==1: ROB ID sent, in_use==0: register value sent

    Note:   RAT updates with a 1 cycle lag in issue, so when checking for an instruction ensure to check 
            the inputs from the ROB too
            In case of a stall, RS ready bit goes to the instruction queue too, so no need to add
            additional ready bit for holding values
*/

module register_allocation_table #(
    parameter REGISTER_SIZE=32
    )(
    input clk,
    input reset_n,

    // connection from instruction queues
    instruction_bus_if.RAT instr,

    // connection from ROB (issue stage)
    input rat_rob_comms_t issue_comms;

    // connection from ROB (dispatch stage)
    input rat_rob_comms_t dispatch_comms;

    // connections to reservation stations
    operation_bus_if.RAT issue_data,


);

RAT_entry_t RAT_buffer[31:0];
operations_e operation_q;
chip_select_e RAT_chip_select_q;

logic src1_ready_q, src2_ready_q, RAT_op_valid_q;
logic[4:0] src1_ROB_ID_q, src2_ROB_ID_q;
logic[2:0] RS_slot_ID;


always @(posedge clk) begin
    if(!reset_n) begin // reset
        for (i = 0; i < 32; i++) begin
            RAT_buffer[i].in_use <= 1'b0;
            RAT_buffer[i].ROB_id <= i[4:0];   // map-to-arch-reg
        end

        src1_ready_q <= 1'b1;
        src2_ready_q <= 1'b1;
        src1_ROB_ID_q <= '0;
        src2_ROB_ID_q <= '0;
        operation_q <= '0;
        RAT_chip_select_q <= '0;
        RAT_op_valid_q <= 1'b0;
        RS_slot_q <= 3'b000;

    end
    else begin
        
        // update RAT on dispatch
        if(dispatch_comms.valid && dispatch_comms.rd!=0 && RAT_buffer[dispatch_comms.rd].ROB_id == dispatch_comms.ROB_id) begin
                // ROB is reset
                RAT_buffer[dispatch_comms.rd].ROB_id <= dispatch_comms.rd;
                RAT_buffer[dispatch_comms.rd].in_use <= 0;
        end
        // update RAT on issue
        if(issue_comms.valid && issue_comms.rd!=0) begin
            RAT_buffer[issue_comms.rd].ROB_id <= issue_comms.ROB_id;
            RAT_buffer[issue_comms.rd].in_use <= 1;
        end

        // check RAT entries for RS1 and RS2

        if(issue_comms.valid && issue_comms.rd == instr.src1_address && instr.src1_address != 0) begin
            src1_ROB_ID_q <= issue_comms.ROB_id;
            src1_ready_q <=0;
        end
        else begin
            src1_ROB_ID_q <= RAT_buffer[instr.src1_address].pointer;
            src1_ready_q <= (instr.src1_address != 0) ? ~RAT_buffer[instr.src1_address].in_use : 1;
        end
        if(issue_comms.valid && issue_comms.rd == instr.src2_address && instr.src2_address != 0) begin
            src2_ROB_ID_q <= issue_comms.ROB_id;
            src2_ready_q <= 0;
        end
        else begin
            src2_ROB_ID_q <= RAT_buffer[instr.src2_address].pointer;
            src2_ready_q <= (instr.src2_address != 0) ? ~RAT_buffer[instr.src2_address].in_use : 1;
        end
        operation_q <= instr.operation;
        RAT_chip_select_q <= instr.chip_select;
        RAT_op_valid_q <= (instr.chip_select!=0);
        RS_slot_q <= instr.RS_slot_ID;
    end


end

assign issue_data.operation = operation_q;
assign issue_data.RAT_chip_select = RAT_chip_select_q;
assign issue_data.src1_ROB_ID = src1_ROB_ID_q;
assign issue_data.src2_ROB_ID = src2_ROB_ID_q;
assign issue_data.src1_ready = src1_ready_q;
assign issue_data.src2_ready = src2_ready_q;
assign issue_data.RAT_op_valid = RAT_op_valid_q;
assign issue_data.rs_slot = RS_slot_ID_q;

endmodule