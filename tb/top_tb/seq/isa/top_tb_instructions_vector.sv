protected function signal_pkg::data_t rv32v_vadd_vv (input logic[4:0] vd, vs1, vs2);
        rv32v_vadd_vv = enc_valu(6'b000000, 1'b0, vs2, vs1, 3'b000, vd, 7'b1010111);
    endfunction

    protected function signal_pkg::data_t rv32v_vsub_vv (input logic[4:0] vd, vs1, vs2);
        rv32v_vsub_vv = enc_valu(6'b000010, 1'b0, vs2, vs1, 3'b000, vd, 7'b1010111);
    endfunction

    protected function signal_pkg::data_t rv32v_vand_vv (input logic[4:0] vd, vs1, vs2);
        rv32v_vand_vv = enc_valu(6'b001001, 1'b0, vs2, vs1, 3'b000, vd, 7'b1010111);
    endfunction

    protected function signal_pkg::data_t rv32v_vor_vv (input logic[4:0] vd, vs1, vs2);
        rv32v_vor_vv = enc_valu(6'b001010, 1'b0, vs2, vs1, 3'b000, vd, 7'b1010111);
    endfunction

    protected function signal_pkg::data_t rv32v_vxor_vv (input logic[4:0] vd, vs1, vs2);
        rv32v_vxor_vv = enc_valu(6'b001011, 1'b0, vs2, vs1, 3'b000, vd, 7'b1010111);
    endfunction

    protected function signal_pkg::data_t rv32v_vadd_vx (input logic[4:0] vd, rs1, vs2);
        rv32v_vadd_vx = enc_valu(6'b000000, 1'b0, vs2, rs1, 3'b100, vd, 7'b1010111);
    endfunction

    protected function signal_pkg::data_t rv32v_vsub_vx (input logic[4:0] vd, rs1, vs2);
        rv32v_vsub_vx = enc_valu(6'b000010, 1'b0, vs2, rs1, 3'b100, vd, 7'b1010111);
    endfunction

    protected function signal_pkg::data_t rv32v_vand_vx (input logic[4:0] vd, rs1, vs2);
        rv32v_vand_vx = enc_valu(6'b001001, 1'b0, vs2, rs1, 3'b100, vd, 7'b1010111);
    endfunction

    protected function signal_pkg::data_t rv32v_vor_vx (input logic[4:0] vd, rs1, vs2);
        rv32v_vor_vx = enc_valu(6'b001010, 1'b0, vs2, rs1, 3'b100, vd, 7'b1010111);
    endfunction

    protected function signal_pkg::data_t rv32v_vxor_vx (input logic[4:0] vd, rs1, vs2);
        rv32v_vxor_vx = enc_valu(6'b001011, 1'b0, vs2, rs1, 3'b100, vd, 7'b1010111);
    endfunction

    protected function signal_pkg::data_t rv32v_vrsub_vx (input logic[4:0] vd, rs1, vs2);
        rv32v_vrsub_vx = enc_valu(6'b000011, 1'b0, vs2, rs1, 3'b100, vd, 7'b1010111);
    endfunction

    protected function signal_pkg::data_t rv32v_vle32_v (input logic[4:0] rs1, vd);
        rv32v_vle32_v = enc_vls(12'b000000000000, rs1, 3'b110, vd, 7'b0000111);
    endfunction

    protected function signal_pkg::data_t rv32v_vse32_v (input logic[4:0] rs1, vs1);
        rv32v_vse32_v = enc_vls(12'b000000000000, rs1, 3'b110, vs1, 7'b0100111);
    endfunction
