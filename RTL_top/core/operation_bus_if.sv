interface operation_bus_if #(parameter NUM_RS = 2)();

// ROB signals
logic[4:0] dest_ROB_ID;
chip_select_e ROB_chip_select;
logic ROB_inputs_valid;

// inputs from Registers
logic[31:0] operand_a_in;
logic[31:0] operand_b_in;
chip_select_e reg_chip_select;
logic reg_input_valid;

// inputs from RAT
operations_e operation;
chip_select_e RAT_chip_select;
logic[4:0] src1_ROB_ID;
logic[4:0] src2_ROB_ID;
logic src1_ready;
logic src2_ready;
logic RAT_inputs_valid;

rs_entry_t rs_entry;
logic[NUM_RS-1:0] rs_full_vec;
chip_select_e cs;

/*
    combinationally combine the data into rs_entry format
    rs_entry.occupied is treated like a valid variable here
*/
assign rs_entry.occupied = (ROB_chip_select == RAT_chip_select) && (RAT_chip_select == reg_chip_select) && reg_input_valid && ROB_inputs_valid && RAT_inputs_valid;
assign rs_entry.ready_to_dispatch = src1_ready && src2_ready;
assign rs_entry.operation = operation;
assign rs_entry.instr_ROB_ID = dest_ROB_ID;
assign rs_entry.operand_a = operand_a_in;
assign rs_entry.operand_b = operand_b_in;
assign rs_entry.operand_a_tag = src1_ROB_ID;
assign rs_entry.operand_b_tag = src2_ROB_ID;
assign rs_entry.operand_a_ready = src1_ready;
assign rs_entry.operand_b_ready = src2_ready;
assign cs = RAT_chip_select;

modport RAT (
    input rs_full_vec,
    output operation, RAT_chip_select, src1_ROB_ID, src2_ROB_ID, src1_ready, src2_ready, RAT_inputs_valid
);

modport ROB (
    input rs_full_vec,
    output dest_ROB_ID, ROB_chip_select, ROB_inputs_valid
);

modport Registers(
    input rs_full_vec,
    output operand_a_in, operand_b_in, reg_chip_select, reg_input_valid
    );

modport RS (
    input cs, rs_entry
);

modport instr_queue (
    input rs_full_vec
)

endinterface