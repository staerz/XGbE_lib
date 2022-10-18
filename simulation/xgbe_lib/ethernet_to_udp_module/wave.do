onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/ETH_RDY_FILE
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/ETH_RXD_FILE
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/ETH_TXD_FILE
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/UDP_RDY_FILE
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/UDP_RXD_FILE
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/UDP_TXD_FILE
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/MNL_RST_FILE
add wave -noupdate -group {Constants and Config} -radix binary -radixshowbase 0 /ethernet_to_udp_module_tb/EOP_CHECK_EN
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/MAC_TIMEOUT
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/PAUSE_LENGTH
add wave -noupdate /ethernet_to_udp_module_tb/uut/my_mac_i
add wave -noupdate /ethernet_to_udp_module_tb/uut/my_ip_i
add wave -noupdate /ethernet_to_udp_module_tb/uut/ip_netmask_i
add wave -noupdate /ethernet_to_udp_module_tb/clk
add wave -noupdate /ethernet_to_udp_module_tb/rst
add wave -noupdate -radix decimal -radixshowbase 0 /ethernet_to_udp_module_tb/cnt
add wave -noupdate -color Yellow /ethernet_to_udp_module_tb/uut/eth_rx_ready_o
add wave -noupdate -color Yellow -expand -subitemconfig {/ethernet_to_udp_module_tb/uut/eth_rx_packet_i.data {-color Yellow -height 17} /ethernet_to_udp_module_tb/uut/eth_rx_packet_i.valid {-color Yellow -height 17} /ethernet_to_udp_module_tb/uut/eth_rx_packet_i.sop {-color Yellow -height 17} /ethernet_to_udp_module_tb/uut/eth_rx_packet_i.eop {-color Yellow -height 17} /ethernet_to_udp_module_tb/uut/eth_rx_packet_i.empty {-color Yellow -height 17} /ethernet_to_udp_module_tb/uut/eth_rx_packet_i.error {-color Yellow -height 17}} /ethernet_to_udp_module_tb/uut/eth_rx_packet_i
add wave -noupdate -color Orange /ethernet_to_udp_module_tb/uut/eth_tx_ready_i
add wave -noupdate -color Orange -expand -subitemconfig {/ethernet_to_udp_module_tb/uut/eth_tx_packet_o.data {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/eth_tx_packet_o.valid {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/eth_tx_packet_o.sop {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/eth_tx_packet_o.eop {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/eth_tx_packet_o.empty {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/eth_tx_packet_o.error {-color Orange -height 17}} /ethernet_to_udp_module_tb/uut/eth_tx_packet_o
add wave -noupdate -color Cyan /ethernet_to_udp_module_tb/uut/udp_rx_ready_o
add wave -noupdate -color Cyan /ethernet_to_udp_module_tb/uut/udp_rx_packet_i
add wave -noupdate -color Cyan /ethernet_to_udp_module_tb/uut/udp_rx_id_i
add wave -noupdate -color Magenta /ethernet_to_udp_module_tb/uut/udp_tx_ready_i
add wave -noupdate -color Magenta /ethernet_to_udp_module_tb/uut/udp_tx_packet_o
add wave -noupdate -color Magenta /ethernet_to_udp_module_tb/uut/udp_tx_id_o
add wave -noupdate -group {ethernet module internals} /ethernet_to_udp_module_tb/uut/inst_ethernet_module/blk_stripoff_header/protocol
add wave -noupdate -group {ethernet module internals} /ethernet_to_udp_module_tb/uut/inst_ethernet_module/blk_stripoff_header/rx_count
add wave -noupdate -group {ethernet module internals} /ethernet_to_udp_module_tb/uut/inst_ethernet_module/blk_stripoff_header/rx_mux
add wave -noupdate -group {ethernet module internals} /ethernet_to_udp_module_tb/uut/inst_ethernet_module/blk_stripoff_header/rx_ready
add wave -noupdate -group {ethernet module internals} /ethernet_to_udp_module_tb/uut/inst_ethernet_module/blk_stripoff_header/rx_state
add wave -noupdate -group {ethernet module internals} /ethernet_to_udp_module_tb/uut/inst_ethernet_module/blk_stripoff_header/tx_mux
add wave -noupdate -expand -group {arp module} /ethernet_to_udp_module_tb/uut/inst_arp_module/reco_done_o
add wave -noupdate -expand -group {arp module} /ethernet_to_udp_module_tb/uut/inst_arp_module/reco_en_i
add wave -noupdate -expand -group {arp module} /ethernet_to_udp_module_tb/uut/inst_arp_module/reco_ip_i
add wave -noupdate -expand -group {arp module} /ethernet_to_udp_module_tb/uut/inst_arp_module/reco_mac_o
add wave -noupdate -expand -group {arp module} /ethernet_to_udp_module_tb/uut/inst_arp_module/my_ip_valid_i
add wave -noupdate -expand -group {arp module} /ethernet_to_udp_module_tb/uut/inst_arp_module/blk_make_rx_interface/my_ip_announce
add wave -noupdate -expand -group {arp module} -color Yellow /ethernet_to_udp_module_tb/uut/inst_arp_module/arp_rx_ready_o
add wave -noupdate -expand -group {arp module} -color Yellow /ethernet_to_udp_module_tb/uut/inst_arp_module/arp_rx_packet_i
add wave -noupdate -expand -group {arp module} -color Orange /ethernet_to_udp_module_tb/uut/inst_arp_module/arp_tx_ready_i
add wave -noupdate -expand -group {arp module} -color Orange /ethernet_to_udp_module_tb/uut/inst_arp_module/arp_tx_packet_o
add wave -noupdate -expand -group {arp table internals} /ethernet_to_udp_module_tb/uut/inst_arp_module/blk_arp_table/inst_arp_table/disco_port_i
add wave -noupdate -expand -group {arp table internals} /ethernet_to_udp_module_tb/uut/inst_arp_module/blk_arp_table/inst_arp_table/disco_port_o
add wave -noupdate -expand -group {arp table internals} /ethernet_to_udp_module_tb/uut/inst_arp_module/blk_arp_table/inst_arp_table/disco_wren_i
add wave -noupdate -expand -group {arp table internals} /ethernet_to_udp_module_tb/uut/inst_arp_module/blk_arp_table/inst_arp_table/reco_en_i
add wave -noupdate -expand -group {arp table internals} /ethernet_to_udp_module_tb/uut/inst_arp_module/blk_arp_table/inst_arp_table/reco_found_o
add wave -noupdate -expand -group {arp table internals} /ethernet_to_udp_module_tb/uut/inst_arp_module/blk_arp_table/inst_arp_table/reco_port_i
add wave -noupdate -expand -group {arp table internals} /ethernet_to_udp_module_tb/uut/inst_arp_module/blk_arp_table/inst_arp_table/reco_port_o
add wave -noupdate -expand -group {arp table internals} -color White -expand -subitemconfig {/ethernet_to_udp_module_tb/uut/inst_arp_module/blk_arp_table/inst_arp_table/port_io_table_data(4) {-color White -height 17} /ethernet_to_udp_module_tb/uut/inst_arp_module/blk_arp_table/inst_arp_table/port_io_table_data(3) {-color White -height 17} /ethernet_to_udp_module_tb/uut/inst_arp_module/blk_arp_table/inst_arp_table/port_io_table_data(2) {-color White -height 17} /ethernet_to_udp_module_tb/uut/inst_arp_module/blk_arp_table/inst_arp_table/port_io_table_data(1) {-color White -height 17}} /ethernet_to_udp_module_tb/uut/inst_arp_module/blk_arp_table/inst_arp_table/port_io_table_data
add wave -noupdate -radix decimal -radixshowbase 0 /ethernet_to_udp_module_tb/cnt
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/icmp_in_ready
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/protocol
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/rx_count
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/rx_mux
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/rx_ready
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/rx_state
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/src_ip_accept
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/tx_mux
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/udp_tx_id_r
add wave -noupdate -expand -group {ip module} -color Yellow /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_rx_ready_o
add wave -noupdate -expand -group {ip module} -color Yellow /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_rx_packet_i
add wave -noupdate -expand -group {ip module} -expand -group {icmp internals} -color Orange /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/inst_icmp/icmp_tx_ready_i
add wave -noupdate -expand -group {ip module} -expand -group {icmp internals} -color Orange /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/inst_icmp/icmp_tx_packet_o
add wave -noupdate -expand -group {ip module} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/inst_icmp/is_icmp_request_i
add wave -noupdate -expand -group {ip module} -color Orange /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_tx_ready_i
add wave -noupdate -expand -group {ip module} -color Orange /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_tx_packet_o
add wave -noupdate -expand -group {ip module} -expand -group {ip id table} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/blk_make_ip_udp_table/inst_id_ip_table/disco_wren_i
add wave -noupdate -expand -group {ip module} -expand -group {ip id table} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/blk_make_ip_udp_table/inst_id_ip_table/disco_port_i
add wave -noupdate -expand -group {ip module} -expand -group {ip id table} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/blk_make_ip_udp_table/inst_id_ip_table/disco_port_o
add wave -noupdate -expand -group {ip module} -expand -group {ip id table} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/blk_make_ip_udp_table/inst_id_ip_table/reco_en_i
add wave -noupdate -expand -group {ip module} -expand -group {ip id table} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/blk_make_ip_udp_table/inst_id_ip_table/reco_port_i
add wave -noupdate -expand -group {ip module} -expand -group {ip id table} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/blk_make_ip_udp_table/inst_id_ip_table/reco_port_o
add wave -noupdate -expand -group {ip module} -expand -group {ip id table} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/blk_make_ip_udp_table/inst_id_ip_table/reco_found_o
add wave -noupdate -expand -group {ip module} -expand -group {ip id table} -color White -expand -subitemconfig {/ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/blk_make_ip_udp_table/inst_id_ip_table/port_io_table_data(5) {-color White -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/blk_make_ip_udp_table/inst_id_ip_table/port_io_table_data(4) {-color White -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/blk_make_ip_udp_table/inst_id_ip_table/port_io_table_data(3) {-color White -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/blk_make_ip_udp_table/inst_id_ip_table/port_io_table_data(2) {-color White -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/blk_make_ip_udp_table/inst_id_ip_table/port_io_table_data(1) {-color White -height 17}} /ethernet_to_udp_module_tb/uut/inst_ip_module/blk_stripoff_header/blk_make_ip_udp_table/inst_id_ip_table/port_io_table_data
add wave -noupdate -expand -group {dhcp module} -color {Medium Orchid} /ethernet_to_udp_module_tb/uut/inst_dhcp_module/dhcp_rx_ready_o
add wave -noupdate -expand -group {dhcp module} -color {Medium Orchid} /ethernet_to_udp_module_tb/uut/inst_dhcp_module/dhcp_rx_packet_i
add wave -noupdate -expand -group {dhcp module} -color {Medium Orchid} /ethernet_to_udp_module_tb/uut/inst_dhcp_module/udp_rx_id_i
add wave -noupdate -expand -group {dhcp module} -color Gold /ethernet_to_udp_module_tb/uut/inst_dhcp_module/dhcp_tx_ready_i
add wave -noupdate -expand -group {dhcp module} -color Gold -expand -subitemconfig {/ethernet_to_udp_module_tb/uut/inst_dhcp_module/dhcp_tx_packet_o.data {-color Gold -height 17} /ethernet_to_udp_module_tb/uut/inst_dhcp_module/dhcp_tx_packet_o.valid {-color Gold -height 17} /ethernet_to_udp_module_tb/uut/inst_dhcp_module/dhcp_tx_packet_o.sop {-color Gold -height 17} /ethernet_to_udp_module_tb/uut/inst_dhcp_module/dhcp_tx_packet_o.eop {-color Gold -height 17} /ethernet_to_udp_module_tb/uut/inst_dhcp_module/dhcp_tx_packet_o.empty {-color Gold -height 17} /ethernet_to_udp_module_tb/uut/inst_dhcp_module/dhcp_tx_packet_o.error {-color Gold -height 17}} /ethernet_to_udp_module_tb/uut/inst_dhcp_module/dhcp_tx_packet_o
add wave -noupdate -expand -group {dhcp module} -color Gold /ethernet_to_udp_module_tb/uut/inst_dhcp_module/udp_tx_id_o
add wave -noupdate -expand -group {dhcp module} /ethernet_to_udp_module_tb/uut/inst_dhcp_module/my_ip_o
add wave -noupdate -expand -group {dhcp module} /ethernet_to_udp_module_tb/uut/inst_dhcp_module/ip_netmask_o
add wave -noupdate -color Cyan /ethernet_to_udp_module_tb/uut/inst_dhcp_module/dhcp_state
add wave -noupdate /ethernet_to_udp_module_tb/uut/inst_dhcp_module/blk_make_rx_interface/rx_state
add wave -noupdate -expand -group {interface splitter} /ethernet_to_udp_module_tb/uut/inst_interface_splitter/PORT_LIST
add wave -noupdate -expand -group {interface splitter} /ethernet_to_udp_module_tb/uut/inst_interface_splitter/DATA_W_OFFSET
add wave -noupdate -expand -group {interface splitter} /ethernet_to_udp_module_tb/uut/inst_interface_splitter/avst_rx_ready_o
add wave -noupdate -expand -group {interface splitter} /ethernet_to_udp_module_tb/uut/inst_interface_splitter/avst_rx_packet_i
add wave -noupdate -expand -group {interface splitter} /ethernet_to_udp_module_tb/uut/inst_interface_splitter/avst_tx_readys_i
add wave -noupdate -expand -group {interface splitter} /ethernet_to_udp_module_tb/uut/inst_interface_splitter/avst_tx_packet_o
add wave -noupdate -expand -group {interface splitter} -radix binary -radixshowbase 1 /ethernet_to_udp_module_tb/uut/inst_interface_splitter/status_vector_o
add wave -noupdate -expand -group {interface splitter} /ethernet_to_udp_module_tb/uut/inst_interface_splitter/rx_state
add wave -noupdate -expand -group {interface splitter} /ethernet_to_udp_module_tb/uut/inst_interface_splitter/rx_mux
add wave -noupdate -expand -group {interface splitter} /ethernet_to_udp_module_tb/uut/inst_interface_splitter/rx_ready
add wave -noupdate -expand -group {interface splitter} /ethernet_to_udp_module_tb/uut/inst_interface_splitter/first_port
add wave -noupdate -expand -group {interface splitter} /ethernet_to_udp_module_tb/uut/inst_interface_splitter/port_info
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2940284 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 227
configure wave -valuecolwidth 178
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {5953200 ps}
run -all