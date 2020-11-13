-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Testbench for reset_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details Generates the environment for the reset_module.vhd.
--!
--! For proper operation of the reset, RST_RXD_FILE has to contain the
--! properly formatted reset request, respecting the configuration of MY_MAC,
--! MY_IP and MY_UDP_port.
--!
--! RESET_DURATION is set to 10
-------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.std_logic_1164.all;
--! @endcond

--! Testbench for reset_module.vhd
entity reset_module_tb is
  generic (
    --! File containing the RST RX data
    RST_RXD_FILE      : string := "sim_data_files/RST_data_in.dat";
    --! File containing counters on which the RX interface is not ready
    RST_RDY_FILE      : string := "sim_data_files/RST_rx_ready_in.dat";
    --! File to write out the response of the module
    RST_TXD_FILE      : string := "sim_data_files/RST_data_out.dat";
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE      : string := "sim_data_files/MNL_RST_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG      : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG      : character := '@';

    --! @name Configuration of the module
    --! This configuration must match the data in the RST_RXD_FILE input file
    --! @{

    --! MAC address
    MY_MAC            : std_logic_vector(47 downto 0) := x"00_22_8F_02_41_EE";
    --! IP address
    MY_IP             : std_logic_vector(31 downto 0) := x"C0_A8_00_1E";
    --! UDP port
    MY_UDP_PORT       : std_logic_vector(15 downto 0) := x"00_05";
    --! @}

    --! Reset duration for rst_out in clk cycles
    RESET_DURATION    : positive               := 10;
    --! Width of rst_out
    RESET_WIDTH       : positive range 1 to 32 := 32
  );
end reset_module_tb;

--! @cond
library sim;
library misc;
library ethernet_lib;
--! @endcond

--! Implementation of reset_module_tb
architecture tb of reset_module_tb is

  --! Clock
  signal clk              : std_logic;
  --! Reset, sync with #clk
  signal rst              : std_logic;

  --! @name Avalon-ST (IPbus) to module (read from file)
  --! @{

  --! TX ready
  signal rst_tx_ready     : std_logic;
  --! TX data
  signal rst_tx_data      : std_logic_vector(63 downto 0);
  --! TX controls
  signal rst_tx_ctrl      : std_logic_vector(6 downto 0);
  --! @}

  --! @name Avalon-ST (IPbus) from module (written to file)
  --! @{

  --! RX ready
  signal rst_rx_ready     : std_logic;
  --! RX data
  signal rst_rx_data      : std_logic_vector(63 downto 0);
  --! RX controls
  signal rst_rx_ctrl      : std_logic_vector(6 downto 0);
  --! @}

  --! Reset output
  signal rst_out          : std_logic_vector(reset_width-1 downto 0);

  --! Status of the module
  signal status_vector    : std_logic_vector(2 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut: entity ethernet_lib.reset_module
  generic map (
    RESET_DURATION  => RESET_DURATION,
    RESET_WIDTH     => RESET_WIDTH,
    RESET_REGISTER_ADD => x"0000_0001"
  )
  port map (
    clk             => clk,
    rst             => rst,

    -- Avalon-ST from reset requester
    rst_rx_ready    => rst_tx_ready,
    rst_rx_data     => rst_tx_data,
    rst_rx_ctrl     => rst_tx_ctrl,

    -- Avalon-ST to reset requester
    rst_tx_ready    => rst_rx_ready,
    rst_tx_data     => rst_rx_data,
    rst_tx_ctrl     => rst_rx_ctrl,

    -- Configuration of the module
    my_mac          => my_mac,
    my_ip           => my_ip,
    my_udp_port     => my_udp_port,

    -- Reset output
    rst_out         => rst_out,

    -- Status of the module
    status_vector   => status_vector
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

    blk_rst_tx : block
    begin
      --! Instantiate av_st_sender to read rst_tx from RST_RXD_FILE
      rst_rx_gen: entity sim.av_st_sender
      generic map (
        FILENAME      => RST_RXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG,
        COUNTER_FLAG  => COUNTER_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        cnt       => counter,

        -- Avalon-ST to outside world
        tx_ready  => rst_tx_ready,
        tx_data   => rst_tx_data,
        tx_ctrl   => rst_tx_ctrl
      );

    end block;

    blk_rst_log : block
      signal wren           : std_logic := '0';
      signal rst_rx_ready_n : std_logic := '0';
    begin

      --! Instantiate counter_matcher to generate rst_rx_ready_n
      inst_rx_ready : entity sim.counter_matcher
      generic map (
        FILENAME      => RST_RDY_FILE,
        COMMENT_FLAG  => COMMENT_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        counter   => counter,
        stimulus  => rst_rx_ready_n
      );

      rst_rx_ready <= not rst_rx_ready_n;

      -- logging block for rx interface
      wren <= rst_rx_ctrl(6) and rst_rx_ready;

      --! Instantiate file_writer_hex to write rst_rx_data
      inst_rst_log : entity sim.file_writer_hex
      generic map (
        FILENAME      => RST_TXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG,
        BITSPERWORD   => 16,
        WORDSPERLINE  => 4
      )
      port map (
        clk       => clk,
        rst       => rst,
        wren      => wren,

        empty     => rst_rx_ctrl(2 downto 0),
        eop       => rst_rx_ctrl(4),
        err       => rst_rx_ctrl(3),

        din       => rst_rx_data
      );

    end block;

  end block;

end tb;
