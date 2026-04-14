package config_pkg;

    //------------------------------------------
    // GLOBAL PARAMETERS
    //------------------------------------------

    // General architecture config
    parameter int unsigned INSTRUCTION_QUEUE_LEN = 16;
    parameter int unsigned NUMBER_OF_EX = 2; // 4 eventually
    parameter int unsigned NUMBER_OF_BRANCH_EX = 2;
    parameter int unsigned ROB_LEN = 32;

    // Reservation station config
    parameter int unsigned RS_MAX_LEN = 16;
    parameter int unsigned NUMBER_OF_RS = 1; // 3 eventually
    parameter int unsigned DUAL_SLOT_RS_LEN = 16;
    parameter int unsigned SINGLE_SLOT_RS_LEN = 8;

    // Data/Storage config
    parameter int unsigned DATA_SIZE = 32;
    parameter int unsigned VECTOR_DATA_SIZE = 128;
    parameter int unsigned ARCH_REG_DEPTH = 32;
    parameter int unsigned PRF_DEPTH = 48;

    //-------------------------------------------
    // DERIVED PARAMETERS
    //-------------------------------------------

    localparam int unsigned RS_ADDR_W = $clog2(RS_MAX_LEN);
    localparam int unsigned INSTRUCTION_QUEUE_PTR_LEN = $clog2(INSTRUCTION_QUEUE_LEN+1);
    localparam int unsigned RS_IDX_W = (NUMBER_OF_RS>1) ? $clog2(NUMBER_OF_RS) : 1;
    localparam int unsigned ROB_ADDR_W = $clog2(ROB_LEN);
    localparam int unsigned DUAL_SLOT_RS_IDX_W =$clog2(DUAL_SLOT_RS_LEN);
    localparam int unsigned SINGLE_SLOT_RS_IDX_W = $clog2(SINGLE_SLOT_RS_LEN);
    localparam int unsigned EX_IDX_W = $clog2(NUMBER_OF_EX);
    localparam int unsigned BRANCH_IDX_W = $clog2(NUMBER_OF_BRANCH_EX);
    localparam int unsigned REG_ADDR_W = $clog2(ARCH_REG_DEPTH);
    localparam int unsigned PRF_ADDR_W = $clog2(PRF_DEPTH);

endpackage

