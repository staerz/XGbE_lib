-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief ICMP module according to RFC 792
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details
--! Watches for incoming IP frames and checks them being ICMP echo requests.
--! If detected as such, an ICMP response is being produced.
--!
--! Not to block the RX interface, a FIFO is used to store the ICMP request.
--! If an ICMP request is already in the FIFO, further requests will simply be
--! dropped.
--!
--! @todo The is_icmp_request should be removed and instead a full RX FSM
--! analysing the header should be implemented (take from ip_module!) to really
--! seal off module dependencies.
-------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.STD_LOGIC_1164.all;
--! @endcond

entity icmp_module is
  port (
    --! Clock
    clk              : in    std_logic;
    --! Reset, sync with clk
    rst              : in    std_logic;

    --! @name Avalon-ST from IP module
    --! @{

    --! RX ready
    ip_rx_ready      : out   std_logic;
    --! RX data
    ip_rx_data       : in    std_logic_vector(63 downto 0);
    --! RX control
    ip_rx_ctrl       : in    std_logic_vector(6 downto 0);
    --! Indication of being ICMP request
    is_icmp_request  : in    std_logic;
    --! @}

    --! @name Avalon-ST to IP module
    --! @{

    --! TX ready
    icmp_out_ready   : in    std_logic;
    --! TX data
    icmp_out_data    : out   std_logic_vector(63 downto 0);
    --! TX controls
    icmp_out_ctrl    : out   std_logic_vector(6 downto 0);
    --! @}

    --! @brief Status of the module
    --! @details Status of the module
    --! - 2: icmp_tx_ready
    --! - 1: rx_fifo_wr_full
    --! - 0: rx_fifo_wr_empty
    status_vector    : out   std_logic_vector(2 downto 0)
  );
end icmp_module;

--! @cond
library ethernet_lib;
library misc;
--! @endcond

--! Implementation of the icmp_module
architecture behavioral of icmp_module is

  --! Depth of the icmp packet buffer
  --! (not before 4 the icmp_request is triggered)
  constant ICMP_BUFFER_DEPTH : integer range 2 to 10 := 4;

  --! Type to store entire data and controls
  type t_icmp_buffer is array(0 to ICMP_BUFFER_DEPTH) of std_logic_vector(7+63 downto 0);

  --! buffer to temporarily store incoming packet to prepare loopback
  signal icmp_buffer : t_icmp_buffer;
  --! CRC of the ICMP response
  signal icmp_crc    : std_logic_vector(15 downto 0);
  --! replacement of counter
  signal sof_buffer  : std_logic_vector(1 downto 0);

begin

  -- Receive part: the module is always ready to receive data
  ip_rx_ready <= '1';

  --! Store incoming data blindly, is_icmp_request will indicate if it's actually ICMP
  proc_fill_buffer : process (clk) is
  begin
    if rising_edge(clk) then
      if rst = '1' then
        icmp_buffer <= (others => (others => '0'));
        sof_buffer  <= (others => '0');
      else
        -- shift sof bit:
        sof_buffer <= sof_buffer(0) & icmp_buffer(ICMP_BUFFER_DEPTH-1)(69);

        -- MAC produces error on interruption => ignore error by inserting '0' instead;
        icmp_buffer(0) <= ip_rx_ctrl & ip_rx_data;

        icmp_buffer(1 to ICMP_BUFFER_DEPTH) <= icmp_buffer(0 to ICMP_BUFFER_DEPTH-1);
      end if;
    end if;
  end process;

  calculate_icmp_crc : block
    --! CRC reset
    signal crc_rst : std_logic;
    --! CRC for the package being replied
    signal crc_in  : std_logic_vector(15 downto 0);
  begin

    -- combine with the registered sof flag:
    crc_in <=
      -- subtract 8 (corresponding from changing type from 8 to 0) (inverted byte order)
      x"F7FF" when icmp_buffer(0)(69) = '1' else
      not ip_rx_data(15 downto 0) when icmp_buffer(1)(69) = '1' else
      (others => '0');

    with ip_rx_ctrl(5) select crc_rst <=
      '1' when '1',
      '0' when others;

    --! Use checksum_calc to calculate icmp_crc
    crc_calc : entity misc.checksum_calc
    generic map (
      I_WIDTH => 16,
      O_WIDTH => 16
    )
    port map (
      clk     => clk,
      en      => '1',
      rst     => crc_rst,
      data_in => crc_in,
      sum_out => icmp_crc
    );

  end block;

  fifo_block : block
    --! @name Avalon-ST reply sent into FIFO
    --! @{

    --! TX ready
    signal icmp_tx_ready  : std_logic;
    --! TX data
    signal icmp_tx_data   : std_logic_vector(63 downto 0);
    --! TX control
    signal icmp_tx_ctrl   : std_logic_vector(6 downto 0);
    --! @}

    --! Switch for valid ICMP data
    signal valid_data       : std_logic;
    --! Status vector for the instantiated rx_fifo_module
    signal status_vector_i  : std_logic_vector(4 downto 0);
  begin

    --! Mark valid data based on indication by outer module
    proc_reg_request : process (clk) is
    begin
      if rising_edge(clk) then
        -- if the outer module indicated valid data: mark it
        if is_icmp_request = '1' then
          valid_data <= '1';
        -- when the frame is over: unmark it
        elsif icmp_buffer(ICMP_BUFFER_DEPTH-1)(68) = '1' then
          valid_data <= '0';
        end if;
      end if;
    end process;

    icmp_tx_data <=
      -- new source IP addresses = old destination IP address:
      icmp_buffer(ICMP_BUFFER_DEPTH-1)(63 downto 32) & icmp_buffer(ICMP_BUFFER_DEPTH-2)(63 downto 32) when sof_buffer(0) = '1' else
      -- new destination IP address = old source IP address, ICMP code = x"00";
      icmp_buffer(ICMP_BUFFER_DEPTH)(31 downto 0) & x"00" & icmp_buffer(ICMP_BUFFER_DEPTH-1)(23 downto 16) & icmp_crc when sof_buffer(1) = '1' else

      icmp_buffer(ICMP_BUFFER_DEPTH-1)(63 downto 0);

    icmp_tx_ctrl <=
      icmp_buffer(ICMP_BUFFER_DEPTH-1)(70 downto 64) when valid_data = '1' else
      (others => '0');

    -- so far, the header is prepared correctly

    --! Storage of the incoming data into the rx_fifo_module
    icmp_fifo_inst : entity ethernet_lib.rx_fifo_module
    generic map (
      LOCK_FIFO     => false,
      DUAL_CLK      => false
    )
    port map (
      rx_fifo_in_rst    => rst,

      -- avalon-st to fill fifo
      rx_fifo_in_clk    => clk,
      rx_fifo_in_ready  => icmp_tx_ready,
      rx_fifo_in_data   => icmp_tx_data,
      rx_fifo_in_ctrl   => icmp_tx_ctrl,

      -- avalon-st to empty fifo
      rx_fifo_out_clk   => clk,
      rx_fifo_out_ready => icmp_out_ready,
      rx_fifo_out_data  => icmp_out_data,
      rx_fifo_out_ctrl  => icmp_out_ctrl,

      status_vector   => status_vector_i
    );

    status_vector <= icmp_tx_ready & status_vector_i(1 downto 0);
  end block;

end behavioral;
