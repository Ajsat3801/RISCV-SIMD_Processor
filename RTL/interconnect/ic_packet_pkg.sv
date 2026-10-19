package ic_packet_pkg;

    import ic_config_pkg::*;

    //  -------------------------------------------------------------------------------------------
    //          Signal definitions

    typedef enum logic[1:0] {OKAY = 2'b00, EXOKAY = 2'b01, SLVERR = 2'b10, DECERR = 2'b11} axi_resp_e;
    typedef enum logic[1:0] {FIXED = 2'b00, INCR = 2'b01, WRAP = 2'b10} axi_burst_e;

    typedef logic [ADDR_WIDTH-1:0] axi_addr_t;
    typedef logic [2:0]  axi_size_t;  // spec fixes to 3 bits

    typedef logic [3:0]  axi_cache_t; // spec fixes to 4 bits
    typedef logic [2:0]  axi_prot_t;
    typedef logic[ID_R_WIDTH-1 : 0] axi_rd_id_t;
    typedef logic[ID_W_WIDTH-1 : 0] axi_wr_id_t;

    typedef logic [7:0]  axi_len_t;   // spec fixes to 8 bits
    typedef logic        axi_lock_t;
    typedef logic [3:0]  axi_qos_t;
    
    typedef logic[DATA_WIDTH-1:0] axi_data_t;
    typedef logic[DATA_WIDTH/8-1:0] axi_strb_t;

    //  -------------------------------------------------------------------------------------------
    //          Channel definitions

    typedef struct packed {
        axi_addr_t araddr;
        axi_size_t arsize;
        axi_burst_e arburst;
        axi_cache_t arcache;
        axi_prot_t arprot;
        axi_rd_id_t arid;
        axi_len_t arlen;
        axi_lock_t arlock;
        axi_qos_t arqos;
    } axi_ar_t;

    typedef struct packed {
        logic rlast;
        axi_data_t rdata;
        axi_resp_e rresp;
        axi_rd_id_t rid;
    } axi_r_t;

    typedef struct packed {
        axi_addr_t awaddr;
        axi_size_t awsize;
        axi_burst_e awburst;
        axi_cache_t awcache;
        axi_prot_t awprot;
        axi_wr_id_t awid;
        axi_len_t awlen;
        axi_lock_t awlock;
        axi_qos_t awqos;
    } axi_aw_t;

    typedef struct packed {
        logic wlast;
        axi_data_t wdata;
        axi_strb_t wstrb;
    } axi_w_t;

    typedef struct packed {
        axi_resp_e bresp;
        axi_wr_id_t bid;
    } axi_b_t;

    //  -------------------------------------------------------------------------------------------
    //          Ports by direction

    typedef struct packed {
        logic axi_arvalid;
        axi_ar_t axi_ar;

        logic axi_awvalid;
        axi_aw_t axi_aw;

        logic axi_wvalid;
        axi_w_t axi_w;

        logic axi_rready;
        logic axi_bready;

    } mgr_out_t; // manager to subordinate

    typedef struct packed {
        
        logic axi_rvalid;
        axi_r_t axi_r;

        logic axi_bvalid;
        axi_b_t axi_b;

        logic axi_arready;
        logic axi_awready;
        logic axi_wready;
    } sub_out_t; // subordinate to manager

endpackage