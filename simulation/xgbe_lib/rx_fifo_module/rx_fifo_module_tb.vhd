-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Testbench for rx_fifo_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details Generates the environment for the rx_fifo_module.vhd.
--!
--! RESET_DURATION is set to 5
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Testbench for rx_fifo_module.vhd
entity rx_fifo_module_tb is
  generic (
    --! File containing the reset input data
    AVST_RXD_FILE : string := "sim_data_files/FIFO_data_in.dat";
    --! File to write out the response of the reset_module
    AVST_TXD_FILE : string := "sim_data_files/FIFO_data_out.dat";
    --! File containing counters on which the rx interface is not ready
    AVST_RDY_FILE : string := "sim_data_files/FIFO_rx_ready_in.dat";
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE  : string := "sim_data_files/MNL_RST_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG  : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG  : character := '@';

    --! Locking the FIFO on the writing side
    LOCK_FIFO     : boolean := true;
    --! Locking the FIFO on the reading side
    LOCK_FIFO_OUT : boolean := false;
    --! Enable true dual clock mode or not.
    DUAL_CLK      : boolean := false
  );
end entity rx_fifo_module_tb;

--! @cond
library sim;
library misc;
library xgbe_lib;
--! @endcond

--! Implementation of reset_module_tb
architecture tb of rx_fifo_module_tb is

  --! Clock
  signal clk : std_logic;
  --! Reset, sync with #clk
  signal rst : std_logic;

  --! @name Avalon-ST to module (read from file)
  --! @{

  --! TX ready
  signal tx_ready  : std_logic;
  --! TX data and controls
  signal tx_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));

  --! @}

  --! @name Avalon-ST from module (written to file)
  --! @{

  --! RX ready
  signal rx_ready  : std_logic;
  --! RX data and controls
  signal rx_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));

  --! @}

  --! status of the module
  signal status_vector : std_logic_vector(4 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity xgbe_lib.rx_fifo_module
  generic map (
    LOCK_FIFO     => LOCK_FIFO,
    LOCK_FIFO_OUT => LOCK_FIFO_OUT,
    DUAL_CLK      => DUAL_CLK
  )
  port map (

    -- Reset, sync with clk_i
    rst_i => rst,

    --! Avalon-ST FIFO RX interface to load FIFO
    clk_i       => clk,
    rx_ready_o  => tx_ready,
    rx_packet_i => tx_packet,

    --! Avalon-ST FIFO TX interface to empty FIFO
    clk_o       => clk,
    tx_ready_i  => rx_ready,
    tx_packet_o => rx_packet,

    -- Status of the module
    status_vector_o => status_vector
  );

  -- Simulation part
  -- generating stimuli based on counter
  blk_simulation : block
    --! @cond
    -- vsg_disable_next_line signal_007
    signal counter   : integer := 0;
    signal async_rst : std_logic;
    signal sim_rst   : std_logic;
    signal mnl_rst   : std_logic;
    --! @endcond
  begin

    --! Instantiate simulation_basics to start
    inst_sim_basics : entity sim.simulation_basics
    generic map (
      RESET_DURATION => 5,
      CLK_OFFSET     => 0 ns,
      CLK_PERIOD     => 6.4 ns
    )
    port map (
      clk => clk,
      rst => sim_rst,
      cnt => counter
    );

    --! Instantiate counter_matcher to read mnl_rst from MNL_RST_FILE
    inst_mnl_rst_gen : entity sim.counter_matcher
    generic map (
      FILENAME     => MNL_RST_FILE,
      COMMENT_FLAG => COMMENT_FLAG
    )
    port map (
      clk      => clk,
      rst      => '0',
      cnt      => counter,
      stimulus => mnl_rst
    );

    async_rst <= sim_rst or mnl_rst;

    --! Instantiate delay_chain to generate rst
    inst_rst_sync : entity misc.delay_chain
    port map (
      clk        => clk,
      rst        => '0',
      sig_in(0)  => async_rst,
      sig_out(0) => rst
    );

    --! Instantiate avst_packet_sender to read tx from AVST_RXD_FILE
    inst_tx : entity xgbe_lib.avst_packet_sender
    generic map (
      FILENAME     => AVST_RXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => counter,

      tx_ready_i  => tx_ready,
      tx_packet_o => tx_packet
    );

    --! Instantiate avst_packet_receiver to write rx to AVST_TXD_FILE
    inst_rx : entity xgbe_lib.avst_packet_receiver
    generic map (
      READY_FILE   => AVST_RDY_FILE,
      DATA_FILE    => AVST_TXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => counter,

      rx_ready_o  => rx_ready,
      rx_packet_i => rx_packet
    );

  end block blk_simulation;

end architecture tb;
