-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Testbench for reset_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details Generates the environment for the reset_module.vhd.
--!
--! For proper operation of the reset, RST_RXD_FILE has to contain the
--! properly formatted reset request, respecting the configuration of MY_MAC,
--! MY_IP and MY_UDP_port.
--!
--! RESET_DURATION is set to 10
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Testbench for reset_module.vhd
entity reset_module_tb is
  generic (
    --! File containing the RST RX data
    RST_RXD_FILE   : string := "sim_data_files/RST_data_in.dat";
    --! File containing counters on which the RX interface is not ready
    RST_RDY_FILE   : string := "sim_data_files/RST_rx_ready_in.dat";
    --! File to write out the response of the module
    RST_TXD_FILE   : string := "sim_data_files/RST_data_out.dat";
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE   : string := "sim_data_files/MNL_RST_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG   : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG   : character := '@';

    --! @name Configuration of the module
    --! This configuration must match the data in the RST_RXD_FILE input file
    --! @{

    --! MAC address
    MY_MAC         : std_logic_vector(47 downto 0) := x"00_22_8F_02_41_EE";
    --! IP address
    MY_IP          : std_logic_vector(31 downto 0) := x"C0_A8_00_1E";
    --! UDP port
    MY_UDP_PORT    : std_logic_vector(15 downto 0) := x"00_05";
    --! @}

    --! Reset duration for rst_out in clk cycles
    RESET_DURATION : positive               := 10;
    --! Width of rst_out
    RESET_WIDTH    : positive range 1 to 32 := 32
  );
end entity reset_module_tb;

--! @cond
library sim;
library misc;
library xgbe_lib;
--! @endcond

--! Implementation of reset_module_tb
architecture tb of reset_module_tb is

  --! Clock
  signal clk : std_logic;
  --! Reset, sync with #clk
  signal rst : std_logic;

  --! @name Avalon-ST (IPbus) to module (read from file)
  --! @{

  --! TX ready
  signal tx_ready  : std_logic;
  --! TX data and controls
  signal tx_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
  --! @}

  --! @name Avalon-ST (IPbus) from module (written to file)
  --! @{

  --! RX ready
  signal rx_ready  : std_logic;
  --! RX data and controls
  signal rx_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
  --! @}

  --! Reset output
  signal rst_out : std_logic_vector(RESET_WIDTH - 1 downto 0);

  --! Status of the module
  signal status_vector : std_logic_vector(2 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity xgbe_lib.reset_module
  generic map (
    RESET_DURATION     => RESET_DURATION,
    RESET_WIDTH        => RESET_WIDTH,
    RESET_REGISTER_ADD => x"0000_0001"
  )
  port map (
    clk => clk,
    rst => rst,

    -- Avalon-ST from reset requester
    rx_ready_o  => tx_ready,
    rx_packet_i => tx_packet,

    -- Avalon-ST to reset requester
    tx_ready_i  => rx_ready,
    tx_packet_o => rx_packet,

    -- Configuration of the module
    my_mac_i      => MY_MAC,
    my_ip_i       => MY_IP,
    my_udp_port_i => MY_UDP_PORT,

    -- Reset output
    rst_o => rst_out,

    -- Status of the module
    status_vector_o => status_vector
  );

  -- Simulation part
  -- generating stimuli based on counter
  blk_simulation : block
    signal counter : integer;
    signal sim_rst : std_logic;
    signal mnl_rst : std_logic;
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
    inst_mnl_rst : entity sim.counter_matcher
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

    rst <= sim_rst or mnl_rst;

    --! Instantiate avst_packet_sender to read rst_tx from RST_RXD_FILE
    inst_tx : entity xgbe_lib.avst_packet_sender
    generic map (
      FILENAME     => RST_RXD_FILE,
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

    --! Instantiate avst_packet_receiver to write eth_rx to ETH_TXD_FILE
    inst_rx : entity xgbe_lib.avst_packet_receiver
    generic map (
      READY_FILE   => RST_RDY_FILE,
      DATA_FILE    => RST_TXD_FILE,
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
