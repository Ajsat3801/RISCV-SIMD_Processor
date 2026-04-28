interface if_vector_request_bus;
    
    logic valid;
    instr_pkg::rs_slot_id_t rs_slot;
    instr_pkg::decoded_instr_t instr;
    logic rob_valid;
    instr_pkg::rob_address_t rob_id;
    instr_pkg::prf_tag_t prf_tag;
    instr_pkg::prf_tag_t operand_a_tag;
    instr_pkg::prf_tag_t operand_b_tag;
    instr_pkg::operations_e operation;
    instr_pkg::chip_select_e chip_select;
    logic a_is_vector, b_is_vector;
    logic operand_a_ready, operand_b_ready;

    modport prf (
        output valid, chip_select,
        output instr, operation,
        output rob_id, rs_slot, prf_tag,
        output operand_a_tag, operand_b_tag,
        output a_is_vector, b_is_vector,
        output operand_a_ready, operand_b_ready
    );

    modport rob (
        output rob_valid,
        output rob_id
    );

    modport rs (
        input valid, chip_select,
        input instr, operation,
        input rob_id, rs_slot, prf_tag,
        input operand_a_tag, operand_b_tag,
        input a_is_vector, b_is_vector,
        input operand_a_ready, operand_b_ready
    );    

endinterface