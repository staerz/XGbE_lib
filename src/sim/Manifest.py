# Additional module options
mod_opt = {'vcom_vlog_library_path': '.'}

# List of modules (sub-libraries, dependencies)
modules = {
  'local': [
    # PoC module need to be at the same level as common in order for projects sharing it to work
    '../PoC'
  ],
}

# Using VHDL-2008
vcom_opt = '-2008'

# Library name
library = 'sim'

# List of source files for the module
files = [
  'AV_ST_sender.vhd',
  'counter_matcher.vhd',
  'file_writer_hex.vhd',
  'file_reader_hex.vhd',
  'simulation_basics.vhd',
]
