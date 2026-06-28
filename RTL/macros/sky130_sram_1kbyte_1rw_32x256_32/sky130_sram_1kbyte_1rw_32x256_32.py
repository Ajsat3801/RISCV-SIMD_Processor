tech_name = "sky130"

word_size = 32
num_words = 256

num_rw_ports = 1
num_r_ports = 0
num_w_ports = 0

num_banks = 1
words_per_row = 4
num_spare_rows = 1
num_spare_cols = 1

write_size = 32

check_lvsdrc = False
inline_lvsdrc = False
use_pex = False
analytical_delay = True
nominal_corner_only = True
route_supplies = False

process_corners = ["TT"]
supply_voltages = [1.8]
temperatures = [25]

output_path = "output"
output_name = "sky130_sram_32x256"
tech_name = "sky130"
