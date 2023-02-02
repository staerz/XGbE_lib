-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief IP module
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details
--! Creates/descrambles the IP header from/to a UDP packet.
--!
--! Only IPv4 with header length of 20 bytes is supported.
--!
--! Some further limitations for a slim implementation apply to the IP RX path:
--! - No check of the IP length field is done.
--! - No check of the IP checksum field is done.
--! - Hence no consistency check of the eop delimiter is done.
--! @todo Introduce a packet_null constant that sets data to don't care,
--! controls to all zero.
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! IP module
entity ip_module is
  generic (
    --! @brief End of packet check
    --! @details If enabled, the module counter checks the UDP length indication and
    --! raises the error indicator upon eop if not matching.
    EOP_CHECK_EN   : std_logic               := '1';
    --! @brief Post-UDP-module UDP CRC calculation
    --! @details If enabled, the UDP check sum will be (re)calculated from the UDP
    --! pseudo header.
    --! This requires the check sum over the UDP data already being present in the
    --! UDP CRC field.
    --! If disabled, the check sum is omitted and set to x"0000".
    UDP_CRC_EN     : boolean                 := true;
    --! @brief Enable IP address filtering
    --! @details If enabled, only packets arriving from IP addresses of the same
    --! network (specified by ip_netmask_i) as ip_scr_addr are accepted.
    IP_FILTER_EN   : std_logic               := '1';
    --! Depth of table (number of stored connections)
    ID_TABLE_DEPTH : integer range 1 to 1024 := 4;
    --! The minimal number of clock cycles between two outgoing packets.
    PAUSE_LENGTH   : integer range 0 to 10   := 2
  );
  port (
    --! Clock
    clk              : in    std_logic;
    --! Reset, sync with #clk
    rst              : in    std_logic;

    --! @name Avalon-ST from IP module
    --! @{

    --! RX ready
    ip_rx_ready_o    : out   std_logic;
    --! RX data and controls
    ip_rx_packet_i   : in    t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @name Avalon-ST to IP module
    --! @{

    --! TX ready
    ip_tx_ready_i    : in    std_logic;
    --! TX data and controls
    ip_tx_packet_o   : out   t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @name Avalon-ST from UDP module
    --! @{

    --! RX ready
    udp_rx_ready_o   : out   std_logic;
    --! RX data and controls
    udp_rx_packet_i  : in    t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! RX packet ID (to restore IP address)
    udp_rx_id_i      : in    std_logic_vector(15 downto 0);
    --! @}

    --! @name Avalon-ST to UDP module
    --! @{

    --! TX ready
    udp_tx_ready_i   : in    std_logic;
    --! TX data and controls
    udp_tx_packet_o  : out   t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! TX packet ID (to restore IP address)
    udp_tx_id_o      : out   std_logic_vector(15 downto 0);
    --! @}

    --! @name Configuration of the module
    --! @{

    --! IP address
    my_ip_i          : in    std_logic_vector(31 downto 0);
    --! IP subnet mask
    ip_netmask_i     : in    std_logic_vector(31 downto 0) := x"ff_ff_ff_00";
    --! @}

    --! Destination IP address of DHCP server (used when transmitting DHCP packets)
    dhcp_server_ip_i : in    std_logic_vector(31 downto 0);

    --! @brief Status of the module
    --! @details Status of the module
    --! - 12: IP/ID table: table full
    --! - 11: IP/ID table: table empty
    --! - 10: ICMP: icmp_tx_ready
    --! - 9: ICMP: rx_fifo_wr_full
    --! - 8: ICMP: rx_fifo_wr_empty
    --! - 7: Interface merger: ICMP is being forwarded
    --! - 6: Interface merger: IP is being forwarded
    --! - 5: Interface merger: module in IDLE
    --! - 4: TX FSM in UDP mode (transmission ongoing)
    --! - 3: TX FSM in IDLE (transmission may still be fading out)
    --! - 2: RX FSM: UDP packet is being received
    --! - 1: RX FSM: ICMP packet is being received
    --! - 0: RX FSM: IDLE mode
    status_vector_o  : out   std_logic_vector(12 downto 0)
  );
end entity ip_module;

--! @cond
library xgbe_lib;
--! @endcond

--! Implementation of the IP module
architecture behavioral of ip_module is

  --! Broadcast IP address
  signal ip_broadcast_addr : std_logic_vector(31 downto 0);
  --! Flag if incoming IP packet is an ICMP request
  signal icmp_request      : std_logic;

  --! @name Signals treating the udp id/ip table
  --! @{

  --! Recovery enable
  signal reco_en       : std_logic;
  --! Recovery success indicator
  signal reco_ip_found : std_logic;
  --! Recovered IP address
  signal reco_ip       : std_logic_vector(31 downto 0);
  --! @}

  --! @name Avalon-ST for ICMP module
  --! @{

  --! TX ready
  signal icmp_tx_ready  : std_logic;
  --! TX data and controls
  signal icmp_tx_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );
--! @}

begin

  -- address calculated from self configuration and ip_netmask_i
  -- in tx if destination cannot be resolved
  ip_broadcast_addr <= my_ip_i or not ip_netmask_i;

  -- IP transmitter interface
  blk_ip_tx : block
    --! @name Intermediate Avalon-ST after the IP header has been added
    --! @{

    --! TX ready
    signal ip_tx_ready_r  : std_logic;
    --! TX data and controls
    signal ip_tx_packet_r : t_avst_packet(
      data(63 downto 0),
      empty(2 downto 0),
      error(0 downto 0)
    );
  --! @}
  begin

    --! Instantiate the ip_header_module to generate header for incoming UPD packets
    inst_ip_header_module : entity xgbe_lib.ip_header_module
    generic map (
      EOP_CHECK_EN => EOP_CHECK_EN,
      UDP_CRC_EN   => UDP_CRC_EN,
      PAUSE_LENGTH => PAUSE_LENGTH
    )
    port map (
      clk => clk,
      rst => rst,

      -- avalon-st from udp module
      udp_rx_ready_o   => udp_rx_ready_o,
      udp_rx_packet_i  => udp_rx_packet_i,
      dhcp_server_ip_i => dhcp_server_ip_i,

      -- avalon-st to ip module
      ip_tx_ready_i  => ip_tx_ready_r,
      ip_tx_packet_o => ip_tx_packet_r,

      -- signals for building the header
      reco_en_o       => reco_en,
      reco_ip_found_i => reco_ip_found,
      reco_ip_i       => reco_ip,

      -- configuration of the module
      my_ip_i      => my_ip_i,
      ip_netmask_i => ip_netmask_i,

      -- status of the module
      status_vector_o => status_vector_o(4 downto 3)
    );

    --! Instantiate the interface_merger to merge TX of ip_header_module and icmp_module
    inst_interface_merger : entity xgbe_lib.interface_merger
    port map (
      -- clk (synch reset with clk)
      clk => clk,
      rst => rst,

      -- avalon-st from first priority module
      avst1_rx_ready_o  => ip_tx_ready_r,
      avst1_rx_packet_i => ip_tx_packet_r,

      -- avalon-st from second priority module
      avst2_rx_ready_o  => icmp_tx_ready,
      avst2_rx_packet_i => icmp_tx_packet,

      -- avalon-st to outer module
      avst_tx_ready_i  => ip_tx_ready_i,
      avst_tx_packet_o => ip_tx_packet_o,

      -- status of the module, see definitions below
      status_vector_o => status_vector_o(7 downto 5)
    );

  end block blk_ip_tx;

  -- receive part - IP interface

  blk_stripoff_header : block
    --! @brief State definition for the RX FSM
    --! @details
    --! State definition for the RX FSM
    --! - HEADER: Expecting IP header
    --! - RX:     Packet forwarding
    --! - SKIP:   Skips all packets until EOF (if header is wrong)

    type t_rx_state is (HEADER, RX, SKIP);

    --! State of the RX FSM

    -- vsg_disable_next_line signal_007
    signal rx_state : t_rx_state := HEADER;

    --! Ready
    signal rx_ready : std_logic;

    --! Counter for incoming packets
    signal rx_count : integer range 0 to 1500;

    --! Indicator if source IP address is accepted (passing netmask filter)
    signal src_ip_accept : std_logic;

    --! @brief Enclosed protocol
    --! @details
    --! Enclosed supported protocol
    --! - NOTSUPPORTED: unsupported protocol
    --! - UDP:          UDP
    --! - ICMP:         ICMP
    type t_protocol is (NOTSUPPORTED, UDP, ICMP);

    --! Protocol of the incoming packet

    -- vsg_disable_next_line signal_007
    signal protocol : t_protocol := NOTSUPPORTED;

    --! Ready signal of the icmp_module
    signal icmp_in_ready : std_logic;

    --! Number of interfaces (for trailer_module)
    constant N_INTERFACES : positive := 2;

    --! RX interface selection
    signal rx_mux : std_logic_vector(N_INTERFACES - 1 downto 0);
    --! TX interface selection
    signal tx_mux : std_logic_vector(N_INTERFACES - 1 downto 0);

    --! ID for storing in the UDP-ID/IP table
    signal udp_tx_id_r : unsigned(15 downto 0);
  begin

    -- mapping of module dependent to block specific signals
    ip_rx_ready_o <= rx_ready;

    -- receiver is ready when data can be forwarded to the consecutive modules
    with tx_mux select rx_ready <=
      udp_tx_ready_i  when "10",
      icmp_in_ready when "01",
      '1' when others;

    status_vector_o(2 downto 1) <= rx_mux;
    status_vector_o(0)          <= '1' when rx_state = HEADER else '0';

    --! @brief RX FSM to handle IP requests
    --! @details Analyse incoming data packets and check them for UDP content.
    --! @todo If other header length than 20 was supported, watch out for
    --! eventual displacement of data words and adjust the trailer respectively.
    --! That would require the trailer module to be configurable on the fly
    --! and is hence a new approach!
    --! An option would be to have a second trailer modules instantiated for IPv6.
    proc_analyse_header : process (clk)
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          rx_state     <= HEADER;
          protocol     <= NOTSUPPORTED;
          icmp_request <= '0';
        elsif rx_ready = '1' then

          case rx_state is

            -- check header data
            when HEADER =>

              case rx_count is

                when 0 =>
                  if ip_rx_packet_i.sop = '1' then
                    -- version 4, 20 bytes header and no more fragments
                    if ip_rx_packet_i.data(63 downto 56) = x"45" and ip_rx_packet_i.data(13) = '0' then
                      rx_state <= HEADER;
                    else
                      rx_state <= SKIP;
                    end if;
                  else
                    rx_state <= HEADER;
                  end if;

                when 1 =>
                  -- check protocol and retrieve source address as potential
                  -- destination address for tx path

                  case ip_rx_packet_i.data(55 downto 48) is

                    when x"11" =>
                      protocol <= UDP;
                      rx_state <= HEADER;

                    when x"01" =>
                      protocol <= ICMP;
                      rx_state <= HEADER;

                    when others =>
                      rx_state <= SKIP;

                  end case;

                when 2 =>
                  -- apply IP address filter
                  if (ip_rx_packet_i.data(63 downto 32) = my_ip_i or
                      ip_rx_packet_i.data(63 downto 32) = ip_broadcast_addr) and src_ip_accept = '1'
                     then

                    case protocol is

                      when NOTSUPPORTED =>
                        rx_state <= SKIP;

                      when others =>
                        rx_state <= RX;

                    end case;

                    -- check icmp packet for "request"
                    if protocol = ICMP and ip_rx_packet_i.data(31 downto 24) = x"08" then
                      icmp_request <= '1';
                    else
                      icmp_request <= '0';
                    end if;
                  else
                    rx_state <= SKIP;
                  end if;

                when others =>
                  null;

              end case;

            -- stay in rx mode until the end of the packet
            when RX =>
              if ip_rx_packet_i.eop = '1' then
                icmp_request <= '0';
                protocol     <= NOTSUPPORTED;
                rx_state     <= HEADER;
              else
                rx_state <= RX;
              end if;

            -- just let pass all other data until the end of the packet
            when SKIP =>
              if ip_rx_packet_i.eop = '1' then
                icmp_request <= '0';
                protocol     <= NOTSUPPORTED;
                rx_state     <= HEADER;
              else
                rx_state <= skip;
              end if;

          end case;

        end if;
      end if;
    end process proc_analyse_header;

    with protocol select rx_mux <=
      "10" when UDP,
      "01" when ICMP,
      "00" when NOTSUPPORTED;

    --! Instantiate the icmp_module to treat ICMP requests
    inst_icmp : entity xgbe_lib.icmp_module
    port map (
      -- clk
      clk => clk,
      rst => rst,

      -- avalon-st to fill fifo
      ip_rx_ready_o  => icmp_in_ready,
      ip_rx_packet_i => ip_rx_packet_i,

      -- indication of being ICMP request
      is_icmp_request_i => icmp_request,

      -- avalon-st to empty FIFO
      icmp_tx_ready_i  => icmp_tx_ready,
      icmp_tx_packet_o => icmp_tx_packet,

      status_vector_o => status_vector_o(10 downto 8)
    );

    blk_make_trailer : block
      --! TX data and controls for trailer_module
      signal tx_packet : t_avst_packet(
        data(63 downto 0),
        empty(2 downto 0),
        error(0 downto 0)
      );
    begin

      udp_tx_packet_o <=
        tx_packet when tx_mux = "10" and src_ip_accept = '1' else
        (data => (others => '-'), error => (others => '0'), empty => (others => '0'), others => '0');

      udp_tx_id_o <=
        std_logic_vector(udp_tx_id_r) when tx_mux = "10" and src_ip_accept = '1' and tx_packet.valid = '1' else
        (others => '0');

      --! Instantiate trailer_module to make tx controls right
      inst_trailer : entity xgbe_lib.trailer_module
      generic map (
        HEADER_LENGTH => 20,
        N_INTERFACES  => N_INTERFACES
      )
      port map (
        -- clk
        clk => clk,
        rst => rst,

        -- avalon-st from outer module
        rx_packet_i => ip_rx_packet_i,
        rx_mux_i    => rx_mux,

        rx_count_o => rx_count,

        -- avalon-st to outer module
        tx_ready_i  => rx_ready,
        tx_packet_o => tx_packet,
        tx_mux_o    => tx_mux
      );

    end block blk_make_trailer;

    blk_make_ip_udp_table : block
      --! @name Signals for the discovery interface of the udp/ip table
      --! @{

      --! Flag if discovery is being made
      signal make_disco : std_logic;
      --! Discovery write enable
      signal disco_wren : std_logic;
      --! Discovery identifier
      signal disco_id   : std_logic_vector(15 downto 0);
      --! Discovery IP address
      signal disco_ip   : std_logic_vector(31 downto 0);
      --! UDP RX ID to be recovered
      signal udp_rx_id  : std_logic_vector(15 downto 0);
    --! @}
    begin

      gen_without_ip_filter : if IP_FILTER_EN = '0' generate

        -- no IP filter: accept any IP address
        src_ip_accept <= '1';

        --! Store source IP address as disco_ip independently of IP filter
        proc_disco_ip_no_filter : process (clk)
        begin
          if rising_edge(clk) then
            -- Default: just keep storing the discovered IP address
            disco_ip <= disco_ip;
            if (rst = '1') then
              disco_ip <= (others => '0');
            elsif rx_ready = '1' then
              if rx_state = header and rx_count = 1 then
                disco_ip <= ip_rx_packet_i.data(31 downto 0);
              end if;
            end if;
          end if;
        end process proc_disco_ip_no_filter;

      end generate gen_without_ip_filter;

      -- else:

      gen_with_ip_filter : if IP_FILTER_EN = '1' generate

        --! Store source IP address as disco_ip only if IP filter passed
        proc_disco_ip_filter : process (clk)
        begin
          if rising_edge(clk) then
            -- Defaults: keep storing recovered info
            src_ip_accept <= src_ip_accept;
            disco_ip      <= disco_ip;

            if rst = '1' then
              src_ip_accept <= '0';
              disco_ip      <= (others => '0');
            elsif rx_ready = '1' then
              if rx_state = header and rx_count = 1 then
                -- Check weather source address ('ip_rx_packet_i.data(31 downto 0)')
                -- is in the same network as the core address ('my_ip_i')
                if ((not(my_ip_i xor ip_rx_packet_i.data(31 downto 0))) and ip_netmask_i) = ip_netmask_i then
                  src_ip_accept <= '1';
                  disco_ip      <= ip_rx_packet_i.data(31 downto 0);
                else
                  src_ip_accept <= '0';
                end if;
              end if;
            end if;
          end if;
        end process proc_disco_ip_filter;

      end generate gen_with_ip_filter;

      --! @brief Generate an ID counter for each incoming package
      --! @details For each package the ID is increased with each start of packet.
      --! The ID is used for port_io_table and forwarded to the udp_module.
      --! @todo Test if the overflow is needed/useful: It looks like we could simply always
      --! increase, udp_tx_id_r'left seems to actually half the available addresses.
      proc_gen_id_counter : process (clk)
      begin
        if rising_edge(clk) then
          -- Default: keep current id in memory, nothing to discover
          udp_tx_id_r <= udp_tx_id_r;
          make_disco  <= '0';

          if rst = '1' then
            -- Reset brings the id back to 0
            udp_tx_id_r <= (others => '0');
          -- Valid updates are only on ready signal
          -- Once protocol matches (but tx to udp is just not yet started):
          elsif rx_ready = '1' and protocol = UDP and rx_count = 2 and src_ip_accept = '1' then
            -- Increase the ID, so 1 is the actual first possible ID as the ID is
            -- 'discovered' only at the 3rd clock cycle of the incoming packet
            if udp_tx_id_r(udp_tx_id_r'left) = '1' then
              -- Watch overflow: if table is already filled, use 1 as the first id, not 0
              udp_tx_id_r <= to_unsigned(1, udp_tx_id_r'length);
            else
              udp_tx_id_r <= udp_tx_id_r + 1;
            end if;
            make_disco <= '1';
          end if;
        end if;
      end process proc_gen_id_counter;

      --! @brief Store pair of the ID and IP address
      --! @details Storage of discovered IP and ID is indicated by by make_disco
      --! @todo Can't this be combined with proc_gen_id_counter?
      proc_store_ip_id_relation : process (clk)
      begin
        if rising_edge(clk) then
          -- default: don't care for disco_id and don't write
          disco_id   <= (others => '-');
          disco_wren <= '0';
          -- store if indicated (and not in reset)
          if rst = '0' and make_disco = '1' then
            disco_id   <= std_logic_vector(udp_tx_id_r);
            disco_wren <= '1';
          end if;
        end if;
      end process proc_store_ip_id_relation;

      --! Account for 1 cycle clock delay from ip_header_module for generating reco_en
      proc_udp_rx_id : process (clk)
      begin
        if rising_edge(clk) then
          udp_rx_id <= udp_rx_id_i;
        end if;
      end process proc_udp_rx_id;

      --! Instantiate port_io_table to store pair of discovered IP and package ID
      inst_id_ip_table : entity xgbe_lib.port_io_table
      generic map (
        PORT_I_W    => 16,
        PORT_O_W    => 32,
        TABLE_DEPTH => ID_TABLE_DEPTH
      )
      port map (
        clk => clk,
        rst => rst,

        -- Discovery interface for writing pair of associated addresses/ports
        disco_wren_i => disco_wren,
        disco_port_i => disco_id,
        disco_port_o => disco_ip,

        -- Recovery interface for reading pair of associated addresses/ports
        reco_en_i    => reco_en,
        reco_port_i  => udp_rx_id,
        reco_found_o => reco_ip_found,
        reco_port_o  => reco_ip,

        -- Status of the module
        status_vector_o => status_vector_o(12 downto 11)
      );

    end block blk_make_ip_udp_table;

  end block blk_stripoff_header;

end architecture behavioral;
