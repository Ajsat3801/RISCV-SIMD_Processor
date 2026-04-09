interface allocation_bus_if;
    
    logic valid;
    instr_pkg::rs_slot_id_t rs_slot;
    instr_pkg::decoded_instr_t instr;
    instr_pkg::prf_tag_t prf_tag;
    instr_pkg::rob_address_t rob_id;
    instr_pkg::prf_tag_t operand_a_tag;
    instr_pkg::prf_tag_t operand_b_tag;

    instr_pkg::rob_address_t rob_tail;

    modport alloc_rename (
        input rob_tail,

        output valid,
        output rs_slot,
        output instr,
        output prf_tag,
        output rob_id,
        output operand_a_tag,
        output operand_b_tag  
    );
    modport rob (
        input valid,
        input instr,
        input prf_tag,
        input rob_id, 

        output rob_tail,
    );

    modport prf (
        input valid,
        input rs_slot,
        input instr,
        input prf_tag,
        input rob_id,
        input operand_a_tag,
        input operand_b_tag,
    );

endinterface