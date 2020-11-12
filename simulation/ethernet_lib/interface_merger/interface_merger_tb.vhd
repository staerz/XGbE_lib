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
--! the respective files AVST1_DAT_FILENAME and AVST2_DAT_FILENAME.
--! The result is written to AVST_LOG_FILENAME.
-------------------------------------------------------------------------------

--! @cond
library ieee;
  use ieee.std_logic_1164.all;
--! @endcond

entity interface_merger_tb is
  generic (
    --! File containing the AVST1 input data
    AVST1_DAT_FILENAME  : string := "sim_data_files/AVST1_data_in.dat";
    --! File containing the AVST2 input data
    AVST2_DAT_FILENAME  : string := "sim_data_files/AVST2_data_in.dat";
    --! File containing counters on which the rx interface is not ready
    AVST_RX_READY_FILE  : string := "sim_data_files/AVST_rx_ready_in.dat";
    --! File to write out the response of the interface merger
    AVST_LOG_FILENAME   : string := "sim_data_files/AVST_data_out.dat";
    -- file containing counters on which a manual reset is carried out
    MNL_RST_FILE        : string := "sim_data_files/MNL_RST_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG        : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG        : character := '@';
    --! Enable or disable interface interruption (interface locking)
    INTERRUPT_ENABLE    : boolean   := false;
    --! If true, a one clock idle is generated after each frame.
    GAP_ENABLE          : boolean   := false
  );
end interface_merger_tb;

--! @cond
library sim;
library misc;
library ethernet_lib;
--! @endcond

--! Implementation of interface_merger_tb
architecture tb of interface_merger_tb is

  --! Clock
  signal clk              : std_logic;
  --! reset, sync with #clk
  signal rst              : std_logic;

  --! @name Avalon-ST from first priority module
  --! @{

  --! TX ready
  signal avst1_tx_ready   : std_logic;
  --! TX data
  signal avst1_tx_data    : std_logic_vector(63 downto 0);
  --! TX controls
  signal avst1_tx_ctrl    : std_logic_vector(6 downto 0);

  --! @}

  --! @name Avalon-ST from second priority module (being interrupted)
  --! @{

  --! TX ready
  signal avst2_tx_ready   : std_logic;
  --! TX data
  signal avst2_tx_data    : std_logic_vector(63 downto 0);
  --! TX controls
  signal avst2_tx_ctrl    : std_logic_vector(6 downto 0);

  --! @}

  --! @name Avalon-ST to outer world
  --! @{

  --! RX ready
  signal avst_rx_ready    : std_logic;
  --! RX data
  signal avst_rx_data     : std_logic_vector(63 downto 0);
  --! RX controls
  signal avst_rx_ctrl     : std_logic_vector(6 downto 0);

  --! @}

  --! status of the module
  signal status_vector    : std_logic_vector(2 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut: entity ethernet_lib.interface_merger
  generic map (
    INTERRUPT_ENABLE  => INTERRUPT_ENABLE,
    GAP_ENABLE        => GAP_ENABLE
  )
  port map (
    clk               => clk,
    rst               => rst,

    -- avalon-st from first priority module
    avst1_rx_ready    => avst1_tx_ready,
    avst1_rx_data     => avst1_tx_data,
    avst1_rx_ctrl     => avst1_tx_ctrl,

    -- avalon-st from second priority module
    avst2_rx_ready    => avst2_tx_ready,
    avst2_rx_data     => avst2_tx_data,
    avst2_rx_ctrl     => avst2_tx_ctrl,

    -- avalon-st to outer module
    avst_tx_ready     => avst_rx_ready,
    avst_tx_data      => avst_rx_data,
    avst_tx_ctrl      => avst_rx_ctrl,

    -- status of the module, see definitions below
    status_vector     => status_vector
  );

  -- Simulation part
  -- generating stimuli based on counter
  simulation: block
    signal counter    : integer := 0;
    signal async_rst  : std_logic;
    signal sim_rst    : std_logic;
    signal mnl_rst    : std_logic;
  begin

    --! Instantiate simulation_basics to start
    sim_basics: entity sim.simulation_basics
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
    mnl_rst_gen: entity sim.counter_matcher
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

    async_rst <= sim_rst or mnl_rst;

    --! Instantiate delay_chain to generate rst
    rst_sync_inst: entity misc.delay_chain
    port map (
      clk         => clk,
      rst         => '0',
      sig_in(0)   => async_rst,
      sig_out(0)  => rst
    );

    --! Instantiate av_st_sender to read avst1_tx from AVST1_DAT_FILENAME
    avst1_tx_gen: entity sim.av_st_sender
    generic map (
      FILENAME      => AVST1_DAT_FILENAME,
      COMMENT_FLAG  => COMMENT_FLAG,
      COUNTER_FLAG  => COUNTER_FLAG
    )
    port map (
      clk       => clk,
      rst       => rst,
      cnt       => counter,

      tx_ready  => avst1_tx_ready,
      tx_data   => avst1_tx_data,
      tx_ctrl   => avst1_tx_ctrl
    );

    --! Instantiate av_st_sender to read avst2_tx from AVST2_DAT_FILENAME
    avst2_tx_gen: entity sim.av_st_sender
    generic map (
      FILENAME      => AVST2_DAT_FILENAME,
      COMMENT_FLAG  => COMMENT_FLAG,
      COUNTER_FLAG  => COUNTER_FLAG
    )
    port map (
      clk       => clk,
      rst       => rst,
      cnt       => counter,

      tx_ready  => avst2_tx_ready,
      tx_data   => avst2_tx_data,
      tx_ctrl   => avst2_tx_ctrl
    );

    -- logging for RX interface
    avst_log_gen : block
      --! Write enable
      signal wren             : std_logic := '0';
      --! Inverted ready signal
      signal avst_rx_ready_n  : std_logic := '0';
    begin

      --! Instantiate counter_matcher to read avst_rx_ready_n from AVST_RX_READY_FILE
      rx_ready_gen: entity sim.counter_matcher
      generic map (
        FILENAME      => AVST_RX_READY_FILE,
        COMMENT_FLAG  => COMMENT_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        counter   => counter,
        stimulus  => avst_rx_ready_n
      );

      avst_rx_ready <= not avst_rx_ready_n;

      wren <= avst_rx_ctrl(6) and avst_rx_ready;

      --! Instantiate file_writer_hex to write avst_rx_data
      log_rx: entity sim.file_writer_hex
      generic map (
        FILENAME      => AVST_LOG_FILENAME,
        COMMENT_FLAG  => COMMENT_FLAG,
        BITSPERWORD   => 16,
        WORDSPERLINE  => 4
      )
      port map (
        clk       => clk,
        rst       => rst,
        wren      => wren,

        empty     => avst_rx_ctrl(2 downto 0),
        eop       => avst_rx_ctrl(4),
        err       => avst_rx_ctrl(3),

        din       => avst_rx_data
      );

    end block;

  end block;

end tb;
