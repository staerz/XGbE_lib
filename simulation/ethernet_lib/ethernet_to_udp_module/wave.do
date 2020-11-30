onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/ETH_RDY_FILE
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/ETH_RXD_FILE
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/ETH_TXD_FILE
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/UDP_RDY_FILE
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/UDP_RXD_FILE
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/UDP_TXD_FILE
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/MNL_RST_FILE
add wave -noupdate -group {Constants and Config} -radix binary -radixshowbase 0 /ethernet_to_udp_module_tb/EOF_CHECK_EN
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/MAC_TIMEOUT
add wave -noupdate -group {Constants and Config} /ethernet_to_udp_module_tb/PAUSE_LENGTH
add wave -noupdate -group {Constants and Config} -radix hexadecimal -radixshowbase 0 /ethernet_to_udp_module_tb/my_mac
add wave -noupdate /ethernet_to_udp_module_tb/uut/my_mac
add wave -noupdate /ethernet_to_udp_module_tb/uut/my_ip
add wave -noupdate /ethernet_to_udp_module_tb/uut/ip_netmask
add wave -noupdate /ethernet_to_udp_module_tb/clk
add wave -noupdate /ethernet_to_udp_module_tb/rst
add wave -noupdate -radix unsigned /ethernet_to_udp_module_tb/blk_simulation/counter
add wave -noupdate -color Yellow /ethernet_to_udp_module_tb/uut/eth_rx_ready
add wave -noupdate -color Yellow /ethernet_to_udp_module_tb/uut/eth_rx_data
add wave -noupdate -color Yellow -expand -subitemconfig {/ethernet_to_udp_module_tb/uut/eth_rx_ctrl(6) {-color Yellow -height 17} /ethernet_to_udp_module_tb/uut/eth_rx_ctrl(5) {-color Yellow -height 17} /ethernet_to_udp_module_tb/uut/eth_rx_ctrl(4) {-color Yellow -height 17} /ethernet_to_udp_module_tb/uut/eth_rx_ctrl(3) {-color Yellow -height 17} /ethernet_to_udp_module_tb/uut/eth_rx_ctrl(2) {-color Yellow -height 17} /ethernet_to_udp_module_tb/uut/eth_rx_ctrl(1) {-color Yellow -height 17} /ethernet_to_udp_module_tb/uut/eth_rx_ctrl(0) {-color Yellow -height 17}} /ethernet_to_udp_module_tb/uut/eth_rx_ctrl
add wave -noupdate -color Orange /ethernet_to_udp_module_tb/uut/eth_tx_ready
add wave -noupdate -color Orange /ethernet_to_udp_module_tb/uut/eth_tx_data
add wave -noupdate -color Orange -expand -subitemconfig {/ethernet_to_udp_module_tb/uut/eth_tx_ctrl(6) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/eth_tx_ctrl(5) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/eth_tx_ctrl(4) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/eth_tx_ctrl(3) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/eth_tx_ctrl(2) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/eth_tx_ctrl(1) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/eth_tx_ctrl(0) {-color Orange -height 17}} /ethernet_to_udp_module_tb/uut/eth_tx_ctrl
add wave -noupdate -color Cyan /ethernet_to_udp_module_tb/uut/udp_rx_ready
add wave -noupdate -color Cyan /ethernet_to_udp_module_tb/uut/udp_rx_data
add wave -noupdate -color Cyan -expand -subitemconfig {/ethernet_to_udp_module_tb/uut/udp_rx_ctrl(6) {-color Cyan -height 17} /ethernet_to_udp_module_tb/uut/udp_rx_ctrl(5) {-color Cyan -height 17} /ethernet_to_udp_module_tb/uut/udp_rx_ctrl(4) {-color Cyan -height 17} /ethernet_to_udp_module_tb/uut/udp_rx_ctrl(3) {-color Cyan -height 17} /ethernet_to_udp_module_tb/uut/udp_rx_ctrl(2) {-color Cyan -height 17} /ethernet_to_udp_module_tb/uut/udp_rx_ctrl(1) {-color Cyan -height 17} /ethernet_to_udp_module_tb/uut/udp_rx_ctrl(0) {-color Cyan -height 17}} /ethernet_to_udp_module_tb/uut/udp_rx_ctrl
add wave -noupdate -color Cyan /ethernet_to_udp_module_tb/uut/udp_rx_id
add wave -noupdate -color Magenta /ethernet_to_udp_module_tb/uut/udp_tx_ready
add wave -noupdate -color Magenta /ethernet_to_udp_module_tb/uut/udp_tx_data
add wave -noupdate -color Magenta -expand -subitemconfig {/ethernet_to_udp_module_tb/uut/udp_tx_ctrl(6) {-color Magenta} /ethernet_to_udp_module_tb/uut/udp_tx_ctrl(5) {-color Magenta} /ethernet_to_udp_module_tb/uut/udp_tx_ctrl(4) {-color Magenta} /ethernet_to_udp_module_tb/uut/udp_tx_ctrl(3) {-color Magenta} /ethernet_to_udp_module_tb/uut/udp_tx_ctrl(2) {-color Magenta} /ethernet_to_udp_module_tb/uut/udp_tx_ctrl(1) {-color Magenta} /ethernet_to_udp_module_tb/uut/udp_tx_ctrl(0) {-color Magenta}} /ethernet_to_udp_module_tb/uut/udp_tx_ctrl
add wave -noupdate -color Magenta /ethernet_to_udp_module_tb/uut/udp_tx_id
add wave -noupdate -group {ethernet module internals} /ethernet_to_udp_module_tb/uut/inst_ethernet_module/stripoff_header/protocol
add wave -noupdate -group {ethernet module internals} /ethernet_to_udp_module_tb/uut/inst_ethernet_module/stripoff_header/rx_count
add wave -noupdate -group {ethernet module internals} /ethernet_to_udp_module_tb/uut/inst_ethernet_module/stripoff_header/rx_eof
add wave -noupdate -group {ethernet module internals} /ethernet_to_udp_module_tb/uut/inst_ethernet_module/stripoff_header/rx_mux
add wave -noupdate -group {ethernet module internals} /ethernet_to_udp_module_tb/uut/inst_ethernet_module/stripoff_header/rx_ready
add wave -noupdate -group {ethernet module internals} /ethernet_to_udp_module_tb/uut/inst_ethernet_module/stripoff_header/rx_sof
add wave -noupdate -group {ethernet module internals} /ethernet_to_udp_module_tb/uut/inst_ethernet_module/stripoff_header/rx_state
add wave -noupdate -group {ethernet module internals} /ethernet_to_udp_module_tb/uut/inst_ethernet_module/stripoff_header/tx_mux
add wave -noupdate -expand -group {arp module} -color Yellow /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_rx_ready
add wave -noupdate -expand -group {arp module} -color Yellow /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_rx_data
add wave -noupdate -expand -group {arp module} -color Yellow -expand -subitemconfig {/ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_rx_ctrl(6) {-color Yellow} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_rx_ctrl(5) {-color Yellow} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_rx_ctrl(4) {-color Yellow} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_rx_ctrl(3) {-color Yellow} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_rx_ctrl(2) {-color Yellow} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_rx_ctrl(1) {-color Yellow} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_rx_ctrl(0) {-color Yellow}} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_rx_ctrl
add wave -noupdate -expand -group {arp module} -color Orange /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_tx_ready
add wave -noupdate -expand -group {arp module} -color Orange /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_tx_data
add wave -noupdate -expand -group {arp module} -color Orange -expand -subitemconfig {/ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_tx_ctrl(6) {-color Orange} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_tx_ctrl(5) {-color Orange} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_tx_ctrl(4) {-color Orange} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_tx_ctrl(3) {-color Orange} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_tx_ctrl(2) {-color Orange} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_tx_ctrl(1) {-color Orange} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_tx_ctrl(0) {-color Orange}} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_tx_ctrl
add wave -noupdate -expand -group {arp table internals} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_table_block/arp_table_inst/disco_pin
add wave -noupdate -expand -group {arp table internals} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_table_block/arp_table_inst/disco_pout
add wave -noupdate -expand -group {arp table internals} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_table_block/arp_table_inst/disco_wren
add wave -noupdate -expand -group {arp table internals} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_table_block/arp_table_inst/reco_en
add wave -noupdate -expand -group {arp table internals} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_table_block/arp_table_inst/reco_found
add wave -noupdate -expand -group {arp table internals} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_table_block/arp_table_inst/reco_pin
add wave -noupdate -expand -group {arp table internals} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_table_block/arp_table_inst/reco_pout
add wave -noupdate -expand -group {arp table internals} -color White -expand -subitemconfig {/ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_table_block/arp_table_inst/port_io_table_data(4) {-color White -height 17} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_table_block/arp_table_inst/port_io_table_data(3) {-color White -height 17} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_table_block/arp_table_inst/port_io_table_data(2) {-color White -height 17} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_table_block/arp_table_inst/port_io_table_data(1) {-color White -height 17}} /ethernet_to_udp_module_tb/uut/isnt_arp_module/arp_table_block/arp_table_inst/port_io_table_data
add wave -noupdate -radix unsigned /ethernet_to_udp_module_tb/blk_simulation/counter
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/icmp_in_ready
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/protocol
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/rx_count
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/rx_eof
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/rx_mux
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/rx_ready
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/rx_sof
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/rx_state
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/src_ip_accept
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/tx_mux
add wave -noupdate -group {ip module internals} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/udp_tx_id_i
add wave -noupdate -expand -group {ip module} -color Yellow /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_rx_ready
add wave -noupdate -expand -group {ip module} -color Yellow /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_rx_data
add wave -noupdate -expand -group {ip module} -color Yellow -expand -subitemconfig {/ethernet_to_udp_module_tb/uut/inst_ip_module/ip_rx_ctrl(6) {-color Yellow} /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_rx_ctrl(5) {-color Yellow} /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_rx_ctrl(4) {-color Yellow} /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_rx_ctrl(3) {-color Yellow} /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_rx_ctrl(2) {-color Yellow} /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_rx_ctrl(1) {-color Yellow} /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_rx_ctrl(0) {-color Yellow}} /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_rx_ctrl
add wave -noupdate -expand -group {ip module} -expand -group {icmp internals} -color Orange /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/icmp_inst/icmp_out_ready
add wave -noupdate -expand -group {ip module} -expand -group {icmp internals} -color Orange /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/icmp_inst/icmp_out_data
add wave -noupdate -expand -group {ip module} -expand -group {icmp internals} -color Orange -expand -subitemconfig {/ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/icmp_inst/icmp_out_ctrl(6) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/icmp_inst/icmp_out_ctrl(5) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/icmp_inst/icmp_out_ctrl(4) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/icmp_inst/icmp_out_ctrl(3) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/icmp_inst/icmp_out_ctrl(2) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/icmp_inst/icmp_out_ctrl(1) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/icmp_inst/icmp_out_ctrl(0) {-color Orange -height 17}} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/icmp_inst/icmp_out_ctrl
add wave -noupdate -expand -group {ip module} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/icmp_inst/is_icmp_request
add wave -noupdate -expand -group {ip module} -color Orange /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_tx_ready
add wave -noupdate -expand -group {ip module} -color Orange /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_tx_data
add wave -noupdate -expand -group {ip module} -color Orange -expand -subitemconfig {/ethernet_to_udp_module_tb/uut/inst_ip_module/ip_tx_ctrl(6) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_tx_ctrl(5) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_tx_ctrl(4) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_tx_ctrl(3) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_tx_ctrl(2) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_tx_ctrl(1) {-color Orange -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_tx_ctrl(0) {-color Orange -height 17}} /ethernet_to_udp_module_tb/uut/inst_ip_module/ip_tx_ctrl
add wave -noupdate -expand -group {ip module} -expand -group {ip id table} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/make_ip_udp_table/id_ip_table_inst/disco_wren
add wave -noupdate -expand -group {ip module} -expand -group {ip id table} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/make_ip_udp_table/id_ip_table_inst/disco_pin
add wave -noupdate -expand -group {ip module} -expand -group {ip id table} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/make_ip_udp_table/id_ip_table_inst/disco_pout
add wave -noupdate -expand -group {ip module} -expand -group {ip id table} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/make_ip_udp_table/id_ip_table_inst/reco_en
add wave -noupdate -expand -group {ip module} -expand -group {ip id table} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/make_ip_udp_table/id_ip_table_inst/reco_pin
add wave -noupdate -expand -group {ip module} -expand -group {ip id table} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/make_ip_udp_table/id_ip_table_inst/reco_pout
add wave -noupdate -expand -group {ip module} -expand -group {ip id table} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/make_ip_udp_table/id_ip_table_inst/reco_found
add wave -noupdate -expand -group {ip module} -expand -group {ip id table} -color White -expand -subitemconfig {/ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/make_ip_udp_table/id_ip_table_inst/port_io_table_data(5) {-color White -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/make_ip_udp_table/id_ip_table_inst/port_io_table_data(4) {-color White -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/make_ip_udp_table/id_ip_table_inst/port_io_table_data(3) {-color White -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/make_ip_udp_table/id_ip_table_inst/port_io_table_data(2) {-color White -height 17} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/make_ip_udp_table/id_ip_table_inst/port_io_table_data(1) {-color White -height 17}} /ethernet_to_udp_module_tb/uut/inst_ip_module/stripoff_header/make_ip_udp_table/id_ip_table_inst/port_io_table_data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3970794 ps} 0}
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
WaveRestoreZoom {0 ps} {4000 ns}
run 4000 ns
