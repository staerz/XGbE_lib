# Additional module options
mod_opt = {'vcom_vlog_library_path': '.'}

# List of modules (sub-libraries, dependencies)
modules = {
  'local': [
    '../PoC',
  ],
}

# Using VHDL-2008
vcom_opt = '-2008'

# Default library
library = 'memory'

# List of source files for the module
files = [
  'generic_fifo.vhd',
  'altera_fifo.vhd',
]
