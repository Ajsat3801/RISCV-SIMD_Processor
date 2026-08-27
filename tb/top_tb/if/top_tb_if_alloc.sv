
interface top_tb_if_alloc(input logic clk_i);

    function automatic top_tb_typedef_pkg::alloc_snapshot_t sample();

        sample.valid    = dut.u_core.u_alloc_bus.valid;
        sample.sc_valid = dut.u_core.u_alloc_bus.sc_valid;
        sample.vc_valid = dut.u_core.u_alloc_bus.vc_valid;

        sample.rob_id  = dut.u_core.u_alloc_bus.rob_id;
        sample.prf_tag = dut.u_core.u_alloc_bus.prf_tag;

        sample.chip_select = dut.u_core.u_alloc_bus.instr.chip_select;
        sample.operation   = dut.u_core.u_alloc_bus.instr.operation;

        sample.dest_address = dut.u_core.u_alloc_bus.instr.dest_address;
        sample.src1_address = dut.u_core.u_alloc_bus.instr.src1_address;
        sample.src2_address = dut.u_core.u_alloc_bus.instr.src2_address;

        sample.imm    = dut.u_core.u_alloc_bus.instr.imm;
        sample.extend = dut.u_core.u_alloc_bus.instr.extend;

        sample.write_to_reg = dut.u_core.u_alloc_bus.instr.write_to_reg;
        sample.pre_calc     = dut.u_core.u_alloc_bus.instr.pre_calc;
        sample.is_branch    = dut.u_core.u_alloc_bus.instr.is_branch;
        sample.read_src2    = dut.u_core.u_alloc_bus.instr.read_src2;
        sample.src1_vector  = dut.u_core.u_alloc_bus.instr.src1_vector;
        sample.src2_vector  = dut.u_core.u_alloc_bus.instr.src2_vector;

        sample.a_is_vector = dut.u_core.u_alloc_bus.a_is_vector;
        sample.b_is_vector = dut.u_core.u_alloc_bus.b_is_vector;

    endfunction : sample

endinterface : top_tb_if_alloc