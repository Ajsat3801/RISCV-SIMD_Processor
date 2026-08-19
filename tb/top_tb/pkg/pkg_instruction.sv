
package pkg_instruction;

    import top_tb_typedef_pkg::*;
    
    // --------------------------------------------------------------------------------------------
    //                                      Instruction Encoding
    // --------------------------------------------------------------------------------------------

    function automatic signal_pkg::data_t enc_r(
        input logic [6:0] funct7,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [4:0] rd,
        input logic [6:0] opcode
    );
        enc_r = {funct7, rs2, rs1, funct3, rd, opcode};

    endfunction : enc_r

    function automatic signal_pkg::data_t enc_i(
        input logic [11:0] imm,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [4:0] rd,
        input logic [6:0] opcode
    );
        enc_i = {imm, rs1, funct3, rd, opcode};

    endfunction : enc_i

    function automatic signal_pkg::data_t enc_s(
        input logic [11:0] imm, 
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [6:0] opcode
    );
        enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    endfunction : enc_s

    function automatic signal_pkg::data_t enc_u(
        input logic [19:0] imm,
        input logic [4:0] rd,
        input logic [6:0] opcode
    );
        enc_u = {imm, rd, opcode};

    endfunction : enc_u

    function automatic signal_pkg::data_t enc_b(
        input logic [12:0] imm,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [6:0] opcode
    );
        enc_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};

    endfunction : enc_b

    function automatic signal_pkg::data_t enc_j(
        input logic [20:0] imm,
        input logic [4:0] rd,
        input logic [6:0] opcode
    );
        enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};

    endfunction : enc_j

    function automatic signal_pkg::data_t enc_valu(
        input logic [5:0] funct6,
        input logic vm,
        input logic [4:0] src2,
        input logic [4:0] src1,
        input logic [2:0] mode,
        input logic [4:0] dest,
        input logic [6:0] opcode
    );
        enc_valu = {funct6, vm, src2, src1, mode, dest, opcode};
    endfunction : enc_valu

    function automatic signal_pkg::data_t enc_vls(
        input logic [11:0] pad,
        input logic [4:0] rs1,
        input logic [2:0] width,
        input logic [4:0] vreg, 
        input logic [6:0] opcode
    );
        // common encoding for vector loads and vector stores
        // only here, loads and stores are handled separately everwhere else
        enc_vls = {pad, rs1, width, vreg, opcode};
    endfunction : enc_vls
    
    function automatic signal_pkg::data_t encode_instr(
        input instr_e instr,
        input logic [4:0] rs1, rs2, rd,
        input logic [20:0] imm
    );

        case (instr[6:0])
            OPC_OP :
                encode_instr = enc_r(  .funct7({1'b0, instr[10], 4'b0000, instr[11]}),.rs2(rs2),.rs1(rs1),
                                    .funct3(instr[9:7]),.rd(rd),.opcode(OPC_OP));
            OPC_OP_IMM : 
                if (instr[9:7] inside {3'b001, 3'b101})     // SLLI / SRLI: [31:25] is funct7, not imm
                    encode_instr = enc_i(.imm({7'b0, imm[4:0]}), .rs1(rs1), .funct3(instr[9:7]),
                                        .rd(rd), .opcode(OPC_OP_IMM));
                else
                    encode_instr = enc_i(.imm(imm[11:0]), .rs1(rs1), .funct3(instr[9:7]),
                                        .rd(rd), .opcode(OPC_OP_IMM));
            OPC_LOAD :
                encode_instr = enc_i (.imm(imm[11:0]), .rs1(rs1), .funct3(instr[9:7]), .rd(rd), .opcode(OPC_LOAD));
            OPC_STORE :
                encode_instr = enc_s (.imm(imm[11:0]), .rs2(rs2), .rs1(rs1), .funct3(instr[9:7]), .opcode(OPC_STORE));
            OPC_BRANCH :
                encode_instr = enc_b(.imm(imm[12:0]), .rs2(rs2), .rs1(rs1), .funct3(instr[9:7]), .opcode(OPC_BRANCH));
            OPC_JAL :
                encode_instr = enc_j(.imm(imm[20:0]), .rd(rd), .opcode(OPC_JAL));
            OPC_LUI : 
                encode_instr = enc_u(.imm(imm[19:0]), .rd(rd), .opcode(OPC_LUI));
            OPC_AUIPC :
                encode_instr = enc_u(.imm(imm[19:0]), .rd(rd), .opcode(OPC_AUIPC));
            OPC_SYSTEM :
                encode_instr = terminate();
            OPC_OP_V :
                encode_instr = enc_valu(.funct6(instr[17:12]), .vm(1'b0), .src2(rs2), .src1(rs1),
                                        .mode(instr[9:7]), .dest(rd), .opcode(OPC_OP_V));
            OPC_VLOAD :
                encode_instr = enc_vls(12'b000000000000, rs1, instr[9:7], rd, OPC_VLOAD);
            OPC_VSTORE :
                encode_instr = enc_vls(12'b000000000000, rs1, instr[9:7], rd, OPC_VSTORE);
            default :
                encode_instr = '1;

        endcase

    endfunction

    //  -------------------------------------------------------------------------------------------
    //                              Functions for instructions
    //  -------------------------------------------------------------------------------------------

    //  --------------------------------- ALU Instructions ----------------------------------------

    function automatic signal_pkg::data_t rv32i_addi (input logic [4:0] rd, rs1, input logic [11:0] imm);
        rv32i_addi = enc_i(imm, rs1, 3'b000, rd, 7'b0010011);
    endfunction

    function automatic signal_pkg::data_t rv32i_slti (input logic [4:0] rd, rs1, input logic [11:0] imm);
        rv32i_slti = enc_i(imm, rs1, 3'b010, rd, 7'b0010011);
    endfunction

    function automatic signal_pkg::data_t rv32i_sltiu (input logic [4:0] rd, rs1, input logic [11:0] imm);
        rv32i_sltiu = enc_i(imm, rs1, 3'b011, rd, 7'b0010011);
    endfunction

    function automatic signal_pkg::data_t rv32i_xori (input logic [4:0] rd, rs1, input logic [11:0] imm);
        rv32i_xori = enc_i(imm, rs1, 3'b100, rd, 7'b0010011);
    endfunction

    function automatic signal_pkg::data_t rv32i_ori (input logic [4:0] rd, rs1, input logic [11:0] imm);
        rv32i_ori = enc_i(imm, rs1, 3'b110, rd, 7'b0010011);
    endfunction

    function automatic signal_pkg::data_t rv32i_andi (input logic [4:0] rd, rs1, input logic [11:0] imm);
        rv32i_andi = enc_i(imm, rs1, 3'b111, rd, 7'b0010011);
    endfunction

    function automatic signal_pkg::data_t rv32i_slli (input logic [4:0] rd, rs1, shamt);
        rv32i_slli  = enc_r(7'b0000000, shamt, rs1, 3'b001, rd, 7'b0010011);
    endfunction

    function automatic signal_pkg::data_t rv32i_srli (input logic [4:0] rd, rs1, shamt);
        rv32i_srli  = enc_r(7'b0000000, shamt, rs1, 3'b101, rd, 7'b0010011);
    endfunction

    function automatic signal_pkg::data_t rv32i_add (input logic [4:0] rd, rs1, rs2);
        rv32i_add  = enc_r(7'b0000000, rs2, rs1, 3'b000, rd, 7'b0110011);
    endfunction

    function automatic signal_pkg::data_t rv32i_sub (input logic [4:0] rd, rs1, rs2);
        rv32i_sub  = enc_r(7'b0100000, rs2, rs1, 3'b000, rd, 7'b0110011);
    endfunction

    function automatic signal_pkg::data_t rv32i_sll (input logic [4:0] rd, rs1, rs2);
        rv32i_sll = enc_r(7'b0000000, rs2, rs1, 3'b001, rd, 7'b0110011);
    endfunction

    function automatic signal_pkg::data_t rv32i_slt (input logic [4:0] rd, rs1, rs2);
        rv32i_slt  = enc_r(7'b0000000, rs2, rs1, 3'b010, rd, 7'b0110011);
    endfunction

    function automatic signal_pkg::data_t rv32i_sltu (input logic [4:0] rd, rs1, rs2);
        rv32i_sltu  = enc_r(7'b0000000, rs2, rs1, 3'b011, rd, 7'b0110011);
    endfunction

    function automatic signal_pkg::data_t rv32i_xor (input logic [4:0] rd, rs1, rs2);
        rv32i_xor  = enc_r(7'b0000000, rs2, rs1, 3'b100, rd, 7'b0110011);
    endfunction

    function automatic signal_pkg::data_t rv32i_srl (input logic [4:0] rd, rs1, rs2);
        rv32i_srl  = enc_r(7'b0000000, rs2, rs1, 3'b101, rd, 7'b0110011);
    endfunction

    function automatic signal_pkg::data_t rv32i_or  (input logic [4:0] rd, rs1, rs2);
        rv32i_or   = enc_r(7'b0000000, rs2, rs1, 3'b110, rd, 7'b0110011);
    endfunction

    function automatic signal_pkg::data_t rv32i_and (input logic [4:0] rd, rs1, rs2);
        rv32i_and  = enc_r(7'b0000000, rs2, rs1, 3'b111, rd, 7'b0110011);
    endfunction

    //  --------------------------------- Branch Instructions -------------------------------------

    function automatic signal_pkg::data_t rv32i_beq (input logic[4:0] rs1, rs2, input logic[12:0] offset);
        rv32i_beq = enc_b(offset, rs2, rs1, 3'b000, 7'b1100011);
    endfunction

    function automatic signal_pkg::data_t rv32i_bne (input logic[4:0] rs1, rs2, input logic[12:0] offset);
        rv32i_bne = enc_b(offset, rs2, rs1, 3'b001, 7'b1100011);
    endfunction

    function automatic signal_pkg::data_t rv32i_blt (input logic[4:0] rs1, rs2, input logic[12:0] offset);
        rv32i_blt = enc_b(offset, rs2, rs1, 3'b100, 7'b1100011);
    endfunction

    function automatic signal_pkg::data_t rv32i_bge (input logic[4:0] rs1, rs2, input logic[12:0] offset);
        rv32i_bge = enc_b(offset, rs2, rs1, 3'b101, 7'b1100011);
    endfunction

    function automatic signal_pkg::data_t rv32i_bltu (input logic[4:0] rs1, rs2, input logic[12:0] offset);
        rv32i_bltu = enc_b(offset, rs2, rs1, 3'b110, 7'b1100011);
    endfunction

    function automatic signal_pkg::data_t rv32i_bgeu (input logic[4:0] rs1, rs2, input logic[12:0] offset);
        rv32i_bgeu = enc_b(offset, rs2, rs1, 3'b111, 7'b1100011);
    endfunction

    // --------------------------------- Jump Instructions ----------------------------------------

    function automatic signal_pkg::data_t rv32i_jal (input logic[4:0] rd, input logic [20:0] offset);
        rv32i_jal = enc_j(offset, rd, 7'b1101111);
    endfunction

    function automatic signal_pkg::data_t rv32i_lui (input logic [4:0] rd, input logic [19:0] imm);
        rv32i_lui  = enc_u(imm, rd, 7'b0110111);
    endfunction

    function automatic signal_pkg::data_t rv32i_auipc (input logic [4:0] rd, input logic [19:0] imm);
        rv32i_auipc  = enc_u(imm, rd, 7'b0010111);
    endfunction

    //  ------------------------------- Memory Instructions ---------------------------------------

    function automatic signal_pkg::data_t rv32i_lw  (input logic [4:0] rd, rs1, input logic [11:0] imm);
        rv32i_lw   = enc_i(imm, rs1, 3'b010, rd, 7'b0000011);
    endfunction

    function automatic signal_pkg::data_t rv32i_sw  (input logic [4:0] rs2, rs1, input logic [11:0] imm);
        rv32i_sw   = enc_s(imm, rs2, rs1, 3'b010, 7'b0100011);
    endfunction

    // -------------------------------- MULDIV Instructions ---------------------------------------

    function automatic signal_pkg::data_t rv32m_mul (input logic [4:0] rd, rs1, rs2);
        rv32m_mul  = enc_r(7'b0000001, rs2, rs1, 3'b000, rd, 7'b0110011);11
    endfunction

    function automatic signal_pkg::data_t rv32m_mulh (input logic [4:0] rd, rs1, rs2);
        rv32m_mulh  = enc_r(7'b0000001, rs2, rs1, 3'b001, rd, 7'b0110011);
    endfunction

    function automatic signal_pkg::data_t rv32m_mulhsu (input logic [4:0] rd, rs1, rs2);
        rv32m_mulhsu  = enc_r(7'b0000001, rs2, rs1, 3'b010, rd, 7'b0110011);
    endfunction

    function automatic signal_pkg::data_t rv32m_mulhu (input logic [4:0] rd, rs1, rs2);
        rv32m_mulhu  = enc_r(7'b0000001, rs2, rs1, 3'b011, rd, 7'b0110011);
    endfunction

    function automatic signal_pkg::data_t rv32m_div (input logic [4:0] rd, rs1, rs2);
        rv32m_div  = enc_r(7'b0000001, rs2, rs1, 3'b100, rd, 7'b0110011);
    endfunction

    function automatic signal_pkg::data_t rv32m_divu (input logic [4:0] rd, rs1, rs2);
        rv32m_divu  = enc_r(7'b0000001, rs2, rs1, 3'b101, rd, 7'b0110011);
    endfunction

    function automatic signal_pkg::data_t rv32m_rem (input logic [4:0] rd, rs1, rs2);
        rv32m_rem  = enc_r(7'b0000001, rs2, rs1, 3'b110, rd, 7'b0110011);
    endfunction

    function automatic signal_pkg::data_t rv32m_remu (input logic [4:0] rd, rs1, rs2);
        rv32m_remu  = enc_r(7'b0000001, rs2, rs1, 3'b111, rd, 7'b0110011);
    endfunction

    // --------------------- Vector - Vector Instructions -----------------------------------------

    function automatic signal_pkg::data_t rv32v_vadd_vv (input logic[4:0] vd, vs1, vs2);
        rv32v_vadd_vv = enc_valu(6'b000000, 1'b0, vs2, vs1, 3'b000, vd, 7'b1010111);
    endfunction

    function automatic signal_pkg::data_t rv32v_vsub_vv (input logic[4:0] vd, vs1, vs2);
        rv32v_vsub_vv = enc_valu(6'b000010, 1'b0, vs2, vs1, 3'b000, vd, 7'b1010111);
    endfunction

    function automatic signal_pkg::data_t rv32v_vand_vv (input logic[4:0] vd, vs1, vs2);
        rv32v_vand_vv = enc_valu(6'b001001, 1'b0, vs2, vs1, 3'b000, vd, 7'b1010111);
    endfunction

    function automatic signal_pkg::data_t rv32v_vor_vv (input logic[4:0] vd, vs1, vs2);
        rv32v_vor_vv = enc_valu(6'b001010, 1'b0, vs2, vs1, 3'b000, vd, 7'b1010111);
    endfunction

    function automatic signal_pkg::data_t rv32v_vxor_vv (input logic[4:0] vd, vs1, vs2);
        rv32v_vxor_vv = enc_valu(6'b001011, 1'b0, vs2, vs1, 3'b000, vd, 7'b1010111);
    endfunction

    //  ----------------------- Vector - Scalar Instructions --------------------------------------

    function automatic signal_pkg::data_t rv32v_vadd_vx (input logic[4:0] vd, rs1, vs2);
        rv32v_vadd_vx = enc_valu(6'b000000, 1'b0, vs2, rs1, 3'b100, vd, 7'b1010111);
    endfunction

    function automatic signal_pkg::data_t rv32v_vsub_vx (input logic[4:0] vd, rs1, vs2);
        rv32v_vsub_vx = enc_valu(6'b000010, 1'b0, vs2, rs1, 3'b100, vd, 7'b1010111);
    endfunction

    function automatic signal_pkg::data_t rv32v_vand_vx (input logic[4:0] vd, rs1, vs2);
        rv32v_vand_vx = enc_valu(6'b001001, 1'b0, vs2, rs1, 3'b100, vd, 7'b1010111);
    endfunction

    function automatic signal_pkg::data_t rv32v_vor_vx (input logic[4:0] vd, rs1, vs2);
        rv32v_vor_vx = enc_valu(6'b001010, 1'b0, vs2, rs1, 3'b100, vd, 7'b1010111);
    endfunction

    function automatic signal_pkg::data_t rv32v_vxor_vx (input logic[4:0] vd, rs1, vs2);
        rv32v_vxor_vx = enc_valu(6'b001011, 1'b0, vs2, rs1, 3'b100, vd, 7'b1010111);
    endfunction

    function automatic signal_pkg::data_t rv32v_vrsub_vx (input logic[4:0] vd, rs1, vs2);
        rv32v_vrsub_vx = enc_valu(6'b000011, 1'b0, vs2, rs1, 3'b100, vd, 7'b1010111);
    endfunction

    //  -------------------------- Vector Memory Instructions -------------------------------------

    function automatic signal_pkg::data_t rv32v_vle32_v (input logic[4:0] rs1, vd);
        rv32v_vle32_v = enc_vls(12'b000000000000, rs1, 3'b110, vd, 7'b0000111);
    endfunction

    function automatic signal_pkg::data_t rv32v_vse32_v (input logic[4:0] rs1, vs1);
        rv32v_vse32_v = enc_vls(12'b000000000000, rs1, 3'b110, vs1, 7'b0100111);
    endfunction

    // ---------------------------------- Terminate -----------------------------------------------

    function automatic signal_pkg::data_t terminate();
        // ecall in RISC-V standard, but used as a terminate instruction for the DUT
        //  fe_fetch detects opcode 1110011 and halts; the C++ model breaks on (raw & 0x7F) == 0x73
        terminate = top_tb_config_pkg::TERMINATE;
    endfunction

endpackage : pkg_instruction