    protected function signal_pkg::data_t rv32i_lui (input logic [4:0] rd, input logic [19:0] imm);
        rv32i_lui  = enc_u(imm, rd, 7'b0110111);
    endfunction

    protected function signal_pkg::data_t rv32i_auipc (input logic [4:0] rd, input logic [19:0] imm);
        rv32i_auipc  = enc_u(imm, rd, 7'b0010111);
    endfunction

    protected function signal_pkg::data_t rv32i_lw  (input logic [4:0] rd, rs1, input logic [11:0] imm);
        rv32i_lw   = enc_i(imm, rs1, 3'b010, rd, 7'b0000011);
    endfunction

    protected function signal_pkg::data_t rv32i_sw  (input logic [4:0] rs2, rs1, input logic [11:0] imm);
        rv32i_sw   = enc_s(imm, rs2, rs1, 3'b010, 7'b0100011);
    endfunction

    protected function signal_pkg::data_t terminate();
        // ecall in RISC-V standard, but used as a terminate instruction for the DUT
        //  fe_fetch detects opcode 1110011 and halts; the C++ model breaks on (raw & 0x7F) == 0x73
        terminate = top_tb_config_pkg::TERMINATE;
    endfunction