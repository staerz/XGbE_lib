onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix decimal -radixshowbase 0 /dhcp_in_ip_module_tb/cnt
add wave -noupdate /dhcp_in_ip_module_tb/uut1/clk
add wave -noupdate /dhcp_in_ip_module_tb/uut1/rst
add wave -noupdate -color {Dark Slate Gray} /dhcp_in_ip_module_tb/uut2/ip_rx_ready_o
add wave -noupdate -color {Dark Slate Gray} -expand -subitemconfig {/dhcp_in_ip_module_tb/uut2/ip_rx_packet_i.data {-color {Dark Slate Gray} -height 17} /dhcp_in_ip_module_tb/uut2/ip_rx_packet_i.valid {-color {Dark Slate Gray} -height 17} /dhcp_in_ip_module_tb/uut2/ip_rx_packet_i.sop {-color {Dark Slate Gray} -height 17} /dhcp_in_ip_module_tb/uut2/ip_rx_packet_i.eop {-color {Dark Slate Gray} -height 17} /dhcp_in_ip_module_tb/uut2/ip_rx_packet_i.empty {-color {Dark Slate Gray} -height 17} /dhcp_in_ip_module_tb/uut2/ip_rx_packet_i.error {-color {Dark Slate Gray} -height 17}} /dhcp_in_ip_module_tb/uut2/ip_rx_packet_i
add wave -noupdate -color Khaki /dhcp_in_ip_module_tb/uut2/ip_tx_ready_i
add wave -noupdate -color Khaki -expand -subitemconfig {/dhcp_in_ip_module_tb/uut2/ip_tx_packet_o.data {-color Khaki -height 17} /dhcp_in_ip_module_tb/uut2/ip_tx_packet_o.valid {-color Khaki -height 17} /dhcp_in_ip_module_tb/uut2/ip_tx_packet_o.sop {-color Khaki -height 17} /dhcp_in_ip_module_tb/uut2/ip_tx_packet_o.eop {-color Khaki -height 17} /dhcp_in_ip_module_tb/uut2/ip_tx_packet_o.empty {-color Khaki -height 17} /dhcp_in_ip_module_tb/uut2/ip_tx_packet_o.error {-color Khaki -height 17}} /dhcp_in_ip_module_tb/uut2/ip_tx_packet_o
add wave -noupdate -color {Medium Orchid} /dhcp_in_ip_module_tb/uut1/dhcp_rx_ready_o
add wave -noupdate -color {Medium Orchid} -radix hexadecimal -childformat {{/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(15) -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(14) -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(13) -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(12) -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(11) -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(10) -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(9) -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(8) -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(7) -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(6) -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(5) -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(4) -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(3) -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(2) -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(1) -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(0) -radix hexadecimal}} -subitemconfig {/dhcp_in_ip_module_tb/uut1/udp_rx_id_i(15) {-color {Medium Orchid} -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/udp_rx_id_i(14) {-color {Medium Orchid} -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/udp_rx_id_i(13) {-color {Medium Orchid} -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/udp_rx_id_i(12) {-color {Medium Orchid} -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/udp_rx_id_i(11) {-color {Medium Orchid} -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/udp_rx_id_i(10) {-color {Medium Orchid} -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/udp_rx_id_i(9) {-color {Medium Orchid} -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/udp_rx_id_i(8) {-color {Medium Orchid} -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/udp_rx_id_i(7) {-color {Medium Orchid} -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/udp_rx_id_i(6) {-color {Medium Orchid} -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/udp_rx_id_i(5) {-color {Medium Orchid} -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/udp_rx_id_i(4) {-color {Medium Orchid} -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/udp_rx_id_i(3) {-color {Medium Orchid} -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/udp_rx_id_i(2) {-color {Medium Orchid} -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/udp_rx_id_i(1) {-color {Medium Orchid} -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/udp_rx_id_i(0) {-color {Medium Orchid} -radix hexadecimal}} /dhcp_in_ip_module_tb/uut1/udp_rx_id_i
add wave -noupdate -color {Medium Orchid} -radix hexadecimal -childformat {{/dhcp_in_ip_module_tb/uut1/dhcp_rx_packet_i.data -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/dhcp_rx_packet_i.valid -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/dhcp_rx_packet_i.sop -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/dhcp_rx_packet_i.eop -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/dhcp_rx_packet_i.empty -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/dhcp_rx_packet_i.error -radix hexadecimal}} -expand -subitemconfig {/dhcp_in_ip_module_tb/uut1/dhcp_rx_packet_i.data {-color {Medium Orchid} -height 17 -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/dhcp_rx_packet_i.valid {-color {Medium Orchid} -height 17 -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/dhcp_rx_packet_i.sop {-color {Medium Orchid} -height 17 -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/dhcp_rx_packet_i.eop {-color {Medium Orchid} -height 17 -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/dhcp_rx_packet_i.empty {-color {Medium Orchid} -height 17 -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/dhcp_rx_packet_i.error {-color {Medium Orchid} -height 17 -radix hexadecimal}} /dhcp_in_ip_module_tb/uut1/dhcp_rx_packet_i
add wave -noupdate -color Gold /dhcp_in_ip_module_tb/uut1/dhcp_tx_ready_i
add wave -noupdate -color Gold /dhcp_in_ip_module_tb/uut1/udp_tx_id_o
add wave -noupdate -color Gold -radix hexadecimal -childformat {{/dhcp_in_ip_module_tb/uut1/dhcp_tx_packet_o.data -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/dhcp_tx_packet_o.valid -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/dhcp_tx_packet_o.sop -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/dhcp_tx_packet_o.eop -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/dhcp_tx_packet_o.empty -radix hexadecimal} {/dhcp_in_ip_module_tb/uut1/dhcp_tx_packet_o.error -radix hexadecimal}} -expand -subitemconfig {/dhcp_in_ip_module_tb/uut1/dhcp_tx_packet_o.data {-color Gold -height 17 -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/dhcp_tx_packet_o.valid {-color Gold -height 17 -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/dhcp_tx_packet_o.sop {-color Gold -height 17 -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/dhcp_tx_packet_o.eop {-color Gold -height 17 -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/dhcp_tx_packet_o.empty {-color Gold -height 17 -radix hexadecimal} /dhcp_in_ip_module_tb/uut1/dhcp_tx_packet_o.error {-color Gold -height 17 -radix hexadecimal}} /dhcp_in_ip_module_tb/uut1/dhcp_tx_packet_o
add wave -noupdate -radix hexadecimal -radixshowbase 0 /dhcp_in_ip_module_tb/uut1/my_mac_i
add wave -noupdate -radix hexadecimal -radixshowbase 0 /dhcp_in_ip_module_tb/uut1/my_ip_o
add wave -noupdate /dhcp_in_ip_module_tb/uut1/one_ms_tick_i
add wave -noupdate -radix binary -radixshowbase 0 /dhcp_in_ip_module_tb/uut1/status_vector_o
add wave -noupdate -expand -group {DHCP module} /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/dhcp_rx_operation
add wave -noupdate -expand -group {DHCP module} -radix decimal /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/dhcp_lease_time
add wave -noupdate -expand -group {DHCP module} /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/dhcp_server_ip
add wave -noupdate -expand -group {DHCP module} -color Cyan /dhcp_in_ip_module_tb/uut1/dhcp_state
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} -color Gold /dhcp_in_ip_module_tb/uut1/udp_tx_id
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} -color Cyan /dhcp_in_ip_module_tb/uut1/dhcp_state
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} /dhcp_in_ip_module_tb/uut1/send_dhcp_decline
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} /dhcp_in_ip_module_tb/uut1/send_dhcp_discover
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} -radix decimal /dhcp_in_ip_module_tb/uut1/blk_make_tx_interface/secs
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} /dhcp_in_ip_module_tb/uut1/resend_dhcp_discover
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} /dhcp_in_ip_module_tb/uut1/send_dhcp_release
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} /dhcp_in_ip_module_tb/uut1/send_dhcp_request
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} -radix decimal /dhcp_in_ip_module_tb/uut1/blk_manage_lease_times/seconds
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} /dhcp_in_ip_module_tb/uut1/blk_manage_lease_times/blk_backoff_request/timer_pos
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} /dhcp_in_ip_module_tb/uut1/resend_dhcp_request
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} /dhcp_in_ip_module_tb/uut1/dhcp_offer_selected
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} /dhcp_in_ip_module_tb/uut1/dhcp_acknowledge
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} /dhcp_in_ip_module_tb/uut1/dhcp_nack
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} /dhcp_in_ip_module_tb/uut1/dhcp_accept
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} /dhcp_in_ip_module_tb/uut1/decline_sent
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} /dhcp_in_ip_module_tb/uut1/t1_expired
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} /dhcp_in_ip_module_tb/uut1/t2_expired
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} /dhcp_in_ip_module_tb/uut1/lease_expired
add wave -noupdate -expand -group {DHCP module} -group {Global FSM} /dhcp_in_ip_module_tb/uut1/xid
add wave -noupdate -expand -group {DHCP module} -expand -group {TX FSM} -color Cyan /dhcp_in_ip_module_tb/uut1/blk_make_tx_interface/tx_state
add wave -noupdate -expand -group {DHCP module} -expand -group {TX FSM} -radix decimal /dhcp_in_ip_module_tb/uut1/blk_make_tx_interface/tx_count
add wave -noupdate -expand -group {DHCP module} -expand -group {TX FSM} /dhcp_in_ip_module_tb/uut1/blk_make_tx_interface/dhcp_packet
add wave -noupdate -expand -group {DHCP module} -expand -group {TX FSM} /dhcp_in_ip_module_tb/uut1/blk_make_tx_interface/udp_crc
add wave -noupdate -expand -group {DHCP module} -expand -group {TX FSM} /dhcp_in_ip_module_tb/uut1/blk_make_tx_interface/udp_length
add wave -noupdate -expand -group {DHCP module} -expand -group {TX FSM} /dhcp_in_ip_module_tb/uut1/blk_make_tx_interface/fifo_state
add wave -noupdate -expand -group {DHCP module} -expand -group {TX FSM} -expand -group {TX OPTIONS FIFO} /dhcp_in_ip_module_tb/uut1/blk_make_tx_interface/blk_gen_tx_data/blk_fifo_handler/dhcp_tx_operation
add wave -noupdate -expand -group {DHCP module} -expand -group {TX FSM} -expand -group {TX OPTIONS FIFO} /dhcp_in_ip_module_tb/uut1/blk_make_tx_interface/blk_gen_tx_data/blk_fifo_handler/dhcp_options_fifo_din
add wave -noupdate -expand -group {DHCP module} -expand -group {TX FSM} -expand -group {TX OPTIONS FIFO} /dhcp_in_ip_module_tb/uut1/blk_make_tx_interface/blk_gen_tx_data/blk_fifo_handler/dhcp_options_fifo_wen
add wave -noupdate -expand -group {DHCP module} -expand -group {TX FSM} -expand -group {TX OPTIONS FIFO} /dhcp_in_ip_module_tb/uut1/blk_make_tx_interface/blk_gen_tx_data/blk_fifo_handler/dhcp_options_fifo_ren
add wave -noupdate -expand -group {DHCP module} -expand -group {TX FSM} -expand -group {TX OPTIONS FIFO} /dhcp_in_ip_module_tb/uut1/blk_make_tx_interface/blk_gen_tx_data/blk_fifo_handler/dhcp_options_fifo_dout
add wave -noupdate -expand -group {DHCP module} -expand -group {TX FSM} -expand -group {TX OPTIONS FIFO} /dhcp_in_ip_module_tb/uut1/blk_make_tx_interface/blk_gen_tx_data/blk_fifo_handler/dhcp_options_fifo_full
add wave -noupdate -expand -group {DHCP module} -expand -group {TX FSM} -expand -group {TX OPTIONS FIFO} /dhcp_in_ip_module_tb/uut1/blk_make_tx_interface/blk_gen_tx_data/blk_fifo_handler/dhcp_options_fifo_empty
add wave -noupdate -expand -group {DHCP module} -expand -group {TX FSM} /dhcp_in_ip_module_tb/uut1/blk_make_tx_interface/dhcp_options
add wave -noupdate -expand -group {DHCP module} -expand -group RX -color Cyan /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/rx_state
add wave -noupdate -expand -group {DHCP module} -expand -group RX -color {Medium Orchid} /dhcp_in_ip_module_tb/uut1/udp_rx_id
add wave -noupdate -expand -group {DHCP module} -expand -group RX /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/rx_type
add wave -noupdate -expand -group {DHCP module} -expand -group RX /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/dhcp_rx_ready_i
add wave -noupdate -expand -group {DHCP module} -expand -group RX /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/rx_count
add wave -noupdate -expand -group {DHCP module} -expand -group RX -expand /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/rx_packet_reg
add wave -noupdate -expand -group {DHCP module} -expand -group RX /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/offered_yiaddr
add wave -noupdate -expand -group {DHCP module} -expand -group RX /dhcp_in_ip_module_tb/uut1/yourid
add wave -noupdate -expand -group {DHCP module} -expand -group RX -expand -group {RX OPT FIFO} /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/dhcp_rx_options_fifo_din
add wave -noupdate -expand -group {DHCP module} -expand -group RX -expand -group {RX OPT FIFO} /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/dhcp_rx_options_fifo_wen
add wave -noupdate -expand -group {DHCP module} -expand -group RX -expand -group {RX OPT FIFO} /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/dhcp_rx_options_fifo_ren
add wave -noupdate -expand -group {DHCP module} -expand -group RX -expand -group {RX OPT FIFO} /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/dhcp_rx_options_fifo_dout
add wave -noupdate -expand -group {DHCP module} -expand -group RX -expand -group {RX OPT FIFO} /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/dhcp_rx_options_fifo_full
add wave -noupdate -expand -group {DHCP module} -expand -group RX -expand -group {RX OPT FIFO} /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/dhcp_rx_options_fifo_empty
add wave -noupdate -expand -group {DHCP module} -expand -group RX -expand -group {RX OPT FIFO} -radix decimal /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/value_length
add wave -noupdate -expand -group {DHCP module} -expand -group RX /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/value_buffer
add wave -noupdate -expand -group {DHCP module} -expand -group RX -color Cyan /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/dhcp_option
add wave -noupdate -expand -group {DHCP module} -expand -group RX -color Cyan /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/blk_dhcp_rx_options_fifo_handler/option_state
add wave -noupdate -expand -group {DHCP module} -expand -group RX /dhcp_in_ip_module_tb/uut1/blk_make_rx_interface/parse_options_done
add wave -noupdate -expand -group {DHCP module} -expand -group {Lease timers} /dhcp_in_ip_module_tb/uut1/one_ms_tick_i
add wave -noupdate -expand -group {DHCP module} -expand -group {Lease timers} -radix decimal /dhcp_in_ip_module_tb/uut1/blk_manage_lease_times/lease
add wave -noupdate -expand -group {DHCP module} -expand -group {Lease timers} -radix decimal /dhcp_in_ip_module_tb/uut1/blk_manage_lease_times/t1
add wave -noupdate -expand -group {DHCP module} -expand -group {Lease timers} -radix decimal /dhcp_in_ip_module_tb/uut1/blk_manage_lease_times/t2
add wave -noupdate -expand -group {DHCP module} -expand -group {Lease timers} /dhcp_in_ip_module_tb/uut1/blk_manage_lease_times/second_tick
add wave -noupdate -expand -group {DHCP module} -expand -group {Lease timers} /dhcp_in_ip_module_tb/uut1/blk_manage_lease_times/seconds
add wave -noupdate -group {IP module} /dhcp_in_ip_module_tb/uut2/ip_netmask_i
add wave -noupdate -group {IP module} /dhcp_in_ip_module_tb/uut2/ip_broadcast_addr
add wave -noupdate -group {IP module} -radix binary /dhcp_in_ip_module_tb/uut2/status_vector_o
add wave -noupdate -group {IP module} -expand -group {IP RX} /dhcp_in_ip_module_tb/uut2/blk_stripoff_header/rx_state
add wave -noupdate -group {IP module} -expand -group {IP RX} /dhcp_in_ip_module_tb/uut2/blk_stripoff_header/rx_ready
add wave -noupdate -group {IP module} -expand -group {IP RX} /dhcp_in_ip_module_tb/uut2/blk_stripoff_header/rx_count
add wave -noupdate -group {IP module} -expand -group {IP RX} /dhcp_in_ip_module_tb/uut2/blk_stripoff_header/src_ip_accept
add wave -noupdate -group {IP module} -expand -group {IP RX} /dhcp_in_ip_module_tb/uut2/blk_stripoff_header/protocol
add wave -noupdate -group {IP module} -expand -group {IP RX} /dhcp_in_ip_module_tb/uut2/blk_stripoff_header/icmp_in_ready
add wave -noupdate -group {IP module} -expand -group {IP RX} /dhcp_in_ip_module_tb/uut2/blk_stripoff_header/rx_mux
add wave -noupdate -group {IP module} -expand -group {IP RX} /dhcp_in_ip_module_tb/uut2/blk_stripoff_header/tx_mux
add wave -noupdate -group {IP module} -expand -group {IP RX} /dhcp_in_ip_module_tb/uut2/blk_stripoff_header/udp_tx_id_r
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2976000 ps} 0}
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
WaveRestoreZoom {2943661 ps} {4995959 ps}
run -all