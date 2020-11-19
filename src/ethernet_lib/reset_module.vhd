-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief IPbus reset responder
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details
--! Watches out for a reset request being sent via IPbus and generates a
--! response.
--! The full Ethernet frame is expected (rx) and constructed (tx).
--!
--! IPbus write transactions on RESET_REGISTER_ADD with WRITE_SIZE = 1 are
--! interpreted as reset request.
--!
--! The module is to be connected in parallel to the incoming data stream
--! and should have first priority on the TX interface merger.
--!
--! Addresses and ports for self-configuration have to be always provided:
--!   - my_mac: Ethernet MAC address
--!   - my_ip: IP address
--!   - my_udp_port: UDP port
-------------------------------------------------------------------------------

--! @cond
library ieee;
  use ieee.std_logic_1164.all;
--! @endcond

--! IPbus reset responder
entity reset_module is
  generic (
    --! Reset duration for rst_out in clk cycles
    RESET_DURATION      : positive               := 10;
    --! Width of rst_out
    RESET_WIDTH         : positive range 1 to 32 := 1;
    --! IPbus address of the reset register
    RESET_REGISTER_ADD  : std_logic_vector(31 downto 0)
  );
  port (
    --! Clock
    clk           : in    std_logic;
    --! Reset, sync with #clk
    rst           : in    std_logic;

    --! @name Avalon-ST from reset requester
    --! @{

    --! RX ready
    rst_rx_ready  : out   std_logic;
    --! RX data
    rst_rx_data   : in    std_logic_vector(63 downto 0);
    --! RX controls
    rst_rx_ctrl   : in    std_logic_vector(6 downto 0);
    --! @}

    --! @name Avalon-ST to reset requester
    --! @{

    --! TX ready
    rst_tx_ready  : in    std_logic;
    --! TX data
    rst_tx_data   : out   std_logic_vector(63 downto 0);
    --! TX controls
    rst_tx_ctrl   : out   std_logic_vector(6 downto 0);
    --! @}

    --! @name Configuration of the module
    --! @{

    --! MAC address
    my_mac        : in    std_logic_vector(47 downto 0);
    --! IP address
    my_ip         : in    std_logic_vector(31 downto 0);
    --! UDP port
    my_udp_port   : in    std_logic_vector(15 downto 0);
    --! @}

    --! Reset output
    rst_out       : out   std_logic_vector(RESET_WIDTH-1 downto 0);

    --! @brief Status of the module
    --! @details Status of the module
    --! - 2: Reset in progress
    --! - 1: Reset response is being sent
    --! - 0: Reset receiver is not ready
    status_vector : out   std_logic_vector(2 downto 0)
  );
end reset_module;

--! @cond
library ieee;
  use ieee.numeric_std.all;

library misc;
--! @endcond

--! Implementation of the IPbus reset responder

architecture behavioral of reset_module is

  --! Reset initiation once a reset request has been recovered
  signal init_reset     : std_logic := '0';

  --! @name Ethernet configuration of the reset requester
  --! @{

  --! MAC address
  signal tg_mac       : std_logic_vector(47 downto 0) := (others => '0');
  --! IP address
  signal tg_ip        : std_logic_vector(31 downto 0) := (others => '0');
  --! UDP port
  signal tg_udp       : std_logic_vector(15 downto 0) := (others => '0');
  --! @}

  --! @name Information on the requesting IPbus packet
  --! @{

  --! Packet ID
  signal ipbus_packet_id    : std_logic_vector(15 downto 0) := (others => '0');
  --! Transaction ID
  signal ipbus_trans_id   : std_logic_vector(11 downto 0) := (others => '0');
  --! Number of words
  signal ipbus_number_words : std_logic_vector(7 downto 0) := (others => '0');
  --! Packet endianness
  signal ipbus_big_endian   : std_logic := '0';
  --! @}

  --! Decoded soft resets from reset request
  signal soft_resets      : std_logic_vector(31 downto 0);

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
  make_tx_interface : block
    --! Counter for outgoing response frame
    signal tx_count       : unsigned(4 downto 0) := (others => '1');

  begin
    status_vector(0) <= '1' when rst_tx_ready = '0' else '0';
    status_vector(1) <= '1' when to_integer(tx_count) >= 1 and to_integer(tx_count) <= 7 else '0';

    --  rst_tx_data   <= see state machine;

    rst_tx_ctrl(6)  <= '1' when to_integer(tx_count) >= 1 and to_integer(tx_count) <= 7 else '0';
    rst_tx_ctrl(5)  <= '1' when to_integer(tx_count) = 1 else '0';
    rst_tx_ctrl(4)  <= '1' when to_integer(tx_count) = 7 else '0';
    rst_tx_ctrl(3)  <= '0';

    with to_integer(tx_count) select rst_tx_ctrl(2 downto 0) <=
      "000" when 1 to 6,
      "010" when 7,
      "000" when others;

    --! @brief Counting the clock cycles being in the sending mode
    --! (the frames of 8 bytes to be sent)
    proc_cnt : process (clk) is
    begin
      if rising_edge(clk) then
        if init_reset = '1' then
          tx_count <= (others => '0');
        -- keep counting otherwise
        elsif rst_tx_ready = '1' and tx_count(tx_count'left) = '0' then
          tx_count <= tx_count + 1;
        else
          tx_count <= tx_count;
        end if;
      end if;
    end process;

    gen_tx_data : block
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
      signal ip_crc_out   : std_logic_vector(15 downto 0) := (others => '0');

      --! @name Intermediate data words
      --! @{

      --! IPbus word 1
      signal ipbus_word_1 : std_logic_vector(31 downto 0) := (others => '0');
      --! IPbus word 2
      signal ipbus_word_2 : std_logic_vector(31 downto 0) := (others => '0');
      --! IPbus word 3
      signal ipbus_word_3 : std_logic_vector(31 downto 0) := (others => '0');
      --! @}

    begin
      -- Create reset response packet as the complete Ethernet frame
      with to_integer(tx_count) select rst_tx_data <=
        -- destination mac (6 bytes)
        tg_mac &
        -- + first 2 bytes source mac
        my_mac(47 downto 32)
          when 1,

        -- last 4 bytes source mac
        my_mac(31 downto 0) &
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
        my_ip &
        -- destination IP address (upper part)
        tg_ip(31 downto 16)
          when 4,

        -- destination IP address (lower part)
        tg_ip(15 downto 0) &
        -- source UDP port
        my_udp_port &
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

      -- actually setting the IPbus data to be transmitted according to endianness
      -- IPbus packet header
      ipbus_word_1 <= twist32(x"20" & ipbus_packet_id & x"f0", ipbus_big_endian);
      -- Transaction header
      ipbus_word_2 <= twist32(x"2" & ipbus_trans_id & ipbus_number_words & x"10", ipbus_big_endian);
      -- Read address
      ipbus_word_3 <= twist32(RESET_REGISTER_ADD, ipbus_big_endian);

      -- main code taken from ip_header_module, but be aware of data shift
      calculate_ip_header_crc: block
        --! Cumulative IP CRCn (data flowing in)
        signal ip_header_before_crc : std_logic_vector(63 downto 0);
        --! Reset of CRC calculation
        signal ip_crc_rst : std_logic;
      begin

        -- Consider the IP header when creating the packet
        with to_integer(tx_count) select ip_header_before_crc <=
          x"4500" & IP_LENGTH & IP_ID & x"0000" when 1,
          IP_TTLPROT & x"0000" & my_ip when 2,
          tg_ip & x"0000_0000" when 3,
          (others => '0') when others;

        -- Reset the CRC calculation initially
        with to_integer(tx_count) select ip_crc_rst <=
          '1' when 0,
          '0' when others;

        --! Instantiate checksum_calc to calculate IP CRC
        crc_calc: entity misc.checksum_calc
        generic map (
          I_WIDTH => 64,
          O_WIDTH => 16
        )
        port map (
          clk     => clk,
          en      => rst_tx_ready,
          rst     => ip_crc_rst,
          data_in => ip_header_before_crc,
          sum_out => ip_crc_out
        );

      end block;

    end block;

  end block;

  -- once recovered, generate the reset output signal
  make_reset : block
    --! @name Signals to create the reset for a given RESET_DURATION
    --! @{

    --! Counter enable
    signal cnt_en   : std_logic := '0';
    --! Counter end
    signal cnt_done : std_logic := '0';
    --! @}
  begin

    --! Create cnt_en
    proc_cnt_en : process (clk) is
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
    end process;

    --! Instantiate counting to generate reset of duration RESET_DURATION
    reset_cnt : entity misc.counting
    generic map (
      counter_max_value => RESET_DURATION
    )
    port map (
      clk         => clk,
      rst         => init_reset,
      en          => cnt_en,

      cycle_done  => cnt_done
    );

    rst_out <= soft_resets(RESET_WIDTH-1 downto 0) when cnt_en = '1' else (others => '0');
  end block;

  -- Receiver part
  make_rx_interface : block
    --! @brief State definition for the RX FSM
    --! @details
    --! State definition for the RX FSM
    --! - IDLE:       no transmission running
    --! - HEADER:     header is being analysed (and still valid)
    --! - SKIP:       frame is skipped until eof (due to invalid header data)
    --! - RESETTING:  reset is successfully recognised
    type t_rx_state is (IDLE, HEADER, SKIP, RESETTING);

    --! State of the RX FSM
    signal rx_state       : t_rx_state := IDLE;

    --! Internal ready
    signal rst_rx_ready_i   : std_logic := '1';
    --! Internal valid (delayed)
    signal rst_rx_valid_d   : std_logic := '0';

    --! Counter for incoming frame
    signal rx_count         : unsigned(7 downto 0) := to_unsigned(0, 8);
    --! @names Registers for receiving data
    --! @{
    signal rx_data_reg      : std_logic_vector(63 downto 0) := (others => '0');
    signal rx_data_reg1     : std_logic_vector(63 downto 0) := (others => '0');
    signal rx_data_reg2     : std_logic_vector(63 downto 0) := (others => '0');
    --! @}
    --! RX control signals
    signal rst_rx_ctrl_reg  : std_logic_vector(6 downto 0) := (others => '0');

    --! @name Registers to extract relevant data from incoming (reset) packets
    --! these signals serve the tx path and are extracted blindly
    --! @{

    --! Target MAC address
    signal rx_data_copy_tg_mac        : std_logic_vector(47 downto 0) := (others => '0');
    --! Target IP address
    signal rx_data_copy_tg_ip         : std_logic_vector(31 downto 0) := (others => '0');
    --! Target UDP port
    signal rx_data_copy_tg_udp        : std_logic_vector(15 downto 0) := (others => '0');
    --! Target IPbus packet ID
    signal rx_data_copy_packet_id     : std_logic_vector(15 downto 0) := (others => '0');
    --! Target IPbus transaction ID
    signal rx_data_copy_trans_id      : std_logic_vector(11 downto 0) := (others => '0');
    --! Target IPbus number of words
    signal rx_data_copy_number_words  : std_logic_vector(7 downto 0) := (others => '0');
    --! @}

  begin
    status_vector(2) <= '1' when rx_state = RESETTING else '0';

    -- receiver is always ready
    rst_rx_ready_i <= '1';

    rst_rx_ready <= rst_rx_ready_i;

    --! @brief Transfer of recovered IDs to signals for TX FSM
    --! @todo rst should actually reset all signals here - and default values should be removed
    proc_initiate_reset : process (clk) is
    begin
      if rising_edge(clk) then
        if (rst = '1') then
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
    end process;

    --! Introduce delay of rst_valid to keep counting one frame after the packet
    proc_rst_rx_valid_d : process (clk) is
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          rst_rx_valid_d <= '0';
        else
          rst_rx_valid_d <= rst_rx_ctrl(6);
        end if;
      end if;
    end process;

    --! Counting the frames of 8 bytes received
    proc_manage_rx_count_from_rx_sof : process (clk) is
    begin
      if rising_edge(clk) then
        -- reset counter
        if (rst = '1') then
          rx_data_reg      <= (others => '0');
          rx_count         <= (others => '0');
          ipbus_big_endian <= '0';
        elsif (rst_rx_ctrl(6) = '1' or rst_rx_valid_d = '1') and rst_rx_ready_i = '1' then
          -- ... sof initializes counter and endian-ness
          if (rst_rx_ctrl(5) = '1') then
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
            if rst_rx_data(47 downto 40) = x"20" and
              rst_rx_data(23 downto 16) = x"f0" then
              ipbus_big_endian <= '0';
            elsif rst_rx_data(47 downto 40) = x"f0" and
              -- or in big-endian
              rst_rx_data(23 downto 16) = x"20" then
              ipbus_big_endian <= '1';
            end if;
          end if;

          rst_rx_ctrl_reg <= rst_rx_ctrl;
          rx_data_reg1    <= rst_rx_data;
          rx_data_reg2    <= rx_data_reg1;
          -- if required, twist 32 bit words of IPbus
          if ipbus_big_endian = '1' then
            if rx_count = 5 then
              rx_data_reg(63 downto 48) <= rx_data_reg1(63 downto 48);
              rx_data_reg(47 downto 16) <= twist32(rx_data_reg1(47 downto 16), '1');
              rx_data_reg(15 downto  8) <= rst_rx_data(55 downto 48);
              rx_data_reg( 7 downto  0) <= rst_rx_data(63 downto 56);
            else
              rx_data_reg(63 downto 56) <= rx_data_reg2( 7 downto 0);
              rx_data_reg(55 downto 48) <= rx_data_reg2(15 downto 8);
              rx_data_reg(47 downto 16) <= twist32(rx_data_reg1(47 downto 16), '1');
              rx_data_reg(15 downto  8) <= rst_rx_data(55 downto 48);
              rx_data_reg( 7 downto  0) <= rst_rx_data(63 downto 56);
            end if;
          else
            rx_data_reg <= rx_data_reg1;
          end if;
        end if;
      end if;
    end process;

    --! @brief Retrieve relevant data from the reset packet blindly.
    --! @details Data will be applied only if it actually was a reset request.
    proc_extract_rx_data_copy : process (clk) is
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
    end process;

    --! @brief RX FSM to handle reset requests
    --! @details Analyses incoming data packets and checks them for reset content.
    proc_rx_fsm : process (clk) is
    begin

      if rising_edge(clk) then
        -- reset goes to IDLE
        if (rst = '1') then
          rx_state    <= IDLE;
          soft_resets <= (others => '0');
        else

          case rx_state is

            when IDLE =>
              -- check for start of frame
              if (rst_rx_ctrl(5) = '1') then
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
                  if rx_data_reg(63 downto 16) /= my_mac then
                    rx_state <= SKIP;
                  end if;
                when 2 =>
                  -- require ip protocol
                  if rx_data_reg(31 downto 16) /= x"0800" then
                    rx_state <= SKIP;
                  end if;
                when 3 =>
                  -- no more fragments
                  if rx_data_reg(29) /= '0' or
                    -- udp
                    rx_data_reg(7 downto 0) /= x"11"
                  then
                    rx_state <= SKIP;
                  end if;
                when 4 =>
                  if rx_data_reg(15 downto 0) /= my_ip(31 downto 16) then
                    rx_state <= SKIP;
                  end if;
                when 5 =>
                  if rx_data_reg(63 downto 48) /= my_ip(15 downto 0) or
                    rx_data_reg(31 downto 16) /= my_udp_port
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
                    if rst_rx_ctrl_reg(4) = '1' and rst_rx_ctrl_reg(3) = '0' then
                      rx_state                  <= RESETTING;
                      soft_resets(31 downto 16) <= rx_data_reg(15 downto 0);
                    else
                      rx_state <= HEADER;
                    end if;
                  end if;

                when others =>
                  -- may be padded: wait for eof
                  -- error indication
                  if rst_rx_ctrl_reg(4) = '1' and rst_rx_ctrl_reg(3) = '0' then
                    rx_state <= RESETTING;
                  end if;

              end case;

            -- once all requirements are fulfilled, reset
            when RESETTING =>
              soft_resets(15 downto 0) <= rx_data_reg(63 downto 48);
              rx_state                 <= IDLE;

            -- just let pass all other data, wait for eof
            when SKIP =>
              if rst_rx_ctrl(4) = '1' then
                rx_state <= IDLE;
              end if;

          end case;

        end if;
      end if;
    end process;

  end block;

end behavioral;
