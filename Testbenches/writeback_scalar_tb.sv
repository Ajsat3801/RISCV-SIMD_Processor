`timescale 1ns/1ps

module writeback_scalar_tb();

logic clk, resetn;
logic salu_result_valid, smuldiv_result_valid, slsu_result_valid;
logic wb_salu_ready, wb_smuldiv_ready, write_enable, reset_busy;
logic[4:0] rd_bb;
wb_desc_t scalar_alu_res, scalar_lsu_res, scalar_muldiv_res, wb_data;

Writeback_scalar dut(
    .clk(clk),
    .resetn(resetn),

    .scalar_alu_res(scalar_alu_res),
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

    scalar_alu_res.rd <= 5'b0;
    scalar_alu_res.wb_data <= 32'b0;
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
    scalar_alu_res.rd <= 5'd1;
    scalar_alu_res.wb_data <= 32'd1;

    #10 salu_result_valid <= 0;
    
    #10
    salu_result_valid <= 1;
    scalar_alu_res.rd <= 5'd2;
    scalar_alu_res.wb_data <= 32'd2;

    #10 salu_result_valid <= 0;

    #10
    slsu_result_valid <= 1;
    scalar_lsu_res.rd <=5'd4;
    scalar_lsu_res.wb_data <= 32'd4;

    #10 slsu_result_valid <= 0;

    #10
    salu_result_valid <= 1;
    scalar_alu_res.rd <= 5'd3;
    scalar_alu_res.wb_data <= 32'd3;

    #10 salu_result_valid <= 0;

end

always @(posedge clk) $strobe("%0t  alu:%b lsu:%b alu_rd:%0d alu_data:%0d lsu_rd:%0d lsu_data:%0d rd=%0d data=%0d WE=%0d cnt=%0d",
                            $time, salu_result_valid, slsu_result_valid,  scalar_alu_res.rd, 
                            scalar_alu_res.wb_data, scalar_lsu_res.rd, scalar_lsu_res.wb_data,
                              wb_data.rd, wb_data.wb_data, write_enable, dut.salu_q_count);

/*
always @( clk ) begin
        $display("--------");
        $display("%t", $time);
        $display("alu_res_valid:%b, in_rd:%d, in_data:%d, out_rd: %d, out_data: %d, write_enable = %b, salu_q_count=%d",
        salu_result_valid, scalar_alu_res.rd, scalar_alu_res.wb_data, wb_data.rd, wb_data.wb_data, write_enable ,dut.salu_q_count);
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