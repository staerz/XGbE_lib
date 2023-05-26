-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Testbench for ethernet_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details Generates the environment for the ethernet_module.vhd.
--!
--! RESET_DURATION is set to 5
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Testbench for ethernet_module.vhd
entity ethernet_module_tb is
  generic (
    --! Clock period
    CLK_PERIOD   : time   := 6.4 ns;
    --! File containing the ETH RX data
    ETH_RXD_FILE : string := "sim_data_files/ETH_rx_in.dat";
    --! File containing counters on which the ETH TX interface is not ready
    ETH_RDY_FILE : string := "sim_data_files/ETH_tx_ready_in.dat";
    --! File to write out the ETH response of the module
    ETH_TXD_FILE : string := "sim_data_files/ETH_tx_out.dat";
    --! File to read expected ETH response of the module
    ETH_CHK_FILE : string := "sim_data_files/ETH_tx_expect.dat";
    --! File containing the ARP RX data
    ARP_RXD_FILE : string := "sim_data_files/ARP_rx_in.dat";
    --! File containing counters on which the TX interface is not ready
    ARP_RDY_FILE : string := "sim_data_files/ARP_tx_ready_in.dat";
    --! File to write out the response of the module
    ARP_TXD_FILE : string := "sim_data_files/ARP_tx_out.dat";
    --! File to read expected ARP response of the module
    ARP_CHK_FILE : string := "sim_data_files/ARP_tx_expect.dat";
    --! File containing the IP RX data
    IP_RXD_FILE  : string := "sim_data_files/IP_rx_in.dat";
    --! File containing counters on which the IP TX interface is not ready
    IP_RDY_FILE  : string := "sim_data_files/IP_tx_ready_in.dat";
    --! File to write out the IP response of the module
    IP_TXD_FILE  : string := "sim_data_files/IP_tx_out.dat";
    --! File to read expected IP response of the module
    IP_CHK_FILE  : string := "sim_data_files/IP_tx_expect.dat";
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE : string := "sim_data_files/MNL_RST_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG : character := '@';

    --! End of packet check
    EOP_CHECK_EN : std_logic                := '1';
    --! The minimal number of clock cycles between two outgoing packets.
    PAUSE_LENGTH : integer range 0 to 1024  := 2;
    --! Timeout to reconstruct MAC from IP in milliseconds
    MAC_TIMEOUT  : integer range 1 to 10000 := 1000
  );
end entity ethernet_module_tb;

--! @cond
library xgbe_lib;
library sim;

library testbench;
  use testbench.testbench_pkg.all;

library uvvm_util;
  context uvvm_util.uvvm_util_context;
--! @endcond

--! Implementation of ethernet_module_tb
architecture tb of ethernet_module_tb is

  --! Clock
  signal clk : std_logic;
  --! Reset, sync with #clk
  signal rst : std_logic;
  --! Counter for the simulation
  signal cnt : integer;
  --! End of File indicators of all readers (data sources and checkers)
  signal eof : std_logic_vector(3 * 2 - 1 downto 0);

  --! Reset of the simulation (only at start)
  signal sim_rst : std_logic;

  --! @name Avalon-ST (ETH) to module (read from file)
  --! @{

  --! TX ready
  signal eth_tx_ready  : std_logic;
  --! TX data and controls
  signal eth_tx_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );

  --! @}

  --! @name Avalon-ST (ETH) from module (written to file)
  --! @{

  --! RX ready
  signal eth_rx_ready  : std_logic;
  --! RX data and controls
  signal eth_rx_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );

  --! @}

  --! @name Avalon-ST (ARP) to module (read from file)
  --! @{

  --! TX ready
  signal arp_tx_ready  : std_logic;
  --! TX data and controls
  signal arp_tx_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );

  --! @}

  --! @name Avalon-ST (ARP) from module (written to file)
  --! @{

  --! RX ready
  signal arp_rx_ready  : std_logic;
  --! RX data and controls
  signal arp_rx_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );

  --! @}

  --! @name Avalon-ST (IP) to module (read from file)
  --! @{

  --! TX ready
  signal ip_tx_ready  : std_logic;
  --! TX data and controls
  signal ip_tx_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );

  --! @}

  --! @name Avalon-ST (IP) from module (written to file)
  --! @{

  --! RX ready
  signal ip_rx_ready  : std_logic;
  --! RX data and controls
  signal ip_rx_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );

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
  signal status_vector : std_logic_vector(8 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity xgbe_lib.ethernet_module
  generic map (
    EOP_CHECK_EN => EOP_CHECK_EN,
    PAUSE_LENGTH => PAUSE_LENGTH,
    MAC_TIMEOUT  => MAC_TIMEOUT
  )
  port map (
    clk => clk,
    rst => rst,

    eth_rx_ready_o  => eth_tx_ready,
    eth_rx_packet_i => eth_tx_packet,

    eth_tx_ready_i  => eth_rx_ready,
    eth_tx_packet_o => eth_rx_packet,

    arp_rx_ready_o  => arp_tx_ready,
    arp_rx_packet_i => arp_tx_packet,

    arp_tx_ready_i  => arp_rx_ready,
    arp_tx_packet_o => arp_rx_packet,

    ip_rx_ready_o  => ip_tx_ready,
    ip_rx_packet_i => ip_tx_packet,

    ip_tx_ready_i  => ip_rx_ready,
    ip_tx_packet_o => ip_rx_packet,

    reco_en_o   => reco_en,
    reco_ip_o   => reco_ip,
    reco_mac_i  => reco_mac,
    reco_done_i => reco_done,

    my_mac_i => MY_MAC,

    one_ms_tick_i => one_ms_tick,

    status_vector_o => status_vector
  );

  -- Simulation part
  -- generating stimuli based on cnt
  blk_simulation : block
    --! @cond
    signal mnl_rst : std_logic;
  --! @endcond
  begin

    --! Instantiate simulation_basics to start
    inst_sim_basics : entity sim.simulation_basics
    generic map (
      RESET_DURATION => 5,
      CLK_OFFSET     => 0 ns,
      CLK_PERIOD     => CLK_PERIOD
    )
    port map (
      clk => clk,
      rst => sim_rst,
      cnt => cnt
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
      cnt      => cnt,
      stimulus => mnl_rst
    );

    rst <= sim_rst or mnl_rst;

    -- fake auxiliary signals
    reco_done <= '1';
    reco_mac  <= x"AB_CD_EF_01_23_45";

    --! Instantiate avst_packet_sender to read eth_tx from ETH_RXD_FILE
    inst_eth_tx : entity fpga.avst_packet_sender
    generic map (
      FILENAME     => ETH_RXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      tx_ready_i  => eth_tx_ready,
      tx_packet_o => eth_tx_packet,

      eof_o => eof(0)
    );

    --! Instantiate avst_packet_sender to read arp_tx from ARP_RXD_FILE
    inst_arp_tx : entity fpga.avst_packet_sender
    generic map (
      FILENAME     => ARP_RXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      tx_ready_i  => arp_tx_ready,
      tx_packet_o => arp_tx_packet,

      eof_o => eof(1)
    );

    --! Instantiate avst_packet_sender to read ip_tx from IP_RXD_FILE
    inst_ip_tx : entity fpga.avst_packet_sender
    generic map (
      FILENAME     => IP_RXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      tx_ready_i  => ip_tx_ready,
      tx_packet_o => ip_tx_packet,

      eof_o => eof(2)
    );

    --! Instantiate avst_packet_receiver to write eth_rx to ETH_TXD_FILE
    inst_eth_rx : entity fpga.avst_packet_receiver
    generic map (
      READY_FILE   => ETH_RDY_FILE,
      DATA_FILE    => ETH_TXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      rx_ready_o  => eth_rx_ready,
      rx_packet_i => eth_rx_packet
    );

    --! Instantiate avst_packet_receiver to write arp_rx to ARP_TXD_FILE
    inst_arp_rx : entity fpga.avst_packet_receiver
    generic map (
      READY_FILE   => ARP_RDY_FILE,
      DATA_FILE    => ARP_TXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      rx_ready_o  => arp_rx_ready,
      rx_packet_i => arp_rx_packet
    );

    --! Instantiate avst_packet_receiver to write ip_rx to IP_TXD_FILE
    inst_ip_rx : entity fpga.avst_packet_receiver
    generic map (
      READY_FILE   => IP_RDY_FILE,
      DATA_FILE    => IP_TXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      rx_ready_o  => ip_rx_ready,
      rx_packet_i => ip_rx_packet
    );

  end block blk_simulation;

  blk_uvvm : block
    --! Expected RX data and controls
    signal eth_rx_expect : t_avst_packet(
      data(63 downto 0),
      empty(2 downto 0),
      error(0 downto 0)
    );
    signal arp_rx_expect : t_avst_packet(
      data(63 downto 0),
      empty(2 downto 0),
      error(0 downto 0)
    );
    signal ip_rx_expect  : t_avst_packet(
      data(63 downto 0),
      empty(2 downto 0),
      error(0 downto 0)
    );
  begin

    --! Use the avst_packet_sender to read expected ETH data from an independent file
    inst_eth_tx_checker : entity fpga.avst_packet_sender
    generic map (
      FILENAME     => ETH_CHK_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => sim_rst,
      cnt_i => cnt,

      tx_ready_i  => eth_rx_ready,
      tx_packet_o => eth_rx_expect,

      eof_o => eof(3)
    );

    --! Use the avst_packet_sender to read expected ARP data from an independent file
    inst_arp_tx_checker : entity fpga.avst_packet_sender
    generic map (
      FILENAME     => ARP_CHK_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => sim_rst,
      cnt_i => cnt,

      tx_ready_i  => arp_rx_ready,
      tx_packet_o => arp_rx_expect,

      eof_o => eof(4)
    );

    --! Use the avst_packet_sender to read expected IP data from an independent file
    inst_ip_tx_checker : entity fpga.avst_packet_sender
    generic map (
      FILENAME     => IP_CHK_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => sim_rst,
      cnt_i => cnt,

      tx_ready_i  => ip_rx_ready,
      tx_packet_o => ip_rx_expect,

      eof_o => eof(5)
    );

    --! UVVM check
    proc_uvvm : process
    begin
      -- Wait a bit to let simulation settle
      wait for CLK_PERIOD;
      -- Wait for the reset to drop
      await_value(rst, '0', 0 ns, 60 * CLK_PERIOD, ERROR, "Reset drop expected.");
      -- Wait for another reset to rise
      await_value(rst, '1', 0 ns, 60 * CLK_PERIOD, ERROR, "Reset rise expected.");

      --! @cond #(doxygen fails parsing the while loop)
      note("The following acknowledge check messages are all suppressed.");
      -- make sure to be slightly after the rising edge
      wait for 1 ns;
      -- Now we just compare expected data and valid to actual values as long as there's sth. to read from files
      -- vsg_disable_next_line whitespace_013
      while nand(eof) loop
        check_value(eth_rx_packet.valid, eth_rx_expect.valid, ERROR, "Checking expected ETH valid.", "", ID_NEVER);
        check_value(eth_rx_packet.sop, eth_rx_expect.sop, ERROR, "Checking expected ETH sop.", "", ID_NEVER);
        check_value(eth_rx_packet.eop, eth_rx_expect.eop, ERROR, "Checking expected ETH eop.", "", ID_NEVER);
        -- only check the expected data when it's relevant: reader will hold data after packet while uut might not
        if eth_rx_expect.valid then
          check_value(eth_rx_packet.data, eth_rx_expect.data, ERROR, "Checking expected ETH data.", "", HEX, KEEP_LEADING_0, ID_NEVER);
        end if;
        check_value(arp_rx_packet.valid, arp_rx_expect.valid, ERROR, "Checking expected ARP valid.", "", ID_NEVER);
        check_value(arp_rx_packet.sop, arp_rx_expect.sop, ERROR, "Checking expected ARP sop.", "", ID_NEVER);
        check_value(arp_rx_packet.eop, arp_rx_expect.eop, ERROR, "Checking expected ARP eop.", "", ID_NEVER);
        -- only check the expected data when it's relevant: reader will hold data after packet while uut might not
        if arp_rx_expect.valid then
          check_value(arp_rx_packet.data, arp_rx_expect.data, ERROR, "Checking expected ARP data.", "", HEX, KEEP_LEADING_0, ID_NEVER);
        end if;
        check_value(ip_rx_packet.valid, ip_rx_expect.valid, ERROR, "Checking expected IP valid.", "", ID_NEVER);
        check_value(ip_rx_packet.sop, ip_rx_expect.sop, ERROR, "Checking expected IP sop.", "", ID_NEVER);
        check_value(ip_rx_packet.eop, ip_rx_expect.eop, ERROR, "Checking expected IP eop.", "", ID_NEVER);
        -- only check the expected data when it's relevant: reader will hold data after packet while uut might not
        if ip_rx_expect.valid then
          check_value(ip_rx_packet.data, ip_rx_expect.data, ERROR, "Checking expected IP data.", "", HEX, KEEP_LEADING_0, ID_NEVER);
        end if;
        wait for CLK_PERIOD;
      end loop;
      --! @endcond
      note("If until here no errors showed up, a gazillion of checks on eth_rx_packet, arp_rx_packet and ip_rx_packet went fine.");

      -- Grant an additional clock cycle in order for the avst_packet_receiver to finish writing
      wait for CLK_PERIOD;

      tb_end_simulation;

    end process proc_uvvm;

  end block blk_uvvm;

end architecture tb;
