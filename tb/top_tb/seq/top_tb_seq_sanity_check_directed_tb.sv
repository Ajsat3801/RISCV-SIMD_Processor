import pkg_instruction::*;

class top_tb_seq_sanity_check_directed_tb extends top_tb_seq_program_base;

    `uvm_object_utils(top_tb_seq_sanity_check_directed_tb)

    function new(string name = "top_tb_seq_sanity_check_directed_tb");
        super.new(name);
    endfunction : new

    virtual function void build_program();

        signal_pkg::data_t prog[$];
        dmem_preload = new[7];
        sc_prf_preload = new[3];
        vc_prf_preload = new[3];

        dmem_preload[0] = {    32'd3,    32'd2,    32'd1,    32'd0};
        dmem_preload[1] = {    32'd7,    32'd6,    32'd5,    32'd4};
        dmem_preload[2] = {  32'd627,   -32'd7,    32'd4,   32'd15};
        dmem_preload[3] = {    32'd3, -32'd785,  32'd814, -32'd387};
        dmem_preload[4] = {    32'd4,    32'd3,    32'd2,    32'd1};
        dmem_preload[5] = {    32'd0,    32'd0,    32'd0,    32'd0};
        dmem_preload[6] = {   32'd40,   32'd30,   32'd20,   32'd10};

        sc_prf_preload[0] = 32'd0;
        sc_prf_preload[1] = 32'd1;
        sc_prf_preload[2] = 32'd2;

        vc_prf_preload[0] = {4{32'd0}};
        vc_prf_preload[1] = {4{32'd1}};
        vc_prf_preload[2] = {4{32'd2}};

        // test loads
        prog.push_back( rv32i_lw(1, 0, 8) );            // lw       r1  8   (r0)    R1  becomes 15
        prog.push_back( rv32i_lw(2, 0, 9) );            // lw       r2  9   (r0)    R2  becomes 4
        prog.push_back( rv32i_lw(3, 0, 10) );           // lw       r3  10  (r0)    R3  becomes -7
        prog.push_back( rv32i_lw(4, 1, 0) );            // lw       r4  0   (r1)    R4  becomes 3

        // test arithmetic ops + loads in between
        prog.push_back( rv32i_add(7, 1, 2) );           // add 	    r7	r1	r2      R7  becomes 19
        prog.push_back( rv32i_sub(8, 1, 2) );           // sub 	    r8	r1	r2      R8  becomes 11
        prog.push_back( rv32i_addi(9, 8, 5) );          // addi	    r9	r8	5       R9  becomes 16
        prog.push_back( rv32i_lw(10, 8, 0) );           // lw       r10 0   (r8)    R10 becomes 627
        prog.push_back( rv32i_lw(11, 1, -1) );          // lw       r11 -1  (r1)    R11 becomes -785
        prog.push_back( rv32m_mul(12, 10, 11) );        // mul      r12	r10	r11     R12 becomes -492195
        prog.push_back( rv32m_mulh(13, 10, 11) );       // mulh	    r13	r10	r11     R13 becomes -1
        prog.push_back( rv32m_mulhu(14, 10, 11) );      // mulhu	r14	r10	r11     R14 becomes 626
        prog.push_back( rv32m_mulhsu(15, 11, 10) );     // mulhsu   r15 r11	r10     R15 becomes -1
        prog.push_back( rv32i_andi(16, 15, 8) );        // andi	    r16	r15	8       R16 becomes 8
        prog.push_back( rv32i_slli(17, 2, 2) );         // slli	    r17	r2	2       R17 becomes 16
        prog.push_back( rv32i_srli(18, 17, 1) );        // srli	    r18	r17	1       R18 becomes 8
        prog.push_back( rv32m_div(19, 1, 4) );          // div 	    r19	r1	r4      R19 becomes 5
        prog.push_back( rv32m_divu(20, 1, 4) );         // divu	    r20	r1	r4      R20 becomes 5
        prog.push_back( rv32m_rem(21, 1, 4) );          // rem 	    r21	r1	r4      R21 becomes 0
        prog.push_back( rv32m_div(22, 3, 4) );          // div 	    r22	r3	r4      R22 becomes -2
        prog.push_back( rv32m_remu(23, 3, 4) );         // remu	    r23	r3	r4      R23 becomes 0
        prog.push_back( rv32m_rem(24, 3, 4) );          // rem 	    r24	r3	r4      R24 becomes 1
        prog.push_back( rv32i_slt(25, 3, 1) );          // slt  	r25	r3	r1      R25 becomes 1
        prog.push_back( rv32i_xori(26, 9, 7) );         // xori	    r26	r9	7       R26 becomes 23
        prog.push_back( rv32i_sltu(27, 1, 2) );         // sltu	    r27	r1	r2      R27 becomes 0
        prog.push_back( rv32i_ori(28, 26, 31) );        // ori 	    r28	r26	31      R28 becomes 31
        prog.push_back( rv32i_slti(29, 3, 0) );         // slti	    r29	r3	0       R29 becomes 1
        prog.push_back( rv32i_sltiu(30, 3, 1) );        // sltiu	r30	r3	1       R30 becomes 0
        prog.push_back( rv32m_mul(31, 1, 2) );          // mul  	r31	r1	r2      R31 becomes 60
        prog.push_back( rv32i_add(25, 10, 11) );        // add      r25 r10 r11     R25 becomes -158

        // tests overloading of PRF
        prog.push_back( rv32m_div(27, 17, 15) );        // div      r27 r17 r15     R27 becomes -16
        prog.push_back( rv32i_sub(29, 10, 11) );        // sub      r29 r10 r11     R29 becomes 1412

        // tests stores
        prog.push_back( rv32i_sw(26, 0, 20) );          // sw       r26 20  (r0)    mem(20) becomes 23
        prog.push_back( rv32i_sw(6, 26, -2) );          // sw       r6  -2  (r26)   mem(21) becomes 126976
        prog.push_back( rv32i_sw(8, 27, 38) );          // sw       r8  38  (r27)   mem(22) becomes 11
        prog.push_back( rv32i_sw(27, 26, 0) );          // sw       r27 0   (r26)   mem(23) becomes -16

        // test vector ops
        prog.push_back( rv32v_vle32_v(17, 1) );         // vle32    v1	r17         V1  becomes [ 1,  2,  3,  4]
        prog.push_back( rv32i_addi(26, 26, 1) );        // addi     r26 r26 1       R26 becomes 24
        prog.push_back( rv32v_vle32_v(26, 2) );         // V2  becomes [10, 20, 30, 40]

        prog.push_back( rv32v_vadd_vv(3, 1, 2) );       // V3  becomes [11, 22, 33, 44]
        prog.push_back( rv32v_vsub_vv(4, 1, 2) );       // V4  becomes [ 9, 18, 27, 36]
        prog.push_back( rv32v_vand_vv(5, 1, 2) );       // V5  becomes [ 0,  0,  2,  0]
        prog.push_back( rv32v_vor_vv(6, 1, 2) );        // V6  becomes [11, 22, 31, 44]
        prog.push_back( rv32v_vxor_vv(7, 1, 2) );       // V7  becomes [11, 22, 29, 44]
     // prog.push_back( rv32v_vrsub_vv(8, 1, 2) );      // V8  becomes [-9, -18, -27, -36]  <-- see note 3

        prog.push_back( rv32v_vadd_vx(9, 2, 1) );       // V9  becomes [ 5,  6,  7,  8]
        prog.push_back( rv32v_vsub_vx(10, 2, 1) );      // V10 becomes [-3, -2, -1,  0]
        prog.push_back( rv32v_vand_vx(11, 2, 1) );      // V11 becomes [ 0,  0,  0,  4]
        prog.push_back( rv32v_vor_vx(12, 2, 1) );       // V12 becomes [ 5,  6,  7,  4]
        prog.push_back( rv32v_vxor_vx(13, 2, 1) );      // V13 becomes [ 5,  6,  7,  0]
        prog.push_back( rv32v_vrsub_vx(14, 2, 1) );     // V14 becomes [ 3,  2,  1,  0]

        prog.push_back( rv32i_addi(28, 28, 1) );        // R28 becomes 32
        prog.push_back( rv32v_vse32_v(28, 3) );         // mem(32) becomes V3

        // tests branches (all are taken; if R30 is 0, everything passed)
        prog.push_back( rv32i_beq(16, 18, 2) );         // skips next instruction
        prog.push_back( rv32i_addi(30, 0, 12'h111) );   // R30 becomes 0x111 (error)

        prog.push_back( rv32i_bne(1, 2, 2) );           // skips next instruction
        prog.push_back( rv32i_addi(30, 0, 12'h112) );   // R30 becomes 0x112 (error)

        prog.push_back( rv32i_blt(2, 1, 2) );           // skips next instruction
        prog.push_back( rv32i_addi(30, 0, 12'h113) );   // R30 becomes 0x113 (error)

        prog.push_back( rv32i_bge(1, 2, 2) );           // skips next instruction
        prog.push_back( rv32i_addi(30, 0, 12'h114) );   // R30 becomes 0x114 (error)

        prog.push_back( rv32i_bltu(2, 1, 2) );          // skips next instruction
        prog.push_back( rv32i_addi(30, 0, 12'h115) );   // R30 becomes 0x115 (error)

        prog.push_back( rv32i_bgeu(1, 2, 2) );          // skips next instruction
        prog.push_back( rv32i_addi(30, 0, 12'h116) );   // R30 becomes 0x116 (error)

        prog.push_back( rv32i_addi(31, 0, 31) );        // R31 becomes 31
        prog.push_back( rv32i_jal(21, 2) );             // skips the ecall below
        prog.push_back( terminate() );                  // ecall (never reached)

        prog.push_back( rv32i_addi(31, 0, -1) );        // R31 becomes -1, last instruction retired
        prog.push_back( terminate() );                  // ecall (terminate)

        //  ---------------------------------------------------------------------------------------

        imem_preload = new[prog.size()];
        foreach(prog[i]) imem_preload[i] = prog[i];

    endfunction : build_program


endclass : top_tb_seq_sanity_check_directed_tb

