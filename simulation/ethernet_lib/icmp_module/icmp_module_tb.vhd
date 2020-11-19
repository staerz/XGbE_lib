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
library IEEE;
  use IEEE.std_logic_1164.all;
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
library misc;
library ethernet_lib;
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
  --! TX data
  signal ip_tx_data      : std_logic_vector(63 downto 0);
  --! TX controls
  signal ip_tx_ctrl      : std_logic_vector(6 downto 0);
  --! Indication of being ICMP request
  signal is_icmp_request : std_logic;

  --! @}

  --! @name Avalon-ST (IP) from module (written to file)
  --! @{

  --! RX ready
  signal icmp_rx_ready   : std_logic;
  --! RX data
  signal icmp_rx_data    : std_logic_vector(63 downto 0);
  --! RX controls
  signal icmp_rx_ctrl    : std_logic_vector(6 downto 0);

  --! @}

  --! Status of the module
  signal status_vector  : std_logic_vector(2 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut: entity ethernet_lib.icmp_module
  port map (

    clk             => clk,
    rst             => rst,

    -- Avalon-ST RX interface
    ip_rx_ready     => ip_tx_ready,
    ip_rx_data      => ip_tx_data,
    ip_rx_ctrl      => ip_tx_ctrl,
    is_icmp_request => is_icmp_request,

    -- Avalon-ST TX interface
    icmp_out_ready  => icmp_rx_ready,
    icmp_out_data   => icmp_rx_data,
    icmp_out_ctrl   => icmp_rx_ctrl,

    -- Status of the module
    status_vector   => status_vector
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

    blk_icmp_tx : block
    begin
      --! Instantiate av_st_sender to read rst_tx from ICMP_RXD_FILE
      inst_ip_tx : entity sim.av_st_sender
      generic map (
        FILENAME      => ICMP_RXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG,
        COUNTER_FLAG  => COUNTER_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        cnt       => counter,

        -- Avalon-ST to outside world
        tx_ready  => ip_tx_ready,
        tx_data   => ip_tx_data,
        tx_ctrl   => ip_tx_ctrl
      );

      -- mark any frame as valid icmp frame
      is_icmp_request <= '1';
    end block;

    blk_icmp_log : block
      --! @cond
      signal wren            : std_logic := '0';
      signal icmp_rx_ready_n : std_logic := '0';
      --! @endcond
    begin

      --! Instantiate counter_matcher to generate icmp_rx_ready_n
      inst_icmp_rx_ready : entity sim.counter_matcher
      generic map (
        FILENAME      => ICMP_RDY_FILE,
        COMMENT_FLAG  => COMMENT_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        counter   => counter,
        stimulus  => icmp_rx_ready_n
      );

      icmp_rx_ready <= not icmp_rx_ready_n;

      -- logging block for TX interface
      wren <= icmp_rx_ctrl(6) and icmp_rx_ready;

      --! Instantiate file_writer_hex to write icmp_tx_data
      inst_icmp_log : entity sim.file_writer_hex
      generic map (
        FILENAME      => ICMP_TXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG,
        BITSPERWORD   => 16,
        WORDSPERLINE  => 4
      )
      port map (
        clk       => clk,
        rst       => rst,
        wren      => wren,

        empty     => icmp_rx_ctrl(2 downto 0),
        eop       => icmp_rx_ctrl(4),
        err       => icmp_rx_ctrl(3),

        din       => icmp_rx_data
      );

    end block;

  end block;

end tb;
