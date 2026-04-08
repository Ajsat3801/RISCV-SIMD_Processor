/*
 * Contains typedefs used to describe instructions
 */

import config_pkg::*;

package instr_pkg;

/* CHIP SELECT
 * chip_select_e[2] indicates scalar or vector
 * chip_select_e[1:0] if its 01 its ALU, if its 11 its LSU
 */ 
    typedef enum logic[2:0] { 
        NONE    = 3'b000,
        CS_SALU = 3'b001, CS_SMULDIV = 3'b010, CS_SLSU = 3'b011,
        CS_VALU = 3'b101,                      CS_VLSU = 3'b111
    } chip_select_e;

/* ALU OPERATIONS
 * operations_e[3] indicates compute or branch
 * operations_e[2:0] is funct3 of instr( instr[14:12])
 */
    typedef enum logic [3:0] { 
        ALU_ADD  = 4'b0000, ALU_SLL  = 4'b0001, ALU_SLT  = 4'b0010, ALU_SLTU = 4'b0011, 
        ALU_XOR  = 4'b0100, ALU_SRL  = 4'b0101, ALU_OR   = 4'b0110, ALU_AND  = 4'b0111,
        ALU_BEQ  = 4'b1000,                     ALU_BNE  = 4'b1010, 
        ALU_BLT  = 4'b1100, ALU_BGE  = 4'b1101, ALU_BLTU = 4'b1110, ALU_BGEU = 4'b1111
    } alu_operations_e;

/* MULDIV Operations
 * operations_e[3] indicates compute or branch
 * operations_e[2:0] is funct3 of instr( instr[14:12])
 */ 
    typedef enum logic [3:0] { 
        MULDIV_MUL = 4'b0000,
        MULDIV_DIV = 4'b0100
    } muldiv_operations_e;

/* LSU Operations
 * operations_e[3] indicate load or store (instr[5] from opcode)
 * operations_e[2:0] is funct3 of instr (instr[14:12]); done for decode simplicity
 */
    typedef enum logic [3:0] {
        LSU_LW = 4'b0010,
        LSU_SW = 4'b1010
    } lsu_operations_e;

/* Vector ALU Operations
 * operations_e[3:0] is LSB 4 bits of funct7 (instr[29:26])
 */
    typedef enum logic [3:0] { 
     
        VALU_ADD = 4'b0000, VALU_SUB = 4'b0010, VALU_RSUB = 4'b0011
        VALU_AND = 4'b1001, VALU_OR  = 4'b1010, VALU_XOR  = 4'b1011
    } valu_operations_e;

/* VECTOR LSU Operations
 * operations_e[3] indicate load or store (instr[5] from opcode)
 * operations_e[2:0] indicate vector size (32 fixed for now)
 */
    typedef enum logic [3:0] { 
     
        VLSU_VSE32 = 4'b1110,
        VLSU_VLE32 = 4'b0110
    } vlsu_operations_e;

    typedef union packed {
        alu_operations_e alu;
        muldiv_operations_e muldiv;
        lsu_operations_e lsu;
        valu_operations_e valu;
        vlsu_operations_e vlsu;
    } operations_e;

    // Aliases for various standard signals

    typedef logic [DATA_SIZE-1:0] data_t;
    typedef logic [REG_ADDR_W-1:0] arf_address_t;
    typedef logic [RS_ADDR_W-1:0]  rs_slot_id_t;
    typedef logic [ROB_ADDR_W-1:0] rob_address_t;
    typedef logic [3:0] [DATA_SIZE-1:0] vec_data_t;
    
/*
 * tag of an instruction used for snoop etc
 * MSB indicates whether scalar or vector
 * Other bits are the address of data at PRF
 * Note: address width of scalar and vector PRF is same
 */
	typedef struct {
     
        logic vector;
        logic [(PRF_ADDR_W-1):0] tag 
    } prf_tag_t;

/*
 * Decoded instruction
 * see previous typedefs for chip_select & operations
 * addresses are of architectural regs, not physical. 
 * 12 bit imm used for i type, loads, stores, b type etc
 * 10 bit extend is used for pre-calculated data
 * pre-calculated data = 32 bits = {src1, src2, imm, extend}
 * pre-calc data is used in lui, auipc, branches, jal
 * control variables:
 *     write_to_reg: whether result is written back
 *     pre_calc: whether output is pre-calculated or not
 *     is_branch: whether there is branch
 *     read_src2: src2 is not read in itype,xui,branches and loads
 *     src1_vector, src2_vector: whether input is scalar or vector
 *     sign: used only for sub instruction, ALU_ADD && sign ==1 => SUB
 */
    typedef struct packed {
     
        logic valid;
        chip_select_e chip_select;
        operations_e operation;
        
        logic arf_address_t dest_address;
        logic arf_address_t src1_address;
        logic arf_address_t src2_address;
        
        logic [11:0] imm;
        logic [9:0] extend;

        logic write_to_reg;
        logic pre_calc; 
        logic is_branch;
        logic read_src2;
        logic src1_vector;
        logic src2_vector;

        logic sign;
        
    } decoded_instr_t;

endpackage