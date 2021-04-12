onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /reset_module_tb/RST_RXD_FILE
add wave -noupdate /reset_module_tb/RST_RDY_FILE
add wave -noupdate /reset_module_tb/RST_TXD_FILE
add wave -noupdate /reset_module_tb/MNL_RST_FILE
add wave -noupdate -radix hexadecimal -radixshowbase 0 /reset_module_tb/MY_MAC
add wave -noupdate -radix hexadecimal -radixshowbase 0 /reset_module_tb/MY_IP
add wave -noupdate -radix hexadecimal -radixshowbase 0 /reset_module_tb/MY_UDP_PORT
add wave -noupdate -radix decimal -radixshowbase 0 /reset_module_tb/blk_simulation/counter
add wave -noupdate /reset_module_tb/clk
add wave -noupdate /reset_module_tb/rst
add wave -noupdate /reset_module_tb/uut/rx_ready_o
add wave -noupdate -radix hexadecimal -radixshowbase 0 /reset_module_tb/uut/rx_packet_i
add wave -noupdate /reset_module_tb/uut/tx_ready_i
add wave -noupdate -radix hexadecimal -radixshowbase 0 /reset_module_tb/uut/tx_packet_o
add wave -noupdate -expand -group Internals /reset_module_tb/uut/blk_make_rx_interface/rx_valid_d
add wave -noupdate -expand -group Internals /reset_module_tb/uut/blk_make_rx_interface/rx_state
add wave -noupdate -color Yellow -radix hexadecimal -radixshowbase 0 /reset_module_tb/uut/rst_o
add wave -noupdate -expand -group Internals -radix decimal -radixshowbase 0 /reset_module_tb/uut/blk_make_rx_interface/rx_count
add wave -noupdate -expand -group Internals -radix hexadecimal /reset_module_tb/uut/soft_resets
add wave -noupdate -expand -group Internals -radix hexadecimal -radixshowbase 0 /reset_module_tb/uut/blk_make_rx_interface/rx_ready
add wave -noupdate -expand -group Internals -radix hexadecimal -radixshowbase 0 /reset_module_tb/uut/blk_make_rx_interface/rx_data_reg1
add wave -noupdate -expand -group Internals -radix hexadecimal -radixshowbase 0 /reset_module_tb/uut/blk_make_rx_interface/rx_data_reg2
add wave -noupdate -expand -group Internals -color Plum -radix hexadecimal -radixshowbase 0 /reset_module_tb/uut/blk_make_rx_interface/rx_data_reg
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
