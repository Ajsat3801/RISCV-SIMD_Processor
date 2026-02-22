interface retirement_bus_if();
    
logic[4:0] ROB_id;
logic[31:0] data;
logic[4:0] rd;
logic branch, valid, instr_valid, taken, branch_valid;

assign instr_valid = ~branch && valid;
assign branch_valid = branch && valid;
assign taken = rd[0];

modport ROB(output ROB_id, rd, data, branch, valid);
modport Reg(input rd, data, instr_valid);
modport RAT(input ROB_id, rd, instr_valid);
modport Branch(input data, taken, branch_valid);

endinterface