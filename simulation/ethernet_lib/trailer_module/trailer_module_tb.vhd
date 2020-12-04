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
library fpga;
  context fpga.interfaces;
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
  signal tx_ready  : std_logic;
  --! TX data and controls
  signal tx_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
  --! Additional rx indicator if multiple interfaces are used
  signal tx_mux    : std_logic_vector(N_INTERFACES-1 downto 0) := (others => '0');

  --! @}

  --! @name Avalon-ST from module (written to file)
  --! @{

  --! RX ready
  signal rx_ready  : std_logic;
  --! RX data and controls
  signal rx_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
  --! Additional tx indicator if multiple interfaces are used
  signal rx_mux    : std_logic_vector(N_INTERFACES-1 downto 0) := (others => '0');

  --! @}

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity ethernet_lib.trailer_module
  generic map (
    HEADER_LENGTH   => HEADER_LENGTH,
    N_INTERFACES    => N_INTERFACES,
    MAX_FRAME_SIZE  => MAX_FRAME_SIZE
  )
  port map (
    clk         => clk,
    rst         => rst,

    rx_ready_o  => tx_ready,
    rx_packet_i => tx_packet,
    rx_mux_i    => tx_mux,

    rx_count_o  => open,

    tx_ready_i  => rx_ready,
    tx_packet_o => rx_packet,
    tx_mux_o    => rx_mux
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

    --! Instantiate avst_packet_sender to read tx from AVST_RXD_FILE
    inst_tx : entity ethernet_lib.avst_packet_sender
    generic map (
      FILENAME      => AVST_RXD_FILE,
      COMMENT_FLAG  => COMMENT_FLAG,
      COUNTER_FLAG  => COUNTER_FLAG
    )
    port map (
      clk       => clk,
      rst       => rst,
      cnt       => counter,

      tx_ready  => tx_ready,
      tx_packet => tx_packet
    );

    --! Instantiate avst_packet_receiver to write rx to AVST_TXD_FILE
    inst_rx : entity ethernet_lib.avst_packet_receiver
    generic map (
      READY_FILE    => AVST_RDY_FILE,
      DATA_FILE     => AVST_TXD_FILE,
      COMMENT_FLAG  => COMMENT_FLAG
    )
    port map (
      clk       => clk,
      rst       => rst,
      cnt       => counter,

      rx_ready  => rx_ready,
      rx_packet => rx_packet
    );

  end block;

end tb;
