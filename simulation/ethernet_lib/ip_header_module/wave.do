onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ip_header_module_tb/UDP_RXD_FILE
add wave -noupdate /ip_header_module_tb/IP_RDY_FILE
add wave -noupdate /ip_header_module_tb/IP_TXD_FILE
add wave -noupdate /ip_header_module_tb/MNL_RST_FILE
add wave -noupdate -radix decimal -radixshowbase 0 /ip_header_module_tb/blk_simulation/counter
add wave -noupdate /ip_header_module_tb/clk
add wave -noupdate /ip_header_module_tb/rst
add wave -noupdate /ip_header_module_tb/uut/udp_rx_ready
add wave -noupdate /ip_header_module_tb/uut/udp_rx_data
add wave -noupdate /ip_header_module_tb/uut/udp_rx_ctrl
add wave -noupdate /ip_header_module_tb/uut/reco_en
add wave -noupdate /ip_header_module_tb/uut/reco_ip_found
add wave -noupdate /ip_header_module_tb/uut/reco_ip
add wave -noupdate /ip_header_module_tb/uut/my_ip
add wave -noupdate /ip_header_module_tb/uut/ip_netmask
add wave -noupdate /ip_header_module_tb/uut/ip_tx_ready
add wave -noupdate /ip_header_module_tb/uut/ip_tx_data
add wave -noupdate -expand -subitemconfig {/ip_header_module_tb/uut/ip_tx_ctrl(4) {-color Coral -height 17}} /ip_header_module_tb/uut/ip_tx_ctrl
add wave -noupdate /ip_header_module_tb/uut/status_vector
add wave -noupdate -expand -group internals /ip_header_module_tb/uut/make_tx_interface/udp_data_transport/tx_data_sr
add wave -noupdate -expand -group internals /ip_header_module_tb/uut/make_tx_interface/udp_data_transport/tx_ctrl_sr
add wave -noupdate -expand -group internals /ip_header_module_tb/uut/make_tx_interface/udp_data_transport/tx_valid
add wave -noupdate -expand -group internals /ip_header_module_tb/uut/ip_broadcast_addr
add wave -noupdate -expand -group internals /ip_header_module_tb/uut/ip_dst_addr
add wave -noupdate -expand -group internals /ip_header_module_tb/uut/ip_id
add wave -noupdate -expand -group internals /ip_header_module_tb/uut/ip_length
add wave -noupdate -expand -group internals /ip_header_module_tb/uut/tx_count
add wave -noupdate -expand -group internals /ip_header_module_tb/uut/tx_done
add wave -noupdate -expand -group internals /ip_header_module_tb/uut/tx_state
add wave -noupdate -expand -group internals /ip_header_module_tb/uut/make_tx_interface/udp_data_transport/make_tx_done/cnt_rst
add wave -noupdate -expand -group internals /ip_header_module_tb/uut/make_tx_interface/udp_data_transport/make_tx_done/tx_next
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
