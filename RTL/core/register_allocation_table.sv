

module register_allocation_table #(
    parameter REGISTER_SIZE=32
    )(
    input clk,
    input reset_n,

    // connection from instruction queues
    input IQ_RAT_t alloc_instr,

    // connection from ROB (issue stage)
    input rat_rob_comms_t issue_instr,

    // connection from ROB (retire stage)
    retirement_bus_if.Retire retire_instr,

    // connections to reservation stations
    operation_bus_if.RAT issue_data,


);

RAT_entry_t RAT_buffer[31:0];
operations_e operation_q;
chip_select_e RAT_chip_select_q;

logic src1_ready_q, src2_ready_q, RAT_op_valid_q;
logic[4:0] src1_ROB_id_q, src2_ROB_id_q,src1_ROB_id, src2_ROB_id;
logic[2:0] RS_slot_id_q;

logic retire, issue, replace, alloc_src1, alloc_src2, forward_src1, forward_src2;
logic src1_ready, src2_ready;

integer unsigned i;

always_comb begin
    src1_ROB_id = 'd0;
    src2_ROB_id = 'd0;
    src1_ready = 1'b1;
    src2_ready = 1'b1;

    retire = retire_instr.instr_valid && (retire_instr.rd != 'd0) && RAT_buffer[retire_instr.rd].ROB_id == retire_instr.ROB_id;
    issue = issue_instr.valid && (issue_instr.rd != 'd0);
    replace = issue && retire && (retire_instr.rd == issue_instr.rd);

    alloc_src1 = alloc_instr.valid && alloc_instr.src1_address != 0;
    alloc_src2 = alloc_instr.valid && alloc_instr.src2_address != 0;

    forward_src1 = issue_instr.valid && issue_instr.rd == alloc_instr.src1_address && alloc_instr.src1_address != 0;
    forward_src2 = issue_instr.valid && issue_instr.rd == alloc_instr.src2_address && alloc_instr.src2_address != 0;

    // combinational read for RS1 and RS2
    if(alloc_src1) begin
        src1_ROB_id = (forward_src1) ? issue_instr.ROB_id : RAT_buffer[alloc_instr.src1_address].ROB_id;
        src1_ready = (forward_src1) ? 0 : ~RAT_buffer[alloc_instr.src1_address].in_use;
    end

    if(alloc_src2) begin
        src2_ROB_id = (forward_src2) ? issue_instr.ROB_id : RAT_buffer[alloc_instr.src2_address].ROB_id;
        src2_ready = (forward_src2) ? 0 : ~RAT_buffer[alloc_instr.src2_address].in_use;
    end
end


always_ff @(posedge clk) begin
    
    if(!reset_n) begin // reset
        
        for (i = 0; i < 32; i++) RAT_buffer[i]<= 'd0;

        src1_ready_q <= 1'b1;
        src2_ready_q <= 1'b1;
        src1_ROB_id_q <= '0;
        src2_ROB_id_q <= '0;
        operation_q <= '0;
        RAT_chip_select_q <= '0;
        RAT_op_valid_q <= 1'b0;
        RS_slot_id_q <= 3'b000;

    end
    else begin
        
        // update RAT on dispatch
        if (retire && !replace) begin
            // RAT is reset
            RAT_buffer[retire_instr.rd].ROB_id <= retire_instr.rd;
            RAT_buffer[retire_instr.rd].in_use <= 1'b0;
        end
        // update RAT on issue
        if(issue) begin
            RAT_buffer[issue_instr.rd].ROB_id <= issue_instr.ROB_id;
            RAT_buffer[issue_instr.rd].in_use <= 1'b1;
        end


        src1_ROB_id_q <= src1_ROB_id;
        src1_ready_q <= src1_ready;

        src2_ROB_id_q <= src2_ROB_id;
        src2_ready_q <= src2_ready;

        operation_q <= alloc_instr.operation;
        RAT_chip_select_q <= alloc_instr.chip_select;
        RAT_op_valid_q <= alloc_instr.valid;
        RS_slot_id_q <= alloc_instr.RS_slot_id;
    end


end

assign issue_data.operation = operation_q;
assign issue_data.RAT_chip_select = RAT_chip_select_q;
assign issue_data.src1_ROB_ID = src1_ROB_id_q;
assign issue_data.src2_ROB_ID = src2_ROB_id_q;
assign issue_data.src1_ready = src1_ready_q;
assign issue_data.src2_ready = src2_ready_q;
assign issue_data.RAT_op_valid = RAT_op_valid_q;
assign issue_data.rs_slot = RS_slot_id_q;

endmodule