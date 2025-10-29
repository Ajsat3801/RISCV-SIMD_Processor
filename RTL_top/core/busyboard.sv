

module busyboard #() (
    input logic clk,

    //CONNECTIONS WITH DECODE
    input logic[4:0] rs1_addr, rs2_addr, rd_addr,
    input logic check_rs1, check_rs2, check_rd,
    output logic rs1_valid, rs2_valid, rd_valid

    // CONNECTIONS WITH WRITEBACK
    input logic [4:0] wb_rd_addr,
    input logic wb_rd,
    
    
);

logic[31:0] busyboard_scalar;
logic rs1_valid_ff, rs2_valid_ff;

always_ff @( posedge clk ) begin
    if(wb_rd) begin
        busyboard_scalar[wb_addr] <= 1;
    end
    if(check_rs1) begin
        rs1_valid_ff <= busyboard_scalar[rs1_addr];
    end
    else rs1_valid_ff  <= 0;
    if(check_rs2) begin
        rs2_valid_ff <= busyboard_scalar[rs2_addr];
    end
    else rs2_valid_ff  <= 0;
end

assign rs1_valid = rs1_valid_ff;
assign rs2_valid = rs2_valid_ff;


endmodule