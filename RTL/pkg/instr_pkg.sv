package instr_pkg;

localparam REG_W = 32;
localparam REG_ADDR_W = $clog2(REG_W); // 5 in case of current situation

typedef enum logic[1:0] {NONE, CS_SALU, CS_SMULDIV, CS_SLSU} chip_select_e;

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

/*
Instruction Type

ROB decoding:
valid && CS == 0 -> you have branch, jump or lui/auipc -> store 32 bits
Write = 1 -> value at data goes to register
branch = 1 -> value at data is new PC

ex: JAL -> 011, BEQ (taken) -> 101, BEQ (not taken) -> 100

Data is split into 4 parts, 
Data[31:27] => src1_address
Data[26:22] => src2_address
Data[21:10] => imm
Data[9:0] => extend

*/


typedef struct packed {
    
    logic valid;
    chip_select_e chip_select;
    operations_e operation;
    
    logic [REG_ADDR_W-1:0] dest_address;
    logic [REG_ADDR_W-1:0] src1_address;
    logic [REG_ADDR_W-1:0] src2_address;
    
    logic [11:0] imm;
    logic [9:0] extend;

    logic write_to_reg;
    logic pre_calc; 
    logic is_branch;
    logic read_src2;

    logic sign; // used for sub etc
    
} decoded_instr_t;

endpackage

/*
branch
*/