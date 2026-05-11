
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

    always_comb begin

        dmem_data_o = lsu_output.data;
        mem_addr_o = lsu_output.mem_addr[9:2];

        if(!lsu_output.valid || !lsu_output.is_store) write_enable_o = '0;
        else if(lsu_output.is_vector) write_enable_o = '1;
        else begin
            write_enable_o =  '0;
            write_enable_o[lsu_output.mem_addr[1:0]] = 1'b1;
        end
    end

    always_comb begin
        
        vc_wb_o.valid   = vc_wb_valid;
        vc_wb_o.rob_id  = rob_id_q;
        vc_wb_o.prf_tag = prf_tag_q;
        vc_wb_o.data    = dmem_data_i;
        
        sc_wb_o.valid   = sc_wb_valid;
        sc_wb_o.rob_id  = rob_id_q;
        sc_wb_o.prf_tag = prf_tag_q;
        sc_wb_o.data    = dmem_data_i[32*idx + 31:32*idx];

    end

    always @(posedge clk_i) begin
        if(!reset_ni) begin
            rob_id_q <= '0;
            prf_tag_q <= '0;
            idx <= '0;
            sc_wb_valid <= 1'b0;
            vc_wb_valid <= 1'b0;
        end
        else begin
            rob_id_q  <= lsu_output.rob_id;
            prf_tag_q <= lsu_output.prf_tag;
        
            idx <= lsu_output.mem_addr[1:0];

            sc_wb_valid <= lsu_output.valid && !lsu_output.is_vector && !lsu_output.is_store;
            vc_wb_valid <= lsu_output.valid && lsu_output.is_vector && !lsu_output.is_store;
        end
        
    end

endmodule