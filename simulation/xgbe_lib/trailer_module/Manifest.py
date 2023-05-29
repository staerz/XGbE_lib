# Project description
description = 'Simulation of the bare trailer_module'

# Simulating the design
action = 'simulation'

# Top module used for simulation
top_module = 'xgbe_lib_tb.trailer_module_tb'

# Waveforms for simulation
sim_do_cmd = 'wave.do'

# List of modules
modules = {
  'local': [
    '${FPGA_PATH}',  # load BSP, streams senders and receivers
    '../../../src/xgbe_lib',
    '${TESTBENCH_PATH}',
  ],
}

# Default library
library = 'xgbe_lib_tb'

# List of source files for the Reset_module testbench
files = [
  'trailer_module_tb.vhd',
]

# Project configuration override
configuration = {
  # select target device:
  'G_BSP_NONE': {'value': 'True'},
}
