-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Testbench for icmp_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details Generates the environment for the icmp_module.vhd.
--!
--! RESET_DURATION is set to 5
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Testbench for icmp_module.vhd
entity icmp_module_tb is
  generic (
    --! Clock period
    CLK_PERIOD    : time   := 6.4 ns;
    --! File containing the ICMP RX data
    ICMP_RXD_FILE : string := "sim_data_files/ICMP_rx_in.dat";
    --! File containing counters on which the TX interface is not ready
    ICMP_RDY_FILE : string := "sim_data_files/ICMP_tx_ready_in.dat";
    --! File to write out the response of the module
    ICMP_TXD_FILE : string := "sim_data_files/ICMP_tx_out.dat";
    --! File to read expected ICMP response of the module
    ICMP_CHK_FILE : string := "sim_data_files/ICMP_tx_expect.dat";
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE  : string := "sim_data_files/MNL_RST_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG  : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG  : character := '@'
  );
end entity icmp_module_tb;

--! @cond
library sim;
library xgbe_lib;

library testbench;
  use testbench.testbench_pkg.all;

library uvvm_util;
  context uvvm_util.uvvm_util_context;
--! @endcond

--! Implementation of icmp_module_tb
architecture tb of icmp_module_tb is

  --! Clock
  signal clk : std_logic;
  --! reset, sync with #clk
  signal rst : std_logic;
  --! Counter for the simulation
  signal cnt : integer;
  --! End of File indicators of all readers (data sources and checkers)
  signal eof : std_logic_vector(1 downto 0);

  --! Reset of the simulation (only at start)
  signal sim_rst : std_logic;

  --! @name Avalon-ST (IP) to module (read from file)
  --! @{

  --! TX ready
  signal ip_tx_ready     : std_logic;
  --! TX data and controls
  signal ip_tx_packet    : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );
  --! Indication of being ICMP request
  signal is_icmp_request : std_logic;

  --! @}

  --! @name Avalon-ST (IP) from module (written to file)
  --! @{

  --! RX ready
  signal icmp_rx_ready  : std_logic;
  --! RX data and controls
  signal icmp_rx_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );

  --! @}

  --! Status of the module
  signal status_vector : std_logic_vector(2 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity xgbe_lib.icmp_module
  port map (
    clk => clk,
    rst => rst,

    -- Avalon-ST RX interface
    ip_rx_ready_o     => ip_tx_ready,
    ip_rx_packet_i    => ip_tx_packet,
    is_icmp_request_i => is_icmp_request,

    -- Avalon-ST TX interface
    icmp_tx_ready_i  => icmp_rx_ready,
    icmp_tx_packet_o => icmp_rx_packet,

    -- Status of the module
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

    --! Instantiate avst_packet_sender to read ip_tx from ICMP_RXD_FILE
    inst_icmp_tx : entity fpga.avst_packet_sender
    generic map (
      FILENAME     => ICMP_RXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      tx_ready_i  => ip_tx_ready,
      tx_packet_o => ip_tx_packet,

      eof_o => eof(0)
    );

    --! Instantiate avst_packet_receiver to write icmp_rx to ICMP_TXD_FILE
    inst_icmp_rx : entity fpga.avst_packet_receiver
    generic map (
      READY_FILE   => ICMP_RDY_FILE,
      DATA_FILE    => ICMP_TXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      rx_ready_o  => icmp_rx_ready,
      rx_packet_i => icmp_rx_packet
    );

    -- mark any packet as valid icmp packet
    is_icmp_request <= '1';

  end block blk_simulation;

  blk_uvvm : block
    --! Expected RX data and controls
    signal icmp_rx_expect : t_avst_packet(
      data(63 downto 0),
      empty(2 downto 0),
      error(0 downto 0)
    );
  begin

    --! Use the avst_packet_sender to read expected ICMP data from an independent file
    inst_icmp_tx_checker : entity fpga.avst_packet_sender
    generic map (
      FILENAME     => ICMP_CHK_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => sim_rst,
      cnt_i => cnt,

      tx_ready_i  => icmp_rx_ready,
      tx_packet_o => icmp_rx_expect,

      eof_o => eof(1)
    );

    --! UVVM check
    proc_uvvm : process
      -- since the rx fifo is involved, it will return Xes upon reset, and the version of UVVM we use cannot handle that comparison
      -- so we explicitly catch those Xes and then override with 0s.
      variable icmp_rx_packet_no_x : t_avst_packet(
        data(63 downto 0),
        empty(2 downto 0),
        error(0 downto 0)
      );
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
        if is_x(icmp_rx_packet.valid) then
          icmp_rx_packet_no_x := (data => (others => '0'), empty => (others => '0'), error => (others => '0'), others => '0');
        else
          icmp_rx_packet_no_x := icmp_rx_packet;
        end if;
        check_value(icmp_rx_packet_no_x.valid, icmp_rx_expect.valid, ERROR, "Checking expected ICMP valid.", "", ID_NEVER);
        check_value(icmp_rx_packet_no_x.sop, icmp_rx_expect.sop, ERROR, "Checking expected ICMP sop.", "", ID_NEVER);
        check_value(icmp_rx_packet_no_x.eop, icmp_rx_expect.eop, ERROR, "Checking expected ICMP eop.", "", ID_NEVER);
        -- only check the expected data when it's relevant: reader will hold data after packet while uut might not
        if icmp_rx_expect.valid then
          check_value(icmp_rx_packet_no_x.data, icmp_rx_expect.data, ERROR, "Checking expected ICMP data.", "", HEX, KEEP_LEADING_0, ID_NEVER);
        end if;
        wait for CLK_PERIOD;
      end loop;
      --! @endcond
      note("If until here no errors showed up, a gazillion of checks on icmp_rx_packet went fine.");

      -- Grant an additional clock cycle in order for the avst_packet_receiver to finish writing
      wait for CLK_PERIOD;

      tb_end_simulation;

    end process proc_uvvm;

  end block blk_uvvm;

end architecture tb;
