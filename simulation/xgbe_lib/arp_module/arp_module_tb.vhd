-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Testbench for arp_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details Generates the environment for the arp_module.vhd.
--! Data packets are read from #ARP_RXD_FILE and passed to the arp_module.
--! #MY_MAC and #MY_IP must be configured in accordance with data in that file.
--! The module's output is logged to #ARP_TXD_FILE.
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Testbench for arp_module.vhd
entity arp_module_tb is
  generic (
    --! Clock period
    CLK_PERIOD        : time   := 6.4 ns;
    --! File containing the ARP RX data
    ARP_RXD_FILE      : string := "sim_data_files/ARP_rx_in.dat";
    --! File containing counters on which the TX interface is not ready
    ARP_RDY_FILE      : string := "sim_data_files/ARP_tx_ready_in.dat";
    --! File to write out the response of the module
    ARP_TXD_FILE      : string := "sim_data_files/ARP_tx_out.dat";
    --! File to read expected response of the module
    ARP_CHK_FILE      : string := "sim_data_files/ARP_tx_expect.dat";
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE      : string := "sim_data_files/MNL_RST_in.dat";
    --! File containing IP addresses to be recovered
    RECO_FILE         : string := "sim_data_files/RECO_in.dat";

    --! Definition how many clock cycles a millisecond is
    ONE_MILLISECOND   : integer := 7;

    --! Flag to use to indicate comments
    COMMENT_FLAG      : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG      : character := '@';

    --! MAC address
    MY_MAC            : std_logic_vector(47 downto 0) := x"00_22_8F_02_41_EE";
    --! IP address
    MY_IP             : std_logic_vector(31 downto 0) := x"C0_A8_00_1E";

    --! Timeout in milliseconds
    ARP_TIMEOUT       : integer range 2 to 1000 := 10;
    --! Cycle time in milliseconds for APR requests (when repetitions are needed)
    ARP_REQUEST_CYCLE : integer range 1 to 1000 := 2;
    --! Depth of ARP table (number of stored connections)
    ARP_TABLE_DEPTH   : integer range 1 to 1024 := 4
  );
end entity arp_module_tb;

--! @cond
library xgbe_lib;
library sim;

library testbench;
  use testbench.testbench_pkg.all;

library uvvm_util;
  context uvvm_util.uvvm_util_context;
--! @endcond

--! Implementation of arp_module_tb
architecture tb of arp_module_tb is

  --! Clock
  signal clk : std_logic;
  --! reset, sync with #clk
  signal rst : std_logic;
  --! Counter for the simulation
  signal cnt : integer;
  --! End of File indicators of all readers (data sources and checkers)
  signal eof : std_logic_vector(2 downto 0);

  --! @name Avalon-ST (ARP with Ethernet header) to module (read from file)
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

  --! @name Interface for recovering MAC address from given IP address
  --! @{

  --! Data read from file
  signal reco      : t_avst_packet(
    data(31 downto 0),
    empty(1 downto 0),
    error(0 downto 0)
  );
  --! Recovery enable
  signal reco_en   : std_logic;
  --! IP address to recover
  signal reco_ip   : std_logic_vector(31 downto 0);
  --! Recovered MAX address
  signal reco_mac  : std_logic_vector(47 downto 0);
  --! recovery success: 1 = found, 0 = not found (time out)
  signal reco_done : std_logic;
  --! @}

  --! Clock cycle when 1 millisecond is passed
  signal one_ms_tick : std_logic;

  --! Status of the module
  signal status_vector : std_logic_vector(4 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity xgbe_lib.arp_module
  generic map (
    ARP_REQUEST_CYCLE => ARP_REQUEST_CYCLE,
    ARP_TIMEOUT       => ARP_TIMEOUT,
    ARP_TABLE_DEPTH   => ARP_TABLE_DEPTH
  )
  port map (
    clk => clk,
    rst => rst,

    -- signals from arp requester
    arp_rx_ready_o  => arp_tx_ready,
    arp_rx_packet_i => arp_tx_packet,

    -- signals to arp requester
    arp_tx_ready_i  => arp_rx_ready,
    arp_tx_packet_o => arp_rx_packet,

    -- interface for recovering mac address from given ip address
    reco_en_i   => reco_en,
    reco_ip_i   => reco_ip,
    -- response (next clk if directly found, later if arp request needs to be sent)
    reco_mac_o  => reco_mac,
    reco_done_o => reco_done,

    my_mac_i      => MY_MAC,
    my_ip_i       => MY_IP,
    my_ip_valid_i => '1',

    one_ms_tick_i => one_ms_tick,

    -- status of the ARP module, see definitions below
    status_vector_o => status_vector
  );

  -- Simulation part
  -- generating stimuli based on cnt
  blk_simulation : block
    signal sim_rst : std_logic;
    signal mnl_rst : std_logic;
  begin

    --! Instantiate simulation_basics to start
    inst_sim_basics : entity sim.simulation_basics
    generic map (
      CLK_OFFSET => 0 ns,
      CLK_PERIOD => CLK_PERIOD
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

      eof_o => eof(0)
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

    with cnt mod 5 select one_ms_tick <=
      '1' when 0,
      '0' when others;

    inst_reco : entity fpga.avst_packet_sender
    generic map (
      FILENAME      => RECO_FILE,
      COMMENT_FLAG  => COMMENT_FLAG,
      COUNTER_FLAG  => COUNTER_FLAG,
      BITSPERWORD   => 8,
      WORDSPERLINE  => 4,
      BITSPERSYMBOL => 8
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      tx_ready_i  => '1',
      tx_packet_o => reco,

      eof_o => eof(2)
    );

    reco_ip <= reco.data;
    reco_en <= reco.sop;

  end block blk_simulation;

  blk_uvvm : block
    --! Expected RX data and controls
    signal arp_rx_expect : t_avst_packet(
      data(63 downto 0),
      empty(2 downto 0),
      error(0 downto 0)
    );
  begin

    --! Use the avst_packet_sender to read expected data from an independent file
    inst_arp_tx_checker : entity fpga.avst_packet_sender
    generic map (
      FILENAME     => ARP_CHK_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      tx_ready_i  => arp_rx_ready,
      tx_packet_o => arp_rx_expect,

      eof_o => eof(1)
    );

    --! UVVM check
    proc_uvvm : process
    begin
      -- Wait a bit to let simulation settle
      wait for CLK_PERIOD;
      -- Wait for the reset to drop
      await_value(rst, '0', 0 ns, 60 * CLK_PERIOD, ERROR, "Reset drop expected.");

      note("The following acknowledge check messages are all suppressed.");
      -- make sure to be slightly after the rising edge
      wait for 1 ns;
      -- Now we just compare expected data and valid to actual values as long as there's sth. to read from files
      -- vsg_disable_next_line whitespace_013
      while nand(eof) loop
        check_value(arp_rx_packet.valid, arp_rx_expect.valid, ERROR, "Checking expected valid.", "", ID_NEVER);
        check_value(arp_rx_packet.sop, arp_rx_expect.sop, ERROR, "Checking expected sop.", "", ID_NEVER);
        check_value(arp_rx_packet.eop, arp_rx_expect.eop, ERROR, "Checking expected eop.", "", ID_NEVER);
        -- only check the expected data when it's relevant: reader will hold data after packet while uut might not
        if arp_rx_expect.valid then
          check_value(arp_rx_packet.data, arp_rx_expect.data, ERROR, "Checking expected data.", "", HEX, KEEP_LEADING_0, ID_NEVER);
        end if;
        wait for CLK_PERIOD;
      end loop;
      note("If until here no errors showed up, a gazillion of checks on arp_rx_packet went fine.");

      -- Grant an additional clock cycle in order for the avst_packet_receiver to finish writing
      wait for CLK_PERIOD;

      tb_end_simulation;

    end process proc_uvvm;

  end block blk_uvvm;

end architecture tb;
