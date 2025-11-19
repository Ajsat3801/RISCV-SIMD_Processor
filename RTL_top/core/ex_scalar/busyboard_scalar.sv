/*
Busyboard to prevent hazards

*/

module busyboard #() (
    input logic clk,
    input logic resetn,

    //CONNECTIONS WITH DECODE
    input logic[4:0] rs1_addr, rs2_addr, rd_addr,
    input logic check_rs1, check_rs2, check_rd,
    output logic rs1_valid, rs2_valid, rd_valid

    // CONNECTIONS WITH WRITEBACK
    input logic [4:0] wb_rd_addr,
    input logic reset_busy,
    
    
);

logic[31:0] busyboard_scalar;
logic rs1_busy_q, rs2_busy_q, rd_busy_q;

always_ff @( posedge clk ) begin
    if(!resetn) begin
        for(int i = 0;i<32; i++) busyboard_scalar[i] <= 0;
        rs1_busy_q <= 0;
        rs2_busy_q <= 0;
        rd_busy_q <= 0;
    end

    else begin
        
        // Write from writeback
        if(reset_busy) busyboard_scalar[wb_rd_addr] <= 1'b0;

        // Read to decode
        if(check_rs1) rs1_busy_q <= busyboard_scalar[rs1_addr];
        else rs1_busy_q <= 1'b0;
        if(check_rs2) rs2_busy_q <= busyboard_scalar[rs2_addr];
        else rs2_busy_q <= 1'b0;
        if(check_rd) rd_busy_q <= busyboard_scalar[rd_addr];
        else rd_busy_q <= 1'b0;

    end    

end

assign rs1_valid = !rs1_busy_q;
assign rs2_valid = !rs2_busy_q;
assign rd_valid = !rd_busy_q;


endmodule