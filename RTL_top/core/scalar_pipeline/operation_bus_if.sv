interface operation_bus_if(input logic clk);

// ROB signals
logic[4:0] dest_ROB_ID;
chip_select_e ROB_chip_select;
logic ROB_inputs_valid;

// inputs from Registers
logic[31:0] operand_a_in;
logic[31:0] operand_b_in;
chip_select_e register_chip_select;
logic register_input_valid;

// inputs from RAT
operations_e operation;
chip_select_e RAT_chip_select;
logic[4:0] src1_ROB_ID;
logic[4:0] src2_ROB_ID;
logic src1_ready;
logic src2_ready;
logic RAT_inputs_valid;

rs_entry_t rs_entry;
logic rs_full;

/*
    combinationally combine the data into rs_entry format
    rs_entry.occupied is treated like a valid variable here
*/
assign rs_entry.occupied = (ROB_chip_select == RAT_chip_select) && (RAT_chip_select == register_chip_select) && register_input_valid && ROB_inputs_valid && RAT_inputs_valid;
assign rs_entry.ready_to_dispatch = src1_ready && src2_ready;
assign rs_entry.operation = operation;
assign rs_entry.instr_ROB_ID = dest_ROB_ID;
assign rs_entry.operand_a = (src1_ready) ? operand_a_in : {27'b0,src1_ROB_ID};
assign rs_entry.operand_b = (src2_ready) ? operand_b_in : {27'b0,src2_ROB_ID};
assign rs_entry.operand_a_ready = src1_ready;
assign rs_entry.operand_b_ready = src2_ready;


modport RAT (
    input rs_full,
    output operation, RAT_chip_select, src1_ROB_ID, src2_ROB_ID, src1_ready, src2_ready, RAT_inputs_valid
);

modport ROB (
    input rs_full,
    output dest_ROB_ID, ROB_chip_select, ROB_inputs_valid
);

modport RAT(
    input rs_full,
    output operation, RAT_chip_select, src1_ROB_ID, src2_ROB_ID, src1_ready, src2_ready, RAT_inputs_valid
);

modport RS (
input cs, rs_entry, output rs_full
);


endinterface