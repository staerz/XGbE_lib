onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /reset_module_tb/RST_DAT_FILENAME
add wave -noupdate /reset_module_tb/RST_LOG_FILENAME
add wave -noupdate /reset_module_tb/RST_RX_READY_FILE
add wave -noupdate /reset_module_tb/MNL_RST_FILE
add wave -noupdate -radix hexadecimal -radixshowbase 0 /reset_module_tb/my_mac
add wave -noupdate -radix hexadecimal -radixshowbase 0 /reset_module_tb/my_ip
add wave -noupdate -radix hexadecimal -radixshowbase 0 /reset_module_tb/my_udp_port
add wave -noupdate -radix decimal -radixshowbase 0 /reset_module_tb/simulation/counter
add wave -noupdate /reset_module_tb/clk
add wave -noupdate /reset_module_tb/rst
add wave -noupdate -radix hexadecimal /reset_module_tb/uut/soft_resets
add wave -noupdate -color Yellow -radix hexadecimal -radixshowbase 0 /reset_module_tb/rst_out
add wave -noupdate /reset_module_tb/uut/rst_rx_ready
add wave -noupdate -radix hexadecimal -radixshowbase 0 /reset_module_tb/uut/rst_rx_data
add wave -noupdate -radix binary -radixshowbase 0 /reset_module_tb/uut/rst_rx_ctrl
add wave -noupdate /reset_module_tb/uut/make_RX_interface/rst_rx_valid_d
add wave -noupdate /reset_module_tb/uut/rst_tx_ready
add wave -noupdate -radix hexadecimal -radixshowbase 0 /reset_module_tb/uut/rst_tx_data
add wave -noupdate -radix binary -radixshowbase 0 /reset_module_tb/uut/rst_tx_ctrl
add wave -noupdate -expand -group Internals /reset_module_tb/uut/make_rx_interface/rx_state
add wave -noupdate -expand -group Internals -radix decimal -radixshowbase 0 /reset_module_tb/uut/make_RX_interface/rx_count
add wave -noupdate -expand -group Internals -radix hexadecimal -radixshowbase 0 /reset_module_tb/uut/rst_rx_data
add wave -noupdate -expand -group Internals -radix hexadecimal -radixshowbase 0 /reset_module_tb/uut/make_RX_interface/rx_data_reg1
add wave -noupdate -expand -group Internals -radix hexadecimal -radixshowbase 0 /reset_module_tb/uut/make_RX_interface/rx_data_reg2
add wave -noupdate -expand -group Internals -color Plum -radix hexadecimal -radixshowbase 0 /reset_module_tb/uut/make_RX_interface/rx_data_reg
add wave -noupdate -expand -group Internals /reset_module_tb/uut/ipbus_big_endian
add wave -noupdate -expand -group Internals -radix hexadecimal -radixshowbase 0 /reset_module_tb/uut/ipbus_packet_id
add wave -noupdate -expand -group Internals -radix hexadecimal -radixshowbase 0 /reset_module_tb/uut/ipbus_trans_id
add wave -noupdate -expand -group Internals -radix hexadecimal -radixshowbase 0 /reset_module_tb/uut/ipbus_number_words
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {183939 ps} 0}
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
WaveRestoreZoom {0 ps} {600 ns}
run 600 ns
