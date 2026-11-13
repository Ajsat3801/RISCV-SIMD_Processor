
module lib_d_ff (
    input  logic clk_i,
    input  logic reset_ni,
    input  logic d_i,
    output logic q_o
);

    always_ff @(posedge clk_i or negedge reset_ni) begin
        
        if(!reset_ni) q_o <= 1'b0;
        else q_o <= d_i;
        
    end

endmodule