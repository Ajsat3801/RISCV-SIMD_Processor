interface data_bus_if #(
    parameter type T = instr_pkg::data_t
    );

    logic valid;
    instr_pkg::prf_tag_t prf_tag;
    instr_pkg::rob_address_t rob_id;
    T data;

    modport writeback (output valid, rob_id, prf_tag, data);
    modport snoop     (input  valid, rob_id, prf_tag, data);
    modport rob       (input  valid, rob_id);
    modport prf       (input  valid, prf_tag, data)

endinterface