/*
    combinationally combine the data into rs_entry format
    rs_entry.occupied is treated like a valid variable here

    There is potential to make this into a sequential circuit if needed
*/


interface operand_bus_if #(parameter NUM_RS = 2, parameter RS_SIZE=8)();

// ROB signals
logic[4:0] rob_id;
logic rob_input_valid;

// inputs from Registers
logic[31:0] operand_a;
logic[31:0] operand_b;
logic reg_input_valid;

// inputs from RAT
instr_pkg::operations_e operation; // 4 bits
instr_pkg::chip_select_e chip_select;
logic[4:0] src1_rob_id;
logic[4:0] src2_rob_id;
logic src1_ready;
logic src2_ready;
logic sign;
logic rat_input_valid;
logic[$clog2(RS_SIZE)-1:0] rs_slot;

// connections from RS
storage_pkg::rs_entry_t rs_entry;

// control signals
assign rs_entry.occupied = reg_input_valid && rob_input_valid && rat_input_valid;
assign rs_entry.ready_to_dispatch = src1_ready && src2_ready;
assign rs_entry.operand_a_ready = src1_ready;
assign rs_entry.operand_b_ready = src2_ready;

// data signals
assign rs_entry.operation = operation;
assign rs_entry.instr_rob_id = rob_id;
assign rs_entry.operand_a = operand_a;
assign rs_entry.operand_b = operand_b;
assign rs_entry.operand_a_tag = src1_rob_id;
assign rs_entry.operand_b_tag = src2_rob_id;
assign rs_entry.sign = sign;


modport rat (
    output operation, chip_select, sign, src1_rob_id, src2_rob_id, src1_ready, src2_ready, rat_input_valid, rs_slot;
);

modport rob (
    output rob_id, rob_input_valid
);

modport registers(
    output operand_a, operand_b, reg_input_valid
    );

modport rs (
    input chip_select, rs_slot, rs_entry
);

endinterface