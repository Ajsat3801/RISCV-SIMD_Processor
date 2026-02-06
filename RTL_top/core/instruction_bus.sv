interface instruction_bus_if();

decoded_instr_t queue_instr;
logic[2:0]  RS_slot_ID;

operations_e operation;
logic[4:0] src1_address, src2_address, dest_address;
chip_select_e chip_select;

assign operation = queue_instr.operation;
assign src1_address = queue_instr.src1_address;
assign src2_address = queue_instr.src2_address;
assign dest_address = queue_instr.dest_address;
assign chip_select = queue_instr.chip_select;

modport Instruction_Queue (
    output queue_instr, RS_slot_ID
);

modport RAT (
    input operation, src1_address, src2_address, chip_select, RS_slot_ID
);

modport ROB (
    input dest_address, chip_select
);

modport Registers (
    input src1_address, src2_address, chip_select
);

endinterface