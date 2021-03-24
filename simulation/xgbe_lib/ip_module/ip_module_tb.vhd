-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Testbench for ip_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details Generates the environment for the ip_module.vhd.
--!
--! RESET_DURATION is set to 5
-------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Testbench for ip_module.vhd
entity ip_module_tb is
  generic (
    --! File containing the IP RX data
    IP_RXD_FILE       : string := "sim_data_files/IP_data_in.dat";
    --! File containing counters on which the IP RX interface is not ready
    IP_RDY_FILE       : string := "sim_data_files/IP_rx_ready_in.dat";
    --! File to write out the IP response of the module
    IP_TXD_FILE       : string := "sim_data_files/IP_data_out.dat";
    --! File containing the UDP RX data
    UDP_RXD_FILE      : string := "sim_data_files/UDP_data_in.dat";
    --! File containing counters on which the UDP RX interface is not ready
    UDP_RDY_FILE      : string := "sim_data_files/UDP_rx_ready_in.dat";
    --! File to write out the UDP response of the module
    UDP_TXD_FILE      : string := "sim_data_files/UDP_data_out.dat";
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE      : string := "sim_data_files/MNL_RST_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG      : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG      : character := '@';
    --! End of frame check
    EOF_CHECK_EN      : std_logic := '1';
    --! Post-UDP-module UDP CRC calculation
    UDP_CRC_EN        : boolean   := true;
    --! Enable IP address filtering
    IP_FILTER_EN      : std_logic := '1';

    --! Depth of table (number of stored connections)
    ID_TABLE_DEPTH    : integer range 1 to 1024 := 5;
    --! The minimal number of clock cycles between two outgoing frames.
    PAUSE_LENGTH      : integer range 0 to 1024 := 2
  );
end ip_module_tb;

--! @cond
library xgbe_lib;
library sim;
--! @endcond

--! Implementation of ip_module_tb
architecture tb of ip_module_tb is

  --! Clock
  signal clk           : std_logic;
  --! Reset, sync with #clk
  signal rst           : std_logic;

  --! @name Avalon-ST (IP) to module (read from file)
  --! @{

  --! TX ready
  signal ip_tx_ready   : std_logic;
  --! TX data and controls
  signal ip_tx_packet  : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));

  --! @}

  --! @name Avalon-ST (IP) from module (written to file)
  --! @{

  --! RX ready
  signal ip_rx_ready   : std_logic;
  --! RX data and controls
  signal ip_rx_packet  : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));

  --! @}

  --! @name Avalon-ST (UDP) to module (read from file)
  --! @{

  --! TX ready
  signal udp_tx_ready  : std_logic;
  --! TX data and controls
  signal udp_tx_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
  --! TX identifier
  signal udp_tx_id     : std_logic_vector(15 downto 0);

  --! @}

  --! @name Avalon-ST (UDP) from module (written to file)
  --! @{

  --! RX ready
  signal udp_rx_ready  : std_logic;
  --! RX data and controls
  signal udp_rx_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
  --! RX identifier
  signal udp_rx_id     : std_logic_vector(15 downto 0);

  --! @}

  --! @name Configuration of the module
  --! @{

  --! IP address
  signal my_ip         : std_logic_vector(31 downto 0) := x"c0_a8_00_1e";
  --! Net mask
  signal ip_netmask    : std_logic_vector(31 downto 0) := x"ff_ff_ff_00";
  --! @}

  --! Status of the module
  signal status_vector : std_logic_vector(12 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity xgbe_lib.ip_module
  generic map (
    EOF_CHECK_EN    => EOF_CHECK_EN,
    UDP_CRC_EN      => UDP_CRC_EN,
    IP_FILTER_EN    => IP_FILTER_EN,
    ID_TABLE_DEPTH  => ID_TABLE_DEPTH,
    PAUSE_LENGTH    => PAUSE_LENGTH
  )
  port map (
    clk             => clk,
    rst             => rst,

    ip_rx_ready_o   => ip_tx_ready,
    ip_rx_packet_i  => ip_tx_packet,

    ip_tx_ready_i   => ip_rx_ready,
    ip_tx_packet_o  => ip_rx_packet,

    udp_rx_ready_o  => udp_tx_ready,
    udp_rx_packet_i => udp_tx_packet,
    udp_rx_id_i     => udp_tx_id,

    udp_tx_ready_i  => udp_rx_ready,
    udp_tx_packet_o => udp_rx_packet,
    udp_tx_id_o     => udp_rx_id,

    my_ip_i         => my_ip,
    ip_netmask_i    => ip_netmask,

    status_vector_o => status_vector
  );

  -- Simulation part
  -- generating stimuli based on counter
  blk_simulation : block
    --! @cond
    signal counter     : integer := 0;
    signal sim_rst     : std_logic;
    signal mnl_rst     : std_logic;
    signal udp_tx_id_r : unsigned(15 downto 0);
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
      cnt       => counter,
      stimulus  => mnl_rst
    );

    rst <= sim_rst or mnl_rst;

    --! Instantiate avst_packet_sender to read ip_tx from IP_RXD_FILE
    inst_ip_tx : entity xgbe_lib.avst_packet_sender
    generic map (
      FILENAME      => IP_RXD_FILE,
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

    --! Instantiate avst_packet_receiver to write ip_rx to IP_TXD_FILE
    inst_ip_rx : entity xgbe_lib.avst_packet_receiver
    generic map (
      READY_FILE    => IP_RDY_FILE,
      DATA_FILE     => IP_TXD_FILE,
      COMMENT_FLAG  => COMMENT_FLAG
    )
    port map (
      clk       => clk,
      rst       => rst,
      cnt       => counter,

      rx_ready  => ip_rx_ready,
      rx_packet => ip_rx_packet
    );

    --! Instantiate avst_packet_sender to read udp_tx from UDP_RXD_FILE
    inst_udp_tx : entity xgbe_lib.avst_packet_sender
    generic map (
      FILENAME      => UDP_RXD_FILE,
      COMMENT_FLAG  => COMMENT_FLAG,
      COUNTER_FLAG  => COUNTER_FLAG
    )
    port map (
      clk       => clk,
      rst       => rst,
      cnt       => counter,

      tx_ready  => udp_tx_ready,
      tx_packet => udp_tx_packet
    );

    --! Instantiate avst_packet_receiver to write udp_rx to UDP_TXD_FILE
    inst_upd_rx : entity xgbe_lib.avst_packet_receiver
    generic map (
      READY_FILE    => UDP_RDY_FILE,
      DATA_FILE     => UDP_TXD_FILE,
      COMMENT_FLAG  => COMMENT_FLAG
    )
    port map (
      clk       => clk,
      rst       => rst,
      cnt       => counter,

      rx_ready  => udp_rx_ready,
      rx_packet => udp_rx_packet
    );

    --! Generate an ID for each new UDP packet
    proc_gen_id_counter : process (clk) is
    begin
      if rising_edge(clk) then
        if rst = '1' then
          udp_tx_id_r <= to_unsigned(1, udp_tx_id_r'length);
        elsif udp_tx_packet.eop = '1' and udp_tx_ready = '1' then
          -- let simulation generate one id which will not be generated by ip module
          -- itself in order to test the proper reaction of a non-existing id
          if udp_tx_id_r = to_unsigned(id_table_depth+1, 16) then
            udp_tx_id_r <= to_unsigned(1, udp_tx_id_r'length);
          else
            udp_tx_id_r <= udp_tx_id_r + 1;
          end if;
        else
          udp_tx_id_r <= udp_tx_id_r;
        end if;
      end if;
    end process;

    udp_tx_id <=
      std_logic_vector(udp_tx_id_r) when udp_tx_packet.valid = '1' else
      (others => '0');

  end block;

end tb;
