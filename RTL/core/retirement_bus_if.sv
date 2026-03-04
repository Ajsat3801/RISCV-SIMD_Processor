interface retirement_bus_if();

logic valid;
logic write_to_reg;
logic [4:0] dest_address;
logic [31:0] data;
logic is_branch;
logic branch_taken;
logic [4:0] rob_id;

modport rob     (output valid, write_to_reg, dest_address, data, is_branch, branch_taken, rob_id);
modport reg     (input  valid, write_to_reg, dest_address, data);
modport rat     (input  valid, write_to_reg, dest_address, rob_id);
modport branch  (input  valid, is_branch, branch_taken, data);

endinterface