-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Testbench for ethernet_to_udp_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details Generates the environment for the ethernet_to_udp_module.vhd.
--!
--! RESET_DURATION is set to 5
-------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.std_logic_1164.all;
--! @endcond

--! Testbench for ethernet_to_udp_module.vhd
entity ethernet_to_udp_module_tb is
  generic (
    --! File containing the ETH RX data
    ETH_RXD_FILE      : string := "sim_data_files/ETH_data_in.dat";
    --! File containing counters on which the ETH RX interface is not ready
    ETH_RDY_FILE      : string := "sim_data_files/ETH_rx_ready_in.dat";
    --! File to write out the ETH response of the module
    ETH_TXD_FILE      : string := "sim_data_files/ETH_data_out.dat";
    --! File containing the UDP RX data
    UDP_RXD_FILE      : string := "sim_data_files/UDP_data_in.dat";
    --! File containing counters on which the UDP RX interface is not ready
    UDP_RDY_FILE      : string := "sim_data_files/UDP_rx_ready_in.dat";
    --! File to write out the UDP response of the module
    UDP_TXD_FILE      : string := "sim_data_files/UDP_data_out.dat";
    --! File containing counters on which a manual reset is carried out
    MNL_RST_FILE      : string := "sim_data_files/MNL_RST_in.dat";

    --! Flag to use to indicate comments
    COMMENT_FLAG      : character := '%';
    --! Flat to use to indicate counters
    COUNTER_FLAG      : character := '@';

    --! End of frame check
    EOF_CHECK_EN      : std_logic                := '1';
    --! The minimal number of clock cycles between two outgoing frames.
    PAUSE_LENGTH      : integer range 0 to 1024  := 2;
    --! Timeout to reconstruct MAC from IP in milliseconds
    MAC_TIMEOUT       : integer range 1 to 10000 := 1000;

    --! Post-UDP-module UDP CRC calculation
    UDP_CRC_EN        : boolean                 := true;
    --! Enable IP address filtering
    IP_FILTER_EN      : std_logic               := '1';
    --! Depth of table (number of stored connections)
    ID_TABLE_DEPTH    : integer range 1 to 1024 := 5;
    --! The minimal number of clock cycles between two outgoing frames.

    --! Timeout in milliseconds
    ARP_TIMEOUT       : integer range 2 to 1000 := 10;
    --! Cycle time in milliseconds for APR requests (when repetitions are needed)
    ARP_REQUEST_CYCLE : integer range 1 to 1000 := 2;
    --! Depth of ARP table (number of stored connections)
    ARP_TABLE_DEPTH   : integer range 1 to 1024 := 4;

    --! Duration of a millisecond (ms) in clock cycles of clk
    ONE_MILLISECOND   : integer := 15
  );
end ethernet_to_udp_module_tb;

--! @cond
library IEEE;
  use IEEE.numeric_std.all;
library ethernet_lib;
library sim;
library misc;
--! @endcond

--! Implementation of ethernet_to_udp_module_tb
architecture tb of ethernet_to_udp_module_tb is

  --! Clock
  signal clk            : std_logic;
  --! Reset, sync with #clk
  signal rst            : std_logic;

  --! @name Avalon-ST (ETH) to module (read from file)
  --! @{

  --! TX ready
  signal eth_tx_ready   : std_logic;
  --! TX data
  signal eth_tx_data    : std_logic_vector(63 downto 0);
  --! TX controls
  signal eth_tx_ctrl    : std_logic_vector(6 downto 0);

  --! @}

  --! @name Avalon-ST (ETH) from module (written to file)
  --! @{

  --! RX ready
  signal eth_rx_ready   : std_logic;
  --! RX data
  signal eth_rx_data    : std_logic_vector(63 downto 0);
  --! RX controls
  signal eth_rx_ctrl    : std_logic_vector(6 downto 0);

  --! @}

  --! @name Avalon-ST (UDP) to module (read from file)
  --! @{

  --! TX ready
  signal udp_tx_ready   : std_logic;
  --! TX data
  signal udp_tx_data    : std_logic_vector(63 downto 0);
  --! TX controls
  signal udp_tx_ctrl    : std_logic_vector(6 downto 0);
  --! TX identifier
  signal udp_tx_id      : std_logic_vector(15 downto 0);

  --! @}

  --! @name Avalon-ST (UDP) from module (written to file)
  --! @{

  --! RX ready
  signal udp_rx_ready   : std_logic;
  --! RX data
  signal udp_rx_data    : std_logic_vector(63 downto 0);
  --! RX controls
  signal udp_rx_ctrl    : std_logic_vector(6 downto 0);
  --! RX identifier
  signal udp_rx_id      : std_logic_vector(15 downto 0);

  --! @}

  --! @name Configuration of the module
  --! @{

  --! MAC address
  signal my_mac         : std_logic_vector(47 downto 0) := x"00_22_8f_02_41_ee";
  --! IP address
  signal my_ip          : std_logic_vector(31 downto 0) := x"c0_a8_00_1e";
  --! Net mask
  signal ip_netmask     : std_logic_vector(31 downto 0) := x"ff_ff_00_00";
  --! @}

  --! Status of the module
  signal status_vector  : std_logic_vector(26 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity ethernet_lib.ethernet_to_udp_module
  generic map (
    EOF_CHECK_EN      => EOF_CHECK_EN,
    PAUSE_LENGTH      => PAUSE_LENGTH,
    MAC_TIMEOUT       => MAC_TIMEOUT,
    UDP_CRC_EN        => UDP_CRC_EN,
    IP_FILTER_EN      => IP_FILTER_EN,
    ID_TABLE_DEPTH    => ID_TABLE_DEPTH,
    ARP_REQUEST_CYCLE => ARP_REQUEST_CYCLE,
    ARP_TIMEOUT       => ARP_TIMEOUT,
    ARP_TABLE_DEPTH   => ARP_TABLE_DEPTH,
    ONE_MILLISECOND   => ONE_MILLISECOND
  )
  port map (
    clk             => clk,
    rst             => rst,

    eth_rx_ready    => eth_tx_ready,
    eth_rx_data     => eth_tx_data,
    eth_rx_ctrl     => eth_tx_ctrl,

    eth_tx_ready    => eth_rx_ready,
    eth_tx_data     => eth_rx_data,
    eth_tx_ctrl     => eth_rx_ctrl,

    udp_rx_ready    => udp_tx_ready,
    udp_rx_data     => udp_tx_data,
    udp_rx_ctrl     => udp_tx_ctrl,
    udp_rx_id       => udp_tx_id,

    udp_tx_ready    => udp_rx_ready,
    udp_tx_data     => udp_rx_data,
    udp_tx_ctrl     => udp_rx_ctrl,
    udp_tx_id       => udp_rx_id,

    my_mac          => my_mac,
    my_ip           => my_ip,
    ip_netmask      => ip_netmask,

    status_vector   => status_vector
  );

  -- Simulation part
  -- generating stimuli based on counter
  blk_simulation : block
    --! @cond
    signal counter    : integer := 0;
    signal sim_rst    : std_logic;
    signal mnl_rst    : std_logic;
    --! @endcond

  begin
    --! Instantiate simulation_basics to start
    inst_sim_basics : entity sim.simulation_basics
    generic map (
      RESET_DURATION  => 5,
      CLK_OFFSET      => 0 ns,
      CLK_PERIOD      => 6.4 ns
    )
    port map (
      clk => clk,
      rst => sim_rst,
      cnt => counter
    );

    --! Instantiate counter_matcher to read mnl_rst from MNL_RST_FILE
    inst_mnl_rst : entity sim.counter_matcher
    generic map (
      FILENAME      => MNL_RST_FILE,
      COMMENT_FLAG  => COMMENT_FLAG
    )
    port map (
      clk       => clk,
      rst       => '0',
      counter   => counter,
      stimulus  => mnl_rst
    );

    rst <= sim_rst or mnl_rst;

    blk_tx : block
      signal udp_tx_id_i : unsigned(15 downto 0);
    begin

      --! Instantiate av_st_sender to read eth_tx from ETH_RXD_FILE
      inst_eth_tx : entity sim.av_st_sender
      generic map (
        FILENAME      => ETH_RXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG,
        COUNTER_FLAG  => COUNTER_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        cnt       => counter,

        -- Avalon-ST to outside world
        tx_ready  => eth_tx_ready,
        tx_data   => eth_tx_data,
        tx_ctrl   => eth_tx_ctrl
      );

      --! Instantiate av_st_sender to read udp_tx from UDP_RXD_FILE
      inst_arp_tx : entity sim.av_st_sender
      generic map (
        FILENAME      => UDP_RXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG,
        COUNTER_FLAG  => COUNTER_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        cnt       => counter,

        -- Avalon-ST to outside world
        tx_ready  => udp_tx_ready,
        tx_data   => udp_tx_data,
        tx_ctrl   => udp_tx_ctrl
      );

      --! Generate an ID for each new UDP packet
      proc_gen_id_counter : process (clk) is
      begin
        if rising_edge(clk) then
          if rst = '1' then
            udp_tx_id_i <= to_unsigned(1, udp_tx_id_i'length);
          elsif udp_tx_ctrl(4) = '1' and udp_tx_ready = '1' then
            -- let simulation generate one id which will not be generated by ip module
            -- itself in order to test the proper reaction of a non-existing id
            if udp_tx_id_i = to_unsigned(id_table_depth+1, 16) then
              udp_tx_id_i <= to_unsigned(1, udp_tx_id_i'length);
            else
              udp_tx_id_i <= udp_tx_id_i + 1;
            end if;
          else
            udp_tx_id_i <= udp_tx_id_i;
          end if;
        end if;
      end process;

      udp_tx_id <=
        std_logic_vector(udp_tx_id_i) when udp_tx_ctrl(6) = '1' else
        (others => '0');
    end block;

    blk_log : block
    begin

      --! Instantiate av_st_receiver to write eth_rx to ETH_TXD_FILE
      inst_eth_rx : entity ethernet_lib.av_st_receiver
      generic map (
        READY_FILE    => ETH_RDY_FILE,
        DATA_FILE     => ETH_TXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        cnt       => counter,

        -- Avalon-ST from outside world
        rx_ready  => eth_rx_ready,
        rx_data   => eth_rx_data,
        rx_ctrl   => eth_rx_ctrl
      );

      --! Instantiate av_st_receiver to write udp_rx to UDP_TXD_FILE
      inst_arp_rx : entity ethernet_lib.av_st_receiver
      generic map (
        READY_FILE    => UDP_RDY_FILE,
        DATA_FILE     => UDP_TXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        cnt       => counter,

        -- Avalon-ST from outside world
        rx_ready  => udp_rx_ready,
        rx_data   => udp_rx_data,
        rx_ctrl   => udp_rx_ctrl
      );

    end block;

  end block;

end tb;
