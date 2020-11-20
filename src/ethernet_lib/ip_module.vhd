-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief IP module
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details
--! Creates/descrambles the IP header from/to a UDP frame.
--!
--! Only IPv4 with header length of 20 bytes is supported.
-------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.STD_LOGIC_1164.all;
--! @endcond

--! IP module
entity ip_module is
  generic (
    --! @brief End of frame check
    --! @details If enabled, the module counter checks the UDP length indication and
    --! raises the error indicator upon eof if not matching.
    EOF_CHECK_EN   : std_logic               := '1';
    --! @brief Post-UDP-module UDP CRC calculation
    --! @details If enabled, the UDP check sum will be (re)calculated from the pseudo
    --! header.
    --! This requires the check sum over the UDP data already being present in the
    --! UDP CRC field.
    --! If disabled, the check sum is omitted and set to x"0000".
    UDP_CRC_EN     : boolean                 := true;
    --! @brief Enable IP address filtering
    --! @details If enabled, only packets arriving from IP addresses of the same
    --! network (specified by ip_netmask) as ip_scr_addr are accepted.
    IP_FILTER_EN   : std_logic               := '1';
    --! Depth of table (number of stored connections)
    ID_TABLE_DEPTH : integer range 1 to 1024 := 4;
    --! The minimal number of clock cycles between two outgoing frames.
    PAUSE_LENGTH   : integer range 0 to 10   := 2
  );
  port (
    --! Clock
    clk           : in    std_logic;
    --! Reset, sync with #clk
    rst           : in    std_logic;

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

    --! @name Avalon-ST from UDP module
    --! @{

    --! RX ready
    udp_rx_ready  : out   std_logic;
    --! RX data
    udp_rx_data   : in    std_logic_vector(63 downto 0);
    --! RX controls
    udp_rx_ctrl   : in    std_logic_vector(6 downto 0);
    --! RX packet ID (to restore IP address)
    udp_rx_id     : in    std_logic_vector(15 downto 0);
    --! @}

    --! @name Avalon-ST to UDP module
    --! @{

    --! TX ready
    udp_tx_ready  : in    std_logic;
    --! TX data
    udp_tx_data   : out   std_logic_vector(63 downto 0);
    --! TX controls
    udp_tx_ctrl   : out   std_logic_vector(6 downto 0);
    --! TX packet ID (to restore IP address)
    udp_tx_id     : out   std_logic_vector(15 downto 0);
    --! @}

    --! @name Configuration of the module
    --! @{

    --! IP address
    my_ip         : in    std_logic_vector(31 downto 0);
    --! Net mask
    ip_netmask    : in    std_logic_vector(31 downto 0) := x"ff_ff_ff_00";
    --! @}

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
    --! - 2: RX FSM: UDP frame is being received
    --! - 1: RX FSM: ICMP frame is being received
    --! - 0: RX FSM: IDLE mode
    status_vector : out   std_logic_vector(12 downto 0)
  );
end ip_module;

--! @cond
library ethernet_lib;
library ieee;
  use ieee.numeric_std.all;
--! @endcond

--! Implementation of the IP module
architecture behavioral of ip_module is

  --! Broadcast IP address
  signal ip_broadcast_addr  : std_logic_vector(31 downto 0);
  --! Flag if incoming IP packet is an ICMP request
  signal icmp_request       : std_logic;

  --! @name Signals treating the udp id/ip table
  --! @{

  --! Recovery enable
  signal reco_en        : std_logic;
  --! Recovery success indicator
  signal reco_ip_found  : std_logic;
  --! Recovered IP address
  signal reco_ip        : std_logic_vector(31 downto 0);
  --! @}

  --! @name Avalon-ST for ICMP module
  --! @{

  --! TX ready
  signal icmp_tx_ready_i  : std_logic;
  --! TX data
  signal icmp_tx_data_i   : std_logic_vector(63 downto 0);
  --! TX controls
  signal icmp_tx_ctrl_i   : std_logic_vector(6 downto 0);
  --! @}

begin

  -- address calculated from self configuration and ip_netmask
  -- in tx if destination cannot be resolved
  ip_broadcast_addr <= my_ip or not ip_netmask;

  -- IP transmitter interface
  gen_ip_tx : block
    --! @name Intermediate Avalon-ST after the IP header has been added
    --! @{

    --! TX ready
    signal ip_tx_ready_i  : std_logic;
    --! TX data
    signal ip_tx_data_i   : std_logic_vector(63 downto 0);
    --! TX controls
    signal ip_tx_ctrl_i   : std_logic_vector(6 downto 0);
    --! @}
  begin

    --! Instantiate the ip_header_module to generate header for incoming UPD frames
    ip_header_module_inst : entity ethernet_lib.ip_header_module
    generic map (
      EOF_CHECK_EN  => EOF_CHECK_EN,
      UDP_CRC_EN    => UDP_CRC_EN,
      PAUSE_LENGTH  => PAUSE_LENGTH
    )
    port map (
      clk           => clk,
      rst           => rst,

      -- avalon-st from udp module
      udp_rx_ready  => udp_rx_ready,
      udp_rx_data   => udp_rx_data,
      udp_rx_ctrl   => udp_rx_ctrl,

      -- avalon-st to ip module
      ip_tx_ready   => ip_tx_ready_i,
      ip_tx_data    => ip_tx_data_i,
      ip_tx_ctrl    => ip_tx_ctrl_i,

      -- signals for building the header
      reco_en       => reco_en,
      reco_ip_found => reco_ip_found,
      reco_ip       => reco_ip,

      -- configuration of the module
      my_ip         => my_ip,
      ip_netmask    => ip_netmask,

      -- status of the module
      status_vector => status_vector(4 downto 3)
    );

    --! Instantiate the interface_merger to merge TX of ip_header_module and icmp_module
    interface_merger_inst: entity ethernet_lib.interface_merger
    port map (
      -- clk (synch reset with clk)
      clk             => clk,
      rst             => rst,

      -- avalon-st from first priority module
      avst1_rx_ready  => ip_tx_ready_i,
      avst1_rx_data   => ip_tx_data_i,
      avst1_rx_ctrl   => ip_tx_ctrl_i,

      -- avalon-st from second priority module
      avst2_rx_ready  => icmp_tx_ready_i,
      avst2_rx_data   => icmp_tx_data_i,
      avst2_rx_ctrl   => icmp_tx_ctrl_i,

      -- avalon-st to outer module
      avst_tx_ready   => ip_tx_ready,
      avst_tx_data    => ip_tx_data,
      avst_tx_ctrl    => ip_tx_ctrl,

      -- status of the module, see definitions below
      status_vector   => status_vector(7 downto 5)
    );

  end block;

  -- receive part - IP interface
  stripoff_header : block
    --! @brief State definition for the RX FSM
    --! @details
    --! State definition for the RX FSM
    --! - HEADER: Expecting IP header
    --! - RX:     Packet forwarding
    --! - SKIP:   Skips all frames until EOF (if header is wrong)
    type t_rx_state is (HEADER, RX, SKIP);

    --! State of the RX FSM
    signal rx_state : t_rx_state := HEADER;

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

    --! Indicator if source IP address is accepted (passing netmask filter)
    signal src_ip_accept    : std_logic;

    --! @brief Enclosed protocol
    --! @details
    --! Enclosed supported protocol
    --! - NOTSUPPORTED: unsupported protocol
    --! - UDP:          UDP
    --! - ICMP:         ICMP
    type t_protocol is (NOTSUPPORTED, UDP, ICMP);

    --! Protocol of the incoming packet
    signal protocol : t_protocol := NOTSUPPORTED;

    --! Ready signal of the icmp_module
    signal icmp_in_ready    : std_logic;

    --! Number of interfaces (for trailer_module)
    constant N_INTERFACES_I : positive := 2;

    --! RX interface selection
    signal rx_mux         : std_logic_vector(N_INTERFACES_I-1 downto 0);
    --! TX interface selection
    signal tx_mux         : std_logic_vector(N_INTERFACES_I-1 downto 0);

    --! ID for storing in the UDP-ID/IP table
    signal udp_tx_id_i    : unsigned(15 downto 0);

  begin
    -- mapping of module dependent to block specific signals
    ip_rx_ready <= rx_ready;
    rx_sof      <= ip_rx_ctrl(5);
    rx_eof      <= ip_rx_ctrl(4);

    -- receiver is ready when data can be forwarded to the consecutive modules
    with tx_mux select rx_ready <=
      udp_tx_ready  when "10",
      icmp_in_ready when "01",
      '1' when others;

    status_vector(2 downto 1) <= rx_mux;
    status_vector(0)          <= '1' when rx_state = HEADER else '0';

    --! @brief RX FSM to handle IP requests
    --! @details Analyse incoming data packets and check them for UDP content.
    --! @todo If other header length than 20 was supported, watch out for
    --! eventual displacement of data words and adjust the trailer respectively.
    --! That would require the trailer module to be configurable on the fly
    --! and is hence a new approach!
    --! An option would be to have a second trailer modules instantiated for IPv6.
    proc_analyse_header : process (clk) is
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
                  if rx_sof = '1' then
                    -- version 4, 20 bytes header and no more fragments
                    if ip_rx_data(63 downto 56) = x"45" and ip_rx_data(13) = '0' then
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

                  case ip_rx_data(55 downto 48) is

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
                  if (ip_rx_data(63 downto 32) = my_ip or ip_rx_data(63 downto 32) = ip_broadcast_addr) and src_ip_accept = '1' then

                    case protocol is

                      when NOTSUPPORTED =>
                        rx_state <= skip;
                      when others =>
                        rx_state <= rx;

                    end case;

                    -- check icmp packet for "request"
                    if protocol = ICMP and ip_rx_data(31 downto 24) = x"08" then
                      icmp_request <= '1';
                    else
                      icmp_request <= '0';
                    end if;
                  else
                    rx_state <= skip;
                  end if;
                when others =>
                  null;

              end case;

            -- stay in rx mode until the end of the packet
            when RX =>
              if rx_eof = '1' then
                icmp_request <= '0';
                protocol     <= NOTSUPPORTED;
                rx_state     <= HEADER;
              else
                rx_state <= RX;
              end if;

            -- just let pass all other data until the end of the packet
            when SKIP =>
              if rx_eof = '1' then
                icmp_request <= '0';
                protocol     <= NOTSUPPORTED;
                rx_state     <= HEADER;
              else
                rx_state <= skip;
              end if;

          end case;

        end if;
      end if;
    end process;

    with protocol select rx_mux <=
      "10" when UDP,
      "01" when ICMP,
      "00" when NOTSUPPORTED;

    --! Instantiate the icmp_module to treat ICMP requests
    icmp_inst : entity ethernet_lib.icmp_module
    port map (
      -- clk
      clk             => clk,
      rst             => rst,

      -- avalon-st to fill fifo
      ip_rx_ready     => icmp_in_ready,
      ip_rx_data      => ip_rx_data,
      ip_rx_ctrl      => ip_rx_ctrl,

      -- indication of being ICMP request
      is_icmp_request => icmp_request,

      -- avalon-st to empty FIFO
      icmp_out_ready  => icmp_tx_ready_i,
      icmp_out_data   => icmp_tx_data_i,
      icmp_out_ctrl   => icmp_tx_ctrl_i,

      status_vector   => status_vector(10 downto 8)
    );

    make_trailer_block : block
      --! TX data for trailer_module
      signal tx_data      : std_logic_vector(63 downto 0);
      --! TX controls for trailer_module: valid & sof & eof & error & empty
      signal tx_ctrl      : std_logic_vector(6 downto 0);
    begin
      udp_tx_data <= tx_data when tx_mux = "10" and src_ip_accept = '1' else (others => '0');
      udp_tx_ctrl <= tx_ctrl when tx_mux = "10" and src_ip_accept = '1' else (others => '0');

      udp_tx_id <= std_logic_vector(udp_tx_id_i) when tx_mux = "10" and src_ip_accept = '1' and tx_ctrl(6) = '1' else (others => '0');

      --! Instantiate trailer_module to make tx controls right
      trailer_inst : entity ethernet_lib.trailer_module
      generic map (
        HEADER_LENGTH => 20,
        N_INTERFACES  => N_INTERFACES_I
      )
      port map (
        -- clk
        clk       => clk,
        rst       => rst,

        -- avalon-st from outer module
        rx_data     => ip_rx_data,
        rx_ctrl     => ip_rx_ctrl,
        rx_mux      => rx_mux,

        rx_count    => rx_count,

        -- avalon-st to outer module
        tx_ready    => rx_ready,
        tx_data     => tx_data,
        tx_ctrl     => tx_ctrl,
        tx_mux      => tx_mux
      );

    end block;

    make_ip_udp_table: block
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
      --! @}

    begin

      gen_without_ip_filter : if IP_FILTER_EN = '0' generate

        -- no IP filter: accept any IP address
        src_ip_accept <= '1';

        --! Store source IP address as disco_ip independently of IP filter
        proc_disco_ip_no_filter : process (clk) is
        begin
          if rising_edge(clk) then
            -- Default: just keep storing the discovered IP address
            disco_ip <= disco_ip;
            if (rst = '1') then
              disco_ip <= (others => '0');
            elsif rx_ready = '1' then
              if rx_state = header and rx_count = 1 then
                disco_ip <= ip_rx_data(31 downto 0);
              end if;
            end if;
          end if;
        end process;

      end generate;

      -- else:

      gen_with_ip_filter : if IP_FILTER_EN = '1' generate

        --! Store source IP address as disco_ip only if IP filter passed
        proc_disco_ip_filter : process (clk) is
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
                -- Check weather source address ('ip_rx_data(31 downto 0)')
                -- is in the same network as the core address ('my_ip')
                if ((not(my_ip xor ip_rx_data(31 downto 0))) and ip_netmask) = ip_netmask then
                  src_ip_accept <= '1';
                  disco_ip      <= ip_rx_data(31 downto 0);
                else
                  src_ip_accept <= '0';
                end if;
              end if;
            end if;
          end if;
        end process;

      end generate;

      --! @brief Generate an ID counter for each incoming package
      --! @details For each package the ID is increased with each start of frame.
      --! The ID is used for port_io_table and forwarded to the udp_module.
      --! @todo Test if the overflow is needed/useful: It looks like we could simply always
      --! increase, udp_tx_id_i'left seems to actually half the available addresses.
      proc_gen_id_counter : process (clk) is
      begin
        if rising_edge(clk) then
          -- Default: keep current id in memory, nothing to discover
          udp_tx_id_i <= udp_tx_id_i;
          make_disco  <= '0';

          if rst = '1' then
            -- Reset brings the id back to 0
            udp_tx_id_i <= (others => '0');
          -- Valid updates are only on ready signal
          -- Once protocol matches (but tx to udp is just not yet started):
          elsif rx_ready = '1' and protocol = udp and rx_count = 2 and src_ip_accept = '1' then
            -- Increase the ID, so 1 is the actual first possible ID as the ID is
            -- 'discovered' only at the 3rd clock cycle of the incoming frame
            if udp_tx_id_i(udp_tx_id_i'left) = '1' then
              -- Watch overflow: if table is already filled, use 1 as the first id, not 0
              udp_tx_id_i <= to_unsigned(1, udp_tx_id_i'length);
            else
              udp_tx_id_i <= udp_tx_id_i + 1;
            end if;
            make_disco <= '1';
          end if;
        end if;
      end process;

      --! @brief Store pair of the ID and IP address
      --! @details Storage of discovered IP and ID is indicated by by make_disco
      --! @todo Can't this be combined with proc_gen_id_counter?
      proc_store_ip_id_relation : process (clk) is
      begin
        if rising_edge(clk) then
          -- default: don't care for disco_id and don't write
          disco_id   <= (others => '-');
          disco_wren <= '0';
          -- store if indicated (and not in reset)
          if rst = '0' and make_disco = '1' then
            disco_id   <= std_logic_vector(udp_tx_id_i);
            disco_wren <= '1';
          end if;
        end if;
      end process;

      --! Instantiate port_io_table to store pair of discovered IP and package ID
      id_ip_table_inst : entity ethernet_lib.port_io_table
      generic map (
        PIN_WIDTH     => 16,
        POUT_WIDTH    => 32,
        TABLE_DEPTH   => ID_TABLE_DEPTH
      )
      port map (
        clk           => clk,
        rst           => rst,

        -- Discovery interface for writing pair of associated addresses/ports
        disco_wren    => disco_wren,
        disco_pin     => disco_id,
        disco_pout    => disco_ip,

        -- Recovery interface for reading pair of associated addresses/ports
        reco_en       => reco_en,
        reco_pin      => udp_rx_id,
        reco_found    => reco_ip_found,
        reco_pout     => reco_ip,

        -- Status of the module
        status_vector => status_vector(12 downto 11)
      );

    end block;

  end block;

end behavioral;
