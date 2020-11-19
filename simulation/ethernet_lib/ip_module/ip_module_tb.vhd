-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Testbench for ip_module.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details Generates the environment for the ip_module.vhd.
--!
--! RESET_DURATION is set to 5
-------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.std_logic_1164.all;
--! @endcond

--! Testbench for ip_module.vhd
entity ip_module_tb is
  generic (
    --! File containing the IP RX data
    IP_RXD_FILE       : string := "sim_data_files/IP_data_in.dat";
    --! File containing counters on which the IP RX interface is not ready
    IP_RDY_FILE       : string := "sim_data_files/IP_rx_ready_in.dat";
    --! File to write out the IP response of the module
    IP_TXD_FILE       : string := "sim_data_files/IP_data_out.dat";
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
    EOF_CHECK_EN      : std_logic := '1';
    --! Post-UDP-module UDP CRC calculation
    UDP_CRC_EN        : boolean   := true;
    --! Enable IP address filtering
    IP_FILTER_EN      : std_logic := '1';

    --! Depth of table (number of stored connections)
    ID_TABLE_DEPTH    : integer range 1 to 1024 := 5;
    --! The minimal number of clock cycles between two outgoing frames.
    PAUSE_LENGTH      : integer range 0 to 1024 := 2
  );
end ip_module_tb;

--! @cond
library IEEE;
  use IEEE.numeric_std.all;
library ethernet_lib;
library sim;
library misc;
--! @endcond

--! Implementation of ip_module_tb
architecture tb of ip_module_tb is

  --! Clock
  signal clk            : std_logic;
  --! Reset, sync with #clk
  signal rst            : std_logic;

  --! @name Avalon-ST (IP) to module (read from file)
  --! @{

  --! TX ready
  signal ip_tx_ready    : std_logic;
  --! TX data
  signal ip_tx_data     : std_logic_vector(63 downto 0);
  --! TX controls
  signal ip_tx_ctrl     : std_logic_vector(6 downto 0);

  --! @}

  --! @name Avalon-ST (IP) from module (written to file)
  --! @{

  --! RX ready
  signal ip_rx_ready    : std_logic;
  --! RX data
  signal ip_rx_data     : std_logic_vector(63 downto 0);
  --! RX controls
  signal ip_rx_ctrl     : std_logic_vector(6 downto 0);

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

  --! IP address
  signal my_ip          : std_logic_vector(31 downto 0) := x"c0_a8_00_1e";
  --! Net mask
  signal ip_netmask     : std_logic_vector(31 downto 0) := x"ff_ff_ff_00";
  --! @}

  --! Status of the module
  signal status_vector  : std_logic_vector(12 downto 0);

begin

  --! Instantiate the Unit Under Test (UUT)
  uut : entity ethernet_lib.ip_module
  generic map (
    EOF_CHECK_EN    => EOF_CHECK_EN,
    UDP_CRC_EN      => UDP_CRC_EN,
    IP_FILTER_EN    => IP_FILTER_EN,
    ID_TABLE_DEPTH  => ID_TABLE_DEPTH,
    PAUSE_LENGTH    => PAUSE_LENGTH
  )
  port map (
    clk             => clk,
    rst             => rst,

    ip_rx_ready     => ip_tx_ready,
    ip_rx_data      => ip_tx_data,
    ip_rx_ctrl      => ip_tx_ctrl,

    ip_tx_ready     => ip_rx_ready,
    ip_tx_data      => ip_rx_data,
    ip_tx_ctrl      => ip_rx_ctrl,

    udp_rx_ready    => udp_tx_ready,
    udp_rx_data     => udp_tx_data,
    udp_rx_ctrl     => udp_tx_ctrl,
    udp_rx_id       => udp_tx_id,

    udp_tx_ready    => udp_rx_ready,
    udp_tx_data     => udp_rx_data,
    udp_tx_ctrl     => udp_rx_ctrl,
    udp_tx_id       => udp_rx_id,

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

    blk_ip_tx : block
    begin
      --! Instantiate av_st_sender to read ip_tx from IP_RXD_FILE
      inst_ip_tx : entity sim.av_st_sender
      generic map (
        FILENAME      => IP_RXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG,
        COUNTER_FLAG  => COUNTER_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        cnt       => counter,

        -- Avalon-ST to outside world
        tx_ready  => ip_tx_ready,
        tx_data   => ip_tx_data,
        tx_ctrl   => ip_tx_ctrl
      );

    end block;

    blk_ip_log : block
      --! @cond
      signal wren          : std_logic := '0';
      signal ip_rx_ready_n : std_logic := '0';
      --! @endcond
    begin

      --! Instantiate counter_matcher to generate ip_rx_ready_n
      inst_ip_rx_ready : entity sim.counter_matcher
      generic map (
        FILENAME      => IP_RDY_FILE,
        COMMENT_FLAG  => COMMENT_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        counter   => counter,
        stimulus  => ip_rx_ready_n
      );

      ip_rx_ready <= not ip_rx_ready_n;

      -- logging block for TX interface
      wren <= ip_rx_ctrl(6) and ip_rx_ready;

      --! Instantiate file_writer_hex to write ip_tx_data
      inst_ip_log : entity sim.file_writer_hex
      generic map (
        FILENAME      => IP_TXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG,
        BITSPERWORD   => 16,
        WORDSPERLINE  => 4
      )
      port map (
        clk       => clk,
        rst       => rst,
        wren      => wren,

        empty     => ip_rx_ctrl(2 downto 0),
        eop       => ip_rx_ctrl(4),
        err       => ip_rx_ctrl(3),

        din       => ip_rx_data
      );

    end block;

    blk_udp_tx : block
      signal udp_tx_id_i : unsigned(15 downto 0);
    begin
      --! Instantiate av_st_sender to read udp_tx from UDP_RXD_FILE
      inst_udp_tx : entity sim.av_st_sender
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

    blk_udp_log : block
      --! @cond
      signal wren           : std_logic := '0';
      signal udp_rx_ready_n : std_logic := '0';
      --! @endcond
    begin

      --! Instantiate counter_matcher to generate ip_rx_ready_n
      inst_udp_rx_ready : entity sim.counter_matcher
      generic map (
        FILENAME      => UDP_RDY_FILE,
        COMMENT_FLAG  => COMMENT_FLAG
      )
      port map (
        clk       => clk,
        rst       => rst,
        counter   => counter,
        stimulus  => udp_rx_ready_n
      );

      udp_rx_ready <= not udp_rx_ready_n;

      -- logging block for TX interface
      wren <= udp_rx_ctrl(6) and udp_rx_ready;

      --! Instantiate file_writer_hex to write ip_tx_data
      inst_upd_log : entity sim.file_writer_hex
      generic map (
        FILENAME      => UDP_TXD_FILE,
        COMMENT_FLAG  => COMMENT_FLAG,
        BITSPERWORD   => 16,
        WORDSPERLINE  => 4
      )
      port map (
        clk       => clk,
        rst       => rst,
        wren      => wren,

        empty     => udp_rx_ctrl(2 downto 0),
        eop       => udp_rx_ctrl(4),
        err       => udp_rx_ctrl(3),

        din       => udp_rx_data
      );

    end block;

  end block;

end tb;
