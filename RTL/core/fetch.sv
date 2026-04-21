
module fetch(
    input logic clk_i,
    input logic reset_ni,

    retirement_bus_if.branch branching_i,

    output instr_pkg::raw_instr_t raw_instr_o,
    output instr_pkg::pc_t pc_to_imem_o,
    output instr_pkg::pc_t pc_to_decoder_o
);

/*
 * FETCH MODULE functions
 * 1) Communication with IMEM
 * 2) Maintain PC
 * 3) Handle Branching
 */

endmodule