onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /interface_merger_tb/clk
add wave -noupdate /interface_merger_tb/rst
add wave -noupdate -radix decimal -radixshowbase 0 /interface_merger_tb/simulation/counter
add wave -noupdate -divider avst_tx_1
add wave -noupdate /interface_merger_tb/avst1_dat_filename
add wave -noupdate /interface_merger_tb/avst1_tx_ready
add wave -noupdate -radix hexadecimal -radixshowbase 0 /interface_merger_tb/avst1_tx_data
add wave -noupdate -radix binary -radixshowbase 0 /interface_merger_tb/avst1_tx_ctrl
add wave -noupdate -divider avst_tx_2
add wave -noupdate /interface_merger_tb/avst2_dat_filename
add wave -noupdate /interface_merger_tb/avst2_tx_ready
add wave -noupdate -radix hexadecimal -radixshowbase 0 /interface_merger_tb/avst2_tx_data
add wave -noupdate -radix binary -radixshowbase 0 /interface_merger_tb/avst2_tx_ctrl
add wave -noupdate -divider avst_rx
add wave -noupdate /interface_merger_tb/avst_rx_ready_file
add wave -noupdate /interface_merger_tb/avst_log_filename
add wave -noupdate /interface_merger_tb/avst_rx_ready
add wave -noupdate -radix hexadecimal -radixshowbase 0 /interface_merger_tb/avst_rx_data
add wave -noupdate -radix binary -radixshowbase 0 /interface_merger_tb/avst_rx_ctrl
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
