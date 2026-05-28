
    task automatic display_sc_wb();
        $display("[SC_WB] in[%b %0d | %b  %0d | %b %0d | %b %0d], out[%b %0d %h]",
            dut.u_core.u_scalar_writeback.ex_result_i[0].valid, dut.u_core.u_scalar_writeback.ex_result_i[0].prf_tag, 
            dut.u_core.u_scalar_writeback.ex_result_i[1].valid, dut.u_core.u_scalar_writeback.ex_result_i[1].prf_tag,
            dut.u_core.u_scalar_writeback.ex_result_i[2].valid, dut.u_core.u_scalar_writeback.ex_result_i[2].prf_tag, 
            dut.u_core.u_scalar_writeback.ex_result_i[3].valid, dut.u_core.u_scalar_writeback.ex_result_i[3].prf_tag,
            dut.u_core.u_scalar_writeback.data_bus_o.valid,
            dut.u_core.u_scalar_writeback.data_bus_o.prf_tag,
            dut.u_core.u_scalar_writeback.data_bus_o.data
        );
    endtask

    task automatic display_vc_wb();
        $display("[VC_WB] in[(%b %0d)(%b %0d)(%d %0d)], out[%b %0d (%0d %0d %0d %0d)]",
            
            dut.u_core.u_vector_writeback.ex_result_i[0].valid,
            dut.u_core.u_vector_writeback.ex_result_i[0].prf_tag,
            dut.u_core.u_vector_writeback.ex_result_i[1].valid,
            dut.u_core.u_vector_writeback.ex_result_i[1].prf_tag,
            dut.u_core.u_vector_writeback.lsu_result_i.valid,
            dut.u_core.u_vector_writeback.lsu_result_i.prf_tag,

            dut.u_core.u_vector_writeback.data_bus_o.valid,
            dut.u_core.u_vector_writeback.data_bus_o.prf_tag,
            $signed(dut.u_core.u_vector_writeback.data_bus_o.data[0]),
            $signed(dut.u_core.u_vector_writeback.data_bus_o.data[1]),
            $signed(dut.u_core.u_vector_writeback.data_bus_o.data[2]),
            $signed(dut.u_core.u_vector_writeback.data_bus_o.data[3]),
        );
    endtask