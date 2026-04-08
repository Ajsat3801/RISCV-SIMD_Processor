
interface instruction_bus_if;

    logic valid;
    instr_pkg::decoded_instr_t instr;
    instr_pkg::rs_slot_id_t rs_slot_id;

    modport queue (output valid, instr, rs_slot_id);
    modport rat   (input  valid, instr, rs_slot_id);
    modport rob   (input  valid, instr)

endinterface