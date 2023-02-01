-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief RX FIFO module to buffer packet and decouple from rx_ready.
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details
--! Buffers incoming packets in a FIFO to guaranty a stable "rx_ready = '1'"
--! during a packet reception for the connected outer module.
--!
--! Does NOT support jumbo packets.
--!
--! @todo on eop check error: if set, drop the packet from the FIFO...
--! @todo in not locked case (LOCK_FIFO = false): check if the outcoming packet is complete:
--! the packet might be dropped whilst writing into FIFO...
--! @todo Rename rx_fifo_in_* to FIFO_RX_*, rx_fifo_out_* to FIFO_TX_*
--! @todo Rename module to avst_fifo_module
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! RX FIFO module to buffer packet and decouple from rx_ready.
entity rx_fifo_module is
  generic (
    --! @brief Locking the FIFO on the writing side
    --! @details
    --! LOCK_FIFO = true:
    --!
    --! Once a packet is received, the FIFO is locked to not receive any more
    --! packets (rx_ready = '0') until the FIFO is empty again.
    --!
    --! If the rx_ready = '0' indication is not respected whilst in LOCK state,
    --! the packet is simply discarded.
    --! After recovery from the LOCK state, only full packets (re-starting on sop)
    --! will be captured to ensure packet integrity.
    --!
    --! LOCK_FIFO = false:
    --!
    --! The FIFO is locked (rx_ready = '0') for 1 cycle only to add an empty word.
    --! After that, the next packet can be stored into the FIFO.
    --! Nevertheless, upon a filled FIFO, rx_ready will return to '1'.
    --! If still data is forced in, it is lost.
    --! @todo Rename to LOCK_FIFO_RX
    LOCK_FIFO     : boolean := true;
    --! @brief Locking the FIFO on the reading side
    --! @details
    --! LOCK_FIFO_OUT = true:
    --!
    --! Reading of the FIFO may only start after the reception of a full packet
    --! (capturing the end-of-packet delimiter) to ensure packet integrity.
    --!
    --! LOCK_FIFO_OUT = true:
    --!
    --! Reading of the FIFO may start as soon as there are enough words in the
    --! FIFO to start sending of the data.
    --! @todo Rename to LOCK_FIFO_TX
    LOCK_FIFO_OUT : boolean := false;
    --! @brief Enable true dual clock mode or not.
    --! @details if dual clock is enabled, clk_o must be provided.
    DUAL_CLK      : boolean := false
  );
  port (
    --! Reset, sync with clk_i
    rst_i           : in    std_logic;

    --! @name Avalon-ST FIFO RX interface to load FIFO
    --! @{

    --! RX clock
    clk_i           : in    std_logic;
    --! RX ready
    rx_ready_o      : out   std_logic;
    --! RX data and controls
    rx_packet_i     : in    t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @name Avalon-ST FIFO TX interface to empty FIFO
    --! @{

    --! TX clock
    --! @todo: maybe setting a default value (as that's an optional port!?)
    clk_o           : in    std_logic;
    --! TX ready
    tx_ready_i      : in    std_logic;
    --! TX data and controls
    tx_packet_o     : out   t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! @}

    --! @brief Status of the module
    --! @details Status of the module
    --! - 4: rx_fifo_rd_full
    --! - 3: rx_fifo_rd_empty
    --! - 2: rx_fifo_wen
    --! - 1: rx_fifo_wr_full
    --! - 0: rx_fifo_wr_empty
    status_vector_o : out   std_logic_vector(4 downto 0)
  );
end entity rx_fifo_module;

--! @cond
library xgbe_lib;
library misc;
library memory;
--! @endcond

--! Implementation of the rx_fifo_module
architecture behavioral of rx_fifo_module is

  --! @name Signals controlling the FIFO data flow
  --! @{

  --! Reset
  signal rx_fifo_rst      : std_logic;
  --! Data in
  signal rx_fifo_din      : std_logic_vector(7 + 63 downto 0);
  --! Write enable
  signal rx_fifo_wen      : std_logic;
  --! Read enable
  signal rx_fifo_ren      : std_logic;
  --! Data out
  signal rx_fifo_dout     : std_logic_vector(7 + 63 downto 0);
  --! Read full
  signal rx_fifo_rd_full  : std_logic;
  --! Read empty
  signal rx_fifo_rd_empty : std_logic;
  --! Write full
  signal rx_fifo_wr_full  : std_logic;
  --! Write empty
  signal rx_fifo_wr_empty : std_logic;
  --! @}

  --! @brief State definition for the RX FSM
  --! @details
  --! State definition for the RX FSM
  --! - IDLE:  Waiting for incoming packet
  --! - WRITE: Incoming packet is written to FIFO
  --! - LOCK:  Data is read from FIFO until it's empty again
  type t_fifo_state is (IDLE, WRITE, LOCK);

  --! State of the RX FSM

  -- vsg_disable_next_line signal_007
  signal fifo_state : t_fifo_state := LOCK;

  --! FIFO reset
  signal fifo_rst        : std_logic;
  --! FIFO read enable permit
  signal fifo_ren_permit : std_logic;

begin

  status_vector_o <= rx_fifo_rd_full & rx_fifo_rd_empty & rx_fifo_wen & rx_fifo_wr_full & rx_fifo_wr_empty;

  --! @brief Instantiate the generic_fifo to store incoming data
  --! @details
  --! Depth requirements for this FIFO = maximum length of an incoming packet
  --! - Normal packet: 1520 byte, at 8 bytes per clk = 190
  --! - Jumbo packets: 9000 byte, at 8 bytes per clk = 1125
  --!
  --! Width: data width (64 bit) + width of all controls (7)
  inst_fifo : entity memory.generic_fifo
  generic map (
    WR_D_WIDTH => rx_fifo_din'length,
    WR_D_DEPTH => 256,
    DUAL_CLK   => DUAL_CLK
  )
  port map (
    rst => rx_fifo_rst,

    wr_clk   => clk_i,
    wr_en    => rx_fifo_wen,
    wr_data  => rx_fifo_din,
    wr_empty => rx_fifo_wr_empty,
    wr_full  => rx_fifo_wr_full,

    rd_clk   => clk_o,
    rd_en    => rx_fifo_ren,
    rd_data  => rx_fifo_dout,
    rd_empty => rx_fifo_rd_empty,
    rd_full  => rx_fifo_rd_full
  );

  --! Derive fifo_rst from rst_i using hilo_detect
  inst_fifo_rst_hilo : entity misc.hilo_detect
  generic map (
    LOHI => false
  )
  port map (
    clk     => clk_i,
    sig_in  => rst_i,
    sig_out => fifo_rst
  );

  --! @brief Reset FIFO from rst_i
  --! @todo Why is that not done simply via a simply assignment?
  proc_fifo_rst : process (clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        rx_fifo_rst <= '1';
      else
        rx_fifo_rst <= '0';
      end if;
    end if;
  end process proc_fifo_rst;

  --! Handling the writing of input data into the FIFO
  proc_fifo_writer : process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        rx_fifo_din <= (others => '-');
        rx_fifo_wen <= '0';
      -- vsg_off if_035 if_009
      elsif
        -- insert one empty word into the FIFO
        -- upon reset to have clear zero output
        (fifo_rst = '1') or
        -- and at the end of a packet
        (rx_fifo_wr_full = '0' and rx_fifo_din(68) = '1')
      then
        rx_fifo_din <= (others => '0');
        rx_fifo_wen <= '1';
      elsif
        -- only store from the beginning of a packet
        (rx_fifo_wr_full = '0') and
        ((fifo_state = IDLE and rx_packet_i.sop = '1') or fifo_state = WRITE)
      then
        -- vsg_on if_035 if_009
        rx_fifo_din <= avst_ctrl(rx_packet_i) & rx_packet_i.data;
        rx_fifo_wen <= rx_packet_i.valid;
      else
        -- just don't write into FIFO
        rx_fifo_din <= (others => '-');
        rx_fifo_wen <= '0';
      end if;
    end if;
  end process proc_fifo_writer;

  --! FIFO RX FSM
  proc_fifo_locker : process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        -- IDLE is not the default, it's LOCK
        -- On reset, an empty word is written to FIFO first.
        -- This is immediately read out -> it becomes empty
        -- -> state goes to IDLE
        fifo_state <= LOCK;
      else

        case fifo_state is

          when IDLE =>
            if rx_packet_i.eop = '1' then
              -- one word transmission...
              fifo_state <= LOCK;
            elsif rx_packet_i.sop = '1' then
              fifo_state <= WRITE;
            else
              fifo_state <= IDLE;
            end if;

          when WRITE =>
            if rx_packet_i.eop = '1' then
              -- generate at least one cycle state LOCK to ensure to have time to store an empty word in FIFO
              fifo_state <= LOCK;
            else
              fifo_state <= WRITE;
            end if;

          when LOCK =>
            -- lock or not in dependence of generic:
            if LOCK_FIFO then
              if rx_fifo_wr_empty = '1' then
                fifo_state <= IDLE;
              else
                fifo_state <= LOCK;
              end if;
            else
              fifo_state <= IDLE;
            end if;

        end case;

      end if;
    end if;
  end process proc_fifo_locker;

  with fifo_state select rx_ready_o <=
    '0' when LOCK,
    not rx_fifo_wr_full when others;

  -- Generating FIFO read permit depending on LOCK_FIFO_OUT

  gen_lock_fifo_out_off : if not LOCK_FIFO_OUT generate
    -- still need at least one clk delay to guarantee continuous data out flow
    signal ren_delay : std_logic_vector(2 downto 0);
  begin

    --! FIFO is not read locked: It can be read as soon as it's not empty (with a little delay)
    proc_ren_delay : process (clk_o)
    begin
      if rising_edge(clk_o) then
        if rx_fifo_rd_empty = '1' then
          ren_delay <= (others => '0');
        elsif tx_ready_i = '1' then
          ren_delay <= ren_delay(ren_delay'left - 1 downto 0) & not rx_fifo_rd_empty;
        else
          ren_delay <= ren_delay;
        end if;
      end if;
    end process proc_ren_delay;

    fifo_ren_permit <= ren_delay(ren_delay'left);
  end generate gen_lock_fifo_out_off;

  -- else

  gen_lock_fifo_out_on : if LOCK_FIFO_OUT generate
    signal read_ready : std_logic;
  begin

    --! FIFO is read locked: It can only be read as soon as having detected the eop in the incoming packet
    proc_fifo_out_locker : process (clk_i)
    begin
      if rising_edge(clk_i) then
        if rst_i = '1' then
          read_ready <= '0';
        elsif fifo_state /= LOCK and rx_packet_i.eop = '1' then
          read_ready <= '1';
        elsif rx_fifo_wr_empty = '1' then
          read_ready <= '0';
        end if;
      end if;
    end process proc_fifo_out_locker;

    --! Give read permit on output clock domain
    proc_fifo_out_reader : process (clk_o)
    begin
      if rising_edge(clk_o) then
        fifo_ren_permit <= read_ready;
      end if;
    end process proc_fifo_out_reader;

  end generate gen_lock_fifo_out_on;

  -- read FIFO when destination is ready and data is available and read is permitted
  rx_fifo_ren <= tx_ready_i and not rx_fifo_rd_empty and fifo_ren_permit;

  blk_tx : block
    --! Width of the input data interface
    constant DATA_W  : integer range 1 to 128 := 64;
    --! Width of the empty indicator of the input data interface
    constant EMPTY_W : integer range 1 to 128 := 3;
  begin

    tx_packet_o <= (
      data  => rx_fifo_dout(DATA_W - 1 downto 0),
      valid => rx_fifo_dout(EMPTY_W - 1 + DATA_W + 4),
      sop   => rx_fifo_dout(EMPTY_W - 1 + DATA_W + 3),
      eop   => rx_fifo_dout(EMPTY_W - 1 + DATA_W + 2),
      error => rx_fifo_dout(EMPTY_W - 1 + DATA_W + 1 downto EMPTY_W - 1 + DATA_W + 1),
      empty => rx_fifo_dout(EMPTY_W - 1 + DATA_W downto DATA_W)
    );

  end block blk_tx;

end architecture behavioral;
