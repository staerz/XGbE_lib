# Additional module options: compile files locally
mod_opt = {'vcom_vlog_library_path': '.'}

# List of modules (sub-libraries, dependencies)
modules = {
  'local': [
    '../PoC',
    {'../altera': {'action': 'simulation'}},  #  delay chain uses it ... how can we only include the syn attributes?
  ],
}

# Using VHDL-2008
vcom_opt = '-2008'

# Library name
library = 'misc'

# List of source files for the module
files = [
  'checksum_calc.vhd',
  'counter.vhd',
  'counting.vhd',
  'delay_chain.vhd',
  'hilo_detect.vhd',
]
