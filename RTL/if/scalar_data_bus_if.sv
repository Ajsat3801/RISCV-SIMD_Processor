interface scalar_data_bus_if();

    logic valid;
    instr_pkg::prf_tag_t prf_tag;
    instr_pkg::rob_address_t rob_id;
    instr_pkg::data_t data;

    modport writeback (output valid, rob_id, prf_tag, data);
    modport snoop     (input  valid, rob_id, prf_tag, data);

endinterface