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
  "av_st_receiver.vhd",
  "avst_packet_receiver.vhd",
  "avst_packet_sender.vhd",
  "reset_module.vhd",
  "port_io_table.vhd",
  "arp_module.vhd",
  "interface_merger.vhd",
  "trailer_module.vhd",
  "rx_fifo_module.vhd",
  "icmp_module.vhd",
  "ip_header_module.vhd",
  "ip_module.vhd",
#  "ethernet_header_module.vhd",
#  "ethernet_module.vhd",
#  "ethernet_to_udp_module.vhd",
]
