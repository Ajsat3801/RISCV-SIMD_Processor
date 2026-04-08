
module reorder_buffer (
    input logic clk_i,
    input logic reset_ni,
    input logic flush,

    // instruction bus
    allocation_bus_if.rob allocate_instr_io,

    // scalar databus
    scalar_data_bus_if.snoop scalar_wb_i;
    //modport snoop (input  valid, rob_id, prf_tag, data);

    // vector databus
    vector_data_bus_if.snoop vector_wb_i;
    //modport snoop (input  valid, rob_id, prf_tag, data);

    // output to retirement bus
    retirement_bus_if.rob retire_instr_o,
    /*modport rob (output   valid, write_to_reg, dest_address,  
                            is_branch, branch_taken, tag)*/

    output logic rob_full_o
);

/*
 *
 *
 */

storage_pkg::rob_entry_t rob_table[ROB_LEN-1:0];
storage_pkg::rob_entry_t rob_input;
instr_pkg::rob_address_t head, tail, head_next, tail_next;
logic head_epoch, tail_epoch, head_epoch_next, tail_epoch_next;
logic full, empty;
/*
typedef struct packed {
        logic ready;
        
        logic write_to_reg;
        instr_pkg::tag_t prf_tag;
        instr_pkg::arf_address_t dest_address;

        instr_pkg::data_t data;
        logic is_branch;
        logic branch_taken;
        
    } rob_entry_t;
*/

always_comb begin

    {head_epoch_next, head_next} = {head_epoch, head} + 1'b1;
    {tail_epoch_next, tail_next} = {tail_epoch, tail} + 1'b1;

    full  = (head == tail) && (head_epoch != tail_epoch);
    empty = (head == tail) && (head_epoch == tail_epoch);

    push_allowed = !full && allocate_instr_i.valid;
    pop_allowed  = !empty && rob_table[head].ready;

    // compiling instruction into rob entry
    // inputs valid and instr
    rob_input.ready
    rob_input.write_to_reg
    rob_input.prf_tag
    rob_input.arf_address_t
    rob_input.data
    rob_input.is_branch
    rob_input.branch_taken

    
end

always_ff @(posedge clk) begin
    if(!reset_ni) begin
        
        for (i=0; i<ROB_LEN; i++) rob_table[i] <= '0;
        
        head <= '0;
        tail <= '0;
        head_epoch <= '0;
        tail_epoch <= '0;
        
        sprf_rob_id_o <= '0;
        sprf_rob_id_valid_o <= 1'b0;

        vprf_rob_id_o <= '0;
        vprf_rob_id_valid_o <= 1'b0;

    end
    if(flush_i) begin
    end
    else begin
    end
end

endmodule