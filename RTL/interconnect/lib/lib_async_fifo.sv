// Async FIFO based CDC implementation.

module lib_async_fifo #(
    parameter int unsigned FIFO_DEPTH = 8, // Must be power of 2 & >=4
    parameter type T = logic [31:0]
) (
    // Source clock side inputs
    input  logic src_clk_i,
    input  logic src_reset_ni,
    input  T src_data_i,
    input  logic src_valid_i,
    output logic src_ready_o,

    // Destination clock side inputs
    input  logic dst_clk_i,
    input  logic dst_reset_ni,
    input  logic dst_ready_i,
    output logic dst_valid_o,
    output T dst_data_o
);

//  -----------------------------------------------------------------------------------------------
//      Localparams & Functions

    // log(FIFO_DEPTH) bits for address and 1 bit for epoch
    localparam int unsigned PTR_W = $clog2(FIFO_DEPTH) + 1;
    typedef logic[PTR_W-1:0] fifo_ptr_t; 

    function automatic fifo_ptr_t bin2gray(fifo_ptr_t bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction

//  -----------------------------------------------------------------------------------------------
//      FIFO for data
    
    T fifo [FIFO_DEPTH-1:0];
    fifo_ptr_t b_rd_ptr, b_wt_ptr;
    logic wrt_en;

    // combinational read
    assign dst_data_o = fifo[b_rd_ptr[PTR_W-2:0]];

    // sequential write if write enable is asserted and there is no reset
    always_ff @(posedge src_clk_i) begin
        if(src_reset_ni && wrt_en) fifo[b_wt_ptr[PTR_W-2:0]] <= src_data_i;
    end

//  -----------------------------------------------------------------------------------------------
//      Synchronizers

    fifo_ptr_t usync_rptr_d, usync_rptr_q;   // gray coded read pointer
    fifo_ptr_t sync_rptr;
    fifo_ptr_t usync_wptr_d, usync_wptr_q;   // gray coded write pointer
    fifo_ptr_t sync_wptr;         // gray coded pointer afer synchronization 

    lib_nflop_sync #(.WIDTH(PTR_W)) u_read_synchronizer(
        .clk_i(src_clk_i), .reset_ni(src_reset_ni),
        .data_i(usync_rptr_q), .data_o(sync_rptr)
    );

    lib_nflop_sync #(.WIDTH(PTR_W)) u_write_synchronizer (
        .clk_i(dst_clk_i), .reset_ni(dst_reset_ni),
        .data_i(usync_wptr_q), .data_o(sync_wptr)
    );

//  -----------------------------------------------------------------------------------------------
//      FIFO full and empty conditions

    // Note: sequential because otherwise a circular combinational loop will be formed

    logic fifo_full, fifo_empty;

    always_ff @(posedge src_clk_i) begin
        if(!src_reset_ni) fifo_full <= 1'b0;
        // gray equivalent of all but the MSB match in binary
        else fifo_full <= (usync_wptr_d == {~sync_rptr[PTR_W-1:PTR_W-2], sync_rptr[PTR_W-3:0]});
    end

    always_ff @(posedge dst_clk_i) begin
        if(!dst_reset_ni) fifo_empty <= 1'b1;
        else fifo_empty <= (usync_rptr_d == sync_wptr);
    end

//  -----------------------------------------------------------------------------------------------
//      Write handler - source clock

    fifo_ptr_t write_ptr_d, write_ptr_q;
    
    assign usync_wptr_d = bin2gray(write_ptr_d); // cannot be combinational derived from FF
    
    always_comb begin
        write_ptr_d = write_ptr_q;
        if(src_valid_i && !fifo_full) write_ptr_d = write_ptr_q + 1'b1;
    end

    always_ff @(posedge src_clk_i) begin
        if(!src_reset_ni) begin
            write_ptr_q <= '0;
            usync_wptr_q <= '0;
        end
        else begin
            write_ptr_q <= write_ptr_d;
            usync_wptr_q <= usync_wptr_d;
        end
    end

    assign wrt_en = src_valid_i && !fifo_full;
    assign b_wt_ptr = write_ptr_q;

//  -----------------------------------------------------------------------------------------------
//      Read Handler - Destination clock

    fifo_ptr_t read_ptr_d, read_ptr_q;

    assign usync_rptr_d = bin2gray(read_ptr_d);
    
    always_comb begin
        read_ptr_d = read_ptr_q;
        if(dst_ready_i && !fifo_empty) read_ptr_d = read_ptr_q + 1'b1;
    end
    
    always_ff @(posedge dst_clk_i) begin
        if(!dst_reset_ni) begin
            read_ptr_q <= '0;
            usync_rptr_q <= '0;
        end
        else begin
            read_ptr_q <= read_ptr_d;
            usync_rptr_q <= usync_rptr_d;
        end
    end

    assign b_rd_ptr = read_ptr_q;

//  -----------------------------------------------------------------------------------------------
//      Output Control signals

    assign dst_valid_o = !fifo_empty;
    assign src_ready_o = !fifo_full;
    
endmodule 