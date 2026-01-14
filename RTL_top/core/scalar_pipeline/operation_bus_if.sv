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

/*
    operation valid:
    checks if all 3 inputs are valid and have the same chip select
*/
logic ops_valid;
assign ops_valid = (ROB_chip_select == RAT_chip_select) && (RAT_chip_select == register_chip_select) && register_input_valid && ROB_inputs_valid && RAT_inputs_valid;

assign operand_a = (src1_ready) ? operand_a_in : {27'b0,src1_ROB_ID};
assign operand_b = (src2_ready) ? operand_b_in : {27'b0,src2_ROB_ID};
assign operand_a_ready = src1_ready;
assign operand_b_ready = src2_ready;
assign instr_ROB_ID = dest_ROB_ID;

modport RAT (
    output operation, RAT_chip_select, src1_ROB_ID, src2_ROB_ID, src1_ready, src2_ready, RAT_inputs_valid
);

modport ROB (
    output dest_ROB_ID, ROB_chip_select, ROB_inputs_valid
);

modport RAT(
    output operation, RAT_chip_select, src1_ROB_ID, src2_ROB_ID, src1_ready, src2_ready, RAT_inputs_valid
);

modport RS (
input ops_valid, cs, operation, instr_ROB_ID, operand_a, operand_b, operand_a_ready, operand_b_ready
);


endinterface