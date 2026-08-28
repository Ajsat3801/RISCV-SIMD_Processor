package config_pkg;

    // ----------------------------------------------------------------------------------------------------------------
    //                                          GLOBAL CONFIG PARAMETERS 
    // ----------------------------------------------------------------------------------------------------------------

    parameter int unsigned DATA_W = 32;                     // Number of bits in a single element
    parameter int unsigned VECTOR_LEN = 4;                  // Number of elements in a vector
    
    parameter int unsigned SCALAR_EX_N = 4;                 // Number of scalar ex units
    parameter int unsigned VECTOR_EX_N = 2;                 // Number of vector ex units
    parameter int unsigned RS_SINGLE_DISPATCH_N = 4;        // Number of reservation stations with 1 dispatch slot
    parameter int unsigned RS_DUAL_DISPATCH_N = 1;          // Number of reservation stations with 2 dispatch slots

    parameter int unsigned INSTR_QUEUE_DEPTH = 16;          // Number of entries in instruction queue
    parameter int unsigned ROB_DEPTH = 32;                  // Number of entries in ROB
    parameter int unsigned RS_SINGLE_DISPATCH_DEPTH = 8;    // Number of entries in an RS with 1 dispatch slot
    parameter int unsigned RS_DUAL_DISPATCH_DEPTH = 32;     // Number of entries in an RS with 2 dispatch slots
    parameter int unsigned STORE_BUFFER_DEPTH = 4;          // Number of entries in store buffer

    parameter int unsigned ARCH_REG_DEPTH = 32;             // Number of registers in the core
    parameter int unsigned PRF_DEPTH = 64;                  // Number of physical registers in the core

    parameter int unsigned IMEM_DEPTH = 256;                // Number of entries in IMEM
    parameter int unsigned DMEM_BANK_DEPTH = 256;           // Number of entries in a single bank of DMEM
    parameter int unsigned PC_W = 16;                       // Width of program counter
    parameter int unsigned PHY_MEM_ADDR_W = 16;             // Width of memory address
    parameter int unsigned CACHE_LINE_DEPTH = 4;            // Number of words in a single cache line

    // ----------------------------------------------------------------------------------------------------------------
    //                                          DERIVED CONFIG PARAMETERS 
    // ----------------------------------------------------------------------------------------------------------------

    localparam int unsigned EX_TOT_N = SCALAR_EX_N + VECTOR_EX_N; // Total number of ex units
    
    // Total number of reservation stations & RS select signal width calculation
    localparam int unsigned RS_TOT_N = RS_SINGLE_DISPATCH_N + RS_DUAL_DISPATCH_N;
    localparam int unsigned RS_SEL_W = (RS_TOT_N>1) ? $clog2(RS_TOT_N) : 1;
    // Total number of instructions that can be dispatched in a single cycle (== EX_TOT_N)
    localparam int unsigned RS_TOT_DISPATCH_N = 2*RS_DUAL_DISPATCH_N + RS_SINGLE_DISPATCH_N;
    
    // Reservation station address width calculation
    localparam int unsigned RS_MAX_DEPTH = (RS_DUAL_DISPATCH_DEPTH>RS_SINGLE_DISPATCH_DEPTH) ? 
                                            RS_DUAL_DISPATCH_DEPTH : RS_SINGLE_DISPATCH_DEPTH;
    localparam int unsigned RS_ADDR_W = $clog2(RS_MAX_DEPTH);
    
    localparam int unsigned DMEM_BANKS_N = VECTOR_LEN;      // Number of banks in DMEM (= Vector length)
    localparam int unsigned DMEM_DEPTH = IMEM_DEPTH * DMEM_BANKS_N; // Total depth of banked DMEM

endpackage

