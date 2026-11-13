

module lib_nflop_sync #(
    parameter int unsigned WIDTH = 1,
    parameter int unsigned SYNC_STAGES = 2 // Note: min 2
) (
    input  logic clk_i,
    input  logic reset_ni,
    input  logic[WIDTH-1:0] data_i,
    output logic[WIDTH-1:0] data_o
);
    
    logic [WIDTH-1:0] dm [SYNC_STAGES:0];

    assign dm[0] = data_i;
    
    genvar stage,idx;
    generate
        for(idx=0; idx<WIDTH; idx++) begin : g_bit
            for (stage=0; stage<SYNC_STAGES; stage++) begin : g_stage
                lib_d_ff d_ff(
                    .clk_i(clk_i),
                    .reset_ni(reset_ni),
                    .d_i(dm[stage][idx]),
                    .q_o(dm[stage+1][idx])
                );
            end
        end
    endgenerate

    assign data_o = dm[SYNC_STAGES];

endmodule