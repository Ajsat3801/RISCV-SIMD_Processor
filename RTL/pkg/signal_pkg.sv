/*
 * Contains typedefs used to describe instructions
 */

package signal_pkg;

    import config_pkg::*;

//  -----------------------------------------------------------------------------------------------
//                                          Chip Select
//  -----------------------------------------------------------------------------------------------
//
//  ->  chip_select_e[1:0] is 01 for ALU, 10 for MULDIV and 11 for LSU

    typedef enum logic[2:0] { 
        NONE    = 3'b000, CS_BRANCH  = 3'b100,
        CS_SALU = 3'b001, CS_MULDIV = 3'b010, CS_SLSU = 3'b011,
        CS_VALU = 3'b101,                     CS_VLSU = 3'b111
    } chip_select_e;

//  -----------------------------------------------------------------------------------------------
//                                         Operations Enum
//  -----------------------------------------------------------------------------------------------

//  ------------------  R-TYPE OPERATIONS (Scalar ALU, Scalar MULDIV and Branch)  -----------------

//  ->  Internal decoding format used by ex units
//  ->  operations_e[3] indicates compute or branch (except for SUB)
//  ->  operations_e[2:0] is funct3 of instr (instr[14:12])
//  ->  Note: use 4'1101 for SRA if implemented in the future

    typedef enum logic [3:0] { 
        ALU_ADD  = 4'b0000, ALU_SLL  = 4'b0001, ALU_SLT  = 4'b0010, ALU_SLTU = 4'b0011, 
        ALU_XOR  = 4'b0100, ALU_SRL  = 4'b0101, ALU_OR   = 4'b0110, ALU_AND  = 4'b0111,
        ALU_SUB  = 4'b1000 
    } alu_operations_e;

    typedef enum logic [3:0] {
        BR_BEQ  = 4'b1000,                    BR_BNE  = 4'b1001, 
        BR_BLT  = 4'b1100, BR_BGE  = 4'b1101, BR_BLTU = 4'b1110, BR_BGEU = 4'b1111
    } branch_operations_e;

    typedef enum logic [3:0] { 
        MULDIV_MUL = 4'b0000, MULDIV_MULH = 4'b0001, MULDIV_MULHSU = 4'b0010, MULDIV_MULHU = 4'b0011,
        MULDIV_DIV = 4'b0100, MULDIV_DIVU = 4'b0101, MULDIV_REM = 4'b0110, MULDIV_REMU = 4'b0111
    } muldiv_operations_e;

//  -------------------------------------  LSU Operations  ----------------------------------------

//  ->  operations_e[3] indicate load or store (instr[5] from opcode)
//  ->  operations_e[2:0] is funct3 of instr (instr[14:12]); done for decode simplicity

    typedef enum logic [3:0] {
        LSU_LB  = 4'b0000, LSU_LH  = 4'b0001, LSU_LW = 4'b0010, 
        LSU_LBU = 4'b0100, LSU_LHU = 4'b0101,
        LSU_SB  = 4'b1000, LSU_SH  = 4'b1001, LSU_SW = 4'b1010
    } lsu_operations_e;

//  -----------------------------------  Vector ALU Operations  -----------------------------------

//  ->  operations_e[3:0] is LSB 4 bits of funct7 (instr[29:26])

    typedef enum logic [3:0] { 
        VALU_ADD = 4'b0000, VALU_SUB = 4'b0010, VALU_RSUB = 4'b0011,
        VALU_AND = 4'b1001, VALU_OR  = 4'b1010, VALU_XOR  = 4'b1011
    } valu_operations_e;

//  -----------------------------------------------------------------------------------------------
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
        branch_operations_e br;
        muldiv_operations_e muldiv;
        lsu_operations_e lsu;
        valu_operations_e valu;
        vlsu_operations_e vlsu;
    } operations_e;

//  -----------------------------------------------------------------------------------------------
//                                          Signals 
//  -----------------------------------------------------------------------------------------------
    localparam int unsigned PRF_ADDR_W = $clog2(PRF_DEPTH);
    localparam int unsigned REG_ADDR_W = $clog2(ARCH_REG_DEPTH);
    localparam int unsigned ROB_ADDR_W = $clog2(ROB_DEPTH);

    // Aliases for various standard signals

    typedef logic [config_pkg::DATA_W-1:0] data_t;
    typedef logic [VECTOR_LEN-1:0] [config_pkg::DATA_W-1:0] vector_data_t;

    typedef logic [REG_ADDR_W-1:0] arf_address_t;
    typedef logic [RS_ADDR_W-1:0]  rs_slot_id_t;
    
    typedef logic [(PRF_ADDR_W-1):0] prf_address_t;
    typedef logic [(PHY_MEM_ADDR_W)-1:0] mem_address_t;
    typedef logic [(PC_W)-1:0] pc_t;
    
/*
 * tag of an instruction used for snoop etc
 * MSB indicates whether scalar or vector
 * Other bits are the address of data at PRF
 * Note: address width of scalar and vector PRF is same
 */
	
    typedef struct packed { logic vector; prf_address_t tag; } prf_tag_t;
    typedef struct packed { logic epoch; logic [ROB_ADDR_W-1:0] address; } rob_address_t;

//  -----------------------------------------------------------------------------------------------
//                                    Wrapper Functions/Tasks
//  -----------------------------------------------------------------------------------------------

    function automatic data_t extract_subword (
        input data_t w,
        input mem_address_t addr,
        input operations_e o
    );
        //  Function to extract the subword from a load instruction based on the word, address and
        //  load operation

        logic [7:0] byte_sel;
        logic [15:0] hword_sel;

        byte_sel = w[8*addr[1:0] +: 8]; // byte from word slected by addr[1:0]
        hword_sel = w[16*addr[1] +: 16]; // halfword from word selected by addr[1]

        case (o.lsu)
            LSU_LB:  return {{24{byte_sel[7]}}, byte_sel};
            LSU_LH:  return {{16{hword_sel[15]}}, hword_sel};
            LSU_LBU: return {24'b0, byte_sel};
            LSU_LHU: return {16'b0, hword_sel};
            default: return w;
        endcase
    endfunction

endpackage