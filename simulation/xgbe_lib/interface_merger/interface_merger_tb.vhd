-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Testbench for interface_merger.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details Generates the environment for the interface_merger.vhd.
--! Two AVST streams are pushed through the interface merger, data is read from
--! the respective files AVST1_RXD_FILE and AVST2_RXD_FILE.
--! The result is written to AVST_TXD_FILE.
-------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Testbench for interface_merger.vhd
entity interface_merger_tb is
  generic (
    --! File containing the AVST1 RX data
    AVST1_RXD_FILE      : string := "sim_data_files/AVST1_data_in.dat";
    --! File containing the AVST2 RX data
    AVST2_RXD_FILE      : string := "sim_data_files/AVST2_data_in.dat";
    --! File containing counters on which the RX interface is not ready
    AVST_RDY_FILE       : string := "sim_data_files/AVST_rx_ready_in.dat";
    --! File to write out the response of the module
    AVST_TXD_FILE       : string := "sim_data_files/AVST_data_out.dat";
    -- file containing counters on which a manual reset is carried out
    MNL_RST_FILE        : string := "sim_data_files/MNL_RST_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG        : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG        : character := '@';

    --! Width of the input data interface
    DATA_W              : integer range 1 to 128 := 64;
    --! Width of the empty indicator of the input data interface
    EMPTY_W             : integer range 1 to 128 := 3;

    --! Enable or disable interface interruption (interface locking)
    INTERRUPT_ENABLE    : boolean := false;
    --! If true, a one clock idle is generated after each frame.
    GAP_ENABLE          : boolean := false
  );
end interface_merger_tb;

--! @cond
library sim;
library misc;
library xgbe_lib;
--! @endcond

--! Implementation of interface_merger_tb
architecture tb of interface_merger_tb is

  --! Clock
  signal clk              : std_logic;
  --! reset, sync with #clk
  signal rst              : std_logic;

  --! @name Avalon-ST (first priority interface) to module (read from file)
  --! @{

  --! TX ready
  signal avst1_tx_ready   : std_logic;
  --! TX data and controls
  signal avst1_tx_packet  : t_avst_packet(data(DATA_W-1 downto 0), empty(EMPTY_W-1 downto 0), error(0 downto 0));

  --! @}

  --! @name Avalon-ST (second priority interface) to module (read from file)
  --! @{

  --! TX ready
  signal avst2_tx_ready   : std_logic;
  --! TX data and controls
  signal avst2_tx_packet  : t_avst_packet(data(DATA_W-1 downto 0), empty(EMPTY_W-1 downto 0), error(0 downto 0));

  --! @}

  --! @name Avalon-ST from module (written to file)
  --! @{

  --! RX ready
  signal avst_rx_ready    : std_logic;
  --! RX data and controls
  signal avst_rx_packet   : t_avst_packet(data(DATA_W-1 downto 0), empty(EMPTY_W-1 downto 0), error(0 downto 0));

  --! @}

  --! Status of the module
  signal status_vector    : std_logic_vector(2 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut: entity xgbe_lib.interface_merger
  generic map (
    DATA_W            => DATA_W,
    EMPTY_W           => EMPTY_W,
    INTERRUPT_ENABLE  => INTERRUPT_ENABLE,
    GAP_ENABLE        => GAP_ENABLE
  )
  port map (
    clk               => clk,
    rst               => rst,

    -- avalon-st from first priority module
    avst1_rx_ready_o  => avst1_tx_ready,
    avst1_rx_packet_i => avst1_tx_packet,

    -- avalon-st from second priority module
    avst2_rx_ready_o  => avst2_tx_ready,
    avst2_rx_packet_i => avst2_tx_packet,

    -- avalon-st to outer module
    avst_tx_ready_i   => avst_rx_ready,
    avst_tx_packet_o  => avst_rx_packet,

    -- status of the module, see definitions below
    status_vector_o   => status_vector
  );

  -- Simulation part
  -- generating stimuli based on counter
  blk_simulation : block
    signal counter    : integer := 0;
    signal sim_rst    : std_logic;
    signal mnl_rst    : std_logic;
  begin

    --! Instantiate simulation_basics to start
    inst_sim_basics : entity sim.simulation_basics
    generic map (
      RESET_DURATION  => 5,
      CLK_OFFSET      => 0 ns,
      CLK_PERIOD      => 6.4 ns
    )
    port map (
      clk => clk,
      rst => sim_rst,
      cnt => counter
    );

    --! Instantiate counter_matcher to read mnl_rst from MNL_RST_FILE
    inst_mnl_rst : entity sim.counter_matcher
    generic map (
      FILENAME      => MNL_RST_FILE,
      COMMENT_FLAG  => COMMENT_FLAG
    )
    port map (
      clk       => clk,
      rst       => '0',
      counter   => counter,
      stimulus  => mnl_rst
    );

    rst <= sim_rst or mnl_rst;

    --! Instantiate avst_packet_sender to read avst1_tx from AVST1_RXD_FILE
    inst_avst1_tx : entity xgbe_lib.avst_packet_sender
    generic map (
      FILENAME      => AVST1_RXD_FILE,
      COMMENT_FLAG  => COMMENT_FLAG,
      COUNTER_FLAG  => COUNTER_FLAG
    )
    port map (
      clk       => clk,
      rst       => rst,
      cnt       => counter,

      tx_ready  => avst1_tx_ready,
      tx_packet => avst1_tx_packet
    );

    --! Instantiate avst_packet_sender to read avst2_tx from AVST2_RXD_FILE
    inst_avst2_tx : entity xgbe_lib.avst_packet_sender
    generic map (
      FILENAME      => AVST2_RXD_FILE,
      COMMENT_FLAG  => COMMENT_FLAG,
      COUNTER_FLAG  => COUNTER_FLAG
    )
    port map (
      clk       => clk,
      rst       => rst,
      cnt       => counter,

      tx_ready  => avst2_tx_ready,
      tx_packet => avst2_tx_packet
    );

    --! Instantiate avst_packet_receiver to write eth_rx to ETH_TXD_FILE
    inst_rx : entity xgbe_lib.avst_packet_receiver
    generic map (
      READY_FILE    => AVST_RDY_FILE,
      DATA_FILE     => AVST_TXD_FILE,
      COMMENT_FLAG  => COMMENT_FLAG
    )
    port map (
      clk       => clk,
      rst       => rst,
      cnt       => counter,

      rx_ready  => avst_rx_ready,
      rx_packet => avst_rx_packet
    );

  end block;

end tb;
