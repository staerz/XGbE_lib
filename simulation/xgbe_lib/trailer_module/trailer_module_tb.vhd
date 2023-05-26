-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Testbench for trailer_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details Generates the environment for the trailer_module.vhd.
--! Data packets read from AVST_RXD_FILE are pushed through the
--! trailer module configured with a specific header_length.
--! The output is written to AVST_TXD_FILE.
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Testbench for trailer_module.vhd
entity trailer_module_tb is
  generic (
    --! Clock period
    CLK_PERIOD      : time   := 6.4 ns;
    --! File containing the AVST RX data
    AVST_RXD_FILE   : string := "sim_data_files/AVST_rx_in.dat";
    --! File containing counters on which the TX interface is not ready
    AVST_RDY_FILE   : string := "sim_data_files/AVST_tx_ready_in.dat";
    --! File to write out the response of the module
    AVST_TXD_FILE   : string := "sim_data_files/AVST_tx_out.dat";
    --! File to read expected AVST response of the module
    AVST_CHK_FILE   : string := "sim_data_files/AVST_tx_expect.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG    : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG    : character := '@';
    --! Number of bytes of the header to be cut off
    HEADER_LENGTH   : integer   := 3;
    --! (Maximum) packet size in bytes
    MAX_PACKET_SIZE : integer   := 1500
  );
end entity trailer_module_tb;

--! @cond
library sim;
library xgbe_lib;

library testbench;
  use testbench.testbench_pkg.all;

library uvvm_util;
  context uvvm_util.uvvm_util_context;
--! @endcond

--! Implementation of trailer_module_tb
architecture tb of trailer_module_tb is

  --! Number of interfaces (if multiple interfaces are used)
  constant N_INTERFACES : positive := 2;

  --! Clock
  signal clk : std_logic;
  --! Reset, sync with #clk
  signal rst : std_logic;
  --! Counter for the simulation
  signal cnt : integer;
  --! End of File indicators of all readers (data sources and checkers)
  signal eof : std_logic_vector(1 downto 0);

  --! @name Avalon-ST to module (read from file)
  --! @{

  --! TX ready
  signal tx_ready  : std_logic;
  --! TX data and controls
  signal tx_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );

  --! Additional rx indicator if multiple interfaces are used
  constant TX_MUX : std_logic_vector(N_INTERFACES - 1 downto 0) := (others => '0');

  --! @}

  --! @name Avalon-ST from module (written to file)
  --! @{

  --! RX ready
  signal rx_ready  : std_logic;
  --! RX data and controls
  signal rx_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );
  --! Additional tx indicator if multiple interfaces are used
  signal rx_mux    : std_logic_vector(N_INTERFACES - 1 downto 0);

--! @}

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity xgbe_lib.trailer_module
  generic map (
    HEADER_LENGTH   => HEADER_LENGTH,
    N_INTERFACES    => N_INTERFACES,
    MAX_PACKET_SIZE => MAX_PACKET_SIZE
  )
  port map (
    clk => clk,
    rst => rst,

    rx_ready_o  => tx_ready,
    rx_packet_i => tx_packet,
    rx_mux_i    => TX_MUX,

    rx_count_o => open,

    tx_ready_i  => rx_ready,
    tx_packet_o => rx_packet,
    tx_mux_o    => rx_mux
  );

  -- Simulation part
  -- generating stimuli based on cnt
  blk_simulation : block
  begin

    --! Instantiate simulation_basics to start
    inst_sim_basics : entity sim.simulation_basics
    generic map (
      CLK_PERIOD => CLK_PERIOD
    )
    port map (
      clk => clk,
      rst => rst,
      cnt => cnt
    );

    --! Instantiate avst_packet_sender to read tx from AVST_RXD_FILE
    inst_tx : entity fpga.avst_packet_sender
    generic map (
      FILENAME     => AVST_RXD_FILE,
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

    --! Instantiate avst_packet_receiver to write rx to AVST_TXD_FILE
    inst_rx : entity fpga.avst_packet_receiver
    generic map (
      READY_FILE   => AVST_RDY_FILE,
      DATA_FILE    => AVST_TXD_FILE,
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

    --! Use the avst_packet_sender to read expected data from an independent file
    inst_tx_checker : entity fpga.avst_packet_sender
    generic map (
      FILENAME     => AVST_CHK_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
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
      await_value(rst, '0', 10 ns, 60 * CLK_PERIOD, ERROR, "Reset drop expected.");

      --! @cond #(doxygen fails parsing the while loop)
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
      --! @endcond
      note("If until here no errors showed up, a gazillion of checks on rx_packet went fine.");

      -- Grant an additional clock cycle in order for the avst_packet_receiver to finish writing
      wait for CLK_PERIOD;

      tb_end_simulation;

    end process proc_uvvm;

  end block blk_uvvm;

end architecture tb;
