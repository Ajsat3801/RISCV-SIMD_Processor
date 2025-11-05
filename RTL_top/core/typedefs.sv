/*
    type defs for decoded instructions
*/

package instr_desc;
    typedef enum logic {IDLE, BUSY} decode_state_e;
    typedef enum logic {SALU, SMULDIV} wb_state_e;
    typedef enum logic[2:0] { NOP, ADD, SUB, SLT, SLTU, XOR, OR, AND} alu_ops_e;

    typedef struct packed {
        alu_ops_e operation;
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