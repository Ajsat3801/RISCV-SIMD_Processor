
    task automatic display_fetch_states();
        $display("[FETCH] IN:[PC:%0d (%b %b)], BR:[%b %b %b %0d] OUT:[%b @ %b - %0d]",
            dut.u_core.u_fetch.imem_req_o.address,
            dut.u_core.u_fetch.compute_i,
            dut.u_core.u_fetch.ready_i,
            dut.u_core.u_fetch.retire_instr_i.valid,
            dut.u_core.u_fetch.retire_instr_i.is_branch,
            dut.u_core.u_fetch.retire_instr_i.branch_taken,
            dut.u_core.u_fetch.retire_instr_i.data,
            dut.u_core.u_fetch.fetch_valid_o,
            dut.u_core.u_fetch.fetched_instr_o,
            dut.u_core.u_fetch.fetched_pc_o
        );
    endtask

    task automatic display_decode_states();
        $display("[DECODE] (%b %b %b)in:[%b @ %0d for %0d (%0d, %0d %0d %0d)]\thold: [%b %0d (%0d, %0d %0d %0d)]\tstates: [%b %b %b]\tout: [%b %0d (%0d, %0d %0d %0d)]",
            
            dut.u_core.u_decode.fetch_valid_i,
            dut.u_core.u_decode.hold_en,
            dut.u_core.u_decode.queue_ready_i,
            
            dut.u_core.u_decode.input_instr.valid,
            dut.u_core.u_decode.fetched_pc_i,
            dut.u_core.u_decode.input_instr.chip_select, 
            dut.u_core.u_decode.input_instr.operation,
            dut.u_core.u_decode.input_instr.dest_address, 
            dut.u_core.u_decode.input_instr.src1_address, 
            dut.u_core.u_decode.input_instr.src2_address,

            dut.u_core.u_decode.hold_instr.valid,
            dut.u_core.u_decode.hold_instr.chip_select, 
            dut.u_core.u_decode.hold_instr.operation,
            dut.u_core.u_decode.hold_instr.dest_address, 
            dut.u_core.u_decode.hold_instr.src1_address, 
            dut.u_core.u_decode.hold_instr.src2_address,

            dut.u_core.u_decode.in_to_out,
            dut.u_core.u_decode.hold_to_out,
            dut.u_core.u_decode.in_to_hold,

            dut.u_core.u_decode.decoded_instr_o.valid,
            dut.u_core.u_decode.decoded_instr_o.chip_select, 
            dut.u_core.u_decode.decoded_instr_o.operation,
            dut.u_core.u_decode.decoded_instr_o.dest_address, 
            dut.u_core.u_decode.decoded_instr_o.src1_address, 
            dut.u_core.u_decode.decoded_instr_o.src2_address,

        );
        /*
        $display("[DECODE] in: [%b %b %b] out[(%b - %b %0d (%0d, %0d %0d %0d) - %b]",
            dut.u_core.u_decode.fetch_valid_i,
            dut.u_core.u_decode.fetched_instr_i,

            dut.u_core.u_decode.queue_ready_i,

            dut.u_core.u_decode.decoded_instr_en_o,


            dut.u_core.u_decode.decoded_instr_o.valid,
            dut.u_core.u_decode.decoded_instr_o.chip_select, 
            dut.u_core.u_decode.decoded_instr_o.operation,
            dut.u_core.u_decode.decoded_instr_o.dest_address, 
            dut.u_core.u_decode.decoded_instr_o.src1_address, 
            dut.u_core.u_decode.decoded_instr_o.src2_address,
            dut.u_core.u_decode.decode_ready_o
        );*/
    endtask

    task automatic display_queue_states();
        $display("[QUEUE] IN:[%b %0d (%0d, %0d %0d %0d)] \tflags[%b %b %b (%0d)] \trdy_i:[%b %b] \tQ:[%b %0d %b %0d] \tOut:[%b %0d (%0d, %0d %0d %0d)] \trdy_o:[%b %b]",
            
            dut.u_core.u_instr_q.in_valid,
            dut.u_core.u_decode.decoded_instr_o.chip_select, 
            dut.u_core.u_decode.decoded_instr_o.operation,
            dut.u_core.u_decode.decoded_instr_o.dest_address, 
            dut.u_core.u_decode.decoded_instr_o.src1_address, 
            dut.u_core.u_decode.decoded_instr_o.src2_address,

            dut.u_core.u_instr_q.enqueue,
            dut.u_core.u_instr_q.dequeue,
            dut.u_core.u_instr_q.rs_empty[dut.u_core.u_instr_q.rs_index],
            dut.u_core.u_instr_q.rs_index,

            !dut.u_core.u_instr_q.rob_full_i,
            !dut.u_core.u_instr_q.arr_full_i,

            /*dut.u_core.u_instr_q.instr_fifo[dut.u_core.u_instr_q.head.address].valid,
            dut.u_core.u_instr_q.instr_fifo[dut.u_core.u_instr_q.head.address].chip_select, 
            dut.u_core.u_instr_q.instr_fifo[dut.u_core.u_instr_q.head.address].operation,
            dut.u_core.u_instr_q.instr_fifo[dut.u_core.u_instr_q.head.address].dest_address, 
            dut.u_core.u_instr_q.instr_fifo[dut.u_core.u_instr_q.head.address].src1_address, 
            dut.u_core.u_instr_q.instr_fifo[dut.u_core.u_instr_q.head.address].src2_address, */

            dut.u_core.u_instr_q.head.epoch,
            dut.u_core.u_instr_q.head.address,
            dut.u_core.u_instr_q.tail.epoch,
            dut.u_core.u_instr_q.tail.address,

            dut.u_core.u_instr_q.dispatched_instr_o.valid,
            dut.u_core.u_instr_q.dispatched_instr_o.chip_select, 
            dut.u_core.u_instr_q.dispatched_instr_o.operation,
            dut.u_core.u_instr_q.dispatched_instr_o.dest_address, 
            dut.u_core.u_instr_q.dispatched_instr_o.src1_address, 
            dut.u_core.u_instr_q.dispatched_instr_o.src2_address, 

            dut.u_core.u_instr_q.queue_ready_o,
            dut.u_core.u_instr_q.full
        );
    endtask