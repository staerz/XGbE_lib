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
    --! Clock period
    CLK_PERIOD     : time   := 6.4 ns;
    --! File containing the RST RX data
    RST_RXD_FILE   : string := "sim_data_files/RST_rx_in.dat";
    --! File containing counters on which the TX interface is not ready
    RST_RDY_FILE   : string := "sim_data_files/RST_tx_ready_in.dat";
    --! File to write out the response of the module
    RST_TXD_FILE   : string := "sim_data_files/RST_tx_out.dat";
    --! File to read expected RST response of the module
    RST_CHK_FILE   : string := "sim_data_files/RST_tx_expect.dat";
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
library xgbe_lib;

library testbench;
  use testbench.testbench_pkg.all;

library uvvm_util;
  context uvvm_util.uvvm_util_context;
--! @endcond

--! Implementation of reset_module_tb
architecture tb of reset_module_tb is

  --! Clock
  signal clk : std_logic;
  --! Reset, sync with #clk
  signal rst : std_logic;
  --! Counter for the simulation
  signal cnt : integer;
  --! End of File indicators of all readers (data sources and checkers)
  signal eof : std_logic_vector(1 downto 0);

  --! Reset of the simulation (only at start)
  signal sim_rst : std_logic;

  --! @name Avalon-ST (IPbus) to module (read from file)
  --! @{

  --! TX ready
  signal tx_ready  : std_logic;
  --! TX data and controls
  signal tx_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );
  --! @}

  --! @name Avalon-ST (IPbus) from module (written to file)
  --! @{

  --! RX ready
  signal rx_ready  : std_logic;
  --! RX data and controls
  signal rx_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );
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
  -- generating stimuli based on cnt
  blk_simulation : block
    signal mnl_rst : std_logic;
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

    --! Instantiate avst_packet_sender to read rst_tx from RST_RXD_FILE
    inst_tx : entity fpga.avst_packet_sender
    generic map (
      FILENAME     => RST_RXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      tx_ready_i  => tx_ready,
      tx_packet_o => tx_packet,

      eof_o => eof(0)
    );

    --! Instantiate avst_packet_receiver to write rst_rx to RST_TXD_FILE
    inst_rx : entity fpga.avst_packet_receiver
    generic map (
      READY_FILE   => RST_RDY_FILE,
      DATA_FILE    => RST_TXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      rx_ready_o  => rx_ready,
      rx_packet_i => rx_packet
    );

  end block blk_simulation;

  blk_uvvm : block
    --! Expected RX data and controls
    signal rx_expect : t_avst_packet(
      data(63 downto 0),
      empty(2 downto 0),
      error(0 downto 0)
    );
  begin

    --! Use the avst_packet_sender to read expected RST data from an independent file
    inst_rst_tx_checker : entity fpga.avst_packet_sender
    generic map (
      FILENAME     => RST_CHK_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => sim_rst,
      cnt_i => cnt,

      tx_ready_i  => rx_ready,
      tx_packet_o => rx_expect,

      eof_o => eof(1)
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

      note("The following acknowledge check messages are all suppressed.");
      -- make sure to be slightly after the rising edge
      wait for 1 ns;
      -- Now we just compare expected data and valid to actual values as long as there's sth. to read from files
      -- vsg_disable_next_line whitespace_013
      while nand(eof) loop
        check_value(rx_packet.valid, rx_expect.valid, ERROR, "Checking expected valid.", "", ID_NEVER);
        check_value(rx_packet.sop, rx_expect.sop, ERROR, "Checking expected sop.", "", ID_NEVER);
        check_value(rx_packet.eop, rx_expect.eop, ERROR, "Checking expected eop.", "", ID_NEVER);
        -- only check the expected data when it's relevant: reader will hold data after packet while uut might not
        if rx_expect.valid then
          check_value(rx_packet.data, rx_expect.data, ERROR, "Checking expected data.", "", HEX, KEEP_LEADING_0, ID_NEVER);
        end if;
        wait for CLK_PERIOD;
      end loop;
      note("If until here no errors showed up, a gazillion of checks on rx_packet went fine.");

      -- Grant an additional clock cycle in order for the avst_packet_receiver to finish writing
      wait for CLK_PERIOD;

      tb_end_simulation;

    end process proc_uvvm;

  end block blk_uvvm;

end architecture tb;
