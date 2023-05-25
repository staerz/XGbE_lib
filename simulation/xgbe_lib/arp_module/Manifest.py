# Project description
description = 'Simulation of the bare arp_module'

# Simulating the design
action = 'simulation'

# Top module used for simulation
top_module = 'xgbe_lib.arp_module_tb'

# Waveforms for simulation
sim_do_cmd = 'wave.do'

# List of modules
modules = {
  "local": [
    '$PROJECT_ROOT_PATH/fpga',  # load central BSP of LASP (loads common/misc and common/sim as well)
    '$PROJECT_ROOT_PATH/fpga/src/public',  # load streams senders and receivers
    "../../../src/xgbe_lib",
    '${TESTBENCH_PATH}',
  ],
}

# Default library
library = "xgbe_lib"

# List of source files for the Reset_module testbench
files = [
  "arp_module_tb.vhd",
]

# Project configuration override
configuration = {
  # select target device:
  'G_BSP_NONE': {'value': 'True'},
}
