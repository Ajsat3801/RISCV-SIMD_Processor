
package packet_pkg;

// ------------------------------------------------------------------------------------------------
//                                  DECODED INSTRUCTION PACKET
// ------------------------------------------------------------------------------------------------ 
/* 
 * -> see signal_pkg typedefs for chip_select & operations definitions
 * -> addresses are of architectural regs, not physical. 
 * -> 12 bit imm used for i type, loads, stores, b type etc
 * -> 10 bit extend is used for pre-calculated data
 * -> pre-calculated data = 32 bits = {src1, src2, imm, extend}
 * -> pre-calc data is used in lui, auipc, branches, jal
 * -> control variables:
 *      -> write_to_reg: whether result is written back
 *      -> pre_calc: whether output is pre-calculated or not
 *      -> is_branch: whether there is branch
 *      -> read_src2: src2 is not read in itype,xui,branches and loads
 *      -> src1_vector, src2_vector: whether input is scalar or vector
 */

    typedef struct packed {
     
        logic valid;
        signal_pkg::chip_select_e chip_select;
        signal_pkg::operations_e operation;
        
        signal_pkg::arf_address_t dest_address;
        signal_pkg::arf_address_t src1_address;
        signal_pkg::arf_address_t src2_address;
        
        logic [11:0] imm;
        logic [9:0] extend;

        logic write_to_reg;
        logic pre_calc; 
        logic is_branch;
        logic read_src2;
        logic src1_vector;
        logic src2_vector;
        
    } decoded_instr_t;

// ------------------------------------------------------------------------------------------------
//                                         REQUEST PACKETS
// ------------------------------------------------------------------------------------------------
    
    typedef struct packed {
        logic valid;
        
        signal_pkg::prf_tag_t prf_tag;
        signal_pkg::rob_address_t rob_id;
        signal_pkg::operations_e operation;

        signal_pkg::data_t operand_a;
        signal_pkg::data_t operand_b;

    } sc_ex_request_t;

    typedef struct packed {
        logic valid;

        signal_pkg::prf_tag_t prf_tag;
        signal_pkg::rob_address_t rob_id;

        signal_pkg::vector_data_t operand_a;
        signal_pkg::vector_data_t operand_b;

        signal_pkg::operations_e operation;

        logic a_is_vector;
        logic b_is_vector;

    } vc_alu_ex_request_t;

    typedef struct packed {
        logic valid;
        
        signal_pkg::prf_tag_t prf_tag;
        signal_pkg::rob_address_t rob_id;
        
        signal_pkg::operations_e operation;

        signal_pkg::prf_tag_t operand_a_tag;
        signal_pkg::prf_tag_t operand_b_tag;

        logic[11:0] imm;
        logic read_src2;

        logic a_is_vector;
        logic b_is_vector;

    } read_request_t;

    typedef struct packed {
        signal_pkg::prf_tag_t store_data_tag,
        logic a_is_vector;
        logic b_is_vector;
    } vc_lsu_read_request_t;

    typedef struct packed {
        signal_pkg::vector_data_t store_data,
        logic a_is_vector,
        logic b_is_vector
    } vc_lsu_ex_request_t;

// ------------------------------------------------------------------------------------------------
//                                   FUNCTIONAL UNIT RESULTS
// ------------------------------------------------------------------------------------------------
    
    typedef struct packed {
        logic valid;

        signal_pkg::prf_tag_t prf_tag;
        signal_pkg::rob_address_t rob_id;

        signal_pkg::data_t data;
    } sc_ex_result_t;

    typedef struct packed {
        logic valid;
        
        signal_pkg::rob_address_t rob_id;
        logic branch_taken;

    } br_result_t;

    typedef struct packed {
        logic valid;

        signal_pkg::prf_tag_t prf_tag;
        signal_pkg::rob_address_t rob_id;

        signal_pkg::vector_data_t data;

    } vc_ex_result_t;

// ------------------------------------------------------------------------------------------------
//                                        BUFFER ENTRIES
// ------------------------------------------------------------------------------------------------

    typedef struct packed {
        logic occupied;
        
        signal_pkg::prf_tag_t prf_tag;
        signal_pkg::rob_address_t rob_id;
        
        signal_pkg::operations_e operation;

        signal_pkg::prf_tag_t operand_a_tag;
        signal_pkg::prf_tag_t operand_b_tag;

        logic[11:0] imm;
        logic read_src2;

        logic operand_a_is_vector;
        logic operand_b_is_vector;

        logic operand_a_ready;
        logic operand_b_ready;

    } rs_entry_t;
    
    typedef struct packed {
        logic ready;
        logic write_to_reg;

        signal_pkg::prf_tag_t prf_tag;
        signal_pkg::arf_address_t dest_address;

        signal_pkg::data_t data;

        logic is_branch;
        logic branch_taken;
        
    } rob_entry_t;

    typedef struct packed {
        logic valid;
        logic is_store;
        logic is_vector;

        signal_pkg::prf_tag_t prf_tag;
        signal_pkg::rob_address_t rob_id;
        
        signal_pkg::dmem_address_t mem_addr;

        signal_pkg::vector_data_t data;

    } load_store_entry_t;

endpackage

