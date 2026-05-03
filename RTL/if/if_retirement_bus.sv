/* RETIRE INSTRUCTION BUS
 * ->  interface to broadcast a retired instruction
 * ->  originates from ROB and ARR units update their respective commit tables
 * ->  for branch to update pc to data, valid && is_branch && branch_taken
 * ->  LSU snoops retirement bus as store instructions is to be written only on retirement
*/
interface if_retirement_bus;

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

    modport arr (
        input valid, 
        input write_to_reg, prf_tag,
        input dest_address
    );

    modport branch (
        input valid,
        input is_branch, branch_taken,
        input data
    );

    modport lsu (
        input valid,
        input prf_tag
    );

endinterface