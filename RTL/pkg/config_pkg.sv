package config_pkg;

    // ----------------------------------------------------------------------------------------------------------------
    //                                          GLOBAL CONFIG PARAMETERS 
    // ----------------------------------------------------------------------------------------------------------------

    parameter int unsigned DATA_W = 32;                     // Number of bits in a single element
    parameter int unsigned VECTOR_LEN = 4;                  // Number of elements in a vector
    
    parameter int unsigned INSTR_QUEUE_DEPTH = 16;          // Number of entries in instruction queue
    parameter int unsigned ROB_DEPTH = 32;                  // Number of entries in ROB
    parameter int unsigned ARCH_REG_DEPTH = 32;             // Number of registers in the core
    parameter int unsigned PRF_DEPTH = 64;                  // Number of physical registers in the core

    parameter int unsigned EX_SC_ALU_N = 2;
    parameter int unsigned EX_MULDIV_N = 1;
    parameter int unsigned EX_BRANCH_N = 1;
    parameter int unsigned EX_LSU_N = 1;
    parameter int unsigned EX_VC_ALU_N = 1;

    parameter int unsigned RS_POOL_N = 6;
    parameter int unsigned RS_SC_ALU_DEPTH = 16;
    parameter int unsigned RS_MULDIV_DEPTH = 8;
    parameter int unsigned RS_BRANCH_DEPTH = 8;
    parameter int unsigned RS_VC_ALU_DEPTH = 8;
    parameter int unsigned RS_LSU_LOAD_DEPTH  = 8;          // Number of load entries in LSU reservation station
    parameter int unsigned RS_LSU_STORE_DEPTH = 4;          // Number of store entries in LSU reservation station
    
    parameter int unsigned STORE_BUFFER_DEPTH = 4;          // Number of entries in store buffer

    parameter int unsigned IMEM_DEPTH = 256;                // Number of entries in IMEM
    parameter int unsigned DCACHE_BANK_DEPTH = 256;         // Number of entries in a single bank of DCACHE
    parameter int unsigned PC_W = 16;                       // Width of program counter (Max 22)
    parameter int unsigned PHY_MEM_ADDR_W = 16;             // Width of memory address

    // ----------------------------------------------------------------------------------------------------------------
    //                                          DERIVED CONFIG PARAMETERS 
    // ----------------------------------------------------------------------------------------------------------------

    // Total Number of scalar writeback ports
    localparam int unsigned SCALAR_EX_N = EX_SC_ALU_N + EX_MULDIV_N + EX_LSU_N;  
    // Total number of vector writeback ports
    localparam int unsigned VECTOR_EX_N = EX_LSU_N + EX_VC_ALU_N;        

    localparam int unsigned RS_DISPATCH_N = SCALAR_EX_N + VECTOR_EX_N + EX_BRANCH_N;
    
    localparam int unsigned IMEM_ADDR_W = $clog2(IMEM_DEPTH);

/* Notes
 *  -> the number of banks in a cache will always be equal to the number of elements in a vector
 *  -> All RS depths must be powers of 2.
 *  -> EX_LSU_N counted twice in RS_DISPATCH_N because of decoupled dispatched signals for loads and stores
 */

endpackage

