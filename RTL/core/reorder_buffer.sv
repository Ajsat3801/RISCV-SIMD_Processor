
module reorder_buffer (
    input logic clk_i,
    input logic reset_ni,

    // allocation bus
    allocation_bus_if.rob sc_allocated_instr_io,
    allocation_bus_if.rob vc_allocated_instr_io,

    // scalar databus
    data_bus_if.snoop scalar_wb_i,
    //modport snoop (input  valid, rob_id, prf_tag, data);

    input signal_pkg::wb_to_rob_branch_signal_t branch_i,

    // vector databus
    vector_data_bus_if.snoop vector_wb_i,
    //modport snoop (input  valid, rob_id, prf_tag, data);

    // output to retirement bus
    retirement_bus_if.rob retire_instr_o,
    /*modport rob (output   valid, write_to_reg, dest_address,  
                            is_branch, branch_taken, tag)*/

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
logic full, empty, add_to_rob;

typedef enum {
    2'b00 = INSTR_NOP, 2'b01 = INSTR_VV, 
    2'b10 = INSTR_SC,  2'b11 = INSTR_VX
} instr_type_e;

instr_type_e instr_type;

always_comb begin

    {head_next.epoch, head_next.address} = {head.epoch, head.address} + 1'b1;
    {tail_next.epoch, tail_next.address} = {tail.epoch, tail.address} + 1'b1;

    full  = (head.address == tail.address) && (head.epoch != tail.epoch);
    empty = (head.address == tail.address) && (head.epoch == tail.epoch);
    
    push_allowed = !full && sc_allocated_instr_io.valid;
    pop_allowed  = !empty && rob_table[head].ready;

    // compiling instruction into rob entry
    // inputs valid and instr

    rob_input = '0;

    instr_type = {sc_allocated_instr_io.valid, vc_allocated_instr_io.valid}; 

    case (instr_type)
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
            rob_input.ready =   sc_allocated_instr_io.pre_calc && 
                                sc_allocated_instr_io.write_to_reg;
            rob_input.write_to_reg = sc_allocated_instr_io.instr_write_to_reg;
            rob_input.prf_tag      = sc_allocated_instr_io.prf_tag;
            rob_input.dest_address = sc_allocated_instr_io.instr.dest_address;
            rob_input.data = {
                sc_allocated_instr_io.instr.src1_address,
                sc_allocated_instr_io.instr_src2_address,
                sc_allocated_instr_io.instr_imm,
                sc_allocated_instr_io.extend
            };
            rob_input.is_branch = sc_allocated_instr_io.instr.is_branch; 
            
        end

    endcase
    
    add_to_rob = (instr_type != INSTR_NOP) && !full;

    // sending tail values to ARR modules
    sc_allocated_instr_io.rob_tail = tail;
    vc_allocated_instr_io.rob_tail = tail;

    // sends signal to instruction queue when 1 slot or no slots are remaining
    rob_exp_full_o = (head.address == tail_next.address) && 
                     (head.epoch != tail_next.epoch) || full;
    
end

always_ff @(posedge clk) begin
    if(!reset_ni) begin
        
        for (i=0; i<ROB_LEN; i++) rob_table[i] <= '0;
        
        head <= '0;
        tail <= '0;

    end
    else begin

        if(add_to_rob) begin
            rob_table[tail] <= rob_input;
            tail <= tail_next;
        end

        // Snooping
        // branch snooping
        if(branch_i.valid && rob_table[branch_i.rob_id].is_branch) begin
            rob_table[branch_i.rob_id].ready <= 1'b1;
            rob_table[branch_i.rob_id].branch_taken <= branch_i.branch_taken;
        end
        // scalar snooping
        if(scalar_wb_i.valid) begin
            rob_table[scalar_wb_i.rob_id].ready <= 1'b1;
        end
        // vector snooping
        if(vector_wb_i.valid) begin
            rob_table[vector_wb_i.rob_id].ready <= 1'b1;
        end

        // Retire
        if(rob_table[head].ready) begin
            retire_instr_o.valid <= rob_table[head].ready;
            retire_instr_o.write_to_reg <= rob_table[head].write_to_reg;
            retire_instr_o.prf_tag <= rob_table[head].prf_tag;
            retire_instr_o.dest_address <= rob_table[head].dest_address;
            retire_instr_o.data <= rob_table[head].data;
            retire_instr_o.is_branch <= rob_table[head].is_branch;
            retire_instr_o.branch_taken <= rob_table[head].branch_taken;

            if(rob_table[head].is_branch && rob_table[head].branch_taken) begin
                for (i=0; i<ROB_LEN; i++) rob_table[i] <= '0;
                head <= '0;
                tail <= '0;
            end 
            else head <= head_next;
        end
    end
end

endmodule