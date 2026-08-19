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

    typedef enum logic [6:0] {
        OPC_OP     = 7'b0110011,     // register-register  (RV32I / RV32M)
        OPC_OP_IMM = 7'b0010011,     // register-immediate
        OPC_LOAD   = 7'b0000011,
        OPC_STORE  = 7'b0100011,
        OPC_BRANCH = 7'b1100011,
        OPC_JAL    = 7'b1101111,
        OPC_LUI    = 7'b0110111,
        OPC_AUIPC  = 7'b0010111,
        OPC_SYSTEM = 7'b1110011,     // ecall, used as terminator
        OPC_OP_V   = 7'b1010111,     // vector ALU
        OPC_VLOAD  = 7'b0000111,
        OPC_VSTORE = 7'b0100111
    } opcodes_e;

    typedef enum logic [17:0] {

        // values chosen in the format {sel(for vectors only), muldiv bit, sub bit, funct3, opcode}
        UNKNOWN     = '1,

        //  ---------------------------- RV32I register-register ------------------------------
        I_ADD       = { 6'b000000,   1'b0,  1'b0,  3'b000,  OPC_OP     },
        I_SUB       = { 6'b000000,   1'b0,  1'b1,  3'b000,  OPC_OP     },
        I_SLL       = { 6'b000000,   1'b0,  1'b0,  3'b001,  OPC_OP     },
        I_SLT       = { 6'b000000,   1'b0,  1'b0,  3'b010,  OPC_OP     },
        I_SLTU      = { 6'b000000,   1'b0,  1'b0,  3'b011,  OPC_OP     },
        I_XOR       = { 6'b000000,   1'b0,  1'b0,  3'b100,  OPC_OP     },
        I_SRL       = { 6'b000000,   1'b0,  1'b0,  3'b101,  OPC_OP     },   // SRA not implemented
        I_OR        = { 6'b000000,   1'b0,  1'b0,  3'b110,  OPC_OP     },
        I_AND       = { 6'b000000,   1'b0,  1'b0,  3'b111,  OPC_OP     },

        //  ---------------------------- RV32I register-immediate -----------------------------
        I_ADDI      = { 6'b000000,   1'b0,  1'b0,  3'b000,  OPC_OP_IMM },
        I_SLLI      = { 6'b000000,   1'b0,  1'b0,  3'b001,  OPC_OP_IMM },
        I_SLTI      = { 6'b000000,   1'b0,  1'b0,  3'b010,  OPC_OP_IMM },
        I_SLTIU     = { 6'b000000,   1'b0,  1'b0,  3'b011,  OPC_OP_IMM },
        I_XORI      = { 6'b000000,   1'b0,  1'b0,  3'b100,  OPC_OP_IMM },
        I_SRLI      = { 6'b000000,   1'b0,  1'b0,  3'b101,  OPC_OP_IMM },   // SRAI not implemented
        I_ORI       = { 6'b000000,   1'b0,  1'b0,  3'b110,  OPC_OP_IMM },
        I_ANDI      = { 6'b000000,   1'b0,  1'b0,  3'b111,  OPC_OP_IMM },

        //  --------------------------------- RV32M -------------------------------------------
        M_MUL       = { 6'b000000,   1'b1,  1'b0,  3'b000,  OPC_OP     },
        M_MULH      = { 6'b000000,   1'b1,  1'b0,  3'b001,  OPC_OP     },
        M_MULHSU    = { 6'b000000,   1'b1,  1'b0,  3'b010,  OPC_OP     },
        M_MULHU     = { 6'b000000,   1'b1,  1'b0,  3'b011,  OPC_OP     },
        M_DIV       = { 6'b000000,   1'b1,  1'b0,  3'b100,  OPC_OP     },
        M_DIVU      = { 6'b000000,   1'b1,  1'b0,  3'b101,  OPC_OP     },
        M_REM       = { 6'b000000,   1'b1,  1'b0,  3'b110,  OPC_OP     },
        M_REMU      = { 6'b000000,   1'b1,  1'b0,  3'b111,  OPC_OP     },

        //  ---------------------------- Scalar load / store ----------------------------------
        I_LW        = { 6'b000000,   1'b0,  1'b0,  3'b010,  OPC_LOAD   },
        I_SW        = { 6'b000000,   1'b0,  1'b0,  3'b010,  OPC_STORE  },

        //  --------------------------------- Branches ----------------------------------------
        I_BEQ       = { 6'b000000,   1'b0,  1'b0,  3'b000,  OPC_BRANCH },
        I_BNE       = { 6'b000000,   1'b0,  1'b0,  3'b001,  OPC_BRANCH },
        I_BLT       = { 6'b000000,   1'b0,  1'b0,  3'b100,  OPC_BRANCH },
        I_BGE       = { 6'b000000,   1'b0,  1'b0,  3'b101,  OPC_BRANCH },
        I_BLTU      = { 6'b000000,   1'b0,  1'b0,  3'b110,  OPC_BRANCH },
        I_BGEU      = { 6'b000000,   1'b0,  1'b0,  3'b111,  OPC_BRANCH },

        //  ------------------------- Jump / upper immediate ----------------------------------
        //  funct3 held at 0: for J-type and U-type, instr[14:12] is immediate, not funct3
        I_JAL       = { 6'b000000,   1'b0,  1'b0,  3'b000,  OPC_JAL    },
        I_LUI       = { 6'b000000,   1'b0,  1'b0,  3'b000,  OPC_LUI    },
        I_AUIPC     = { 6'b000000,   1'b0,  1'b0,  3'b000,  OPC_AUIPC  },

        //  ------------------------- Vector ALU, vector-vector -------------------------------
        //  funct3 = 000 selects .vv;  sel carries funct6
        V_ADD_VV    = { 6'b000000,   1'b0,  1'b0,  3'b000,  OPC_OP_V   },
        V_SUB_VV    = { 6'b000010,   1'b0,  1'b0,  3'b000,  OPC_OP_V   },
        V_AND_VV    = { 6'b001001,   1'b0,  1'b0,  3'b000,  OPC_OP_V   },
        V_OR_VV     = { 6'b001010,   1'b0,  1'b0,  3'b000,  OPC_OP_V   },
        V_XOR_VV    = { 6'b001011,   1'b0,  1'b0,  3'b000,  OPC_OP_V   },

        //  ------------------------- Vector ALU, vector-scalar -------------------------------
        //  funct3 = 100 selects .vx
        V_ADD_VX    = { 6'b000000,   1'b0,  1'b0,  3'b100,  OPC_OP_V   },
        V_SUB_VX    = { 6'b000010,   1'b0,  1'b0,  3'b100,  OPC_OP_V   },
        V_RSUB_VX   = { 6'b000011,   1'b0,  1'b0,  3'b100,  OPC_OP_V   },
        V_AND_VX    = { 6'b001001,   1'b0,  1'b0,  3'b100,  OPC_OP_V   },
        V_OR_VX     = { 6'b001010,   1'b0,  1'b0,  3'b100,  OPC_OP_V   },
        V_XOR_VX    = { 6'b001011,   1'b0,  1'b0,  3'b100,  OPC_OP_V   },

        //  ---------------------------- Vector load / store ----------------------------------
        //  the muldiv bit sits at instr[25], which is vm for vector ops;  decode() passes it
        //  through for OPC_OP_V so a masked (vm=1) instruction lands on no member -> UNKNOWN
        V_LE32      = { 6'b000000,   1'b0,  1'b0,  3'b110,  OPC_VLOAD  },
        V_SE32      = { 6'b000000,   1'b0,  1'b0,  3'b110,  OPC_VSTORE },

        //  -------------------------------- Terminator ---------------------------------------
        I_ECALL     = { 6'b000000,   1'b0,  1'b0,  3'b000,  OPC_SYSTEM }

    } instr_e;

endpackage