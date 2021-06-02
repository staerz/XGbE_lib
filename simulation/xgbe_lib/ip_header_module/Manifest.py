# Project description
description = "Simulation of the bare ip_header_module"

# Simulating the design
action = "simulation"

# Top module used for simulation
top_module = "xgbe_lib.ip_header_module_tb"

# Waveforms for simulation
sim_do_cmd = "wave.do"

# List of modules
modules = {
  "local" : [
    '$PROJECT_ROOT_PATH/fpga', # load central BSP of LASP (loads common/misc and common/sim as well)
    "../../../src/xgbe_lib",
  ],
}

# Default library
library = "xgbe_lib"

# List of source files for the ip_header_module testbench
files = [
  "ip_header_module_tb.vhd",
]

# Project configuration override
configuration = {
  # select target device:
  'G_BSP_NONE'      : {'value': 'True', 'description': 'No actual target, use default FPGA, no constraints, Default: False.'},
}