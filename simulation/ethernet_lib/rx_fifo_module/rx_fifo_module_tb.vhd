-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Testbench for rx_fifo_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details Generates the environment for the rx_fifo_module.vhd.
--!
--! RESET_DURATION is set to 5
-------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.std_logic_1164.all;
--! @endcond

--! Testbench for rx_fifo_module.vhd
entity rx_fifo_module_tb is
  generic (
    --! File containing the reset input data
    FIFO_DAT_FILENAME  : string := "sim_data_files/FIFO_data_in.dat";
    --! File to write out the response of the reset_module
    FIFO_LOG_FILENAME  : string := "sim_data_files/FIFO_data_out.dat";
    --! File containing counters on which the rx interface is not ready
    FIFO_RX_READY_FILE : string := "sim_data_files/FIFO_rx_ready_in.dat";
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE       : string := "sim_data_files/MNL_RST_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG       : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG       : character := '@';

    --! @name Configuration of the module
    --! @{

    --! @brief Locking the FIFO on the writing side
    LOCK_FIFO      : boolean := true;
    --! @brief Locking the FIFO on the reading side
    LOCK_FIFO_OUT  : boolean := false;
    --! @brief Enable true dual clock mode or not.
    DUAL_CLK       : boolean := false

    --! @}
  );
end rx_fifo_module_tb;

--! @cond
library sim;
library misc;
library ethernet_lib;
--! @endcond

--! Implementation of reset_module_tb
architecture tb of rx_fifo_module_tb is

  --! Clock
  signal clk              : std_logic;
  --! Reset, sync with #clk
  signal rst              : std_logic;

  --! @name Avalon-ST from input
  --! @{

  --! RX ready
  signal fifo_rx_ready     : std_logic;
  --! RX data
  signal fifo_rx_data      : std_logic_vector(63 downto 0);
  --! RX controls
  signal fifo_rx_ctrl      : std_logic_vector(6 downto 0);

  --! @}

  --! @name Avalon-ST to output
  --! @{

  --! TX ready
  signal fifo_tx_ready     : std_logic;
  --! TX data
  signal fifo_tx_data      : std_logic_vector(63 downto 0);
  --! TX controls
  signal fifo_tx_ctrl      : std_logic_vector(6 downto 0);

  --! @}

  --! @brief FIFO read empty
  --! @todo Port could be removed as already indicated by status_vector(3)
  signal rx_fifo_rd_empty  : std_logic;

  --! status of the module
  signal status_vector  : std_logic_vector(4 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut: entity ethernet_lib.rx_fifo_module
  generic map (
    LOCK_FIFO     => LOCK_FIFO,
    LOCK_FIFO_OUT => LOCK_FIFO_OUT,
    DUAL_CLK      => DUAL_CLK
  )
  port map (

    -- Reset, sync with rx_fifo_in_clk
    rx_fifo_in_rst    => rst,

    --! Avalon-ST FIFO RX interface to load FIFO
    rx_fifo_in_clk    => clk,
    rx_fifo_in_ready  => fifo_tx_ready,
    rx_fifo_in_data   => fifo_tx_data,
    rx_fifo_in_ctrl   => fifo_tx_ctrl,

    --! Avalon-ST FIFO TX interface to empty FIFO
    rx_fifo_out_clk   => clk,
    rx_fifo_out_ready => fifo_rx_ready,
    rx_fifo_out_data  => fifo_rx_data,
    rx_fifo_out_ctrl  => fifo_rx_ctrl,

    -- FIFO read empty
    rx_fifo_rd_empty  => rx_fifo_rd_empty,

    -- Status of the module
    status_vector     => status_vector
  );

  -- Simulation part
  -- generating stimuli based on counter
  simulation: block
    --! @cond
    signal counter    : integer := 0;
    signal async_rst  : std_logic;
    signal sim_rst    : std_logic;
    signal mnl_rst    : std_logic;
    --! @endcond
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
      clk        => clk,
      rst        => '0',
      sig_in(0)  => async_rst,
      sig_out(0) => rst
    );

    fifo_tx_gen_block: block
    begin
      --! Instantiate av_st_sender to read rst_tx from FIFO_DAT_FILENAME
      rst_rx_gen: entity sim.av_st_sender
      generic map (
        FILENAME      => FIFO_DAT_FILENAME,
        COMMENT_FLAG  => COMMENT_FLAG,
        COUNTER_FLAG  => COUNTER_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        cnt       => counter,

        -- Avalon-ST to outside world
        tx_ready  => fifo_tx_ready,
        tx_data   => fifo_tx_data,
        tx_ctrl   => fifo_tx_ctrl
      );

    end block;

    fifo_log_gen: block
      --! @cond
      signal wren            : std_logic := '0';
      signal fifo_rx_ready_n : std_logic := '0';
      --! @endcond
    begin

      --! Instantiate counter_matcher to generate fifo_rx_ready_n
      rx_ready_gen: entity sim.counter_matcher
      generic map (
        FILENAME      => FIFO_RX_READY_FILE,
        COMMENT_FLAG  => COMMENT_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        counter   => counter,
        stimulus  => fifo_rx_ready_n
      );

      fifo_rx_ready <= not fifo_rx_ready_n;

      -- logging block for rx interface
      wren <= fifo_rx_ctrl(6) and fifo_rx_ready;

      --! Instantiate file_writer_hex to write fifo_rx_data
      log_rx: entity sim.file_writer_hex
      generic map (
        FILENAME      => FIFO_LOG_FILENAME,
        COMMENT_FLAG  => COMMENT_FLAG,
        BITSPERWORD   => 16,
        WORDSPERLINE  => 4
      )
      port map (
        clk       => clk,
        rst       => rst,
        wren      => wren,

        empty     => fifo_rx_ctrl(2 downto 0),
        eop       => fifo_rx_ctrl(4),
        err       => fifo_rx_ctrl(3),

        din       => fifo_rx_data
      );

    end block;

  end block;

end tb;
