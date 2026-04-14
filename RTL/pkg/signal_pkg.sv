
package signal_pkg;

    typedef struct packed {
        logic valid;
        
        instr_pkg::prf_tag_t prf_tag;
        instr_pkg::rob_address_t rob_id;

        instr_pkg::data_t operand_a;
        instr_pkg::data_t operand_b;

        instr_pkg::operations_e operation;
        logic sign;

    } rs_to_alu_signal_t;

    typedef struct packed {
        logic valid;

        instr_pkg::prf_tag_t prf_tag;
        instr_pkg::rob_address_t rob_id;

        logic [31:0] data;

    } ex_to_wb_signal_t;

    typedef struct packed {
        logic valid;

        instr_pkg::rob_address_t rob_id;
        logic branch_taken;

    } alu_to_wb_branch_signal_t;

    typedef struct packed {
        logic valid;
        
        instr_pkg::rob_address_t rob_id;
        logic branch_taken;

    } wb_to_rob_branch_t;

endpackage