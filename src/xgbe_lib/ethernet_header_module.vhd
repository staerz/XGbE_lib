-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Ethernet header module
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details
--! Constructs the Ethernet header from an incoming (IPv4) packet.
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Ethernet header module
entity ethernet_header_module is
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

    --! @name Avalon-ST from IP module
    --! @{

    --! RX ready
    ip_rx_ready_o   : out   std_logic;
    --! RX data and controls
    ip_rx_packet_i  : in    t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @name Avalon-ST to Eth outside world
    --! @{

    --! TX ready
    eth_tx_ready_i  : in    std_logic;
    --! TX data and controls
    eth_tx_packet_o : out   t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
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
    --! - 2: Waiting for MAC address
    --! - 1: IP packet is being forwarded
    --! - 0: IDLE mode
    status_vector_o : out   std_logic_vector(2 downto 0)
  );
end entity ethernet_header_module;

--! @cond
library misc;
--! @endcond

--! Implementation of the ethernet_header_module
architecture behavioral of ethernet_header_module is

  --! Broadcast MAC address
  constant MAC_BROADCAST_ADDR : std_logic_vector(47 downto 0) := (others => '1');

  --! @brief Internal ready signal
  --! @details Depending on eth_tx_ready_i first, and then on the
  --! success of the retrieval of the requested MAC address:
  --! While the IP is looked up (inducing ARP request), IP data transfer is
  --! paused.
  signal ip_tx_ready_r : std_logic;

  --! @brief State definition for the TX FSM
  --! @details
  --! State definition for the TX FSM
  --! - IDLE:    No transmission running and no ARP response to send.
  --! - IP:      A running IP transmission is being passed on.
  --! - TRAILER: A running IP transmission is fading out.
  type t_tx_state is (IDLE, IP, TRAILER);

  --! State of the TX FSM
  signal tx_state : t_tx_state;

  --! Indicate if transmission is done
  signal tx_done : std_logic;

  --! Destination MAC address
  signal mac_dst_addr : std_logic_vector(47 downto 0);

  --! Counter for outgoing packet
  signal tx_count : integer range 0 to 511;

begin

  status_vector_o(1) <= '1' when tx_state = IP else '0';
  status_vector_o(0) <= '1' when tx_state = IDLE else '0';

  with tx_state select ip_rx_ready_o <=
    ip_tx_ready_r when IDLE | IP,
    '0' when others;

  --! FSM to handle data forwarding of the interfaces
  proc_tx_state : process (clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        tx_state <= IDLE;
        tx_count <= 0;
      else
        if ip_tx_ready_r = '1' then
          tx_count <= tx_count + 1;

          case tx_state is

            when IDLE =>
              -- first priority: IP data forwarding
              if ip_rx_packet_i.sop = '1' then
                tx_state <= IP;
                tx_count <= 1;
              -- second priority: ARP request
              else
                tx_state <= IDLE;
                tx_count <= 0;
              end if;

            when IP =>
              -- interrupt only after finished transmission:
              if ip_rx_packet_i.eop = '1' then
                tx_state <= TRAILER;
              else
                tx_state <= IP;
              end if;

            when TRAILER =>
              if tx_done = '1' then
                tx_state <= IDLE;
                tx_count <= 0;
              else
                tx_state <= TRAILER;
              end if;

          end case;

        end if;
      end if;
    end if;
  end process proc_tx_state;

  blk_make_tx_interface : block
    signal eth_packet_length : unsigned(15 downto 0);

    constant SR_DEPTH : integer := 7;

    type t_tx_data_sr is array(1 to SR_DEPTH) of std_logic_vector(63 downto 0);

    type t_tx_ctrl_sr is array(1 to SR_DEPTH) of std_logic_vector(4 downto 0);

    signal tx_data_sr : t_tx_data_sr;
    signal tx_ctrl_sr : t_tx_ctrl_sr;

    signal tx_valid : std_logic_vector(0 to SR_DEPTH);
  begin

    blk_make_tx_done : block
      signal cnt_rst : std_logic;
    begin

      cnt_rst <= '1' when tx_state /= trailer else tx_valid(2);

      --! Instantiate counter to generate requested gap
      inst_trailer_counter : entity misc.counting
      generic map (
        COUNTER_MAX_VALUE => PAUSE_LENGTH
      )
      port map (
        clk => clk,
        rst => cnt_rst,
        en  => ip_tx_ready_r,

        cycle_done => tx_done
      );

    end block blk_make_tx_done;

    --! Set ETH packet length from IP length indication
    proc_set_eth_packet_length : process (clk)
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          eth_packet_length <= (others => '0');
        else
          if ip_tx_ready_r = '1' and tx_state = IDLE and ip_rx_packet_i.sop = '1' then
            eth_packet_length <= to_unsigned(14, 16) + unsigned(ip_rx_packet_i.data(47 downto 32));
          end if;
        end if;
      end if;
    end process proc_set_eth_packet_length;

    --! @brief Main process to assemble output packet from incoming IP data stream
    --! @details
    --! Buffer the first 5 words in shift register to await destination IP address,
    --! then (in block "request_mac") look up corresponding MAC address for
    --! finally starting the transmission of the packet on the eth_tx interface.
    --! Also set control signals of the interface properly.
    proc_make_data_and_controls : process (clk)
      variable byte_count : unsigned(15 downto 0);
      variable empty      : unsigned(3 downto 0);
      variable error      : std_logic;
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          tx_data_sr  <= (others => (others => '0'));
          tx_ctrl_sr  <= (others => (others => '0'));
          tx_valid(0) <= '0';
        elsif ip_tx_ready_r = '1' then
          -- take care for the data first: shift IP data into register
          -- with proper re-alignment for the insertion of 14 bytes of Ethernet header
          tx_data_sr(1) <= ip_rx_packet_i.data(47 downto 0) & x"0000";
          tx_data_sr(2) <= tx_data_sr(1)(63 downto 16) & ip_rx_packet_i.data(63 downto 48);

          -- default: shift
          tx_data_sr(3 to SR_DEPTH) <= tx_data_sr(2 to SR_DEPTH - 1);
          tx_ctrl_sr(3 to SR_DEPTH) <= tx_ctrl_sr(2 to SR_DEPTH - 1);

          -- now take care of the controls
          -- shift IP controls into register
          -- with proper re-calculation of the end position and empty value
          if ip_rx_packet_i.eop = '1' then
            -- calculate new ip_rx_empty from ip_rx_packet_i.empty
            empty := unsigned('0' & ip_rx_packet_i.empty) + 2;

            -- total number of bytes is multiple of 8: number in empty gives 'fill up' bytes
            byte_count := eth_packet_length + empty;

            -- do length check on the packet and set error, eventually
            if EOP_CHECK_EN = '1' then
              if (eth_packet_length < 64 - 4) and (tx_count = 5) and (ip_rx_packet_i.empty = "010") then
                -- ... but only if it is not padded:
                -- signature is maximum 49 data bytes but still 6 empty bytes in the eop packet due to padding
                error := '0';
              elsif (to_unsigned(tx_count + 3, 13) & "000") /= byte_count then
                error := '1';
              else
                error := ip_rx_packet_i.error(0);
              end if;
            else
              error := '0';
            end if;

            if unsigned(ip_rx_packet_i.empty) >= 8 - 2 then
              -- skip one register due to ip-header insertion
              tx_ctrl_sr(1) <= (others => '0');
              tx_ctrl_sr(2) <= ip_rx_packet_i.eop & error & std_logic_vector(empty(2 downto 0));

              tx_valid(1 to 2) <= "01";
            else
              tx_ctrl_sr(1) <= ip_rx_packet_i.eop & error & std_logic_vector(empty(2 downto 0));
              tx_ctrl_sr(2) <= (others => '0');

              tx_valid(1 to 2) <= "11";
            end if;
          else
            tx_ctrl_sr(1) <= (others => '0');
            -- todo: move the tx_ctrl_sr(2) <= tx_ctrl_sr(1); one up
            tx_ctrl_sr(2) <= tx_ctrl_sr(1);

            -- todo: mmove the shift up
            tx_valid(1) <= tx_valid(0);
            tx_valid(2) <= tx_valid(1);
          end if;

          -- handling of the valid bit
          -- mark rise and fall
          if ip_rx_packet_i.eop = '1' then
            tx_valid(0) <= '0';
          elsif tx_count = 4 and tx_state /= TRAILER then
            tx_valid(0 to 2) <= (others => '1');
          else
            tx_valid(0) <= tx_valid(0);
          end if;

          if tx_count = 4 then
            tx_valid(3 to SR_DEPTH) <= (others => '1');
          else
            -- default: shift and let bits 1 and 2 be decided from above
            tx_valid(3 to SR_DEPTH) <= tx_valid(2 to SR_DEPTH - 1);
          end if;
        end if;
      end if;
    end process proc_make_data_and_controls;

    -- finally compose ETH data output stream from registers and mac_dst_addr
    -- that has been retrieved in the meantime
    -- vsg_off comment_010
    with tx_count select eth_tx_packet_o.data <=
      -- insert discovered MAC address at correct position
      mac_dst_addr & my_mac_i(47 downto 32) when 5,
      -- insert (lsbs of MAC address and) protocol (IP)
      my_mac_i(31 downto 0) & x"0800" & tx_data_sr(SR_DEPTH)(15 downto 0) when 6,
      -- or just attach (IP) data from the shift register
      tx_data_sr(SR_DEPTH) when others;

    -- vsg_on comment_010
    -- set valid
    eth_tx_packet_o.valid <= tx_valid(SR_DEPTH);

    -- set sop
    eth_tx_packet_o.sop <= '1' when tx_count = 5 else '0';

    -- set eop indicators from shift register
    eth_tx_packet_o.eop   <= tx_ctrl_sr(SR_DEPTH)(4);
    eth_tx_packet_o.error <= tx_ctrl_sr(SR_DEPTH)(3 downto 3);
    eth_tx_packet_o.empty <= tx_ctrl_sr(SR_DEPTH)(2 downto 0);

  end block blk_make_tx_interface;

  -- almost same behaviour as 'request_ip: block' in IP header module
  -- todo: make it some common module?
  blk_request_mac : block

    type t_request_state is (IDLE, WAITING);

    -- vsg_disable_next_line signal_007
    signal request_state : t_request_state := IDLE;

    signal request_cnt_rst : std_logic;
    signal request_cnt_en  : std_logic;
    signal request_timeout : std_logic;
  begin

    status_vector_o(2) <= '1' when request_state = WAITING else '0';

    request_cnt_rst <= '1' when request_state = IDLE else '0';
    request_cnt_en  <= '1' when one_ms_tick_i = '1' and request_state = WAITING else '0';

    inst_request_timeout : entity misc.counting
    generic map (
      COUNTER_MAX_VALUE => MAC_TIMEOUT,
      CYCLIC            => false
    )
    port map (
      clk => clk,
      rst => request_cnt_rst,
      en  => request_cnt_en,

      cycle_done => request_timeout
    );

    with request_state select ip_tx_ready_r <=
      '0' when WAITING,
      eth_tx_ready_i when others;

    proc_set_mac_dst_addr : process (clk)
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          request_state <= IDLE;
          reco_en_o     <= '0';
          reco_ip_o     <= (others => '-');
          mac_dst_addr  <= (others => '0');
        else
          -- default
          reco_en_o <= '0';

          case request_state is

            when IDLE =>
              if ip_tx_ready_r = '1' and tx_count = 2 then
                -- treat special case of IP broadcast:
                -- it can only come from a DHCP package and we cannot use the ARP table yet
                -- as it is reserved for the DHCP module until an IP address is configured
                if ip_rx_packet_i.data(63 downto 32) = x"FF_FF_FF_FF" then
                  mac_dst_addr  <= MAC_BROADCAST_ADDR;
                  request_state <= IDLE;
                else
                  reco_en_o     <= '1';
                  reco_ip_o     <= ip_rx_packet_i.data(63 downto 32);
                  request_state <= WAITING;
                end if;
              else
                request_state <= IDLE;
              end if;

            when WAITING =>
              if reco_done_i = '1' then
                -- take MAC address from table
                mac_dst_addr  <= reco_mac_i;
                request_state <= IDLE;
              else
                if request_timeout = '1' then
                  mac_dst_addr  <= MAC_BROADCAST_ADDR;
                  request_state <= IDLE;
                else
                  request_state <= WAITING;
                end if;
              end if;

          end case;

        end if;
      end if;
    end process proc_set_mac_dst_addr;

  end block blk_request_mac;

end architecture behavioral;
