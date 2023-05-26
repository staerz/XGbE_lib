-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief IPbus reset responder
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details
--! Watches out for a reset request being sent via IPbus and generates a
--! response.
--! The full Ethernet packet is expected (rx) and constructed (tx).
--!
--! IPbus write transactions on RESET_REGISTER_ADD with WRITE_SIZE = 1 are
--! interpreted as reset request.
--!
--! The module is to be connected in parallel to the incoming data stream
--! and should have first priority on the TX interface merger.
--!
--! Addresses and ports for self-configuration have to be always provided:
--!   - my_mac_i: Ethernet MAC address
--!   - my_ip_i: IP address
--!   - my_udp_port_i: UDP port
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! IPbus reset responder
entity reset_module is
  generic (
    --! Reset duration for rst_o in clk cycles
    RESET_DURATION     : positive               := 10;
    --! Width of rst_o
    RESET_WIDTH        : positive range 1 to 32 := 1;
    --! IPbus address of the reset register
    RESET_REGISTER_ADD : std_logic_vector(31 downto 0)
  );
  port (
    --! Clock
    clk             : in    std_logic;
    --! Reset, sync with #clk
    rst             : in    std_logic;

    --! @name Avalon-ST from reset requester
    --! @{

    --! RX ready
    rx_ready_o      : out   std_logic;
    --! RX data and controls
    rx_packet_i     : in    t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @name Avalon-ST to reset requester
    --! @{

    --! TX ready
    tx_ready_i      : in    std_logic;
    --! TX data and controls
    tx_packet_o     : out   t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @name Configuration of the module
    --! @{

    --! MAC address
    my_mac_i        : in    std_logic_vector(47 downto 0);
    --! IP address
    my_ip_i         : in    std_logic_vector(31 downto 0);
    --! UDP port
    my_udp_port_i   : in    std_logic_vector(15 downto 0);
    --! @}

    --! Reset output
    rst_o           : out   std_logic_vector(RESET_WIDTH - 1 downto 0);

    --! @brief Status of the module
    --! @details Status of the module
    --! - 2: Reset in progress
    --! - 1: Reset response is being sent
    --! - 0: Reset receiver is not ready
    status_vector_o : out   std_logic_vector(2 downto 0)
  );
end entity reset_module;

--! @cond
library IEEE;
  use IEEE.numeric_std.all;

library misc;
--! @endcond

--! Implementation of the IPbus reset responder
architecture behavioral of reset_module is

  --! Reset initiation once a reset request has been recovered
  signal init_reset : std_logic;

  --! @name Ethernet configuration of the reset requester
  --! @{

  --! MAC address
  signal tg_mac : std_logic_vector(47 downto 0);
  --! IP address
  signal tg_ip  : std_logic_vector(31 downto 0);
  --! UDP port
  signal tg_udp : std_logic_vector(15 downto 0);
  --! @}

  --! @name Information on the requesting IPbus packet
  --! @{

  --! Packet ID
  signal ipbus_packet_id    : std_logic_vector(15 downto 0);
  --! Transaction ID
  signal ipbus_trans_id     : std_logic_vector(11 downto 0);
  --! Number of words
  signal ipbus_number_words : std_logic_vector(7 downto 0);
  --! Packet endianness
  signal ipbus_big_endian   : std_logic;
  --! @}

  --! Decoded soft resets from reset request
  signal soft_resets : std_logic_vector(31 downto 0);

  --! function to swap bytes from little to big endian (used for IPbus)

  function twist32 (arg: std_logic_vector(31 downto 0); twist: std_logic) return std_logic_vector is
  begin

    if twist = '1' then
      return arg(7 downto 0) & arg(15 downto 8) & arg(23 downto 16) & arg(31 downto 24);
    else
      return arg;
    end if;

  end;

begin

  -- Transmitter part
  blk_make_tx_interface : block
    --! Counter for outgoing response packet

    -- vsg_disable_next_line signal_007
    signal tx_count : unsigned(4 downto 0) := (others => '1');
  begin

    status_vector_o(0) <= '1' when tx_ready_i = '0' else '0';
    status_vector_o(1) <= '1' when to_integer(tx_count) >= 1 and to_integer(tx_count) <= 7 else '0';

    --  tx_packet_o   <= see state machine;

    tx_packet_o.valid <= '1' when to_integer(tx_count) >= 1 and to_integer(tx_count) <= 7 else '0';
    tx_packet_o.sop   <= '1' when to_integer(tx_count) = 1 else '0';
    tx_packet_o.eop   <= '1' when to_integer(tx_count) = 7 else '0';
    tx_packet_o.error <= "0";

    with to_integer(tx_count) select tx_packet_o.empty <=
      "000" when 1 to 6,
      "010" when 7,
      "000" when others;

    --! @brief Counting the clock cycles being in the sending mode
    --! (the packets of 8 bytes to be sent)
    proc_cnt : process (clk)
    begin
      if rising_edge(clk) then
        if init_reset = '1' then
          tx_count <= (others => '0');
        -- keep counting otherwise
        elsif tx_ready_i = '1' and tx_count(tx_count'left) = '0' then
          tx_count <= tx_count + 1;
        else
          tx_count <= tx_count;
        end if;
      end if;
    end process proc_cnt;

    blk_gen_tx_data : block
      --! @name Protocol internals of the IPbus
      --! @{

      --! Length of the datagram
      constant IP_LENGTH  : std_logic_vector(15 downto 0) := x"0024";
      --! IPbus ID
      constant IP_ID      : std_logic_vector(15 downto 0) := x"1234";
      --! Time to live and protocol
      constant IP_TTLPROT : std_logic_vector(15 downto 0) := x"4011";
      --! @}

      --! IPbus CRC
      signal ip_crc_out : std_logic_vector(15 downto 0);

      --! @name Intermediate data words
      --! @{

      --! IPbus word 1
      signal ipbus_word_1 : std_logic_vector(31 downto 0);
      --! IPbus word 2
      signal ipbus_word_2 : std_logic_vector(31 downto 0);
      --! IPbus word 3
      signal ipbus_word_3 : std_logic_vector(31 downto 0);
    --! @}
    begin

      -- Create reset response packet as the complete Ethernet packet
      -- vsg_off comment_010
      with to_integer(tx_count) select tx_packet_o.data <=
        -- destination mac (6 bytes)
        tg_mac &
        -- + first 2 bytes source mac
        my_mac_i(47 downto 32)
          when 1,
        -- last 4 bytes source mac
        my_mac_i(31 downto 0) &
        -- packet type: ip = x"0800"
        x"0800" &
        -- type of service
        x"4500"
          when 2,
        -- length ... is constant as write is only confirmed
        IP_LENGTH &
        -- id
        IP_ID &
        -- fragmentation
        x"0000" &
        -- ttl and protocol
        IP_TTLPROT
          when 3,
        -- IP CRC
        ip_crc_out &
        -- source IP address
        my_ip_i &
        -- destination IP address (upper part)
        tg_ip(31 downto 16)
          when 4,
        -- destination IP address (lower part)
        tg_ip(15 downto 0) &
        -- source UDP port
        my_udp_port_i &
        -- destination UDP port
        tg_udp &
        -- UDP length ... is constant as write is only confirmed
        x"0010"
          when 5,
        -- optional UDP CRC
        x"0000" &
        -- 1st IPbus word
        ipbus_word_1 &
        -- 2nd IPbus word (upper part)
        ipbus_word_2(31 downto 16)
          when 6,
        -- 2nd IPbus word (lower part)
        ipbus_word_2(15 downto 0) &
        -- 3rd IPbus word
        ipbus_word_3 &
        x"0000"
          when 7,
        (others => '0')
          when others;

      -- vsg_on comment_010
      -- actually setting the IPbus data to be transmitted according to endianness
      -- IPbus packet header
      ipbus_word_1 <= twist32(x"20" & ipbus_packet_id & x"f0", ipbus_big_endian);
      -- Transaction header
      ipbus_word_2 <= twist32(x"2" & ipbus_trans_id & ipbus_number_words & x"10", ipbus_big_endian);
      -- Read address
      ipbus_word_3 <= twist32(RESET_REGISTER_ADD, ipbus_big_endian);

      -- main code taken from ip_header_module, but be aware of data shift
      blk_calculate_ip_header_crc : block
        --! Cumulative IP CRCn (data flowing in)
        signal ip_header_before_crc : std_logic_vector(63 downto 0);
        --! Reset of CRC calculation
        signal ip_crc_rst           : std_logic;
      begin

        -- Consider the IP header when creating the packet
        with to_integer(tx_count) select ip_header_before_crc <=
          x"4500" & IP_LENGTH & IP_ID & x"0000" when 1,
          IP_TTLPROT & x"0000" & my_ip_i when 2,
          tg_ip & x"0000_0000" when 3,
          (others => '0') when others;

        -- Reset the CRC calculation initially
        with to_integer(tx_count) select ip_crc_rst <=
          '1' when 0,
          '0' when others;

        --! Instantiate checksum_calc to calculate IP CRC
        inst_crc_calc : entity misc.checksum_calc
        generic map (
          I_WIDTH => 64,
          O_WIDTH => 16
        )
        port map (
          clk     => clk,
          en      => tx_ready_i,
          rst     => ip_crc_rst,
          data_in => ip_header_before_crc,
          sum_out => ip_crc_out
        );

      end block blk_calculate_ip_header_crc;

    end block blk_gen_tx_data;

  end block blk_make_tx_interface;

  -- once recovered, generate the reset output signal
  blk_make_reset : block
    --! @name Signals to create the reset for a given RESET_DURATION
    --! @{

    --! Counter enable

    -- vsg_disable_next_line signal_007
    signal cnt_en   : std_logic := '0';
    --! Counter end
    signal cnt_done : std_logic;
  --! @}
  begin

    --! Create cnt_en
    proc_cnt_en : process (clk)
    begin
      if rising_edge(clk) then
        if init_reset = '1' then
          -- enable reset counter
          cnt_en <= '1';
        elsif cnt_done = '1' then
          -- disable after duration
          cnt_en <= '0';
        else
          -- stay in current state
          cnt_en <= cnt_en;
        end if;
      end if;
    end process proc_cnt_en;

    --! Instantiate counting to generate reset of duration RESET_DURATION
    inst_reset_cnt : entity misc.counting
    generic map (
      COUNTER_MAX_VALUE => RESET_DURATION
    )
    port map (
      clk => clk,
      rst => init_reset,
      en  => cnt_en,

      cycle_done => cnt_done
    );

    rst_o <= soft_resets(RESET_WIDTH - 1 downto 0) when cnt_en = '1' else (others => '0');

  end block blk_make_reset;

  -- Receiver part
  blk_make_rx_interface : block

    --! @brief State definition for the RX FSM
    --! @details
    --! State definition for the RX FSM
    --! - IDLE:       no transmission running
    --! - HEADER:     header is being analysed (and still valid)
    --! - SKIP:       packet is skipped until eop (due to invalid header data)
    --! - RESETTING:  reset is successfully recognised
    type t_rx_state is (IDLE, HEADER, SKIP, RESETTING);

    --! State of the RX FSM

    -- vsg_disable_next_line signal_007
    signal rx_state : t_rx_state := IDLE;

    --! Internal ready
    signal rx_ready   : std_logic;
    --! Internal valid (delayed)
    signal rx_valid_d : std_logic;

    --! Counter for incoming packet
    -- vsg_disable_next_line signal_007
    signal rx_count : unsigned(7 downto 0) := to_unsigned(0, 8);

    --! @name Registers for receiving data
    --! @{

    --! 0th-level register
    signal rx_data_reg  : std_logic_vector(63 downto 0);
    --! 1st-level register
    signal rx_data_reg1 : std_logic_vector(63 downto 0);
    --! 2nd-level register
    signal rx_data_reg2 : std_logic_vector(63 downto 0);
    --! @}
    --! RX control signals
    signal rx_ctrl_reg  : std_logic_vector(6 downto 0);

    --! @name Registers to extract relevant data from incoming (reset) packets
    --! these signals serve the tx path and are extracted blindly
    --! @{

    --! Target MAC address
    signal rx_data_copy_tg_mac       : std_logic_vector(47 downto 0);
    --! Target IP address
    signal rx_data_copy_tg_ip        : std_logic_vector(31 downto 0);
    --! Target UDP port
    signal rx_data_copy_tg_udp       : std_logic_vector(15 downto 0);
    --! Target IPbus packet ID
    signal rx_data_copy_packet_id    : std_logic_vector(15 downto 0);
    --! Target IPbus transaction ID
    signal rx_data_copy_trans_id     : std_logic_vector(11 downto 0);
    --! Target IPbus number of words
    signal rx_data_copy_number_words : std_logic_vector(7 downto 0);
  --! @}
  begin

    status_vector_o(2) <= '1' when rx_state = RESETTING else '0';

    -- receiver is always ready
    rx_ready <= '1';

    rx_ready_o <= rx_ready;

    --! @brief Transfer of recovered IDs to signals for TX FSM
    proc_initiate_reset : process (clk)
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          init_reset         <= '0';
          tg_mac             <= (others => '0');
          tg_ip              <= (others => '0');
          tg_udp             <= (others => '0');
          ipbus_packet_id    <= (others => '0');
          ipbus_trans_id     <= (others => '0');
          ipbus_number_words <= (others => '0');
        else
          if rx_state = RESETTING then
            init_reset         <= '1';
            tg_mac             <= rx_data_copy_tg_mac;
            tg_ip              <= rx_data_copy_tg_ip;
            tg_udp             <= rx_data_copy_tg_udp;
            ipbus_packet_id    <= rx_data_copy_packet_id;
            ipbus_trans_id     <= rx_data_copy_trans_id;
            ipbus_number_words <= rx_data_copy_number_words;
          else
            init_reset         <= '0';
            tg_mac             <= tg_mac;
            tg_ip              <= tg_ip;
            tg_udp             <= tg_udp;
            ipbus_packet_id    <= ipbus_packet_id;
            ipbus_trans_id     <= ipbus_trans_id;
            ipbus_number_words <= ipbus_number_words;
          end if;
        end if;
      end if;
    end process proc_initiate_reset;

    --! Introduce delay of rx_packet_i.valid to keep counting one packet after the packet
    proc_rx_valid_d : process (clk)
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          rx_valid_d <= '0';
        else
          rx_valid_d <= rx_packet_i.valid;
        end if;
      end if;
    end process proc_rx_valid_d;

    --! Counting the packets of 8 bytes received
    proc_manage_rx_count_from_rx_sop : process (clk)
    begin
      if rising_edge(clk) then
        -- reset counter
        if (rst = '1') then
          rx_data_reg      <= (others => '0');
          rx_count         <= (others => '0');
          ipbus_big_endian <= '0';
        elsif (rx_packet_i.valid = '1' or rx_valid_d = '1') and rx_ready = '1' then
          -- ... sop initializes counter and endian-ness
          if rx_packet_i.sop = '1' then
            -- rx_count <= to_unsigned(1, 8);
            -- with new reg stage, make it from 0
            rx_count         <= to_unsigned(0, 8);
            ipbus_big_endian <= '0';
          elsif rx_count(rx_count'left) = '0' then
            -- ... otherwise keep counting, but only until maximum value given by width
            rx_count <= rx_count + 1;
          else
            rx_count <= rx_count;
          end if;

          -- watch out for endianness
          if rx_count = 4 then
            -- IPbus packet header in little-endian
            -- IPbus protocol version 2
            -- endianness and control packet
            if rx_packet_i.data(47 downto 40) = x"20" and
               rx_packet_i.data(23 downto 16) = x"f0" then
              ipbus_big_endian <= '0';
            elsif rx_packet_i.data(47 downto 40) = x"f0" and
              -- or in big-endian
                  rx_packet_i.data(23 downto 16) = x"20" then
              ipbus_big_endian <= '1';
            end if;
          end if;

          rx_ctrl_reg  <= avst_ctrl(rx_packet_i);
          rx_data_reg1 <= rx_packet_i.data;
          rx_data_reg2 <= rx_data_reg1;
          -- if required, twist 32 bit words of IPbus
          if ipbus_big_endian = '1' then
            if rx_count = 5 then
              rx_data_reg(63 downto 48) <= rx_data_reg1(63 downto 48);
              rx_data_reg(47 downto 16) <= twist32(rx_data_reg1(47 downto 16), '1');
              rx_data_reg(15 downto  8) <= rx_packet_i.data(55 downto 48);
              rx_data_reg( 7 downto  0) <= rx_packet_i.data(63 downto 56);
            else
              rx_data_reg(63 downto 56) <= rx_data_reg2( 7 downto 0);
              rx_data_reg(55 downto 48) <= rx_data_reg2(15 downto 8);
              rx_data_reg(47 downto 16) <= twist32(rx_data_reg1(47 downto 16), '1');
              rx_data_reg(15 downto  8) <= rx_packet_i.data(55 downto 48);
              rx_data_reg( 7 downto  0) <= rx_packet_i.data(63 downto 56);
            end if;
          else
            rx_data_reg <= rx_data_reg1;
          end if;
        end if;
      end if;
    end process proc_manage_rx_count_from_rx_sop;

    --! @brief Retrieve relevant data from the reset packet blindly.
    --! @details Data will be applied only if it actually was a reset request.
    proc_extract_rx_data_copy : process (clk)
    begin
      if rising_edge(clk) then
        -- check whether request or response
        -- default: keep data in registers:
        rx_data_copy_tg_mac       <= rx_data_copy_tg_mac;
        rx_data_copy_tg_ip        <= rx_data_copy_tg_ip;
        rx_data_copy_tg_udp       <= rx_data_copy_tg_udp;
        rx_data_copy_packet_id    <= rx_data_copy_packet_id;
        rx_data_copy_trans_id     <= rx_data_copy_trans_id;
        rx_data_copy_number_words <= rx_data_copy_number_words;

        case to_integer(rx_count) is

          when 1 =>
            -- first part of src mac in rx, will be dst mac on tx
            rx_data_copy_tg_mac(47 downto 32) <= rx_data_reg(15 downto 0);

          when 2 =>
            -- second part of src mac in rx, will be dst mac on tx
            rx_data_copy_tg_mac(31 downto 0) <= rx_data_reg(63 downto 32);

          when 4 =>
            rx_data_copy_tg_ip <= rx_data_reg(47 downto 16);

          when 5 =>
            rx_data_copy_tg_udp <= rx_data_reg(47 downto 32);

          when 6 =>
            rx_data_copy_packet_id <= rx_data_reg(39 downto 24);
            rx_data_copy_trans_id  <= rx_data_reg(11 downto 0);

          when 7 =>
            -- should be x01
            rx_data_copy_number_words <= rx_data_reg(63 downto 56);

          when others =>
            null;

        end case;

      end if;
    end process proc_extract_rx_data_copy;

    --! @brief RX FSM to handle reset requests
    --! @details Analyses incoming data packets and checks them for reset content.
    proc_rx_fsm : process (clk)
    begin

      if rising_edge(clk) then
        -- reset goes to IDLE
        if (rst = '1') then
          rx_state    <= IDLE;
          soft_resets <= (others => '0');
        else

          case rx_state is

            when IDLE =>
              -- check for start of packet
              if rx_packet_i.sop = '1' then
                rx_state <= HEADER;
              else
                rx_state <= IDLE;
              end if;

            when HEADER =>
              -- check header data
              -- default:
              rx_state <= HEADER;

              case to_integer(rx_count) is

                when 0 =>
                  rx_state <= HEADER;

                when 1 =>
                  -- require proper mac address
                  if rx_data_reg(63 downto 16) /= my_mac_i then
                    rx_state <= SKIP;
                  end if;

                when 2 =>
                  -- require ip protocol
                  if rx_data_reg(31 downto 16) /= x"0800" then
                    rx_state <= SKIP;
                  end if;

                when 3 =>
                  -- no more fragments or udp
                  if rx_data_reg(29) /= '0' or rx_data_reg(7 downto 0) /= x"11" then
                    rx_state <= SKIP;
                  end if;

                when 4 =>
                  if rx_data_reg(15 downto 0) /= my_ip_i(31 downto 16) then
                    rx_state <= SKIP;
                  end if;

                when 5 =>
                  if rx_data_reg(63 downto 48) /= my_ip_i(15 downto 0) or
                     rx_data_reg(31 downto 16) /= my_udp_port_i
                     then
                    rx_state <= SKIP;
                  end if;

                when 6 =>
                  -- IPbus packet header
                  -- IPbus protocol version 2 (big or little endian)
                  if rx_data_reg(47 downto 40) /= x"20" or
                     rx_data_reg(23 downto 16) /= x"f0" or
                    -- IPbus protocol version 2
                     rx_data_reg(15 downto 12) /= x"2"
                     then
                    rx_state <= SKIP;
                  end if;

                when 7 =>
                  -- write_size = 1 -> number_words
                  if rx_data_reg(63 downto 56) /= x"01" or
                    -- type id = 1 (write), infocode = x"f"
                     rx_data_reg(55 downto 48) /= x"1f" or
                    -- IPbus base_address
                     rx_data_reg(47 downto 16) /= RESET_REGISTER_ADD
                     then
                    rx_state <= SKIP;
                  else
                    -- error indication
                    if rx_ctrl_reg(4) = '1' and rx_ctrl_reg(3) = '0' then
                      rx_state                  <= RESETTING;
                      soft_resets(31 downto 16) <= rx_data_reg(15 downto 0);
                    else
                      rx_state <= HEADER;
                    end if;
                  end if;

                when others =>
                  -- may be padded: wait for eop
                  -- error indication
                  if rx_ctrl_reg(4) = '1' and rx_ctrl_reg(3) = '0' then
                    rx_state <= RESETTING;
                  end if;

              end case;

            -- once all requirements are fulfilled, reset
            when RESETTING =>
              soft_resets(15 downto 0) <= rx_data_reg(63 downto 48);
              rx_state                 <= IDLE;

            -- just let pass all other data, wait for eop
            when SKIP =>
              if rx_packet_i.eop = '1' then
                rx_state <= IDLE;
              end if;

          end case;

        end if;
      end if;
    end process proc_rx_fsm;

  end block blk_make_rx_interface;

end architecture behavioral;
