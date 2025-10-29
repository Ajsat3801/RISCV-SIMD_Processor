/*  
Writeback for Scalar registers

*/


module Writeback_scalar(
    input logic clk;

    // FROM SCALAR ALU
    input wb_desc_t scalar_alu_res,
    input logic salu_result_valid,
    output logic wb_salu_ready,

    // FROM SCALAR MULDIV

    // FROM SCALAR LSU

    // TO SCALAR REGISTER
    output logic[4:0] rd,
    output logic[31:0] wb_data,
    output logic write_enable,

    // TO BUSYBOARD
    output logic[4:0] rd,
    output logic reset_busy
);

endmodule