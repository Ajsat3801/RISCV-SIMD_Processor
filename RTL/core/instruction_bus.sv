/*note unused*/

interface instruction_bus_if();

decoded_instr_t alloc_instr;
logic[2:0]  RS_slot_ID;
logic valid;

operations_e operation;
logic[4:0] src1_address, src2_address, dest_address;
chip_select_e chip_select;
logic read_src2, branch;
logic[31:0] target_pc;

assign operation = alloc_instr.operation;
assign src1_address = alloc_instr.src1_address;
assign src2_address = alloc_instr.src2_address;
assign dest_address = alloc_instr.dest_address;
assign read_src2 = alloc_instr.read_src2;
assign target_pc = alloc_instr.target_pc;
assign chip_select = alloc_instr.chip_select;
assign branch = alloc_instr.branch;

modport Instruction_Queue (
    output alloc_instr, 
    RS_slot_ID, valid
);

modport RAT (
    input valid, operation, src1_address, 
    src2_address, chip_select, 
    RS_slot_ID
);

modport ROB (
    input valid, dest_address, branch, target_pc
);

modport Registers (
    input valid, src1_address, src2_address, read_src2
);

endinterface