package config_pkg;

    //------------------------------------------
    // GLOBAL PARAMETERS
    //------------------------------------------

    // General architecture config
    parameter int unsigned INSTRUCTION_QUEUE_LEN = 16;
    parameter int unsigned EX_COUNT = 6;
    parameter int unsigned SCALAR_EX_COUNT = 4;
    parameter int unsigned VECTOR_EX_COUNT = 2;
    parameter int unsigned ROB_LEN = 32;

    // Reservation station config
    parameter int unsigned RS_COUNT = 5;
    parameter int unsigned SINGLE_SLOT_RS_COUNT = 4;
    parameter int unsigned DUAL_SLOT_RS_COUNT = 1;
    parameter int unsigned SINGLE_SLOT_RS_LEN = 8;
    parameter int unsigned DUAL_SLOT_RS_LEN = 32;

    // Data/Storage config
    parameter int unsigned DATA_SIZE = 32;
    parameter int unsigned VECTOR_SIZE = 4;
    parameter int unsigned ARCH_REG_DEPTH = 32;
    parameter int unsigned PRF_DEPTH = 64;
    parameter int unsigned STORE_BUFFER_SIZE = 4;

    // Memory config
    parameter int unsigned IMEM_WORD_SIZE = 32;
    parameter int unsigned IMEM_NUM_WORDS = 256;
    parameter int unsigned DMEM_WORD_SIZE = 32;
    parameter int unsigned DMEM_NUM_WORDS = 256;

    // We are using 5 identical SRAMs, each with 1 R/W port. one for IMEM and 4 for banked DMEM

    //-------------------------------------------
    // DERIVED PARAMETERS
    //-------------------------------------------

    localparam int unsigned RS_MAX_LEN = (DUAL_SLOT_RS_LEN>SINGLE_SLOT_RS_LEN) ? DUAL_SLOT_RS_LEN : SINGLE_SLOT_RS_LEN;
    localparam int unsigned RS_ADDR_W = $clog2(RS_MAX_LEN);
    localparam int unsigned RS_IDX_W = (RS_COUNT>1) ? $clog2(RS_COUNT) : 1;
    localparam int unsigned ROB_ADDR_W = $clog2(ROB_LEN);
    localparam int unsigned DUAL_SLOT_RS_IDX_W =$clog2(DUAL_SLOT_RS_LEN);
    localparam int unsigned SINGLE_SLOT_RS_IDX_W = $clog2(SINGLE_SLOT_RS_LEN);
    localparam int unsigned EX_IDX_W = $clog2(EX_COUNT);
    localparam int unsigned REG_ADDR_W = $clog2(ARCH_REG_DEPTH);
    localparam int unsigned PRF_ADDR_W = $clog2(PRF_DEPTH);
    localparam int unsigned RS_DISPATCH_COUNT = 2*DUAL_SLOT_RS_COUNT + SINGLE_SLOT_RS_COUNT;
    localparam int unsigned IMEM_ADDR_SIZE = $clog2(IMEM_NUM_WORDS);
    localparam int unsigned DMEM_NUM_BANKS = VECTOR_SIZE;
    localparam int unsigned DMEM_SIZE = DMEM_NUM_WORDS * DMEM_NUM_BANKS;
    localparam int unsigned DMEM_ADDR_SIZE = $clog2(DMEM_SIZE);

endpackage

