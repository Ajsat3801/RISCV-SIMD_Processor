    `define SET_FIXED(FIELD, VAL) \
        FIELD.rand_mode(0); \
        FIELD = VAL;

    `define CLEAR_FIXED(FIELD) \
        FIELD.rand_mode(1);

class top_tb_instr_gen extends uvm_object;

    `uvm_object_utils(top_tb_instr_gen)

    // random fields
    rand instr_e op;
    rand logic [4:0] rs1, rs2, rd;
    rand logic [20:0] imm;

    signal_pkg::data_t instr;

    int unsigned current_pc;
    int random_small_no;
    int unsigned program_length;

    rand int target_offset;
    rand int reg_pool_size;

    typedef enum {
        CAT_ALU, CAT_VALU, CAT_MUL, CAT_DIV, CAT_VC_LSU,
        CAT_SC_LSU, CAT_BRANCH, CAT_JUMP, CAT_UPPER
    } instr_cat_e;

    rand instr_cat_e cat;

    function new(string name = "top_tb_instr_gen");
        super.new(name);
    endfunction

    //  -------------------------------------------------------------------------------------------
    //                                  Constraints
    //  -------------------------------------------------------------------------------------------

    constraint c_cat_mix {
        cat dist {
            CAT_ALU    := 396,    CAT_VALU  := 135,
            CAT_MUL := 60, CAT_DIV := 20, CAT_VC_LSU  := 60,
            CAT_SC_LSU  := 200,  CAT_BRANCH:= 120,
            CAT_JUMP   := 36,   CAT_UPPER := 20
        };
    }

    constraint c_cat_to_op {
        (cat == CAT_ALU)    -> op inside {I_ADD, I_SUB, I_AND, I_OR, I_XOR, I_SLL, I_SRL,
                                          I_SLT, I_SLTU, I_ADDI, I_ANDI, I_ORI, I_XORI,
                                          I_SLLI, I_SRLI, I_SLTI, I_SLTIU};
        (cat == CAT_VALU)   -> op inside {V_ADD_VV, V_ADD_VX, V_SUB_VV, V_SUB_VX, V_RSUB_VX,
                                          V_AND_VV, V_AND_VX, V_OR_VV, V_OR_VX,
                                          V_XOR_VV, V_XOR_VX};
        (cat == CAT_MUL) -> op inside {M_MUL, M_MULH, M_MULHU, M_MULHSU};
        (cat == CAT_DIV)    -> op inside {M_DIV, M_DIVU, M_REM, M_REMU};
        (cat == CAT_SC_LSU)   -> op inside {I_LW, I_SW};
        (cat == CAT_VC_LSU)  -> op inside {V_LE32, V_SE32};
        (cat == CAT_BRANCH) -> op inside {I_BEQ, I_BNE, I_BLT, I_BGE, I_BLTU, I_BGEU};
        (cat == CAT_JUMP)   -> op == I_JAL;
        (cat == CAT_UPPER)  -> op inside {I_LUI, I_AUIPC};
    }

    constraint c_order {
        solve cat before op;
        solve op  before target_offset;
        solve op  before imm;
        solve op  before rs1;
    }

    constraint c_pool_size{
        reg_pool_size inside {[3 : 31]};
    }
    constraint c_legal{
        op != UNKNOWN;
        op != I_ECALL;
    }
    constraint c_reg_pool {
        rd  inside {[1 : reg_pool_size]};
        !(rd inside {[top_tb_config_pkg::RESERVED_REG_LO : top_tb_config_pkg::RESERVED_REG_HI]});
        rs1 inside {[0 : reg_pool_size]};
        rs2 inside {[0 : reg_pool_size]};
    }

    constraint c_br_target {
        (op inside {I_BEQ, I_BNE, I_BLT, I_BGE, I_BLTU, I_BGEU}) -> {
            target_offset inside {[2 : 8]};
            target_offset[0] == 1'b0;
            //(current_pc + target_offset) < program_length;
        }
    }

    constraint c_jal_target {
        (op == I_JAL) -> {
            target_offset inside {[2 : 1048575]};
            target_offset[0] == 1'b0;
            (current_pc + target_offset) < program_length;
        }
    }

    constraint c_dmem_target {
        (op inside {I_LW, I_SW, V_LE32, V_SE32}) -> {
            rs1 == 4;
            imm + random_small_no >= 0;
            imm + random_small_no < 1024;
        }
    }

    function void post_randomize();

        // overwrite imm for branches and jumps
        if (op inside {I_BEQ, I_BNE, I_BLT, I_BGE, I_BLTU, I_BGEU}) imm[12:0] = target_offset[12:0];
        else if (op == I_JAL) imm[20:0] = target_offset[20:0];

        instr = pkg_instruction_encoding::encode_instr(.instr(op), .rs1(rs1), .rs2(rs2), .rd(rd), .imm({imm}));

    endfunction : post_randomize

    function string convert2string();
        return $sformatf("%-10s rd: x%02d\trs1: x%02d\trs2: x%02d\timm: %06h\t-> %08h",
                         op.name(), rd, rs1, rs2, imm, instr);
    endfunction : convert2string

    function void set_current_pc(int unsigned pc);
        // used to call 
        current_pc = pc;
    endfunction : set_current_pc

    function void set_random_small_no (int num);
        random_small_no = num;
    endfunction : set_random_small_no

    function void set_program_length(int unsigned len);
        program_length = len;
    endfunction : set_program_length

endclass : top_tb_instr_gen