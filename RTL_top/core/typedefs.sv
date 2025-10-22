/*
    type defs for decoded instructions
*/

package instr_desc;

    typedef enum logic[3:0] { NOP, ADD, SUB,
    SLT, SLTU, XOR, OR, AND; 
    } alu_ops_t;

    typedef struct packed {
        alu_ops_t operation;
        logic [4:0] rd;
        logic [31:0] operand_a;
        logic [31:0] operand_b;
        logic use_imm;
    } alu_desc_t;

    // typedefs for scalar muldiv, vector alu, vector muldiv remaining
endpackage