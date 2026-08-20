
class top_tb_instr_gen extends uvm_object;

    `uvm_object_utils(top_tb_instr_gen)

    // random fields
    rand instr_e op;
    rand logic [4:0] rs1, rs2, rd;
    rand logic [20:0] imm;

    signal_pkg::data_t instr;

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

    constraint c_imm_temp {
        imm > 2;
        imm < 8;
    }

    function void post_randomize();
        instr = pkg_instruction::encode_instr(.instr(op), .rs1(rs1), .rs2(rs2), .rd(rd), .imm({imm}));
    endfunction : post_randomize

    function string convert2string();
        return $sformatf("%-10s rd: x%02d\trs1: x%02d\trs2: x%02d\timm: %06h\t-> %08h",
                         op.name(), rd, rs1, rs2, imm, instr);
    endfunction : convert2string

endclass : top_tb_instr_gen