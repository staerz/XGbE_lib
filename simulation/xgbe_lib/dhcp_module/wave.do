onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix decimal -radixshowbase 0 /dhcp_module_tb/cnt
add wave -noupdate /dhcp_module_tb/uut/clk
add wave -noupdate /dhcp_module_tb/uut/rst
add wave -noupdate /dhcp_module_tb/uut/dhcp_rx_ready_o
add wave -noupdate -radix hexadecimal -childformat {{/dhcp_module_tb/uut/dhcp_rx_packet_i.data -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_rx_packet_i.valid -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_rx_packet_i.sop -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_rx_packet_i.eop -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_rx_packet_i.empty -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_rx_packet_i.error -radix hexadecimal}} -radixshowbase 0 -expand -subitemconfig {/dhcp_module_tb/uut/dhcp_rx_packet_i.data {-height 17 -radix hexadecimal -radixshowbase 0} /dhcp_module_tb/uut/dhcp_rx_packet_i.valid {-height 17 -radix hexadecimal -radixshowbase 0} /dhcp_module_tb/uut/dhcp_rx_packet_i.sop {-height 17 -radix hexadecimal -radixshowbase 0} /dhcp_module_tb/uut/dhcp_rx_packet_i.eop {-height 17 -radix hexadecimal -radixshowbase 0} /dhcp_module_tb/uut/dhcp_rx_packet_i.empty {-height 17 -radix hexadecimal -radixshowbase 0} /dhcp_module_tb/uut/dhcp_rx_packet_i.error {-height 17 -radix hexadecimal -radixshowbase 0}} /dhcp_module_tb/uut/dhcp_rx_packet_i
add wave -noupdate /dhcp_module_tb/uut/dhcp_tx_ready_i
add wave -noupdate -radix hexadecimal -childformat {{/dhcp_module_tb/uut/dhcp_tx_packet_o.data -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_tx_packet_o.valid -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_tx_packet_o.sop -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_tx_packet_o.eop -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_tx_packet_o.empty -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_tx_packet_o.error -radix hexadecimal}} -radixshowbase 0 -expand -subitemconfig {/dhcp_module_tb/uut/dhcp_tx_packet_o.data {-height 17 -radix hexadecimal -radixshowbase 0} /dhcp_module_tb/uut/dhcp_tx_packet_o.valid {-height 17 -radix hexadecimal -radixshowbase 0} /dhcp_module_tb/uut/dhcp_tx_packet_o.sop {-height 17 -radix hexadecimal -radixshowbase 0} /dhcp_module_tb/uut/dhcp_tx_packet_o.eop {-height 17 -radix hexadecimal -radixshowbase 0} /dhcp_module_tb/uut/dhcp_tx_packet_o.empty {-height 17 -radix hexadecimal -radixshowbase 0} /dhcp_module_tb/uut/dhcp_tx_packet_o.error {-height 17 -radix hexadecimal -radixshowbase 0}} /dhcp_module_tb/uut/dhcp_tx_packet_o
add wave -noupdate -expand /dhcp_module_tb/blk_uvvm/dhcp_rx_expect
add wave -noupdate /dhcp_module_tb/uut/reco_en_i
add wave -noupdate -radix hexadecimal -radixshowbase 0 /dhcp_module_tb/uut/reco_ip_i
add wave -noupdate -radix hexadecimal -radixshowbase 0 /dhcp_module_tb/uut/reco_mac_o
add wave -noupdate /dhcp_module_tb/uut/reco_done_o
add wave -noupdate -radix hexadecimal -radixshowbase 0 /dhcp_module_tb/uut/my_mac_i
add wave -noupdate -radix hexadecimal -radixshowbase 0 /dhcp_module_tb/uut/my_ip_o
add wave -noupdate /dhcp_module_tb/uut/one_ms_tick_i
add wave -noupdate -radix binary -radixshowbase 0 /dhcp_module_tb/uut/status_vector_o
add wave -noupdate -expand -group {Global FSM} -color Cyan /dhcp_module_tb/uut/dhcp_state
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/send_dhcp_decline
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/send_dhcp_discover
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/send_dhcp_release
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/send_dhcp_request
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/dhcp_offer_selected
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/dhcp_acknowledge
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/dhcp_nack
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/dhcp_accept
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/decline_sent
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/t1_expires
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/t2_expires
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/lease_expired
add wave -noupdate -expand -group {TX FSM} -color Cyan /dhcp_module_tb/uut/blk_make_tx_interface/tx_state
add wave -noupdate -expand -group {TX FSM} -radix decimal /dhcp_module_tb/uut/blk_make_tx_interface/tx_count
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/dhcp_frame
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/udp_crc
add wave -noupdate -expand -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/udp_length
add wave -noupdate /dhcp_module_tb/uut/xid
add wave -noupdate -expand -group RX -color Cyan /dhcp_module_tb/uut/blk_make_rx_interface/rx_state
add wave -noupdate -expand -group RX /dhcp_module_tb/uut/blk_make_rx_interface/rx_type
add wave -noupdate -expand -group RX /dhcp_module_tb/uut/blk_make_rx_interface/dhcp_rx_ready_i
add wave -noupdate -expand -group RX /dhcp_module_tb/uut/blk_make_rx_interface/rx_count
add wave -noupdate -expand -group RX -expand /dhcp_module_tb/uut/blk_make_rx_interface/rx_packet_reg
add wave -noupdate -expand -group RX /dhcp_module_tb/uut/blk_make_rx_interface/offered_yiaddr
add wave -noupdate -expand -group RX -expand -group {RX OPT FIFO} /dhcp_module_tb/uut/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/dhcp_rx_options_fifo_din
add wave -noupdate -expand -group RX -expand -group {RX OPT FIFO} /dhcp_module_tb/uut/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/dhcp_rx_options_fifo_wen
add wave -noupdate -expand -group RX -expand -group {RX OPT FIFO} /dhcp_module_tb/uut/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/dhcp_rx_options_fifo_ren
add wave -noupdate -expand -group RX -expand -group {RX OPT FIFO} /dhcp_module_tb/uut/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/dhcp_rx_options_fifo_dout
add wave -noupdate -expand -group RX -expand -group {RX OPT FIFO} /dhcp_module_tb/uut/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/dhcp_rx_options_fifo_full
add wave -noupdate -expand -group RX -expand -group {RX OPT FIFO} /dhcp_module_tb/uut/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/dhcp_rx_options_fifo_empty
add wave -noupdate -expand -group RX -expand -group {RX OPT FIFO} -radix decimal /dhcp_module_tb/uut/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/value_length
add wave -noupdate -expand -group RX /dhcp_module_tb/uut/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/value_buffer
add wave -noupdate -expand -group RX -color Cyan /dhcp_module_tb/uut/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/dhcp_option
add wave -noupdate -expand -group RX -color Cyan /dhcp_module_tb/uut/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/option_state
add wave -noupdate -expand -group RX /dhcp_module_tb/uut/blk_make_rx_interface/parse_options_done
add wave -noupdate /dhcp_module_tb/uut/blk_make_rx_interface/dhcp_operation
add wave -noupdate /dhcp_module_tb/uut/blk_make_rx_interface/dhcp_lease_time
add wave -noupdate /dhcp_module_tb/uut/blk_make_rx_interface/dhcp_server_ip
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {959649 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 211
configure wave -valuecolwidth 156
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
WaveRestoreZoom {906615 ps} {1207471 ps}
