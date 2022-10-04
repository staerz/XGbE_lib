# Project description
description = "Simulation of the bare rx_fifo_module"

# Simulating the design
action = "simulation"

# Top module used for simulation
top_module = "xgbe_lib.rx_fifo_module_tb"

# Waveforms for simulation
sim_do_cmd = "wave.do"

# List of modules
modules = {
  "local": [
    '$PROJECT_ROOT_PATH/fpga',  # load central BSP of LASP (loads common/misc and common/sim as well)
    "../../../src/xgbe_lib",
    '${TESTBENCH_PATH}',
  ],
}

# Default library
library = "xgbe_lib"

# List of source files for the rx_fifo_module testbench
files = [
  "rx_fifo_module_tb.vhd",
]

# Project configuration override
configuration = {
  # select target device:
  'G_BSP_NONE': {'value': 'True'},
}
