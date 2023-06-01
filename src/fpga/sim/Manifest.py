# Additional module options: compile files locally
# mod_opt = {'vcom_vlog_library_path': '.'}

# List of modules
modules = {
  'local' : [
    '../context',
    '../../sim',
  ],
}

# Default library
library = 'fpga'

# List of source files
files = [
  'avst_packet_sender.vhd',
  'avst_packet_receiver.vhd',
]
