module register_allocation_table #(
    parameter REGISTER_SIZE=32
    )(
    input clk,
    input reset_n,

    // connection from instruction queues
    input queue_to_rat_signal_t alloc_instr,

    // connection from ROB (issue stage)
    input rob_to_rat_signal_t issue_instr,

    // connection from ROB (retire stage)
    retirement_bus_if.retire retire_instr,

    // connections to reservation stations
    operation_bus_if.rat issue_data,
);

rat_entry_t rat_buffer[31:0];
operations_e operation_q;
chip_select_e chip_select_q;

logic src1_ready_q, src2_ready_q, rat_input_valid_q;
logic[4:0] src1_rob_id_q, src2_rob_id_q, src1_rob_id, src2_rob_id;
logic[2:0] rs_slot_id_q;

logic retire, issue, replace, alloc_src1, alloc_src2, forward_src1, forward_src2;
logic src1_ready, src2_ready;

integer unsigned i;

always_comb begin
    src1_rob_id = 'd0;
    src2_rob_id = 'd0;
    src1_ready = 1'b1;
    src2_ready = 1'b1;

    retire = retire_instr.instr_valid && (retire_instr.dest_address != 'd0) && rat_buffer[retire_instr.dest_address].rob_id == retire_instr.rob_id;
    issue = issue_instr.valid && (issue_instr.dest_address != 'd0);
    replace = issue && retire && (retire_instr.dest_address == issue_instr.dest_address);

    alloc_src1 = alloc_instr.valid && alloc_instr.src1_address != 0;
    alloc_src2 = alloc_instr.valid && alloc_instr.src2_address != 0;

    forward_src1 = issue_instr.valid && issue_instr.dest_address == alloc_instr.src1_address && alloc_instr.src1_address != 0;
    forward_src2 = issue_instr.valid && issue_instr.dest_address == alloc_instr.src2_address && alloc_instr.src2_address != 0;

    // combinational read for RS1 and RS2
    if(alloc_src1) begin
        src1_rob_id = (forward_src1) ? issue_instr.rob_id : rat_buffer[alloc_instr.src1_address].rob_id;
        src1_ready = (forward_src1) ? 0 : ~rat_buffer[alloc_instr.src1_address].in_use;
    end

    if(alloc_src2) begin
        src2_rob_id = (forward_src2) ? issue_instr.rob_id : rat_buffer[alloc_instr.src2_address].rob_id;
        src2_ready = (forward_src2) ? 0 : ~rat_buffer[alloc_instr.src2_address].in_use;
    end
end


always_ff @(posedge clk) begin
    
    if(!reset_n) begin // reset
        
        for (i = 0; i < 32; i++) rat_buffer[i]<= 'd0;

        src1_ready_q <= 1'b1;
        src2_ready_q <= 1'b1;
        src1_rob_id_q <= '0;
        src2_rob_id_q <= '0;
        operation_q <= '0;
        chip_select_q <= '0;
        rat_input_valid_q <= 1'b0;
        rs_slot_id_q <= 3'b000;

    end
    else begin
        
        // update RAT on dispatch
        if (retire && !replace) begin
            // RAT is reset
            rat_buffer[retire_instr.dest_address].rob_id <= retire_instr.dest_address;
            rat_buffer[retire_instr.dest_address].in_use <= 1'b0;
        end
        // update RAT on issue
        if(issue) begin
            rat_buffer[issue_instr.dest_address].rob_id <= issue_instr.rob_id;
            rat_buffer[issue_instr.dest_address].in_use <= 1'b1;
        end

        src1_rob_id_q <= src1_rob_id;
        src1_ready_q <= src1_ready;

        src2_rob_id_q <= src2_rob_id;
        src2_ready_q <= src2_ready;

        operation_q <= alloc_instr.operation;
        chip_select_q <= alloc_instr.chip_select;
        rat_input_valid_q <= alloc_instr.valid;
        rs_slot_id_q <= alloc_instr.RS_slot_id;
        sign_q <= alloc_instr.sign;
    end


end

assign issue_data.rat_input_valid = rat_input_valid_q;

assign issue_data.operation = operation_q;
assign issue_data.chip_select = chip_select_q;
assign issue_data.sign = sign_q;

assign issue_data.rs_slot = rs_slot_id_q;

assign issue_data.src1_rob_id = src1_rob_id_q;
assign issue_data.src2_rob_id = src2_rob_id_q;
assign issue_data.src1_ready = src1_ready_q;
assign issue_data.src2_ready = src2_ready_q;




endmodule