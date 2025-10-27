//TOP module

module top(
    input clk,
    input imem_out,
    input dmem_out,
    input dmem_busy,
    output dmem_store_data,
    output dmem_address
    // no data inputs or outputs, it will directly change in DMEM
);

/*

    IMEM out connects to fetch
    Fetch connects to Decode
    Decode connects to the various pipelines + scalar & vector registers
    DMEM connects with core

*/

endmodule