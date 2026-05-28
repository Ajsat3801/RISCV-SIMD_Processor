
    task automatic display_arr_states();
        $display("[ARR] in[(%b %b) %0d, %0d %0d %0d] out[(%b %b %b) %0d %0d %0d]",
            dut.u_core.u_alloc_rename_retire.sc_alloc_valid,  
            dut.u_core.u_alloc_rename_retire.vc_alloc_valid,
            dut.u_core.u_alloc_rename_retire.dispatched_instr_i.chip_select,
            dut.u_core.u_alloc_rename_retire.dispatched_instr_i.dest_address,
            dut.u_core.u_alloc_rename_retire.dispatched_instr_i.src1_address,
            dut.u_core.u_alloc_rename_retire.dispatched_instr_i.src2_address,
            dut.u_core.u_alloc_rename_retire.alloc_instr_o.sc_valid,
            dut.u_core.u_alloc_rename_retire.alloc_instr_o.vc_valid,
            dut.u_core.u_alloc_rename_retire.alloc_instr_o.precalc_valid,
            dut.u_core.u_alloc_rename_retire.alloc_instr_o.instr.chip_select,
            dut.u_core.u_alloc_rename_retire.alloc_instr_o.instr.dest_address,
            dut.u_core.u_alloc_rename_retire.alloc_instr_o.prf_tag
        );
    endtask

    task automatic display_arr_states_sc();
        $display("[SC ARR] commit_table  ",
                dut.u_core.u_alloc_rename_retire.alloc_instr_o.sc_valid,
                dut.u_core.u_alloc_rename_retire.alloc_instr_o.rs_slot_id,
                dut.u_core.u_alloc_rename_retire.alloc_instr_o.operand_a_ready,
                dut.u_core.u_alloc_rename_retire.alloc_instr_o.operand_b_ready,
                dut.u_core.u_scalar_alu_rs.rs_request_i.rs_entry.occupied,
                dut.u_core.u_scalar_alu_rs.rs_request_i.rs_slot_id,
                dut.u_core.u_scalar_alu_rs.rs_request_i.rs_entry.operand_a_ready,
                dut.u_core.u_scalar_alu_rs.rs_request_i.rs_entry.operand_b_ready
        );
    endtask

    task automatic display_arr_states_vc();
        $display("[VC ARR] out:[%b @ %0d (%h %h)] [RS] in:[%b @ %0d (%h %h)] ",
                dut.u_core.u_alloc_rename_retire.alloc_instr_o.vc_valid,
                dut.u_core.u_alloc_rename_retire.alloc_instr_o.rs_slot_id,
                dut.u_core.u_alloc_rename_retire.alloc_instr_o.operand_a_ready,
                dut.u_core.u_alloc_rename_retire.alloc_instr_o.operand_b_ready,
                dut.u_core.u_vector_alu_rs.rs_request_i.rs_entry.occupied,
                dut.u_core.u_vector_alu_rs.rs_request_i.rs_slot_id,
                dut.u_core.u_vector_alu_rs.rs_request_i.rs_entry.operand_a_ready,
                dut.u_core.u_vector_alu_rs.rs_request_i.rs_entry.operand_b_ready
        );
    endtask

    task automatic display_rob_states();
        $display("[ROB] alloc[%b %0d]\twb [%b %0d | %b %0d %0d]\thead:(%b) [%0d %0d]\tptrs:[%b %0d | %b %0d](%b)\tretire[%b for %0d (%0d)] rdy[%b]",
            dut.u_core.u_reorder_buffer.alloc_instr_io.valid,
            dut.u_core.u_reorder_buffer.alloc_instr_io.prf_tag,

            dut.u_core.u_reorder_buffer.sc_data_bus_i.valid,
            dut.u_core.u_reorder_buffer.sc_data_bus_i.prf_tag,

            dut.u_core.u_reorder_buffer.vc_data_bus_i.valid,
            dut.u_core.u_reorder_buffer.vc_data_bus_i.prf_tag,
            dut.u_core.u_reorder_buffer.vc_data_bus_i.rob_id.address,

            dut.u_core.u_reorder_buffer.rob_table[dut.u_core.u_reorder_buffer.head.address].ready,
            dut.u_core.u_reorder_buffer.rob_table[dut.u_core.u_reorder_buffer.head.address].dest_address,
            dut.u_core.u_reorder_buffer.rob_table[dut.u_core.u_reorder_buffer.head.address].prf_tag,

            dut.u_core.u_reorder_buffer.head.epoch, dut.u_core.u_reorder_buffer.head.address,
            dut.u_core.u_reorder_buffer.tail.epoch, dut.u_core.u_reorder_buffer.tail.address,
            dut.u_core.u_reorder_buffer.full,

            dut.u_core.u_reorder_buffer.retire_instr_o.valid,
            dut.u_core.u_reorder_buffer.retire_instr_o.dest_address,
            dut.u_core.u_reorder_buffer.retire_instr_o.prf_tag,

            dut.u_core.u_reorder_buffer.rob_full_o
        );
    endtask