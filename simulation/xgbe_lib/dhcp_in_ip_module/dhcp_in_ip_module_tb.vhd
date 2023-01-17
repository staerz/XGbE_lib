-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Testbench for dhcp_module.vhd as UDP client of the ip_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details Tests the dhcp_module.vhd as UDP client of the ip_module.vhd.
--!
--! RESET_DURATION is set to 5
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Testbench for dhcp_module.vhd as a UDP client of the ip_module.vhd
entity dhcp_in_ip_module_tb is
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
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE   : string := "sim_data_files/MNL_RST_in.dat";
    --! File containing counters on which a boot is carried out
    BOOT_FILE      : string := "sim_data_files/BOOT_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG   : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG   : character := '@';
    --! End of packet check
    EOP_CHECK_EN   : std_logic := '1';

    --! MAC address
    MY_MAC         : std_logic_vector(47 downto 0) := x"00_22_8F_02_41_EE";

    --! Post-UDP-module UDP CRC calculation
    UDP_CRC_EN     : boolean := false;

    --! Enable IP address filtering
    IP_FILTER_EN   : std_logic               := '1';
    --! Depth of table (number of stored connections)
    ID_TABLE_DEPTH : integer range 1 to 1024 := 5;
    --! The minimal number of clock cycles between two outgoing packets.
    PAUSE_LENGTH   : integer range 0 to 1024 := 2
  );
end entity dhcp_in_ip_module_tb;

--! @cond
library xgbe_lib;
library sim;

library testbench;
  use testbench.testbench_pkg.all;

library uvvm_util;
  context uvvm_util.uvvm_util_context;
--! @endcond

--! Implementation of dhcp_in_ip_module_tb
architecture tb of dhcp_in_ip_module_tb is

  --! Clock
  signal clk  : std_logic;
  --! Reset, sync with #clk
  signal rst  : std_logic;
  --! @details Rebooting with last assigned IP address (rather than resetting requesting new one)
  signal boot : std_logic;
  --! Counter for the simulation
  signal cnt  : integer;
  --! End of File indicators of all readers (data sources and checkers)
  signal eof  : std_logic_vector(3 downto 0);

  --! Reset of the simulation (only at start)
  signal sim_rst : std_logic;

  --! @brief Boot, sync with #clk
  --! @name Avalon-ST (IP) to IP module (read from file)
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

  --! @name Avalon-ST (IP) from IP module (written to file)
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

  --! @name Avalon-ST (UDP) to DHCP module
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

  --! @name Avalon-ST (UDP) from DHCP module
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

  --! @name Interface for recovering MAC address from given IP address
  --! @{

  --! Recovery enable to ARP module
  signal reco_en   : std_logic;
  --! IP address to recover to ARP module
  signal reco_ip   : std_logic_vector(31 downto 0);
  --! Recovery done indicator: 1 = found or timeout
  signal reco_done : std_logic;
  --! recovery failure: 1 = not found (time out), 0 = found
  signal reco_fail : std_logic;
  --! @}

  --! @name Configuration of the module
  --! @{
  --! Assigned (retrieved) IP address
  signal my_ip      : std_logic_vector(31 downto 0);
  --! IP subnet mask
  signal ip_netmask : std_logic_vector(31 downto 0);
  --! @}

  --! IP address to be used for transmitting DHCP packets
  signal dhcp_server_ip : std_logic_vector(31 downto 0);

  --! Clock cycle when 1 millisecond is passed
  signal one_ms_tick : std_logic;

  --! Status of the IP module
  signal status_vector_ip : std_logic_vector(12 downto 0);

  --! Status of the DHCP module
  signal status_vector_dhcp : std_logic_vector(6 downto 0);

  --! Print out "At cnt=<cnt>: <txt>"
  function txt_at_cnt (txt : string; cnt : integer) return string is
  begin

    return "At cnt=" & integer'image(cnt) & ": " & txt;

  end function txt_at_cnt;

begin

  --! Instantiate the primary Unit Under Test (UUT): DHCP module
  uut1 : entity xgbe_lib.dhcp_module
  generic map (
    UDP_CRC_EN => UDP_CRC_EN
  )
  port map (
    clk    => clk,
    rst    => rst,
    boot_i => boot,

    -- signals from dhcp requester
    dhcp_rx_ready_o  => udp_tx_ready,
    dhcp_rx_packet_i => udp_tx_packet,
    dhcp_server_ip_o => dhcp_server_ip,

    -- signals to dhcp requester
    dhcp_tx_ready_i  => udp_rx_ready,
    dhcp_tx_packet_o => udp_rx_packet,

    -- interface for recovering mac address from given ip address
    reco_en_o   => reco_en,
    reco_ip_o   => reco_ip,
    reco_done_i => reco_done,
    reco_fail_i => reco_fail,

    my_mac_i     => MY_MAC,
    my_ip_o      => my_ip,
    ip_netmask_o => ip_netmask,

    one_ms_tick_i => one_ms_tick,

    -- status of the DHCP module, see definitions below
    status_vector_o => status_vector_dhcp
  );

  proc_reco : process (clk)
  begin
    if rising_edge(clk) then
      if reco_en = '1' then
        reco_done <= '1';
        reco_fail <= '1';
      else
        reco_done <= '0';
        reco_fail <= '0';
      end if;
    end if;
  end process proc_reco;

  --! Instantiate the secondary Unit Under Test (UUT): IP module
  uut2 : entity xgbe_lib.ip_module
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

    udp_rx_ready_o  => udp_rx_ready,
    udp_rx_packet_i => udp_rx_packet,
    udp_rx_id_i     => udp_rx_id,

    udp_tx_ready_i  => udp_tx_ready,
    udp_tx_packet_o => udp_tx_packet,
    udp_tx_id_o     => udp_tx_id,

    my_ip_i      => my_ip,
    ip_netmask_i => ip_netmask,

    dhcp_server_ip_i => dhcp_server_ip,

    status_vector_o => status_vector_ip
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
      stimulus => mnl_rst,

      eof => eof(3)
    );

    rst <= sim_rst or mnl_rst;

    --! Instantiate counter_matcher to read boot from BOOT_FILE
    inst_boot : entity sim.counter_matcher
    generic map (
      FILENAME     => BOOT_FILE,
      COMMENT_FLAG => COMMENT_FLAG
    )
    port map (
      clk      => clk,
      rst      => '0',
      cnt      => cnt,
      stimulus => boot,

      eof => eof(2)
    );

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

      eof_o => eof(1)
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

    with cnt mod 5 select one_ms_tick <=
      '1' when 0,
      '0' when others;

  end block blk_simulation;

  blk_uvvm : block
    --! Expected RX data and controls
    signal ip_rx_expect : t_avst_packet(
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

      eof_o => eof(0)
    );

    -- We expect 1 error from the reset cutting into the started transmission:
    -- The reader cuts off with eop, but not the dhcp module
    increment_expected_alerts(ERROR, 1);

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
        check_value(ip_rx_packet.valid, ip_rx_expect.valid, ERROR, txt_at_cnt("Checking expected IP valid.",cnt), "", ID_NEVER);
        check_value(ip_rx_packet.sop, ip_rx_expect.sop, ERROR, txt_at_cnt("Checking expected IP sop.",cnt), "", ID_NEVER);
        check_value(ip_rx_packet.eop, ip_rx_expect.eop, ERROR, txt_at_cnt("Checking expected IP eop.",cnt), "", ID_NEVER);
        check_value(ip_rx_packet.error(0), ip_rx_expect.error(0), ERROR, txt_at_cnt("Checking expected IP eop.",cnt), "", ID_NEVER);
        -- only check the expected data when it's relevant: reader will hold data after packet while uut might not
        if ip_rx_expect.valid then
          check_value(ip_rx_packet.data, ip_rx_expect.data, ERROR, txt_at_cnt("Checking expected IP data.",cnt), "", HEX, KEEP_LEADING_0, ID_NEVER);
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
