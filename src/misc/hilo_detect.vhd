--------------------------------------------------------------------------------
-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Detects a signal transition from high to low in consecutive clock cycles
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--! @author Kade Gigliotti <kade.gigliotti@cern.ch> (commenting)
-------------------------------------------------------------------------------
--! @brief Instantiation of hilo_detect according to generics.
--! @details Provides a simplistic logic for detecting a signal change in
--! consecutive clock cycles, depending on generic #lohi.
--! - If #lohi = false (default):
--!   #sig_out = '1' when #sig_in changes from '1' to '0' else #sig_out = '0'
--!   @image latex hilo_detect_lohi_false.pdf "Timing diagram of hilo_detect when lohi = false (default)" height=4.8\wdline
--! - If #lohi = true:
--!   #sig_out = '1' when #sig_in changes from '0' to '1' else #sig_out = '0'
--!   @image latex hilo_detect_lohi_true.pdf "Timing diagram of hilo_detect when lohi = true" height=4.8\wdline
--!
--! @section hilo_detect_inst_temp Instantiation template
--!
--! @code{.vhdl}
--! [inst_name]: entity misc.hilo_detect
--! generic map (
--!   lohi    => [boolean := false] -- Switch transition detection from high->low to low->high
--! )
--! port map (
--!   clk     => [in  std_logic], -- Clock
--!   sig_in  => [in  std_logic], -- Input signal
--!   sig_out => [out std_logic]  -- Output signal
--! );
--! @endcode
-------------------------------------------------------------------------------
--! @cond
library IEEE;
use IEEE.std_logic_1164.all;
--! @endcond

entity hilo_detect is
generic (
  --! Invert the detection logic from a high-to-low to a low-to-high transition of the input signal #sig_in.
  lohi    : boolean := false
);
port (
  --! Clock.
  clk     : in  std_logic;
  --! Input signal on which the transition is to be detected.
  sig_in  : in  std_logic;
  --! Transition detected output, high for 1 clock cycle only.
  sig_out : out std_logic
);
end hilo_detect;

--! Implementation of hilo_detect
architecture behavioral of hilo_detect is
--! Registered input signal
signal reg : std_logic := '0';

begin
  --! @details
  --! On the rising edge of #clk, #reg is set to #sig_in.
  --! #sig_out is set from #reg and #sig_in in accordance with #lohi.
  sig_in_reg_proc : process(clk)
  begin
    if rising_edge(clk) then
      reg <= sig_in;
    end if;
  end process;

  -- If lohi = true:
  -- sig_out = '1' when reg = '0' and sig_in = '1'
  inverted: if lohi generate
  begin
    sig_out <= not reg and sig_in;
  end generate;

  -- If lohi = false:
  -- sig_out = '1' when sig_in = '0' and reg = '1'
  not_inverted: if not lohi generate
  begin
    sig_out <= not sig_in and reg;
  end generate;

end behavioral;

