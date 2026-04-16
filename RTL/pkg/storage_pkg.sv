
package storage_pkg;

    typedef struct packed {
        logic occupied;
        
        instr_pkg::prf_tag_t prf_tag;
        instr_pkg::rob_address_t rob_id;
        
        instr_pkg::data_t operand_a;
        instr_pkg::data_t operand_b; 
        
        instr_pkg::operations_e operation;

        instr_pkg::prf_tag_t operand_a_tag;
        instr_pkg::prf_tag_t operand_b_tag;

        logic operand_a_ready;
        logic operand_b_ready;

    } rs_entry_t;

    typedef struct packed {
        logic ready;
        logic write_to_reg;

        instr_pkg::prf_tag_t prf_tag;
        instr_pkg::arf_address_t dest_address;

        instr_pkg::data_t data;

        logic is_branch;
        logic branch_taken;
        
    } rob_entry_t;

    typedef struct packed {
        logic valid;

        instr_pkg::prf_tag_t prf_tag;
        instr_pkg::rob_address_t rob_id;

        instr_pkg::data_t data;

    } alu_result_entry_t;

endpackage