/*
    type defs for decoded instructions
*/

package instr_desc;
    typedef enum logic {IDLE, BUSY} decode_state_e;
    typedef enum logic[1:0] {NONE, SALU, SMULDIV, SLSU} chip_select_e;
    typedef enum logic {SALU, SMULDIV} wb_state_e;
    typedef enum logic[5:0] { NOP, ADD, SUB, SLT, SLTU, XOR, OR, AND} operations_e;

    typedef struct packed {
        logic occupied;
        logic ready_to_dispatch;
        logic[5:0] operation;
        logic[5:0] instr_ROB_ID;
        logic[31:0] operand_a; // stores ROB ID of a if operand A not ready
        logic[31:0] operand_b; // likewise for operand B
        logic operand_a_ready;
        logic operand_b_ready;

    } rs_entry_t;

    typedef struct packed {
        operations_e operation;
        logic [31:0] operand_a;
        logic [31:0] operand_b;
        logic [4:0] Rob_ID;
    } rs_dispatch_t;

    typedef struct packed {
        operations_e operation;
        logic [4:0] rd;
        logic [31:0] operand_a;
        logic [31:0] operand_b;
    } alu_desc_t;

    typedef struct packed {
        logic [4:0] rd;
        logic [31:0] wb_data;
    } wb_desc_t;

    // typedefs for scalar muldiv, vector alu, vector muldiv remaining
endpackage