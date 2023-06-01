# Additional module options: compile files locally
# mod_opt = {'vcom_vlog_library_path': '.'}

# Default library
library = 'fpga'

modules = {
  'local': [
    # PoC module: load before context since context uses it
    '../../PoC',
  ],
}

# List of source files
files = [
  'fpga_if.vhd',
  'interfaces.vhd',
]
