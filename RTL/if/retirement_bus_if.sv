//TO BE UPDATED LATER

interface retirement_bus_if;

    logic valid;
    logic write_to_reg;
    instr_pkg::arf_address_t dest_address;
    logic is_branch;
    logic branch_taken;
    instr_pkg::prf_tag_t prf_tag;

    modport rob     (output valid, write_to_reg, 
    dest_address, is_branch, branch_taken, prf_tag);
    modport prf     (input  valid, write_to_reg, prf_tag);
    modport rat     (input  valid, write_to_reg, dest_address, prf_tag);
    modport branch  (input  valid, is_branch, branch_taken);

endinterface