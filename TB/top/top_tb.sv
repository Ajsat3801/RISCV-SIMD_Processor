// Sanity check testbench for core + imem + dmem
/* KNown issues
   Signed multiplication may not be working
 */

module top_tb;

    logic clk, reset_n;
    logic compute;
    logic imem_preload_en, dmem_preload_en;

    packet_pkg::imem_request_t imem_preload_request;
    packet_pkg::dmem_request_t dmem_preload_request;

    logic sc_prf_preload_en, vc_prf_preload_en;
    signal_pkg::prf_tag_t sc_prf_preload_addr, vc_prf_preload_addr;
    signal_pkg::data_t sc_prf_preload_data;
    signal_pkg::vector_data_t vc_prf_preload_data;

    signal_pkg::arf_address_t prev_dest_address, vc_prev_dest_address;
    signal_pkg::prf_tag_t prev_prf_tag, vc_prev_prf_tag;
    logic prev_retire_sc, prev_retire_vc;

    int cycles;

    signal_pkg::data_t instr_array[];
    signal_pkg::data_t sc_prf_array[];
    signal_pkg::vector_data_t vc_prf_array[];
    signal_pkg::vector_data_t data_array[];

    top dut(
        .clk_i(clk),
        .reset_ni(reset_n),

        .compute_i(compute),

        .imem_preload_en_i(imem_preload_en),
        .preload_imem_request_i(imem_preload_request),

        .dmem_preload_en_i(dmem_preload_en),
        .preload_dmem_request_i(dmem_preload_request),

        .sc_prf_preload_en_i(sc_prf_preload_en),
        .sc_prf_preload_data_i(sc_prf_preload_data),
        .sc_prf_preload_addr_i(sc_prf_preload_addr), 

        .vc_prf_preload_en_i(vc_prf_preload_en),
        .vc_prf_preload_data_i(vc_prf_preload_data),
        .vc_prf_preload_addr_i(vc_prf_preload_addr)
        
    );

    initial begin
        clk = 1'b0;
        #10;
        forever #10 clk = ~clk;
    end

    initial begin
        instr_array = '{ 
            /*
            // tests loads
            32'b00000000100000000010000010000011	,//	lw   	r1	8(R0)	32	R1  becomes 15
            32'b00000000100100000010000100000011	,//	lw  	r2	9(R0)	33	R2  becomes 4
            32'b00000000101000000010000110000011	,//	lw  	r3	10(R0)	34	R3  becomes -7
            32'b00000000000000001010001000000011	,//	lw  	r4	0(R1)	35	R4  becomes 3
            
            // tests arithmetic ops + loads in between
            32'b00000000001000001000001010110011	,//	add 	r5	r1 	r2 	36	R5  becomes 19
            32'b01100000001000001000001100110011	,//	sub 	r6	r1 	r2 	37	R6  becomes 11
            32'b00000000011000101000001110110011	,//	add 	r7	r5	r6 	38	R7  becomes 30
            32'b01100000001000111000010000110011	,//	sub 	r8	r7	r2 	39	R8  becomes 26
            32'b00000000010101000000010010010011	,//	addi	r9	r8	5  	40	R9  becomes 31
            32'b00000000000000110010010100000011	,//	lw  	r10	0(R6)	41	R10 becomes 627
            32'b11111111111100001010010110000011	,//	lw  	r11	-1(15)	42	R11 becomes -785
            32'b00000010101101010000011000110011	,//	mul  	r12	r10	r11	43	R12 becomes -492195
            32'b00000010101101010001011010110011	,//	mulh	r13	r10	r11	44	R13 becomes -1
            32'b00000010101101010011011100110011	,//	mulhu	r14	r10	r11	45	R14 becomes 626
            32'b00000010101001011010011110110011	,//	mulhsu	r15	r11	r10	46	R15 becomes -1
            32'b00000000100001111111100000010011	,//	andi	r16	r15	8	47	R16 becomes 8
            32'b00000000001000010001100010010011	,//	slli	r17	r2	2	48	R17 becomes 16
            32'b00000000000110001101100100010011	,//	srli	r18	r17	1	49	R18 becomes 8
            32'b00000010010000001100100110110011	,//	div 	r19	r1	r4	50	R19 becomes 5
            32'b00000010010000001101101000110011	,//	divu	r20	r1	r4	51	R20 becomes 5
            32'b00000010010000001110101010110011	,//	rem 	r21	r1	r4	52	R21 becomes 0 
            32'b00000010010000011100101100110011	,//	div 	r22	r3	r4	53	R22 becomes -2
            32'b00000010010000011111101110110011	,//	remu	r23	r3	r4	55  R23 becomes 0
            32'b00000010010000011110110000110011	,//	rem 	r24	r3	r4	55	R24 becomes 1
            32'b00000000000100011010110010110011	,//	slt 	r25	r3	r1	56	R25 becomes 1 (x)
            32'b00000000011101001100110100010011	,//	xori	r26	r9	7	57	R26 becomes 24
            32'b00000000001000001011110110110011	,//	sltu	r27	r1	r2	58	R27 becomes 0 (x)
            32'b00000001111111010110111000010011	,//	ori 	r28	r26	31	59	R28 becomes 31
            32'b00000000000000011010111010010011	,//	slti	r29	r3	0	60	R29 becomes 1 (x)
            32'b00000000000100011011111100010011	,//	sltiu	r30	r3	1	61	R30 becomes 0 
            32'b00000010001000001000111110110011	,//	mul  	r31	r1	r2	62	R31 becomes 60
            32'b00000000101101010000110010110011    ,// add     r25 r10 r11 63  R25 becomes -158

            // tests overloading of PRF
            32'b00000010111110001100110110110011    ,// div     r27 r17 r15 1   R27 becomes -16
            32'b01100000101101010000111010110011    ,// sub     r29 r10 r11 2   R26 becomes 1412

            // tests stores
            32'b00000001101000000010100000100011    ,// sw      r26 16(r0)      mem(16) becomes 24
            32'b11111110011000101010111100100011    ,// sw      r6  -2(r5)      mem(17) becomes 11
            32'b00000000100010001010000100100011    ,// sw      r8   2(r17)     mem(18) becomes 26
            32'b00000001101100101010000000100011    ,// sw      r27  0(r5)      mem(19) becomes -16 
            
            // tests branches (all are taken, if R30 is 0, it means everything passed. )

            32'b00000000000100001000001001100011    ,// beq     r18, r16, 2     skips next instruction
            32'b00010001000100000000111100010011    ,// addi    r30, r0, 0x111  R30 becomes 0x111 (error)

            32'b00000000001000001001001001100011    ,// bne     r1, r2, 2       skips next instruction
            32'b00010001001000000000111100010011    ,// addi    r30, r0, 0x112  R30 becomes 0x112 (error)

            32'b00000000000100011100001001100011    ,// blt     r3, r1, 2       skips next instruction
            32'b00010001001100000000111100010011    ,// addi    r30, r0, 0x113  R30 becomes 0x113 (error)
            
            32'b00000000001000001101001001100011    ,// bge     r1, r2, 2       skips next instruction
            32'b00010001010000000000111100010011    ,// addi    r30, r0, 0x114  R30 becomes 0x114 (error)
            
            32'b00000000000100010110001001100011    ,// bltu    r2, r1, 2       skips next instruction
            32'b00010001010100000000111100010011    ,// addi    r30, r0, 0x115  R30 becomes 0x115 (error)

            32'b00000000001000001111001001100011    ,// bgeu    r1, r2, 2       skips next instruction
            32'b00010001011000000000111100010011    ,// addi    r30, r0, 0x116  R30 becomes 0x116 (error)
            */
            32'b00000000001000000000101011101111    ,// jal     r21 1           skips the ecall

            32'b00000000000000000000000001110011    ,//  ecall (terminate)

            32'b00010001010000000000101110010011    ,// addi    r23, r0, 0x114  R23 becomes 0x114 (error)
            32'b00000000000000000000000001110011     //  ecall (terminate)
        };

        data_array = '{
            {    3,    2,    1,    0},
            {    7,    6,    5,    4},
            {  627,   -7,    4,   15},
            {    3, -785,  814, -387}
        };
        sc_prf_array = {32'd1, 32'd2};
        vc_prf_array = {{4{32'd1}},{4{32'd2}}};
    end

    task automatic init();
        cycles  = 0;
        reset_n = 1'b0;
        compute = 1'b0;
        
        imem_preload_en = 1'b0;
        imem_preload_request = '0;

        dmem_preload_en = 1'b0;
        dmem_preload_request = '0;

        sc_prf_preload_en   = 1'b0;
        sc_prf_preload_data = '0;
        sc_prf_preload_addr = '0;

        vc_prf_preload_en   = 1'b0;
        vc_prf_preload_data = '0;
        vc_prf_preload_addr = '0;

        repeat (3) @(posedge clk);
        reset_n = 1'b1;
        repeat (3) @(posedge clk);
    endtask

    task automatic preload_sc_prf();
        int n = 1;
        
        repeat(sc_prf_array.size()) begin
            @(negedge clk);
            sc_prf_preload_en   <= 1'b1;
            sc_prf_preload_addr <= '{vector: 1'b0, tag: signal_pkg::prf_address_t'(n)};
            sc_prf_preload_data <= sc_prf_array[n-1];
            n++;
        end

        @(negedge clk);
        sc_prf_preload_en   <= 1'b0;
        sc_prf_preload_addr <= '0;
        sc_prf_preload_data <= '0;
    endtask
    
    task automatic preload_vc_prf();
        int n = 1;
        
        repeat(vc_prf_array.size()) begin
            @(negedge clk);
            $display("%0d %h",n, vc_prf_array[n-1]);
            vc_prf_preload_en   <= 1'b1;
            vc_prf_preload_addr <= '{vector: 1'b1, tag: signal_pkg::prf_address_t'(n)};
            vc_prf_preload_data <= vc_prf_array[n-1];
            n++;
        end


        @(negedge clk);
        vc_prf_preload_en   <= 1'b0;
        vc_prf_preload_addr <= '0;
        vc_prf_preload_data <= '0;
    endtask

    task automatic preload_imem();
       
        int n = 0;
        
        repeat(instr_array.size()) begin
            @(negedge clk);
            imem_preload_en <= 1'b1;
            imem_preload_request.address <= n;
            imem_preload_request.data    <= instr_array[n];
            imem_preload_request.write_enable <= 1'b1;
            n++;
            
        end
        @(negedge clk);
        imem_preload_en <= 1'b0;
        imem_preload_request <= '0;
    endtask

    task automatic preload_dmem();
       
        int n = 0;
        
        repeat(data_array.size()) begin
            @(negedge clk);
            dmem_preload_en <= 1'b1;
            dmem_preload_request.address <= n;
            dmem_preload_request.data    <= data_array[n];
            dmem_preload_request.write_enable <= 4'b1111;
            n++;
            
        end
        @(negedge clk);
        dmem_preload_en <= 1'b0;
        dmem_preload_request <= '0;
    endtask

    task automatic display_final_prf_state_sc();
        logic match = 1;
        $display("                             FINAL STATE SCALAR PRF");
        for(int i=0; i<32; i+=4) begin
            $display("R%02d: %h (%04d)\t| R%02d: %h (%04d)\t| R%02d: %h (%04d)\t| R%02d: %h (%04d)",
                i,
                $signed(dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i]]),
                $signed(dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i]]),
                i+1,
                $signed(dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i+1]]),
                $signed(dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i+1]]),
                i+2,
                $signed(dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i+2]]),
                $signed(dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i+2]]),
                i+3,
                $signed(dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i+3]]),
                $signed(dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i+3]])
            );
        end
        
        for(int i=0; i<32; i++) begin
            match = match && (
                dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i]] ==
                dut.u_core.u_scalar_prf_replica1.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i]]
                );
        end
        if(match) $display("\nReplicas Match");
        else $display("\nReplicas do not match");
        $display("----------------------------------------------------------------------------------------------------");
    endtask

    task automatic display_final_prf_state_vc();
        $display("                             FINAL STATE VECTOR PRF");
        for(int i=0; i<32; i++) begin
            $display("V%02d:\t%h (%04d)  \t%h (%04d)  \t%h (%04d)  \t%h (%04d) ", 
                    i, 
                    $signed(dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[i]][0]),
                    $signed(dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[i]][0]),
                    $signed(dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[i]][1]),
                    $signed(dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[i]][1]),
                    $signed(dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[i]][2]),
                    $signed(dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[i]][2]),
                    $signed(dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[i]][3]),
                    $signed(dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[i]][3])
                );
        end
        $display("----------------------------------------------------------------------------------------------------");
    endtask

    task automatic display_stage_valids();             
        $display("[SC CORE] fetch=%h, decode=%h, queue=%h %h, alloc=%h %h @ %0d, rs=%h %h %h [%h] %h %h, ex=%h %h %h %h %h %h, wb=%h %h (%0d, %od), retire=%h (%0d)",
                dut.u_core.u_decode.fetch_valid_i,
                dut.u_core.u_decode.decoded_instr_o.valid, 
                dut.u_core.u_instr_q.dispatched_instr_o.valid,
                dut.u_core.u_instr_q.dispatched_instr_o.dest_address,

                dut.u_core.u_alloc_rename_retire.alloc_instr_o.sc_valid, dut.u_core.u_alloc_rename_retire.alloc_instr_o.vc_valid,
                dut.u_core.u_alloc_rename_retire.alloc_instr_o.instr.dest_address,

                dut.u_core.u_scalar_alu_rs.sc_rd_req0_o.valid, dut.u_core.u_scalar_alu_rs.sc_rd_req1_o.valid,
                dut.u_core.u_scalar_muldiv_rs.sc_rd_req_o.valid, dut.u_core.u_branch_rs.sc_rd_req_o.valid,
                dut.u_core.u_lsu_rs.ls_read_request_o.valid, dut.u_core.u_vector_alu_rs.vc_read_request_o.valid,

                dut.u_core.u_scalar_alu0.sc_ex_result_o.valid, dut.u_core.u_scalar_alu1.sc_ex_result_o.valid,
                dut.u_core.u_scalar_muldiv.sc_ex_result_o.valid, dut.u_core.u_branch.br_ex_result_o.valid,
                dut.u_core.u_lsu.lsu_output_o.valid, dut.u_core.u_vector_alu.vc_ex_result_o.valid,

                dut.u_core.u_scalar_writeback.data_bus_o.valid, dut.u_core.u_vector_writeback.data_bus_o.valid,
                dut.u_core.u_scalar_writeback.data_bus_o.prf_tag, dut.u_core.u_vector_writeback.data_bus_o.prf_tag,

                dut.u_core.u_reorder_buffer.retire_instr_o.valid, dut.u_core.u_reorder_buffer.retire_instr_o.prf_tag
        );
    endtask

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

    task automatic display_queue_states();
        $display("[QUEUE] IN:[%b %b %b] State:[%0d %0d] head[%b %b] flags[%b %b] Out:[%b]",
            dut.u_core.u_instr_q.decoded_instr_i.valid,
            dut.u_core.u_instr_q.rob_full_i,
            dut.u_core.u_instr_q.arr_full_i,
            dut.u_core.u_instr_q.head, dut.u_core.u_instr_q.tail,
            dut.u_core.u_instr_q.instr_fifo[dut.u_core.u_instr_q.head].valid,
            dut.u_core.u_instr_q.instr_fifo[dut.u_core.u_instr_q.head].chip_select, 
            dut.u_core.u_instr_q.enqueue, dut.u_core.u_instr_q.dequeue,
            dut.u_core.u_instr_q.dispatched_instr_o.valid
        );
    endtask

    task automatic display_arr_states();
        $display("[ARR] in[%b %b %b] ret [%b %0d] states[(%0d %0d) (%0d %0d)] out[%b %b %b %b] ready[%b]",
            dut.u_core.u_alloc_rename_retire.sc_alloc_valid,  
            dut.u_core.u_alloc_rename_retire.vc_alloc_valid,
            dut.u_core.u_alloc_rename_retire.flush_i,
            dut.u_core.u_alloc_rename_retire.retire_instr_i.valid,
            dut.u_core.u_alloc_rename_retire.retire_instr_i.prf_tag,
            dut.u_core.u_alloc_rename_retire.sc_head,
            dut.u_core.u_alloc_rename_retire.sc_tail,
            dut.u_core.u_alloc_rename_retire.sc_head_committed,
            dut.u_core.u_alloc_rename_retire.sc_tail_committed,
            dut.u_core.u_alloc_rename_retire.alloc_instr_o.sc_valid,
            dut.u_core.u_alloc_rename_retire.alloc_instr_o.vc_valid,
            dut.u_core.u_alloc_rename_retire.alloc_instr_o.precalc_valid,
            dut.u_core.u_alloc_bus.precalc_data,
            dut.u_core.u_alloc_rename_retire.arr_full_o
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

    task automatic display_rs_states_sc();
        $display("[SC RS] in for %0d [%b @ %0d %0d (%0d-%h %0d-%h)] ready:[%b %b] data_bus:[%b %0d] out:[%b %0d | %b %0d]",
                dut.u_core.u_scalar_alu_rs.rs_request_i.chip_select,
                dut.u_core.u_scalar_alu_rs.rs_request_i.valid,
                dut.u_core.u_scalar_alu_rs.rs_request_i.rs_slot_id,
                dut.u_core.u_scalar_alu_rs.rs_request_i.rs_entry.prf_tag,
                dut.u_core.u_scalar_alu_rs.rs_request_i.rs_entry.operand_a_tag,
                dut.u_core.u_scalar_alu_rs.rs_request_i.rs_entry.operand_a_ready,
                dut.u_core.u_scalar_alu_rs.rs_request_i.rs_entry.operand_b_tag,
                dut.u_core.u_scalar_alu_rs.rs_request_i.rs_entry.operand_b_ready,
                dut.u_core.u_scalar_alu_rs.sc_ex0_ready_i,
                dut.u_core.u_scalar_alu_rs.sc_ex1_ready_i,
                dut.u_core.u_scalar_alu_rs.sc_data_bus_i.valid,
                dut.u_core.u_scalar_alu_rs.sc_data_bus_i.prf_tag,
                dut.u_core.u_scalar_alu_rs.sc_rd_req0_o.valid,
                dut.u_core.u_scalar_alu_rs.sc_rd_req0_o.prf_tag,
                dut.u_core.u_scalar_alu_rs.sc_rd_req1_o.valid,
                dut.u_core.u_scalar_alu_rs.sc_rd_req1_o.prf_tag  
        );
    endtask

    task automatic display_rs_states_muldiv();
        $display("[MULDIV RS] in for %0d [%b @ %0d %0d (%0d-%h %0d-%h)] ready:[%b %b %b - %b] data_bus:[%b %0d] out:[%b %0d]",
                dut.u_core.u_scalar_muldiv_rs.rs_request_i.chip_select,
                dut.u_core.u_scalar_muldiv_rs.rs_request_i.valid,
                dut.u_core.u_scalar_muldiv_rs.rs_request_i.rs_slot_id,
                dut.u_core.u_scalar_muldiv_rs.rs_request_i.rs_entry.prf_tag,
                dut.u_core.u_scalar_muldiv_rs.rs_request_i.rs_entry.operand_a_tag,
                dut.u_core.u_scalar_muldiv_rs.rs_request_i.rs_entry.operand_a_ready,
                dut.u_core.u_scalar_muldiv_rs.rs_request_i.rs_entry.operand_b_tag,
                dut.u_core.u_scalar_muldiv_rs.rs_request_i.rs_entry.operand_b_ready,
                dut.u_core.sc_ex_ready[2],
                !(dut.u_core.sc_rd_req[2].valid),
                !(dut.u_core.sc_ex_req[2].valid),
                dut.u_core.u_scalar_muldiv_rs.sc_ex_ready_i,
                dut.u_core.u_scalar_muldiv_rs.sc_data_bus_i.valid,
                dut.u_core.u_scalar_muldiv_rs.sc_data_bus_i.prf_tag,
                dut.u_core.u_scalar_muldiv_rs.sc_rd_req_o.valid,
                dut.u_core.u_scalar_muldiv_rs.sc_rd_req_o.prf_tag,
        );
    endtask

    task automatic display_rs_states_branch();

        $display("[BRANCH RS] in for %0d [%b @ %0d %0d (%0d-%h %0d-%h)] ready:%b data_bus:[%b %0d] out:[%b %0d]",
                dut.u_core.u_branch_rs.rs_request_i.chip_select,
                dut.u_core.u_branch_rs.rs_request_i.valid,
                dut.u_core.u_branch_rs.rs_request_i.rs_slot_id,
                dut.u_core.u_branch_rs.rs_request_i.rs_entry.prf_tag,
                dut.u_core.u_branch_rs.rs_request_i.rs_entry.operand_a_tag,
                dut.u_core.u_branch_rs.rs_request_i.rs_entry.operand_a_ready,
                dut.u_core.u_branch_rs.rs_request_i.rs_entry.operand_b_tag,
                dut.u_core.u_branch_rs.rs_request_i.rs_entry.operand_b_ready,
                dut.u_core.u_branch_rs.sc_ex_ready_i,
                dut.u_core.u_branch_rs.sc_data_bus_i.valid,
                dut.u_core.u_branch_rs.sc_data_bus_i.prf_tag,
                dut.u_core.u_branch_rs.sc_rd_req_o.valid,
                dut.u_core.u_branch_rs.sc_rd_req_o.prf_tag,
        );
    endtask

    task automatic display_rs_states_vc();
        $display("[VC RS] in:[%b @ %0d (%h %h)] ready:%b out:[%0d %b]",
                dut.u_core.u_vector_alu_rs.rs_request_i.rs_entry.occupied,
                dut.u_core.u_vector_alu_rs.rs_request_i.rs_slot_id,
                dut.u_core.u_vector_alu_rs.rs_request_i.rs_entry.operand_a_ready,
                dut.u_core.u_vector_alu_rs.rs_request_i.rs_entry.operand_b_ready,
                dut.u_core.u_vector_alu_rs.vc_ex_ready_i,
                dut.u_core.u_vector_alu_rs.vc_read_request_o.prf_tag,
                dut.u_core.u_vector_alu_rs.vc_read_request_o.valid
        );
    endtask

    task automatic display_rs_states_lsu();
    if(dut.u_core.u_lsu_rs.ls_read_request_o.valid || dut.u_core.u_lsu_rs.instr_valid)
        $display("[LSU RS] in:[%b @ %0d %0d (%h %h) imm(%b %b)] ready:%b out:[%b %0d imm(%b %b)]",
                dut.u_core.u_lsu_rs.rs_request_i.valid,
                dut.u_core.u_lsu_rs.rs_request_i.rs_slot_id,
                dut.u_core.u_lsu_rs.rs_request_i.rs_entry.prf_tag,
                dut.u_core.u_lsu_rs.rs_request_i.rs_entry.operand_a_ready,
                dut.u_core.u_lsu_rs.rs_request_i.rs_entry.operand_b_ready,
                dut.u_core.u_lsu_rs.rs_request_i.rs_entry.read_src2,
                dut.u_core.u_lsu_rs.rs_request_i.rs_entry.imm,
                dut.u_core.u_lsu_rs.lsu_ready_i,
                dut.u_core.u_lsu_rs.ls_read_request_o.valid,
                dut.u_core.u_lsu_rs.ls_read_request_o.prf_tag,
                dut.u_core.u_lsu_rs.ls_read_request_o.read_src2,
                dut.u_core.u_lsu_rs.ls_read_request_o.imm
        );
    endtask

    task automatic display_prf_sc();
        $display("[SC PRF] R1:%h %h R2:%h %h R3:%h %h R4:%h %h R5:%h %h R6:%h %h R7:%h %h",
            dut.u_core.u_scalar_prf_replica0.regfile[1],
            dut.u_core.u_scalar_prf_replica1.regfile[1],
            dut.u_core.u_scalar_prf_replica0.regfile[2],
            dut.u_core.u_scalar_prf_replica1.regfile[2],
            dut.u_core.u_scalar_prf_replica0.regfile[32],
            dut.u_core.u_scalar_prf_replica1.regfile[32],
            dut.u_core.u_scalar_prf_replica0.regfile[33],
            dut.u_core.u_scalar_prf_replica1.regfile[33],
            dut.u_core.u_scalar_prf_replica0.regfile[34],
            dut.u_core.u_scalar_prf_replica1.regfile[34],
            dut.u_core.u_scalar_prf_replica0.regfile[35],
            dut.u_core.u_scalar_prf_replica1.regfile[35],
            dut.u_core.u_scalar_prf_replica0.regfile[36],
            dut.u_core.u_scalar_prf_replica1.regfile[36]
        );
    endtask

    task automatic display_prf_vc();
        $display("[VC PRF] R1:%h R2:%h R3:%h",
            dut.u_core.u_vector_prf.regfile[1],
            dut.u_core.u_vector_prf.regfile[2],
            dut.u_core.u_vector_prf.regfile[32],
        );
    endtask

    task automatic display_prf_inout_sc();
        $display("[PRF IN] IN:[%b @ %d (%h)] PRECALC:[%b @ %d (%h)]",
            dut.u_core.u_scalar_prf_replica0.sc_wb_instr_i.valid,
            dut.u_core.u_scalar_prf_replica0.sc_wb_instr_i.prf_tag,
            dut.u_core.u_scalar_prf_replica0.sc_wb_instr_i.data,
            dut.u_core.u_scalar_prf_replica0.precalc_i.precalc_valid,
            dut.u_core.u_scalar_prf_replica0.precalc_i.precalc_prf_tag,
            dut.u_core.u_scalar_prf_replica0.precalc_i.precalc_data
        );
    endtask

    task automatic display_prf_inout_ls();
    $display("[PRF IN] sc: [%b @ %d (%0d %0d)]",
            dut.u_core.u_scalar_prf_replica1.ls_rd_req_i.valid,
            dut.u_core.u_scalar_prf_replica1.ls_rd_req_i.prf_tag,
            dut.u_core.u_scalar_prf_replica1.ls_rd_req_i.operand_a_tag,
            dut.u_core.u_scalar_prf_replica1.ls_rd_req_i.operand_b_tag,
        );
    endtask

    task automatic display_prf_inout_vc();
        $display("[PRF INOUT] IN:[%b @ %0d (%b %b)] OUT:[%b - %h %h]",
            dut.u_core.u_vector_prf.vc_alu_rd_req_i.valid,
            dut.u_core.u_vector_prf.vc_alu_rd_req_i.prf_tag,
            dut.u_core.u_vector_prf.vc_alu_rd_req_i.operand_a_tag,
            dut.u_core.u_vector_prf.vc_alu_rd_req_i.operand_b_tag,
            dut.u_core.u_vector_prf.vc_alu_ex_req_o.valid,
            dut.u_core.u_vector_prf.vc_alu_ex_req_o.operand_a,
            dut.u_core.u_vector_prf.vc_alu_ex_req_o.operand_b
        );
    endtask

    task automatic display_muldiv_states();
        $display("[MULDIV] IN:[%b @ %0d - %h %h], ready:[%b %b %b] OUT:[%b @ %0d - %h]",
            dut.u_core.u_scalar_muldiv.sc_ex_request_i.valid,
            dut.u_core.u_scalar_muldiv.sc_ex_request_i.prf_tag,
            dut.u_core.u_scalar_muldiv.sc_ex_request_i.operand_a,
            dut.u_core.u_scalar_muldiv.sc_ex_request_i.operand_b,
            dut.u_core.u_scalar_muldiv_rs.sc_ex_ready_i,
                !(dut.u_core.sc_rd_req[2]),
                !(dut.u_core.sc_ex_req[2]),
            dut.u_core.u_scalar_muldiv.sc_ex_result_o.valid,
            dut.u_core.u_scalar_muldiv.sc_ex_result_o.prf_tag,
            dut.u_core.u_scalar_muldiv.sc_ex_result_o.data
        );
    endtask

    task automatic display_branch_states();
    if(dut.u_core.u_branch.br_ex_request_i.valid)
        $display("[BRANCH] IN:[%b - %h %h] CMP:[%b %b %b] Out:[%b %b]",
            dut.u_core.u_branch.br_ex_request_i.valid,
            dut.u_core.u_branch.br_ex_request_i.operand_a,
            dut.u_core.u_branch.br_ex_request_i.operand_b,
            dut.u_core.u_branch.a_lt_b,
            dut.u_core.u_branch.a_lt_b_u,
            dut.u_core.u_branch.a_eq_b,
            dut.u_core.u_branch.br_ex_result_o.valid,
            dut.u_core.u_branch.br_ex_result_o.branch_taken
        );
    endtask

    task automatic display_vc_alu_states();
        $display("[VC ALU] IN:[%b @ %0d - %h %h], OUT:[%b @ %0d - %h]",
            dut.u_core.u_vector_alu.vc_ex_request_i.valid,
            dut.u_core.u_vector_alu.vc_ex_request_i.rob_id,
            dut.u_core.u_vector_alu.vc_ex_request_i.operand_a,
            dut.u_core.u_vector_alu.vc_ex_request_i.operand_b,
            dut.u_core.u_vector_alu.vc_ex_result_o.valid,
            dut.u_core.u_vector_alu.vc_ex_result_o.rob_id,
            dut.u_core.u_vector_alu.vc_ex_result_o.data
        );
    endtask

    task automatic display_lsu_inout();
        $display("[LSU] in[%b %h %h @ %0d], out[%b %h @ %0d]",
            dut.u_core.u_lsu.lsu_request_i.valid,
            dut.u_core.u_lsu.lsu_request_i.operand_a,
            dut.u_core.u_lsu.lsu_request_i.operand_b,
            dut.u_core.u_lsu.lsu_request_i.prf_tag,
            dut.u_core.u_lsu.lsu_output_o.valid,
            dut.u_core.u_lsu.lsu_output_o.mem_addr,
            dut.u_core.u_lsu.lsu_output_o.prf_tag
        );
    endtask

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
        $display("[DMEM val] (For base address %0d) \n[%0d: %h (%0d)] [%0d:%h (%0d)] [%0d: %h (%0d)] [%0d: %h (%0d)]", 
            base_addr,
            base_addr + 3, dut.u_dmem.u_dmem3.mem[i][31:0], $signed(dut.u_dmem.u_dmem3.mem[i][31:0]),
            base_addr + 2, dut.u_dmem.u_dmem2.mem[i][31:0], $signed(dut.u_dmem.u_dmem2.mem[i][31:0]),
            base_addr + 1, dut.u_dmem.u_dmem1.mem[i][31:0], $signed(dut.u_dmem.u_dmem1.mem[i][31:0]),
            base_addr + 0, dut.u_dmem.u_dmem0.mem[i][31:0], $signed(dut.u_dmem.u_dmem0.mem[i][31:0]) 
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

    task automatic display_commit_states_sc();
        $display("[FINAL] R1:%h %h R2:%h %h R3:%h %h R4:%h %h R5:%h %h R6:%h %h R7:%h %h",
            dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[1]],
            dut.u_core.u_scalar_prf_replica1.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[1]],
            dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[2]],
            dut.u_core.u_scalar_prf_replica1.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[2]],
            dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[3]],
            dut.u_core.u_scalar_prf_replica1.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[3]],
            dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[4]],
            dut.u_core.u_scalar_prf_replica1.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[4]],
            dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[5]],
            dut.u_core.u_scalar_prf_replica1.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[5]],
            dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[6]],
            dut.u_core.u_scalar_prf_replica1.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[6]],
            dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[7]],
            dut.u_core.u_scalar_prf_replica1.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[7]]
        );
    endtask

    task automatic display_commit_states_vc();
        $display("[FINAL] R1:%h R2:%h R3:%h R4:%h R5:%h R6:%h R7:%h",
            dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[1]],
            dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[2]],
            dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[3]],
            dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[4]],
            dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[5]],
            dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[6]],
            dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[7]]
        );
    endtask
    
    always @(posedge clk) begin;
        prev_dest_address <= dut.u_core.u_alloc_rename_retire.retire_instr_i.dest_address;
        prev_prf_tag      <= dut.u_core.u_alloc_rename_retire.retire_instr_i.prf_tag;
        prev_retire_sc    <= dut.u_core.u_alloc_rename_retire.retire_instr_i.valid && !dut.u_core.u_alloc_rename_retire.retire_instr_i.prf_tag.vector;
        prev_retire_vc    <= dut.u_core.u_alloc_rename_retire.retire_instr_i.valid && dut.u_core.u_alloc_rename_retire.retire_instr_i.prf_tag.vector;
        if(prev_retire_sc) begin
        $display("[sc Retire at cycle %0d (%0t ns)] \tR%02d \ttag:%0d \tval:%h",
            (cycles-1), ($time()-20),
            prev_dest_address,
            prev_prf_tag,
            dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[prev_dest_address]]
        );
        end
        if(prev_retire_vc) begin
        $display("[vc Retire at cycle %0d (%0t ns)] \tV%02d \ttag:%0d \tval:%h",
            (cycles-1), ($time()-20),
            prev_dest_address,
            prev_prf_tag,
            dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[prev_dest_address]]
        );
        end
    end

    initial begin
        init();
        //preload_sc_prf();
        //preload_vc_prf();
        preload_imem();
        preload_dmem();
        compute = 1'b1;
        cycles = 0;
        
        $display("----------------------------------------------------------------------------------------------------");
        $display("                                                BEGIN TEST");    
        $display("----------------------------------------------------------------------------------------------------");
    

    end

    always @(posedge clk) begin
        #1;
        cycles++;

        //display_stage_valids();

        //display_fetch_states();

        //display_queue_states();

        display_arr_states();
        //display_arr_states_sc();
        //display_arr_states_vc();

        //display_rs_states_sc();
        //display_rs_states_branch();
        //display_rs_states_muldiv();
        //display_rs_states_vc();
        //display_rs_states_lsu();

        //display_prf_sc();
        //display_prf_vc();
        //display_prf_inout_sc();
        //display_prf_inout_vc();
        //display_prf_inout_ls();

        //display_muldiv_states();
        //display_branch_states();
        //display_vc_alu_states();
        //display_lsu_inout();

        //display_dmem_inout();
        //display_dmem_val(0);
        //display_dmem_val(1);
        //display_dmem_val(2);
        //display_dmem_controller();

        //display_sc_wb();

        //display_commit_states_sc();
        //display_commit_states_vc();

        if(cycles >= 512) begin
            $display("----------------------------------------------------------------------------------------------------");
            $display("                                           RUN COMPLETE"); 
            $display("----------------------------------------------------------------------------------------------------");
            display_final_prf_state_sc();
            display_final_prf_state_vc();
            display_dmem_val(16);
            $finish;
        end
    end
endmodule