-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Testbench for ip_header_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details Generates the environment for the ip_header_module.vhd.
--!
--! RESET_DURATION is set to 5
-------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.std_logic_1164.all;
--! @endcond

--! Testbench for ip_header_module.vhd
entity ip_header_module_tb is
  generic (
    --! File containing the reset input data
    UDP_RXD_FILE      : string := "sim_data_files/UDP_data_in.dat";
    --! File containing counters on which the RX interface is not ready
    IP_RDY_FILE       : string := "sim_data_files/IP_rx_ready_in.dat";
    --! File to write out the IP response of the module
    IP_TXD_FILE       : string := "sim_data_files/IP_data_out.dat";
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE      : string := "sim_data_files/MNL_RST_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG      : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG      : character := '@'
  );
end ip_header_module_tb;

--! @cond
library sim;
library misc;
library ethernet_lib;
--! @endcond

--! Implementation of ip_header_module_tb
architecture tb of ip_header_module_tb is

  --! Clock
  signal clk            : std_logic;
  --! Reset, sync with #clk
  signal rst            : std_logic;

  --! @name Avalon-ST (UDP) to module (read from file)
  --! @{

  --! TX ready
  signal udp_tx_ready   : std_logic;
  --! TX data
  signal udp_tx_data    : std_logic_vector(63 downto 0);
  --! TX controls
  signal udp_tx_ctrl    : std_logic_vector(6 downto 0);

  --! @}

  --! @name Avalon-ST (IP) from module (written to file)
  --! @{

  --! RX ready
  signal ip_rx_ready    : std_logic;
  --! RX data
  signal ip_rx_data     : std_logic_vector(63 downto 0);
  --! RX controls
  signal ip_rx_ctrl     : std_logic_vector(6 downto 0);

  --! @}

  --! @name Interface for recovering IP address from given UDP ID
  --! @{

  --! Recovery enable
  signal reco_en        : std_logic;
  --! Recovery success indicator
  signal reco_ip_found  : std_logic;
  --! Recovered IP address
  signal reco_ip        : std_logic_vector(31 downto 0);
  --! @}

  --! @name Configuration of the module
  --! @{

  --! IP address
  signal my_ip          : std_logic_vector(31 downto 0) := x"c0_a8_00_95";
  --! Net mask
  signal ip_netmask     : std_logic_vector(31 downto 0) := x"ff_ff_ff_00";
  --! @}

  --! Status of the module
  signal status_vector  : std_logic_vector(1 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity ethernet_lib.ip_header_module
  port map (

    clk             => clk,
    rst             => rst,

    -- Avalon-ST RX interface
    udp_rx_ready    => udp_tx_ready,
    udp_rx_data     => udp_tx_data,
    udp_rx_ctrl     => udp_tx_ctrl,

    -- Avalon-ST TX interface
    ip_tx_ready     => ip_rx_ready,
    ip_tx_data      => ip_rx_data,
    ip_tx_ctrl      => ip_rx_ctrl,

    -- Configuration of the module
    my_ip           => my_ip,
    ip_netmask      => ip_netmask,

    -- Interface for recovering IP address
    reco_en         => reco_en,
    reco_ip_found   => reco_ip_found,
    reco_ip         => reco_ip,

    -- Status of the module
    status_vector   => status_vector
  );

  -- Simulation part
  -- generating stimuli based on counter
  blk_simulation : block
    --! @cond
    signal counter    : integer := 0;
    signal async_rst  : std_logic;
    signal sim_rst    : std_logic;
    signal mnl_rst    : std_logic;
    --! @endcond
  begin

    --! Instantiate simulation_basics to start
    inst_sim_basics: entity sim.simulation_basics
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

    -- fake auxiliary signals
    reco_ip_found <= '1';
    reco_ip       <= x"c0_a8_00_45";

    blk_udp_tx : block
    begin
      --! Instantiate av_st_sender to read udp_tx from UDP_RXD_FILE
      inst_udp_tx : entity sim.av_st_sender
      generic map (
        FILENAME      => UDP_RXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG,
        COUNTER_FLAG  => COUNTER_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        cnt       => counter,

        -- Avalon-ST to outside world
        tx_ready  => udp_tx_ready,
        tx_data   => udp_tx_data,
        tx_ctrl   => udp_tx_ctrl
      );

    end block;

    blk_ip_log : block
      --! @cond
      signal wren          : std_logic := '0';
      signal ip_rx_ready_n : std_logic := '0';
      --! @endcond
    begin

      --! Instantiate counter_matcher to generate ip_rx_ready_n
      inst_rx_ready : entity sim.counter_matcher
      generic map (
        FILENAME      => IP_RDY_FILE,
        COMMENT_FLAG  => COMMENT_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        counter   => counter,
        stimulus  => ip_rx_ready_n
      );

      ip_rx_ready <= not ip_rx_ready_n;

      -- logging block for TX interface
      wren <= ip_rx_ctrl(6) and ip_rx_ready;

      --! Instantiate file_writer_hex to write ip_tx_data
      inst_ip_log : entity sim.file_writer_hex
      generic map (
        FILENAME      => IP_TXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG,
        BITSPERWORD   => 16,
        WORDSPERLINE  => 4
      )
      port map (
        clk       => clk,
        rst       => rst,
        wren      => wren,

        empty     => ip_rx_ctrl(2 downto 0),
        eop       => ip_rx_ctrl(4),
        err       => ip_rx_ctrl(3),

        din       => ip_rx_data
      );

    end block;

  end block;

end tb;
