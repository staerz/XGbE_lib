-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Testbench for ethernet_header_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details Generates the environment for the ethernet_header_module.vhd.
--!
--! RESET_DURATION is set to 5
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Testbench for ethernet_header_module.vhd
entity ethernet_header_module_tb is
  generic (
    --! File containing the reset input data
    IP_RXD_FILE  : string := "sim_data_files/IP_data_in.dat";
    --! File containing counters on which the RX interface is not ready
    ETH_RDY_FILE : string := "sim_data_files/ETH_rx_ready_in.dat";
    --! File to write out the IP response of the module
    ETH_TXD_FILE : string := "sim_data_files/ETH_data_out.dat";
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE : string := "sim_data_files/MNL_RST_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG : character := '@'
  );
end entity ethernet_header_module_tb;

--! @cond
library sim;
library xgbe_lib;
--! @endcond

--! Implementation of ethernet_header_module_tb
architecture tb of ethernet_header_module_tb is

  --! Clock
  signal clk : std_logic;
  --! Reset, sync with #clk
  signal rst : std_logic;

  --! @name Avalon-ST (IP) to module (read from file)
  --! @{

  --! TX ready
  signal ip_tx_ready  : std_logic;
  --! TX data and controls
  signal ip_tx_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));

  --! @}

  --! @name Avalon-ST (ETH) from module (written to file)
  --! @{

  --! RX ready
  signal eth_rx_ready  : std_logic;
  --! RX data and controls
  signal eth_rx_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));

  --! @}

  --! @name Interface for recovering MAC address from given IP address
  --! @{

  --! Recovery enable
  signal reco_en   : std_logic;
  --! IP address to recover
  signal reco_ip   : std_logic_vector(31 downto 0);
  --! Recovered MAC address
  signal reco_mac  : std_logic_vector(47 downto 0);
  --! Recovery success indicator
  signal reco_done : std_logic;
  --! @}

  --! MAC address
  constant MY_MAC : std_logic_vector(47 downto 0) := x"00_22_8F_02_41_EE";

  --! Clock cycle when 1 millisecond is passed
  signal one_ms_tick : std_logic;

  --! Status of the module
  signal status_vector : std_logic_vector(2 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity xgbe_lib.ethernet_header_module
  port map (

    clk => clk,
    rst => rst,

    -- Avalon-ST RX interface
    ip_rx_ready_o  => ip_tx_ready,
    ip_rx_packet_i => ip_tx_packet,

    -- Avalon-ST TX interface
    eth_tx_ready_i  => eth_rx_ready,
    eth_tx_packet_o => eth_rx_packet,

    -- interface for recovering mac address from given ip address
    reco_en_o   => reco_en,
    reco_ip_o   => reco_ip,
    -- response (next clk if directly found, later if arp request needs to be sent)
    reco_mac_i  => reco_mac,
    reco_done_i => reco_done,

    -- Configuration of the module
    my_mac_i => MY_MAC,

    one_ms_tick_i => one_ms_tick,

    -- Status of the module
    status_vector_o => status_vector
  );

  -- Simulation part
  -- generating stimuli based on counter
  blk_simulation : block
    --! @cond
    signal counter : integer;
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
    reco_done <= '1';
    reco_mac  <= x"AB_CD_EF_01_23_45";

    --! Instantiate avst_packet_sender to read ip_tx from IP_RXD_FILE
    inst_ip_tx : entity xgbe_lib.avst_packet_sender
    generic map (
      FILENAME     => IP_RXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => counter,

      tx_ready_i  => ip_tx_ready,
      tx_packet_o => ip_tx_packet
    );

    --! Instantiate avst_packet_receiver to write eth_rx to ETH_TXD_FILE
    inst_eth_rx : entity xgbe_lib.avst_packet_receiver
    generic map (
      READY_FILE   => ETH_RDY_FILE,
      DATA_FILE    => ETH_TXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => counter,

      rx_ready_o  => eth_rx_ready,
      rx_packet_i => eth_rx_packet
    );

  end block blk_simulation;

end architecture tb;