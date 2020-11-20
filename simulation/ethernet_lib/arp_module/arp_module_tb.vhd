-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Testbench for arp_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details Generates the environment for the arp_module.vhd.
--! Data packets are read from #ARP_RXD_FILE and passed to the arp_module.
--! #MY_MAC and #MY_IP must be configured in accordance with data in that file.
--! The module's output is logged to #ARP_TXD_FILE.
-------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.std_logic_1164.all;
--! @endcond

--! Testbench for arp_module.vhd
entity arp_module_tb is
  generic (
    --! File containing the ARP RX data
    ARP_RXD_FILE      : string := "sim_data_files/ARP_request_in.dat";
    --! File containing counters on which the RX interface is not ready
    ARP_RDY_FILE      : string := "sim_data_files/ARP_rx_ready_in.dat";
    --! File to write out the response of the module
    ARP_TXD_FILE      : string := "sim_data_files/ARP_response_out.dat";

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
end arp_module_tb;

--! @cond
library ethernet_lib;
library misc;
library sim;
--! @endcond

--! Implementation of arp_module_tb
architecture tb of arp_module_tb is

  --! Clock
  signal clk              : std_logic;
  --! reset, sync with #clk
  signal rst              : std_logic;

  --! @name Avalon-ST (ARP with Ethernet header) to module (read from file)
  --! @{

  --! TX ready
  signal arp_tx_ready     : std_logic;
  --! TX data
  signal arp_tx_data      : std_logic_vector(63 downto 0);
  --! TX controls
  signal arp_tx_ctrl      : std_logic_vector(6 downto 0);

  --! @}

  --! @name Avalon-ST (ARP) from module (written to file)
  --! @{

  --! RX ready
  signal arp_rx_ready     : std_logic;
  --! RX data
  signal arp_rx_data      : std_logic_vector(63 downto 0);
  --! RX controls
  signal arp_rx_ctrl      : std_logic_vector(6 downto 0);

  --! @}

  --! @name Interface for recovering MAC address from given IP address
  --! @{

  --! Recovery enable
  signal reco_en          : std_logic;
  --! IP address to recover
  signal reco_ip          : std_logic_vector(31 downto 0);
  --! Recovered MAX address
  signal reco_mac         : std_logic_vector(47 downto 0);
  --! recovery success: 1 = found, 0 = not found (time out)
  signal reco_mac_done    : std_logic;
  --! @}

  --! Clock cycle when 1 millisecond is passed
  signal one_ms_tick      : std_logic;

  --! Status of the module
  signal status_vector    : std_logic_vector(4 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity ethernet_lib.arp_module
  generic map (
    ARP_REQUEST_CYCLE => ARP_REQUEST_CYCLE,
    ARP_TIMEOUT       => ARP_TIMEOUT,
    ARP_TABLE_DEPTH   => ARP_TABLE_DEPTH
  )
  port map (
    clk             => clk,
    rst             => rst,

    -- signals from arp requester
    arp_rx_ready    => arp_tx_ready,
    arp_rx_data     => arp_tx_data,
    arp_rx_ctrl     => arp_tx_ctrl,

    -- signals to arp requester
    arp_tx_ready    => arp_rx_ready,
    arp_tx_data     => arp_rx_data,
    arp_tx_ctrl     => arp_rx_ctrl,

    -- interface for recovering mac address from given ip address
    reco_en         => reco_en,
    reco_ip         => reco_ip,
    -- response (next clk if directly found, later if arp request needs to be sent)
    reco_mac        => reco_mac,
    reco_mac_done   => reco_mac_done,

    my_mac          => my_mac,
    my_ip           => my_ip,

    one_ms_tick     => one_ms_tick,

    -- status of the ARP module, see definitions below
    status_vector   => status_vector
  );

  -- Simulation part
  -- generating stimuli based on counter
  blk_simulation : block
    signal counter        : integer := 0;
    signal sim_rst        : std_logic;
    signal mnl_rst        : std_logic;
  begin

    --! Instantiate simulation_basics to start
    inst_sim_basics : entity sim.simulation_basics
    generic map (
      CLK_OFFSET    => 0 ns,
      CLK_PERIOD    => 6.4 ns
    )
    port map (
      clk => clk,
      rst => sim_rst,
      cnt => counter
    );

    with counter select mnl_rst <=
      '1' when 9 to 12,
      '0' when others;

    rst <= sim_rst or mnl_rst;

    blk_arp_tx : block
    begin

      --! Instantiate av_st_sender to read arp_tx from ARP_RXD_FILE
      inst_arp_tx : entity sim.av_st_sender
      generic map (
        FILENAME      => ARP_RXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG,
        COUNTER_FLAG  => COUNTER_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        cnt       => counter,

        -- Avalon-ST to outside world
        tx_ready  => arp_tx_ready,
        tx_data   => arp_tx_data,
        tx_ctrl   => arp_tx_ctrl
      );
    end block;

    blk_arp_log : block
      signal wren           : std_logic;
      signal arp_rx_ready_n : std_logic;
    begin

      --! Instantiate counter_matcher to read arp_rx_ready_n from ARP_RDY_FILE
      inst_arp_rx_ready : entity sim.counter_matcher
      generic map (
        FILENAME      => ARP_RDY_FILE,
        COMMENT_FLAG  => COMMENT_FLAG
      )
      port map (
        clk         => clk,
        rst         => rst,
        counter     => counter,
        stimulus    => arp_rx_ready_n
      );

      arp_rx_ready <= not arp_rx_ready_n;

      -- logging block for RX interface
      wren <= arp_rx_ctrl(6) and arp_rx_ready;

      --! Instantiate file_writer_hex to write arp_rx_data
      inst_arp_log : entity sim.file_writer_hex
      generic map (
        FILENAME      => ARP_TXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG,
        BITSPERWORD   => 16,
        WORDSPERLINE  => 4
      )
      port map (
        clk       => clk,
        rst       => rst,
        wren      => wren,

        empty     => arp_rx_ctrl(2 downto 0),
        eop       => arp_rx_ctrl(4),
        err       => arp_rx_ctrl(3),

        din       => arp_rx_data
      );

    end block;

    with counter mod 5 select one_ms_tick <=
      '1' when 0,
      '0' when others;

    with counter select reco_ip <=
      x"C0_A8_00_23" when 100,
      (others => '0') when others;

    with counter select reco_en <=
      '1' when 100,
      '0' when others;

  end block;

end tb;
