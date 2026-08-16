protected function signal_pkg::data_t rv32i_beq (input logic[4:0] rs1, rs2, input logic[12:0] offset);
        rv32i_beq = enc_b(offset, rs2, rs1, 3'b000, 7'b1100011);
    endfunction

    protected function signal_pkg::data_t rv32i_bne (input logic[4:0] rs1, rs2, input logic[12:0] offset);
        rv32i_bne = enc_b(offset, rs2, rs1, 3'b001, 7'b1100011);
    endfunction

    protected function signal_pkg::data_t rv32i_blt (input logic[4:0] rs1, rs2, input logic[12:0] offset);
        rv32i_blt = enc_b(offset, rs2, rs1, 3'b100, 7'b1100011);
    endfunction

    protected function signal_pkg::data_t rv32i_bge (input logic[4:0] rs1, rs2, input logic[12:0] offset);
        rv32i_bge = enc_b(offset, rs2, rs1, 3'b101, 7'b1100011);
    endfunction

    protected function signal_pkg::data_t rv32i_bltu (input logic[4:0] rs1, rs2, input logic[12:0] offset);
        rv32i_bltu = enc_b(offset, rs2, rs1, 3'b110, 7'b1100011);
    endfunction

    protected function signal_pkg::data_t rv32i_bgeu (input logic[4:0] rs1, rs2, input logic[12:0] offset);
        rv32i_bgeu = enc_b(offset, rs2, rs1, 3'b111, 7'b1100011);
    endfunction

    protected function signal_pkg::data_t rv32i_jal (input logic[4:0] rd, input logic [20:0] offset);
        rv32i_jal = enc_j(offset, rd, 7'b1101111);
    endfunction