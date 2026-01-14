/*
Busyboard to prevent hazards

*/

module Register_Allocation_Table #() (
    input logic clk,
    input logic reset_n,

    // inputs from ROB (decode stage)


    // inputs from ROB (writeback stage)

    // inputs from instruction queue

    // input from reservation stations
    input logic rs_full_to_registers,

    // outputs to reservation stations
    output operations_e operation,
    output RAT_chip_select,
    output logic[4:0] src1_ROB_ID,
    output logic[4:0] src2_ROB_ID,
    output logic src1_ready,
    output logic src2_ready,
    output logic RAT_inputs_valid,


    
    
);

endmodule