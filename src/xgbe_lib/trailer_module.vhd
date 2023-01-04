-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Trailer module to cut off a header from an AVST packet
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details
--! Cuts off the first 'HEADER_LENGTH' bytes of an incoming packet (header) and
--! recreates a new packet only containing the rest of the packet (payload).
--! Proper data shifting and assertion of control flags is done, as well as
--! an overflow protection:
--! The packet will be terminated with an error if the number of transmitted bytes
--! exceeds 'MAX_PACKET_SIZE', all incoming data onwards is discarded.
--!
--! The control signals to be connected are:
--!
--! - rx/tx_ctrl(6)           <= rx/tx_valid
--! - rx/tx_ctrl(5)           <= rx/tx_sop
--! - rx/tx_ctrl(4)           <= rx/tx_eop
--! - rx/tx_ctrl(3)           <= rx/tx_error
--! - rx/tx_ctrl(2 downto 0)  <= rx/tx_empty
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Trailer module to cut off a header from an AVST packet
entity trailer_module is
  generic (
    --! Number of bytes of the header to be cut off
    HEADER_LENGTH   : integer  := 14;
    --! Number of interfaces (if multiple interfaces are used)
    N_INTERFACES    : positive := 1;
    --! (Maximum) packet size in bytes
    MAX_PACKET_SIZE : integer  := 1500
  );
  port (
    --! Clock
    clk         : in    std_logic;
    --! Reset, sync with clk
    rst         : in    std_logic;

    --! @name Avalon-ST RX interface
    --! @{

    --! RX ready
    rx_ready_o  : out   std_logic;
    --! RX data and controls
    rx_packet_i : in    t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! Additional rx indicator if multiple interfaces are used
    rx_mux_i    : in    std_logic_vector(N_INTERFACES - 1 downto 0);

    --! @}

    --! @name Avalon-ST TX interface
    --! @{

    --! TX ready
    tx_ready_i  : in    std_logic;
    --! TX data and controls
    tx_packet_o : out   t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
    --! Additional tx indicator if multiple interfaces are used
    tx_mux_o    : out   std_logic_vector(N_INTERFACES - 1 downto 0);
    --! @}

    --! Counter for the incoming data words
    rx_count_o  : out   integer range 0 to 1600 := 0
  );
end entity trailer_module;

--! Implementation of the trailer module
architecture behavioral of trailer_module is

  --! Word when the data starts (after header)
  constant DATA_START : integer := HEADER_LENGTH / 8 + 1;
  --! If header is not a multiple of 8, a shift is needed
  constant BYTE_SHIFT : integer := 8 - (HEADER_LENGTH mod 8);
  --! Maximum number of expected clock cycles for a packet to last
  constant RX_CNT_MAX : integer := (HEADER_LENGTH + MAX_PACKET_SIZE) / 8 + 1;

  --! Packet word counter
  signal rx_count_r : integer range 0 to RX_CNT_MAX;

  --! Condensed version of controls:
  --! - 11: valid
  --! - 10: sop
  --! - 9, 4: eop (now, next)
  --! - 8, 3: error (now, next)
  --! - 7 downto 5, 2 downto 0: empty (now, next)

  -- vsg_disable_next_line signal_007
  signal ctrl    : std_logic_vector(11 downto 0) := (others => '0');
  --! Data register
  signal rx_dreg : std_logic_vector(63 downto 0);

  --! Valid register
  signal valid_reg  : std_logic;
  --! Eof register
  signal rx_eop_reg : std_logic;

  --! Overflow indicator

  -- vsg_disable_next_line signal_007
  signal rx_overflow : std_logic := '0';
  --! Overflow register
  signal rx_of_reg   : std_logic;

  --! Multiplex registers
  signal tx_mux_reg  : std_logic_vector(N_INTERFACES - 1 downto 0);
  --! Multiplex registers
  signal tx_mux_reg2 : std_logic_vector(N_INTERFACES - 1 downto 0);

begin

  rx_ready_o <= tx_ready_i;
  rx_count_o <= rx_count_r;

  -- set tx_packet control signals
  tx_packet_o.valid <= ctrl(11);
  tx_packet_o.sop   <= ctrl(10);
  tx_packet_o.eop   <= ctrl(9);
  tx_packet_o.error <= ctrl(8 downto 8);
  tx_packet_o.empty <= ctrl(7 downto 5);

  --! Propagate rx_mux_i to tx_mux_o
  proc_tx_mux : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        tx_mux_reg  <= (others => '0');
        tx_mux_reg2 <= (others => '0');
      elsif tx_ready_i = '1' then
        -- default: fade out
        tx_mux_reg  <= rx_mux_i;
        tx_mux_reg2 <= tx_mux_reg;
        if to_integer(unsigned(rx_mux_i)) /= 0 then
          tx_mux_reg2 <= rx_mux_i;
        end if;
      end if;
    end if;
  end process proc_tx_mux;

  with ctrl(11) select tx_mux_o <=
    tx_mux_reg2 when '1',
    (others => '0') when others;

  --! Count the incoming data words (don't care about sop, that's handled by valid)
  proc_rx_count_from_rx_sop : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        rx_count_r <= 0;
      elsif tx_ready_i = '1' then
        -- default: shift flags and reset counter
        rx_eop_reg <= rx_packet_i.eop;
        rx_of_reg  <= rx_overflow;
        rx_count_r <= 0;

        -- reset overflow on eop(reg) of incoming packet
        if rx_eop_reg = '1' then
          rx_overflow <= '0';
        elsif rx_packet_i.valid = '1' and rx_overflow = '0' then
          if rx_count_r < RX_CNT_MAX then
            rx_count_r <= rx_count_r + 1;
          else
            rx_overflow <= '1';
          end if;
        end if;
      end if;
    end if;
  end process proc_rx_count_from_rx_sop;

  --! Generate end of packet indicators (eop, empty)
  --! @todo replace tx_data assignment by function (to prevent warning for BYTE_SHIFT = 8)
  proc_make_trailer : process (clk)
    variable empty  : signed(2 downto 0);
    variable emptyy : signed(4 downto 0);
    variable diff   : signed(14 downto 0);
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        ctrl(9 downto 0) <= (others => '0');
        tx_packet_o.data <= (others => '0');
        rx_dreg          <= (others => '0');
      elsif tx_ready_i = '1' then
        rx_dreg          <= rx_packet_i.data;
        -- make the byte shifting according to the given numbers
        -- the synthesizer may produce a warning here for a null range std_logic_vector
        -- when BYTE_SHIFT is 8, so when HEADER_LENGTH is a multiple of 8
        tx_packet_o.data <=
          rx_dreg((8 * BYTE_SHIFT) - 1 downto 0) &
          rx_packet_i.data(63 downto 8 * BYTE_SHIFT);

        -- default trailer: fade out
        ctrl(9 downto 0) <= ctrl(4 downto 0) & "00000";

        -- take care of the valid flag:
        -- the default is to derive it from the counter (the difference to DATA_START)
        -- but if the eop (= ctrl(9)) has been set, the next is not valid
        -- (the avst interface foresees one empty clk between two packets
        diff      := to_signed(DATA_START, 15) - to_signed(rx_count_r + 1, 15);
        ctrl(11)  <= not ctrl(9) and diff(diff'left);
        -- register valid to determine sop
        valid_reg <= ctrl(11);

        -- check on rising edge of overflow
        if rx_overflow = '1' and rx_of_reg = '0' then
          -- indicate eop with error
          ctrl(11)         <= '1';
          ctrl(9 downto 5) <= "11000";
          ctrl(4 downto 0) <= (others => '0');
        -- in the end: watch out for eop, empty and error
        elsif rx_packet_i.eop = '1' then
          -- take care of the flags to be set at the end of a packet
          -- according to the given numbers:
          --
          --    empty from shift and given rx_packet_i.empty
          --    (use auxiliary variable emptyy to prevent truncate warnings)
          --    error from rx error
          emptyy := to_signed(to_integer(unsigned(rx_packet_i.empty)) + (8 - BYTE_SHIFT), 5);
          empty  := emptyy(2 downto 0);

          if unsigned(rx_packet_i.empty) < BYTE_SHIFT then
            -- ctrl for now
            ctrl(9 downto 5) <= (others => '0');
            -- ctrl for next clk
            ctrl(4 downto 0) <= "1" & rx_packet_i.error & std_logic_vector(empty);
          else
            -- ctrl for now
            ctrl(9 downto 5) <= "1" & rx_packet_i.error & std_logic_vector(empty);
            -- ctrl for next clk
            ctrl(4 downto 0) <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process proc_make_trailer;

  -- independently, look for the sop flag: it's to be set only if the valid rises
  ctrl(10) <= not valid_reg and ctrl(11);

end architecture behavioral;
