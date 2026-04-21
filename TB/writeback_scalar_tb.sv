`timescale 1ns/1ps

module writeback_scalar_tb();

logic clk, resetn;
logic salu_result_valid, smuldiv_result_valid, slsu_result_valid;
logic wb_salu_ready, wb_smuldiv_ready, write_enable, reset_busy;
logic[4:0] rd_bb;
wb_desc_t sc_alu_res, scalar_lsu_res, scalar_muldiv_res, wb_data;

Writeback_scalar dut(
    .clk(clk),
    .resetn(resetn),

    .sc_alu_res(sc_alu_res),
    .salu_result_valid(salu_result_valid),
    .wb_salu_ready(wb_salu_ready),

    .scalar_muldiv_res(scalar_muldiv_res),
    .smuldiv_result_valid(smuldiv_result_valid),
    .wb_smuldiv_ready(wb_smuldiv_ready),

    .scalar_lsu_res(scalar_lsu_res),
    .slsu_result_valid(slsu_result_valid),

    .wb_data(wb_data),
    .write_enable(write_enable),

    .rd_bb(rd_bb),
    .reset_busy(reset_busy)

);

initial begin
    clk <= 1'b0;
    resetn <= 1'b0;

    salu_result_valid <= 1'b0;
    smuldiv_result_valid <= 1'b0;
    slsu_result_valid <= 1'b0;

    sc_alu_res.rd <= 5'b0;
    sc_alu_res.wb_data <= 32'b0;
    scalar_lsu_res.rd <= 5'b0;
    scalar_lsu_res.wb_data <= 32'b0;
    scalar_muldiv_res.rd <= 5'b0;
    scalar_muldiv_res.wb_data <= 32'b0;

end

// clock generation
always begin
    #5
    clk = ~clk;
end

// stimulus generation *alu only* 
initial begin
    #10 resetn = 1;

    #10 
    salu_result_valid <= 1;
    sc_alu_res.rd <= 5'd1;
    sc_alu_res.wb_data <= 32'd1;

    #10 salu_result_valid <= 0;
    
    #10
    salu_result_valid <= 1;
    sc_alu_res.rd <= 5'd2;
    sc_alu_res.wb_data <= 32'd2;

    #10 salu_result_valid <= 0;

    #10
    slsu_result_valid <= 1;
    scalar_lsu_res.rd <=5'd4;
    scalar_lsu_res.wb_data <= 32'd4;

    #10 slsu_result_valid <= 0;

    #10
    salu_result_valid <= 1;
    sc_alu_res.rd <= 5'd3;
    sc_alu_res.wb_data <= 32'd3;

    #10 salu_result_valid <= 0;

end

always @(posedge clk) $strobe("%0t  alu:%b lsu:%b alu_rd:%0d alu_data:%0d lsu_rd:%0d lsu_data:%0d rd=%0d data=%0d WE=%0d cnt=%0d",
                            $time, salu_result_valid, slsu_result_valid,  sc_alu_res.rd, 
                            sc_alu_res.wb_data, scalar_lsu_res.rd, scalar_lsu_res.wb_data,
                              wb_data.rd, wb_data.wb_data, write_enable, dut.salu_q_count);

/*
always @( clk ) begin
        $display("--------");
        $display("%t", $time);
        $display("alu_res_valid:%b, in_rd:%d, in_data:%d, out_rd: %d, out_data: %d, write_enable = %b, salu_q_count=%d",
        salu_result_valid, sc_alu_res.rd, sc_alu_res.wb_data, wb_data.rd, wb_data.wb_data, write_enable ,dut.salu_q_count);
end*/

initial begin
    #120
    $finish;
    end
  
initial begin
    $dumpfile("writeback_scalar_tb.vcd");
    $dumpvars(0, writeback_scalar_tb);
end


endmodule
/*
CPU time: .431 seconds to compile + .404 seconds to elab + .385 seconds to link
Chronologic VCS simulator copyright 1991-2023
Contains Synopsys proprietary information.
Compiler version U-2023.03-SP2_Full64; Runtime version U-2023.03-SP2_Full64;  Nov  4 00:03 2025
5000  alu:0 lsu:0 alu_rd:0 alu_data:0 lsu_rd:0 lsu_data:0 rd=0 data=0 WE=0 cnt=0
15000  alu:0 lsu:0 alu_rd:0 alu_data:0 lsu_rd:0 lsu_data:0 rd=0 data=0 WE=0 cnt=0
25000  alu:1 lsu:0 alu_rd:1 alu_data:1 lsu_rd:0 lsu_data:0 rd=0 data=0 WE=0 cnt=1
35000  alu:0 lsu:0 alu_rd:1 alu_data:1 lsu_rd:0 lsu_data:0 rd=1 data=1 WE=1 cnt=0
45000  alu:1 lsu:0 alu_rd:2 alu_data:2 lsu_rd:0 lsu_data:0 rd=1 data=1 WE=0 cnt=1
55000  alu:0 lsu:0 alu_rd:2 alu_data:2 lsu_rd:0 lsu_data:0 rd=2 data=2 WE=1 cnt=0
65000  alu:0 lsu:1 alu_rd:2 alu_data:2 lsu_rd:4 lsu_data:4 rd=4 data=4 WE=1 cnt=0
75000  alu:0 lsu:0 alu_rd:2 alu_data:2 lsu_rd:4 lsu_data:4 rd=4 data=4 WE=0 cnt=0
85000  alu:1 lsu:0 alu_rd:3 alu_data:3 lsu_rd:4 lsu_data:4 rd=4 data=4 WE=0 cnt=1
95000  alu:0 lsu:0 alu_rd:3 alu_data:3 lsu_rd:4 lsu_data:4 rd=3 data=3 WE=1 cnt=0
105000  alu:0 lsu:0 alu_rd:3 alu_data:3 lsu_rd:4 lsu_data:4 rd=3 data=3 WE=0 cnt=0
115000  alu:0 lsu:0 alu_rd:3 alu_data:3 lsu_rd:4 lsu_data:4 rd=3 data=3 WE=0 cnt=0
$finish called from file "testbench.sv", line 106.
$finish at simulation time               120000
           V C S   S i m u l a t i o n   R e p o r t 
Time: 120000 ps
CPU Time:      0.500 seconds;       Data structure size:   0.0Mb
Tue Nov  4 00:03:56 2025
*/