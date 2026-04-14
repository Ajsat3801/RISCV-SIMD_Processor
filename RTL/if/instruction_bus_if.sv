
interface instruction_bus_if;

    logic valid;
    instr_pkg::decoded_instr_t instr;
    instr_pkg::rs_slot_id_t rs_slot_id;

    modport queue (
        output valid,
        output instr,
        output rs_slot_id
    );

    modport arr (
        input valid,
        input instr,
        input rs_slot_id
    );

endinterface