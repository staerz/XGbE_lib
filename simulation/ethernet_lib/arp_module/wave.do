onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix decimal -radixshowbase 0 /arp_module_tb/blk_simulation/counter
add wave -noupdate /arp_module_tb/uut/clk
add wave -noupdate /arp_module_tb/uut/rst
add wave -noupdate /arp_module_tb/uut/arp_rx_ready
add wave -noupdate -radix hexadecimal -radixshowbase 0 /arp_module_tb/uut/arp_rx_data
add wave -noupdate -radix binary -childformat {{/arp_module_tb/uut/arp_rx_ctrl(6) -radix binary} {/arp_module_tb/uut/arp_rx_ctrl(5) -radix binary} {/arp_module_tb/uut/arp_rx_ctrl(4) -radix binary} {/arp_module_tb/uut/arp_rx_ctrl(3) -radix binary} {/arp_module_tb/uut/arp_rx_ctrl(2) -radix binary} {/arp_module_tb/uut/arp_rx_ctrl(1) -radix binary} {/arp_module_tb/uut/arp_rx_ctrl(0) -radix binary}} -radixshowbase 0 -expand -subitemconfig {/arp_module_tb/uut/arp_rx_ctrl(6) {-height 18 -radix binary} /arp_module_tb/uut/arp_rx_ctrl(5) {-height 18 -radix binary -radixshowbase 0} /arp_module_tb/uut/arp_rx_ctrl(4) {-height 18 -radix binary} /arp_module_tb/uut/arp_rx_ctrl(3) {-height 18 -radix binary} /arp_module_tb/uut/arp_rx_ctrl(2) {-height 18 -radix binary} /arp_module_tb/uut/arp_rx_ctrl(1) {-height 18 -radix binary} /arp_module_tb/uut/arp_rx_ctrl(0) {-height 18 -radix binary}} /arp_module_tb/uut/arp_rx_ctrl
add wave -noupdate /arp_module_tb/uut/arp_tx_ready
add wave -noupdate -radix hexadecimal -radixshowbase 0 /arp_module_tb/uut/arp_tx_data
add wave -noupdate -radix binary -childformat {{/arp_module_tb/uut/arp_tx_ctrl(6) -radix binary} {/arp_module_tb/uut/arp_tx_ctrl(5) -radix binary} {/arp_module_tb/uut/arp_tx_ctrl(4) -radix binary} {/arp_module_tb/uut/arp_tx_ctrl(3) -radix binary} {/arp_module_tb/uut/arp_tx_ctrl(2) -radix binary} {/arp_module_tb/uut/arp_tx_ctrl(1) -radix binary} {/arp_module_tb/uut/arp_tx_ctrl(0) -radix binary}} -radixshowbase 0 -expand -subitemconfig {/arp_module_tb/uut/arp_tx_ctrl(6) {-height 18 -radix binary} /arp_module_tb/uut/arp_tx_ctrl(5) {-height 18 -radix binary} /arp_module_tb/uut/arp_tx_ctrl(4) {-height 18 -radix binary} /arp_module_tb/uut/arp_tx_ctrl(3) {-height 18 -radix binary} /arp_module_tb/uut/arp_tx_ctrl(2) {-height 18 -radix binary} /arp_module_tb/uut/arp_tx_ctrl(1) {-height 18 -radix binary} /arp_module_tb/uut/arp_tx_ctrl(0) {-height 18 -radix binary}} /arp_module_tb/uut/arp_tx_ctrl
add wave -noupdate /arp_module_tb/uut/reco_en
add wave -noupdate -radix hexadecimal -radixshowbase 0 /arp_module_tb/uut/reco_ip
add wave -noupdate -radix hexadecimal -radixshowbase 0 /arp_module_tb/uut/reco_mac
add wave -noupdate /arp_module_tb/uut/reco_mac_done
add wave -noupdate -radix hexadecimal -radixshowbase 0 /arp_module_tb/uut/my_mac
add wave -noupdate -radix hexadecimal -radixshowbase 0 /arp_module_tb/uut/my_ip
add wave -noupdate /arp_module_tb/uut/one_ms_tick
add wave -noupdate -radix binary -radixshowbase 0 /arp_module_tb/uut/status_vector
add wave -noupdate -expand -group internals -divider RX
add wave -noupdate -expand -group internals /arp_module_tb/uut/make_rx_interface/arp_rx_ready_i
add wave -noupdate -expand -group internals /arp_module_tb/uut/make_rx_interface/config_tg_en
add wave -noupdate -expand -group internals /arp_module_tb/uut/make_rx_interface/rx_count
add wave -noupdate -expand -group internals /arp_module_tb/uut/make_rx_interface/rx_data_copy_tg_ip
add wave -noupdate -expand -group internals /arp_module_tb/uut/make_rx_interface/rx_data_copy_tg_mac
add wave -noupdate -expand -group internals /arp_module_tb/uut/make_rx_interface/rx_data_reg
add wave -noupdate -expand -group internals /arp_module_tb/uut/make_rx_interface/rx_state
add wave -noupdate -expand -group internals /arp_module_tb/uut/make_rx_interface/rx_type
add wave -noupdate -expand -group internals -divider TX
add wave -noupdate -expand -group internals /arp_module_tb/uut/make_tx_interface/arp_data_loaded
add wave -noupdate -expand -group internals /arp_module_tb/uut/make_tx_interface/config_tg_ip
add wave -noupdate -expand -group internals /arp_module_tb/uut/make_tx_interface/config_tg_mac
add wave -noupdate -expand -group internals /arp_module_tb/uut/make_tx_interface/fifo_state
add wave -noupdate -expand -group internals /arp_module_tb/uut/make_tx_interface/tx_count
add wave -noupdate -expand -group internals /arp_module_tb/uut/make_tx_interface/tx_state
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
