protected function signal_pkg::data_t rv32m_mul (input logic [4:0] rd, rs1, rs2);
        rv32m_mul  = enc_r(7'b0000001, rs2, rs1, 3'b000, rd, 7'b0110011);
    endfunction

    protected function signal_pkg::data_t rv32m_mulh (input logic [4:0] rd, rs1, rs2);
        rv32m_mulh  = enc_r(7'b0000001, rs2, rs1, 3'b001, rd, 7'b0110011);
    endfunction

    protected function signal_pkg::data_t rv32m_mulhsu (input logic [4:0] rd, rs1, rs2);
        rv32m_mulhsu  = enc_r(7'b0000001, rs2, rs1, 3'b010, rd, 7'b0110011);
    endfunction

    protected function signal_pkg::data_t rv32m_mulhu (input logic [4:0] rd, rs1, rs2);
        rv32m_mulhu  = enc_r(7'b0000001, rs2, rs1, 3'b011, rd, 7'b0110011);
    endfunction

    protected function signal_pkg::data_t rv32m_div (input logic [4:0] rd, rs1, rs2);
        rv32m_div  = enc_r(7'b0000001, rs2, rs1, 3'b100, rd, 7'b0110011);
    endfunction

    protected function signal_pkg::data_t rv32m_divu (input logic [4:0] rd, rs1, rs2);
        rv32m_divu  = enc_r(7'b0000001, rs2, rs1, 3'b101, rd, 7'b0110011);
    endfunction

    protected function signal_pkg::data_t rv32m_rem (input logic [4:0] rd, rs1, rs2);
        rv32m_rem  = enc_r(7'b0000001, rs2, rs1, 3'b110, rd, 7'b0110011);
    endfunction

    protected function signal_pkg::data_t rv32m_remu (input logic [4:0] rd, rs1, rs2);
        rv32m_remu  = enc_r(7'b0000001, rs2, rs1, 3'b111, rd, 7'b0110011);
    endfunction