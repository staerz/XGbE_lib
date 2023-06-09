onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ethernet_header_module_tb/IP_RXD_FILE
add wave -noupdate /ethernet_header_module_tb/ETH_RDY_FILE
add wave -noupdate /ethernet_header_module_tb/ETH_TXD_FILE
add wave -noupdate /ethernet_header_module_tb/MNL_RST_FILE
add wave -noupdate -radix decimal -radixshowbase 0 /ethernet_header_module_tb/cnt
add wave -noupdate /ethernet_header_module_tb/clk
add wave -noupdate /ethernet_header_module_tb/rst
add wave -noupdate /ethernet_header_module_tb/uut/ip_rx_ready_o
add wave -noupdate /ethernet_header_module_tb/uut/ip_rx_packet_i
add wave -noupdate /ethernet_header_module_tb/uut/reco_en_o
add wave -noupdate /ethernet_header_module_tb/uut/reco_ip_o
add wave -noupdate /ethernet_header_module_tb/uut/reco_done_i
add wave -noupdate /ethernet_header_module_tb/uut/reco_mac_i
add wave -noupdate /ethernet_header_module_tb/uut/my_mac_i
add wave -noupdate /ethernet_header_module_tb/uut/eth_tx_ready_i
add wave -noupdate /ethernet_header_module_tb/uut/eth_tx_packet_o
add wave -noupdate /ethernet_header_module_tb/uut/status_vector_o
add wave -noupdate -expand -group internals /ethernet_header_module_tb/uut/blk_make_tx_interface/tx_data_sr
add wave -noupdate -expand -group internals /ethernet_header_module_tb/uut/blk_make_tx_interface/tx_ctrl_sr
add wave -noupdate -expand -group internals /ethernet_header_module_tb/uut/blk_make_tx_interface/tx_valid
add wave -noupdate -expand -group internals /ethernet_header_module_tb/uut/MAC_BROADCAST_ADDR
add wave -noupdate -expand -group internals /ethernet_header_module_tb/uut/mac_dst_addr
add wave -noupdate -expand -group internals /ethernet_header_module_tb/uut/tx_count
add wave -noupdate -expand -group internals /ethernet_header_module_tb/uut/tx_done
add wave -noupdate -expand -group internals /ethernet_header_module_tb/uut/tx_state
add wave -noupdate -expand -group internals /ethernet_header_module_tb/uut/blk_make_tx_interface/blk_make_tx_done/cnt_rst
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {390400 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
WaveRestoreZoom {0 ps} {2600 ns}
run 2600 ns
