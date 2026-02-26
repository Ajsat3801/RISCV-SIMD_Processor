package storage_pkg;

typedef struct packed {
    logic occupied;
    
    logic [ROB_ADDR_W-1:0] dest_rob_id;
    
    logic [31:0] operand_a;
    logic [31:0] operand_b; 
    
    operations_e operation;
    logic sign;

    logic [ROB_ADDR_W-1:0] operand_a_tag;
    logic [ROB_ADDR_W-1:0] operand_b_tag;

    logic operand_a_ready;
    logic operand_b_ready;
} rs_entry_t;

typedef struct packed {
    logic [ROB_ADDR_W-1:0] rob_id;
    logic in_use; // if in use is 1, then value is ROB, else its register
} rat_entry_t;

typedef struct packed {
    logic ready;
    
    logic write_to_reg;
    logic[REG_ADDR_W-1:0] dest_address;

    logic [31:0] data;
    logic branch;
    

} rob_entry_t;

endpackage