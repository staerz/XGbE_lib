# Additional module options: compile files locally
# mod_opt = {'vcom_vlog_library_path': '.'}

# Library
library = "xgbe_lib"

# modules that sources here depend on
modules = {
  'local': [
    '../memory',
    '../misc',
  ],
}

# List of source files for the module
files = [
  "reset_module.vhd",
  "port_io_table.vhd",
  "arp_module.vhd",
  "dhcp_module.vhd",
  "interface_merger.vhd",
  "interface_splitter.vhd",
  "trailer_module.vhd",
  "rx_fifo_module.vhd",
  "icmp_module.vhd",
  "ip_header_module.vhd",
  "ip_module.vhd",
  "ethernet_header_module.vhd",
  "ethernet_module.vhd",
  "ethernet_to_udp_module.vhd",
]
