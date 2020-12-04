onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /rx_fifo_module_tb/AVST_RXD_FILE
add wave -noupdate /rx_fifo_module_tb/AVST_TXD_FILE
add wave -noupdate /rx_fifo_module_tb/AVST_RDY_FILE
add wave -noupdate /rx_fifo_module_tb/MNL_RST_FILE
add wave -noupdate -radix decimal -radixshowbase 0 /rx_fifo_module_tb/blk_simulation/counter
add wave -noupdate /rx_fifo_module_tb/clk
add wave -noupdate /rx_fifo_module_tb/rst
add wave -noupdate /rx_fifo_module_tb/uut/rx_ready_o
add wave -noupdate -radix hexadecimal -radixshowbase 0 /rx_fifo_module_tb/uut/rx_packet_i
add wave -noupdate /rx_fifo_module_tb/uut/tx_ready_i
add wave -noupdate -radix hexadecimal -radixshowbase 0 /rx_fifo_module_tb/uut/tx_packet_o
add wave -noupdate -expand -group Internals /rx_fifo_module_tb/uut/rx_fifo_rst
add wave -noupdate -expand -group Internals /rx_fifo_module_tb/uut/rx_fifo_din
add wave -noupdate -expand -group Internals /rx_fifo_module_tb/uut/rx_fifo_wen
add wave -noupdate -expand -group Internals /rx_fifo_module_tb/uut/rx_fifo_ren
add wave -noupdate -expand -group Internals /rx_fifo_module_tb/uut/rx_fifo_dout
add wave -noupdate -expand -group Internals /rx_fifo_module_tb/uut/rx_fifo_rd_full
add wave -noupdate -expand -group Internals /rx_fifo_module_tb/uut/rx_fifo_rd_empty
add wave -noupdate -expand -group Internals /rx_fifo_module_tb/uut/rx_fifo_wr_full
add wave -noupdate -expand -group Internals /rx_fifo_module_tb/uut/rx_fifo_wr_empty
add wave -noupdate -expand -group Internals /rx_fifo_module_tb/uut/fifo_rst
add wave -noupdate -expand -group Internals /rx_fifo_module_tb/uut/fifo_state
add wave -noupdate -expand -group Internals -radix decimal -radixshowbase 0 /rx_fifo_module_tb/uut/fifo_ren_permit
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
WaveRestoreZoom {0 ps} {700 ns}
run 700 ns
