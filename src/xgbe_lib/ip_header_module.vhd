-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief IP header module
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details
--! Constructs the IP header from an incoming (UDP) packet
--! and forwards the enclosed (UDP) packets with re-arranged eop flags.
--! Only supports incoming packets up to a length of 1500 bytes (= 187 cycles)
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! IP header module
entity ip_header_module is
  generic (
    --! @brief End of packet check:
    --! @details If enabled, the module counter checks the UDP length indication and
    --! raises the error indicator upon eop if not matching
    EOP_CHECK_EN : std_logic             := '1';
    --! @brief Post-UDP-module UDP CRC calculation
    --! @details If enabled, the UDP check sum will be (re)calculated from the pseudo
    --! header.
    --! This requires the check sum over the UDP data already being present in the
    --! UDP CRC field.
    --! If disabled, the check sum is omitted and set to x"0000".
    UDP_CRC_EN   : boolean               := true;
    --! The minimal number of clock cycles between two outgoing packets.
    PAUSE_LENGTH : integer range 0 to 10 := 2
  );
  port (
    --! Clock
    clk              : in    std_logic;
    --! Reset, sync with #clk
    rst              : in    std_logic;

    --! @name Avalon-ST from UDP module
    --! @{

    --! RX ready
    udp_rx_ready_o   : out   std_logic;
    --! RX data and controls
    udp_rx_packet_i  : in    t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! Destination IP address of DHCP server (used when transmitting DHCP packets)
    dhcp_server_ip_i : in    std_logic_vector(31 downto 0);
    --! @}

    --! @name Avalon-ST to IP module
    --! @{

    --! TX ready
    ip_tx_ready_i    : in    std_logic;
    --! TX data and controls
    ip_tx_packet_o   : out   t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @name Interface for recovering IP address from given UDP port
    --! @{

    --! Recovery enable
    reco_en_o        : out   std_logic;
    --! Recovery success indicator
    reco_ip_found_i  : in    std_logic;
    --! Recovered IP address
    reco_ip_i        : in    std_logic_vector(31 downto 0);
    --! @}

    --! @name Configuration of the module
    --! @{

    --! IP address
    my_ip_i          : in    std_logic_vector(31 downto 0);
    --! IP subnet mask
    ip_netmask_i     : in    std_logic_vector(31 downto 0) := x"ff_ff_ff_00";
    --! @}

    --! @brief Status of the module
    --! @details Status of the module
    --! - 1: TX FSM in UDP mode (transmission ongoing)
    --! - 0: TX FSM in IDLE (transmission may still be fading out)
    status_vector_o  : out   std_logic_vector(1 downto 0)
  );
end entity ip_header_module;

--! @cond
library misc;
--! @endcond

--! Implementation of the IP header module
architecture behavioral of ip_header_module is

  --! Broadcast IP address
  signal ip_broadcast_addr : std_logic_vector(31 downto 0);

  --! @brief State definition for the TX FSM
  --! @details
  --! State definition for the TX FSM
  --! - IDLE:    no transmission running
  --! - UDP:     data from UDP is being received and transmission is started
  --! - TRAILER: the current transmission is finished
  --! - ABORT:   the current transmission is aborted (if package is too long)
  type t_tx_state is (IDLE, UDP, TRAILER, ABORT);

  --! State of the TX FSM
  signal tx_state : t_tx_state;

  --! Indicate if transmission is done
  signal tx_done : std_logic;

  --! @name IP header information
  --! @{

  --! Destination IP address
  signal ip_dst_addr : std_logic_vector(31 downto 0);
  --! IP length
  signal ip_length   : unsigned(15 downto 0);
  --! Unique ID of the packet (simple 16 bit counter)
  signal ip_id       : unsigned(15 downto 0);
  --! @}

  --! Counter for outgoing packet
  signal tx_count : integer range 0 to 511;
  --! @name Avalon-ST rx controls (for better readability)
  --! @{

  --! Start of packet
  signal udp_rx_sop   : std_logic;
  --! end of packet
  signal udp_rx_eop   : std_logic;
  --! end of packet empty indicator
  signal udp_rx_empty : std_logic_vector(2 downto 0);
  --! end of packet error indicator
  signal udp_rx_error : std_logic;
--! @}

begin

  udp_rx_sop   <= udp_rx_packet_i.sop;
  udp_rx_eop   <= udp_rx_packet_i.eop;
  udp_rx_error <= udp_rx_packet_i.error(0);
  udp_rx_empty <= udp_rx_packet_i.empty(2 downto 0);

  --  broadcast address calculated from self configuration and IP_netmask
  --  used in TX if destination cannot be resolved
  ip_broadcast_addr <= my_ip_i or not ip_netmask_i;

  -- Transceiver specific status vector bits:
  status_vector_o(0) <= '1' when tx_state = IDLE else '0';
  status_vector_o(1) <= '1' when tx_state = UDP else '0';

  --! FSM to handle data forwarding of the interfaces
  proc_tx_state : process (clk)
    --! Indicator if package is too long
    variable overflow : std_logic;
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        tx_state <= IDLE;
        tx_count <= 0;
      else
        if ip_tx_ready_i = '1' then
          tx_count <= tx_count + 1;
          -- make sure that we don't create packets longer that 187 clock cycles (= 1496 bytes)
          -- we make use of the trailing shift register, so 6 earlier anyway ...
          overflow := to_signed(187 - 6 - tx_count, 10)(9);

          case tx_state is

            when IDLE =>
              if udp_rx_sop = '1' then
                tx_state <= UDP;
                tx_count <= 1;
              else
                tx_state <= IDLE;
                tx_count <= 0;
              end if;

            when UDP =>
              if udp_rx_eop = '1' then
                tx_state <= TRAILER;
              elsif overflow = '1' then
                tx_state <= ABORT;
              else
                tx_state <= UDP;
              end if;

            when TRAILER =>
              if tx_done = '1' then
                tx_state <= IDLE;
                tx_count <= 0;
              else
                tx_state <= TRAILER;
              end if;

            when ABORT =>
              tx_state <= IDLE;

          end case;

        end if;
      end if;
    end if;
  end process proc_tx_state;

  blk_request_ip : block
    signal request : std_logic_vector(1 downto 0);
  begin

    --! Process to set the IP destination address
    proc_set_ip_dst_addr : process (clk)
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          request     <= "00";
          reco_en_o   <= '0';
          ip_dst_addr <= (others => '0');
        else
          -- default
          reco_en_o <= '0';

          case request is

            when "00" =>
              if ip_tx_ready_i = '1' and tx_state = IDLE and udp_rx_sop = '1' then
                -- Check for DHCP destination port:
                -- Then skip IP lookup and move to dedicated state setting DHCP server address
                if udp_rx_packet_i.data(47 downto 32) = x"0043" then
                  request <= "11";
                else
                  reco_en_o <= '1';
                  request   <= "01";
                end if;
              else
                request <= "00";
              end if;

            when "01" =>
              -- just wait one clock
              request <= "10";

            when "10" =>
              -- one clk after looking for it, evaluate result of UDP/IP table:
              if reco_ip_found_i = '1' then
                -- take IP address from table
                ip_dst_addr <= reco_ip_i;
              else
                -- make a broadcast to the subnet
                -- ... the more complex way would be to figure out the corresponding
                -- address differently...
                ip_dst_addr <= ip_broadcast_addr;
              end if;
              request <= "00";

            when "11" =>
              ip_dst_addr <= dhcp_server_ip_i;
              request     <= "00";

            when others =>
              request <= "00";

          end case;

        end if;
      end if;
    end process proc_set_ip_dst_addr;

  end block blk_request_ip;

  --! Set IP length field from UDP length field and know IP header length
  proc_set_ip_length : process (clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        ip_length <= (others => '0');
      else
        if ip_tx_ready_i = '1' and tx_state = IDLE and udp_rx_sop = '1' then
          ip_length <= to_unsigned(20, 16) + unsigned(udp_rx_packet_i.data(31 downto 16));
        end if;
      end if;
    end if;
  end process proc_set_ip_length;

  --! Set IP ID field from counter
  proc_set_ip_id : process (clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        ip_id <= (others => '0');
      elsif ip_tx_ready_i = '1' then
        if tx_done = '1' then
          ip_id <= ip_id + 1;
        end if;
      end if;
    end if;
  end process proc_set_ip_id;

  blk_make_tx_interface : block
    signal ip_header_before_crc : std_logic_vector(63 downto 0);
    signal ip_crc_out           : std_logic_vector(15 downto 0);
    signal udp_crc_out          : std_logic_vector(15 downto 0);
  begin

    blk_udp_data_transport : block
      constant SR_DEPTH : integer := 6;

      type t_tx_data_sr is array(1 to SR_DEPTH) of std_logic_vector(63 downto 0);

      type t_tx_ctrl_sr is array(1 to SR_DEPTH) of std_logic_vector(4 downto 0);

      signal tx_data_sr : t_tx_data_sr;
      -- controls for end of packet: eop & error & empty
      signal tx_ctrl_sr : t_tx_ctrl_sr;

      signal tx_valid : std_logic_vector(0 to SR_DEPTH);
    begin

      -- instantiate counting to generate artificial gap between packets
      blk_make_tx_done : block
        signal cnt_rst : std_logic;
        signal tx_next : std_logic;
      begin

        cnt_rst <= '1' when tx_state /= TRAILER else tx_valid(3);

        -- Instantiate non-cyclic counter to generate requested gap
        inst_trailer_counter : entity misc.counting
        generic map (
          COUNTER_MAX_VALUE => PAUSE_LENGTH,
          CYCLIC            => false
        )
        port map (
          clk => clk,
          rst => cnt_rst,
          en  => ip_tx_ready_i,

          cycle_done => tx_next
        );

        -- make sure that there's only 1 tick of done using hilo_detect
        inst_tx_done : entity misc.hilo_detect
        generic map (
          LOHI => true
        )
        port map (
          clk     => clk,
          sig_in  => tx_next and ip_tx_ready_i,
          sig_out => tx_done
        );

      end block blk_make_tx_done;

      --! @brief Main process to assemble output packet from incoming UDP data stream
      --! @details
      --! Does the multiplexing in dependence of tx_count and also sets control signals
      --! of the interface properly.
      proc_make_data_and_controls : process (clk)
        variable byte_count : unsigned(15 downto 0);
        variable empty      : unsigned(3 downto 0);
        variable error      : std_logic;
      begin
        if rising_edge(clk) then
          if (rst = '1') then
            tx_data_sr <= (others => (others => '0'));
            tx_ctrl_sr <= (others => (others => '0'));
            tx_valid   <= (others => '0');
          elsif ip_tx_ready_i = '1' then
            -- take care of the data first: shift UDP data into register
            -- with proper re-alignment for the insertion of 20 bytes of IP header
            tx_data_sr(1) <= udp_rx_packet_i.data(31 downto 0) & x"0000_0000";
            tx_data_sr(2) <= tx_data_sr(1)(63 downto 32) & udp_rx_packet_i.data(63 downto 32);

            -- default: shift
            tx_data_sr(3 to SR_DEPTH) <= tx_data_sr(2 to SR_DEPTH - 1);

            -- insert IP header (without CRC calculated)
            -- important here: all header data have to be calculated at the given tx_count
            case tx_count is

              when 1 =>
                tx_data_sr(5) <= ip_header_before_crc;

              when 2 =>
                tx_data_sr(5) <= ip_header_before_crc;

              when 3 =>
                tx_data_sr(5) <= ip_header_before_crc(63 downto 32) & tx_data_sr(4)(31 downto 0);

              when others =>
                tx_data_sr(5) <= tx_data_sr(4);

            end case;

            -- now take care of the controls
            -- default: shift UDP controls into register,
            -- depending on conditions (abort or eop) that may change
            tx_ctrl_sr(2 to SR_DEPTH) <= tx_ctrl_sr(1 to SR_DEPTH - 1);

            -- default for valid: also just shift, but conditions (later) apply
            tx_valid(1) <= tx_valid(0);
            tx_valid(2) <= tx_valid(1);

            -- now, depending on some conditions, that may change
            -- with proper re-calculation of the end position and empty value
            if tx_state = ABORT then
              tx_ctrl_sr(1) <= "11000";
            elsif tx_state /= IDLE and udp_rx_eop = '1' then
              -- calculate new ip_rx_empty from udp_rx_empty
              -- the one bit more in empty will also make "overflow" correct in comparison
              empty := unsigned('0' & udp_rx_empty(2 downto 0)) + 4;

              -- total number of bytes is multiple of 8:
              -- number in empty gives 'fill up' bytes
              byte_count := ip_length + empty;

              -- do length check on the packet and set error, eventually
              if EOP_CHECK_EN = '1' then
                if (ip_length < 64 - 4 - 14) and (tx_count = 3) and (udp_rx_empty = "110") then
                  -- ... but only if it is not padded:
                  -- signature is maximum 49 data bytes but still 6 empty bytes in the eop packet due to padding
                  error := '0';
                elsif (to_unsigned(tx_count + 4, 13) & "000") /= byte_count then
                  error := '1';
                else
                  error := udp_rx_error;
                end if;
              else
                error := '0';
              end if;

              if unsigned(udp_rx_empty) >= 8 - 4 then
                -- skip one register due to IP-header insertion
                tx_ctrl_sr(1) <= (others => '0');
                tx_ctrl_sr(2) <= udp_rx_eop & error & std_logic_vector(empty(2 downto 0));

                tx_valid(1 to 2) <= "01";
              else
                tx_ctrl_sr(1) <= udp_rx_eop & error & std_logic_vector(empty(2 downto 0));
                tx_ctrl_sr(2) <= (others => '0');

                tx_valid(1 to 2) <= "11";
              end if;
            else
              tx_ctrl_sr(1) <= (others => '0');
            end if;

            -- handling of the valid bit
            -- mark fall by udp eop or abort
            -- mark rise by started transmission
            if udp_rx_eop = '1' or tx_state = ABORT then
              tx_valid(0) <= '0';
            elsif tx_count = 2 and tx_state /= TRAILER then
              tx_valid(0 to 2) <= (others => '1');
            else
              tx_valid(0) <= tx_valid(0);
            end if;

            if tx_count = 2 then
              tx_valid(3 to SR_DEPTH) <= (others => '1');
            else
              -- default: shift and let bits 1 and 2 be decided from above
              tx_valid(3 to SR_DEPTH) <= tx_valid(2 to SR_DEPTH - 1);
            end if;
          end if;
        end if;
      end process proc_make_data_and_controls;

      -- finally compose data output stream from registers and IP_CRC that has been
      -- computed in the meantime
      -- vsg_off comment_010
      with tx_count select ip_tx_packet_o.data <=
        -- insert IP_CRC at correct position:
        tx_data_sr(SR_DEPTH)(63 downto 48) & ip_crc_out & tx_data_sr(SR_DEPTH)(31 downto 0) when 4,
        -- insert UDP CRC
        tx_data_sr(SR_DEPTH)(63 downto 48) & udp_crc_out & tx_data_sr(SR_DEPTH)(31 downto 0) when 6,
        -- or just attach (UDP) data from the register
        tx_data_sr(SR_DEPTH) when others;

      -- vsg_on comment_010
      -- set valid
      ip_tx_packet_o.valid <= tx_valid(SR_DEPTH);

      -- set sop
      ip_tx_packet_o.sop <= '1' when tx_count = 3 else '0';

      -- set eop indicators from shift register
      ip_tx_packet_o.eop   <= tx_ctrl_sr(SR_DEPTH)(4);
      ip_tx_packet_o.error <= tx_ctrl_sr(SR_DEPTH)(3 downto 3);
      ip_tx_packet_o.empty <= tx_ctrl_sr(SR_DEPTH)(2 downto 0);

    end block blk_udp_data_transport;

    blk_calculate_ip_header_crc : block
      signal ip_crc_rst : std_logic;
    begin

      with tx_count select ip_header_before_crc <=
        x"4500" & std_logic_vector(ip_length) & std_logic_vector(ip_id) & x"0000" when 1,
        x"4011" & x"0000" & my_ip_i when 2,
        ip_dst_addr & x"0000_0000" when 3,
        (others => '0') when others;

      with tx_count select ip_crc_rst <=
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
        en      => ip_tx_ready_i,
        rst     => ip_crc_rst,
        data_in => ip_header_before_crc,
        sum_out => ip_crc_out
      );

    end block blk_calculate_ip_header_crc;

    gen_calculate_udp_header_crc : if UDP_CRC_EN generate
      signal udp_crc_rst  : std_logic;
      signal udp_crc_data : std_logic_vector(31 downto 0);
      signal udp_header   : std_logic_vector(63 downto 0);
      signal udp_crc_r    : std_logic_vector(15 downto 0);
    begin

      proc_set_udp_header : process (clk)
      begin
        if rising_edge(clk) then
          if (rst = '1') then
            udp_header <= (others => '0');
          else
            if ip_tx_ready_i = '1' and tx_state = IDLE and udp_rx_sop = '1' then
              udp_header <= udp_rx_packet_i.data;
            end if;
          end if;
        end if;
      end process proc_set_udp_header;

      -- vsg_off comment_010
      with tx_count select udp_crc_data <=
        -- src and dst port
        udp_header(63 downto 32) when 1,
        my_ip_i when 2,
        ip_dst_addr when 3,
        -- zero, protocol, udp_length
        x"0011" & udp_header(31 downto 16) when 4,
        -- udp_length & crc_n(data)
        udp_header(31 downto 16) & not udp_header(15 downto 0) when 5,
        (others => '0') when others;

      -- vsg_on comment_010
      -- if UDP header is not set, then leave it unset
      with udp_header(15 downto 0) select udp_crc_out <=
        (others => '0') when x"0000",
        udp_crc_r when others;

      with tx_count select udp_crc_rst <=
        '1' when 0,
        '0' when others;

      inst_crc_calc : entity misc.checksum_calc
      generic map (
        I_WIDTH => 32,
        O_WIDTH => 16
      )
      port map (
        clk     => clk,
        en      => ip_tx_ready_i,
        rst     => udp_crc_rst,
        data_in => udp_crc_data,
        sum_out => udp_crc_r
      );

    end generate gen_calculate_udp_header_crc;

    -- else

    gen_dont_calculate_udp_header_crc : if not UDP_CRC_EN generate
    begin

      --! Process to set the CRC in the UPD header
      proc_set_udp_header : process (clk)
      begin
        if rising_edge(clk) then
          if (rst = '1') then
            udp_crc_out <= (others => '0');
          else
            if ip_tx_ready_i = '1' and tx_state = IDLE and udp_rx_sop = '1' then
              udp_crc_out <= udp_rx_packet_i.data(15 downto 0);
            end if;
          end if;
        end if;
      end process proc_set_udp_header;

    end generate gen_dont_calculate_udp_header_crc;

  end block blk_make_tx_interface;

  -- Receive part for the UDP interfaces
  --
  -- default: always indicate being ready to receive data to allow
  -- modules to start transmission
  -- block the interface for intermediate states (trailer...)
  with tx_state select udp_rx_ready_o <=
    ip_tx_ready_i when IDLE | UDP,
    '0' when others;

end architecture behavioral;
