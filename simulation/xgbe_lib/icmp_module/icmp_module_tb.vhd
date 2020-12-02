-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Testbench for icmp_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details Generates the environment for the icmp_module.vhd.
--!
--! RESET_DURATION is set to 5
-------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Testbench for icmp_module.vhd
entity icmp_module_tb is
  generic (
    --! File containing the ICMP RX data
    ICMP_RXD_FILE     : string := "sim_data_files/ICMP_data_in.dat";
    --! File containing counters on which the RX interface is not ready
    ICMP_RDY_FILE     : string := "sim_data_files/ICMP_rx_ready_in.dat";
    --! File to write out the response of the module
    ICMP_TXD_FILE     : string := "sim_data_files/ICMP_data_out.dat";
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE      : string := "sim_data_files/MNL_RST_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG      : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG      : character := '@'
  );
end icmp_module_tb;

--! @cond
library sim;
library xgbe_lib;
--! @endcond

--! Implementation of icmp_module_tb
architecture tb of icmp_module_tb is

  --! Clock
  signal clk             : std_logic;
  --! Reset, sync with #clk
  signal rst             : std_logic;

  --! @name Avalon-ST (IP) to module (read from file)
  --! @{

  --! TX ready
  signal ip_tx_ready     : std_logic;
  --! TX data and controls
  signal ip_tx_packet    : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
  --! Indication of being ICMP request
  signal is_icmp_request : std_logic;

  --! @}

  --! @name Avalon-ST (IP) from module (written to file)
  --! @{

  --! RX ready
  signal icmp_rx_ready   : std_logic;
  --! RX data and controls
  signal icmp_rx_packet  : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));

  --! @}

  --! Status of the module
  signal status_vector   : std_logic_vector(2 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity xgbe_lib.icmp_module
  port map (

    clk               => clk,
    rst               => rst,

    -- Avalon-ST RX interface
    ip_rx_ready_o     => ip_tx_ready,
    ip_rx_packet_i    => ip_tx_packet,
    is_icmp_request_i => is_icmp_request,

    -- Avalon-ST TX interface
    icmp_tx_ready_i   => icmp_rx_ready,
    icmp_tx_packet_o  => icmp_rx_packet,

    -- Status of the module
    status_vector_o   => status_vector
  );

  -- Simulation part
  -- generating stimuli based on counter
  blk_simulation : block
    --! @cond
    signal counter    : integer := 0;
    signal sim_rst    : std_logic;
    signal mnl_rst    : std_logic;
    --! @endcond
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

    --! Instantiate avst_packet_sender to read ip_tx from ICMP_RXD_FILE
    inst_icmp_tx : entity xgbe_lib.avst_packet_sender
    generic map (
      FILENAME      => ICMP_RXD_FILE,
      COMMENT_FLAG  => COMMENT_FLAG,
      COUNTER_FLAG  => COUNTER_FLAG
    )
    port map (
      clk       => clk,
      rst       => rst,
      cnt       => counter,

      tx_ready  => ip_tx_ready,
      tx_packet => ip_tx_packet
    );

    --! Instantiate avst_packet_receiver to write icmp_rx to ICMP_TXD_FILE
    inst_icmp_rx : entity xgbe_lib.avst_packet_receiver
    generic map (
      READY_FILE    => ICMP_RDY_FILE,
      DATA_FILE     => ICMP_TXD_FILE,
      COMMENT_FLAG  => COMMENT_FLAG
    )
    port map (
      clk       => clk,
      rst       => rst,
      cnt       => counter,

      rx_ready  => icmp_rx_ready,
      rx_packet => icmp_rx_packet
    );

    -- mark any frame as valid icmp frame
    is_icmp_request <= '1';

  end block;

end tb;
