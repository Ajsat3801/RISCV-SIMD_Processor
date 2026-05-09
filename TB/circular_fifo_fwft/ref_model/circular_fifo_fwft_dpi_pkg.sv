
package lib_fifo_fwft_1push_dpi_pkg;

// max size of DPI call = 160 (4*32 SIMD data + 32 max metadata)
import "DPI-C" function void lib_fifo_fwft_1push_model_create(int size);

import "DPI-C" function void lib_fifo_fwft_1push_model_run(
	input bit[159:0] data,
	output bit[159:0] output_buffer,
	input bit push,
	input bit pop,
    output bit full,
    output bit empty,
  	input int numwords
);

endpackage