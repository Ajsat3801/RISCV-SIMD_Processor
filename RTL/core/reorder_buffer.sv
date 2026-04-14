
module reorder_buffer (
    input logic clk_i,
    input logic reset_ni,

    allocation_bus_if.rob sc_allocated_instr_io,
    allocation_bus_if.rob vc_allocated_instr_io,

    data_bus_if.snoop scalar_wb_i,
    data_bus_if.snoop vector_wb_i,
    input signal_pkg::wb_to_rob_branch_t branch_i,

    operand_bus_if.rob alloc_instr_o,

    retirement_bus_if.rob retire_instr_o,

    output logic rob_exp_full_o,
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

storage_pkg::rob_entry_t rob_table[ROB_LEN-1:0];
storage_pkg::rob_entry_t rob_input;
instr_pkg::rob_address_t head, tail, head_next, tail_next;
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

    instr_type   = {sc_allocated_instr_io.valid, vc_allocated_instr_io.valid}; 
    
    push_allowed =  !full && 
                    (sc_allocated_instr_io.valid || vc_allocated_instr_io.valid) && 
                    (instr_type != INSTR_NOP);
    pop_allowed  = !empty && rob_table[head.address].ready;

    // compiling instruction into rob entry
    // inputs valid and instr

    rob_input = '0;

    case(instr_type)
        INSTR_VV: begin 
            rob_input.write_to_reg = vc_allocated_instr_io.instr.write_to_reg;
            rob_input.prf_tag = vc_allocated_instr_io.prf_tag;
            rob_input.dest_address = vc_allocated_instr_io.instr.dest_address;
        end
        INSTR_VX: begin
            rob_input.write_to_reg = vc_allocated_instr_io.instr.write_to_reg;
            rob_input.prf_tag = vc_allocated_instr_io.prf_tag;
            rob_input.dest_address = vc_allocated_instr_io.instr.dest_address;
        end
        INSTR_SC: begin
            rob_input.ready =   sc_allocated_instr_io.instr.pre_calc && 
                                sc_allocated_instr_io.instr.write_to_reg;
            rob_input.write_to_reg = sc_allocated_instr_io.instr.write_to_reg;
            rob_input.prf_tag      = sc_allocated_instr_io.prf_tag;
            rob_input.dest_address = sc_allocated_instr_io.instr.dest_address;
            rob_input.data = {
                sc_allocated_instr_io.instr.src1_address,
                sc_allocated_instr_io.instr.src2_address,
                sc_allocated_instr_io.instr.imm,
                sc_allocated_instr_io.instr.extend
            };
            rob_input.is_branch = sc_allocated_instr_io.instr.is_branch; 
            
        end

    endcase

    // sends signal to instruction queue when 1 slot or no slots are remaining
    rob_exp_full_o = (head.address == tail_next.address) && 
                     (head.epoch != tail_next.epoch) || full;
    
end

always_ff @(posedge clk_i) begin
    
    if(!reset_ni) begin
        for (i=0; i<ROB_LEN; i++) rob_table[i] <= '0;
        head <= '0;
        tail <= '0;
        alloc_instr_o.rob_valid <= 1'b0;
        alloc_instr_o.rob_id    <= '0;

    end
    else begin

        if(push_allowed) begin
            rob_table[tail.address] <= rob_input;
            alloc_instr_o.rob_valid <= 1'b1;
            alloc_instr_o.rob_id    <= tail;
            tail <= tail_next;
        end
        else begin
            alloc_instr_o.rob_valid <= 1'b0;
            alloc_instr_o.rob_id    <= '0;
        end

        // Snooping
        // branch snooping
        if(branch_i.valid && rob_table[branch_i.rob_id.address].is_branch) begin
            rob_table[branch_i.rob_id.address].ready <= 1'b1;
            rob_table[branch_i.rob_id.address].branch_taken <= branch_i.branch_taken;
        end
        // scalar snooping
        if(scalar_wb_i.valid) begin
            rob_table[scalar_wb_i.rob_id.address].ready <= 1'b1;
        end
        // vector snooping
        if(vector_wb_i.valid) begin
            rob_table[vector_wb_i.rob_id.address].ready <= 1'b1;
        end

        // Retire
        if(pop_allowed) begin
            retire_instr_o.valid   <= rob_table[head.address].ready;
            retire_instr_o.prf_tag <= rob_table[head.address].prf_tag;
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