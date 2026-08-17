/*  -----------------------------------------------------------------------------------------------
 *                                  ALLOCATED INSTRUCTION BUS
 *  -----------------------------------------------------------------------------------------------
 *
 *  Functions/Behavior:
 *  ->  Bus that compiles decoded instruction from alloc-rename-retire unit & assigns rob id from
 *      reorder buffer into a single packet and broadcasts to all the reservation stations.
 *  ->  The reservation stations snoop the bus & processes them by matching with chip_select
 *  ->  Also the interface between alloc-rename-retire and physical register file for writing
 *      the results of pre-calculated instructions
 *  
 *  Inputs & Outputs:
 *  ->  Allocate-Rename-Retire:
 *      ->  Instruction to be sent to the reservation stations
 *      ->  Already decoded
 *      ->  Destination PRF ID assiged already 
 *      ->  source IDs and source readys
 *      ->  results of pre-calculated inputs
 *      ->  pre-calculated results into PRF
 *  ->  Reorder Buffer
 *      ->  PRF tag of the allocated instruction
 *      ->  outputs ROB ID for the allocated instruction
 *  ->  Reservation Stations
 *      ->  combined inputs of ROB and ARR into a single struct rs_entry_t
 *      ->  reservation station slot id from ARR
 *  ->  Physical Register File
 *      ->  Preloaded results that dont need a register/memory read
 *
 *  Notes:
 *  ->  Assigned instruction may or may not be ready to execute, that is handled by the 
 *      reservation stations
 *  ->  The alloc-rename-retire unit and reorder buffer work independently with no 
 *      co-ordination or checks, keep eye out for incorrect ROB ID getting assigned to
 *      the instruction during verification
 *
 *  -----------------------------------------------------------------------------------------------
*/

interface if_alloc_bus;
    
    logic sc_valid, vc_valid, valid, precalc_valid;
    signal_pkg::rs_slot_id_t rs_slot_id;
    signal_pkg::rob_address_t rob_id;
    packet_pkg::decoded_instr_t instr;
    signal_pkg::prf_tag_t prf_tag;
    signal_pkg::prf_tag_t operand_a_tag, operand_b_tag;
    signal_pkg::prf_tag_t precalc_prf_tag;
    signal_pkg::chip_select_e chip_select;
    signal_pkg::data_t precalc_data;

    logic a_is_vector, b_is_vector;
    logic operand_a_ready, operand_b_ready;
    signal_pkg::operations_e operation;
    
    packet_pkg::rs_entry_t rs_entry;
    
    assign rs_entry = packet_pkg::rs_entry_t'{   1'b1, prf_tag, rob_id, instr.operation,
                                        operand_a_tag, operand_b_tag,
                                        instr.imm, instr.read_src2, 
                                        a_is_vector, b_is_vector,
                                        operand_a_ready, operand_b_ready
                                        };
    assign precalc_data =   (instr.is_branch) ?
                            {22'd0, instr.src1_address, instr.src2_address} :
                            { instr.src1_address, instr.src2_address, instr.imm, instr.extend};
    assign chip_select = instr.chip_select;
    assign valid = sc_valid || vc_valid;

    modport arr (
        output sc_valid, vc_valid,
        output rs_slot_id,
        output instr,
        output prf_tag,
        output operand_a_tag, operand_b_tag,
        output operand_a_ready, operand_b_ready,
        output a_is_vector, b_is_vector,
        output precalc_valid, precalc_prf_tag
    );

    modport rob (
        input valid,
        input instr,
        input prf_tag,
        output rob_id
    );

    modport rs (
        input valid,
        input chip_select,
        input rs_entry,
        input rs_slot_id
    );

    modport precalc (
        input precalc_valid,
        input precalc_data,
        input precalc_prf_tag
    );
    
endinterface