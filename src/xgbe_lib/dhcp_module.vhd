-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief DHCP core according to RFC 2131 (and RFC 2132)
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details
--! Provides an IP address in "my_ip_o" based on negotiating it with a DHCP
--! server.
--! The MAC address of the core has to be provided at all times to "my_mac_i".
--! The incoming interface expects the raw UDP frame (Ethernet and IP header
--! and already stripped off), but including the full UDP header.
--! The outgoing interface provides a full UDP frame, including UDP header with
--! UDP CRC field.
--! The UDP CRC field is set to the checksum over the UDP data if UDP_CRC_EN
--! is enabled, otherwise set to x"0000".
--!
--! Outgoing DHCP requests are buffered while dhcp_tx_ready_i is indicating busy
--! unless it would exceed timeouts specified by the DHCP protocol.
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! DHCP core according to RFC 2131

entity dhcp_module is
  generic (
    --! @brief UDP CRC calculation
    --! @details
    --! If enabled, the UDP check sum will be calculated over the UDP data
    --! and presented in the UDP CRC field for further adaption at the IP layer.
    --! If disabled, the check sum calculation is omitted
    --! and the UDP CRC field set to x"0000".
    UDP_CRC_EN     : boolean                 := true;
    --! Timeout in milliseconds
    DHCP_TIMEOUT       : integer range 2 to 1000 := 50;
    --! Cycle time in milliseconds for ARP requests (when repetitions are needed)
    DHCP_REQUEST_CYCLE : integer range 1 to 1000 := 2;
    --! Depth of ARP table (number of stored connections)
    DHCP_TABLE_DEPTH   : integer range 1 to 1024 := 4
  );
  port (
    --! Clock
    clk             : in    std_logic;
    --! Reset, sync with #clk
    rst             : in    std_logic;
    --! @brief Boot, sync with #clk
    --! @details Rebooting with last assigned IP address (rather than resetting requesting new one)
    boot            : in    std_logic;

    --! @name Avalon-ST from DHCP core
    --! @{

    --! RX ready
    dhcp_rx_ready_o  : out   std_logic;
    --! RX data and controls
    dhcp_rx_packet_i : in    t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @name Avalon-ST to DHCP core
    --! @{

    --! TX ready
    dhcp_tx_ready_i  : in    std_logic;
    --! TX data and controls
    dhcp_tx_packet_o : out   t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @name Interface for recovering MAC address from given IP address
    --! @{

    --! Recovery enable
    reco_en_i       : in    std_logic;
    --! IP address to recover
    reco_ip_i       : in    std_logic_vector(31 downto 0);
    --! Recovered MAC address
    reco_mac_o      : out   std_logic_vector(47 downto 0);
    --! Recovery success: 1 = found, 0 = not found (time out)
    reco_done_o     : out   std_logic;
    --! @}

    --! MAC address of the module
    my_mac_i        : in    std_logic_vector(47 downto 0);
    --! IP address of the module
    my_ip_o         : out   std_logic_vector(31 downto 0);

    --! Clock cycle when 1 millisecond is passed
    one_ms_tick_i   : in    std_logic;

    --! @brief Status of the module
    --! @details Status of the module
    --! - to be defined
    status_vector_o : out   std_logic_vector(4 downto 0)
  );
end entity dhcp_module;

--! @cond
library xgbe_lib;
library misc;
library memory;
--! @endcond

--! Implementation of the dhcp_module
architecture behavioral of dhcp_module is
  --! @brief State definition of the DHCP module
  --! @details
  --! The following is Figure 5 (State-transition diagram for DHCP clients)
  --! from RFC 2131, showing the states of this DHCP module
  --!
  --!  --------                               -------
  --! |        | +-------------------------->|       |<-------------------+
  --! | INIT-  | |     +-------------------->| INIT  |                    |
  --! | REBOOT |DHCPNAK/         +---------->|       |<---+               |
  --! |        |Restart|         |            -------     |               |
  --!  --------  |  DHCPNAK/     |               |                        |
  --!     |      Discard offer   |      -/Send DHCPDISCOVER               |
  --! -/Send DHCPREQUEST         |               |                        |
  --!     |      |     |      DHCPACK            v        |               |
  --!  -----------     |   (not accept.)/   -----------   |               |
  --! |           |    |  Send DHCPDECLINE |           |                  |
  --! | REBOOTING |    |         |         | SELECTING |<----+            |
  --! |           |    |        /          |           |     |DHCPOFFER/  |
  --!  -----------     |       /            -----------   |  |Collect     |
  --!     |            |      /                  |   |       |  replies   |
  --! DHCPACK/         |     /  +----------------+   +-------+            |
  --! Record lease, set|    |   v   Select offer/                         |
  --! timers T1, T2   ------------  send DHCPREQUEST      |               |
  --!     |   +----->|            |             DHCPNAK, Lease expired/   |
  --!     |   |      | REQUESTING |                  Halt network         |
  --!     DHCPOFFER/ |            |                       |               |
  --!     Discard     ------------                        |               |
  --!     |   |        |        |                   -----------           |
  --!     |   +--------+     DHCPACK/              |           |          |
  --!     |              Record lease, set    -----| REBINDING |          |
  --!     |                timers T1, T2     /     |           |          |
  --!     |                     |        DHCPACK/   -----------           |
  --!     |                     v     Record lease, set   ^               |
  --!     +----------------> -------      /timers T1,T2   |               |
  --!                +----->|       |<---+                |               |
  --!                |      | BOUND |<---+                |               |
  --!   DHCPOFFER, DHCPACK, |       |    |            T2 expires/   DHCPNAK/
  --!    DHCPNAK/Discard     -------     |             Broadcast  Halt network
  --!                |       | |         |            DHCPREQUEST         |
  --!                +-------+ |        DHCPACK/          |               |
  --!                     T1 expires/   Record lease, set |               |
  --!                  Send DHCPREQUEST timers T1, T2     |               |
  --!                  to leasing server |                |               |
  --!                          |   ----------             |               |
  --!                          |  |          |------------+               |
  --!                          +->| RENEWING |                            |
  --!                             |          |----------------------------+
  --!                              ----------
  type t_dhcp_state is (INIT, INIT_REBOOT, REBOOTING, SELECTING, REQUESTING, DECLINING, REBINDING, BOUND, RENEWING);

  --! State of the TX FSM
  signal dhcp_state : t_dhcp_state := INIT;

  --! @name Interface for initialising ARP request
  --! @{

  --! Requested IP address
  signal request_ip : std_logic_vector(31 downto 0);
  --! Request enable
  signal request_en : std_logic;
  --! @}

  --! @name Interface for writing new discovered MAC and IP to ARP table
  --! @{

  --! Discovered MAC address
  signal disco_mac  : std_logic_vector(47 downto 0);
  --! Discovered IP address
  signal disco_ip   : std_logic_vector(31 downto 0);
  --! Discovery write enable
  signal disco_wren : std_logic;
  --! @}

  --! Indicator if or if not to use a suggested IP
  signal use_suggest_ip : boolean;
  --! Previous stored IP of the core
  signal mypreviousip   : std_logic_vector(31 downto 0);

  --! The selected yiaddr from the possibly multiple offers
  signal yourid   : std_logic_vector(31 downto 0);
  --! The selected siaddr from the possibly multiple offers
  signal serverid   : std_logic_vector(31 downto 0);
  --! Granted least time (in seconds)
  signal my_lease_time   : std_logic_vector(31 downto 0);

  --! @name Indicators to send dedicated DHCP messages (comm from global FSM to tx FSM)
  --! @{

  --! Discover
  signal send_dhcp_discover : std_logic;
  --! Request
  signal send_dhcp_request : std_logic;
  --! Decline
  signal send_dhcp_decline : std_logic;
  --! Release
  signal send_dhcp_release : std_logic;

  --! @}

  --! @name Signals to feed back to global FSM
  --! @{

  --! DHCP offer selected (while in SELECTING)
  signal dhcp_offer_selected : std_logic;
  --! DHCP acknowledge received (while in REQUESTING, RENEWING, REBINDING, REBOOTING)
  signal dhcp_acknowledge    : std_logic;
  --! Filter on accepting acknowledged config (while in REQESTING)
  signal dhcp_accept         : std_logic;
  --! DHCP decline message sent
  signal decline_sent        : std_logic;
  --! Expiration of T1
  signal t1_expires          : std_logic;
  --! DHCP nacknowledge received (while in REQUESTING, RENEWING, REBINDING, REBOOTING)
  signal dhcp_nack           : std_logic;
  --! Expiration of T2
  signal t2_expires          : std_logic;
  --! Expiration of lease
  signal lease_expired       : std_logic;

  --! @}

  --! @name Signals for RX/TX comm
  --! @{

  --! XID used for client-server interaction
  signal xid : unsigned(31 downto 0);

  --! @}

  --! @brief Size (length in words of 64 bits) of DHCP fixed header
  --! @details
  --! The fixed size part of a DHCP frame consists of the UDP header
  --! (2 words of 32 bits) and another (11 + 16 + 32 + 1) 32-bit words.
  --! In total, the frame comprises 62 32-bit, or 31 64-bit words.
  --!
  --! Compare to dhcp_frame.
  constant DHCP_WORDS : integer := 31;

begin

  assert DHCP_REQUEST_CYCLE < DHCP_TIMEOUT
    report "DHCP_REQUEST_CYCLE must be smaller than DHCP_TIMEOUT!"
    severity failure;

  proc_dchp_state : process (clk)
  begin
    if rising_edge(clk) then

      -- defaults:
      send_dhcp_discover <= '0';
      send_dhcp_request  <= '0';
      send_dhcp_decline  <= '0';

      if rst = '1' then
        dhcp_state <= INIT;
      elsif boot = '1' then
        dhcp_state <= INIT_REBOOT;
      else

        -- TODO: Add timeout options in different states waiting for feedback
        case dhcp_state is

          when INIT =>
            dhcp_state <= SELECTING;

            send_dhcp_discover <= '1';

          when SELECTING =>
            if dhcp_offer_selected = '1' then
              dhcp_state <= REQUESTING;

              send_dhcp_request <= '1';
            else
              dhcp_state <= SELECTING;
            end if;

          when REQUESTING =>
            if dhcp_acknowledge = '1' then
              if dhcp_accept = '1' then
                dhcp_state <= BOUND;
              else
                dhcp_state <= DECLINING;

                send_dhcp_decline <= '1';
              end if;
            elsif dhcp_nack = '1' then
              dhcp_state <= INIT;
            else
              dhcp_state <= REQUESTING;
            end if;

          when DECLINING =>
            if decline_sent = '1' then
              dhcp_state <= INIT;
            else
              dhcp_state <= DECLINING;
            end if;

          when BOUND =>
            if t1_expires = '1' then
              dhcp_state <= RENEWING;

              -- TODO: Check if the request is different from request coming from SELECTING
              send_dhcp_request <= '1';
            else
              dhcp_state <= BOUND;
            end if;

          when RENEWING =>
            if dhcp_acknowledge = '1' then
              dhcp_state <= BOUND;
            elsif dhcp_nack = '1' then
              -- TODO: HALT network
              dhcp_state <= INIT;
            elsif t2_expires = '1' then
              dhcp_state <= REBINDING;

              --! TODO: must be broadcast - same as before?
              send_dhcp_request <= '1';
            else
              dhcp_state <= RENEWING;
            end if;

          when REBINDING =>
            if dhcp_acknowledge = '1' then
              dhcp_state <= BOUND;
            elsif dhcp_nack = '1' or lease_expired = '1' then
              -- TODO: HALT network
              dhcp_state <= INIT;
            else
              dhcp_state <= REBINDING;
            end if;

          when INIT_REBOOT =>
            dhcp_state <= REBOOTING;

            -- TODO: Check if the request is different from request coming from SELECTING
            send_dhcp_request <= '1';

          when REBOOTING =>
            if dhcp_acknowledge = '1' then
              dhcp_state <= BOUND;
            elsif dhcp_nack = '1' then
              dhcp_state <= INIT;
            else
              dhcp_state <= REBOOTING;
            end if;

        end case;

      end if;
    end if;
  end process proc_dchp_state;

  --! @brief Create a new xid for every new request
  --! @details RFC 2131:
  --! A client may choose to reuse the same 'xid' or select a new 'xid' for each retransmitted message.
  --!
  --! We actually choose not to (hey, that's more fun!)
  --!
  --! "The DHCPREQUEST message contains the same 'xid' as the DHCPOFFER message."
  --! But since further "The server inserts the 'xid' field from the
  --! DHCPDISCOVER message into the 'xid' field of the DHCPOFFER message",
  --! Effectively the exact same xid is used for a full DHCP interaction.
  proc_xid : process (clk)
  begin
    if rising_edge(clk) then
      -- reset of xid on input reset
      if rst = '1' then
        --! initial value is absolutely arbitrary
        --! we could make it a value derived from HW ID or anything...
        --! Note that the value+1 is the first one to ever be sent...
        xid <= x"DEAD_BEEE";
      -- create a new xid for each discover message
      --! TODO: or:
      --!  - dhcp_inform (upon fixed IP) [not necessarily to be implemented]
      elsif send_dhcp_discover = '1' or (send_dhcp_request = '1' and dhcp_state = REBOOTING) then
        xid <= xid + 1;
      end if;
    end if;
  end process proc_xid;

  -- Transmitter part
  blk_make_tx_interface : block
    --! @brief State definition for the TX FSM
    --! @details
    --! State definition for the TX FSM
    --! - IDLE:          no transmission running
    --! - ARP_RESPONSE:  ARP response is being sent
    --! - ARP_REQUEST:   ARP request is being sent

    type t_tx_state is (IDLE, DHCP_DISCOVER, DHCP_REQUEST, DHCP_DECLINE, DHCP_RELEASE);
    -- RELEASE, INFORM

    --! State of the TX FSM
    signal tx_state : t_tx_state := IDLE;

    --! @brief Fixed size part of a DHCP frame
    --! @details
    --! Note that for simplicity the mandatory "MAGIC_COOKIE" option is
    --! considered part of this fixed size DHCP frame although RFC 2131
    --! defines it as an option.
    --! Adding this magic cookie also makes the fixed header a multiple
    --! of 8 bytes which is convenient for an 8-byte-based implementation.
    --!
    --! Words of the frame are from left (high) to right (low), i.e. the
    --! leftmost 32-bit word is transmitted first,
    --! according to the following diagram.
    --!
    --!   0                   1                   2                   3
    --!   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    --!   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    --!   |        UDP source port        |     UDP destination port      |
    --!   +-------------------------------+-------------------------------+
    --!   |           UDP length          |         UDP checksum          |
    --!   +===============================+===============================+
    --!   |     op (1)    |   htype (1)   |   hlen (1)    |   hops (1)    |
    --!   +---------------+---------------+---------------+---------------+
    --!   |                            xid (4)                            |
    --!   +-------------------------------+-------------------------------+
    --!   |           secs (2)            |           flags (2)           |
    --!   +-------------------------------+-------------------------------+
    --!   |                          ciaddr  (4)                          |
    --!   +---------------------------------------------------------------+
    --!   |                          yiaddr  (4)                          |
    --!   +---------------------------------------------------------------+
    --!   |                          siaddr  (4)                          |
    --!   +---------------------------------------------------------------+
    --!   |                          giaddr  (4)                          |
    --!   +---------------------------------------------------------------+
    --!   |                                                               |
    --!   |                          chaddr  (16)                         |
    --!   |                                                               |
    --!   |                                                               |
    --!   +---------------------------------------------------------------+
    --!   |                                                               |
    --!   |                          sname   (64)                         |
    --!   +---------------------------------------------------------------+
    --!   |                                                               |
    --!   |                          file    (128)                        |
    --!   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    --!   |                          MAGIC_COOKIE                         |
    --!   +-+---+-+---+-+---+-+---+-+---+-+---+-+---+-+---+-+---+-+---+-+-+
    --!   |                   (more) options (variable)                   |
    --!   +---------------------------------------------------------------+
    signal dhcp_frame: std_logic_vector((DHCP_WORDS * 64) - 1 downto 0);

    --! @name Elements of the DHCP frame
    --! @{

    --! UDP source port (68)
    constant UDP_SRC_PORT : std_logic_vector(15 downto 0) := x"0044";
    --! UDP destination port (67)
    constant UDP_DST_PORT : std_logic_vector(15 downto 0) := x"0043";
    --! UDP length
    signal udp_length     : unsigned(15 downto 0);
    --! UDP CRC
    signal udp_crc        : std_logic_vector(15 downto 0);
    --! DHCP header (op & htype & hlen & hops: fixed for client tx)
    constant DHCP_HEADER  : std_logic_vector(31 downto 0) := x"01_01_06_00";
    -- Transaction ID: already defined globally
    --! Seconds
    signal secs           : std_logic_vector(15 downto 0);
    --! Flags
    signal flags          : std_logic_vector(15 downto 0);
    --! Client IP ADDR
    signal ciaddr         : std_logic_vector(31 downto 0);
    --! Your IP ADDR / Server IP ADDR / Gateway IP ADDR
    constant YSGIADDR     : std_logic_vector(31 downto 0) := (others => '0');
    --! Client Hardware IP ADDR
    signal chaddr         : std_logic_vector(127 downto 0);
    --! Optional server host name, null terminated string
    constant SNAME        : std_logic_vector(511 downto 0) := (others => '0');
    --! Boot file name, null terminated string
    constant BFILE        : std_logic_vector(1023 downto 0) := (others => '0');
    --! Magic cookie (mandatory first option word)
    constant MAGIC_COOKIE : std_logic_vector(31 downto 0) := x"63825363";

    --! @}

    --! Place holder for DHCP options:
    --! Filled in from options FIFO
    signal dhcp_options  : std_logic_vector(63 downto 0);

    --! Register to temporarily store target MAC, used in TX path only and fed by FIFO
    signal config_tg_mac : std_logic_vector(47 downto 0);

    --! Counter for outgoing ARP response frame
    signal tx_count : integer range 0 to 63;

    --! @brief State definition for the FIFO FSM
    --! @details
    --! State definition for the FIFO FSM
    --! - IDLE:     Nothing happening
    --! - READ:     Read data from FIFO
    --! - LAST:     Last word from FIFO was read (FIFO empty again)
    type t_fifo_state is (IDLE, READ, LAST);

    --! State of the FIFO FSM

    -- vsg_disable_next_line signal_007
    signal fifo_state : t_fifo_state := IDLE;
  begin

    --! We know the length in advance (must be in agreement with proc_write_fifo!):
    --! 8 * DHCP_WORDS for fixed DHCP header + options
    --! Note: a more general approach would be to check the number of words
    --! in the tx options FIFO (once written), but then we'd have to wait for that
    --! to happen first which would delay the process
    with tx_state select udp_length <=
      to_unsigned((8 * DHCP_WORDS + 8), 16) when DHCP_DISCOVER,
      (others => '-') when others;

    gen_udp_crc: if UDP_CRC_EN generate
      --! TODO: Implement CRC calculation
      --! Will need major rework as first the package will have to be generated and
      --! the CRC to be calculated on the fly (using common's checksum_calc)
      udp_crc <= (others => '0');
    else generate
      udp_crc <= (others => '0');
    end generate;

    -- count "seconds since DHCP request started"
    blk_secs : block
      signal cnt_rst     : std_logic;
      signal second_tick : std_logic;
    begin

      cnt_rst <= rst or send_dhcp_discover;

      inst_second_tick : entity misc.counting
      generic map (
        COUNTER_MAX_VALUE => 1000
      )
      port map (
        clk => clk,
        rst => cnt_rst,
        en  => one_ms_tick_i,

        cycle_done => second_tick
      );

      inst_seconds : entity misc.counter
      generic map (
        COUNTER_MAX_VALUE => 2**(secs'length)-1
      )
      port map (
        clk => clk,
        rst => rst,
        inc => second_tick,
        dec => '0',

        empty => open,
        full  => open,
        count => secs
      );

    end block blk_secs;

    --! TODO: Check what the outer world does: We may also just send unicasts
    --! and instead add an auxiliary interface to indicate to it which addresses to use!
    --!
    --! A client that cannot receive unicast IP datagrams until its protocol
    --! software has been configured with an IP address SHOULD set the
    --! BROADCAST bit in the 'flags' field to 1 in any DHCPDISCOVER or
    --! DHCPREQUEST messages that client sends.
    --!
    --! If this bit is set to 1, the DHCP message SHOULD be sent as
    --! an IP broadcast using an IP broadcast address (preferably 0xffffffff)
    --!
    --! TODO: we should also separate out the case of DHCP_REQUEST when in RENEWING or REBINDING (we have a valid IP then...)
    with tx_state select flags <=
      (0 => '1', others => '0') when DHCP_DISCOVER | DHCP_REQUEST,
      (others => '0') when others;

    ciaddr <=
      my_ip_o when
--        (tx_state = DHCP_INFORM) or
        (tx_state = DHCP_REQUEST and (dhcp_state = RENEWING or dhcp_state = REBINDING)) or
        (tx_state = DHCP_RELEASE) else
      (others => '0');

    chaddr <= my_mac_i & x"00_00" & x"00_00_00_00" & x"00_00_00_00";

    -- constructing the dhcp_frame (constant part): Fixed structure
    dhcp_frame <=
      UDP_SRC_PORT & UDP_DST_PORT & std_logic_vector(udp_length) & udp_crc &
      DHCP_HEADER &
      std_logic_vector(xid) & secs & flags &
      ciaddr & YSGIADDR &
      YSGIADDR & YSGIADDR &
      chaddr &
      SNAME & BFILE &
      MAGIC_COOKIE;

    status_vector_o(0) <= '1' when dhcp_tx_ready_i = '0' else '0';

    -- arp_tx_packet_o.data   <= see state machine;

    dhcp_tx_packet_o.valid <= '1' when tx_count >= 1 and tx_state /= IDLE else '0';
    dhcp_tx_packet_o.sop   <= '1' when tx_count = 1 else '0';
    dhcp_tx_packet_o.eop   <= '1' when fifo_state = LAST else '0';
    dhcp_tx_packet_o.error <= "0";

    -- the implementation always sends full 8-byte words
    -- (the output of the FIFO is always a full word even if the option could be transmitted in less)
    -- this could be reworked, but then the FIFO would have to also store how many used words the (last!) option has
    dhcp_tx_packet_o.empty <= "000";

    --! @brief Counting the clks being in the DHCP tx mode
    --! which is similar to the frames of 8 bytes to be sent
    proc_count : process (clk)
    begin
      if rising_edge(clk) then
        -- reset of tx_count on input reset or when in IDLE
        if rst = '1' or tx_state = IDLE then
          tx_count <= 0;
        -- keep counting otherwise
        elsif tx_state /= IDLE and dhcp_tx_ready_i = '1' then
          tx_count <= tx_count + 1;
        end if;
      end if;
    end process proc_count;

    blk_gen_tx_data : block
      signal target_mac    : std_logic_vector(47 downto 0);
      signal target_ip     : std_logic_vector(31 downto 0);
      signal target_ip_tmp : std_logic_vector(31 downto 0);
      signal send_request  : std_logic;
    begin

      blk_send_request : block
        signal cnt_rst : std_logic;
        signal cnt_en  : std_logic;
      begin

        cnt_en <= one_ms_tick_i and request_en;

        cnt_rst <= not request_en;

        inst_request_timeout_counter : entity misc.counting
        generic map (
          COUNTER_MAX_VALUE => DHCP_REQUEST_CYCLE
        )
        port map (
          clk => clk,
          rst => cnt_rst,
          en  => cnt_en,

          cycle_done => send_request
        );

      end block blk_send_request;

      proc_arp_request : process (clk)
      begin
        if rising_edge(clk) then
          if rst = '1' then
            target_ip_tmp <= (others => '0');
          elsif request_en = '1' then
            target_ip_tmp <= request_ip;
          else
            target_ip_tmp <= target_ip_tmp;
          end if;
        end if;
      end process proc_arp_request;

      blk_fifo_handler : block
        signal dhcp_operation : std_logic_vector(3 downto 0);

        --  signals controlling the FIFO data flow
        --! FIFO data in
        signal dhcp_options_fifo_din   : std_logic_vector(63 downto 0);
        --! FIRO write enable
        signal dhcp_options_fifo_wen   : std_logic;
        --! FIFO read enable
        signal dhcp_options_fifo_ren   : std_logic;
        --! FIFO data out
        signal dhcp_options_fifo_dout  : std_logic_vector(63 downto 0);
        --! FIFO full
        signal dhcp_options_fifo_full  : std_logic;
        --! FIFO empty
        signal dhcp_options_fifo_empty : std_logic;

      begin

        with tx_state select dhcp_operation <=
          x"1" when DHCP_DISCOVER,
          x"3" when DHCP_REQUEST,
          x"4" when DHCP_DECLINE,
          x"7" when DHCP_RELEASE,
          x"8" when others; -- DHCP_INFORM,

        --! @brief FIFO to store DHCP options to be sent
        --! @details
        --! FIFO is filled while the DHCP fixed header is sent with the options
        --! needed depending on what kind of packet is sent.
        --! Storing 16 options is already on the higher edge.
        inst_dhcp_options_fifo : entity memory.generic_fifo
        generic map (
          WR_D_WIDTH => 64,
          WR_D_DEPTH => 16
        )
        port map (
          rst      => rst,
          wr_clk   => clk,
          wr_en    => dhcp_options_fifo_wen,
          wr_data  => dhcp_options_fifo_din,
          rd_clk   => clk,
          rd_en    => dhcp_options_fifo_ren,
          rd_data  => dhcp_options_fifo_dout,
          rd_full  => dhcp_options_fifo_full,
          rd_empty => dhcp_options_fifo_empty
        );

        -- in each tx_count cycle check if the option needs to be added or not,
        -- depending which kind of packet is to be sent
        --! Compare to table 5 of RFC 2131
        --!
        --! Only MUST options are implemented so far.
        --! We may (in all cases) add a client identifier option
        proc_write_fifo: process(clk)
        begin
          if rising_edge(clk) then
            -- default: don't write anything to the FIFO
            dhcp_options_fifo_din <= (others => '0');
            dhcp_options_fifo_wen <= '0';

            case tx_count is
              -- DHCP Message Type
              when 1 =>
                dhcp_options_fifo_din <= x"35010" & dhcp_operation & x"00_00_00_00_00";
                dhcp_options_fifo_wen <= '1';
              -- Requested IP Address
              when 2 =>
                -- optional for discover, can request any
                if tx_state = DHCP_DISCOVER and use_suggest_ip then
                  dhcp_options_fifo_din <= x"3204" & mypreviousip & x"00_00";
                  dhcp_options_fifo_wen <= '1';
                -- MUST be set to the value of 'yiaddr' in the DHCPOFFER message from the server.
                -- yourid is any of the selected yiaddr
                elsif (tx_state = DHCP_REQUEST and (dhcp_state = REQUESTING or dhcp_state = REBOOTING)) or
                  (tx_state = DHCP_DECLINE) then
                  dhcp_options_fifo_din <= x"3204" & yourid & x"00_00";
                  dhcp_options_fifo_wen <= '1';
                end if;
              -- Server Identifier
              when 3 =>
                -- The client broadcasts a DHCPREQUEST message that MUST include the 'server identifier' option
                -- serverid is any of the selected siaddr
                if (tx_state = DHCP_REQUEST and dhcp_state = REQUESTING) or
                  tx_state = DHCP_DECLINE or tx_state = DHCP_RELEASE then
                  dhcp_options_fifo_din <= x"3604" & serverid & x"00_00";
                  dhcp_options_fifo_wen <= '1';
                end if;
              when others =>
                null;
            end case;
          end if;
        end process proc_write_fifo;

        --! Read FIFO (= add dhcp options for appending to the fixed frame)
        proc_read_fifo : process (clk)
        begin
          if rising_edge(clk) then
            -- default settings:
            dhcp_options_fifo_ren <= '0';

            case fifo_state is

              when IDLE =>
                -- start reading from FIFO as soon as the fixed header is sent already
                if tx_count = DHCP_WORDS-1 and dhcp_options_fifo_empty = '0' then
                  dhcp_options_fifo_ren <= '1';
                  fifo_state <= READ;
                -- TODO: if FIFO is empty at that point, we do have a problem (as filling it went wrong)
                else
                  fifo_state <= IDLE;
                end if;

              when READ =>
                if dhcp_options_fifo_empty = '1' then
                  dhcp_options_fifo_ren <= '1';
                  fifo_state <= READ;
                else
                  fifo_state <= LAST;
                end if;

              when LAST =>
                fifo_state <= IDLE;

            end case;

          end if;
        end process proc_read_fifo;

        -- actual DCHP options are FIFO output if it has useful data, otherwise it's empty
        with fifo_state select dhcp_options <=
          dhcp_options_fifo_dout
            when READ | LAST,
          (others => '0')
            when others;

      end block blk_fifo_handler;

      -- creates DHCP packet: Either chose section from fixed part
      -- or chose options from fifo
      with tx_count select dhcp_tx_packet_o.data <=
        -- tx_count-relative slice of constant part of the DHCP packet
        dhcp_frame( (DHCP_WORDS + 1 - tx_count) * 64 - 1 downto (DHCP_WORDS - tx_count) * 64)
          when 1 to DHCP_WORDS,
        dhcp_options
          when others;

      --! FSM to handle DHCP package transmission
      --! simply the type of action moves the TX state from IDLE
      --! into the dedicated state
      --! Once all options are sent (indicated by the FIFO state being in HOLD)
      --! we return to IDLE.
      proc_tx_state : process (clk)
      begin

        if rising_edge(clk) then
          if (rst = '1') then
            tx_state <= IDLE;
          else

            case tx_state is

              when IDLE =>
                -- possibly replace this by a case switch?
                -- depends on how/where individual selectors are set
                if send_dhcp_discover = '1' then
                  tx_state <= DHCP_DISCOVER;
                elsif send_dhcp_request = '1' then
                  tx_state <= DHCP_REQUEST;
                elsif send_dhcp_decline = '1' then
                  tx_state <= DHCP_DECLINE;
                elsif send_dhcp_release = '1' then
                  tx_state <= DHCP_RELEASE;
                else
                  tx_state <= IDLE;
                end if;

              when DHCP_DISCOVER =>
                if fifo_state = LAST then
                  tx_state <= IDLE;
                else
                  tx_state <= DHCP_DISCOVER;
                end if;

              when DHCP_REQUEST =>
                if fifo_state = LAST then
                  tx_state <= IDLE;
                else
                  tx_state <= DHCP_REQUEST;
                end if;

              when DHCP_DECLINE =>
                if fifo_state = LAST then
                  tx_state <= IDLE;
                else
                  tx_state <= DHCP_DECLINE;
                end if;

              when DHCP_RELEASE =>
                if fifo_state = LAST then
                  tx_state <= IDLE;
                else
                  tx_state <= DHCP_RELEASE;
                end if;

            end case;

          end if;
        end if;
      end process proc_tx_state;

    end block blk_gen_tx_data;

  end block blk_make_tx_interface;

  -- Receiver part
  blk_make_rx_interface : block
    --! @brief State definition for the RX FSM
    --! @details
    --! State definition for the RX FSM
    --! - HEADER: checks all requirement of the incoming DHCP packet
    --! - SKIP: skips all frames until EOF (if header is wrong)
    --! - STORING_OPTS: storing the options in FIFO
    --! - PARSING_OPTS: parsing the options from the FIFO

    type   t_rx_state is (HEADER, SKIP, STORING_OPTS, PARSING_OPTS); --OFFER, ACKNOWLEDGE, NACKNOWLEDGE);
    --! States of the RX FSM
    signal rx_state : t_rx_state;

    --! DHCP package type
    signal rx_type : std_logic_vector(3 downto 0);

    --! Internal ready signal
    signal dhcp_rx_ready_i : std_logic;

    --! Counter for incoming packets: max possible = jumbo frame (9000 bytes = 1125 frames)
    signal rx_count    : integer range 0 to 1125;
    --! Register receiving data
    signal rx_packet_reg : dhcp_rx_packet_i'subtype;

    --! Indicator if parsing DHCP options is done
    signal parse_options_done : std_logic;

    --! @name Data extracted blindly from RX package
    --! @{

    --! Offered IP
    signal offered_yiaddr  : std_logic_vector(31 downto 0);

    --! @}

    --! @name Extracted options
    --! @{

    --! DHCP operation
    signal dhcp_operation  : std_logic_vector(3 downto 0);
    --! DHCP lease time (in seconds)
    signal dhcp_lease_time : std_logic_vector(31 downto 0);
    --! DHCP server IP address
    signal dhcp_server_ip  : std_logic_vector(31 downto 0);

    --! @}

  begin

    -- Receiver is always ready as long as we're not just evaluating options (from a previous request)
    -- That prevents write options of multiple incoming DHCP packets into the options FIFO
    dhcp_rx_ready_i <= '0' when rx_state = PARSING_OPTS else '1';

    dhcp_rx_ready_o <= dhcp_rx_ready_i;

    --! Counting the frames of 8 bytes received
    -- TODO: do we have to reset _reg signals?
    proc_manage_rx_count_from_rx_sop : process (clk)
    begin
      if rising_edge(clk) then
        -- reset counter
        if (rst = '1') then
          rx_count <= 0;
        -- Count (and register) input data words
        elsif dhcp_rx_packet_i.valid = '1' and dhcp_rx_ready_i = '1' then
          rx_packet_reg <= dhcp_rx_packet_i;
          -- and initialize counter upon sop
          if dhcp_rx_packet_i.sop = '1' then
            rx_count <= 1;
          -- ... otherwise keep counting
          else
            rx_count <= rx_count + 1;
          end if;
        end if;
      end if;
    end process proc_manage_rx_count_from_rx_sop;

    --! Storing the relevant data (yiaddr) from incoming DHCP blindly
    --! secs and ciaddr are rather irrelevant
    proc_extract_yiaddr : process (clk)
    begin
      if rising_edge(clk) then
        if rx_count = 4 then
          offered_yiaddr <= rx_packet_reg.data(63 downto 32);
        else
          offered_yiaddr <= offered_yiaddr;
        end if;
      end if;
    end process proc_extract_yiaddr;

    --! @brief FSM to handle incoming DHCP messages
    --! @details
    --! Analysing incoming data packets and checking them for DHCP content.
    proc_rx_state : process (clk)
    begin

      if rising_edge(clk) then
        -- reset or sof indicate new header
        if (rst = '1') or (dhcp_rx_packet_i.sop = '1') then
          rx_state <= HEADER;
        --elsif dhcp_rx_ready_i = '1' then
        else

          case rx_state is

            -- check header data
            when HEADER =>

              case rx_count is

                when 0 =>
                  rx_state <= HEADER;
                when 1 =>
                  -- check UDP header
                  if rx_packet_reg.data(63 downto 48) /= x"0043" or -- UDP_SRC_PORT 67
                    rx_packet_reg.data(47 downto 32) /= x"0044"     -- UDP_DST_PORT 68
                  then
                    rx_state <= SKIP;
                  else
                    rx_state <= HEADER;
                  end if;
                when 2 =>
                  -- vsg_off if_035 if_009
                  -- check for supported DHCP_HEADER (IPv4 on Ethernet)
                  if rx_packet_reg.data(63 downto 56) /= x"02" or            -- OP code: 02 = BOOTREPLY
                    rx_packet_reg.data(55 downto 48) /= x"01" or             -- htype: IP
                    rx_packet_reg.data(47 downto 40) /= x"06" or             -- hlen: 6 (MAC)
                    rx_packet_reg.data(31 downto 0) /= std_logic_vector(xid) -- XID from previous DISCOVER/REQUEST
                  then
                    rx_state <= SKIP;
                  -- vsg_on if_035 if_009
                  else
                    rx_state <= HEADER;
                  end if;
                when 5 =>
                  -- check chaddr (hw address)
                  if rx_packet_reg.data(31 downto 0) /= my_mac_i(47 downto 16) then
                    rx_state <= SKIP;
                  else
                    rx_state <= HEADER;
                  end if;
                when 6 =>
                  -- check chaddr (hw address)
                  if rx_packet_reg.data(63 downto 48) /= my_mac_i(15 downto 0) then
                    rx_state <= SKIP;
                  else
                    rx_state <= HEADER;
                  end if;

                -- if we made it until here, we finally find DHCP options
                when DHCP_WORDS =>
                  rx_state <= STORING_OPTS;

                -- when 2, 3 => MAC and IP data is copied from reg in process extract_rx_data_copy
                when others =>
                  rx_state <= HEADER;

              end case;

            when STORING_OPTS =>
              -- end of frame concludes package
              if rx_packet_reg.eop = '1' then
                rx_state <= PARSING_OPTS;
              else
                rx_state <= STORING_OPTS;
              end if;

            when PARSING_OPTS =>
              if parse_options_done = '1' then
                rx_state <= SKIP;
              else
                rx_state <= PARSING_OPTS;
              end if;

            -- return to HEADER is done external to this case list
            when SKIP =>
              rx_state <= SKIP;

          end case;

        end if;
      end if;
    end process proc_rx_state;

    --! Extract options

    -- Need to extract (see table 3 of RFC 2131):
    -- - IP address lease time (DHCP OFFER, DHCP ACK)
    --     The time is in units of seconds, and is specified as a 32-bit unsigned integer.
    --     The code for this option is 51, and its length is 4.
    -- - server identifier (DHCP OFFER, DHCP ACK, DHCP NACK)
    --     The identifier is the IP address of the selected server.
    --     The code for this option is 54, and its length is 4.
    --
    -- We must fully parse all options (detecting option code, length and then value)
    -- to be sure not to misparse a value for an option!

    blk_dhcp_rx_options_fifo_handler : block
      --  signals controlling the FIFO data flow
      --! FIFO data in: full frame segment
      signal dhcp_rx_options_fifo_din   : std_logic_vector(63 downto 0);
      --! FIRO write enable
      signal dhcp_rx_options_fifo_wen   : std_logic;
      --! FIFO read enable
      signal dhcp_rx_options_fifo_ren   : std_logic;
      --! FIFO data out: On byte at a time
      signal dhcp_rx_options_fifo_dout  : std_logic_vector(7 downto 0);
      --! FIFO full
      signal dhcp_rx_options_fifo_full  : std_logic;
      --! FIFO empty
      signal dhcp_rx_options_fifo_empty : std_logic;

      --! @brief State definition for the options FIFO FSM
      --! @details
      --! State definition for the FIFO FSM
      --! - IDLE:     Nothing happening
      --! - READ:     First ever read (an option)
      --! - OPTION:   Evaluate option identifier
      --! - LENGTH:   Evaluate length indicator
      --! - VALUE:    Read option value
      type t_option_state is (IDLE, READ, OPTION, LENGTH, VALUE);

      --! State of the FIFO FSM

      -- vsg_disable_next_line signal_007
      signal option_state : t_option_state := IDLE;

      --! Value length indication of the option
      signal value_length : unsigned(7 downto 0);

      --! Buffer for data read from FIFO
      --! Information we are interested in is 4 bytes long, that's 6 with option and length field
      signal value_buffer : std_logic_vector(6*8 - 1 downto 0);

      --! Different options we want to extract
      type t_dhcp_option is (SKIP, OPERATION, LEASE_TIME, SERVER_IP);
      --! Current option being extracted
      signal dhcp_option : t_dhcp_option;

    begin

      --! @brief FIFO to store DHCP options to be sent
      --! @details
      --! FIFO is filled (options section only) once a valid package is received
      --! Storing 16 option words is already on the higher edge.
      inst_dhcp_rx_options_fifo : entity memory.generic_fifo
      generic map (
        -- it's actually not a dual clock, but in order to get different port width working, we need this setting
        DUAL_CLK   => true,
        -- make read data available directly in next clock cycle (default is non-zero in dual clock mode)
        RD_SYNC_STAGES => 0,
        WR_D_WIDTH => 64,
        WR_D_DEPTH => 16,
        RD_D_WIDTH => 8
      )
      port map (
        rst      => rst,
        wr_clk   => clk,
        wr_en    => dhcp_rx_options_fifo_wen,
        wr_data  => dhcp_rx_options_fifo_din,
        rd_clk   => clk,
        rd_en    => dhcp_rx_options_fifo_ren,
        rd_data  => dhcp_rx_options_fifo_dout,
        rd_full  => dhcp_rx_options_fifo_full,
        rd_empty => dhcp_rx_options_fifo_empty
      );

      --! @brief Store options in each cycle of rx_state = STORING_OPTS
      --! @details Options are stored (each cycle of rx_state = STORING_OPTS) to FIFO
      --! Data is treated first to:
      --! - Replace any trailing data (at eof, indicated by empty) with zeros
      --!   in order to not confuse the option parser
      --! - swapping the byte order due to the way the FIFO reads the bytes back
      proc_write_fifo : process(clk)
        -- Actual data being stored into the FIFO
        variable rx_data : rx_packet_reg.data'subtype;
      begin
        if rising_edge(clk) then
          if rx_state = STORING_OPTS then

            rx_data := (others => '0');
            if to_integer(rx_packet_reg.empty) > 0 then
              for i in rx_packet_reg.data'high downto 8 * to_integer(rx_packet_reg.empty) loop
                rx_data(i) := rx_packet_reg.data(i);
              end loop;
            else
              rx_data := rx_packet_reg.data;
            end if;

            dhcp_rx_options_fifo_din <= swap(rx_data, 8);
            dhcp_rx_options_fifo_wen <= '1';
          else
            dhcp_rx_options_fifo_din <= (others => '0');
            dhcp_rx_options_fifo_wen <= '0';
          end if;
        end if;
      end process proc_write_fifo;

      --! @brief Options FIFO reading
      --! @details Reading the Options FIFO continuously as long as it's not empty
      --! (it cannot run empty during one packet as we write continuously)
      --! and dump data from FIFO into worded shift register (for later use)
      proc_read_fifo : process (clk)
      begin
        if rising_edge(clk) then
          dhcp_rx_options_fifo_ren <= not dhcp_rx_options_fifo_empty;

          value_buffer <= value_buffer(39 downto 0) & dhcp_rx_options_fifo_dout;
        end if;
      end process proc_read_fifo;

      --! @brief Parsing of DHCP options
      --! @details Option handling happens via cycling trough OPTION-LENGTH-VALUE.
      --! The FIFO output word is looked at.
      --! The OPTION state allows further processes to interpret the actual option (data from FIFO).
      --! Finally we use value_length = 0 to indicate that an option is fully read (for further processes).
      proc_parse_options : process (clk)
      begin
        if rising_edge(clk) then

          -- defaults:
          value_length       <= x"01";
          parse_options_done <= '0';

          -- TODO: Think about this: Do we need to be sensitive to rst, or would it work anyway?
          --if rst = '1' then
          --  option_state <= IDLE;
          --else

          case option_state is

            when IDLE =>
              -- start reading from FIFO as soon as options are available
              if dhcp_rx_options_fifo_empty = '0' then
                option_state <= READ;
              else
                option_state <= IDLE;
              end if;

            when READ =>
              option_state <= OPTION;

            when OPTION =>
              -- Watch out for end of options at large ...
              if dhcp_rx_options_fifo_empty = '1' then
                option_state <= IDLE;

                parse_options_done <= '1';
              -- but check for padding bytes: simply skip and interpret next byte as option
              -- note order of prio: If empty is seen and x"00" at the same time, that simply means there is no more data to read
              elsif dhcp_rx_options_fifo_dout = x"00" then
                option_state <= OPTION;
              else
                option_state <= LENGTH;
              end if;

            when LENGTH =>
              value_length <= unsigned(dhcp_rx_options_fifo_dout);

              option_state <= VALUE;

            when VALUE =>
              if value_length > 1 then
                value_length <= value_length - 1;

                option_state <= VALUE;
              else
                value_length <= (others => '0');

                -- and here goes the setting of the options that we plan to extract
                -- data is now available in value_buffer

                if dhcp_rx_options_fifo_empty = '1' then
                  option_state <= IDLE;

                  parse_options_done <= '1';
                else
                  option_state <= OPTION;
                end if;
              end if;

          end case;

        end if;
      end process proc_parse_options;

      --! Detect the useful (supported) DHCP option
      proc_detect_option : process(clk)
      begin
        if rising_edge(clk) then
          -- default:
          dhcp_option <= dhcp_option;

          -- only once an option is read, interpret it
          if option_state = OPTION then
            case dhcp_rx_options_fifo_dout is
              when x"35" => -- DHCP operation
                dhcp_option <= OPERATION;
              when x"33" => -- IP address lease time
                dhcp_option <= LEASE_TIME;
              when x"36" => -- server identifier
                dhcp_option <= SERVER_IP;
              when others =>
                dhcp_option <= SKIP;
            end case;
          end if;
        end if;
      end process proc_detect_option;

      -- Now we can individually extract the data that we look for

      --! Extract all relevant DHCP options
      proc_extract_dhcp_options : process(clk)
      begin
        if rising_edge(clk) then
          -- options are fully read once the value length has reached 0
          if value_length = 0 then
            -- not using case construct here on purpose as individual cases do actually set independent targets
            if dhcp_option = OPERATION then
              dhcp_operation <= value_buffer(3 downto 0);
            end if;

            if dhcp_option = LEASE_TIME then
              dhcp_lease_time <= value_buffer(31 downto 0);
            end if;

            if dhcp_option = SERVER_IP then
              dhcp_server_ip <= value_buffer(31 downto 0);
            end if;
          end if;
        end if;
      end process proc_extract_dhcp_options;

    end block blk_dhcp_rx_options_fifo_handler;

    --! Finally evaluate the received packet once parsing is done
    proc_evaluate_rx_packet : process(clk)
    begin
      if rising_edge(clk) then
        if parse_options_done = '1' then
          -- check (relevant) DHCP message type:
          --   2: DHCPOFFER
          --   5: DHCPACK
          --   6: DHCPNAK
          if dhcp_operation = x"2" then
            -- we have a valid offer, so we can accept it
            -- note: We just accept the first offer if we're still in SELECTING
            if dhcp_state = SELECTING then
              dhcp_offer_selected <= '1';

              -- also set the options we need to include in the request
              yourid        <= offered_yiaddr;
              serverid      <= dhcp_server_ip;
              -- TODO: check again if we have to calculate back to initial discover time ...
              my_lease_time <= dhcp_lease_time;
            end if;
          end if;
        end if;
      end if;
    end process proc_evaluate_rx_packet;

  end block blk_make_rx_interface;

  -- Handling of ARP requests to the ARP table:
  --
  -- First, look up the requested IP in ARP table.
  -- If found, put out,
  -- if not found, initiate ARP request.
  blk_arp_table : block
    --! @brief Status vector of the ARP table
    --! @details
    --! - 1: ARP table full
    --! - 0: ARP table empty
    signal arptbl_status_vector : std_logic_vector(1 downto 0);

    --! @name signals decoupling ARP table from outer interface
    --! @{

    --! Indicator for recovering IP address
    signal reco_en_r       : std_logic;
    --! ip address to recover
    signal reco_ip_r       : std_logic_vector(31 downto 0);
    --! recovered mac address
    signal reco_mac_r      : std_logic_vector(47 downto 0);
    --! valid flag for recovered mac address: 1 = found, 0 = time out
    signal reco_found_r    : std_logic;
    --! timeout indication
    signal request_timeout : std_logic;
    --! @}

    --! @brief State definition for the ARP table FSM
    --! @details
    --! State definition for the ARP table FSM
    --! - IDLE:               Nothing happening
    --! - ARP_TABLE_REQUEST:  Request ARP recovery
    --! - ARP_TABLE_READ:     Read ARP table
    --! - ARP_WAIT_RESPONSE:  Wait for ARP response
    type   t_request_state is (IDLE, ARP_TABLE_REQUEST, ARP_TABLE_READ, ARP_WAIT_RESPONSE);
    --! State of the ARP table FSM
    signal request_state : t_request_state;

    --! Broadcast MAC address for ARP request
    constant MAC_BROADCAST_ADDR : std_logic_vector(47 downto 0) := (others => '1');
  begin

    status_vector_o(4 downto 3) <= arptbl_status_vector;

    --! FSM to request MAC address.
    proc_mac_address_request : process (clk)
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          request_state <= IDLE;
          reco_en_r     <= '0';
          reco_ip_r     <= (others => '0');
          reco_mac_o    <= (others => '0');
          reco_done_o   <= '0';
          request_en    <= '0';
        else
          -- defaults
          reco_en_r   <= '0';
          reco_ip_r   <= reco_ip_r;
          reco_done_o <= '0';

          case request_state is

            when IDLE =>
              request_en <= '0';
              if reco_en_i = '1' then
                reco_en_r <= '1';
                reco_ip_r <= reco_ip_i;

                request_state <= ARP_TABLE_REQUEST;
              else
                request_state <= IDLE;
              end if;

            when ARP_TABLE_REQUEST =>
              request_state <= ARP_TABLE_READ;

            when ARP_TABLE_READ =>
              if reco_found_r = '1' then
                -- take IP address from table
                reco_mac_o  <= reco_mac_r;
                reco_done_o <= '1';

                request_state <= IDLE;
              else
                -- initiate ARP request
                request_en <= '1';
                request_ip <= reco_ip_r;

                request_state <= ARP_WAIT_RESPONSE;
              end if;

            when ARP_WAIT_RESPONSE =>
              reco_en_r <= '1';

              if reco_found_r = '1' then
                -- take ip address from table
                reco_mac_o  <= reco_mac_r;
                reco_done_o <= '1';
                request_en  <= '0';

                request_state <= IDLE;
              elsif request_timeout = '1' then
                reco_mac_o  <= MAC_BROADCAST_ADDR;
                reco_done_o <= '1';
                request_en  <= '0';

                request_state <= IDLE;
              else
                request_state <= ARP_WAIT_RESPONSE;
              end if;

          end case;

        end if;
      end if;
    end process proc_mac_address_request;

    blk_request_timout : block
      --! @name Signals to steer request_timeout
      --! @{

      --! counter reset
      signal cnt_rst : std_logic;
      --! counter enable
      signal cnt_en  : std_logic;
      --! @}
    begin

      cnt_rst <= '1' when request_state = ARP_TABLE_READ else '0';
      cnt_en  <= '1' when one_ms_tick_i = '1' and request_state = ARP_WAIT_RESPONSE else '0';

      --! Instantiate counting to generate request_timeout
      inst_request_timeout_counter : entity misc.counting
      generic map (
        COUNTER_MAX_VALUE => DHCP_TIMEOUT
      )
      port map (
        clk => clk,
        rst => cnt_rst,
        en  => cnt_en,

        cycle_done => request_timeout
      );

    end block blk_request_timout;

    --! Instantiate port_io_table as ARP table
    inst_arp_table : entity xgbe_lib.port_io_table
    generic map (
      -- IP
      PORT_I_W    => 32,
      -- MAC
      PORT_O_W    => 48,
      -- Depth
      TABLE_DEPTH => DHCP_TABLE_DEPTH
    )
    port map (
      clk             => clk,
      rst             => rst,
      -- Interface for writing new discovered MAC and IP to ARP table
      disco_wren_i    => disco_wren,
      disco_port_i    => disco_ip,
      disco_port_o    => disco_mac,
      -- interface for recovered mac address from given ip address
      reco_en_i       => reco_en_r,
      reco_port_i     => reco_ip_r,
      -- response (next clk)
      reco_found_o    => reco_found_r,
      reco_port_o     => reco_mac_r,
      -- status of the ARP table, see definitions below
      status_vector_o => arptbl_status_vector
      -- one could make the move to indicate the number of occupied entries instead...
      -- that would make status_vector_o a table_depth-dependent length vector
    );

  end block blk_arp_table;

end architecture behavioral;
