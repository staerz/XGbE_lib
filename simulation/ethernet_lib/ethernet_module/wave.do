onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group {Constants and Config} /ethernet_module_tb/ARP_RDY_FILE
add wave -noupdate -group {Constants and Config} /ethernet_module_tb/ARP_RXD_FILE
add wave -noupdate -group {Constants and Config} /ethernet_module_tb/ARP_TXD_FILE
add wave -noupdate -group {Constants and Config} /ethernet_module_tb/ETH_RDY_FILE
add wave -noupdate -group {Constants and Config} /ethernet_module_tb/ETH_RXD_FILE
add wave -noupdate -group {Constants and Config} /ethernet_module_tb/ETH_TXD_FILE
add wave -noupdate -group {Constants and Config} /ethernet_module_tb/IP_RDY_FILE
add wave -noupdate -group {Constants and Config} /ethernet_module_tb/IP_RXD_FILE
add wave -noupdate -group {Constants and Config} /ethernet_module_tb/IP_TXD_FILE
add wave -noupdate -group {Constants and Config} /ethernet_module_tb/MNL_RST_FILE
add wave -noupdate -group {Constants and Config} -radix binary -radixshowbase 0 /ethernet_module_tb/EOF_CHECK_EN
add wave -noupdate -group {Constants and Config} /ethernet_module_tb/MAC_TIMEOUT
add wave -noupdate -group {Constants and Config} /ethernet_module_tb/PAUSE_LENGTH
add wave -noupdate -group {Constants and Config} -radix hexadecimal -radixshowbase 0 /ethernet_module_tb/my_mac
add wave -noupdate -group {Constants and Config} -radix hexadecimal -radixshowbase 0 /ethernet_module_tb/uut/MAC_BROADCAST_ADDR
add wave -noupdate /ethernet_module_tb/clk
add wave -noupdate /ethernet_module_tb/rst
add wave -noupdate -color Tan /ethernet_module_tb/uut/eth_rx_ready
add wave -noupdate -color Tan /ethernet_module_tb/uut/eth_rx_data
add wave -noupdate -color Tan /ethernet_module_tb/uut/eth_rx_ctrl
add wave -noupdate /ethernet_module_tb/uut/eth_tx_ready
add wave -noupdate /ethernet_module_tb/uut/eth_tx_data
add wave -noupdate /ethernet_module_tb/uut/eth_tx_ctrl
add wave -noupdate -color Pink /ethernet_module_tb/uut/arp_rx_ready
add wave -noupdate -color Pink /ethernet_module_tb/uut/arp_rx_data
add wave -noupdate -color Pink /ethernet_module_tb/uut/arp_rx_ctrl
add wave -noupdate /ethernet_module_tb/uut/arp_tx_ready
add wave -noupdate /ethernet_module_tb/uut/arp_tx_data
add wave -noupdate /ethernet_module_tb/uut/arp_tx_ctrl
add wave -noupdate -color Thistle /ethernet_module_tb/uut/ip_rx_ready
add wave -noupdate -color Thistle /ethernet_module_tb/uut/ip_rx_data
add wave -noupdate -color Thistle /ethernet_module_tb/uut/ip_rx_ctrl
add wave -noupdate /ethernet_module_tb/uut/ip_tx_ready
add wave -noupdate /ethernet_module_tb/uut/ip_tx_data
add wave -noupdate /ethernet_module_tb/uut/ip_tx_ctrl
add wave -noupdate /ethernet_module_tb/uut/reco_en
add wave -noupdate /ethernet_module_tb/uut/reco_ip
add wave -noupdate /ethernet_module_tb/uut/reco_mac
add wave -noupdate /ethernet_module_tb/uut/reco_mac_done
add wave -noupdate /ethernet_module_tb/uut/status_vector
add wave -noupdate -expand -group internals /ethernet_module_tb/uut/stripoff_header/protocol
add wave -noupdate -expand -group internals /ethernet_module_tb/uut/stripoff_header/rx_count
add wave -noupdate -expand -group internals /ethernet_module_tb/uut/stripoff_header/rx_eof
add wave -noupdate -expand -group internals /ethernet_module_tb/uut/stripoff_header/rx_mux
add wave -noupdate -expand -group internals /ethernet_module_tb/uut/stripoff_header/rx_ready
add wave -noupdate -expand -group internals /ethernet_module_tb/uut/stripoff_header/rx_sof
add wave -noupdate -expand -group internals /ethernet_module_tb/uut/stripoff_header/rx_state
add wave -noupdate -expand -group internals /ethernet_module_tb/uut/stripoff_header/tx_mux
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {783056 ps} 0}
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
WaveRestoreZoom {0 ps} {3000 ns}
run 3000 ns
