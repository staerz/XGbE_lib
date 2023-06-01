-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------  <-  80 chars  ->  ----------------------------
--! @file
--! @brief Counter with minimal resources creating a cyclic tick
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--! @brief Creates a cyclic tick from an internal minimal resources counter
--!
--! @details Provides a counter consuming minimum resources.
--! Counts the number of #clk cycles when #en = `1` (and #rst = `0`).
--!
--! Two configurations are possible:
--! - cyclic = true (default):
--!   Repetitively produces 1 tick of #cycle_done = `1` when counter is
--!   reached and restarts counting again and again, endlessly.
--! @image latex counting_cyclic.pdf "Timing diagram of counting when cyclic = true" width=\textwidth
--! - cyclic = false:
--!   Produces #cycle_done = `1` and remains once the counter is reached for
--!   the first time.
--!   Only setting #rst = `1` re-initialises the cycle.
--! @image latex counting_nocyclic.pdf "Timing diagram of counting when cyclic = false" width=\textwidth
--!
--! @section counting_inst_temp Instantiation template
--!
--! @code{.vhdl}
--! [inst_name]: entity misc.counting
--! generic map (
--!   -- number of counts
--!   counter_max_value => [integer := 1000],
--!   -- enable cyclic counting
--!   cyclic            => [boolean := true]
--! )
--! port map (
--!   -- clock
--!   clk               => [in  std_logic],
--!   -- sync reset
--!   rst               => [in  std_logic],
--!   -- optional enable
--!   en                => [in  std_logic = '1'],
--!   -- 1-tick out, counter-reached indication
--!   cycle_done        => [out std_logic]
--! );
--! @endcode
--------------------------------------------------------------------------------

--! @cond
library IEEE;
use IEEE.std_logic_1164.all;
--! @endcond

entity counting is
generic (
--! number of counts
  counter_max_value : integer := 1000;
--! enable cyclic counting
  cyclic            : boolean := true
);
port (
--! clock
  clk               : in  std_logic;
--! sync reset
  rst               : in  std_logic;
--! optional enable
  en                : in  std_logic := '1';
--! 1-tick out, counter-reached indication
  cycle_done        : out std_logic := '0'
);
end entity counting;

--! @name Libraries used for Architecture
--! @{
library IEEE;
library PoC;
--! @}
use IEEE.numeric_std.all;
--! Package from 'PoC' for including log2ceil
use PoC.utils.all;

------------------------------  <-  80 chars  ->  ------------------------------
--! @brief Implementation of the counting
--!
--! @details
--! The #counting makes use of the sign flip at of a counter.
--! That's why the initial value is counter_max_value-2 and it only works for
--! #counter_max_value > 1.
--!
--! Special case implementations:
--! - #counter_max_value = 1: just inverts a std_logic each #clk
--! - #counter_max_value = 0: trivial assignment of not #rst and #en
--------------------------------------------------------------------------------
architecture behavorial of counting is
begin
  --! @cond
  default_counter: if counter_max_value > 1 generate
    -- the length of the counter
    constant cl         : positive := log2ceil(counter_max_value);
    -- the init value of the counter
    constant cnt_init   : signed(cl downto 0) := to_signed(counter_max_value-2, cl+1);
    -- the actual counter
    signal counter      : signed(cl downto 0) := cnt_init;
    -- the calculated signal for output
    signal cycle_done_i : std_logic := '0';
  begin
    --! @endcond
    process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          counter <= cnt_init;
          cycle_done_i <= '0';
        elsif en = '1' then
          if counter(counter'left) = '1' then
            if cyclic then
              -- if cyclic, re-initialise and keep counting
              counter <= cnt_init;
            else
              -- if not cyclic, keep the state (this is a dead end until reset)
              counter <= counter;
            end if;
            cycle_done_i <= '1';
          else
            counter <= counter - 1;
            cycle_done_i <= '0';
          end if;
        else
          counter <= counter;
          -- again make the selection: for cylic, the '1' state must not be repeated
          if cyclic then
            cycle_done_i <= '0';
          else
            cycle_done_i <= cycle_done_i;
          end if;
        end if;
      end if;
    end process;

    cycle_done <= cycle_done_i;
  --! @cond
  end generate;

------------------------------  <-  80 chars  ->  ------------------------------
--  one_counting just inverts a std_logic each clk
--------------------------------------------------------------------------------
  one_counter: if counter_max_value = 1 generate
    signal cnt  : std_logic := '0';
  begin
    --! @endcond
    process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          cnt <= '0';
        else
          if en = '1' then
            cnt <= not cnt;
          else
            cnt <= cnt;
          end if;
        end if;
      end if;
    end process;

    cycle_done <= cnt;
  --! @cond
  end generate;

------------------------------  <-  80 chars  ->  ------------------------------
--  zero_counter is a trivial assignment
--------------------------------------------------------------------------------
  zero_counter: if counter_max_value = 0 generate
    cycle_done <= not rst and en;
  end generate;

--! @endcond
end behavorial;
