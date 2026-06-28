
    task automatic display_dmem_inout();
        $display("[DMEM] in:[%b %0d %h ] %h", 
            dut.u_dmem.dmem_request_i.write_enable, 
            dut.u_dmem.dmem_request_i.address, 
            dut.u_dmem.dmem_request_i.data,
            dut.u_dmem.data_o
        );
    endtask

    task automatic display_dmem_val(int base_addr);
        int i = base_addr/4;
        $display("[DMEM val] (For base address %0d) \n[%0d: %h (%0d)]\t[%0d:%h (%0d)]\t[%0d: %h (%0d)]\t[%0d: %h (%0d)]\n", 
            base_addr,
            base_addr + 0, dut.u_dmem.u_dmem0.mem[i][31:0], $signed(dut.u_dmem.u_dmem0.mem[i][31:0]),
            base_addr + 1, dut.u_dmem.u_dmem1.mem[i][31:0], $signed(dut.u_dmem.u_dmem1.mem[i][31:0]),
            base_addr + 2, dut.u_dmem.u_dmem2.mem[i][31:0], $signed(dut.u_dmem.u_dmem2.mem[i][31:0]),
            base_addr + 3, dut.u_dmem.u_dmem3.mem[i][31:0], $signed(dut.u_dmem.u_dmem3.mem[i][31:0]) 
        );

    endtask

    task automatic display_dmem_controller();
        $display("[DMEM CTLR] in [(%b) %h] out [(%b %h | %b %h)]",
            dut.u_core.u_dmem_controller.lsu_output.valid,
            dut.u_core.u_dmem_controller.lsu_output.mem_addr,
            dut.u_core.u_dmem_controller.sc_wb_o.valid,
            dut.u_core.u_dmem_controller.sc_wb_o.data,
            dut.u_core.u_dmem_controller.vc_wb_o.valid,
            dut.u_core.u_dmem_controller.vc_wb_o.data
        );
    endtask