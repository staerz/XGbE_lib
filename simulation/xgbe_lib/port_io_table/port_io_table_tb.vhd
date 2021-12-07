-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Testbench for port_io_table.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details Generates the environment for the port_io_table.vhd.
--! Different pairs of addresses are first written to the port_io_table.
--! Then some requests are sent to see the response of the port_io_table.
--! The example is written as an ARP table: MAC and IP addresses are used.
--------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.std_logic_1164.all;
--! @endcond

--! Testbench for port_io_table.vhd
entity port_io_table_tb is
  generic (
    --! Clock period
    CLK_PERIOD     : time   := 6.4 ns;
    --! File containing the DISCO RX data
    DISCO_RXD_FILE : string := "sim_data_files/DISCO_rx_in.dat";
    --! File containing the RECO RX data
    RECO_RXD_FILE  : string := "sim_data_files/RECO_rx_in.dat";
    --! File to write out the RECO response of the module
    RECO_TXD_FILE  : string := "sim_data_files/RECO_tx_out.dat";
    --! File to read expected RECO response of the module
    RECO_CHK_FILE  : string := "sim_data_files/RECO_tx_expect.dat";
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE   : string := "sim_data_files/MNL_RST_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG   : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG   : character := '@';

    --! Width of the port to be associated
    PORT_I_W       : integer range 1 to 64   := 32;
    --! Width of the associated port
    PORT_O_W       : integer range 1 to 64   := 48;
    --! Depth of the table
    TABLE_DEPTH    : integer range 1 to 1024 := 3
  );
end entity port_io_table_tb;

--! @cond
library xgbe_lib;
library sim;
library fpga;
  context fpga.interfaces;

library testbench;
  use testbench.testbench_pkg.all;

library uvvm_util;
  context uvvm_util.uvvm_util_context;
--! @endcond

--! Implementation of port_io_table_tb
architecture tb of port_io_table_tb is

  --! Clock
  signal clk : std_logic;
  --! Reset, sync with #clk
  signal rst : std_logic;
  --! Counter for the simulation
  signal cnt : integer;
  --! End of File indicators of all readers (data sources and checkers)
  signal eof : std_logic_vector(2 downto 0);

  --! Reset of the simulation (only at start)
  signal sim_rst : std_logic;

  --! Discovery interface for writing pair of associated addresses/ports
  --! Valid is interpreted as write enable
  signal disco_packet : t_avst_packet(data(PORT_I_W + PORT_O_W - 1 downto 0), empty(2 downto 0), error(0 downto 0));

  --! Recovery request interface
  --! Valid is interpreted as reco enable
  signal reco_tx_packet : t_avst_packet(data(PORT_I_W - 1 downto 0), empty(0 downto 0), error(0 downto 0));

  --! Recovery output port (response next clk cycle)
  --! Valid is interpreted as reco found
  signal reco_rx_packet : t_avst_packet(data(PORT_O_W - 1 downto 0), empty(1 downto 0), error(0 downto 0));

  --! Status of the module
  signal status_vector_o : std_logic_vector(1 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity xgbe_lib.port_io_table
  generic map (
    PORT_I_W    => PORT_I_W,
    PORT_O_W    => PORT_O_W,
    TABLE_DEPTH => TABLE_DEPTH
  )
  port map (
    clk => clk,
    rst => rst,

    -- interface for writing new discovered MAC and IP to ARP table
    disco_wren_i => disco_packet.valid,
    disco_port_i => disco_packet.data(PORT_I_W + PORT_O_W - 1 downto PORT_O_W),
    disco_port_o => disco_packet.data(PORT_O_W - 1 downto 0),

    -- interface for recovered MAC address from given IP address
    reco_en_i    => reco_tx_packet.valid,
    reco_port_i  => reco_tx_packet.data,
    -- response (next clk)
    reco_found_o => reco_rx_packet.valid,
    reco_port_o  => reco_rx_packet.data,

    -- status of the ARP table, see definitions below
    status_vector_o => status_vector_o
  );

  -- Since we abuse the packet format a bit, we have to set the other elements in order to make the writer happy
  reco_rx_packet.eop   <= reco_rx_packet.valid;
  reco_rx_packet.sop   <= reco_rx_packet.valid;
  reco_rx_packet.empty <= (others => '0');
  reco_rx_packet.error <= (others => '0');

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

    --! Instantiate avst_packet_sender to read disco from DISCO_RXD_FILE
    inst_disco_tx : entity xgbe_lib.avst_packet_sender
    generic map (
      FILENAME      => DISCO_RXD_FILE,
      COMMENT_FLAG  => COMMENT_FLAG,
      COUNTER_FLAG  => COUNTER_FLAG,
      WORDSPERLINE  => 5,
      BITSPERSYMBOL => 16

    )
    port map (
      clk   => clk,
      rst   => sim_rst,
      cnt_i => cnt,

      tx_ready_i  => '1',
      tx_packet_o => disco_packet,

      eof_o => eof(0)
    );

    --! Instantiate avst_packet_sender to read reco_tx from RECO_RXD_FILE
    inst_reco_tx : entity xgbe_lib.avst_packet_sender
    generic map (
      FILENAME      => RECO_RXD_FILE,
      COMMENT_FLAG  => COMMENT_FLAG,
      COUNTER_FLAG  => COUNTER_FLAG,
      WORDSPERLINE  => 2,
      BITSPERSYMBOL => 16
    )
    port map (
      clk   => clk,
      rst   => sim_rst,
      cnt_i => cnt,

      tx_ready_i  => '1',
      tx_packet_o => reco_tx_packet,

      eof_o => eof(1)
    );

    --! Instantiate avst_packet_receiver to write reco_rx to RECO_TXD_FILE
    inst_reco_rx : entity xgbe_lib.avst_packet_receiver
    generic map (
      DATA_FILE     => RECO_TXD_FILE,
      COMMENT_FLAG  => COMMENT_FLAG,
      WORDSPERLINE  => 3,
      BITSPERSYMBOL => 16
    )
    port map (
      clk   => clk,
      rst   => sim_rst,
      cnt_i => cnt,

      rx_packet_i => reco_rx_packet
    );

  end block blk_simulation;

  blk_uvvm : block
    --! Expected RECO data and controls
    signal reco_expect : t_avst_packet(data(PORT_O_W - 1 downto 0), empty(1 downto 0), error(0 downto 0));
  begin

    --! Use the avst_packet_sender to read expected reco data from an independent file
    inst_reco_checker : entity xgbe_lib.avst_packet_sender
    generic map (
      FILENAME      => RECO_CHK_FILE,
      COMMENT_FLAG  => COMMENT_FLAG,
      COUNTER_FLAG  => COUNTER_FLAG,
      WORDSPERLINE  => 3,
      BITSPERSYMBOL => 16
    )
    port map (
      clk   => clk,
      rst   => sim_rst,
      cnt_i => cnt,

      tx_ready_i  => '1',
      tx_packet_o => reco_expect,

      eof_o => eof(2)
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
        check_value(reco_rx_packet.valid, reco_expect.valid, ERROR, "Checking expected valid.", "", ID_NEVER);
        -- only check the expected data when it's relevant: reader will hold data after packet while uut might not
        if reco_expect.valid then
          check_value(reco_rx_packet.data, reco_expect.data, ERROR, "Checking expected data.", "", HEX, KEEP_LEADING_0, ID_NEVER);
        end if;
        wait for CLK_PERIOD;
      end loop;
      note("If until here no errors showed up, a gazillion of checks on reco_rx_packet went fine.");

      -- Grant an additional clock cycle in order for the avst_packet_receiver to finish writing
      wait for CLK_PERIOD;

      tb_end_simulation;

    end process proc_uvvm;

  end block blk_uvvm;

end architecture tb;
