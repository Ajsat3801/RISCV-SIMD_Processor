import config_pkg::*;
import instr_pkg::*;

package signal_pkg;

localparam NUM_RS = 3;
localparam RS_LEN = 8;
localparam RS_ADDR_LEN = $clog2(RS_LEN);

typedef struct packed {
    logic valid;
    
    logic [ROB_ADDR_W-1:0] rob_id;

    logic [31:0] operand_a;
    logic [31:0] operand_b;

    operations_e operation;
    logic sign;

} rs_to_alu_signal_t;

typedef struct packed {
    logic [REG_ADDR_W-1:0] dest_address;
    logic [ROB_ADDR_W-1:0] rob_id;
    logic valid;
} rob_to_rat_signal_t;

typedef struct packed {
    logic valid;
    logic [ROB_ADDR_W-1:0] rob_id;
    logic [31:0] data;
} ex_to_wb_signal_t;

typedef struct packed {
    logic valid;
    logic [ROB_ADDR_W-1:0] rob_id;
    logic branch_taken;
} alu_to_wb_branch_signal_t;

typedef struct packed {
    logic valid;
    logic rob_id;
    logic branch_taken;

} wb_to_rob_branch_t;

typedef struct packed {
    logic valid;
    logic write_to_reg;
    logic [REG_ADDR_W-1:0] dest_address;

    logic [REG_ADDR_W-1:0] src1_address;
    logic [REG_ADDR_W-1:0] src2_address;
    logic [11:0] imm;
    logic [9:0] extend;
    logic precalc // 1 if the data in ROB doenst need to be written
    logic ready; // 1 if JAL, LUI or AUIPC, derived from operation
    logic is_branch;
} queue_to_rob_signal_t;

typedef struct packed {
    logic valid;

    logic [REG_ADDR_W-1:0] src1_address;
    logic [REG_ADDR_W-1:0] src2_address;
    logic [11:0] imm; // current focus only on i type instructions, 

    logic read_src2;
} queue_to_reg_signal_t;

typedef struct packed {
    
    logic valid; 
    logic [REG_ADDR_W-1:0] src1_address;
    logic [REG_ADDR_W-1:0] src2_address;
    
    operations_e operation;
    chip_select_e chip_select;
    logic sign;
    
    logic [RS_ADDR_LEN-1:0] rs_slot_id;
} queue_to_rat_signal_t; // only performs read, write comes from rob_to_rat_signal

endpackage