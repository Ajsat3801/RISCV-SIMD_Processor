
module fe_fetch(
    input  logic clk_i,
    input  logic reset_ni,
    
    input  logic compute_i,
    
    input  logic ready_i,
    output instr_pkg::raw_instr_t instr_decode_o,
    output instr_pkg::pc_t pc_decode_o,
    output logic fetch_valid_o,

    if_retirement_bus.branch retire_instr_i,

    input  instr_pkg::raw_instr_t instr_imem_i,
    input  logic imem_valid_i,
    output instr_pkg::pc_t pc_imem_o,
    output logic read_enable_o
);
    
    instr_pkg::pc_t pc, pc_sent;
    logic branch_taken;

    always_comb begin
        branch_taken =  retire_instr_i.valid && 
                        retire_instr_i.is_branch &&
                        retire_instr_i.branch_taken;

        pc_imem_o = (branch_taken) ? retire_instr_i.data : pc;
        read_enable_o = compute_i;
    end

    always_ff @(posedge clk_i) begin
        if(!reset_ni) begin
            pc_decode_o <= '0;
            instr_decode_o <= '0;
            fetch_valid_o <= 1'b0;
            pc <= '0;
        end
        else if(compute_i && ready_i) begin
            pc <= (branch_taken) ? retire_instr_i.data + 1'b1 : pc + 1'b1;
            pc_sent <= pc_imem_o;
            instr_decode_o <= instr_imem_i;
            pc_decode_o    <= pc_sent;
            fetch_valid_o  <= !branch_taken;  
        end
        else begin
            fetch_valid_o <= 1'b0;
        end
    end

endmodule