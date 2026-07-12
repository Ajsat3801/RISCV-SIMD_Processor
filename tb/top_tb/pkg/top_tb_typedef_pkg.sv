package top_tb_typedef_pkg;

    typedef struct packed {
        logic valid;

        signal_pkg::prf_tag_t prf_tag;
        signal_pkg::rob_address_t rob_id;

        signal_pkg::data_t data;

        logic write_to_reg;
        signal_pkg::arf_address_t dest_address;

        logic is_branch;
        logic branch_taken;
        
    } retire_snapshot_t;

endpackage