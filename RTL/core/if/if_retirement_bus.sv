/* RETIRE INSTRUCTION BUS
 * ->  interface to broadcast a retired instruction
 * ->  originates from ROB and ARR units update their respective commit tables
 * ->  for branch to update pc to data, valid && is_branch && branch_taken
 * ->  LSU snoops retirement bus as store instructions is to be written only on retirement
*/
interface if_retirement_bus;

    logic valid;
    signal_pkg::prf_tag_t prf_tag;
    signal_pkg::rob_address_t rob_id;
    signal_pkg::data_t data;
    logic write_to_reg;
    signal_pkg::arf_address_t dest_address;
    logic is_branch;
    logic branch_taken;

    modport rob (
        output valid, 
        output prf_tag, rob_id,
        output data,
        output write_to_reg, dest_address,
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
        input rob_id
    );

endinterface