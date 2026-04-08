
interface vector_data_bus_if();

    logic valid;
    instr_pkg::tag_t tag;
    instr_pkg::vec_data_t data;

    modport writeback (output tag, data, valid);
    modport snoop     (input tag, valid);
    modport write     (input tag, data, valid);

endinterface