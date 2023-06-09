# Project description
description = 'Simulation of the bare ethernet_to_udp_module with dynamic DHCP enable: OFF first, then turned ON and OFF again'

# Simulating the design
action = 'simulation'

# Top module used for simulation
top_module = 'xgbe_lib.ethernet_to_udp_module_tb'

# Waveforms for simulation
sim_do_cmd = '../wave.do'

# List of modules
modules = {
  "local": [
    '${FPGA_PATH}',  # load BSP, streams senders and receivers
    "../../../../src/xgbe_lib",
    '${TESTBENCH_PATH}',
  ],
}

# Default library
library = "xgbe_lib"

# List of source files for the Reset_module testbench
files = [
  "../ethernet_to_udp_module_tb.vhd",
]

# Project configuration override
configuration = {
  # select target device:
  'G_BSP_NONE': {'value': 'True'},
  'DHCP_SWITCH': {'type': 'string', 'value': 'DYN', 'module_name': 'xgbe_lib', 'description': 'DHCP enable'},
}
