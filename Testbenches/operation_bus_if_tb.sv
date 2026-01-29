`timescale 1ns/1ps

module operation_bus_if_tb;

    logic[4:0] dest_ROB_ID;
    chip_select_e ROB_chip_select;
    logic ROB_inputs_valid;

    // inputs from Registers
    logic[31:0] operand_a;
    logic[31:0] operand_b;
    chip_select_e reg_chip_select;
    logic reg_input_valid;

    // inputs from RAT
    operations_e operation;
    chip_select_e RAT_chip_select;
    logic[4:0] src1_ROB_ID;
    logic[4:0] src2_ROB_ID;
    logic src1_ready;
    logic src2_ready;
    logic RAT_op_valid;

    rs_entry_t rs_entry;
    logic[NUM_RS-1:0] rs_full_vec;
    chip_select_e cs;

endmodule