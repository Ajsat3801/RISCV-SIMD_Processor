/*  
Writeback for Scalar registers

*/
/* 
    xxxx_q_count counts till n-1 values
    xxxx_q_full acts as an overflow as well as a queue full flag
    
    ENQUEUE LOGIC:
        if ( q_full == 0){
            q[tail] <= input;
            tail <= (tail + 1) % 8;
            if (q_count == all ones) q_full = 1;
            else q_count = q_count + 1;
            q_empty = 0;
        } 
    
    DEQUEUE LOGIC:

        if(q_empty == 0){
            output <= queue[head];
            head <= (head + 1) % 8;
            if (q_full  == 1) q_full = 0;
            else q_count = q_count - 1;
            if(q_count == 0) q_empty = 1;
        }
*/

`include "typedefs.sv"
import instr_desc::*;

module scalar_writeback(
    input logic clk,
    input logic reset_n,

    // FROM SCALAR ALU
    input wb_desc_t scalar_alu_res,
    input logic salu_result_valid,
    output logic wb_salu_ready,

    // FROM SCALAR MULDIV
    input wb_desc_t scalar_muldiv_res,
    input logic smuldiv_result_valid,
    output logic wb_smuldiv_ready,

    // FROM SCALAR LSU
    input wb_desc_t scalar_lsu_res,
    input logic slsu_result_valid,

    // TO SCALAR REGISTER
    output wb_desc_t wb_data,
    output logic write_enable,

    // TO BUSYBOARD
    output logic[4:0] rd_bb,
    output logic reset_busy
);



wb_desc_t wb_data_q;
logic write_enable_q;

logic wb_salu_ready_q, wb_smuldiv_ready_q;
logic reset_busy_q;

wb_state_e state = SALU, next_state = SALU;


wb_desc_t salu_wb_queue[7:0];
logic [2:0] salu_q_head, salu_q_tail, salu_q_count=3'b0;
logic salu_q_full, salu_q_empty; 

wb_desc_t smuldiv_wb_queue[3:0];
logic [1:0] smuldiv_q_head, smuldiv_q_tail, smuldiv_q_count=2'b0;;
logic smuldiv_q_full, smuldiv_q_empty; 

always @(posedge clk) begin
    write_enable_q <=0;
    if(!reset_n) begin
        wb_data_q.wb_data <= 32'b0;
        wb_data_q.rd <= 5'b0;
        write_enable_q <=0;

        state <= SALU;
        next_state <= SALU;

        for(int i=0; i<8; i=i+1) begin
            salu_wb_queue[i].wb_data <= 32'b0;
            salu_wb_queue[i].rd <= 5'b0;
        end
        for(int i=0; i<4; i=i+1) begin
            smuldiv_wb_queue[i].wb_data <= 32'b0;
            smuldiv_wb_queue[i].rd <= 5'b0;
        end

        salu_q_head <= 0;
        salu_q_tail <= 0;
        salu_q_count <= 0;
        salu_q_full <= 0;
        salu_q_empty <= 1; 

        
        smuldiv_q_head <= 0;
        smuldiv_q_tail <= 0;
        smuldiv_q_count <= 0;
        smuldiv_q_full <= 0;
        smuldiv_q_empty <= 1;
        
    end
    else begin
        if(salu_result_valid) begin // enqueue alu result
            if (!salu_q_full) begin
                salu_wb_queue[salu_q_tail] <= scalar_alu_res;
                salu_q_tail <= (salu_q_tail + 1);
                if (salu_q_count == 3'b111) salu_q_full <= 1;
                else salu_q_count <= salu_q_count + 1;
                salu_q_empty <= 0;
            end 
        end
        if(smuldiv_result_valid) begin // enqueue muldiv result
            if(!smuldiv_q_full) begin
                smuldiv_wb_queue[smuldiv_q_tail] <= scalar_muldiv_res;
                smuldiv_q_tail <= (smuldiv_q_tail + 1);
                if (smuldiv_q_count == 2'b11) smuldiv_q_full <= 1;
                else smuldiv_q_count <= smuldiv_q_count + 1;
                smuldiv_q_empty <= 0;
            end 
        end
        if(slsu_result_valid) begin // pass lsu result to register
            wb_data_q.rd <= scalar_lsu_res.rd;
            wb_data_q.wb_data <= scalar_lsu_res.wb_data;
            reset_busy_q <= 1;
            write_enable_q <= 1;
            next_state <= state;
        end
        else begin
            // do round robin between SALU and MULDIV for dequeue
            
            if(state == SALU) begin
                //send ALU
                if(salu_q_count!=0) begin
                    wb_data_q <= salu_wb_queue[salu_q_head];
                    salu_q_head <= (salu_q_head + 1);

                    write_enable_q <= 1;
                    reset_busy_q <= 1;

                    if (salu_q_full  == 1) salu_q_full <= 0;
                    else salu_q_count <= salu_q_count - 1;
                    if(salu_q_count == 0) salu_q_empty <= 1;
                end
                else begin
                    write_enable_q <=0;
                    reset_busy_q <= 0;
                end
                if(smuldiv_q_count!=0) next_state <= SMULDIV;
            end
            
            if(state == SMULDIV) begin
                //send MULDIV
                if(smuldiv_q_count!=0) begin
                    wb_data_q <= smuldiv_wb_queue[smuldiv_q_head];
                    smuldiv_q_head <= (smuldiv_q_head + 1);

                    write_enable_q <= 1;
                    reset_busy_q <= 1;

                    if (smuldiv_q_full  == 1) smuldiv_q_full <= 0;
                    else smuldiv_q_count <= smuldiv_q_count - 1;
                    if(smuldiv_q_count == 0) smuldiv_q_empty <= 1;
                end
                else begin
                    write_enable_q <=0;
                    reset_busy_q <= 0;
                end

                if(salu_q_count!=0) next_state = SALU;
            end     
        end

        next_state <= state;
    end
end

assign wb_data = wb_data_q;
assign write_enable = write_enable_q;

assign rd_bb = wb_data_q.rd;
assign reset_busy = reset_busy_q;

assign wb_salu_ready = (!salu_q_full);
assign wb_smuldiv_ready = (!smuldiv_q_full);

endmodule