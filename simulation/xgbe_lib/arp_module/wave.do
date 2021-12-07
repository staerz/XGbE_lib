onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix decimal -radixshowbase 0 /arp_module_tb/cnt
add wave -noupdate /arp_module_tb/uut/clk
add wave -noupdate /arp_module_tb/uut/rst
add wave -noupdate /arp_module_tb/uut/arp_rx_ready_o
add wave -noupdate -radix hexadecimal -radixshowbase 0 /arp_module_tb/uut/arp_rx_packet_i
add wave -noupdate /arp_module_tb/uut/arp_tx_ready_i
add wave -noupdate -radix hexadecimal -radixshowbase 0 /arp_module_tb/uut/arp_tx_packet_o
add wave -noupdate /arp_module_tb/uut/reco_en_i
add wave -noupdate -radix hexadecimal -radixshowbase 0 /arp_module_tb/uut/reco_ip_i
add wave -noupdate -radix hexadecimal -radixshowbase 0 /arp_module_tb/uut/reco_mac_o
add wave -noupdate /arp_module_tb/uut/reco_done_o
add wave -noupdate -radix hexadecimal -radixshowbase 0 /arp_module_tb/uut/my_mac_i
add wave -noupdate -radix hexadecimal -radixshowbase 0 /arp_module_tb/uut/my_ip_i
add wave -noupdate /arp_module_tb/uut/one_ms_tick_i
add wave -noupdate -radix binary -radixshowbase 0 /arp_module_tb/uut/status_vector_o
add wave -noupdate -expand -group internals -divider RX
add wave -noupdate -expand -group internals /arp_module_tb/uut/blk_make_rx_interface/arp_rx_ready_r
add wave -noupdate -expand -group internals /arp_module_tb/uut/blk_make_rx_interface/config_tg_en
add wave -noupdate -expand -group internals /arp_module_tb/uut/blk_make_rx_interface/rx_count
add wave -noupdate -expand -group internals /arp_module_tb/uut/blk_make_rx_interface/rx_data_copy_tg_ip
add wave -noupdate -expand -group internals /arp_module_tb/uut/blk_make_rx_interface/rx_data_copy_tg_mac
add wave -noupdate -expand -group internals /arp_module_tb/uut/blk_make_rx_interface/rx_data_reg
add wave -noupdate -expand -group internals /arp_module_tb/uut/blk_make_rx_interface/rx_state
add wave -noupdate -expand -group internals /arp_module_tb/uut/blk_make_rx_interface/rx_type
add wave -noupdate -expand -group internals -divider TX
add wave -noupdate -expand -group internals /arp_module_tb/uut/blk_make_tx_interface/arp_data_loaded
add wave -noupdate -expand -group internals /arp_module_tb/uut/blk_make_tx_interface/config_tg_ip
add wave -noupdate -expand -group internals /arp_module_tb/uut/blk_make_tx_interface/config_tg_mac
add wave -noupdate -expand -group internals /arp_module_tb/uut/blk_make_tx_interface/fifo_state
add wave -noupdate -expand -group internals /arp_module_tb/uut/blk_make_tx_interface/tx_count
add wave -noupdate -expand -group internals /arp_module_tb/uut/blk_make_tx_interface/tx_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {449922 ps} 0}
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
WaveRestoreZoom {0 ns} {1400 ns}
run 1400 ns
