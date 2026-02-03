// Code your testbench here
// or browse Examples


`timescale 1ns/1ps;

module scalar_registers_tb();

    logic clk, reset_n;
    //connections from writeback
    logic write_enable;
    wb_desc_t wb_data;

    //connections from decode
    logic[4:0] rs1_addr, rs2_addr;
    logic[31:0] rs1_data, rs2_data;

    scalar_registers dut(
        .clk(clk),
        .reset_n(reset_n),
        .write_enable(write_enable),
        .wb_data(wb_data),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    initial begin

        clk <= 1'b0;
        resetn <= 1'b0;
        write_enable <= 1'b0;
        wb_data.wb_data<= 32'b0;
        wb_data.rd <= 5'b0;
        rs1_addr <= 5'b0;
        rs2_addr <= 5'b0;

    end

    // clk stimulus
    always begin
        #10
        clk = ~clk;
        #10
        clk <= ~clk;

    end

    always begin
        #10 
        resetn <= 1;
        write_enable <= 1;
        wb_data.rd <= 5'b0;
        wb_data.wb_data <= 32'd1;
        rs1_addr <= 5'b0;
        rs2_addr <= 5'b0;

        #10 write_enable <= 0;

        #10
        write_enable <= 1;
        wb_data.rd <= 5'd1;
        wb_data.wb_data <= 32'd1;
        rs1_addr <= 5'b0;
        rs2_addr <= 5'b0;

        #10 write_enable <= 0;

        #10
        write_enable <= 1;
        wb_data.rd <= 5'd2;
        wb_data.wb_data <= 32'd2;
        rs1_addr <= 5'd1;
        rs2_addr <= 5'd0;

        #10 write_enable <= 0;

        #10
        write_enable <= 1;
        wb_data.rd <= 5'd3;
        wb_data.wb_data <= 32'd3;
        rs1_addr <= 5'd2;
        rs2_addr <= 5'd1;

        #10 write_enable <= 0;

        #10
        write_enable <= 1;
        wb_data.rd <= 5'd4;
        wb_data.wb_data <= 32'd4;
        rs1_addr <= 5'd3;
        rs2_addr <= 5'd2;

        #10 write_enable <= 0;
    end
  
    always@(posedge clk) begin
        if(!write_enable)
        $display("%t, we:%b, rd:%d, rd_data:%d, rs1: %d, rs2: %d, rs1_data: %d, rs2_data:%d",
        $time, write_enable, wb_data.rd, wb_data.wb_data, rs1_addr, rs2_addr, rs1_data, rs2_data);
    end

    initial begin
        #120
        $finish;
    end
  
  initial begin
    $dumpfile("regfile_scalar_tb.vcd");
    $dumpvars(0, regfile_scalar_tb);
  end


endmodule

/*
------------------------------------------------------------------------------------------------------------------
                                            VCS SIMULATION RESULT
------------------------------------------------------------------------------------------------------------------
CPU time: .423 seconds to compile + .457 seconds to elab + .430 seconds to link
Chronologic VCS simulator copyright 1991-2023
Contains Synopsys proprietary information.
Compiler version U-2023.03-SP2_Full64; Runtime version U-2023.03-SP2_Full64;  Nov  3 21:25 2025
               10000, we:0, rd: 0, rd_data:         0, rs1:  0, rs2:  0, rs1_data:          x, rs2_data:         x
               30000, we:0, rd: 0, rd_data:         1, rs1:  0, rs2:  0, rs1_data:          0, rs2_data:         0
               50000, we:0, rd: 1, rd_data:         1, rs1:  0, rs2:  0, rs1_data:          0, rs2_data:         0
               70000, we:0, rd: 2, rd_data:         2, rs1:  1, rs2:  0, rs1_data:          0, rs2_data:         0
               90000, we:0, rd: 3, rd_data:         3, rs1:  2, rs2:  1, rs1_data:          0, rs2_data:         0
              110000, we:0, rd: 4, rd_data:         4, rs1:  3, rs2:  2, rs1_data:          0, rs2_data:         0
$finish called from file "testbench.sv", line 106.
$finish at simulation time               120000
           V C S   S i m u l a t i o n   R e p o r t 
Time: 120000 ps
CPU Time:      0.400 seconds;       Data structure size:   0.0Mb
Mon Nov  3 21:25:11 2025
------------------------------------------------------------------------------------------------------------------
*/