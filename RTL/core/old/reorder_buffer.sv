/*
    has 3 fields, Reg, value and ready

    For branch and Jump, target address calculated in decode and stored directly
    for branch, taken/not taken is stored in rd[0]
    
    connections: WB arbiter through CDB, branching from ALU

*/
import config_pkg::*;

module reorder_buffer #()(
    input logic clk,
    input logic reset_n,

    // Instruction Queues
    input signal_pkg::queue_to_rob_signal_t input_instr,
    output logic rob_full,

    // From writeback
    input signal_pkg::wb_to_rob_branch_signal_t branch_data,
    data_bus_if.writeback scalar_wb_data_i,
    vector_data_bus_if.writeback vector_wb_data_i,

    // Retirement Bus
    retirement_bus_if.rob retire_instr,
    // RAT
    output signal_pkg::rob_to_rat_signal_t issue_instr_rat
);

    storage_pkg::rob_entry buffer[ROB_LEN-1:0];
    storage_pkg::rob_entry new_instr;

    instr_pkg::rob_address_t head, tail;
    instr_pkg::rob_address_t head_next, tail_next;
    instr_pkg::data_t precalc_data;
    logic head_epoch, tail_epoch;
    int i;

    instr_pkg::rob_address_t issue_instr_rob_id_q;
    logic issue_instr_rob_valid_q;

    always_comb begin
        tail_next = {tail_epoch,tail} + 1'b1;
        head_next = {head_epoch,head} + 1'b1;

        precalc_data = {input_instr.src1_address, input_instr.src2_address, input_instr.imm, input_instr.extend};

        full = (head == tail) && (head_epoch != tail_epoch);
        empty = (head == tail) && (head_epoch == tail_epoch);

        new_instr.ready = input_instr.ready;
        new_instr.write_to_reg = input_instr.write_to_reg;
        new_instr.dest_address = input_instr.dest_address;
        new_instr.data = (input_instr.precalc) ? precalc_data : '0;
        new_instr.is_branch = input_instr.is_branch;
        new_instr.branch_taken = input_instr.ready 
        // same as ready so that JAL instructions are going.

    end

    always_ff @(posedge clk) begin
        if(!reset_n) begin
            head <= '0;
            tail <= '0;

            for(i=0;i<ROB_LEN+1;i++) buffer[i]<= '0;
        end

        // Add instruction to ROB for allocation
        if(input_instr.valid && !full) begin
            buffer[tail] <= new_instr;

            issue_instr_rs.rob_id <= tail;
            issue_instr_rs.rob_valid <= 1'b0;

            //change this if removing lag in RAT update
            issue_instr_rat.rob_id <= tail;
            issue_instr_rat.dest_address <= input_instr.dest_address;

            tail <= tail_next[ROB_ADDR_W-1:0];
            tail_epoch <= tail_next[ROB_ADDR_W]
        end
        else begin
            issue_instr_rs.rob_id <= '0;
            issue_instr_rs.rob_valid <= 1'b0;
        end

        // Snoop CDB for updates to instructions and branches
        if(branch_data.valid && buffer[branch_data.rob_id].is_branch) begin
            buffer[branch_data.rob_id].branch_taken <= branch_data.branch_valid;
            buffer[branch_data.rob_id].ready <= 1'b1;
        end
        if(cdb_data.valid) begin
            buffer[cdb_data.rob_id].data <= cdb_data.data;
            buffer[cdb_data.rob_id].ready <= 1'b1;
        end

        // Retire instruction if head is ready
        if(buffer[head].ready && !empty) begin
            retire_instr.valid = 1'b1;
            retire_instr.write_to_reg = buffer[head].write_to_reg;
            retire_instr.dest_address = buffer[head].dest_address;
            retire_instr.data = buffer[head].data;
            retire_instr.is_branch = buffer[head].is_branch;
            retire_instr.branch_taken = buffer[head].branch_taken;
            retire_instr.rob_id = head;

            buffer[head] <= '0;

            head <= head_next[ROB_ADDR_W-1:0];
            head_epoch <= head_next[ROB_ADDR_W]
        end
        else begin
            retire_instr.valid = '0;
        end

    end

    assign rob_full = full;

endmodule