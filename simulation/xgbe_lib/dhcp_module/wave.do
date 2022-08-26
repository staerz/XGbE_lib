onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix decimal -radixshowbase 0 /dhcp_module_tb/cnt
add wave -noupdate /dhcp_module_tb/uut/clk
add wave -noupdate /dhcp_module_tb/uut/rst
add wave -noupdate /dhcp_module_tb/uut/dhcp_rx_ready_o
add wave -noupdate -radix hexadecimal -radixshowbase 0 /dhcp_module_tb/uut/dhcp_rx_packet_i
add wave -noupdate /dhcp_module_tb/uut/dhcp_tx_ready_i
add wave -noupdate -radix hexadecimal -childformat {{/dhcp_module_tb/uut/dhcp_tx_packet_o.data -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_tx_packet_o.valid -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_tx_packet_o.sop -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_tx_packet_o.eop -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_tx_packet_o.empty -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_tx_packet_o.error -radix hexadecimal}} -radixshowbase 0 -expand -subitemconfig {/dhcp_module_tb/uut/dhcp_tx_packet_o.data {-height 17 -radix hexadecimal -radixshowbase 0} /dhcp_module_tb/uut/dhcp_tx_packet_o.valid {-height 17 -radix hexadecimal -radixshowbase 0} /dhcp_module_tb/uut/dhcp_tx_packet_o.sop {-height 17 -radix hexadecimal -radixshowbase 0} /dhcp_module_tb/uut/dhcp_tx_packet_o.eop {-height 17 -radix hexadecimal -radixshowbase 0} /dhcp_module_tb/uut/dhcp_tx_packet_o.empty {-height 17 -radix hexadecimal -radixshowbase 0} /dhcp_module_tb/uut/dhcp_tx_packet_o.error {-height 17 -radix hexadecimal -radixshowbase 0}} /dhcp_module_tb/uut/dhcp_tx_packet_o
add wave -noupdate /dhcp_module_tb/uut/reco_en_i
add wave -noupdate -radix hexadecimal -radixshowbase 0 /dhcp_module_tb/uut/reco_ip_i
add wave -noupdate -radix hexadecimal -radixshowbase 0 /dhcp_module_tb/uut/reco_mac_o
add wave -noupdate /dhcp_module_tb/uut/reco_done_o
add wave -noupdate -radix hexadecimal -radixshowbase 0 /dhcp_module_tb/uut/my_mac_i
add wave -noupdate -radix hexadecimal -radixshowbase 0 /dhcp_module_tb/uut/my_ip_o
add wave -noupdate /dhcp_module_tb/uut/one_ms_tick_i
add wave -noupdate -radix binary -radixshowbase 0 /dhcp_module_tb/uut/status_vector_o
add wave -noupdate -expand -group internals -divider RX
add wave -noupdate -expand -group internals /dhcp_module_tb/uut/blk_make_rx_interface/config_tg_en
add wave -noupdate -expand -group internals /dhcp_module_tb/uut/blk_make_rx_interface/rx_count
add wave -noupdate -expand -group internals /dhcp_module_tb/uut/blk_make_rx_interface/rx_data_copy_tg_ip
add wave -noupdate -expand -group internals /dhcp_module_tb/uut/blk_make_rx_interface/rx_data_copy_tg_mac
add wave -noupdate -expand -group internals /dhcp_module_tb/uut/blk_make_rx_interface/rx_data_reg
add wave -noupdate -expand -group internals /dhcp_module_tb/uut/blk_make_rx_interface/rx_state
add wave -noupdate -expand -group internals /dhcp_module_tb/uut/blk_make_rx_interface/rx_type
add wave -noupdate -expand -group internals -divider {Global FSM}
add wave -noupdate /dhcp_module_tb/uut/dhcp_state
add wave -noupdate /dhcp_module_tb/uut/send_dhcp_decline
add wave -noupdate /dhcp_module_tb/uut/send_dhcp_discover
add wave -noupdate /dhcp_module_tb/uut/send_dhcp_release
add wave -noupdate /dhcp_module_tb/uut/send_dhcp_request
add wave -noupdate /dhcp_module_tb/uut/dhcp_offer_selected
add wave -noupdate /dhcp_module_tb/uut/dhcp_acknowledge
add wave -noupdate /dhcp_module_tb/uut/dhcp_nack
add wave -noupdate /dhcp_module_tb/uut/dhcp_accept
add wave -noupdate /dhcp_module_tb/uut/decline_sent
add wave -noupdate /dhcp_module_tb/uut/t1_expires
add wave -noupdate /dhcp_module_tb/uut/t2_expires
add wave -noupdate /dhcp_module_tb/uut/lease_expired
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/tx_state
add wave -noupdate -expand -group {TX FSM} -radix decimal /dhcp_module_tb/uut/blk_make_tx_interface/tx_count
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/dhcp_frame
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/udp_crc
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/udp_length
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/DHCP_HEADER
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/xid
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/secs
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/flags
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/ciaddr
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/YSGIADDR
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/chaddr
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/config_tg_mac
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/dhcp_options
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/fifo_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {455611 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 220
configure wave -valuecolwidth 160
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
WaveRestoreZoom {0 ps} {636409 ps}
