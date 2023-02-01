-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Ethernet module
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details
--! Watches out for incoming Ethernet packets and descrambles MACs,
--! forwards blank IP packets or ARP packets to enclosed modules.
--! @todo Introduce a packet_null constant that sets data to don't care,
--! controls to all zero.
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Ethernet module
entity ethernet_module is
  generic (
    --! @brief End of packet check
    --! @details If enabled, the module counter checks the IP length indication and
    --! raises the error indicator upon eop if not matching.
    EOP_CHECK_EN : std_logic                := '1';
    --! The minimal number of clock cycles between two outgoing packets.
    PAUSE_LENGTH : integer range 0 to 10    := 0;
    --! Timeout to reconstruct MAC from IP in milliseconds
    MAC_TIMEOUT  : integer range 1 to 10000 := 1000
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

    --! @name Avalon-ST to Eth outside world
    --! @{

    --! TX ready
    eth_tx_ready_i  : in    std_logic;
    --! TX data and controls
    eth_tx_packet_o : out   t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @name Avalon-ST from ARP requester
    --! @{

    --! RX ready
    arp_rx_ready_o  : out   std_logic;
    --! RX data and controls
    arp_rx_packet_i : in    t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @name Avalon-ST to ARP requester (with Ethernet header)
    --! @{

    --! TX ready
    arp_tx_ready_i  : in    std_logic;
    --! TX data and controls
    arp_tx_packet_o : out   t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @name Avalon-ST from IP module
    --! @{

    --! RX ready
    ip_rx_ready_o   : out   std_logic;
    --! RX data and controls
    ip_rx_packet_i  : in    t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @name Avalon-ST to IP module
    --! @{

    --! TX ready
    ip_tx_ready_i   : in    std_logic;
    --! TX data and controls
    ip_tx_packet_o  : out   t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @name Interface for recovering MAC address from given IP address
    --! @{

    --! Recovery enable
    reco_en_o       : out   std_logic;
    --! IP address to recover
    reco_ip_o       : out   std_logic_vector(31 downto 0);
    --! Recovered MAC address
    reco_mac_i      : in    std_logic_vector(47 downto 0);
    --! Recovery success: 1 = found, 0 = not found (time out)
    reco_done_i     : in    std_logic;
    --! @}

    --! MAC address of the module
    my_mac_i        : in    std_logic_vector(47 downto 0);

    --! Clock cycle when 1 millisecond is passed
    one_ms_tick_i   : in    std_logic;

    --! @brief Status of the module
    --! @details Status of the module
    --! - 8: Interface merger: ARP is being forwarded
    --! - 7: Interface merger: ETH is being forwarded
    --! - 6: Interface merger: module in idle
    --! - 5: ETH TX: Waiting for MAC address
    --! - 4: ETH TX: IP packet is being forwarded
    --! - 3: ETH TX: IDLE mode
    --! - 2: RX FSM: ARP packet is being received
    --! - 1: RX FSM:  IP packet is being received
    --! - 0: RX FSM: IDLE mode
    status_vector_o : out   std_logic_vector(8 downto 0)
  );
end entity ethernet_module;

--! @cond
library xgbe_lib;
--! @endcond

--! Implementation of the ethernet_module
architecture behavioral of ethernet_module is

  --! Broadcast MAC address
  constant MAC_BROADCAST_ADDR : std_logic_vector(47 downto 0) := (others => '1');

begin

  blk_eth_tx : block
    --! @name Intermediate interface after the Ethernet header has been added
    --! @{

    --! TX ready
    signal eth_tx_ready_r  : std_logic;
    --! RX data and controls
    signal eth_tx_packet_r : t_avst_packet(
      data(63 downto 0),
      empty(2 downto 0),
      error(0 downto 0)
    );
  --! @}
  begin

    --! Instantiate the ethernet_header_module to construct Ethernet header from IP RX interface.
    inst_ethernet_header_module : entity xgbe_lib.ethernet_header_module
    generic map (
      EOP_CHECK_EN => EOP_CHECK_EN,
      PAUSE_LENGTH => PAUSE_LENGTH,
      MAC_TIMEOUT  => MAC_TIMEOUT
    )
    port map (
      -- clk (synch reset with clk)
      clk => clk,
      rst => rst,

      -- avalon-st from ip module
      ip_rx_ready_o  => ip_rx_ready_o,
      ip_rx_packet_i => ip_rx_packet_i,

      -- avalon-st to ethernet module
      eth_tx_ready_i  => eth_tx_ready_r,
      eth_tx_packet_o => eth_tx_packet_r,

      -- interface for recovering mac address from given ip address
      reco_en_o   => reco_en_o,
      reco_ip_o   => reco_ip_o,
      reco_mac_i  => reco_mac_i,
      reco_done_i => reco_done_i,

      -- configuration of the module
      my_mac_i      => my_mac_i,
      one_ms_tick_i => one_ms_tick_i,

      -- status of the module
      status_vector_o => status_vector_o(5 downto 3)
    );

    --! Instantiate the interface_merger to merge reply from ethernet_header_module and ARP RX interface
    inst_interface_merger : entity xgbe_lib.interface_merger
    port map (
      -- clk (synch reset with clk)
      clk => clk,
      rst => rst,

      -- avalon-st from first priority module
      avst1_rx_ready_o  => eth_tx_ready_r,
      avst1_rx_packet_i => eth_tx_packet_r,

      -- avalon-st from second priority module
      avst2_rx_ready_o  => arp_rx_ready_o,
      avst2_rx_packet_i => arp_rx_packet_i,

      -- avalon-st to outer module
      avst_tx_ready_i  => eth_tx_ready_i,
      avst_tx_packet_o => eth_tx_packet_o,

      -- status of the module
      status_vector_o => status_vector_o(8 downto 6)
    );

  end block blk_eth_tx;

  -- receive part - ETH interface

  blk_stripoff_header : block
    --! @brief State definition for the RX FSM
    --! @details
    --! State definition for the RX FSM
    --! - HEADER: Expecting Ethernet header
    --! - RX:     Packet forwarding
    --! - SKIP:   Skips all packets until EOF (if header is wrong)

    type t_rx_state is (HEADER, RX, SKIP);

    --! State of the RX FSM
    signal rx_state : t_rx_state;

    --! Ready
    signal rx_ready : std_logic;

    --! Counter for incoming packets
    signal rx_count : integer range 0 to 1500;

    --! @brief Enclosed protocol
    --! @details
    --! Enclosed supported protocol
    --! - NOTSUPPORTED: unsupported protocol
    --! - UDP:          UDP
    --! - ICMP:         ICMP
    type t_protocol is (NOTSUPPORTED, ARP, IP);

    --! Protocol of the incoming packet
    signal protocol : t_protocol;

    --! Number of interfaces (for trailer_module)
    constant N_INTERFACES : positive := 2;

    --! RX interface selection
    signal rx_mux : std_logic_vector(N_INTERFACES - 1 downto 0);
    --! TX interface selection
    signal tx_mux : std_logic_vector(N_INTERFACES - 1 downto 0);
  begin

    -- mapping of module dependent to block specific signals
    eth_rx_ready_o <= rx_ready;

    -- receiver is ready when data can be forwarded to the consecutive modules
    with tx_mux select rx_ready <=
      ip_tx_ready_i   when "01",
      arp_tx_ready_i  when "10",
      '1' when others;

    status_vector_o(2 downto 1) <= rx_mux;
    status_vector_o(0)          <= '1' when rx_state = HEADER else '0';

    --! @brief RX FSM to handle incoming packets
    --! @details Analyse incoming data packets and check them for IP or ARP content.
    proc_analyse_header : process (clk)
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          rx_state <= HEADER;
          protocol <= NOTSUPPORTED;
        elsif rx_ready = '1' then

          case rx_state is

            -- check header data
            when HEADER =>

              case rx_count is

                when 0 =>
                  if eth_rx_packet_i.sop = '1' then
                    -- vsg_off if_035 if_009
                    -- my or broadcast mac address
                    if eth_rx_packet_i.data(63 downto 16) = my_mac_i or
                       eth_rx_packet_i.data(63 downto 16) = MAC_BROADCAST_ADDR
                    then
                      -- vsg_off if_035 if_009
                      rx_state <= HEADER;
                    else
                      rx_state <= SKIP;
                    end if;
                  else
                    rx_state <= HEADER;
                  end if;

                when 1 =>
                  -- check protocol

                  case eth_rx_packet_i.data(31 downto 16) is

                    when x"0806" =>
                      protocol <= ARP;
                      rx_state <= RX;

                    when x"0800" =>
                      protocol <= IP;
                      rx_state <= RX;

                    when others =>
                      protocol <= NOTSUPPORTED;
                      rx_state <= SKIP;

                  end case;

                when others =>
                  null;

              end case;

            -- stay in rx mode until the end of the packet
            when RX =>
              if rx_ready = '1' and eth_rx_packet_i.eop = '1' then
                protocol <= NOTSUPPORTED;
                rx_state <= HEADER;
              else
                rx_state <= RX;
              end if;

            -- just let pass all other data until the end of the packet
            when SKIP =>
              if eth_rx_packet_i.eop = '1' then
                rx_state <= HEADER;
              else
                rx_state <= SKIP;
              end if;

          end case;

        end if;
      end if;
    end process proc_analyse_header;

    with protocol select rx_mux <=
      "01" when IP,
      "10" when ARP,
      "00" when NOTSUPPORTED;

    blk_make_trailer : block
      --! TX data and controls for trailer_module
      signal tx_packet : t_avst_packet(
        data(63 downto 0),
        empty(2 downto 0),
        error(0 downto 0)
      );
    begin

      arp_tx_packet_o <=
        tx_packet when tx_mux = "10" else
        (data => (others => '-'), error => (others => '0'), empty => (others => '0'), others => '0');

      ip_tx_packet_o <=
        tx_packet when tx_mux = "01" else
        (data => (others => '-'), error => (others => '0'), empty => (others => '0'), others => '0');

      --! Instantiate trailer_module to make tx controls right
      inst_trailer : entity xgbe_lib.trailer_module
      generic map (
        HEADER_LENGTH => 14,
        N_INTERFACES  => N_INTERFACES
      )
      port map (
        -- clk
        clk => clk,
        rst => rst,

        -- avalon-st from outer module
        rx_packet_i => eth_rx_packet_i,
        rx_mux_i    => rx_mux,

        rx_count_o => rx_count,

        -- avalon-st to outer module
        tx_ready_i  => rx_ready,
        tx_packet_o => tx_packet,
        tx_mux_o    => tx_mux
      );

    end block blk_make_trailer;

  end block blk_stripoff_header;

end architecture behavioral;
