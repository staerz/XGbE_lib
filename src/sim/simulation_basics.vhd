-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Basic module for a simple simulation, creating a clock, reset and a counter
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--! @brief Simple simulation environment.
--!
--! @details Generates the basic signals required for any simple simulation.
--!
--! Signals (and generics):
--! - #clk: a clock signal with a clock period of #clk_period.
--!   It starts with a rising edge after #clk_offset.
--! - #rst: an active high synchronous reset, active for the first #reset_duration clock cycles,
--!   thereafter always '0'.
--! - #cnt: a counter starting to count after #rst has settled to '0'.
--!   The first #rst = '0' cycle has #cnt = 0.
--!
--! The entity uses the internal counter behavioral#gblcnt to count the first
--! #reset_duration clock cycles to rise #rst and then starts counting #cnt.
--!
--! @section SB_InstTemplate Instantiation template
--!
--! @code{.vhdl}
--! [sim_basics]: entity sim.simulation_basics
--! generic map (
--!   reset_duration => [natural := 40],
--!   clk_offset     => [time := 0 ns],
--!   clk_period     => [time := 10 ns]
--! )
--! port map (
--!   clk            => [out std_logic],
--!   rst            => [out std_logic],
--!   cnt            => [out natural]
--! );
--! @endcode
-------------------------------------------------------------------------------

--! @cond
library ieee;
use ieee.std_logic_1164.all;
--! @endcond

entity simulation_basics is
generic (
  --! Number of clock cycles that #rst shall be high.
  constant reset_duration : natural := 40;
  --! Offset until the first rising edge of #clk.
  constant clk_offset     : time := 0 ns;
  --! Period of the #clk to be generated.
  constant clk_period     : time := 10 ns
);
port (
  --! Clock.
  signal clk  : out std_logic;
  --! Reset (synchronous with #clk), active for the first #reset_duration clock cycles.
  signal rst  : out std_logic;
  --! Counter starting to count after the initial reset.
  signal cnt  : out natural
);
end simulation_basics;

--! @brief Implementation of simulation_basics.
--!
--! Internal signals #clk_i, #rst_i and #cnt_i are generated and mapped
--! directly to the entity's output ports #clk, #rst and #cnt.
architecture behavioral of simulation_basics is

  --! Internal clock signal, to feed #clk.
  signal clk_i  : std_logic := '0';
  --! Internal reset signal, to feed #rst.
  signal rst_i  : std_logic := '0';
  --! Internal, global counter for reset creation.
  signal gblcnt : natural := 0;
  --! Internal counter, to feed #cnt.
  signal cnt_i  : natural := 0;

begin
  -- concurrent statements and blocks are ignored by doxygen :(

  -- assign internal signals to output ports
  clk <= clk_i;
  rst <= rst_i;
  cnt <= cnt_i;

  --! @brief Process to generate the clock #clk_i
  --! @details This process generates the simulation clock #clk_i.
  --! It first waits for the #clk_offset
  --! and then starts an infinite loop with a rising edge of #clk_i
  --! followed by a falling edge each #clk_period/2.
  proc_clk : process
  begin
    wait for clk_offset;
    loop
      clk_i <= '1';
      gblcnt <= gblcnt + 1;
      wait for clk_period/2;
      clk_i <= '0';
      wait for clk_period/2;
    end loop;
  end process;

  -- reset as long as the internal global counter
  -- is smaller than the configured reset_duration
  rst_i <= '1' when gblcnt < reset_duration else '0';

  --! @brief Process to generate the output #cnt
  --! @details Once #rst_i is released, the #cnt_i is increased by 1 each cycle of #clk_i upon rising edge.
  --! The first non-#rst_i cycle makes the counter #cnt start at 0.
  proc_counting : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        cnt_i <= 0;
      else
        cnt_i <= cnt_i + 1;
      end if;
    end if;
  end process;
end behavioral;
