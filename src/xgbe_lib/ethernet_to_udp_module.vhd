-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Ethernet to UPD module
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details
--! Watches out for incoming Ethernet packets on the ETH interface, removes
--! Ethernet and IP layer and forwards blank UDP packets to enclosed module.
--! Watches out for incoming UDP packets on the UDP interface, adds
--! Ethernet and IP layer and forwards full Ethernet packets to enclosed module.
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

    --! @brief End of packet check
    --! @details If enabled, the module counter checks the IP length indication and
    --! raises the error indicator upon eop if not matching.
    --!
    --! Also used in the ip_module.
    EOP_CHECK_EN      : std_logic                := '1';
    --! @brief The minimal number of clock cycles between two outgoing packets.
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
    --! @brief DHCP Reboot, sync with #clk
    --! @details
    --! Reboot @ref #dhcp_module "the DHCP module" (re-obtain IP-address) without full reset.
    --! The reboot described in @ref dhcp_module_reset_bahaviour "the DHCP module's reset behaviour" is done.
    --! Setting #dhcp_reboot_i to '1' causes the INIT_REBOOT, internally forming the reset signals for
    --! the #dhcp_module accordingly.
    --! #rst doesn't need to be set when rebooting, but #rst without #dhcp_reboot_i causes
    --! full reset of the DHCP module.
    dhcp_reboot_i   : in    std_logic := '0';

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
    --! DHCP enable (enabled by default)
    dhcp_en_i       : in    std_logic                     := '1';
    --! (Optional) IP address to try obtaining when using DHCP
    try_ip_i        : in    std_logic_vector(31 downto 0) := (others => '0');
    --! IP address (when using static IP address configuration)
    my_ip_i         : in    std_logic_vector(31 downto 0) := x"c0_a8_00_02";
    --! Net mask (when using static IP address configuration)
    my_ip_netmask_i : in    std_logic_vector(31 downto 0) := x"ff_ff_00_00";

    --! @}

    --! @name Actual IP configuration of the module
    --! @{

    --! IP address (obtained from DHCP or from static configuration)
    my_ip_o         : out   std_logic_vector(31 downto 0);
    --! IP subnet mask (obtained from DHCP or from static configuration)
    my_ip_netmask_o : out   std_logic_vector(31 downto 0);
    --! @brief Indicator if IP configuration (my_ip_o and my_ip_netmask_o) is valid
    --! @details Note the difference to #status_vector_o (0) which indicates the status of the DHCP module:
    --! When DHCP is disabled, #status_vector_o (0) is '0' but #my_ip_valid_o is '1' (as #my_ip_i and #my_ip_netmask_i are used).
    --! When DHCP is enabled, #status_vector_o (0) = #my_ip_valid_o, and both rise once DHCP negotiation is done.
    my_ip_valid_o   : out   std_logic;

    --! @}

    --! @brief Status of the module
    --! @details Status of the module
    --! - 33: ETH module: Interface merger: ARP is being forwarded
    --! - 32: ETH module: Interface merger: ETH is being forwarded
    --! - 31: ETH module: Interface merger: module in idle
    --! - 30: ETH module: ETH TX: Waiting for MAC address
    --! - 29: ETH module: ETH TX: IP frame is being forwarded
    --! - 28: ETH module: ETH TX: IDLE mode
    --! - 27: ETH module: RX FSM: ARP frame is being received
    --! - 26: ETH module: RX FSM:  IP frame is being received
    --! - 25: ETH module: RX FSM: IDLE mode
    --! - 24: ARP table full
    --! - 23: ARP table empty
    --! - 22: ARP request is being received
    --! - 21: ARP request is being answered
    --! - 20: ARP Data is being forwarded
    --! - 19: IP/ID table: table full
    --! - 18: IP/ID table: table empty
    --! - 17: ICMP: icmp_tx_ready_i
    --! - 16: ICMP: rx_fifo_wr_full
    --! - 15: ICMP: rx_fifo_wr_empty
    --! - 14: IP module: Interface merger: ICMP is being forwarded
    --! - 13: IP module: Interface merger: IP is being forwarded
    --! - 12: IP module: Interface merger: module in IDLE
    --! - 11: IP module: TX FSM in UDP mode (transmission ongoing)
    --! - 10: IP module: TX FSM in IDLE (transmission may still be fading out)
    --! - 9: IP module: RX FSM: UDP frame is being received
    --! - 8: IP module: RX FSM: ICMP frame is being received
    --! - 7: IP module: RX FSM: IDLE mode
    --! - 6: DHCP module: declining offered IP address
    --! - 5: DHCP module: request timeout
    --! - 4: DHCP module: discover timeout
    --! - 3: DHCP module: lease expired
    --! - 2: DHCP module: t2_expired
    --! - 1: DHCP module: t1_expired
    --! - 0: DHCP module: IP address configured (DHCP module in BOUND | RENEWING | REBINDING state)
    status_vector_o : out   std_logic_vector(33 downto 0)
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
  signal arp_to_eth_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );

  --! @}

  --! @name Avalon-ST Ethernet module to ARP module
  --! @{

  --! RX ready
  signal eth_to_arp_ready  : std_logic;
  --! RX data and controls
  signal eth_to_arp_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );

  --! @}

  --! @name Avalon-ST IP module to Ethernet module
  --! @{

  --! TX ready
  signal eth_to_ip_ready  : std_logic;
  --! TX data and controls
  signal eth_to_ip_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );

  --! @}

  --! @name Avalon-ST Ethernet module to IP module
  --! @{

  --! RX ready
  signal ip_to_eth_ready  : std_logic;
  --! RX data and controls
  signal ip_to_eth_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );

  --! @}

  --! @name Interface to integrate DHCP module between UDP RX and IP module
  --! @{

  --! TX ready of DHCP module
  signal dhcp_tx_ready  : std_logic;
  --! TX data and controls of DHCP module
  signal dhcp_tx_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );

  --! UDP RX ready of IP module
  signal udp_to_ip_ready  : std_logic;
  --! UDP RX data and controls of IP module
  signal udp_to_ip_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );

  --! TX ready of IP module
  signal udp_tx_ready_ip  : std_logic;
  --! UDP TX data and controls to IP module
  signal udp_tx_packet_ip : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );

  --! RX ready of DHCP module (for interface parallel to UDP udp_tx_packet_o interface)
  signal udp_rx_ready_dhcp : std_logic;
  --! Internal UDP RX ready: udp_rx_ready_o is not ready unless IP address is configured
  signal udp_rx_ready      : std_logic;
  --! UDP data that goes into the interface merger (from UDP module)
  signal udp_rx_packet     : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );

  --! Destination IP address of DHCP server (used when transmitting DHCP packets)
  signal dhcp_server_ip : std_logic_vector(31 downto 0);

  --! Port list for interface_splitter to identify DHCP port
  constant PORT_LIST : t_slv_vector(1 downto 1) := (1 => x"0044");

  --! @}

  --! @name Interface for recovering MAC address from given IP address
  --! @{

  --! Recovery enable to ARP module
  signal reco_en      : std_logic;
  --! IP address to recover to ARP module
  signal reco_ip      : std_logic_vector(31 downto 0);
  --! Recovery enable from ETH module
  signal reco_en_eth  : std_logic;
  --! IP address to recover from ETH module
  signal reco_ip_eth  : std_logic_vector(31 downto 0);
  --! Recovery enable from DHCP module
  signal reco_en_dhcp : std_logic;
  --! IP address to recover from DHCP module
  signal reco_ip_dhcp : std_logic_vector(31 downto 0);

  --! Recovered MAC address (MAC_BROADCAST_ADDR upon timeout)
  signal reco_mac  : std_logic_vector(47 downto 0);
  --! Recovery done indicator: 1 = found or timeout
  signal reco_done : std_logic;
  --! @}

  --! Clock cycle when 1 millisecond is passed
  signal one_ms_tick : std_logic;

  --! @name Status vectors of the internal modules
  --! @{

  --! ethernet_module
  signal eth_status_vector  : std_logic_vector(8 downto 0);
  --! arp_module
  signal arp_status_vector  : std_logic_vector(4 downto 0);
  --! ip_module
  signal ip_status_vector   : std_logic_vector(12 downto 0);
  --! dhcp_module
  signal dhcp_status_vector : std_logic_vector(6 downto 0);
  --! interface_merger
  signal im_status_vector   : std_logic_vector(2 downto 0);
--! @}

begin

  status_vector_o <= eth_status_vector & arp_status_vector & ip_status_vector & dhcp_status_vector;

  --! Instantiate the ethernet_module
  inst_ethernet_module : entity xgbe_lib.ethernet_module
  generic map (
    EOP_CHECK_EN => EOP_CHECK_EN,
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

    reco_en_o   => reco_en_eth,
    reco_ip_o   => reco_ip_eth,
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

    my_mac_i      => my_mac_i,
    my_ip_i       => my_ip_o,
    my_ip_valid_i => dhcp_status_vector(0),

    one_ms_tick_i => one_ms_tick,

    status_vector_o => arp_status_vector
  );

  --! Instantiate the ip_module
  inst_ip_module : entity xgbe_lib.ip_module
  generic map (
    EOP_CHECK_EN   => EOP_CHECK_EN,
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

    udp_rx_ready_o  => udp_to_ip_ready,
    udp_rx_packet_i => udp_to_ip_packet,
    udp_rx_id_i     => udp_rx_id_i,

    udp_tx_ready_i  => udp_tx_ready_ip,
    udp_tx_packet_o => udp_tx_packet_ip,
    udp_tx_id_o     => udp_tx_id_o,

    my_ip_i      => my_ip_o,
    ip_netmask_i => my_ip_netmask_o,

    dhcp_server_ip_i => dhcp_server_ip,

    status_vector_o => ip_status_vector
  );

  blk_dhcp : block
    --! recovery failure: 1 = not found (time out), 0 = found
    signal reco_fail : std_logic;
    --! reset of DHCP module (when using static IP configuration)
    signal dhcp_rst  : std_logic;
    --! IP address provided by DHCP module
    signal dhcp_ip   : std_logic_vector(31 downto 0);
    --! IP netmask provided by DHCP module
    signal dhcp_mask : std_logic_vector(31 downto 0);
  begin

    reco_fail <= '1' when reco_mac = x"FF_FF_FF_FF_FF_FF" else '0';

    dhcp_rst <= rst or not dhcp_en_i or dhcp_reboot_i;

    --! Instantiate the dhcp_module
    inst_dhcp_module : entity xgbe_lib.dhcp_module
    generic map (
      UDP_CRC_EN => UDP_CRC_EN
    )
    port map (
      clk    => clk,
      rst    => dhcp_rst,
      boot_i => dhcp_reboot_i,

      -- signals from dhcp requester
      dhcp_rx_ready_o  => udp_rx_ready_dhcp,
      dhcp_rx_packet_i => udp_tx_packet_o,

      -- signals to dhcp requester
      dhcp_tx_ready_i  => dhcp_tx_ready,
      dhcp_tx_packet_o => dhcp_tx_packet,
      dhcp_server_ip_o => dhcp_server_ip,

      -- interface for recovering mac address from given ip address
      reco_en_o   => reco_en_dhcp,
      reco_ip_o   => reco_ip_dhcp,
      reco_done_i => reco_done,
      reco_fail_i => reco_fail,

      my_mac_i     => my_mac_i,
      try_ip_i     => try_ip_i,
      my_ip_o      => dhcp_ip,
      ip_netmask_o => dhcp_mask,

      one_ms_tick_i => one_ms_tick,

      -- status of the DHCP module
      status_vector_o => dhcp_status_vector
    );

    --! selection of IP configuration based on dhcp_en_i
    --! this could go into concurrent statements but timing is saver this way
    proc_select_ip : process (clk)
    begin
      if rising_edge(clk) then
        if dhcp_en_i then
          my_ip_o         <= dhcp_ip;
          my_ip_netmask_o <= dhcp_mask;
          my_ip_valid_o   <= dhcp_status_vector(0);
        else
          my_ip_o         <= my_ip_i;
          my_ip_netmask_o <= my_ip_netmask_i;
          my_ip_valid_o   <= '1';
        end if;
      end if;
    end process proc_select_ip;

    -- switch recovery interface to ethernet module when not needed by dhcp module
    -- i.e. it's needed while requesting (= not while (bound (= valid IP) or declining))
    with my_ip_valid_o or dhcp_status_vector(6) select reco_en <=
      reco_en_eth when '1',
      reco_en_dhcp when others;

    with my_ip_valid_o or dhcp_status_vector(6) select reco_ip <=
      reco_ip_eth when '1',
      reco_ip_dhcp when others;

    --! Instantiate the interface_splitter to multiplex ready signals of DHCP and outer UDP
    --! @details
    --! avst_rx_packet_i and avst_tx_packet_o are identical but for consistency
    --! and better understanding of the data path, we use the connections
    inst_interface_splitter : entity xgbe_lib.interface_splitter
    generic map (
      PORT_LIST     => PORT_LIST,
      DATA_W_OFFSET => 32
    )
    port map (
      -- clk (synch reset with clk)
      clk => clk,
      rst => rst,

      -- Avalon-ST input to be multiplexed
      avst_rx_ready_o  => udp_tx_ready_ip,
      avst_rx_packet_i => udp_tx_packet_ip,

      -- Avalon-ST output interface
      avst_tx_readys_i => (0 => udp_tx_ready_i, 1 => udp_rx_ready_dhcp),
      avst_tx_packet_o => udp_tx_packet_o,

      -- status of the module
      status_vector_o => open
    );

    -- block UDP RX interface when IP address is not properly configured
    -- this allows exclusive access to the reco interface for the DHCP module during that time
    with my_ip_valid_o select udp_rx_ready_o <=
      udp_rx_ready when '1',
      '0' when others;

    with my_ip_valid_o select udp_rx_packet <=
      udp_rx_packet_i when '1',
      (valid => '0', sop => '0', eop => '0', others => (others => '-')) when others;

    --! Instantiate the interface_merger to merge reply from dhcp_module and ARP RX interface
    inst_interface_merger : entity xgbe_lib.interface_merger
    port map (
      -- clk (synch reset with clk)
      clk => clk,
      rst => rst,

      -- avalon-st from first priority module
      avst1_rx_ready_o  => dhcp_tx_ready,
      avst1_rx_packet_i => dhcp_tx_packet,

      -- avalon-st from second priority module
      avst2_rx_ready_o  => udp_rx_ready,
      avst2_rx_packet_i => udp_rx_packet,

      -- avalon-st to outer module
      avst_tx_ready_i  => udp_to_ip_ready,
      avst_tx_packet_o => udp_to_ip_packet,

      -- status of the module
      status_vector_o => im_status_vector
    );

  end block blk_dhcp;

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
