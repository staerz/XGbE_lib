onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group {Constants and Config} -radix binary -radixshowbase 0 /ip_module_tb/EOF_CHECK_EN
add wave -noupdate -group {Constants and Config} -radixshowbase 0 /ip_module_tb/udp_crc_en
add wave -noupdate -group {Constants and Config} -radix binary -radixshowbase 0 /ip_module_tb/IP_FILTER_EN
add wave -noupdate -group {Constants and Config} -radix decimal -radixshowbase 0 /ip_module_tb/ID_TABLE_DEPTH
add wave -noupdate -group {Constants and Config} -radix decimal -radixshowbase 0 /ip_module_tb/PAUSE_LENGTH
add wave -noupdate -group {Constants and Config} -radix hexadecimal -radixshowbase 0 /ip_module_tb/ip_netmask
add wave -noupdate -group {Constants and Config} -radix hexadecimal -radixshowbase 0 /ip_module_tb/my_ip
add wave -noupdate -group {Constants and Config} -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/ip_broadcast_addr
add wave -noupdate /ip_module_tb/clk
add wave -noupdate /ip_module_tb/rst
add wave -noupdate -expand -group {IP RX Data} -color Cyan -radix binary -radixshowbase 0 /ip_module_tb/uut/ip_rx_ready_o
add wave -noupdate -expand -group {IP RX Data} -color Cyan -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/ip_rx_packet_i
add wave -noupdate -group {Check header} -radixshowbase 0 /ip_module_tb/uut/blk_stripoff_header/rx_state
add wave -noupdate -group {Check header} -radixshowbase 0 /ip_module_tb/uut/blk_stripoff_header/protocol
add wave -noupdate -group {Check header} -radixshowbase 0 /ip_module_tb/uut/blk_stripoff_header/src_ip_accept
add wave -noupdate -group {Check header} -radixshowbase 0 /ip_module_tb/uut/icmp_request
add wave -noupdate -expand -group {UDP TX Data} -color Aquamarine -radix binary -radixshowbase 0 /ip_module_tb/uut/udp_tx_ready_i
add wave -noupdate -expand -group {UDP TX Data} -color Aquamarine -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/udp_tx_packet_o
add wave -noupdate -expand -group {UDP TX Data} -color Aquamarine -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/udp_tx_id_o
add wave -noupdate -radix decimal -radixshowbase 0 /ip_module_tb/blk_simulation/counter
add wave -noupdate -expand -group port_io_table /ip_module_tb/uut/blk_stripoff_header/udp_tx_id_r
add wave -noupdate -expand -group port_io_table -color Gold /ip_module_tb/uut/blk_stripoff_header/blk_make_ip_udp_table/disco_wren
add wave -noupdate -expand -group port_io_table -color Gold -radix hexadecimal /ip_module_tb/uut/blk_stripoff_header/blk_make_ip_udp_table/disco_id
add wave -noupdate -expand -group port_io_table -color Gold -radix hexadecimal /ip_module_tb/uut/blk_stripoff_header/blk_make_ip_udp_table/disco_IP
add wave -noupdate -expand -group port_io_table -color Gold /ip_module_tb/uut/reco_en
add wave -noupdate -expand -group port_io_table -color Gold -radix hexadecimal /ip_module_tb/uut/udp_rx_id_i
add wave -noupdate -expand -group port_io_table -color Gold /ip_module_tb/uut/reco_ip_found
add wave -noupdate -expand -group port_io_table -color Gold -radix hexadecimal /ip_module_tb/uut/reco_ip
add wave -noupdate -expand -group port_io_table -color Gold /ip_module_tb/uut/blk_stripoff_header/blk_make_ip_udp_table/inst_id_ip_table/port_io_table_data
add wave -noupdate -expand -group {ICMP Module} -group Internals /ip_module_tb/uut/blk_stripoff_header/inst_icmp/calculate_icmp_crc/crc_rst
add wave -noupdate -expand -group {ICMP Module} -group Internals -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/blk_stripoff_header/inst_icmp/calculate_icmp_crc/crc_in
add wave -noupdate -expand -group {ICMP Module} -group Internals -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/blk_stripoff_header/inst_icmp/icmp_crc
add wave -noupdate -expand -group {ICMP Module} /ip_module_tb/uut/blk_stripoff_header/inst_icmp/is_icmp_request_i
add wave -noupdate -expand -group {ICMP Module} -color Thistle /ip_module_tb/uut/blk_stripoff_header/inst_icmp/icmp_tx_ready_i
add wave -noupdate -expand -group {ICMP Module} -color Thistle -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/blk_stripoff_header/inst_icmp/icmp_tx_packet_o
add wave -noupdate -expand -group {UDP RX Data} -color White -radix binary -radixshowbase 0 /ip_module_tb/uut/udp_rx_ready_o
add wave -noupdate -expand -group {UDP RX Data} -color White -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/udp_rx_packet_i
add wave -noupdate -expand -group {UDP RX Data} -color White -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/udp_rx_id_i
add wave -noupdate -radix decimal -radixshowbase 0 /ip_module_tb/blk_simulation/counter
add wave -noupdate -group {Build header} -radixshowbase 0 /ip_module_tb/uut/blk_ip_tx/inst_ip_header_module/tx_state
add wave -noupdate -group {Build header} -radix decimal -radixshowbase 0 /ip_module_tb/uut/blk_ip_tx/inst_ip_header_module/tx_count
add wave -noupdate -group {Build header} -radix binary -childformat {{/ip_module_tb/uut/blk_ip_tx/inst_ip_header_module/request_ip/request(1) -radix binary} {/ip_module_tb/uut/blk_ip_tx/inst_ip_header_module/request_ip/request(0) -radix binary}} -radixshowbase 0 -subitemconfig {/ip_module_tb/uut/blk_ip_tx/inst_ip_header_module/request_ip/request(1) {-height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/blk_ip_tx/inst_ip_header_module/request_ip/request(0) {-height 18 -radix binary -radixshowbase 0}} /ip_module_tb/uut/blk_ip_tx/inst_ip_header_module/request_ip/request
add wave -noupdate -group {Build header} -group {CRC check} -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/blk_ip_tx/inst_ip_header_module/make_tx_interface/IP_header_before_CRC
add wave -noupdate -group {Build header} -group {CRC check} -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/blk_ip_tx/inst_ip_header_module/make_tx_interface/IP_CRC_out
add wave -noupdate -group {Build header} -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/blk_ip_tx/inst_ip_header_module/ip_tx_packet_o
add wave -noupdate -expand -group {IP TX Data} -color Gray75 -radix binary -radixshowbase 0 /ip_module_tb/uut/ip_tx_ready_i
add wave -noupdate -expand -group {IP TX Data} -color Gray75 -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/ip_tx_packet_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1765000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 227
configure wave -valuecolwidth 178
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
WaveRestoreZoom {0 ps} {2500 ns}
run 2500 ns
