/* ------------------------------------------------------------------------------------------------
 *                                        INSTRUCTION FETCH
 * ------------------------------------------------------------------------------------------------
 *  Function/Behavior:
 *  ->  Maintains Program Counter and issues read requests to instruction memory, forwards fetched
 *      instructions downstream to decode.
 *  ->  PC is redirected to branch target and current in-flight instruction is invalidated when the
 *      retirement bus signals a taken branch, .
 *  ->  ECALL instruction acts as a termination signal. All instructions fetched after an ECALL are
 *      marked invalid unless a branch clears the complete flag.
 *
 *  Inputs:
 *  ->  clk, reset_n
 *  ->  compute_i — External start-compute enable
 *  ->  ready_i — Ready signal from the instruction queue.
 *  ->  retire_instr_i — Retirement bus used for branch resolution.
 *  ->  imem_instr_i — Instruction word returned by instruction memory on the current cycle.
 *  ->  imem_addr_i — Address of instruction word returned by instruction memory.
 *
 *  Outputs:
 *  ->  fetched_instr_o — The instruction word latched from imem_instr_i on the previous cycle.
 *  ->  fetched_pc_o — The PC value associated with fetched_instr_o.
 *  ->  fetch_valid_o — signal valid instruction
 *  ->  imem_req_o — Instruction memory request
 *
 *  Notes:
 *  ->  Instruction memory is always read; Module does not suppress the read on branch. Pipeline
 *      validity is controlled entirely through fetch_valid_o, not by gating memory.
 *  ->  The valid signal requires an internal warm-up: the first cycle after reset keeps valid=0
 *      and sets it to 1 on the next active cycle. Preventing spurious valid on the first fetch.
 *  ->  When a branch is taken, complete is cleared to 0 on the same cycle PC is redirected. This
 *      allows execution to resume in case of an ECALL in a mispredicted branch.
 *  ->  PC arithmetic is word-addressed (increments by 1, not 4). The branch target from retirement
 *      bus is expected to also be a word address.
 *
 * ------------------------------------------------------------------------------------------------
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

    input  signal_pkg::data_t imem_instr_i,
    input  [7:0] imem_addr_i,
    output packet_pkg::imem_request_t imem_req_o
);
    
    signal_pkg::pc_t pc, pc_imem;
    logic branch_taken;
    logic complete, valid;

    always_comb begin
        branch_taken =  retire_instr_i.valid && 
                        retire_instr_i.is_branch &&
                        retire_instr_i.branch_taken;

        pc_imem = (branch_taken) ? retire_instr_i.data : pc;
        
        imem_req_o.read_enable  = compute_i;
        imem_req_o.write_enable = 1'b0;
        imem_req_o.address = (ready_i) ? pc_imem : imem_addr_i;
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
            fetched_instr_o <= imem_instr_i;
            fetched_pc_o    <= imem_addr_i;
            fetch_valid_o   <= !branch_taken && !complete && valid; 
            valid <= 1'b1;
            //ecall is used as terminate
            if(imem_instr_i[6:0] == 7'b1110011) complete <= 1'b1;
            if(branch_taken) complete <= 1'b0;
        end
    end

endmodule