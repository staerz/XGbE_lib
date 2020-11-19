# Project description
description = 'Simulation of the bare port_io_table'

# Simulating the design
action = 'simulation'

# Top module used for simulation
top_module = 'ethernet_lib.port_io_table_tb'

# Waveforms for simulation
sim_do_cmd = 'wave.do'

# List of modules
modules = {
  'local' : [
    '$PROJECT_ROOT_PATH/fpga', # load central BSP of LASP (loads common/misc and common/sim as well)
    '../../../src/ethernet_lib',
  ],
}

# Default library
library = 'ethernet_lib'

# List of source files for the Reset_module testbench
files = [
  'port_io_table_tb.vhd',
]

# Project configuration override
configuration = {
  # select target device:
  'G_FPGA_HW_NONE'      : {'value': 'True', 'description': 'No actual target, use default FPGA, no constraints, Default: False.'},
}