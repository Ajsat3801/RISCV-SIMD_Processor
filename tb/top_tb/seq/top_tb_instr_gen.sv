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
    rand int target_offset;

    rand int reg_pool_size;

    function new(string name = "top_tb_instr_gen");
        super.new(name);
    endfunction

    //  -------------------------------------------------------------------------------------------
    //                                  Constraints

    constraint c_pool_size{
        reg_pool_size inside {[3 : 31]};
    }
    constraint c_legal{
        op != UNKNOWN;
        op != I_ECALL;
    }
    constraint c_reg_pool {
        rd  inside {[1 : reg_pool_size]};
        rs1 inside {[0 : reg_pool_size]};
        rs2 inside {[0 : reg_pool_size]};
    }

    constraint c_br_target {
        (op inside {I_BEQ, I_BNE, I_BLT, I_BGE, I_BLTU, I_BGEU}) -> {
            target_offset inside {[-4096 : 4095]};
            target_offset[0] == 1'b0;
            (current_pc + target_offset) inside {[0 : config_pkg::IMEM_NUM_WORDS-1]};
        }
    }

    constraint c_jal_target {
        (op == I_JAL) -> {
            target_offset inside {[-1048576 : 1048575]};
            target_offset[0] == 1'b0;
            (current_pc + target_offset) inside {[0 : config_pkg::IMEM_NUM_WORDS-1]};
        }
    }

    function void post_randomize();

        // overwrite imm for branches and jumps
        if (op inside {I_BEQ, I_BNE, I_BLT, I_BGE, I_BLTU, I_BGEU}) imm[12:0] = target_offset[12:0];
        else if (op == I_JAL) imm[20:0] = target_offset[20:0];

        instr = pkg_instruction::encode_instr(.instr(op), .rs1(rs1), .rs2(rs2), .rd(rd), .imm({imm}));

    endfunction : post_randomize

    function string convert2string();
        return $sformatf("%-10s rd: x%02d\trs1: x%02d\trs2: x%02d\timm: %06h\t-> %08h",
                         op.name(), rd, rs1, rs2, imm, instr);
    endfunction : convert2string

    function void set_current_pc(int unsigned pc);
        // used to call 
        current_pc = pc;
    endfunction : set_current_pc



endclass : top_tb_instr_gen