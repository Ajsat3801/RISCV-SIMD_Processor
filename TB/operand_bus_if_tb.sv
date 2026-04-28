`timescale 1ns/1ps

import instr_desc::*;

module if_scalar_request_bus_tb;

    logic clk;

    logic[4:0] dest_ROB_ID;
    chip_select_e ROB_chip_select;
    logic ROB_inputs_valid;

    // inputs from Registers
    logic[31:0] operand_a;
    logic[31:0] operand_b;
    chip_select_e reg_chip_select;
    logic reg_input_valid;

    // inputs from RAT
    operations_e operation;
    chip_select_e RAT_chip_select;
    logic[4:0] src1_ROB_ID;
    logic[4:0] src2_ROB_ID;
    logic src1_ready;
    logic src2_ready;
    logic RAT_op_valid;

    sc_rs_entry_t rs_entry;
    logic[1:0] rs_full_vec;
    chip_select_e cs;

    initial clk = 1'b0;
    always #5 clk = ~clk;

    if_scalar_request_bus bus();

    task idle();
        begin
            bus.dest_ROB_ID = 0;
            bus.ROB_chip_select = 0;
            bus.ROB_inputs_valid = 1;

            bus.operand_a = 0;
            bus.operand_b = 0;
            bus.reg_chip_select = 0;
            bus.reg_input_valid = 1;

            bus.operation = 0;
            bus.RAT_chip_select = 0;
            bus.src1_ROB_ID = 0;
            bus.src2_ROB_ID = 0;
            bus.src1_ready = 0;
            bus.src2_ready = 0;
            bus.RAT_op_valid = 1;

            rs_full_vec = 0;
        end
    endtask
    
    // tests the outputf of all control signals

    task automatic test_control_signals();
        logic result = 1;
        logic[6:0] i;
        logic exp, got;
        begin
            idle();
            $display("------------------------------\nCheck for valid bits");
            for(i = 7'd0; i<7'd8; i++) begin

                bus.RAT_op_valid = i[2];
                bus.ROB_inputs_valid = i[1];
                bus.reg_input_valid = i[0];
                #1
                got = bus.rs_entry.occupied;
                exp = (i[2:0] == 3'b111)? 1: 0;

                if(got != exp) begin
                    $display("Error at :rat_valid=%d\trob_valid=%d\treg_valid=%d\toccupied=%d\n",
                            i[2], i[1], i[0], got);
                    result = 0;
                end

            end
            if(result) $display("Valid bits working as designed");
            else $display("Valid bits not working");

            idle();
            result = 1;
            $display("------------------------------\nCheck for chip select matching");

            for(i=7'd0; i<7'd64; i++) begin
                bus.RAT_chip_select = i[5:4];
                bus.ROB_chip_select = i[3:2];
                bus.reg_chip_select = i[1:0];
                #1
                got = bus.rs_entry.occupied;
                exp = (i[5:4] == i[3:2]) && (i[3:2] == i[1:0]);

                if(got != exp) begin
                    $display("Error at :rat_CS=%d\trob_CS=%d\treg_CS=%d\texp=%d\tgot=%d",
                            i[5:4], i[3:2], i[1:0], exp, got);
                    result = 0;
                end

                if(bus.cs != i[5:4]) begin
                    $display("Error at :rat_CS=%d\tout_CS=%d",
                            i[5:4], bus.cs);
                    result = 0;
                end

            end
            if(result) $display("Chip Selects & Valids working as designed");
            else $display("Chip Select or Valids not working");

            idle();
            result = 1;
            $display("------------------------------\nCheck for ready to dispatch");
            for(i=7'd0; i<7'd4; i++) begin
                bus.src1_ready = i[0];
                bus.src2_ready = i[1];

                #1;

                got = bus.rs_entry.ready_to_dispatch;
                exp = i[0] && i[1];

                if(got != exp) begin
                    $display("Error at :src1_ready=%d\tsrc2_ready=%d\texp=%d\tgot=%d",
                            i[1], i[0], exp, got);
                    result = 0;
                end

                if(bus.rs_entry.operand_a_ready != i[0]) begin
                    $display("Error at :src1_ready=%d\top_a_ready=%d\t",
                            i[0], bus.rs_entry.operand_a_ready);
                    result = 0;
                end
                if(bus.rs_entry.operand_b_ready != i[1]) begin
                    $display("Error at :src2_ready=%d\top_b_ready=%d\t",
                            i[1], bus.rs_entry.operand_b_ready);
                    result = 0;
                end 
            end
            if(result) $display("Source Ready signals working as designed");
            else $display("Source Ready Signals not working");
        end
    endtask

    task automatic data_test(input logic[82:0] test_stimulus, output logic pass);
        begin
            pass = 1;
            bus.operand_a = test_stimulus[31:0];
            bus.operand_b = test_stimulus[63:32];
            bus.src1_ROB_ID = test_stimulus[68:64];
            bus.src2_ROB_ID = test_stimulus[73:69];
            bus.dest_ROB_ID = test_stimulus[78:74];
            bus.operation = test_stimulus[82:79];
            
            #1;

            if(bus.rs_entry.operand_a != test_stimulus[31:0]) begin
                $display("Error at :op_a=%d\tdest_op_a=%d\t",
                            test_stimulus[31:0], bus.rs_entry.operand_a);
                pass = 0;
            end
            if(bus.rs_entry.operand_b != test_stimulus[63:32]) begin
                $display("Error at :op_b=%d\tdest_op_b=%d\t",
                            test_stimulus[63:32], bus.rs_entry.operand_b);
                pass = 0;
            end
            if(bus.rs_entry.operand_a_tag != test_stimulus[68:64]) begin
                $display("Error at :src1_rob_id=%d\top_a_tag=%d\t",
                            test_stimulus[68:64], bus.rs_entry.operand_a_tag);
                pass = 0;
            end
            if(bus.rs_entry.operand_b_tag != test_stimulus[73:69]) begin
                $display("Error at :src2_rob_id=%d\top_b_tag=%d\t",
                            test_stimulus[73:69], bus.rs_entry.operand_b_tag);
                pass = 0;
            end
            if(bus.rs_entry.instr_ROB_ID != test_stimulus[78:74]) begin
                $display("Error at :dest_rob_id=%d\tinstr_tag=%d\t",
                            test_stimulus[78:74], bus.rs_entry.instr_ROB_ID);
                pass = 0;
            end
            if(bus.rs_entry.operation != test_stimulus[82:79]) begin
                $display("Error at :src2_rob_id=%d\top_b_tag=%d\t",
                            test_stimulus[82:79], bus.rs_entry.operation);
                pass = 0;
            end
        end
        
    endtask

    task automatic test_data_signals();
    logic[3:0] i;
    logic[82:0] test_stimulus;
    logic result = 1;
    logic ind_result;
    begin 
        idle();
        $display("------------------------------\nCheck data signals");
        test_stimulus = {83{1'b0}};
        data_test(test_stimulus, ind_result);
        result = result && ind_result;

        test_stimulus = {83{1'b1}};
        data_test(test_stimulus, ind_result);
        result = result && ind_result;

        for(i = 0; i<8;i++) begin

            test_stimulus = {$urandom(), $urandom(), $urandom()}[82:0];
            data_test(test_stimulus, ind_result);
            result = result && ind_result;

        end

        if(result) $display("Data signals working as designed");
        else $display("Data signals not working"); 

    end

    endtask

    initial begin
        $display("\n------------------------------\nTesting Operation Bus");
        test_control_signals();
        test_data_signals();
        $display("------------------------------\nVerification Complete\n------------------------------\n");
        $finish;
    end

endmodule