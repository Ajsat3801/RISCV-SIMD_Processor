/*
Hacky solution to compile aggregate the UVM tesbench
in EDAPlayground
*/

`timescale 1ns/1ps

`include "circular_fifo_fwft_tb_config_pkg.sv"
`include "circular_fifo_fwft_if.sv"
`include "circular_fifo_fwft_dpi_pkg.sv"
`include "circular_fifo_fwft_tb_pkg.sv"
`include "circular_fifo_fwft_top.sv"
