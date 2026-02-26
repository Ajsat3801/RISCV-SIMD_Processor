interface retirement_bus_if();

logic [4:0] rob_id;
logic [31:0] data;
logic [4:0] dest_address;
logic branch_taken;
logic write_to_reg;
logic valid;

modport ROB(output dest_address, data, branch_taken, write_to_reg, valid);
modport Reg(input dest_address, data, write_to_reg, valid);
modport RAT(input rob_id, dest_address, write_to_reg, valid);
modport Branch(input data, branch_taken, valid);

endinterface