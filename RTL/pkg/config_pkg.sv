package config_pkg;

    //------------------------------------------
    // GLOBAL PARAMETERS
    //------------------------------------------

    // General architecture config
    parameter int unsigned INSTRUCTION_QUEUE_LEN = 16;
    parameter int unsigned EX_COUNT = 6;
    parameter int unsigned SCALAR_EX_COUNT = 4;
    parameter int unsigned ROB_LEN = 32;

    // Reservation station config
    parameter int unsigned RS_COUNT = 5;
    parameter int unsigned SINGLE_SLOT_RS_COUNT = 4;
    parameter int unsigned DUAL_SLOT_RS_COUNT = 1;
    parameter int unsigned SINGLE_SLOT_RS_LEN = 8;
    parameter int unsigned DUAL_SLOT_RS_LEN = 16;

    // Data/Storage config
    parameter int unsigned DATA_SIZE = 32;
    parameter int unsigned VECTOR_DATA_SIZE = 128;
    parameter int unsigned ARCH_REG_DEPTH = 32;
    parameter int unsigned PRF_DEPTH = 48;

    // Memory config
    parameter int unsigned IMEM_WORD_SIZE = 32;
    parameter int unsigned IMEM_NUM_WORDS = 256;
    parameter int unsigned DMEM_WORD_SIZE = 32;
    parameter int unsigned DMEM_NUM_WORDS = 256;
    parameter int unsigned DMEM_NUM_BANKS = 4;

    // We are using 5 identical SRAMs, each with 1 R/W port. one for IMEM and 4 for banked DMEM

    //-------------------------------------------
    // DERIVED PARAMETERS
    //-------------------------------------------

    localparam int unsigned RS_MAX_LEN = (DUAL_SLOT_RS_LEN>SINGLE_SLOT_RS_LEN) ? DUAL_SLOT_RS_LEN : SINGLE_SLOT_RS_LEN;
    localparam int unsigned RS_ADDR_W = $clog2(RS_MAX_LEN);
    localparam int unsigned INSTRUCTION_QUEUE_PTR_LEN = $clog2(INSTRUCTION_QUEUE_LEN+1);
    localparam int unsigned RS_IDX_W = (RS_COUNT>1) ? $clog2(RS_COUNT) : 1;
    localparam int unsigned ROB_ADDR_W = $clog2(ROB_LEN);
    localparam int unsigned DUAL_SLOT_RS_IDX_W =$clog2(DUAL_SLOT_RS_LEN);
    localparam int unsigned SINGLE_SLOT_RS_IDX_W = $clog2(SINGLE_SLOT_RS_LEN);
    localparam int unsigned EX_IDX_W = $clog2(EX_COUNT);
    localparam int unsigned REG_ADDR_W = $clog2(ARCH_REG_DEPTH);
    localparam int unsigned PRF_ADDR_W = $clog2(PRF_DEPTH);
    localparam int unsigned RS_DISPATCH_COUNT = 2*DUAL_SLOT_RS_COUNT + SINGLE_SLOT_RS_COUNT;

endpackage

