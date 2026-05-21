/* ------------------------------------------------------------------------------------------------
 *                                        INSTRUCTION FETCH
 * ------------------------------------------------------------------------------------------------
 *  Function/Behavior:
 *  ->  maintains PC and reads from instruction memory and sends them to the decoder
 *  ->  branching also done in this unit, PC is changed if a branch is taken and current output is
        discarded
 *  ->  ecall instruction is treated as terminate and all subsequent instructions are invalid
 *
 *  Inputs:
 *  ->  clock, reset
 *  ->  external signal to  start compute
 *  ->  ready signal from instruction queue 
 *  ->  retirement bus, for branching 
 *  ->  instruction from instruction memory
 *
 *  Outputs:
 *  ->  read request for instruction memory
 *  ->  outputs to decode
 *      ->  fetched instruction
 *      ->  pc of fetched instruction
 *      ->  valid signal
 *  Notes:
 *  ->  instruction memory read is always valid, this unit gates the instructions to determine if 
        it is valid or not
 */

module fe_fetch(
    input  logic clk_i,
    input  logic reset_ni,
    
    input  logic compute_i,
    input  logic ready_i,

    if_retirement_bus.branch retire_instr_i,

    output signal_pkg::data_t fetched_instr_o,
    output signal_pkg::pc_t fetched_pc_o,
    output logic fetch_valid_o,

    input  signal_pkg::data_t instr_imem_i,
    output packet_pkg::imem_request_t imem_req_o
);
    
    signal_pkg::pc_t pc, pc_sent, pc_imem;
    logic branch_taken;
    logic complete, valid;

    always_comb begin
        branch_taken =  retire_instr_i.valid && 
                        retire_instr_i.is_branch &&
                        retire_instr_i.branch_taken;

        pc_imem = (branch_taken) ? retire_instr_i.data : pc;
        
        imem_req_o.read_enable  = compute_i;
        imem_req_o.write_enable = 1'b0;
        imem_req_o.address = pc_imem;
        imem_req_o.data    = 32'b0;

    end

    always_ff @(posedge clk_i) begin
        if(!reset_ni) begin
            fetched_pc_o    <= '0;
            fetched_instr_o <= '0;
            fetch_valid_o   <= 1'b0;
            pc <= '0;
            complete <= 1'b0;
            valid <= 1'b0;
        end
        else if(compute_i && ready_i) begin
            pc <= (branch_taken) ? retire_instr_i.data + 1'b1 : pc + 1'b1;
            pc_sent <= pc_imem;
            fetched_instr_o <= instr_imem_i;
            fetched_pc_o    <= pc_sent;
            fetch_valid_o   <= !branch_taken && !complete && valid; 
            valid <= 1'b1;
            //ecall is used as terminate
            if(instr_imem_i[6:0] == 7'b1110011) complete <= 1'b1;
        end
        else begin
            fetch_valid_o   <= 1'b0;
        end
    end

endmodule