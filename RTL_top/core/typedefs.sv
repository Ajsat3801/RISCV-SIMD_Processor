/*
    type defs for decoded instructions
*/

package instr_desc;
    enum logic {IDLE, BUSY} decode_state_e;

    typedef enum logic[3:0] { NOP, ADD, SUB,
    SLT, SLTU, XOR, OR, AND; 
    } alu_ops_e;

    typedef struct packed {
        alu_ops_e operation;
        logic [4:0] rd;
        logic [31:0] operand_a;
        logic [31:0] operand_b;
        logic use_imm;
    } alu_desc_t;

    // typedefs for scalar muldiv, vector alu, vector muldiv remaining
endpackage