
module ooo_reorder_buffer (
    input logic clk_i,
    input logic reset_ni,

    if_alloc_bus.rob alloc_instr_io,

    if_data_bus.snoop sc_data_bus_i,
    if_data_bus.snoop vc_data_bus_i,

    input packet_pkg::br_result_t branch_result_i,
    input packet_pkg::store_retire_request_t store_retire_req_i,

    if_retirement_bus.rob retire_instr_o,

    output logic rob_full_o,
    output logic flush_o
);

/*
sc is 1 and vc is 0 -> 
    store scalar prf in dest
    scalar instruction completely ignore vc
sc is 0 and vc is 1 -> vv instruction -> completely ignore sc
both 1 -> vx instruction, -> store vector prf in dest
both 0 -> NOP -> output not valid
*/

packet_pkg::rob_entry_t rob_table[ROB_LEN-1:0];
packet_pkg::rob_entry_t rob_input;
signal_pkg::rob_address_t head, tail, head_next, tail_next;
logic full, empty;
logic push_allowed, pop_allowed;
int i;

typedef enum logic[1:0]{
    INSTR_NOP = 2'b00, INSTR_VV = 2'b01, 
    INSTR_SC  = 2'b10, INSTR_VX = 2'b11
} instr_type_e;

instr_type_e instr_type;

always_comb begin

    {head_next.epoch, head_next.address} = {head.epoch, head.address} + 1'b1;
    {tail_next.epoch, tail_next.address} = {tail.epoch, tail.address} + 1'b1;

    full  = (head.address == tail.address) && (head.epoch != tail.epoch);
    empty = (head.address == tail.address) && (head.epoch == tail.epoch);
    
    push_allowed = !full && alloc_instr_io.valid;
    pop_allowed  = !empty && rob_table[head.address].ready;

    // compiling instruction into rob entry
    // inputs valid and instr

    rob_input.ready =   alloc_instr_io.instr.pre_calc && 
                        alloc_instr_io.instr.write_to_reg;
    rob_input.write_to_reg = alloc_instr_io.instr.write_to_reg;
    rob_input.prf_tag      = alloc_instr_io.prf_tag;
    rob_input.dest_address = alloc_instr_io.instr.dest_address;
    rob_input.data = {
        alloc_instr_io.instr.src1_address,
        alloc_instr_io.instr.src2_address,
        alloc_instr_io.instr.imm,
        alloc_instr_io.instr.extend
    };
    rob_input.is_branch = alloc_instr_io.instr.is_branch;
    rob_input.branch_taken = rob_input.ready && alloc_instr_io.instr.is_branch;

    // sends signal to instruction queue when 1 slot or no slots are remaining
    rob_full_o = (head.address == tail_next.address) && (head.epoch != tail_next.epoch) || full;
    
    alloc_instr_io.rob_id = tail;
    
end

always_ff @(posedge clk_i) begin
    
    if(!reset_ni) begin
        for (i=0; i<ROB_LEN; i++) rob_table[i] <= '0;
        head <= '0;
        tail <= '0;

    end
    else begin

        // adding to ROB
        if(push_allowed) begin
            rob_table[tail.address] <= rob_input;
            tail <= tail_next;
        end
        
        // Snooping
        // store retirement signal snooping
        if(store_retire_req_i.valid) rob_table[store_retire_req_i.rob_id.address].ready <= 1'b1;

        // branch snooping
        if(branch_result_i.valid && rob_table[branch_result_i.rob_id.address].is_branch) begin
            rob_table[branch_result_i.rob_id.address].ready <= 1'b1;
            rob_table[branch_result_i.rob_id.address].branch_taken <= branch_result_i.branch_taken;
        end
        // scalar snooping
        if(sc_data_bus_i.valid) rob_table[sc_data_bus_i.rob_id.address].ready <= 1'b1;
        
        // vector snooping
        if(vc_data_bus_i.valid) rob_table[vc_data_bus_i.rob_id.address].ready <= 1'b1;

        // Retire
        if(pop_allowed) begin
            retire_instr_o.valid   <= rob_table[head.address].ready;
            retire_instr_o.prf_tag <= rob_table[head.address].prf_tag;
            retire_instr_o.rob_id  <= head;
            retire_instr_o.data    <= rob_table[head.address].data;
            retire_instr_o.write_to_reg <= rob_table[head.address].write_to_reg;
            retire_instr_o.dest_address <= rob_table[head.address].dest_address;
            retire_instr_o.is_branch    <= rob_table[head.address].is_branch;
            retire_instr_o.branch_taken <= rob_table[head.address].branch_taken;

            if(rob_table[head.address].is_branch && rob_table[head.address].branch_taken) begin
                for (i=0; i<ROB_LEN; i++) rob_table[i] <= '0;
                head <= '0;
                tail <= '0;
                flush_o <= 1'b1;
            end 
            else begin
                head <= head_next;
                rob_table[head.address] <= '0;
                flush_o <= 1'b0;
            end
        end
        else begin
            retire_instr_o.valid   <= '0;
            retire_instr_o.prf_tag <= '0;
            retire_instr_o.rob_id  <= '0;
            retire_instr_o.data    <= '0;
            retire_instr_o.write_to_reg <= '0;
            retire_instr_o.dest_address <= '0;
            retire_instr_o.is_branch    <= '0;
            retire_instr_o.branch_taken <= '0;
            flush_o <= 1'b0;
        end
    end
end

endmodule