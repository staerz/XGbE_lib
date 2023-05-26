-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief ARP request responder (and generator) according to RFC 826
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details
--! Watches for ARP requests dedicated to this client, referred by the
--! IP address configured in "my_ip_i".
--! The MAC address of the core has to be provided at all times to "my_mac_i".
--! The incoming interface expects the raw ARP packet (Ethernet header
--! already stripped off), but will respond with the Ethernet header for
--! an easier implementation in the hierarchy upper module.
--!
--! Multiple ARP requests entering while arp_tx_ready_i is indicating busy are
--! stored in a FIFO and will be answered when the TX interface is free again.
--!
--! The incoming packet's MAC and IP address are discovered and provided in one
--! single clock cycle to the 'disco' interface for an eventual storage in an
--! external ARP table.
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! ARP request responder (and generator) according to RFC 826

entity arp_module is
  generic (
    --! Timeout in milliseconds
    ARP_TIMEOUT       : integer range 2 to 1000 := 50;
    --! Cycle time in milliseconds for ARP requests (when repetitions are needed)
    ARP_REQUEST_CYCLE : integer range 1 to 1000 := 2;
    --! Depth of ARP table (number of stored connections)
    ARP_TABLE_DEPTH   : integer range 1 to 1024 := 4
  );
  port (
    --! Clock
    clk             : in    std_logic;
    --! Reset, sync with #clk
    rst             : in    std_logic;

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

    --! @name Interface for recovering MAC address from given IP address
    --! @{

    --! Recovery enable
    reco_en_i       : in    std_logic;
    --! IP address to recover
    reco_ip_i       : in    std_logic_vector(31 downto 0);
    --! Recovered MAC address (MAC_BROADCAST_ADDR upon timeout)
    reco_mac_o      : out   std_logic_vector(47 downto 0);
    --! Recovery done indicator: 1 = found or timeout
    reco_done_o     : out   std_logic;
    --! @}

    --! MAC address of the module
    my_mac_i        : in    std_logic_vector(47 downto 0);
    --! IP address of the module
    my_ip_i         : in    std_logic_vector(31 downto 0);
    --! Valid indicator of the IP address of the module
    my_ip_valid_i   : in    std_logic;

    --! Clock cycle when 1 millisecond is passed
    one_ms_tick_i   : in    std_logic;

    --! @brief Status of the module
    --! @details Status of the module
    --! - 4: ARP table full
    --! - 3: ARP table empty
    --! - 2: ARP request is being received
    --! - 1: ARP request is being answered
    --! - 0: Data is being forwarded
    status_vector_o : out   std_logic_vector(4 downto 0)
  );
end entity arp_module;

--! @cond
library xgbe_lib;
library misc;
library memory;
--! @endcond

--! Implementation of the arp_module
architecture behavioral of arp_module is

  --  signals controlling the FIFO data flow
  --! FIFO reset
  signal arp_fifo_rst   : std_logic;
  --! FIFO data in
  signal arp_fifo_din   : std_logic_vector(79 downto 0);
  --! FIRO write enable
  signal arp_fifo_wen   : std_logic;
  --! FIFO read enable
  signal arp_fifo_ren   : std_logic;
  --! FIFO data out
  signal arp_fifo_dout  : std_logic_vector(79 downto 0);
  --! FIFO full
  signal arp_fifo_full  : std_logic;
  --! FIFO empty
  signal arp_fifo_empty : std_logic;

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

begin

  assert ARP_REQUEST_CYCLE < ARP_TIMEOUT
    report "ARP_REQUEST_CYCLE must be smaller than ARP_TIMEOUT!"
    severity failure;

  blk_fifo_handler : block
  begin

    --! @brief FIFO to store MAC and IP addresses of requesting ARP packets
    --! @details
    --! Depth requirements for this FIFO = maximum number of requests during TX forwarding
    --! normal packet: 1500 byte: 42 bytes unpadded, 64 bytes padded = 36 .. 24 packets
    --! jumbo packets: 9000 byte: 42 bytes unpadded, 64 bytes padded = 215 .. 140 packets
    --!
    --! Width: storing MAC (6 bytes) + IP (4 bytes) requires 10 bytes = 80 bit)
    inst_arp_fifo : entity memory.generic_fifo
    generic map (
      WR_D_WIDTH => 80,
      WR_D_DEPTH => 256
    )
    port map (
      rst      => arp_fifo_rst,
      wr_clk   => clk,
      wr_en    => arp_fifo_wen,
      wr_data  => arp_fifo_din,
      rd_clk   => clk,
      rd_en    => arp_fifo_ren,
      rd_data  => arp_fifo_dout,
      rd_full  => arp_fifo_full,
      rd_empty => arp_fifo_empty
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
    end process proc_fifo_rst;

  end block blk_fifo_handler;

  -- Transmitter part
  blk_make_tx_interface : block
    --! Counter for outgoing ARP response packet
    signal tx_count : integer range 0 to 9;

    --! @brief State definition for the TX FSM
    --! @details
    --! State definition for the TX FSM
    --! - IDLE:          no transmission running
    --! - ARP_RESPONSE:  ARP response is being sent
    --! - ARP_REQUEST:   ARP request is being sent
    type t_tx_state is (IDLE, ARP_RESPONSE, ARP_REQUEST);

    --! State of the TX FSM
    signal tx_state : t_tx_state;

    --! Register to temporarily store target MAC, used in TX path only and fed by FIFO
    signal config_tg_mac : std_logic_vector(47 downto 0);
    --! Register to temporarily store target IP, used in TX path only and fed by FIFO
    signal config_tg_ip  : std_logic_vector(31 downto 0);

    --! Indicator if pair of MAC and IP address have been received
    signal arp_data_loaded : std_logic;

    --! @brief State definition for the FIFO FSM
    --! @details
    --! State definition for the FIFO FSM
    --! - IDLE:     Nothing happening
    --! - PRE_READ: Set read request
    --! - READ:     Read data from FIFO
    --! - HOLD:     Wait until read data is properly processed by TX module
    type t_fifo_state is (IDLE, PRE_READ, READ, HOLD);

    --! State of the FIFO FSM

    -- vsg_disable_next_line signal_007
    signal fifo_state : t_fifo_state := IDLE;
  begin

    status_vector_o(0) <= '1' when arp_tx_ready_i = '0' else '0';
    status_vector_o(1) <= '1' when tx_state = arp_response else '0';

    -- arp_tx_packet_o   <= see state machine;

    arp_tx_packet_o.valid <= '1' when tx_count >= 1 and tx_count <= 6 else '0';
    arp_tx_packet_o.sop   <= '1' when tx_count = 1 else '0';
    arp_tx_packet_o.eop   <= '1' when tx_count = 6 else '0';
    arp_tx_packet_o.error <= "0";

    with tx_count select arp_tx_packet_o.empty <=
      "000" when 1 to 5,
      "110" when 6,
      "000" when others;

    --! @brief Counting the clks being in the ARP mode
    --! which is similar to the packets of 8 bytes to be sent
    proc_count : process (clk)
    begin
      if rising_edge(clk) then
        -- reset of tx_count on input reset or not when in ARP state
        if rst = '1' or tx_state = IDLE then
          tx_count <= 0;
        -- keep counting otherwise
        elsif tx_state /= IDLE and arp_tx_ready_i = '1' then
          tx_count <= tx_count + 1;
        end if;
      end if;
    end process proc_count;

    blk_gen_tx_data : block
      signal target_mac    : std_logic_vector(47 downto 0);
      signal target_ip     : std_logic_vector(31 downto 0);
      signal target_ip_tmp : std_logic_vector(31 downto 0);
      signal send_request  : std_logic;
      signal arp_operation : std_logic_vector(15 downto 0);
    begin

      blk_send_request : block
        signal cnt_rst : std_logic;
        signal cnt_en  : std_logic;
      begin

        cnt_en <= one_ms_tick_i and request_en;

        cnt_rst <= not request_en;

        inst_request_timeout_counter : entity misc.counting
        generic map (
          COUNTER_MAX_VALUE => ARP_REQUEST_CYCLE
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
      -- the complete Ethernet packet is created for easiness of the upper layer module
      -- vsg_off comment_010
      with tx_count select arp_tx_packet_o.data <=
        -- destination mac (6 bytes)
        target_mac &
        -- + first 2 bytes source MAC
        -- last 4 bytes source MAC
        my_mac_i(47 downto 32)
          when 1,
        my_mac_i(31 downto 0) &
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
        my_mac_i(47 downto 32)
          when 3,
        -- last 4 bytes source MAC address
        my_mac_i(31 downto 0) &
        -- source IP address
        my_ip_i
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

      -- vsg_on comment_010
      --! Read FIFO and make disco interface
      proc_fifo_reader : process (clk)
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
                fifo_state <= IDLE;
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
      end process proc_fifo_reader;

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
      end process proc_tx_state;

    end block blk_gen_tx_data;

  end block blk_make_tx_interface;

  -- Receiver part
  blk_make_rx_interface : block
    --! @brief State definition for the RX FSM
    --! @details
    --! State definition for the RX FSM
    --! - HEADER: checks all requirement of the incoming ARP packet
    --! - SKIP: skips all packets until EOF (if header is wrong)
    --! - STORING_TG: indicates successful extraction of ARP target MAC and IP

    type   t_rx_state is (HEADER, SKIP, STORING_TG);
    --! States of the RX FSM
    signal rx_state : t_rx_state;

    --! ARP RX type: '0': response, '1': request
    signal rx_type : std_logic;

    --! Internal ready signal
    signal arp_rx_ready_r : std_logic;

    --! Counter for incoming packets: max possible = jumbo packet (9000 bytes = 1125 packets)
    signal rx_count    : integer range 0 to 1125;
    --! Register receiving data
    signal rx_data_reg : std_logic_vector(63 downto 0);
    --! Register receiving controls
    signal rx_ctrl_reg : std_logic_vector(6 downto 0);

    --! @name Register to extract relevant data of incoming (ARP) packets:
    --! These signals serve the RX path and extract data blindly
    --! @{

    --! Requesting MAC
    signal rx_data_copy_tg_mac : std_logic_vector(47 downto 0);
    --! Requesting IP
    signal rx_data_copy_tg_ip  : std_logic_vector(31 downto 0);
    --! @}

    --! Control for retrieving ARP target (requester) and storing data - may be optimized away
    signal config_tg_en   : std_logic;
    --! Indicator when to launch an ARP "inform" packet
    signal my_ip_announce : std_logic;
  begin

    status_vector_o(2) <= '1' when rx_state = STORING_TG else '0';

    -- receiver is always ready when the FIFO is not full
    arp_rx_ready_r <= not arp_fifo_full;

    arp_rx_ready_o <= arp_rx_ready_r;

    --! Counting the packets of 8 bytes received
    proc_manage_rx_count_from_rx_sop : process (clk)
    begin
      if rising_edge(clk) then
        -- reset counter
        if (rst = '1') then
          rx_data_reg <= (others => '0');
          rx_ctrl_reg <= (others => '0');
          rx_count    <= 0;
        -- prevent from overwriting last received valid ARP data
        elsif arp_rx_packet_i.valid = '1' and arp_rx_ready_r = '1' then
          rx_data_reg <= arp_rx_packet_i.data;
          rx_ctrl_reg <= avst_ctrl(arp_rx_packet_i);
          -- ... sop initializes counter
          if arp_rx_packet_i.sop = '1' then
            rx_count <= 1;
          -- ... otherwise keep counting
          else
            rx_count <= rx_count + 1;
          end if;
        end if;
      end if;
    end process proc_manage_rx_count_from_rx_sop;

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
          rx_data_copy_tg_mac              <= rx_data_reg(63 downto 16);
          rx_data_copy_tg_ip(31 downto 16) <= rx_data_reg(15 downto 0);
        else
          -- just store
          rx_data_copy_tg_mac              <= rx_data_copy_tg_mac;
          rx_data_copy_tg_ip(31 downto 16) <= rx_data_copy_tg_ip(31 downto 16);
        end if;

        if rx_count = 3 then
          rx_data_copy_tg_ip(15 downto 0) <= rx_data_reg(63 downto 48);
        else
          -- just store
          rx_data_copy_tg_ip(15 downto 0) <= rx_data_copy_tg_ip(15 downto 0);
        end if;
      end if;
    end process proc_extract_rx_data_copy;

    -- eventually enable data storing and make blindly stored data permanent
    config_tg_en <= '1' when rx_state = STORING_TG else '0';

    --! Convert correct configuration indicator to one-hot to trigger ARP inform from it
    inst_my_ip_announce : entity misc.hilo_detect
    generic map (
      LOHI => true
    )
    port map (
      clk     => clk,
      sig_in  => my_ip_valid_i,
      sig_out => my_ip_announce
    );

    --! Writing ARP identifiers to the FIFO
    proc_fifo_writer : process (clk)
    begin
      if rising_edge(clk) then
        -- write broadcast data (to announce own IP to everyone)
        if my_ip_announce = '1' then
          arp_fifo_din <= (others => '1');
          arp_fifo_wen <= '1';
        -- write extracted values from RX packet (to reply to request)
        elsif config_tg_en = '1' and rx_type = '1' then
          arp_fifo_din <= rx_data_copy_tg_mac & rx_data_copy_tg_ip;
          arp_fifo_wen <= '1';
        else
          -- don't care about data
          arp_fifo_din <= (others => '-');
          arp_fifo_wen <= '0';
        end if;
      end if;
    end process proc_fifo_writer;

    --! Writing the extracted values to the ARP table
    proc_arp_table_writer : process (clk)
    begin
      if rising_edge(clk) then
        if config_tg_en = '1' then
          disco_mac  <= rx_data_copy_tg_mac;
          disco_ip   <= rx_data_copy_tg_ip;
          disco_wren <= '1';
        else
          disco_mac  <= (others => '-');
          disco_ip   <= (others => '-');
          disco_wren <= '0';
        end if;
      end if;
    end process proc_arp_table_writer;

    --! @brief FSM to handle ARP requests.
    --! @details
    --! Analysing incoming data packets and checking them for ARP content.
    --! Extract relevant ARP data if it is an ARP packet.
    proc_rx_state : process (clk)
    begin

      if rising_edge(clk) then
        -- reset or sop indicate new header
        if (rst = '1') or (arp_rx_packet_i.sop = '1') then
          rx_state <= HEADER;
        elsif arp_rx_ready_r = '1' then

          case rx_state is

            -- check header data
            when HEADER =>

              case rx_count is

                when 0 =>
                  rx_state <= HEADER;

                when 1 =>
                  -- vsg_off if_035 if_009
                  -- check for supported header (IPv4 on Ethernet)
                  if rx_data_reg(63 downto 48) /= x"0001" or  -- HW-type Ethernet
                    rx_data_reg(47 downto 32) /= x"0800" or   -- protocol type: IP
                    rx_data_reg(31 downto 16) /= x"0604" then -- HW-size: 6, P-size: 4
                    rx_state <= SKIP;
                  -- vsg_on if_035 if_009
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

                when 4 =>
                  -- requested IP address must match and it mustn't be an error packet
                  if rx_data_reg(63 downto 32) /= my_ip_i or rx_ctrl_reg(4 downto 3) = "11" then
                    rx_state <= SKIP;
                  else
                    rx_state <= STORING_TG;
                  end if;

                -- when 2, 3 => MAC and IP data is copied from reg in process extract_rx_data_copy
                when others =>
                  rx_state <= HEADER;

              end case;

            -- store source MAC and IP
            -- may only be assigned for one clk
            when STORING_TG =>
              -- or twice in a row as IP announcement has prio!
              if my_ip_announce = '1' then
                rx_state <= STORING_TG;
              else
                rx_state <= SKIP;
              end if;

            -- just let pass all other data
            -- new HEADER state is captured by reset condition of FSM
            when SKIP =>
              rx_state <= SKIP;

          end case;

        end if;
      end if;
    end process proc_rx_state;

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
        COUNTER_MAX_VALUE => ARP_TIMEOUT
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
      TABLE_DEPTH => ARP_TABLE_DEPTH
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
