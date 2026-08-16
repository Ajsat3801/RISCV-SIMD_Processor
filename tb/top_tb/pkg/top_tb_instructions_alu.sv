protected function signal_pkg::data_t rv32i_addi (input logic [4:0] rd, rs1, input logic [11:0] imm);
        rv32i_addi = enc_i(imm, rs1, 3'b000, rd, 7'b0010011);
    endfunction

    protected function signal_pkg::data_t rv32i_slti (input logic [4:0] rd, rs1, input logic [11:0] imm);
        rv32i_slti = enc_i(imm, rs1, 3'b010, rd, 7'b0010011);
    endfunction

    protected function signal_pkg::data_t rv32i_sltiu (input logic [4:0] rd, rs1, input logic [11:0] imm);
        rv32i_sltiu = enc_i(imm, rs1, 3'b011, rd, 7'b0010011);
    endfunction

    protected function signal_pkg::data_t rv32i_xori (input logic [4:0] rd, rs1, input logic [11:0] imm);
        rv32i_xori = enc_i(imm, rs1, 3'b100, rd, 7'b0010011);
    endfunction

    protected function signal_pkg::data_t rv32i_ori (input logic [4:0] rd, rs1, input logic [11:0] imm);
        rv32i_ori = enc_i(imm, rs1, 3'b110, rd, 7'b0010011);
    endfunction

    protected function signal_pkg::data_t rv32i_andi (input logic [4:0] rd, rs1, input logic [11:0] imm);
        rv32i_andi = enc_i(imm, rs1, 3'b111, rd, 7'b0010011);
    endfunction

    protected function signal_pkg::data_t rv32i_slli (input logic [4:0] rd, rs1, shamt);
        rv32i_slli  = enc_r(7'b0000000, shamt, rs1, 3'b001, rd, 7'b0010011);
    endfunction

    protected function signal_pkg::data_t rv32i_srli (input logic [4:0] rd, rs1, shamt);
        rv32i_srli  = enc_r(7'b0000000, shamt, rs1, 3'b101, rd, 7'b0010011);
    endfunction

    
    protected function signal_pkg::data_t rv32i_add (input logic [4:0] rd, rs1, rs2);
        rv32i_add  = enc_r(7'b0000000, rs2, rs1, 3'b000, rd, 7'b0110011);
    endfunction

    protected function signal_pkg::data_t rv32i_sub (input logic [4:0] rd, rs1, rs2);
        rv32i_sub  = enc_r(7'b0100000, rs2, rs1, 3'b000, rd, 7'b0110011);
    endfunction

    protected function signal_pkg::data_t rv32i_sll (input logic [4:0] rd, rs1, rs2);
        rv32i_sll = enc_r(7'b0000000, rs2, rs1, 3'b001, rd, 7'b0110011);
    endfunction

    protected function signal_pkg::data_t rv32i_slt (input logic [4:0] rd, rs1, rs2);
        rv32i_slt  = enc_r(7'b0000000, rs2, rs1, 3'b010, rd, 7'b0110011);
    endfunction

    protected function signal_pkg::data_t rv32i_sltu (input logic [4:0] rd, rs1, rs2);
        rv32i_sltu  = enc_r(7'b0000000, rs2, rs1, 3'b011, rd, 7'b0110011);
    endfunction

    protected function signal_pkg::data_t rv32i_xor (input logic [4:0] rd, rs1, rs2);
        rv32i_xor  = enc_r(7'b0000000, rs2, rs1, 3'b100, rd, 7'b0110011);
    endfunction

    protected function signal_pkg::data_t rv32i_srl (input logic [4:0] rd, rs1, rs2);
        rv32i_srl  = enc_r(7'b0000000, rs2, rs1, 3'b101, rd, 7'b0110011);
    endfunction

    protected function signal_pkg::data_t rv32i_or  (input logic [4:0] rd, rs1, rs2);
        rv32i_or   = enc_r(7'b0000000, rs2, rs1, 3'b110, rd, 7'b0110011);
    endfunction

    protected function signal_pkg::data_t rv32i_and (input logic [4:0] rd, rs1, rs2);
        rv32i_and  = enc_r(7'b0000000, rs2, rs1, 3'b111, rd, 7'b0110011);
    endfunction