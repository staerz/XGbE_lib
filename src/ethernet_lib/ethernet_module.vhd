-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Ethernet module
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details
--! Watches out for incoming Ethernet frames and descrambles MACs,
--! forwards blank IP frames or ARP frames to enclosed modules.
-------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.numeric_std.all;
--! @endcond

--! Ethernet module
entity ethernet_module is
  generic (
    --! @brief End of frame check
    --! @details If enabled, the module counter checks the IP length indication and
    --! raises the error indicator upon eof if not matching.
    EOF_CHECK_EN  : std_logic                := '1';
    --! The minimal number of clock cycles between two outgoing frames.
    PAUSE_LENGTH  : integer range 0 to 10    := 0;
    --! Timeout to reconstruct MAC from IP in milliseconds
    MAC_TIMEOUT   : integer range 1 to 10000 := 1000
  );
  port (
    --! Clock
    clk           : in    std_logic;
    --! Reset, sync with #clk
    rst           : in    std_logic;

    --! @name Avalon-ST from ETH outside world
    --! @{

    --! RX ready
    eth_rx_ready  : out   std_logic;
    --! RX data
    eth_rx_data   : in    std_logic_vector(63 downto 0);
    --! RX controls
    eth_rx_ctrl   : in    std_logic_vector(6 downto 0);
    --! @}

    --! @name Avalon-ST to Eth outside world
    --! @{

    --! TX ready
    eth_tx_ready  : in    std_logic;
    --! TX data
    eth_tx_data   : out   std_logic_vector(63 downto 0);
    --! TX controls
    eth_tx_ctrl   : out   std_logic_vector(6 downto 0);
    --! @}

    --! @name Avalon-ST from ARP requester
    --! @{

    --! RX ready
    arp_rx_ready  : out   std_logic;
    --! RX data
    arp_rx_data   : in    std_logic_vector(63 downto 0);
    --! RX controls
    arp_rx_ctrl   : in    std_logic_vector(6 downto 0);
    --! @}

    --! @name Avalon-ST to ARP requester (with Ethernet header)
    --! @{

    --! TX ready
    arp_tx_ready  : in    std_logic;
    --! TX data
    arp_tx_data   : out   std_logic_vector(63 downto 0);
    --! TX controls
    arp_tx_ctrl   : out   std_logic_vector(6 downto 0);
    --! @}

    --! @name Avalon-ST from IP module
    --! @{

    --! RX ready
    ip_rx_ready   : out   std_logic;
    --! RX data
    ip_rx_data    : in    std_logic_vector(63 downto 0);
    --! RX controls
    ip_rx_ctrl    : in    std_logic_vector(6 downto 0);
    --! @}

    --! @name Avalon-ST to IP module
    --! @{

    --! TX ready
    ip_tx_ready   : in    std_logic;
    --! TX data
    ip_tx_data    : out   std_logic_vector(63 downto 0);
    --! TX controls
    ip_tx_ctrl    : out   std_logic_vector(6 downto 0);
    --! @}

    --! @name Interface for recovering MAC address from given IP address
    --! @{

    --! Recovery enable
    reco_en       : out   std_logic;
    --! IP address to recover
    reco_ip       : out   std_logic_vector(31 downto 0);
    --! Recovered MAC address
    reco_mac      : in    std_logic_vector(47 downto 0);
    --! Recovery success: 1 = found, 0 = not found (time out)
    reco_mac_done : in    std_logic;
    --! @}

    --! MAC address of the module
    my_mac        : in    std_logic_vector(47 downto 0);

    --! Clock cycle when 1 millisecond is passed
    one_ms_tick   : in    std_logic;

    --! @brief Status of the module
    --! @details Status of the module
    --! - 8: Interface merger: ARP is being forwarded
    --! - 7: Interface merger: ETH is being forwarded
    --! - 6: Interface merger: module in idle
    --! - 5: ETH TX: Waiting for MAC address
    --! - 4: ETH TX: IP frame is being forwarded
    --! - 3: ETH TX: IDLE mode
    --! - 2: RX FSM: ARP frame is being received
    --! - 1: RX FSM:  IP frame is being received
    --! - 0: RX FSM: IDLE mode
    status_vector : out   std_logic_vector(8 downto 0)
  );
end ethernet_module;

--! @cond
library ethernet_lib;
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
    signal eth_tx_ready_i  : std_logic;
    --! TX data
    signal eth_tx_data_i   : std_logic_vector(63 downto 0);
    --! TX controls
    signal eth_tx_ctrl_i   : std_logic_vector(6 downto 0);
    --! @}

  begin

    --! Instantiate the ethernet_header_module to construct Ethernet header from IP RX interface.
    ethernet_header_module_inst: entity ethernet_lib.ethernet_header_module
    generic map (
      EOF_CHECK_EN  => EOF_CHECK_EN,
      PAUSE_LENGTH  => PAUSE_LENGTH,
      MAC_TIMEOUT   => MAC_TIMEOUT
    )
    port map (
      -- clk (synch reset with clk)
      clk           => clk,
      rst           => rst,

      -- avalon-st from ip module
      ip_rx_ready   => ip_rx_ready,
      ip_rx_data    => ip_rx_data,
      ip_rx_ctrl    => ip_rx_ctrl,

      -- avalon-st to ethernet module
      eth_tx_ready  => eth_tx_ready_i,
      eth_tx_data   => eth_tx_data_i,
      eth_tx_ctrl   => eth_tx_ctrl_i,

      -- interface for recovering mac address from given ip address
      reco_en       => reco_en,
      reco_ip       => reco_ip,
      reco_mac      => reco_mac,
      reco_mac_done => reco_mac_done,

      -- configuration of the module
      my_mac        => my_mac,
      one_ms_tick   => one_ms_tick,

      -- status of the module
      status_vector => status_vector(5 downto 3)
    );

    --! Instantiate the interface_merger to merge reply from ethernet_header_module and ARP RX interface
    interface_merger_inst: entity ethernet_lib.interface_merger
    -- generic map (
    -- )
    port map (
      -- clk (synch reset with clk)
      clk             => clk,
      rst             => rst,

      -- avalon-st from first priority module
      avst1_rx_ready  => eth_tx_ready_i,
      avst1_rx_data   => eth_tx_data_i,
      avst1_rx_ctrl   => eth_tx_ctrl_i,

      -- avalon-st from second priority module
      avst2_rx_ready  => arp_rx_ready,
      avst2_rx_data   => arp_rx_data,
      avst2_rx_ctrl   => arp_rx_ctrl,

      -- avalon-st to outer module
      avst_tx_ready   => eth_tx_ready,
      avst_tx_data    => eth_tx_data,
      avst_tx_ctrl    => eth_tx_ctrl,

      -- status of the module
      status_vector   => status_vector(8 downto 6)
    );

  end block;

  -- receive part - ETH interface
  stripoff_header : block
    --! @brief State definition for the RX FSM
    --! @details
    --! State definition for the RX FSM
    --! - HEADER: Expecting Ethernet header
    --! - RX:     Packet forwarding
    --! - SKIP:   Skips all frames until EOF (if header is wrong)
    type t_rx_state is (HEADER, RX, SKIP);

    --! State of the RX FSM
    signal rx_state       : t_rx_state := HEADER;

    --! @name Avalon-ST rx controls (for better readability)
    --! @{

    --! Start of frame
    signal rx_sof       : std_logic;
    --! End of frame
    signal rx_eof       : std_logic;
    --! Ready
    signal rx_ready     : std_logic;
    --! @}

    --! Counter for incoming packets
    signal rx_count     : integer range 0 to 1500 := 0;

    --! @brief Enclosed protocol
    --! @details
    --! Enclosed supported protocol
    --! - NOTSUPPORTED: unsupported protocol
    --! - UDP:          UDP
    --! - ICMP:         ICMP
    type t_protocol is (NOTSUPPORTED, ARP, IP);

    --! Protocol of the incoming packet
    signal protocol : t_protocol := NOTSUPPORTED;

    --! Number of interfaces (for trailer_module)
    constant N_INTERFACES : positive := 2;

    --! RX interface selection
    signal rx_mux         : std_logic_vector(N_INTERFACES-1 downto 0);
    --! TX interface selection
    signal tx_mux         : std_logic_vector(N_INTERFACES-1 downto 0);

  begin
    -- mapping of module dependent to block specific signals
    eth_rx_ready  <= rx_ready;
    rx_sof        <= eth_rx_ctrl(5);
    rx_eof        <= eth_rx_ctrl(4);

    -- receiver is ready when data can be forwarded to the consecutive modules
    with tx_mux select rx_ready <=
      ip_tx_ready   when "01",
      arp_tx_ready  when "10",
      '1' when others;

    status_vector(2 downto 1) <= rx_mux;
    status_vector(0)          <= '1' when rx_state = HEADER else '0';

    --! @brief RX FSM to handle incoming packets
    --! @details Analyse incoming data packets and check them for IP or ARP content.
    proc_analyse_header : process (clk) is
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          rx_state <= HEADER;
          protocol <= NotSupported;
        elsif rx_ready = '1' then

          case rx_state is

            -- check header data
            when HEADER =>

              case rx_count is

                when 0 =>
                  if rx_sof = '1' then
                    -- my or broadcast mac address
                    if eth_rx_data(63 downto 16) = my_mac or eth_rx_data(63 downto 16) = MAC_BROADCAST_ADDR then
                      rx_state <= HEADER;
                    else
                      rx_state <= SKIP;
                    end if;
                  else
                    rx_state <= HEADER;
                  end if;
                when 1 =>
                  -- check protocol

                  case eth_rx_data(31 downto 16) is

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
              if rx_ready = '1' and rx_eof = '1' then
                protocol <= NOTSUPPORTED;
                rx_state <= HEADER;
              else
                rx_state <= RX;
              end if;

            -- just let pass all other data until the end of the packet
            when SKIP =>
              if rx_eof = '1' then
                rx_state <= HEADER;
              else
                rx_state <= SKIP;
              end if;

          end case;

        end if;
      end if;
    end process;

    with protocol select rx_mux <=
      "01" when IP,
      "10" when ARP,
      "00" when NOTSUPPORTED;

    make_trailer_block : block
      --! TX data for trailer_module
      signal tx_data      : std_logic_vector(63 downto 0);
      --! TX controls for trailer_module: valid & sof & eof & error & empty
      signal tx_ctrl      : std_logic_vector(6 downto 0);
    begin

      arp_tx_data <= tx_data when tx_mux = "10" else (others => '0');
      arp_tx_ctrl <= tx_ctrl when tx_mux = "10" else (others => '0');

      ip_tx_data  <= tx_data when tx_mux = "01" else (others => '0');
      ip_tx_ctrl  <= tx_ctrl when tx_mux = "01" else (others => '0');

      --! Instantiate trailer_module to make tx controls right
      trailer_inst: entity ethernet_lib.trailer_module
      generic map (
        HEADER_LENGTH => 14,
        N_INTERFACES  => N_INTERFACES
      )
      port map (
        -- clk
        clk       => clk,
        rst       => rst,

        -- avalon-st from outer module
        rx_data     => eth_rx_data,
        rx_ctrl     => eth_rx_ctrl,
        rx_mux      => rx_mux,

        rx_count    => rx_count,

        -- avalon-st to outer module
        tx_ready    => rx_ready,
        tx_data     => tx_data,
        tx_ctrl     => tx_ctrl,
        tx_mux      => tx_mux
      );

    end block;

  end block;

end behavioral;
