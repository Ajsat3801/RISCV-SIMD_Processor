/*
    type defs for decoded instructions
*/

package instr_desc;
    typedef enum logic {IDLE, BUSY} decode_state_e;
    typedef enum logic[1:0] {NONE, SALU, SMULDIV, SLSU} chip_select_e;
    typedef enum logic {SALU, SMULDIV} wb_state_e;
    typedef enum logic[3:0] { ALU_NOP, ALU_ADD, ALU_SUB, ALU_SLT, 
                                ALU_SLTU, ALU_XOR, ALU_OR, ALU_AND} alu_operations_e;
    typedef enum logic [3:0] {NOP, MUL, DIV} muldiv_ops_e;

    typedef union packed {
        alu_operations_e alu;
        muldiv_ops_e muldiv;
    } operations_e;

    typedef struct packed {
        logic occupied;
        logic ready_to_dispatch;
        operations_e operation;
        logic[4:0] instr_ROB_ID;
        logic[31:0] operand_a;
        logic[31:0] operand_b; 
        logic[4:0] operand_a_tag;
        logic[4:0] operand_b_tag;
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
        logic[4:0] operand_a_addr,
        logic[4:0] operand_b_addr,
        logic[31:0] operand_b_in,
        logic read_operand_a,
        logic read_operand_b,
        logic bypass_operand_b,
        chip_select_e cs_reg,
    } instr_to_reg_t;

    typedef struct packed {
        operations_e operation;
        logic [4:0] rd;
        logic [31:0] operand_a;
        logic [31:0] operand_b;
    } alu_desc_t;

    typedef struct packed {
        logic [4:0] Rob_ID;
        logic [31:0] wb_data;
    } wb_desc_t;

    // typedefs for scalar muldiv, vector alu, vector muldiv remaining
endpackage