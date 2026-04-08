
module fetch(
    input logic clk_i,
    input logic reset_ni,

    retirement_bus_if.branch branching_i;

    output raw_instr_o;
    output pc_to_imem_o;
    output pc_to_decoder_o;
);

/*
 * FETCH MODULE functions
 * 1) Communication with IMEM
 * 2) Maintain PC
 * 3) Handle Branching
 */

endmodule