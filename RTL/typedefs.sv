/*
    type defs for decoded instructions
*/

package instr_desc;
    typedef enum logic {IDLE, BUSY} decode_state_e;
    typedef enum logic[1:0] {NONE, CS_SALU, CS_SMULDIV, CS_SLSU} chip_select_e;
    typedef enum logic {SALU, SMULDIV} wb_state_e;
    typedef enum logic[3:0] {   4'b0000 = ALU_ADD, 4'b0010 = ALU_SLT, 4'b0011 = ALU_SLTU, 
                                4'b0100 = ALU_XOR, 4'b0110 = ALU_OR,  4'b0111 = ALU_AND } alu_operations_e;
    typedef enum logic [3:0] {NOP, MUL, DIV} muldiv_ops_e;

    typedef union packed {
        alu_operations_e alu;
        muldiv_ops_e muldiv;
    } operations_e;

    typedef struct packed {
        operations_e operation;
        logic[4:0] src1_address;
        logic[4:0] src2_address;
        logic[4:0] dest_address;
        logic read_src2;
        logic branch;
        logic[31:0] target_pc;
        chip_select_e chip_select;
    } decoded_instr_t;

    typedef struct packed {
        logic occupied;
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
        logic[31:0] operand_a;
        logic[31:0] operand_b;
        logic sign;
        logic [4:0] ROB_id;
    } rs_dispatch_t;

    typedef struct packed {
        logic[4:0] operand_a_addr;
        logic[4:0] operand_b_addr;
        logic[31:0] operand_b_in;
        logic read_operand_a;
        logic read_operand_b;
        logic bypass_operand_b;
        chip_select_e cs_reg;
    } instr_to_reg_t;

    typedef struct packed {
        operations_e operation;
        logic [4:0] rd;
        logic [31:0] operand_a;
        logic [31:0] operand_b;
    } alu_desc_t;

    typedef struct packed {
        logic [4:0] ROB_id;
        logic [31:0] wb_data;
    } wb_desc_t;

    typedef struct packed {
        logic[4:0] rd;
        logic[4:0] ROB_id;
        logic valid;
    } rat_rob_comms_t;

    typedef struct packed {
        logic[4:0] ROB_id;
        logic in_use; // if in use is 1, then value is ROB, else its register
    } RAT_entry_t;

    // typedefs for scalar muldiv, vector alu, vector muldiv remaining
endpackage