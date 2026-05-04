interface if_data_bus #(
    parameter type T = signal_pkg::data_t
    );

    logic valid;
    signal_pkg::prf_tag_t prf_tag;
    signal_pkg::rob_address_t rob_id;
    T data;

    modport writeback (
        output valid, 
        output rob_id, prf_tag,
        output data
    );

    modport snoop (
        input valid,
        input rob_id, prf_tag,
        input data
    );

    modport rob (
        input valid,
        input rob_id
    );

    modport prf (
        input valid,
        input prf_tag,
        input data
    );

endinterface