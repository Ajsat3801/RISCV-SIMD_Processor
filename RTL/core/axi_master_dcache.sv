
module axi_master_dcache (
    input logic clk_i,
    input logic reset_ni,
    
    // Controller <-> DCache - read channel
    input packet_pkg::mem_read_request_t dcache_mem_rd_req_i,
    output packet_pkg::mem_read_response_t dcache_mem_rd_res_o,
    
    // Controller <-> Dcache - write channel
    input packet_pkg::mem_write_request_t dcache_mem_wrt_req_i,
    output logic dcache_mem_wrt_done_o,

    // Controller <-> Dcache backpressure
    output logic dcache_mem_rd_rdy_o,
    output logic dcache_mem_wrt_rdy_o,

    // AXI input/output
    input  ic_packet_pkg::sub_out_t data_mgr_port_i,
    output ic_packet_pkg::mgr_out_t data_mgr_port_o,
    output logic axi_error_o
);

    //  -------------------------------------------------------------------------------------------
    //      Typedefs and localparams

    localparam int unsigned BEAT_N = ic_config_pkg::LINE_W/ic_config_pkg::DATA_WIDTH;
    localparam int unsigned BEAT_W = (BEAT_N > 1) ? $clog2(BEAT_N) : 1;
    
    typedef logic[BEAT_W-1:0] beat_t;
    typedef logic[BEAT_N-1:0] [ic_config_pkg::DATA_WIDTH-1:0] axi_line_t;

    typedef enum logic [1:0] {
        RD_IDLE,        // Idle, ready to accept read requests from dcache
        RD_WAIT,        // Master waiting for subordinate to be ready
        RD_DATA         // Master-subordinate handshake complete, reading data in progress
    } read_state_e; 

    typedef enum logic [1:0] {
        WT_IDLE,        // Idle, ready to accept write requests from dcache
        WT_SEND,        // Sends AW & W payload
        WT_WAIT         // Wait for BRESP
    } write_state_e;
    
    typedef struct packed {
        read_state_e state;
        ic_packet_pkg::axi_addr_t addr;
        beat_t beat;
        axi_line_t data;
    } read_buffer_t;

    typedef struct packed {
        write_state_e state;
        logic w_done;
        logic aw_done;
        ic_packet_pkg::axi_addr_t addr;
        beat_t beat;
        axi_line_t data;
    } write_buffer_t;
    
    //  -------------------------------------------------------------------------------------------
    //          AXI Read Channels

    read_buffer_t read_buf_q, read_buf_d;
    logic r_error_d, r_error_q;

    logic ar_handshake, r_handshake, r_last;
    
    assign ar_handshake = data_mgr_port_o.arvalid && data_mgr_port_i.arready;
    assign r_handshake  = data_mgr_port_o.rready  && data_mgr_port_i.rvalid;
    assign r_last = data_mgr_port_i.r.rlast;

    function automatic ic_packet_pkg::axi_ar_t gen_ar_req(ic_packet_pkg::axi_addr_t adr);
        gen_ar_req = '{
            araddr  : adr,
            arsize  : ic_const_pkg::AXSIZE,
            arburst : ic_packet_pkg::INCR,
            arcache : ic_const_pkg::AXCACHE,
            arprot  : ic_const_pkg::AXPROT_D,
            arid    : '0,
            arlen   : ic_const_pkg::AXLEN,
            arlock  : ic_const_pkg::AXLOCK,
            arqos   : ic_const_pkg::AXQOS
        };
    endfunction

    always_comb begin
        read_buf_d = read_buf_q;

        unique case(read_buf_q.state)
            RD_IDLE: if(dcache_mem_rd_req_i.valid) begin
                read_buf_d.state = RD_WAIT;
                read_buf_d.addr  = dcache_mem_rd_req_i.addr;
                read_buf_d.beat  = '0;
            end

            RD_WAIT: if(ar_handshake) read_buf_d.state = RD_DATA;

            RD_DATA: if(r_handshake) begin
                read_buf_d.data[read_buf_q.beat] = data_mgr_port_i.r.rdata;
                read_buf_d.beat = read_buf_q.beat + 1'b1;
                if(r_last) read_buf_d.state = RD_IDLE;
            end
            default:;
        endcase

        r_error_d = r_error_q || (r_handshake && (data_mgr_port_i.r.rresp != ic_packet_pkg::OKAY));
    end

    always_ff @(posedge clk_i) begin
        if(!reset_ni) begin
            read_buf_q <= '0;
            r_error_q  <= '0;
        end
        else begin
            read_buf_q <= read_buf_d;
            r_error_q  <= r_error_d;
        end
    end

    assign data_mgr_port_o.ar = gen_ar_req(read_buf_q.addr);

    assign data_mgr_port_o.arvalid = (read_buf_q.state == RD_WAIT);
    assign data_mgr_port_o.rready  = (read_buf_q.state == RD_DATA);

    //  -------------------------------------------------------------------------------------------
    //          AXI Write Channels

    write_buffer_t write_buf_q, write_buf_d;
    logic w_error_d, w_error_q;

    logic w_handshake, aw_handshake, b_handshake;
    logic w_last;
    
    assign aw_handshake = data_mgr_port_o.awvalid && data_mgr_port_i.awready;
    assign w_handshake  = data_mgr_port_o.wvalid  && data_mgr_port_i.wready;
    assign b_handshake  = data_mgr_port_i.bvalid  && data_mgr_port_o.bready;
    assign w_last = (write_buf_q.beat == beat_t'(BEAT_N-1));

    function automatic ic_packet_pkg::axi_aw_t gen_aw(ic_packet_pkg::axi_addr_t adr);
        gen_aw = '{
            awaddr  : adr,
            awsize  : ic_const_pkg::AXSIZE,
            awburst : ic_packet_pkg::INCR,
            awcache : ic_const_pkg::AXCACHE,
            awprot  : ic_const_pkg::AXPROT_D,
            awid    : '0,
            awlen   : ic_const_pkg::AXLEN,
            awlock  : ic_const_pkg::AXLOCK,
            awqos   : ic_const_pkg::AXQOS
        };
    endfunction

    function automatic ic_packet_pkg::axi_w_t gen_w(
        axi_line_t dta,
        beat_t bt,
        logic last
    );
        gen_w = '{
            wlast : last,
            wdata : dta[bt],
            wstrb : ic_const_pkg::WSTRB
        };
    endfunction
    
    always_comb begin
        write_buf_d = write_buf_q;

        unique case (write_buf_q.state)
            WT_IDLE: if(dcache_mem_wrt_req_i.valid) begin
                write_buf_d.state   = WT_SEND;
                write_buf_d.addr    = dcache_mem_wrt_req_i.addr;
                write_buf_d.beat    = '0;
                write_buf_d.data    = axi_line_t'(dcache_mem_wrt_req_i.data);
                write_buf_d.aw_done = 1'b0;
                write_buf_d.w_done  = 1'b0;
            end
            WT_SEND: begin
                if(aw_handshake ) write_buf_d.aw_done = 1'b1;
                if(w_handshake) begin
                    write_buf_d.beat = write_buf_q.beat + 1'b1;
                    if(w_last) write_buf_d.w_done = 1'b1;
                end
                
                if (write_buf_d.aw_done && write_buf_d.w_done) write_buf_d.state = WT_WAIT;
            end

            WT_WAIT: if(b_handshake) write_buf_d.state = WT_IDLE;
            
            default:;
        endcase

        w_error_d = w_error_q || (b_handshake && (data_mgr_port_i.b.bresp != ic_packet_pkg::OKAY));

    end

    always_ff @(posedge clk_i) begin
        if(!reset_ni) begin
            write_buf_q <= '0;
            w_error_q   <= '0;
        end
        else begin
            write_buf_q <= write_buf_d;
            w_error_q   <= w_error_d;
        end
    end
    
    assign data_mgr_port_o.aw = gen_aw(write_buf_q.addr);
    assign data_mgr_port_o.w  = gen_w(write_buf_q.data,write_buf_q.beat,w_last);
    
    assign data_mgr_port_o.awvalid = (write_buf_q.state == WT_SEND) && !write_buf_q.aw_done;
    assign data_mgr_port_o.wvalid  = (write_buf_q.state == WT_SEND) && !write_buf_q.w_done;
    assign data_mgr_port_o.bready  = write_buf_q.state == WT_WAIT;

    //  -------------------------------------------------------------------------------------------
    //          Dcache outputs & error handling

    assign dcache_mem_rd_res_o.valid = r_handshake && r_last;
    assign dcache_mem_rd_res_o.data  = signal_pkg::vector_data_t'(read_buf_d.data);

    assign dcache_mem_wrt_done_o = b_handshake;

    assign dcache_mem_rd_rdy_o  = (read_buf_q.state == RD_IDLE);
    assign dcache_mem_wrt_rdy_o = (write_buf_q.state == WT_IDLE);

    assign axi_error_o = r_error_q || w_error_q;

    //  -------------------------------------------------------------------------------------------
    //          Sim only error reporting

    `ifndef SYNTHESIS
        always_ff @(posedge clk_i) begin
            if(reset_ni && r_handshake && (data_mgr_port_i.r.rresp != ic_packet_pkg::OKAY))
                $error("dcache RRESP=%s addr=0x%0h", data_mgr_port_i.r.rresp.name(), read_buf_q.addr);
            if(reset_ni && b_handshake && (data_mgr_port_i.b.bresp != ic_packet_pkg::OKAY))
                $error("dcache BRESP=%s addr=0x%0h", data_mgr_port_i.b.bresp.name(), write_buf_q.addr);
        end
    `endif

endmodule