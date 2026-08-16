//  -------------------------------------------------------------------------------------------
    //                                  RV32 Instruction encoding
    //  -------------------------------------------------------------------------------------------

    protected function signal_pkg::data_t enc_r(
        input logic [6:0] funct7,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [4:0] rd,
        input logic [6:0] opcode
    );
        enc_r = {funct7, rs2, rs1, funct3, rd, opcode};

    endfunction : enc_r

    protected function signal_pkg::data_t enc_i(
        input logic [11:0] imm,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [4:0] rd,
        input logic [6:0] opcode
    );
        enc_i = {imm, rs1, funct3, rd, opcode};

    endfunction : enc_i

    protected function signal_pkg::data_t enc_s(
        input logic [11:0] imm, 
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [6:0] opcode
    );
        enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    endfunction : enc_s

    protected function signal_pkg::data_t enc_u(
        input logic [19:0] imm,
        input logic [4:0] rd,
        input logic [6:0] opcode
    );
        enc_u = {imm, rd, opcode};

    endfunction : enc_u

    protected function signal_pkg::data_t enc_b(
        input logic [12:0] imm,
        input logic [4:0] rs2,
        input logic [4:0] rs1,
        input logic [2:0] funct3,
        input logic [6:0] opcode
    );
        enc_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};

    endfunction : enc_b

    protected function signal_pkg::data_t enc_j(
        input logic [20:0] imm,
        input logic [4:0] rd,
        input logic [6:0] opcode
    );
        enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};

    endfunction : enc_j

    protected function signal_pkg::data_t enc_valu(
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

    protected function signal_pkg::data_t enc_vls(
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