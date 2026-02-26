/*
    type defs for decoded instructions
*/

package instr_desc;

    localparam REG_W = 32;
    localparam ROB_W = 32;
    localparam REG_ADDR_W = $clog2(REG_W);
    localparam ROB_ADDR_W = $clog2(ROB_W);

    typedef enum logic {IDLE, BUSY} decode_state_e;
    typedef enum logic[1:0] {NONE, CS_SALU, CS_SMULDIV, CS_SLSU} chip_select_e;
    typedef enum logic {SALU, SMULDIV} wb_state_e;
    typedef enum logic [3:0] {  ALU_ADD  = 4'b0000, ALU_SLT  = 4'b0010, ALU_SLTU = 4'b0011, 
                                ALU_XOR  = 4'b0100, ALU_OR   = 4'b0110, ALU_AND  = 4'b0111,
                                ALU_BEQ  = 4'b1000, ALU_BNE  = 4'b1010, ALU_BLT  = 4'b1100, 
                                ALU_BGE  = 4'b1101, ALU_BLTU = 4'b1110, ALU_BGEU = 4'b1111
                                } alu_operations_e;
    typedef enum logic [3:0] { MULDIV_MUL = 4'b0000, MULDIV_DIV = 4'b0100} muldiv_ops_e;

    typedef union packed {
        alu_operations_e alu;
        muldiv_ops_e muldiv;
    } operations_e;

    typedef struct packed {
        operations_e operation;
        logic [REG_ADDR_W:0] src1_address;
        logic [REG_ADDR_W:0] src2_address;
        logic [REG_ADDR_W:0] dest_address;
        logic read_src2;
        logic branch;
        logic [31:0] target_pc;
        chip_select_e chip_select;
    } decoded_instr_t;

    typedef struct packed {
        logic occupied;
        logic sign;
        logic [ROB_ADDR_W:0] rob_id;
        operations_e operation;
        logic [31:0] operand_a;
        logic [31:0] operand_b; 

        logic [ROB_ADDR_W:0] operand_a_tag;
        logic [ROB_ADDR_W:0] operand_b_tag;
        logic operand_a_ready;
        logic operand_b_ready;
    } rs_entry_t;

    typedef struct packed {
        logic valid;
        logic sign;
        logic [ROB_ADDR_W:0] rob_id;
        operations_e operation;
        logic [31:0] operand_a;
        logic [31:0] operand_b;
    } rs_dispatch_t;

    typedef struct packed {
        logic [REG_ADDR_W:0] dest_address;
        logic [ROB_ADDR_W:0] rob_id;
        logic valid;
    } rat_rob_comms_t;

    typedef struct packed {
        logic [ROB_ADDR_W:0] rob_id;
        logic in_use; // if in use is 1, then value is ROB, else its register
    } RAT_entry_t;

    typedef struct packed {
        logic valid;
        logic [REG_ADDR_W:0] dest_address;
        logic branch;
        logic [31:0] target_pc;
    } IQ_ROB_t; 

    typedef struct packed {
        logic valid;
        logic [REG_ADDR_W:0] src1_address;
        logic [REG_ADDR_W:0] src2_address;
        logic [11:0] imm; // current focus only on i type instructions, 
        logic read_operand_a;
        logic read_operand_b;
        logic imm_used;
    } instr_to_reg_t;



    // typedefs for scalar muldiv, vector alu, vector muldiv remaining
endpackage