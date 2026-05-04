/* ALLOCATED INSTRUCTION BUS
 * ->  Interface between ARR units, reorder buffer and physical registers
 * ->  2 instances created, one for scalar and one for vector
 * ->  (Future scope: potential to reduce the number of fields sent inside instr)
*/

interface if_alloc_bus;
    
    logic valid;
    signal_pkg::rs_slot_id_t rs_slot;
    packet_pkg::decoded_instr_t instr;
    signal_pkg::prf_tag_t prf_tag;
    signal_pkg::prf_tag_t operand_a_tag;
    signal_pkg::prf_tag_t operand_b_tag;
    logic a_is_vector, b_is_vector;

    modport arr (
        output valid,
        output instr,
        output rs_slot, prf_tag,
        output operand_a_tag, operand_b_tag,
        output a_is_vector, b_is_vector
    );

    modport rob (
        input valid,
        input instr,
        input prf_tag
    );

    modport prf (
        input valid,
        input instr,
        input rs_slot, prf_tag,
        input operand_a_tag, operand_b_tag,
        input a_is_vector, b_is_vector
    );

endinterface