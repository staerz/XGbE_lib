onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /icmp_module_tb/ICMP_RXD_FILE
add wave -noupdate /icmp_module_tb/ICMP_TXD_FILE
add wave -noupdate /icmp_module_tb/ICMP_RDY_FILE
add wave -noupdate /icmp_module_tb/MNL_RST_FILE
add wave -noupdate -radix decimal -radixshowbase 0 /icmp_module_tb/blk_simulation/counter
add wave -noupdate /icmp_module_tb/clk
add wave -noupdate /icmp_module_tb/rst
add wave -noupdate /icmp_module_tb/uut/ip_rx_ready_o
add wave -noupdate /icmp_module_tb/uut/ip_rx_packet_i
add wave -noupdate /icmp_module_tb/uut/is_icmp_request_i
add wave -noupdate /icmp_module_tb/uut/icmp_tx_ready_i
add wave -noupdate /icmp_module_tb/uut/icmp_tx_packet_o
add wave -noupdate /icmp_module_tb/uut/status_vector_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {442536 ps} 0}
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
WaveRestoreZoom {0 ps} {1600 ns}
run 1600 ns
