/*
    Queue for ALU ops

*/

module RTL_scalar_alu_queue #(
    parameter QUEUE_LENGTH = 4;
) (
    input logic illegal_instr,
    input alu_desc_t salu_pending_op,
    input logic queue_valid,
    output queue_full,
    output alu_desc_t salu_op_ex,
    output logic salu_op_valid
);

// If ALU is empty you send the data
// IF 


    
endmodule