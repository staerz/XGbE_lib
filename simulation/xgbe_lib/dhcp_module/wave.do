onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix decimal -radixshowbase 0 /dhcp_module_tb/cnt
add wave -noupdate /dhcp_module_tb/uut/clk
add wave -noupdate /dhcp_module_tb/uut/rst
add wave -noupdate -color {Medium Orchid} /dhcp_module_tb/uut/dhcp_rx_ready_o
add wave -noupdate -color {Medium Orchid} -radix hexadecimal -childformat {{/dhcp_module_tb/uut/dhcp_rx_packet_i.data -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_rx_packet_i.valid -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_rx_packet_i.sop -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_rx_packet_i.eop -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_rx_packet_i.empty -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_rx_packet_i.error -radix hexadecimal}} -expand -subitemconfig {/dhcp_module_tb/uut/dhcp_rx_packet_i.data {-color {Medium Orchid} -height 17 -radix hexadecimal} /dhcp_module_tb/uut/dhcp_rx_packet_i.valid {-color {Medium Orchid} -height 17 -radix hexadecimal} /dhcp_module_tb/uut/dhcp_rx_packet_i.sop {-color {Medium Orchid} -height 17 -radix hexadecimal} /dhcp_module_tb/uut/dhcp_rx_packet_i.eop {-color {Medium Orchid} -height 17 -radix hexadecimal} /dhcp_module_tb/uut/dhcp_rx_packet_i.empty {-color {Medium Orchid} -height 17 -radix hexadecimal} /dhcp_module_tb/uut/dhcp_rx_packet_i.error {-color {Medium Orchid} -height 17 -radix hexadecimal}} /dhcp_module_tb/uut/dhcp_rx_packet_i
add wave -noupdate -color Gold /dhcp_module_tb/uut/dhcp_tx_ready_i
add wave -noupdate -color Gold -radix hexadecimal -childformat {{/dhcp_module_tb/uut/dhcp_tx_packet_o.data -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_tx_packet_o.valid -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_tx_packet_o.sop -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_tx_packet_o.eop -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_tx_packet_o.empty -radix hexadecimal} {/dhcp_module_tb/uut/dhcp_tx_packet_o.error -radix hexadecimal}} -expand -subitemconfig {/dhcp_module_tb/uut/dhcp_tx_packet_o.data {-color Gold -height 17 -radix hexadecimal} /dhcp_module_tb/uut/dhcp_tx_packet_o.valid {-color Gold -height 17 -radix hexadecimal} /dhcp_module_tb/uut/dhcp_tx_packet_o.sop {-color Gold -height 17 -radix hexadecimal} /dhcp_module_tb/uut/dhcp_tx_packet_o.eop {-color Gold -height 17 -radix hexadecimal} /dhcp_module_tb/uut/dhcp_tx_packet_o.empty {-color Gold -height 17 -radix hexadecimal} /dhcp_module_tb/uut/dhcp_tx_packet_o.error {-color Gold -height 17 -radix hexadecimal}} /dhcp_module_tb/uut/dhcp_tx_packet_o
add wave -noupdate -color Khaki /dhcp_module_tb/blk_uvvm/dhcp_rx_expect
add wave -noupdate -radix hexadecimal -radixshowbase 0 /dhcp_module_tb/uut/my_mac_i
add wave -noupdate -radix hexadecimal -radixshowbase 0 /dhcp_module_tb/uut/my_ip_o
add wave -noupdate /dhcp_module_tb/uut/ip_netmask_o
add wave -noupdate -radix hexadecimal -radixshowbase 0 /dhcp_module_tb/uut/dhcp_server_ip_o
add wave -noupdate /dhcp_module_tb/uut/one_ms_tick_i
add wave -noupdate -radix binary -radixshowbase 0 /dhcp_module_tb/uut/status_vector_o
add wave -noupdate -expand -group {Global FSM} -color Cyan /dhcp_module_tb/uut/dhcp_state
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/send_dhcp_decline
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/send_dhcp_discover
add wave -noupdate -expand -group {Global FSM} -radix decimal /dhcp_module_tb/uut/blk_make_tx_interface/secs
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/resend_dhcp_discover
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/send_dhcp_release
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/send_dhcp_request
add wave -noupdate -expand -group {Global FSM} -radix decimal /dhcp_module_tb/uut/blk_manage_lease_times/seconds
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/blk_manage_lease_times/blk_backoff_request/timer_pos
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/resend_dhcp_request
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/dhcp_offer_selected
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/dhcp_acknowledge
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/dhcp_nack
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/reco_done
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/dhcp_timedout
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/t1_expired
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/t2_expired
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/lease_expired
add wave -noupdate -expand -group {Global FSM} /dhcp_module_tb/uut/xid
add wave -noupdate -group {TX FSM} -color Cyan /dhcp_module_tb/uut/blk_make_tx_interface/tx_state
add wave -noupdate -group {TX FSM} -radix decimal /dhcp_module_tb/uut/blk_make_tx_interface/tx_count
add wave -noupdate -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/dhcp_packet
add wave -noupdate -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/udp_crc
add wave -noupdate -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/udp_length
add wave -noupdate -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/fifo_state
add wave -noupdate -group {TX FSM} -expand -group {TX OPTIONS FIFO} /dhcp_module_tb/uut/blk_make_tx_interface/blk_gen_tx_data/blk_fifo_handler/dhcp_tx_operation
add wave -noupdate -group {TX FSM} -expand -group {TX OPTIONS FIFO} /dhcp_module_tb/uut/blk_make_tx_interface/blk_gen_tx_data/blk_fifo_handler/dhcp_options_fifo_din
add wave -noupdate -group {TX FSM} -expand -group {TX OPTIONS FIFO} /dhcp_module_tb/uut/blk_make_tx_interface/blk_gen_tx_data/blk_fifo_handler/dhcp_options_fifo_wen
add wave -noupdate -group {TX FSM} -expand -group {TX OPTIONS FIFO} /dhcp_module_tb/uut/blk_make_tx_interface/blk_gen_tx_data/blk_fifo_handler/dhcp_options_fifo_ren
add wave -noupdate -group {TX FSM} -expand -group {TX OPTIONS FIFO} /dhcp_module_tb/uut/blk_make_tx_interface/blk_gen_tx_data/blk_fifo_handler/dhcp_options_fifo_dout
add wave -noupdate -group {TX FSM} -expand -group {TX OPTIONS FIFO} /dhcp_module_tb/uut/blk_make_tx_interface/blk_gen_tx_data/blk_fifo_handler/dhcp_options_fifo_full
add wave -noupdate -group {TX FSM} -expand -group {TX OPTIONS FIFO} /dhcp_module_tb/uut/blk_make_tx_interface/blk_gen_tx_data/blk_fifo_handler/dhcp_options_fifo_empty
add wave -noupdate -group {TX FSM} /dhcp_module_tb/uut/blk_make_tx_interface/dhcp_options
add wave -noupdate -expand -group RX -color Cyan /dhcp_module_tb/uut/blk_make_rx_interface/rx_state
add wave -noupdate -expand -group RX /dhcp_module_tb/uut/blk_make_rx_interface/dhcp_rx_ready_i
add wave -noupdate -expand -group RX /dhcp_module_tb/uut/blk_make_rx_interface/rx_count
add wave -noupdate -expand -group RX -expand /dhcp_module_tb/uut/blk_make_rx_interface/rx_packet_reg
add wave -noupdate -expand -group RX /dhcp_module_tb/uut/blk_make_rx_interface/offered_yiaddr
add wave -noupdate -expand -group RX /dhcp_module_tb/uut/yourid
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
add wave -noupdate /dhcp_module_tb/uut/blk_make_rx_interface/dhcp_rx_operation
add wave -noupdate -radix decimal /dhcp_module_tb/uut/blk_make_rx_interface/dhcp_lease_time
add wave -noupdate /dhcp_module_tb/uut/blk_make_rx_interface/dhcp_server_ip
add wave -noupdate -expand -group {Lease timers} /dhcp_module_tb/uut/one_ms_tick_i
add wave -noupdate -expand -group {Lease timers} /dhcp_module_tb/uut/second_tick
add wave -noupdate -expand -group {Lease timers} -radix decimal /dhcp_module_tb/uut/blk_manage_lease_times/lease
add wave -noupdate -expand -group {Lease timers} -radix decimal /dhcp_module_tb/uut/blk_manage_lease_times/t1
add wave -noupdate -expand -group {Lease timers} -radix decimal /dhcp_module_tb/uut/blk_manage_lease_times/t2
add wave -noupdate -expand -group {Lease timers} /dhcp_module_tb/uut/blk_manage_lease_times/seconds
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {20159407 ps} 0}
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
WaveRestoreZoom {0 ps} {48057734 ps}
run -all