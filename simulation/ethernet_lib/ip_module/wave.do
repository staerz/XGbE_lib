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
add wave -noupdate -expand -group {IP RX Data} -color Cyan -radix binary -radixshowbase 0 /ip_module_tb/uut/ip_rx_ready
add wave -noupdate -expand -group {IP RX Data} -color Cyan -radix hexadecimal -childformat {{/ip_module_tb/uut/ip_rx_data(63) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(62) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(61) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(60) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(59) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(58) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(57) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(56) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(55) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(54) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(53) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(52) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(51) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(50) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(49) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(48) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(47) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(46) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(45) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(44) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(43) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(42) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(41) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(40) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(39) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(38) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(37) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(36) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(35) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(34) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(33) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(32) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(31) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(30) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(29) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(28) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(27) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(26) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(25) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(24) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(23) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(22) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(21) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(20) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(19) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(18) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(17) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(16) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(15) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(14) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(13) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(12) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(11) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(10) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(9) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(8) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(7) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(6) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(5) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(4) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(3) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(2) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(1) -radix hexadecimal} {/ip_module_tb/uut/ip_rx_data(0) -radix hexadecimal}} -radixshowbase 0 -subitemconfig {/ip_module_tb/uut/ip_rx_data(63) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(62) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(61) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(60) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(59) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(58) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(57) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(56) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(55) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(54) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(53) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(52) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(51) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(50) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(49) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(48) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(47) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(46) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(45) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(44) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(43) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(42) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(41) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(40) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(39) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(38) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(37) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(36) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(35) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(34) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(33) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(32) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(31) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(30) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(29) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(28) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(27) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(26) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(25) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(24) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(23) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(22) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(21) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(20) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(19) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(18) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(17) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(16) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(15) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(14) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(13) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(12) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(11) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(10) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(9) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(8) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(7) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(6) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(5) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(4) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(3) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(2) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(1) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0} /ip_module_tb/uut/ip_rx_data(0) {-color Cyan -height 18 -radix hexadecimal -radixshowbase 0}} /ip_module_tb/uut/ip_rx_data
add wave -noupdate -expand -group {IP RX Data} -color Cyan -radix binary -childformat {{/ip_module_tb/uut/ip_rx_ctrl(6) -radix binary} {/ip_module_tb/uut/ip_rx_ctrl(5) -radix binary} {/ip_module_tb/uut/ip_rx_ctrl(4) -radix binary} {/ip_module_tb/uut/ip_rx_ctrl(3) -radix binary} {/ip_module_tb/uut/ip_rx_ctrl(2) -radix binary} {/ip_module_tb/uut/ip_rx_ctrl(1) -radix binary} {/ip_module_tb/uut/ip_rx_ctrl(0) -radix binary}} -radixshowbase 0 -expand -subitemconfig {/ip_module_tb/uut/ip_rx_ctrl(6) {-color Cyan -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/ip_rx_ctrl(5) {-color Cyan -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/ip_rx_ctrl(4) {-color Cyan -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/ip_rx_ctrl(3) {-color Cyan -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/ip_rx_ctrl(2) {-color Cyan -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/ip_rx_ctrl(1) {-color Cyan -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/ip_rx_ctrl(0) {-color Cyan -height 18 -radix binary -radixshowbase 0}} /ip_module_tb/uut/ip_rx_ctrl
add wave -noupdate -group {Check header} -radixshowbase 0 /ip_module_tb/uut/stripoff_header/rx_state
add wave -noupdate -group {Check header} -radixshowbase 0 /ip_module_tb/uut/stripoff_header/protocol
add wave -noupdate -group {Check header} -radixshowbase 0 /ip_module_tb/uut/stripoff_header/src_ip_accept
add wave -noupdate -group {Check header} -radixshowbase 0 /ip_module_tb/uut/icmp_request
add wave -noupdate -expand -group {UDP TX Data} -color Aquamarine -radix binary -radixshowbase 0 /ip_module_tb/uut/udp_tx_ready
add wave -noupdate -expand -group {UDP TX Data} -color Aquamarine -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/udp_tx_data
add wave -noupdate -expand -group {UDP TX Data} -color Aquamarine -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/udp_tx_id
add wave -noupdate -expand -group {UDP TX Data} -color Aquamarine -radix binary -childformat {{/ip_module_tb/uut/udp_tx_ctrl(6) -radix binary} {/ip_module_tb/uut/udp_tx_ctrl(5) -radix binary} {/ip_module_tb/uut/udp_tx_ctrl(4) -radix binary} {/ip_module_tb/uut/udp_tx_ctrl(3) -radix binary} {/ip_module_tb/uut/udp_tx_ctrl(2) -radix binary} {/ip_module_tb/uut/udp_tx_ctrl(1) -radix binary} {/ip_module_tb/uut/udp_tx_ctrl(0) -radix binary}} -radixshowbase 0 -expand -subitemconfig {/ip_module_tb/uut/udp_tx_ctrl(6) {-color Aquamarine -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/udp_tx_ctrl(5) {-color Aquamarine -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/udp_tx_ctrl(4) {-color Aquamarine -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/udp_tx_ctrl(3) {-color Aquamarine -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/udp_tx_ctrl(2) {-color Aquamarine -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/udp_tx_ctrl(1) {-color Aquamarine -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/udp_tx_ctrl(0) {-color Aquamarine -height 18 -radix binary -radixshowbase 0}} /ip_module_tb/uut/udp_tx_ctrl
add wave -noupdate -radix decimal -radixshowbase 0 /ip_module_tb/blk_simulation/counter
add wave -noupdate -expand -group port_io_table /ip_module_tb/uut/stripoff_header/udp_tx_id_i
add wave -noupdate -expand -group port_io_table -color Gold /ip_module_tb/uut/stripoff_header/make_ip_udp_table/disco_wren
add wave -noupdate -expand -group port_io_table -color Gold -radix hexadecimal /ip_module_tb/uut/stripoff_header/make_ip_udp_table/disco_id
add wave -noupdate -expand -group port_io_table -color Gold -radix hexadecimal /ip_module_tb/uut/stripoff_header/make_ip_udp_table/disco_IP
add wave -noupdate -expand -group port_io_table -color Gold /ip_module_tb/uut/reco_en
add wave -noupdate -expand -group port_io_table -color Gold -radix hexadecimal /ip_module_tb/uut/udp_rx_id
add wave -noupdate -expand -group port_io_table -color Gold /ip_module_tb/uut/reco_ip_found
add wave -noupdate -expand -group port_io_table -color Gold -radix hexadecimal /ip_module_tb/uut/reco_ip
add wave -noupdate -expand -group port_io_table -color Gold /ip_module_tb/uut/stripoff_header/make_ip_udp_table/id_ip_table_inst/port_io_table_data
add wave -noupdate -expand -group {ICMP Module} -group Internals /ip_module_tb/uut/stripoff_header/icmp_inst/calculate_icmp_crc/crc_rst
add wave -noupdate -expand -group {ICMP Module} -group Internals -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/stripoff_header/icmp_inst/calculate_icmp_crc/crc_in
add wave -noupdate -expand -group {ICMP Module} -group Internals -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/stripoff_header/icmp_inst/icmp_crc
add wave -noupdate -expand -group {ICMP Module} /ip_module_tb/uut/stripoff_header/icmp_inst/is_icmp_request
add wave -noupdate -expand -group {ICMP Module} -color Thistle /ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_ready
add wave -noupdate -expand -group {ICMP Module} -color Thistle -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_data
add wave -noupdate -expand -group {ICMP Module} -color Thistle -radix binary -childformat {{/ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_ctrl(6) -radix binary} {/ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_ctrl(5) -radix binary} {/ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_ctrl(4) -radix binary} {/ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_ctrl(3) -radix binary} {/ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_ctrl(2) -radix binary} {/ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_ctrl(1) -radix binary} {/ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_ctrl(0) -radix binary}} -radixshowbase 0 -expand -subitemconfig {/ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_ctrl(6) {-color Thistle -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_ctrl(5) {-color Thistle -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_ctrl(4) {-color Thistle -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_ctrl(3) {-color Thistle -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_ctrl(2) {-color Thistle -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_ctrl(1) {-color Thistle -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_ctrl(0) {-color Thistle -height 18 -radix binary -radixshowbase 0}} /ip_module_tb/uut/stripoff_header/icmp_inst/icmp_out_ctrl
add wave -noupdate -expand -group {UDP RX Data} -color White -radix binary -radixshowbase 0 /ip_module_tb/uut/UDP_rx_ready
add wave -noupdate -expand -group {UDP RX Data} -color White -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/UDP_rx_data
add wave -noupdate -expand -group {UDP RX Data} -color White -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/UDP_rx_ID
add wave -noupdate -expand -group {UDP RX Data} -color White -radix binary -childformat {{/ip_module_tb/uut/UDP_rx_ctrl(6) -radix binary} {/ip_module_tb/uut/UDP_rx_ctrl(5) -radix binary} {/ip_module_tb/uut/UDP_rx_ctrl(4) -radix binary} {/ip_module_tb/uut/UDP_rx_ctrl(3) -radix binary} {/ip_module_tb/uut/UDP_rx_ctrl(2) -radix binary} {/ip_module_tb/uut/UDP_rx_ctrl(1) -radix binary} {/ip_module_tb/uut/UDP_rx_ctrl(0) -radix binary}} -radixshowbase 0 -expand -subitemconfig {/ip_module_tb/uut/UDP_rx_ctrl(6) {-color White -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/UDP_rx_ctrl(5) {-color White -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/UDP_rx_ctrl(4) {-color White -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/UDP_rx_ctrl(3) {-color White -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/UDP_rx_ctrl(2) {-color White -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/UDP_rx_ctrl(1) {-color White -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/UDP_rx_ctrl(0) {-color White -height 18 -radix binary -radixshowbase 0}} /ip_module_tb/uut/UDP_rx_ctrl
add wave -noupdate -radix decimal -radixshowbase 0 /ip_module_tb/blk_simulation/counter
add wave -noupdate -group {Build header} -radixshowbase 0 /ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/tx_state
add wave -noupdate -group {Build header} -radix decimal -radixshowbase 0 /ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/tx_count
add wave -noupdate -group {Build header} -radix binary -childformat {{/ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/request_ip/request(1) -radix binary} {/ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/request_ip/request(0) -radix binary}} -radixshowbase 0 -subitemconfig {/ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/request_ip/request(1) {-height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/request_ip/request(0) {-height 18 -radix binary -radixshowbase 0}} /ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/request_ip/request
add wave -noupdate -group {Build header} -group {CRC check} -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/make_tx_interface/IP_header_before_CRC
add wave -noupdate -group {Build header} -group {CRC check} -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/make_tx_interface/IP_CRC_out
add wave -noupdate -group {Build header} -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/IP_tx_data
add wave -noupdate -group {Build header} -radix binary -childformat {{/ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/ip_tx_ctrl(6) -radix binary} {/ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/ip_tx_ctrl(5) -radix binary} {/ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/ip_tx_ctrl(4) -radix binary} {/ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/ip_tx_ctrl(3) -radix binary} {/ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/ip_tx_ctrl(2) -radix binary} {/ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/ip_tx_ctrl(1) -radix binary} {/ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/ip_tx_ctrl(0) -radix binary}} -radixshowbase 0 -expand -subitemconfig {/ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/ip_tx_ctrl(6) {-height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/ip_tx_ctrl(5) {-height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/ip_tx_ctrl(4) {-height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/ip_tx_ctrl(3) {-height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/ip_tx_ctrl(2) {-height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/ip_tx_ctrl(1) {-height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/ip_tx_ctrl(0) {-height 18 -radix binary -radixshowbase 0}} /ip_module_tb/uut/gen_ip_tx/ip_header_module_inst/ip_tx_ctrl
add wave -noupdate -expand -group {IP TX Data} -color Gray75 -radix binary -radixshowbase 0 /ip_module_tb/uut/ip_tx_ready
add wave -noupdate -expand -group {IP TX Data} -color Gray75 -radix hexadecimal -radixshowbase 0 /ip_module_tb/uut/ip_tx_data
add wave -noupdate -expand -group {IP TX Data} -color Gray75 -radix binary -childformat {{/ip_module_tb/uut/ip_tx_ctrl(6) -radix binary} {/ip_module_tb/uut/ip_tx_ctrl(5) -radix binary} {/ip_module_tb/uut/ip_tx_ctrl(4) -radix binary} {/ip_module_tb/uut/ip_tx_ctrl(3) -radix binary} {/ip_module_tb/uut/ip_tx_ctrl(2) -radix binary} {/ip_module_tb/uut/ip_tx_ctrl(1) -radix binary} {/ip_module_tb/uut/ip_tx_ctrl(0) -radix binary}} -radixshowbase 0 -expand -subitemconfig {/ip_module_tb/uut/ip_tx_ctrl(6) {-color Gray75 -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/ip_tx_ctrl(5) {-color Gray75 -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/ip_tx_ctrl(4) {-color Gray75 -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/ip_tx_ctrl(3) {-color Gray75 -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/ip_tx_ctrl(2) {-color Gray75 -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/ip_tx_ctrl(1) {-color Gray75 -height 18 -radix binary -radixshowbase 0} /ip_module_tb/uut/ip_tx_ctrl(0) {-color Gray75 -height 18 -radix binary -radixshowbase 0}} /ip_module_tb/uut/ip_tx_ctrl
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
