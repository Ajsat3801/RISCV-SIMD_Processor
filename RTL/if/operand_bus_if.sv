/*
    combinationally combine the data into rs_entry format
    rs_entry.occupied is treated like a valid variable here

    There is potential to make this into a sequential circuit if needed
*/

interface operand_bus_if #(parameter type T = instr_pkg::data_t);

    instr_pkg::chip_select_e chip_select;
    instr_pkg::rs_slot_id_t rs_slot;
    logic prf_valid;
    logic rob_valid;

    instr_pkg::prf_tag_t prf_tag;
    instr_pkg::rob_address_t rob_id;
    T operand_a;
    T operand_b;
    instr_pkg::operations_e operation;
    instr_pkg::prf_tag_t operand_a_tag;
    instr_pkg::prf_tag_t operand_b_tag;
    logic operand_a_ready;
    logic operand_b_ready;
    logic a_is_vector, b_is_vector;
    
    // connections from RS
    storage_pkg::sc_rs_entry_t rs_entry;

    assign rs_entry.occupied  = prf_valid && rob_valid;
    assign rs_entry.prf_tag   = prf_tag;
    assign rs_entry.rob_id    = rob_id;
    assign rs_entry.operand_a = operand_a;
    assign rs_entry.operand_b = operand_b;
    assign rs_entry.operation = operation;
    assign rs_entry.operand_a_tag   = operand_a_tag;
    assign rs_entry.operand_b_tag   = operand_b_tag;
    assign rs_entry.operand_a_ready = operand_a_ready;
    assign rs_entry.operand_b_ready = operand_b_ready;

    modport prf (
        output prf_valid,
        output chip_select, rs_slot, operation,
        output rob_id, prf_tag, 
        output operand_a, operand_b, 
        output operand_a_tag, operand_b_tag,
        output operand_a_ready, operand_b_ready,
        output a_is_vector, b_is_vector
    );
    modport rob (
        output rob_valid,
        output rob_id
    );

    modport rs (
        input chip_select,
        input rs_slot,
        input rs_entry,
        input a_is_vector,
        input b_is_vector
    );

endinterface