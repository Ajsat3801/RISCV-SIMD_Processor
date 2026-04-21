
package signal_pkg;

    typedef struct packed {
        logic valid;
        
        instr_pkg::prf_tag_t prf_tag;
        instr_pkg::rob_address_t rob_id;

        instr_pkg::data_t operand_a;
        instr_pkg::data_t operand_b;

        instr_pkg::operations_e operation;

    } sc_ex_input_signal_t;

    typedef struct packed {
        logic valid;

        instr_pkg::prf_tag_t prf_tag;
        instr_pkg::rob_address_t rob_id;

        instr_pkg::data_t data;

    } sc_ex_output_signal_t;

    typedef struct packed {
        logic valid;
        
        instr_pkg::rob_address_t rob_id;
        logic branch_taken;

    } br_output_signal_t;

    typedef struct packed {
        logic valid;

        instr_pkg::prf_tag_t prf_tag;
        instr_pkg::rob_address_t rob_id;

        instr_pkg::vector_data_t operand_a;
        instr_pkg::data_t operand_b;

        instr_pkg::operations_e operation;

        logic a_is_vector;
        logic b_is_vector;

    } vc_ex_input_signal_t;

    typedef struct packed {
        logic valid;

        instr_pkg::prf_tag_t prf_tag;
        instr_pkg::rob_address_t rob_id;

        instr_pkg::vector_data_t data;
    } vc_ex_output_signal_t;

    typedef struct packed {
        logic valid;
        
        instr_pkg::prf_tag_t prf_tag;
        instr_pkg::rob_address_t rob_id;

        instr_pkg::data_t operand_a;
        
        instr_pkg::operations_e operation;

        logic a_is_vector;
        logic b_is_vector;

        instr_pkg::prf_tag_t operand_a_tag;
        instr_pkg::prf_tag_t operand_b_tag;

    } vc_dispatched_instr_t;

endpackage