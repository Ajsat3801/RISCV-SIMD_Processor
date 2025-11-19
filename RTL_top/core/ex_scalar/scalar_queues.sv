/*
------------------------------------------------------------------
                                NOTE
------------------------------------------------------------------
This is a purely combinational module
The clocks and reset are passed on to the internal FIFOS

*/
`include "typedefs.sv"
import instr_desc::*;

module scalar_queues(
    input logic clk,
    input logic rst,

    // connectivity with decode
    input decode_select_e chip_select,
    input alu_desc_t decoded_op,

    output logic salu_q_ready,
    output logic smuldiv_q_ready,
    output logic slsu_q_ready,

    // connectivity with SALU
    input logic alu_ready,
    output alu_desc_t alu_op,
    output logic alu_input_valid,

    // connectivity with MULDIV
    input logic muldiv_ready,
    output alu_desc_t muldiv_op,
    output logic lsu_input_valid,

    // connectivity with LSU
    input logic lsu_ready,
    output alu_desc_t lsu_op,
    output logic lsu_input_valid
    
);

wire alu_desc_t add_to_alu_q, add_to_lsu_q, add_to_muldiv_q;




endmodule