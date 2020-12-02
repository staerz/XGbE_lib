onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /interface_merger_tb/clk
add wave -noupdate /interface_merger_tb/rst
add wave -noupdate -radix decimal -radixshowbase 0 /interface_merger_tb/blk_simulation/counter
add wave -noupdate -divider avst_tx_1
add wave -noupdate /interface_merger_tb/AVST1_RXD_FILE
add wave -noupdate /interface_merger_tb/avst1_tx_ready
add wave -noupdate -radix hexadecimal -radixshowbase 0 /interface_merger_tb/avst1_tx_packet
add wave -noupdate -divider avst_tx_2
add wave -noupdate /interface_merger_tb/AVST2_RXD_FILE
add wave -noupdate /interface_merger_tb/avst2_tx_ready
add wave -noupdate -radix hexadecimal -radixshowbase 0 /interface_merger_tb/avst2_tx_packet
add wave -noupdate -divider avst_rx
add wave -noupdate /interface_merger_tb/AVST_RDY_FILE
add wave -noupdate /interface_merger_tb/AVST_TXD_FILE
add wave -noupdate /interface_merger_tb/avst_rx_ready
add wave -noupdate -radix hexadecimal -radixshowbase 0 /interface_merger_tb/avst_rx_packet
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
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
WaveRestoreZoom {0 ps} {2500 ns}
run 2500 ns
