# List of modules
modules = {
  "local" : [
    '$PROJECT_ROOT_PATH/common/src/memory',
  ],
}

# Library
library = "ethernet_lib"

# List of source files for the module
files = [
  "interface_merger.vhd",
  "port_io_table.vhd",
  "arp_module.vhd",
  "reset_module.vhd",
]
