/*
Hacky solution to compile aggregate the UVM tesbench
in EDAPlayground
*/

`timescale 1ns/1ps

`include "top_tb_typedef_pkg.sv"
`include "top_tb_config_pkg.sv"

`include "top_tb_if_preload.sv"
`include "top_tb_if_retirement.sv"
`include "top_tb_if_dut_state.sv"

`include "top_tb_dpi_pkg.sv"
`include "top_tb_pkg.sv"
`include "top_tb_top.sv"