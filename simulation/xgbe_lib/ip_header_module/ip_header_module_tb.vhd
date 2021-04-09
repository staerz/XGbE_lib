-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Testbench for ip_header_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details Generates the environment for the ip_header_module.vhd.
--!
--! RESET_DURATION is set to 5
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Testbench for ip_header_module.vhd
entity ip_header_module_tb is
  generic (
    --! File containing the reset input data
    UDP_RXD_FILE : string := "sim_data_files/UDP_data_in.dat";
    --! File containing counters on which the RX interface is not ready
    IP_RDY_FILE  : string := "sim_data_files/IP_rx_ready_in.dat";
    --! File to write out the IP response of the module
    IP_TXD_FILE  : string := "sim_data_files/IP_data_out.dat";
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE : string := "sim_data_files/MNL_RST_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG : character := '@'
  );
end entity ip_header_module_tb;

--! @cond
library sim;
library xgbe_lib;
--! @endcond

--! Implementation of ip_header_module_tb
architecture tb of ip_header_module_tb is

  --! Clock
  signal clk : std_logic;
  --! Reset, sync with #clk
  signal rst : std_logic;

  --! @name Avalon-ST (UDP) to module (read from file)
  --! @{

  --! TX ready
  signal udp_tx_ready  : std_logic;
  --! TX data and controls
  signal udp_tx_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));

  --! @}

  --! @name Avalon-ST (IP) from module (written to file)
  --! @{

  --! RX ready
  signal ip_rx_ready  : std_logic;
  --! RX data and controls
  signal ip_rx_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));

  --! @}

  --! @name Interface for recovering IP address from given UDP ID
  --! @{

  --! Recovery enable
  signal reco_en       : std_logic;
  --! Recovery success indicator
  signal reco_ip_found : std_logic;
  --! Recovered IP address
  signal reco_ip       : std_logic_vector(31 downto 0);
  --! @}

  --! @name Configuration of the module
  --! @{
  -- vsg_off signal_007
  --! IP address
  signal my_ip      : std_logic_vector(31 downto 0) := x"c0_a8_00_95";
  --! Net mask
  signal ip_netmask : std_logic_vector(31 downto 0) := x"ff_ff_ff_00";
  -- vsg_on signal_007
  --! @}

  --! Status of the module
  signal status_vector : std_logic_vector(1 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity xgbe_lib.ip_header_module
  port map (

    clk => clk,
    rst => rst,

    -- Avalon-ST RX interface
    udp_rx_ready_o  => udp_tx_ready,
    udp_rx_packet_i => udp_tx_packet,

    -- Avalon-ST TX interface
    ip_tx_ready_i  => ip_rx_ready,
    ip_tx_packet_o => ip_rx_packet,

    -- Configuration of the module
    my_ip_i      => my_ip,
    ip_netmask_i => ip_netmask,

    -- Interface for recovering IP address
    reco_en_o       => reco_en,
    reco_ip_found_i => reco_ip_found,
    reco_ip_i       => reco_ip,

    -- Status of the module
    status_vector_o => status_vector
  );

  -- Simulation part
  -- generating stimuli based on counter
  blk_simulation : block
    --! @cond
    -- vsg_disable_next_line signal_007
    signal counter : integer := 0;
    signal sim_rst : std_logic;
    signal mnl_rst : std_logic;
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

    -- fake auxiliary signals
    reco_ip_found <= '1';
    reco_ip       <= x"c0_a8_00_45";

    --! Instantiate avst_packet_sender to read udp_tx from UDP_RXD_FILE
    inst_udp_tx : entity xgbe_lib.avst_packet_sender
    generic map (
      FILENAME     => UDP_RXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk => clk,
      rst => rst,
      cnt => counter,

      tx_ready  => udp_tx_ready,
      tx_packet => udp_tx_packet
    );

    --! Instantiate avst_packet_receiver to write ip_rx to IP_TXD_FILE
    inst_ip_rx : entity xgbe_lib.avst_packet_receiver
    generic map (
      READY_FILE   => IP_RDY_FILE,
      DATA_FILE    => IP_TXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG
    )
    port map (
      clk => clk,
      rst => rst,
      cnt => counter,

      rx_ready  => ip_rx_ready,
      rx_packet => ip_rx_packet
    );

  end block blk_simulation;

end architecture tb;
