-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief ARP request responder (and generator) according to RFC 826
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details
--! Watches for ARP requests dedicated to this client, referred by the
--! IP address configured in "my_ip".
--! The MAC address of the core has to be provided at all times to "my_mac".
--! The incoming interface expects the raw ARP frame (Ethernet header
--! already stripped off), but will respond with the Ethernet header for
--! an easier implementation in the hierarchy upper module.
--!
--! Multiple ARP requests entering while arp_tx_ready is indicating busy are
--! stored in a FIFO and will be answered when the TX interface is free again.
--!
--! The incoming packet's MAC and IP address are discovered and provided in one
--! single clock cycle to the 'disco' interface for an eventual storage in an
--! external ARP table.
-------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.STD_LOGIC_1164.ALL;
  use IEEE.numeric_std.all;
--! @endcond

--! ARP request responder (and generator) according to RFC 826

entity arp_module is
  generic (
    --! Timeout in milliseconds
    ARP_TIMEOUT       : integer range 2 to 1000 := 50;
    --! Cycle time in milliseconds for APR requests (when repetitions are needed)
    ARP_REQUEST_CYCLE : integer range 1 to 1000 := 2;
    --! Depth of ARP table (number of stored connections)
    ARP_TABLE_DEPTH   : integer range 1 to 1024 := 4
  );
  port (
    --! Clock
    clk           : in    std_logic;
    --! Reset, sync with #clk
    rst           : in    std_logic;
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

    --! @name Interface for recovering MAC address from given IP address
    --! @{

    --! Recovery enable
    reco_en       : in    std_logic;
    --! IP address to recover
    reco_ip       : in    std_logic_vector(31 downto 0);
    --! Recovered MAC address
    reco_mac      : out   std_logic_vector(47 downto 0);
    --! Recovery success: 1 = found, 0 = not found (time out)
    reco_mac_done : out   std_logic := '0';
    --! @}

    --! MAC address of the module
    my_mac        : in    std_logic_vector(47 downto 0);
    --! IP address of the module
    my_ip         : in    std_logic_vector(31 downto 0);

    --! Clock cycle when 1 millisecond is passed
    one_ms_tick   : in    std_logic;

    --! @brief Status of the module
    --! @details Status of the module
    --! - 4: ARP table full
    --! - 3: ARP table empty
    --! - 2: ARP request is being received
    --! - 1: APR request is being answered
    --! - 0: Data is being forwarded
    status_vector : out   std_logic_vector(4 downto 0)
  );
end arp_module;

--! @cond
library ethernet_lib;
library misc;
library memory;
--! @endcond

--! Implementation of the arp_module
architecture behavioral of arp_module is

  --  signals controlling the FIFO data flow
  --! FIFO reset
  signal arp_fifo_rst   : std_logic := '0';
  --! FIFO data in
  signal arp_fifo_din   : std_logic_vector(79 downto 0) := (others => '0');
  --! FIRO write enable
  signal arp_fifo_wen   : std_logic := '0';
  --! FIFO read enable
  signal arp_fifo_ren   : std_logic := '0';
  --! FIFO data out
  signal arp_fifo_dout  : std_logic_vector(79 downto 0) := (others => '0');
  --! FIFO full
  signal arp_fifo_full  : std_logic := '0';
  --! FIFO empty
  signal arp_fifo_empty : std_logic := '1';

  --! @name Interface for initialising ARP request
  --! @{

  --! Requested IP address
  signal request_ip   : std_logic_vector(31 downto 0) := (others => '0');
  --! Request enable
  signal request_en   : std_logic := '0';
  --! @}

  --! @name Interface for writing new discovered MAC and IP to ARP table
  --! @{

  --! Discovered MAC address
  signal disco_mac    : std_logic_vector(47 downto 0) := (others => '0');
  --! Discovered IP address
  signal disco_ip     : std_logic_vector(31 downto 0) := (others => '0');
  --! Discovery write enable
  signal disco_wren   : std_logic := '0';
  --! @}

begin

  assert ARP_REQUEST_CYCLE < ARP_TIMEOUT
    report "ARP_REQUEST_CYCLE must be smaller than ARP_TIMEOUT!"
    severity failure;

  fifo_handler : block is
  begin
    --! @brief FIFO to store MAC and IP addresses of requesting ARP packets
    --! @details
    --! Depth requirements for this FIFO = maximum number of requests during TX forwarding
    --! normal frame: 1500 byte: 42 bytes unpadded, 64 bytes padded = 36 .. 24 packets
    --! jumbo frames: 9000 byte: 42 bytes unpadded, 64 bytes padded = 215 .. 140 packets
    --!
    --! Width: storing MAC (6 bytes) + IP (4 bytes) requires 10 bytes = 80 bit)
    arp_fifo_inst : entity memory.generic_fifo
    generic map (
      wr_d_width   => 80,
      wr_d_depth   => 256
    )
    port map (
      rst       => arp_fifo_rst,
      wr_clk    => clk,
      wr_en     => arp_fifo_wen,
      wr_data   => arp_fifo_din,
      rd_clk    => clk,
      rd_en     => arp_fifo_ren,
      rd_data   => arp_fifo_dout,
      rd_full   => arp_fifo_full,
      rd_empty  => arp_fifo_empty
    );

    proc_fifo_rst : process (clk)
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          arp_fifo_rst <= '1';
        else
          arp_fifo_rst <= '0';
        end if;
      end if;
    end process;

  end block;

  -- Transmitter part
  make_tx_interface : block is
    --! @brief State definition for the TX FSM
    --! @details
    --! State definition for the TX FSM
    --! - IDLE:          no transmission running
    --! - ARP_RESPONSE:  ARP response is being sent
    --! - ARP_REQUEST:   ARP request is being sent
    type t_tx_state is (IDLE, ARP_RESPONSE, ARP_REQUEST);
    --! State of the TX FSM
    signal tx_state     : t_tx_state := IDLE;

    --! Register to temporarily store target MAC, used in TX path only and fed by FIFO
    signal config_tg_mac    : std_logic_vector(47 downto 0) := (others => '0');
    --! Register to temporarily store target IP, used in TX path only and fed by FIFO
    signal config_tg_ip     : std_logic_vector(31 downto 0) := (others => '0');

    --! Counter for outgoing ARP response frame
    signal tx_count         : integer range 0 to 9 := 0;

    --! Indicator if pair of MAC and IP address have been received
    signal arp_data_loaded  : std_logic := '0';

    --! @brief State definition for the FIFO FSM
    --! @details
    --! State definition for the FIFO FSM
    --! - IDLE:     Nothing happening
    --! - PRE_READ: Set read request
    --! - READ:     Read data from FIFO
    --! - HOLD:     Wait until read data is properly processed by TX module
    type t_fifo_state is (IDLE, PRE_READ, READ, HOLD);
    --! State of the FIFO FSM
    signal fifo_state : t_fifo_state := IDLE;

  begin
    status_vector(0) <= '1' when arp_tx_ready = '0' else '0';--tx_state = PASS else '0';
    status_vector(1) <= '1' when tx_state = arp_response else '0';

    -- arp_tx_data   <= see state machine;

    arp_tx_ctrl(6)  <= '1' when tx_count >= 1 and tx_count <= 6 else '0';
    arp_tx_ctrl(5)  <= '1' when tx_count = 1 else '0';
    arp_tx_ctrl(4)  <= '1' when tx_count = 6 else '0';
    arp_tx_ctrl(3)  <= '0';

    with tx_count select arp_tx_ctrl(2 downto 0) <=
      "000" when 1 to 5,
      "110" when 6,
      "000" when others;

    --! @brief Counting the clks being in the ARP mode
    --! which is similar to the frames of 8 bytes to be sent
    proc_count: process (clk)
    begin
      if rising_edge(clk) then
        -- reset of tx_count on input reset or not when in ARP state
        if rst = '1' or tx_state = IDLE then
          tx_count <= 0;
        -- keep counting otherwise
        elsif tx_state /= IDLE and arp_tx_ready = '1' then
          tx_count <= tx_count + 1;
        end if;
      end if;
    end process;

    gen_tx_data: block is
      signal target_mac     : std_logic_vector(47 downto 0) := (others => '0');
      signal target_ip      : std_logic_vector(31 downto 0) := (others => '0');
      signal target_ip_tmp  : std_logic_vector(31 downto 0) := (others => '0');
      signal send_request   : std_logic := '0';
      signal arp_operation  : std_logic_vector(15 downto 0) := (others => '0');
    begin
      send_request_block: block is
        signal cnt_rst : std_logic := '0';
        signal cnt_en  : std_logic := '0';
      begin
        cnt_en <= one_ms_tick and request_en;

        cnt_rst <= not request_en;

        request_timeout_counter: entity misc.counting
        generic map (
          counter_max_value => ARP_REQUEST_CYCLE
        )
        port map (
          clk     => clk,
          rst     => cnt_rst,
          en      => cnt_en,

          cycle_done  => send_request
        );
      end block;

      proc_arp_request: process (clk)
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
      end process;

      with tx_state select target_mac <=
        config_tg_mac when ARP_RESPONSE,
        (others => '1') when others; -- ARP_REQUEST

      with tx_state select target_ip <=
        config_tg_ip when ARP_RESPONSE,
        target_ip_tmp when others; -- ARP_REQUEST

      with tx_state select arp_operation <=
        x"0002" when ARP_RESPONSE,
        x"0001" when others; -- ARP_REQUEST

      -- creates ARP response packet
      -- the complete Ethernet frame is created for easiness of the upper layer module
      with tx_count select arp_tx_data <=
        -- destination mac (6 bytes)
        target_mac &
        -- + first 2 bytes source MAC
        -- last 4 bytes source MAC
        my_mac(47 downto 32)
          when 1,
        my_mac(31 downto 0) &
        -- packet type: ARP = x"0806"
        x"0806" &
        -- Hardware address type: Ethernet = x"0001"
        x"0001"
          when 2,
        -- Protocol address type: IP = x"0800"
        x"0800" &
        -- Hardware size: MAC = 6 bytes
        x"06" &
        -- Protocol address size: IP = 4 bytes
        x"04" &
        -- Operation
        arp_operation &
        -- first 2 bytes source MAC address
        my_mac(47 downto 32)
          when 3,
        -- last 4 bytes source MAC address
        my_mac(31 downto 0) &
        -- source IP address
        my_ip
          when 4,
        -- destination MAC address
        target_mac &
        -- first 2 bytes destination IP address
        target_ip(31 downto 16)
          when 5,
        -- second 2 bytes destination IP address
        target_ip(15 downto 0) &
        -- padding: some random data
        x"00_00_00_00_00_00"
          when 6,
        (others => '0')
          when others;

      --! Read FIFO and make disco interface
      proc_fifo_reader: process (clk)
      begin
        if rising_edge(clk) then
          -- default settings:
          arp_fifo_ren    <= '0';
          -- maybe TODO: optimise away config_... and use fifo_dout directly
          config_tg_mac   <= config_tg_mac;
          config_tg_ip    <= config_tg_ip;
          arp_data_loaded <= '0';

          case fifo_state is
            when IDLE =>
              if arp_fifo_empty = '0' then
                arp_fifo_ren <= '1';
                fifo_state   <= PRE_READ;
              else
                fifo_state   <= IDLE;
              end if;

            when PRE_READ =>
              fifo_state <= READ;

            when READ =>
              fifo_state <= HOLD;

              config_tg_mac   <= arp_fifo_dout(79 downto 32);
              config_tg_ip    <= arp_fifo_dout(31 downto 0);
              arp_data_loaded <= '1';

            when HOLD =>
              -- must not go back to IDLE before config_tg_MAC/IP
              -- is last used by tx part
              if tx_count = 2 then
                fifo_state <= IDLE;
              else
                fifo_state <= HOLD;

                arp_data_loaded <= '1';
              end if;

          end case;
        end if;
      end process;

      --! FSM to handle ARP responding vs. ARP requesting
      proc_tx_state : process (clk)
      begin

        if rising_edge(clk) then
          if (rst = '1') then
            tx_state <= IDLE;
          else

            case tx_state is
              when IDLE =>
                if arp_data_loaded = '1' then
                  tx_state <= ARP_RESPONSE;
                elsif send_request = '1' then
                  tx_state <= ARP_REQUEST;
                else
                  tx_state <= IDLE;
                end if;

              when ARP_RESPONSE =>
                -- only when tx_count 7 is reached, one is sure to have
                -- transmitted all data correctly (6 is required to put in
                -- the packet - but give one spare for tx_ready!
                if tx_count = 7 then
                  tx_state <= IDLE;
                else
                  tx_state <= ARP_RESPONSE;
                end if;

              when ARP_REQUEST =>
                -- only when tx_count 7 is reached, one is sure to have
                -- transmitted all data correctly (6 is required to put in
                -- the packet - but give one spare for tx_ready!
                if tx_count = 7 then
                  tx_state <= IDLE;
                else
                  tx_state <= ARP_REQUEST;
                end if;

            end case;
          end if;
        end if;
      end process;

    end block;
  end block;

  -- Receiver part
  make_rx_interface: block is
    --! @brief State definition for the RX FSM
    --! @details
    --! State definition for the RX FSM
    --! - HEADER: checks all requirement of the incoming ARP packet
    --! - SKIP: skips all frames until EOF (if header is wrong)
    --! - STORING_TG: indicates successful extraction of ARP target MAC and IP
    type t_rx_state is (HEADER, SKIP, STORING_TG);
    --! States of the RX FSM
    signal rx_state       : t_rx_state := HEADER;

    --! ARP RX type: '0': response, '1': request
    signal rx_type        : std_logic := '0';

    --! Internal ready signal
    signal arp_rx_ready_i : std_logic := '1';

    --! Counter for incoming packets: max possible = jumbo frame (9000 bytes = 1125 frames)
    signal rx_count       : integer range 0 to 1125 := 0;
    --! Register receiving data
    signal rx_data_reg    : std_logic_vector(63 downto 0) := (others => '0');

    --! @name Register to extract relevant data of incoming (ARP) packets:
    --! These signals serve the RX path and extract data blindly
    --! @{

    --! Requesting MAC
    signal rx_data_copy_tg_mac  : std_logic_vector(47 downto 0) := (others => '0');
    --! Requesting IP
    signal rx_data_copy_tg_ip   : std_logic_vector(31 downto 0) := (others => '0');
    --! @}

    --! Control for retrieving ARP target (requester) and storing data - may be optimized away
    signal config_tg_en         : std_logic := '0';

  begin
    status_vector(2) <= '1' when rx_state = STORING_TG else '0';

    -- receiver is always ready when the FIFO is not full
    arp_rx_ready_i <= not arp_fifo_full;

    arp_rx_ready <= arp_rx_ready_i;

    --! Counting the frames of 8 bytes received
    proc_manage_rx_count_from_rx_sof : process (clk)
    begin
      if rising_edge(clk) then
        -- reset counter
        if (rst = '1') then
          rx_data_reg <= (others => '0');
          rx_count <= 0;
        -- prevent from overwriting last received valid ARP data
        elsif arp_rx_ctrl(6) = '1' and arp_rx_ready_i = '1' then
          rx_data_reg   <= arp_rx_data;
          -- ... sof initializes counter
          if (arp_rx_ctrl(5) = '1') then
            rx_count <= 1;
          -- ... otherwise keep counting
          else
            rx_count <= rx_count + 1;
          end if;
        end if;
      end if;
    end process;

    --! Storing the relevant data from the ARP packet blindly
    proc_extract_rx_data_copy : process (clk)
    begin
      if rising_edge(clk) then
        -- check whether request or response
        if rx_count = 1 then
          rx_type <= rx_data_reg(0);
        else
          rx_type <= rx_type;
        end if;

        if rx_count = 2 then
          rx_data_copy_tg_mac <= rx_data_reg(63 downto 16);
          rx_data_copy_tg_ip(31 downto 16) <= rx_data_reg(15 downto 0);
        else
          -- just store
          rx_data_copy_tg_mac <= rx_data_copy_tg_mac;
          rx_data_copy_tg_ip(31 downto 16) <= rx_data_copy_tg_ip(31 downto 16);
        end if;

        if rx_count = 3 then
          rx_data_copy_tg_ip(15 downto 0) <= rx_data_reg(63 downto 48);
        else
          -- just store
          rx_data_copy_tg_ip(15 downto 0) <= rx_data_copy_tg_ip(15 downto 0);
        end if;
      end if;
    end process;

    -- eventually enable data storing and make blindly stored data permanent
    config_tg_en <= '1' when rx_state = STORING_TG else '0';

    -- writing the extracted values to the FIFO
    proc_fifo_writer : process (clk)
    begin
      if rising_edge(clk) then
        if config_tg_en = '1' and rx_type = '1' then
          arp_fifo_din <= rx_data_copy_tg_mac & rx_data_copy_tg_ip;
          arp_fifo_wen <= '1';
        else
          -- don't care about data
          arp_fifo_din <= (others => '-');
          arp_fifo_wen <= '0';
        end if;
      end if;
    end process;

    --! Writing the extracted values to the ARP table
    proc_arp_table_writer: process (clk)
    begin
      if rising_edge(clk) then
        if config_tg_en = '1' then
          disco_mac <= rx_data_copy_tg_mac;
          disco_ip <= rx_data_copy_tg_ip;
          disco_wren <= '1';
        else
          disco_mac <= (others => '-');
          disco_ip <= (others => '-');
          disco_wren <= '0';
        end if;
      end if;
    end process;

    --! @brief FSM to handle ARP requests.
    --! @details
    --! Analysing incoming data packets and checking them for ARP content.
    --! Extract relevant ARP data if it is an ARP packet.
    proc_rx_state : process (clk)
    begin

      if rising_edge(clk) then
        -- reset or sof indicate new header
        if (rst = '1') or (arp_rx_ctrl(5) = '1') then
          rx_state <= HEADER;
        else

          case rx_state is
            -- check header data
            when HEADER =>

              case rx_count is
                when 0 =>
                  rx_state <= HEADER;
                when 1 =>
                  -- check for supported header (IPv4 on Ethernet)
                  if rx_data_reg(63 downto 48) /= x"0001" or  -- HW-type Ethernet
                    rx_data_reg(47 downto 32) /= x"0800" or   -- protocol type: IP
                    rx_data_reg(31 downto 16) /= x"0604" then -- HW-size: 6, P-size: 4
                    rx_state <= SKIP;
                  else
                    -- check whether ARP request or response
                    case rx_data_reg(15 downto 0) is
                      -- Operation: ARP request
                      when x"0001" =>
                        rx_state <= HEADER;
                      -- Operation: ARP response
                      when x"0002" =>
                        rx_state <= HEADER;
                      when others =>
                        rx_state <= SKIP;
                    end case;
                  end if;
                -- when 2, 3 => MAC and IP data is copied from reg in process extract_rx_data_copy
                when 4 =>
                  -- IP address must match
                  if  rx_data_reg(63 downto 32) /= my_ip then
                    rx_state <= SKIP;
                  else
                    -- error indication
                    if arp_rx_ctrl(4) = '1' and arp_rx_ctrl(3) = '0' then
                      rx_state <= STORING_TG;
                    else
                      rx_state <= HEADER;
                    end if;
                  end if;

                -- maybe padded: wait for eof
                when others =>
                  -- error indication
                  if arp_rx_ctrl(4) = '1' and arp_rx_ctrl(3) = '0' then
                    rx_state <= STORING_TG;
                  else
                    rx_state <= HEADER;
                  end if;

              end case;

            -- store source MAC and IP
            -- may only be assigned for one clk
            when STORING_TG =>
              rx_state <= HEADER;

            -- just let pass all other data, wait for EOF
            when SKIP =>
              if arp_rx_ctrl(4) = '1' then
                rx_state <= HEADER;
              end if;

          end case;

        end if;
      end if;
    end process;
  end block;

  -- Handling of ARP requests to the ARP table:
  --
  -- First, look up the requested IP in ARP table.
  -- If found, put out,
  -- if not found, initiate ARP request.
  arp_table_block: block is
    --! @brief Status vector of the ARP table
    --! @details
    --! - 1: ARP table full
    --! - 0: ARP table empty
    signal arptbl_status_vector : std_logic_vector(1 downto 0);

    --! @name signals decoupling ARP table from outer interface
    --! @{

    --! Indicator for recovering IP address
    signal reco_en_i      : std_logic := '0';
    --! ip address to recover
    signal reco_ip_i      : std_logic_vector(31 downto 0) := (others => '0');
    --! recovered mac address
    signal reco_mac_i     : std_logic_vector(47 downto 0) := (others => '0');
    --! valid flag for recovered mac address: 1 = found, 0 = time out
    signal reco_mac_found_i   : std_logic := '0';
    --! timeout indication
    signal request_timeout    : std_logic := '0';
    --! @}

    --! @brief State definition for the ARP table FSM
    --! @details
    --! State definition for the ARP table FSM
    --! - IDLE:               Nothing happening
    --! - ARP_TABLE_REQUEST:  Request ARP recovery
    --! - ARP_TABLE_READ:     Read ARP table
    --! - ARP_WAIT_RESPONSE:  Wait for ARP response
    type t_request_state is (IDLE, ARP_TABLE_REQUEST, ARP_TABLE_READ, ARP_WAIT_RESPONSE);
    --! State of the ARP table FSM
    signal request_state    : t_request_state := IDLE;

    --! Broadcast MAC address for ARP request
    constant MAC_BROADCAST_ADDR : std_logic_vector(47 downto 0) := (others => '1');
  begin
    status_vector(4 downto 3) <= arptbl_status_vector;

    --! FSM to request MAC address.
    proc_mac_address_request : process (clk)
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          request_state <= IDLE;
          reco_en_i <= '0';
          reco_ip_i <= (others => '0');
          reco_mac <= (others => '0');
          reco_mac_done <= '0';
          request_en <= '0';
        else
          -- defaults
          reco_en_i <= '0';
          reco_ip_i <= reco_ip_i;
          reco_mac_done <= '0';

          case request_state is
            when IDLE =>
              request_en <= '0';
              if reco_en = '1' then
                reco_en_i <= '1';
                reco_ip_i <= reco_ip;

                request_state <= ARP_TABLE_REQUEST;
              else
                request_state <= IDLE;
              end if;

            when ARP_TABLE_REQUEST =>
              request_state <= ARP_TABLE_READ;

            when ARP_TABLE_READ =>
              if reco_mac_found_i = '1' then
                -- take IP address from table
                reco_mac <= reco_mac_i;
                reco_mac_done <= '1';

                request_state <= IDLE;
              else
                -- initiate ARP request
                request_en <= '1';
                request_ip <= reco_ip_i;

                request_state <= ARP_WAIT_RESPONSE;
              end if;

            when ARP_WAIT_RESPONSE =>
              reco_en_i <= '1';

              if reco_mac_found_i = '1' then
                -- take ip address from table
                reco_mac <= reco_mac_i;
                reco_mac_done <= '1';
                request_en <= '0';

                request_state <= IDLE;
              elsif request_timeout = '1' then
                reco_mac <= MAC_BROADCAST_ADDR;
                reco_mac_done <= '1';
                request_en <= '0';

                request_state <= IDLE;
              else
                request_state <= ARP_WAIT_RESPONSE;
              end if;

          end case;
        end if;
      end if;
    end process;

    request_timout_block: block is
      --! @name Signals to steer request_timeout
      --! @{

      --! counter reset
      signal cnt_rst  : std_logic := '0';
      --! counter enable
      signal cnt_en   : std_logic := '0';
      --! @}
    begin
      cnt_rst <= '1' when request_state = ARP_TABLE_READ else '0';
      cnt_en <= '1' when one_ms_tick = '1' and request_state = ARP_WAIT_RESPONSE else '0';

      --! Instantiate counting to generate request_timeout
      request_timeout_counter: entity misc.counting
      generic map (
        counter_max_value => ARP_TIMEOUT
      )
      port map (
        clk     => clk,
        rst     => cnt_rst,
        en      => cnt_en,

        cycle_done  => request_timeout
      );
    end block;

    --! Instantiate port_io_table as ARP table
    arp_table_inst: entity ethernet_lib.port_io_table
    generic map (
      -- IP
      PIN_WIDTH     => 32,
      -- MAC
      POUT_WIDTH    => 48,
      -- Depth
      TABLE_DEPTH   => ARP_TABLE_DEPTH
    )
    port map (
      clk           => clk,
      rst           => rst,
      -- Interface for writing new discovered MAC and IP to ARP table
      disco_wren    => disco_wren,
      disco_pin     => disco_ip,
      disco_pout    => disco_mac,
      -- interface for recovered mac address from given ip address
      reco_en       => reco_en_i,
      reco_pin      => reco_ip_i,
      -- response (next clk)
      reco_found    => reco_mac_found_i,
      reco_pout     => reco_mac_i,
      -- status of the ARP table, see definitions below
      status_vector => arptbl_status_vector
      -- one could make the move to indicate the number of occupied entries instead...
      -- that would make status_vector a table_depth-dependent length vector
    );

  end block;

end behavioral;
