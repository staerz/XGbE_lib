-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Ethernet to UPD module
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details
--! Watches out for incoming Ethernet frames on the ETH interface, removes
--! Ethernet and IP layer and forwards blank UDP frames to enclosed module.
--! Watches out for incoming UDP frames on the UDP interface, adds
--! Ethernet and IP layer and forwards full Ethernet frames to enclosed module.
--! Incorporates ARP and ICMP functionality as internal modules.
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Ethernet to UPD module
entity ethernet_to_udp_module is
  generic (
    --! @name Configuration of the internal ethernet_module
    --! @{

    --! @brief End of frame check
    --! @details If enabled, the module counter checks the IP length indication and
    --! raises the error indicator upon eof if not matching.
    --!
    --! Also used in the ip_module.
    EOF_CHECK_EN      : std_logic                := '1';
    --! @brief The minimal number of clock cycles between two outgoing frames.
    --! @ details
    --! Also used in the ip_module.
    PAUSE_LENGTH      : integer range 0 to 10    := 0;
    --! Timeout to reconstruct MAC from IP in milliseconds
    MAC_TIMEOUT       : integer range 1 to 10000 := 1000;
    --! @}

    --! @name Configuration of the internal ip_module
    --! @{

    --! @brief Post-UDP-module UDP CRC calculation
    --! @details If enabled, the UDP check sum will be (re)calculated from the UDP
    --! pseudo header.
    --! This requires the check sum over the UDP data already being present in the
    --! UDP CRC field.
    --! If disabled, the check sum is omitted and set to x"0000".
    UDP_CRC_EN        : boolean                 := true;
    --! @brief Enable IP address filtering
    --! @details If enabled, only packets arriving from IP addresses of the same
    --! network (specified by ip_netmask_i) as ip_scr_addr are accepted.
    IP_FILTER_EN      : std_logic               := '1';
    --! Depth of table (number of stored connections)
    ID_TABLE_DEPTH    : integer range 1 to 1024 := 4;
    --! @}

    --! @name Configuration of the internal arp_module
    --! @{

    --! Timeout in milliseconds
    ARP_TIMEOUT       : integer range 2 to 1000 := 50;
    --! Cycle time in milliseconds for ARP requests (when repetitions are needed)
    ARP_REQUEST_CYCLE : integer range 1 to 1000 := 2;
    --! Depth of ARP table (number of stored connections)
    ARP_TABLE_DEPTH   : integer range 1 to 1024 := 4;
    --! @}

    --! Duration of a millisecond (ms) in clock cycles of clk
    ONE_MILLISECOND   : integer := 156250
  );
  port (
    --! Clock
    clk             : in    std_logic;
    --! Reset, sync with #clk
    rst             : in    std_logic;

    --! @name Avalon-ST from ETH outside world
    --! @{

    --! RX ready
    eth_rx_ready_o  : out   std_logic;
    --! RX data and controls
    eth_rx_packet_i : in    t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @name Avalon-ST to ETH outside world
    --! @{

    --! TX ready
    eth_tx_ready_i  : in    std_logic;
    --! TX data and controls
    eth_tx_packet_o : out   t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @name Avalon-ST from UDP module
    --! @{

    --! RX ready
    udp_rx_ready_o  : out   std_logic;
    --! RX data and controls
    udp_rx_packet_i : in    t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! RX packet ID (to restore IP address)
    udp_rx_id_i     : in    std_logic_vector(15 downto 0);
    --! @}

    --! @name Avalon-ST to UDP module
    --! @{

    --! TX ready
    udp_tx_ready_i  : in    std_logic;
    --! TX data and controls
    udp_tx_packet_o : out   t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! TX packet ID (to restore IP address)
    udp_tx_id_o     : out   std_logic_vector(15 downto 0);
    --! @}

    --! @name Configuration of the module
    --! @{

    --! MAC address of the module
    my_mac_i        : in    std_logic_vector(47 downto 0);
    --! IP address
    my_ip_i         : in    std_logic_vector(31 downto 0);
    --! IP subnet mask
    ip_netmask_i    : in    std_logic_vector(31 downto 0) := x"ff_ff_ff_00";
    --! @}

    --! @brief Status of the module
    --! @details Status of the module
    --! - 26: ETH module: Interface merger: ARP is being forwarded
    --! - 25: ETH module: Interface merger: ETH is being forwarded
    --! - 24: ETH module: Interface merger: module in idle
    --! - 23: ETH module: ETH TX: Waiting for MAC address
    --! - 22: ETH module: ETH TX: IP frame is being forwarded
    --! - 21: ETH module: ETH TX: IDLE mode
    --! - 20: ETH module: RX FSM: ARP frame is being received
    --! - 19: ETH module: RX FSM:  IP frame is being received
    --! - 18: ETH module: RX FSM: IDLE mode
    --! - 17: ARP table full
    --! - 16: ARP table empty
    --! - 15: ARP request is being received
    --! - 14: ARP request is being answered
    --! - 13: ARP Data is being forwarded
    --! - 12: IP/ID table: table full
    --! - 11: IP/ID table: table empty
    --! - 10: ICMP: icmp_tx_ready_i
    --! - 9: ICMP: rx_fifo_wr_full
    --! - 8: ICMP: rx_fifo_wr_empty
    --! - 7: IP module: Interface merger: ICMP is being forwarded
    --! - 6: IP module: Interface merger: IP is being forwarded
    --! - 5: IP module: Interface merger: module in IDLE
    --! - 4: IP module: TX FSM in UDP mode (transmission ongoing)
    --! - 3: IP module: TX FSM in IDLE (transmission may still be fading out)
    --! - 2: IP module: RX FSM: UDP frame is being received
    --! - 1: IP module: RX FSM: ICMP frame is being received
    --! - 0: IP module: RX FSM: IDLE mode
    status_vector_o : out   std_logic_vector(26 downto 0)
  );
end entity ethernet_to_udp_module;

--! @cond
library xgbe_lib;
library misc;
--! @endcond

--! Implementation of the ethernet_to_udp_module
architecture behavioral of ethernet_to_udp_module is

  --! @name Avalon-ST ARP module to Ethernet module
  --! @{

  --! TX ready
  signal arp_to_eth_ready  : std_logic;
  --! TX data and controls
  signal arp_to_eth_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));

  --! @}

  --! @name Avalon-ST Ethernet module to ARP module
  --! @{

  --! RX ready
  signal eth_to_arp_ready  : std_logic;
  --! RX data and controls
  signal eth_to_arp_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));

  --! @}

  --! @name Avalon-ST IP module to Ethernet module
  --! @{

  --! TX ready
  signal eth_to_ip_ready  : std_logic;
  --! TX data and controls
  signal eth_to_ip_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));

  --! @}

  --! @name Avalon-ST Ethernet module to IP module
  --! @{

  --! RX ready
  signal ip_to_eth_ready  : std_logic;
  --! RX data and controls
  signal ip_to_eth_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));

  --! @}

  --! @name Interface for recovering MAC address from given IP address
  --! @{

  --! Recovery enable
  signal reco_en   : std_logic;
  --! IP address to recover
  signal reco_ip   : std_logic_vector(31 downto 0);
  --! Recovered MAX address
  signal reco_mac  : std_logic_vector(47 downto 0);
  --! recovery success: 1 = found, 0 = not found (time out)
  signal reco_done : std_logic;
  --! @}

  --! Clock cycle when 1 millisecond is passed
  signal one_ms_tick : std_logic;

  --! @name Status vectors of the internal modules
  --! @{

  --! ethernet_module
  signal eth_status_vector : std_logic_vector(8 downto 0);
  --! arp_module
  signal arp_status_vector : std_logic_vector(4 downto 0);
  --! ip_module
  signal ip_status_vector  : std_logic_vector(12 downto 0);
  --! @}

begin

  status_vector_o <= eth_status_vector & arp_status_vector & ip_status_vector;

  --! Instantiate the ethernet_module
  inst_ethernet_module : entity xgbe_lib.ethernet_module
  generic map (
    EOF_CHECK_EN => EOF_CHECK_EN,
    PAUSE_LENGTH => PAUSE_LENGTH,
    MAC_TIMEOUT  => MAC_TIMEOUT
  )
  port map (
    clk => clk,
    rst => rst,

    eth_rx_ready_o  => eth_rx_ready_o,
    eth_rx_packet_i => eth_rx_packet_i,

    eth_tx_ready_i  => eth_tx_ready_i,
    eth_tx_packet_o => eth_tx_packet_o,

    arp_rx_ready_o  => arp_to_eth_ready,
    arp_rx_packet_i => arp_to_eth_packet,

    arp_tx_ready_i  => eth_to_arp_ready,
    arp_tx_packet_o => eth_to_arp_packet,

    ip_rx_ready_o  => ip_to_eth_ready,
    ip_rx_packet_i => ip_to_eth_packet,

    ip_tx_ready_i  => eth_to_ip_ready,
    ip_tx_packet_o => eth_to_ip_packet,

    reco_en_o   => reco_en,
    reco_ip_o   => reco_ip,
    reco_mac_i  => reco_mac,
    reco_done_i => reco_done,

    my_mac_i => my_mac_i,

    one_ms_tick_i => one_ms_tick,

    status_vector_o => eth_status_vector
  );

  --! Instantiate the arp_module
  inst_arp_module : entity xgbe_lib.arp_module
  generic map (
    ARP_REQUEST_CYCLE => ARP_REQUEST_CYCLE,
    ARP_TIMEOUT       => ARP_TIMEOUT,
    ARP_TABLE_DEPTH   => ARP_TABLE_DEPTH
  )
  port map (
    clk => clk,
    rst => rst,

    -- signals from arp requester
    arp_rx_ready_o  => eth_to_arp_ready,
    arp_rx_packet_i => eth_to_arp_packet,

    -- signals to arp requester
    arp_tx_ready_i  => arp_to_eth_ready,
    arp_tx_packet_o => arp_to_eth_packet,

    -- interface for recovering mac address from given ip address
    reco_en_i   => reco_en,
    reco_ip_i   => reco_ip,
    reco_mac_o  => reco_mac,
    reco_done_o => reco_done,

    my_mac_i => my_mac_i,
    my_ip_i  => my_ip_i,

    one_ms_tick_i => one_ms_tick,

    status_vector_o => arp_status_vector
  );

  --! Instantiate the ip_module
  inst_ip_module : entity xgbe_lib.ip_module
  generic map (
    EOF_CHECK_EN   => EOF_CHECK_EN,
    UDP_CRC_EN     => UDP_CRC_EN,
    IP_FILTER_EN   => IP_FILTER_EN,
    ID_TABLE_DEPTH => ID_TABLE_DEPTH,
    PAUSE_LENGTH   => PAUSE_LENGTH
  )
  port map (
    clk => clk,
    rst => rst,

    ip_rx_ready_o  => eth_to_ip_ready,
    ip_rx_packet_i => eth_to_ip_packet,

    ip_tx_ready_i  => ip_to_eth_ready,
    ip_tx_packet_o => ip_to_eth_packet,

    udp_rx_ready_o  => udp_rx_ready_o,
    udp_rx_packet_i => udp_rx_packet_i,
    udp_rx_id_i     => udp_rx_id_i,

    udp_tx_ready_i  => udp_tx_ready_i,
    udp_tx_packet_o => udp_tx_packet_o,
    udp_tx_id_o     => udp_tx_id_o,

    my_ip_i      => my_ip_i,
    ip_netmask_i => ip_netmask_i,

    status_vector_o => ip_status_vector
  );

  --! Instantiate cyclic counting to generate a tick each millisecond
  inst_ms_counter : entity misc.counting
  generic map (
    COUNTER_MAX_VALUE => ONE_MILLISECOND
  )
  port map (
    clk => clk,
    rst => rst,
    en  => '1',

    cycle_done => one_ms_tick
  );

end architecture behavioral;
