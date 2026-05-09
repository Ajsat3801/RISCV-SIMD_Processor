
module data_dmem_controller (
    input  logic clk_i,
    input  logic reset_ni,

    input  logic [127:0] dmem_data_i,

    input  packet_pkg::load_store_entry_t lsu_output,

    output logic [3:0] write_enable_o,
    output logic [7:0] mem_addr_o,
    output logic [127:0] dmem_data_o,

    output packet_pkg::sc_ex_result_t sc_wb_o,
    output packet_pkg::vc_ex_result_t vc_wb_o
);

    signal_pkg::rob_address_t rob_id_q;
    signal_pkg::prf_tag_t prf_tag_q;
    logic [1:0] idx;
    logic sc_wb_valid, vc_wb_valid;

    assign dmem_data_o = lsu_output.data;
    assign mem_addr_o = lsu_output.mem_addr[9:2];

    generate
        for(genvar i=0; i<3; i++) begin
            assign write_enable_o[i] = lsu_output.is_vector || (i == lsu_output.mem_addr[1:0]);
        end
    endgenerate

    always_comb begin
        
        vc_wb_o.valid   = vc_wb_valid;
        vc_wb_o.rob_id  = rob_id_q;
        vc_wb_o.prf_tag = prf_tag_q;
        vc_wb_o.data    = dmem_data_i;
        
        sc_wv_o.valid   = valid;
        sc_wb_o.rob_id  = rob_id_q;
        sc_wb_o.prf_tag = prf_tag_q;
        sc_wb_o.data    = dmem_data_i[32*idx + 31:32*idx];
        
        store_to_rob_tag_o = rob_id_q;

    end

    always @(posedge clk_i) begin
        rob_id_q  <= lsu_output.rob_id;
        prf_tag_q <= lsu_output.prf_tag;
       
        idx <= lsu_output.mem_addr[1:0];

        sc_wb_valid <= lsu_output.valid && !lsu_output.is_vector && !lsu_output.is_store;
        vc_wb_valid <= lsu_output.valid && lsu_output.is_vector && !lsu_output.is_store;
        
    end

endmodule