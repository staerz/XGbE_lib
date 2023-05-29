# Additional module options: compile files locally
mod_opt = {'vcom_vlog_library_path': '.'}

# Additional options for modelsim
vcom_opt = '-suppress vcom-1236,vcom-1346 -2008'

# Library name
library = 'PoC'

# List of source files
files = [
  'my_config_altera_none.vhdl',
  'my_project.vhdl',
  'config.vhdl',
  'utils.vhdl',
]
