/* ALLOCATED INSTRUCTION BUS
 * ->  Interface between ARR units, reorder buffer and physical registers
 * ->  2 instances created, one for scalar and one for vector
 * ->  (Future scope: potential to reduce the number of fields sent inside instr)
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

    logic a_is_vector, b_is_vector;
    logic operand_a_ready, operand_b_ready;
    signal_pkg::operations_e operation;
    
    packet_pkg::rs_entry_t sc_rs_entry, vc_rs_entry;
    assign sc_rs_entry = packet_pkg::rs_entry_t'{   sc_valid, prf_tag, rob_id, instr.operation,
                                        operand_a_tag, operand_b_tag,
                                        instr.imm, instr.read_src2, 
                                        operand_a_ready, operand_b_ready, 
                                        a_is_vector, b_is_vector };
    assign vc_rs_entry = packet_pkg::rs_entry_t'{   vc_valid, prf_tag, rob_id, instr.operation,
                                        operand_a_tag, operand_b_tag,
                                        instr.imm, instr.read_src2, 
                                        operand_a_ready, operand_b_ready, 
                                        a_is_vector, b_is_vector };
    assign precalc_data = { instr.src1_address, instr.src2_address, instr.imm, instr.extend};
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

    modport sc_rs (
        input chip_select,
        input sc_rs_entry,
        input rs_slot_id
    );

    modport vc_rs (
        input chip_select,
        input vc_rs_entry,
        input rs_slot_id
    );

    modport precalc (
        input precalc_valid,
        input precalc_data,
        input precalc_prf_tag
    );
    
endinterface