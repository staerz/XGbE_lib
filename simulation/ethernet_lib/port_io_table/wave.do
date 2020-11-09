onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix decimal -radixshowbase 0 /port_io_table_tb/uut/pin_width
add wave -noupdate -radix decimal -radixshowbase 0 /port_io_table_tb/uut/pout_width
add wave -noupdate -radix decimal -radixshowbase 0 /port_io_table_tb/uut/table_depth
add wave -noupdate /port_io_table_tb/uut/clk
add wave -noupdate /port_io_table_tb/uut/rst
add wave -noupdate /port_io_table_tb/uut/disco_wren
add wave -noupdate -radix hexadecimal -radixshowbase 0 /port_io_table_tb/uut/disco_pin
add wave -noupdate -radix hexadecimal -radixshowbase 0 /port_io_table_tb/uut/disco_pout
add wave -noupdate /port_io_table_tb/uut/reco_en
add wave -noupdate -radix hexadecimal -radixshowbase 0 /port_io_table_tb/uut/reco_pin
add wave -noupdate -radix hexadecimal -radixshowbase 0 /port_io_table_tb/uut/reco_pout
add wave -noupdate /port_io_table_tb/uut/reco_found
add wave -noupdate -radix binary -radixshowbase 0 /port_io_table_tb/uut/status_vector
add wave -noupdate -radix hexadecimal -childformat {{/port_io_table_tb/uut/port_io_table_data(3) -radix hexadecimal} {/port_io_table_tb/uut/port_io_table_data(2) -radix hexadecimal} {/port_io_table_tb/uut/port_io_table_data(1) -radix hexadecimal}} -radixshowbase 0 -expand -subitemconfig {/port_io_table_tb/uut/port_io_table_data(3) {-radix hexadecimal -radixshowbase 0} /port_io_table_tb/uut/port_io_table_data(2) {-radix hexadecimal -radixshowbase 0} /port_io_table_tb/uut/port_io_table_data(1) {-radix hexadecimal -radixshowbase 0}} /port_io_table_tb/uut/port_io_table_data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {358610 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 168
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
run 1200 ns
WaveRestoreZoom {0 ps} {1200 ns}