-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Testbench for trailer_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details Generates the environment for the trailer_module.vhd.
--! Data packets read from AVST_RXD_FILE are pushed through the
--! trailer module configured with a specific header_length.
--! The output is written to AVST_TXD_FILE.
--! @todo Rename ports from fpga_* to avst_*.
-------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.std_logic_1164.all;
--! @endcond

--! Testbench for trailer_module.vhd
entity trailer_module_tb is
  generic (
    --! File containing the AVST RX data
    AVST_RXD_FILE      : string := "sim_data_files/AVST_data_in.dat";
    --! File containing counters on which the RX interface is not ready
    AVST_RDY_FILE      : string := "sim_data_files/AVST_rx_ready_in.dat";
    --! File to write out the response of the module
    AVST_TXD_FILE      : string := "sim_data_files/AVST_data_out.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG       : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG       : character := '@';
    --! Number of bytes of the header to be cut off
    HEADER_LENGTH      : integer   := 3;
    --! (Maximum) frame size in bytes
    MAX_FRAME_SIZE     : integer   := 1500
  );
end trailer_module_tb;

--! @cond
library sim;
library ethernet_lib;
--! @endcond

--! Implementation of trailer_module_tb
architecture tb of trailer_module_tb is

  --! Number of interfaces (if multiple interfaces are used)
  constant N_INTERFACES   : positive := 2;

  --! Clock
  signal clk              : std_logic;
  --! reset, sync with #clk
  signal rst              : std_logic;

  --! @name Avalon-ST to module (read from file)
  --! @{

  --! TX ready
  signal fpga_tx_ready    : std_logic;
  --! TX data
  signal fpga_tx_data     : std_logic_vector(63 downto 0);
  --! TX controls
  signal fpga_tx_ctrl     : std_logic_vector(6 downto 0);
  --! Additional rx indicator if multiple interfaces are used
  signal tx_mux           : std_logic_vector(N_INTERFACES-1 downto 0) := (others => '0');

  --! @}

  --! @name Avalon-ST from module (written to file)
  --! @{

  --! RX ready
  signal fpga_rx_ready    : std_logic;
  --! RX data
  signal fpga_rx_data     : std_logic_vector(63 downto 0);
  --! RX controls
  signal fpga_rx_ctrl     : std_logic_vector(6 downto 0);
  --! Additional tx indicator if multiple interfaces are used
  signal rx_mux           : std_logic_vector(N_INTERFACES-1 downto 0) := (others => '0');

  --! @}

begin

  --! Instantiate the Unit Under Test (UUT)
  uut: entity ethernet_lib.trailer_module
  generic map (
    HEADER_LENGTH   => HEADER_LENGTH,
    N_INTERFACES    => N_INTERFACES,
    MAX_FRAME_SIZE  => MAX_FRAME_SIZE
  )
  port map (
    clk       => clk,
    rst       => rst,

    rx_ready  => fpga_tx_ready,
    rx_data   => fpga_tx_data,
    rx_ctrl   => fpga_tx_ctrl,
    rx_mux    => tx_mux,

    rx_count  => open,

    tx_ready  => fpga_rx_ready,
    tx_data   => fpga_rx_data,
    tx_ctrl   => fpga_rx_ctrl,
    tx_mux    => rx_mux
  );

  -- Simulation part
  -- generating stimuli based on counter
  blk_simulation : block
    signal counter    : integer := 0;
  begin

    --! Instantiate simulation_basics to start
    inst_sim_basics : entity sim.simulation_basics
    port map (
      clk => clk,
      rst => rst,
      cnt => counter
    );

    -- generating the input data
    blk_avst_tx : block
      signal fpga_rx_ready_n : std_logic := '0';
    begin
      --! Instantiate av_st_sender to read fpga_tx from AVST1_DAT_FILENAME
      inst_avst_tx : entity sim.av_st_sender
      generic map (
        FILENAME      => AVST_RXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG,
        COUNTER_FLAG  => COUNTER_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        cnt       => counter,

        tx_ready  => fpga_tx_ready,
        tx_data   => fpga_tx_data,
        tx_ctrl   => fpga_tx_ctrl
      );

      --! Instantiate counter_matcher to read fpga_tx_ready_n from AVST_RDY_FILE
      inst_rx_ready : entity sim.counter_matcher
      generic map (
        FILENAME      => AVST_RDY_FILE,
        COMMENT_FLAG  => COMMENT_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        counter   => counter,
        stimulus  => fpga_rx_ready_n
      );

      fpga_rx_ready <= not fpga_rx_ready_n;

    end block;

    -- logging for RX interface
    blk_avst_log : block
      --! Write enable
      signal wren       : std_logic := '0';
    begin
      wren <= fpga_rx_ctrl(6) and fpga_rx_ready;

      inst_rx_log : entity sim.file_writer_hex
      generic map (
        FILENAME      => AVST_TXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG,
        BITSPERWORD   => 16,
        WORDSPERLINE  => 4
      )
      port map (
        clk       => clk,
        rst       => rst,
        wren      => wren,

        empty     => fpga_rx_ctrl(2 downto 0),
        eop       => fpga_rx_ctrl(4),
        err       => fpga_rx_ctrl(3),

        din       => fpga_rx_data
      );

    end block;

  end block;

end tb;
