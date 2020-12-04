onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix decimal -radixshowbase 0 /trailer_module_tb/uut/header_length
add wave -noupdate /trailer_module_tb/uut/clk
add wave -noupdate /trailer_module_tb/uut/rst
add wave -noupdate /trailer_module_tb/uut/rx_ready_o
add wave -noupdate -radix hexadecimal -radixshowbase 0 /trailer_module_tb/uut/rx_packet_i
add wave -noupdate -radix binary -radixshowbase 0 /trailer_module_tb/uut/rx_mux_i
add wave -noupdate -radix unsigned -radixshowbase 0 /trailer_module_tb/uut/rx_count_o
add wave -noupdate /trailer_module_tb/uut/tx_ready_i
add wave -noupdate -radix hexadecimal -radixshowbase 0 /trailer_module_tb/uut/tx_packet_o
add wave -noupdate -radix binary -radixshowbase 0 /trailer_module_tb/uut/tx_mux_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
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
#set display of signal names to names only (no paths)
config wave -signalnamewidth 1
update
run 1500 ns
WaveRestoreZoom {0 ns} {1500 ns}
