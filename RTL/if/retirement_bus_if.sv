//TO BE UPDATED LATER

interface retirement_bus_if;

    logic valid;
    logic write_to_reg;
    instr_pkg::arf_address_t dest_address;
    logic is_branch;
    logic branch_taken;
    instr_pkg::prf_tag_t prf_tag;
    instr_pkg::data_t data;

    modport rob (
        output valid, 
        output write_to_reg, prf_tag,
        output dest_address, data, 
        output is_branch, branch_taken
    );

    modport prf (
        input valid,
        input write_to_reg, prf_tag
    );

    modport arr (
        input valid, 
        input write_to_reg, prf_tag,
        input dest_address
    );

    modport branch (
        input valid,
        input is_branch, branch_taken
    );

endinterface