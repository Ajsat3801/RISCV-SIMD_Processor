/*
Hacky solution to compile aggregate the UVM tesbench
in EDAPlayground
*/

`timescale 1ns/1ps

`include "lib_rs_slot_freeq_1push_tb_config_pkg.sv"
`include "lib_rs_slot_freeq_1push_if.sv"
`include "lib_rs_slot_freeq_1push_dpi_pkg.sv"
`include "lib_rs_slot_freeq_1push_tb_pkg.sv"
`include "lib_rs_slot_freeq_1push_top.sv"