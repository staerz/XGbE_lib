-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Testbench for ip_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details Generates the environment for the ip_module.vhd.
--!
--! RESET_DURATION is set to 5
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Testbench for ip_module.vhd
entity ip_module_tb is
  generic (
    --! Clock period
    CLK_PERIOD     : time   := 6.4 ns;
    --! File containing the IP RX data
    IP_RXD_FILE    : string := "sim_data_files/IP_rx_in.dat";
    --! File containing counters on which the IP TX interface is not ready
    IP_RDY_FILE    : string := "sim_data_files/IP_tx_ready_in.dat";
    --! File to write out the IP response of the module
    IP_TXD_FILE    : string := "sim_data_files/IP_tx_out.dat";
    --! File to read expected IP response of the module
    IP_CHK_FILE    : string := "sim_data_files/IP_tx_expect.dat";
    --! File containing the UDP RX data
    UDP_RXD_FILE   : string := "sim_data_files/UDP_rx_in.dat";
    --! File containing counters on which the UDP TX interface is not ready
    UDP_RDY_FILE   : string := "sim_data_files/UDP_tx_ready_in.dat";
    --! File to write out the UDP response of the module
    UDP_TXD_FILE   : string := "sim_data_files/UDP_tx_out.dat";
    --! File to read expected UDP response of the module
    UDP_CHK_FILE   : string := "sim_data_files/UDP_tx_expect.dat";
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE   : string := "sim_data_files/MNL_RST_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG   : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG   : character := '@';
    --! End of packet check
    EOP_CHECK_EN   : std_logic := '1';
    --! Post-UDP-module UDP CRC calculation
    UDP_CRC_EN     : boolean   := true;
    --! Enable IP address filtering
    IP_FILTER_EN   : std_logic := '1';

    --! Depth of table (number of stored connections)
    ID_TABLE_DEPTH : integer range 1 to 1024 := 5;
    --! The minimal number of clock cycles between two outgoing packets.
    PAUSE_LENGTH   : integer range 0 to 1024 := 2
  );
end entity ip_module_tb;

--! @cond
library xgbe_lib;
library sim;

library testbench;
  use testbench.testbench_pkg.all;

library uvvm_util;
  context uvvm_util.uvvm_util_context;
--! @endcond

--! Implementation of ip_module_tb
architecture tb of ip_module_tb is

  --! Clock
  signal clk : std_logic;
  --! Reset, sync with #clk
  signal rst : std_logic;
  --! Counter for the simulation
  signal cnt : integer;
  --! End of File indicators of all readers (data sources and checkers)
  signal eof : std_logic_vector(3 downto 0);

  --! Reset of the simulation (only at start)
  signal sim_rst : std_logic;

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

  --! @name Avalon-ST (UDP) to module (read from file)
  --! @{

  --! TX ready
  signal udp_tx_ready  : std_logic;
  --! TX data and controls
  signal udp_tx_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );
  --! TX identifier
  signal udp_tx_id     : std_logic_vector(15 downto 0);

  --! @}

  --! @name Avalon-ST (UDP) from module (written to file)
  --! @{

  --! RX ready
  signal udp_rx_ready  : std_logic;
  --! RX data and controls
  signal udp_rx_packet : t_avst_packet(
    data(63 downto 0),
    empty(2 downto 0),
    error(0 downto 0)
  );
  --! RX identifier
  signal udp_rx_id     : std_logic_vector(15 downto 0);

  --! @}

  --! @name Configuration of the module
  --! @{
  -- vsg_off signal_007
  --! IP address
  signal my_ip      : std_logic_vector(31 downto 0) := x"c0_a8_00_1e";
  --! IP subnet mask
  signal ip_netmask : std_logic_vector(31 downto 0) := x"ff_ff_ff_00";
  --! @}

  --! IP address to be used for transmitting DHCP packets
  signal dhcp_server_ip : std_logic_vector(31 downto 0) := (others => '0');
  -- vsg_on signal_007

  --! Status of the module
  signal status_vector : std_logic_vector(12 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity xgbe_lib.ip_module
  generic map (
    EOP_CHECK_EN   => EOP_CHECK_EN,
    UDP_CRC_EN     => UDP_CRC_EN,
    IP_FILTER_EN   => IP_FILTER_EN,
    ID_TABLE_DEPTH => ID_TABLE_DEPTH,
    PAUSE_LENGTH   => PAUSE_LENGTH
  )
  port map (
    clk => clk,
    rst => rst,

    ip_rx_ready_o  => ip_tx_ready,
    ip_rx_packet_i => ip_tx_packet,

    ip_tx_ready_i  => ip_rx_ready,
    ip_tx_packet_o => ip_rx_packet,

    udp_rx_ready_o  => udp_tx_ready,
    udp_rx_packet_i => udp_tx_packet,
    udp_rx_id_i     => udp_tx_id,

    udp_tx_ready_i  => udp_rx_ready,
    udp_tx_packet_o => udp_rx_packet,
    udp_tx_id_o     => udp_rx_id,

    my_ip_i      => my_ip,
    ip_netmask_i => ip_netmask,

    dhcp_server_ip_i => dhcp_server_ip,

    status_vector_o => status_vector
  );

  -- Simulation part
  -- generating stimuli based on cnt
  blk_simulation : block
    --! @cond
    signal mnl_rst     : std_logic;
    signal udp_tx_id_r : unsigned(15 downto 0);
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
      cnt_i => cnt,

      tx_ready_i  => ip_tx_ready,
      tx_packet_o => ip_tx_packet,

      eof_o => eof(0)
    );

    --! Instantiate avst_packet_receiver to write ip_rx to IP_TXD_FILE
    inst_ip_rx : entity xgbe_lib.avst_packet_receiver
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

    --! Instantiate avst_packet_sender to read udp_tx from UDP_RXD_FILE
    inst_udp_tx : entity xgbe_lib.avst_packet_sender
    generic map (
      FILENAME     => UDP_RXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      tx_ready_i  => udp_tx_ready,
      tx_packet_o => udp_tx_packet,

      eof_o => eof(1)
    );

    --! Instantiate avst_packet_receiver to write udp_rx to UDP_TXD_FILE
    inst_upd_rx : entity xgbe_lib.avst_packet_receiver
    generic map (
      READY_FILE   => UDP_RDY_FILE,
      DATA_FILE    => UDP_TXD_FILE,
      COMMENT_FLAG => COMMENT_FLAG
    )
    port map (
      clk   => clk,
      rst   => rst,
      cnt_i => cnt,

      rx_ready_o  => udp_rx_ready,
      rx_packet_i => udp_rx_packet
    );

    --! Generate an ID for each new UDP packet
    proc_gen_id_counter : process (clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          udp_tx_id_r <= to_unsigned(1, udp_tx_id_r'length);
        elsif udp_tx_packet.eop = '1' and udp_tx_ready = '1' then
          -- let simulation generate one id which will not be generated by ip module
          -- itself in order to test the proper reaction of a non-existing id
          if udp_tx_id_r = to_unsigned(ID_TABLE_DEPTH + 1, 16) then
            udp_tx_id_r <= to_unsigned(1, udp_tx_id_r'length);
          else
            udp_tx_id_r <= udp_tx_id_r + 1;
          end if;
        else
          udp_tx_id_r <= udp_tx_id_r;
        end if;
      end if;
    end process proc_gen_id_counter;

    udp_tx_id <=
      std_logic_vector(udp_tx_id_r) when udp_tx_packet.valid = '1' else
      (others => '0');

  end block blk_simulation;

  blk_uvvm : block
    --! Expected RX data and controls
    signal ip_rx_expect  : t_avst_packet(
      data(63 downto 0),
      empty(2 downto 0),
      error(0 downto 0)
    );
    signal udp_rx_expect : t_avst_packet(
      data(63 downto 0),
      empty(2 downto 0),
      error(0 downto 0)
    );
  begin

    --! Use the avst_packet_sender to read expected IP data from an independent file
    inst_ip_tx_checker : entity xgbe_lib.avst_packet_sender
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

      eof_o => eof(2)
    );

    --! Use the avst_packet_sender to read expected UDP data from an independent file
    inst_udp_tx_checker : entity xgbe_lib.avst_packet_sender
    generic map (
      FILENAME     => UDP_CHK_FILE,
      COMMENT_FLAG => COMMENT_FLAG,
      COUNTER_FLAG => COUNTER_FLAG
    )
    port map (
      clk   => clk,
      rst   => sim_rst,
      cnt_i => cnt,

      tx_ready_i  => udp_rx_ready,
      tx_packet_o => udp_rx_expect,

      eof_o => eof(3)
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
        check_value(ip_rx_packet.valid, ip_rx_expect.valid, ERROR, "Checking expected IP valid.", "", ID_NEVER);
        check_value(ip_rx_packet.sop, ip_rx_expect.sop, ERROR, "Checking expected IP sop.", "", ID_NEVER);
        check_value(ip_rx_packet.eop, ip_rx_expect.eop, ERROR, "Checking expected IP eop.", "", ID_NEVER);
        -- only check the expected data when it's relevant: reader will hold data after packet while uut might not
        if ip_rx_expect.valid then
          check_value(ip_rx_packet.data, ip_rx_expect.data, ERROR, "Checking expected IP data.", "", HEX, KEEP_LEADING_0, ID_NEVER);
        end if;
        check_value(udp_rx_packet.valid, udp_rx_expect.valid, ERROR, "Checking expected UDP valid.", "", ID_NEVER);
        check_value(udp_rx_packet.sop, udp_rx_expect.sop, ERROR, "Checking expected UDP sop.", "", ID_NEVER);
        check_value(udp_rx_packet.eop, udp_rx_expect.eop, ERROR, "Checking expected UDP eop.", "", ID_NEVER);
        -- only check the expected data when it's relevant: reader will hold data after packet while uut might not
        if udp_rx_expect.valid then
          check_value(udp_rx_packet.data, udp_rx_expect.data, ERROR, "Checking expected UDP data.", "", HEX, KEEP_LEADING_0, ID_NEVER);
        end if;
        wait for CLK_PERIOD;
      end loop;
      note("If until here no errors showed up, a gazillion of checks on ip_rx_packet and udp_rx_packet went fine.");

      -- Grant an additional clock cycle in order for the avst_packet_receiver to finish writing
      wait for CLK_PERIOD;

      tb_end_simulation;

    end process proc_uvvm;

  end block blk_uvvm;

end architecture tb;
