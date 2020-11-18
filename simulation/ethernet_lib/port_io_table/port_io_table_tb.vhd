-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Testbench for port_io_table.vhd
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details Generates the environment for the port_io_table.vhd.
--! Different pairs of addresses are first written to the port_io_table.
--! Then some requests are sent to see the response of the port_io_table.
--! The example is written as an ARP table: MAC and IP addresses are used.
-------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.std_logic_1164.all;
--! @endcond

--! Testbench for port_io_table.vhd
entity port_io_table_tb is
  generic (
    --! Width of the port to be associated
    PIN_WIDTH    : integer range 1 to 64   := 32;
    --! Width of the associated port
    POUT_WIDTH   : integer range 1 to 64   := 48;
    --! Depth of the table
    TABLE_DEPTH  : integer range 1 to 1024 := 3
  );
end port_io_table_tb;

--! @cond
library ethernet_lib;
library sim;
--! @endcond

--! Implementation of port_io_table_tb
architecture tb of port_io_table_tb is
  --! Clock
  signal clk        : std_logic;
  --! Reset, sync with #clk
  signal rst        : std_logic;

  --! @name Discovery interface for writing pair of associated addresses/ports
  --! @{

  --! Discovery write enable
  signal disco_wren : std_logic;
  --! Discovery input port
  signal disco_pin  : std_logic_vector(PIN_WIDTH-1 downto 0);
  --! Discovery output port
  signal disco_pout : std_logic_vector(POUT_WIDTH-1 downto 0);
  --! @}

  --! @name Recovery interface for reading pair of associated addresses/ports
  --! @{

  --! Recovery read enable
  signal reco_en    : std_logic;
  --! Recovery input port
  signal reco_pin   : std_logic_vector(PIN_WIDTH-1 downto 0);
  --! Recovery output port (response next clk cycle)
  signal reco_pout  : std_logic_vector(POUT_WIDTH-1 downto 0);
  --! Recovery success indicator
  signal reco_found : std_logic;
  --! @}

  --! Status of the module
  signal status_vector    : std_logic_vector(1 downto 0);

  --! Counter for simulation
  signal counter    : integer := 0;

begin
  --! Instantiate simulation_basics to start
  sim_basics : entity sim.simulation_basics
  port map (
    clk => clk,
    rst => rst,
    cnt => counter
  );

  --! Instantiate the Unit Under Test (UUT)
  uut : entity ethernet_lib.port_io_table
  generic map (
    PIN_WIDTH     => PIN_WIDTH,
    POUT_WIDTH    => POUT_WIDTH,
    TABLE_DEPTH   => TABLE_DEPTH
  )
  port map (
    clk           => clk,
    rst           => rst,

    -- interface for writing new discovered MAC and IP to ARP table
    disco_wren    => disco_wren,
    disco_pin     => disco_pin,
    disco_pout    => disco_pout,

    -- interface for recovered MAC address from given IP address
    reco_en       => reco_en,
    reco_pin      => reco_pin,
    -- response (next clk)
    reco_found    => reco_found,
    reco_pout     => reco_pout,

    -- status of the ARP table, see definitions below
    status_vector => status_vector
  );

--  generating stimuli based on counter

--  generate 4 ARP entries in a table with 3 spaces:
--  last one to overwrite first
  with counter select disco_wren <=
    '1' when 4 | 8 | 16 | 40,
    '0' when others;

  with counter select disco_pin <=
    x"11_22_ab_01" when 4,
    x"22_33_cd_02" when 8,
    x"33_44_ef_03" when 16,
    x"44_55_01_04" when 40,
    (others => '0') when others;

  with counter select disco_pout <=
    x"11_22_33_44_55_66" when 4,
    x"aa_bb_cc_dd_ee_ff" when 8,
    x"ab_cd_ef_ab_cd_ef" when 16,
    x"12_34_56_78_90_ab" when 40,
    (others => '0') when others;

--  generate 4 ARP recover requests
  with counter select reco_en <=
    '1' when 20 | 25 | 30 | 45 | 50 | 55,
    '1' when 60, -- reco for not known address
    '0' when others;

  with counter select reco_pin <=
    x"11_22_ab_01" when 20,
    x"22_33_cd_02" when 25,
    x"33_44_ef_03" when 30,
    x"44_55_01_04" when 45,
    x"11_22_ab_01" when 50, -- first again: should not be found
    x"22_33_cd_02" when 55, -- second again: should be found
    x"ff_aa_bb_cc" when 60, -- unknown address: should not be found
    (others => '0') when others;

end tb;
