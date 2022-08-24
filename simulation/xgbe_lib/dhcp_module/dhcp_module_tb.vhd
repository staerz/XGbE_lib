-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Testbench for dhcp_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details Generates the environment for the dhcp_module.vhd.
--! Data packets are read from #DHCP_RXD_FILE and passed to the dhcp_module.
--! #MY_MAC and #MY_IP must be configured in accordance with data in that file.
--! The module's output is logged to #DHCP_TXD_FILE.
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Testbench for dhcp_module.vhd
entity dhcp_module_tb is
  generic (
    --! Clock period
    CLK_PERIOD        : time   := 6.4 ns;
    --! File containing the DHCP RX data
    DHCP_RXD_FILE     : string := "sim_data_files/DHCP_rx_in.dat";
    --! File containing counters on which the TX interface is not ready
    DHCP_RDY_FILE     : string := "sim_data_files/DHCP_tx_ready_in.dat";
    --! File to write out the response of the module
    DHCP_TXD_FILE     : string := "sim_data_files/DHCP_tx_out.dat";
    --! File to read expected response of the module
    DHCP_CHK_FILE     : string := "sim_data_files/DHCP_tx_expect.dat";
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE      : string := "sim_data_files/MNL_RST_in.dat";

    --! Definition how many clock cycles a millisecond is
    ONE_MILLISECOND   : integer := 7;

    --! Flag to use to indicate comments
    COMMENT_FLAG      : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG      : character := '@';

    --! MAC address
    MY_MAC            : std_logic_vector(47 downto 0) := x"00_22_8F_02_41_EE";

    --! UDP CRC calculation enable
    UDP_CRC_EN        : boolean                 := false;
    --! Timeout in milliseconds
    DHCP_TIMEOUT       : integer range 2 to 1000 := 10;
    --! Cycle time in milliseconds for APR requests (when repetitions are needed)
    DHCP_REQUEST_CYCLE : integer range 1 to 1000 := 2;
    --! Depth of DHCP table (number of stored connections)
    DHCP_TABLE_DEPTH   : integer range 1 to 1024 := 4
  );
end entity dhcp_module_tb;

--! @cond
library xgbe_lib;
library sim;

library testbench;
  use testbench.testbench_pkg.all;

library uvvm_util;
  context uvvm_util.uvvm_util_context;
--! @endcond

--! Implementation of dhcp_module_tb
architecture tb of dhcp_module_tb is

  --! Clock
  signal clk : std_logic;
  --! reset, sync with #clk
  signal rst : std_logic;
  --! Counter for the simulation
  signal cnt : integer;
  --! End of File indicators of all readers (data sources and checkers)
  signal eof : std_logic_vector(1 downto 0);

  --! @name Avalon-ST (DHCP as bare UDP) to module (read from file)
  --! @{

  --! TX ready
  signal dhcp_tx_ready  : std_logic;
  --! TX data and controls
  signal dhcp_tx_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));

  --! @}

  --! @name Avalon-ST (DHCP as bare UDP) from module (written to file)
  --! @{

  --! RX ready
  signal dhcp_rx_ready  : std_logic;
  --! RX data and controls
  signal dhcp_rx_packet : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));

  --! @}

  --! Assigned (retrieved) IP address
  signal my_ip          : std_logic_vector(31 downto 0);

  --! @name Interface for recovering MAC address from given IP address
  --! @{

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
  uut : entity xgbe_lib.dhcp_module
  generic map (
    UDP_CRC_EN         => UDP_CRC_EN,
    DHCP_REQUEST_CYCLE => DHCP_REQUEST_CYCLE,
    DHCP_TIMEOUT       => DHCP_TIMEOUT,
    DHCP_TABLE_DEPTH   => DHCP_TABLE_DEPTH
  )
  port map (
    clk => clk,
    rst => rst,

    -- signals from dhcp requester
    dhcp_rx_ready_o  => dhcp_tx_ready,
    dhcp_rx_packet_i => dhcp_tx_packet,

    -- signals to dhcp requester
    dhcp_tx_ready_i  => dhcp_rx_ready,
    dhcp_tx_packet_o => dhcp_rx_packet,

    -- interface for recovering mac address from given ip address
    reco_en_i   => reco_en,
    reco_ip_i   => reco_ip,
    -- response (next clk if directly found, later if dhcp request needs to be sent)
    reco_mac_o  => reco_mac,
    reco_done_o => reco_done,

    my_mac_i => MY_MAC,
    my_ip_o  => my_ip,

    one_ms_tick_i => one_ms_tick,

    -- status of the DHCP module, see definitions below
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

    --! Instantiate avst_packet_sender to read dhcp_tx from DHCP_RXD_FILE
    inst_dhcp_tx : entity xgbe_lib.avst_packet_sender
    generic map (
      FILENAME     => DHCP_RXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      tx_ready_i  => dhcp_tx_ready,
      tx_packet_o => dhcp_tx_packet,

      eof_o => eof(0)
    );

    --! Instantiate avst_packet_receiver to write dhcp_rx to DHCP_TXD_FILE
    inst_dhcp_rx : entity xgbe_lib.avst_packet_receiver
    generic map (
      READY_FILE   => DHCP_RDY_FILE,
      DATA_FILE    => DHCP_TXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      rx_ready_o  => dhcp_rx_ready,
      rx_packet_i => dhcp_rx_packet
    );

    with cnt mod 5 select one_ms_tick <=
      '1' when 0,
      '0' when others;

    with cnt select reco_ip <=
      x"C0_A8_00_23" when 100,
      (others => '0') when others;

    with cnt select reco_en <=
      '1' when 100,
      '0' when others;

  end block blk_simulation;

  blk_uvvm : block
    --! Expected RX data and controls
    signal dhcp_rx_expect : t_avst_packet(data(63 downto 0), empty(2 downto 0), error(0 downto 0));
  begin

    --! Use the avst_packet_sender to read expected data from an independent file
    inst_dhcp_tx_checker : entity xgbe_lib.avst_packet_sender
    generic map (
      FILENAME     => DHCP_CHK_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      tx_ready_i  => dhcp_rx_ready,
      tx_packet_o => dhcp_rx_expect,

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
        check_value(dhcp_rx_packet.valid, dhcp_rx_expect.valid, ERROR, "Checking expected valid.", "", ID_NEVER);
        check_value(dhcp_rx_packet.sop, dhcp_rx_expect.sop, ERROR, "Checking expected sop.", "", ID_NEVER);
        check_value(dhcp_rx_packet.eop, dhcp_rx_expect.eop, ERROR, "Checking expected eop.", "", ID_NEVER);
        -- only check the expected data when it's relevant: reader will hold data after packet while uut might not
        if dhcp_rx_expect.valid then
          check_value(dhcp_rx_packet.data, dhcp_rx_expect.data, ERROR, "Checking expected data.", "", HEX, KEEP_LEADING_0, ID_NEVER);
        end if;
        wait for CLK_PERIOD;
      end loop;
      note("If until here no errors showed up, a gazillion of checks on dhcp_rx_packet went fine.");

      -- Grant an additional clock cycle in order for the avst_packet_receiver to finish writing
      wait for CLK_PERIOD;

      tb_end_simulation;

    end process proc_uvvm;

  end block blk_uvvm;

end architecture tb;
