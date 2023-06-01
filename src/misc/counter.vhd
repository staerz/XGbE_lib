-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Outputs a std_logic_vector counter
--! @author Philipp Horn <philipp.horn@cern.ch>
--! @author Nick Fritzsche <nick.fritzsche@cern.ch>
-------------------------------------------------------------------------------
--! @details Provide a counter up to #counter_max_value that is
--! - increased upon #inc,
--! - decreased upon #dec,
--! - reset to #counter_rst_value upon #rst.
--!
--! The counter is over- and underflow protected. Reaching the limits is
--! indicated by #full and #empty respectively. If #cyclic is set and the
--! counter reaches a limit, it continues counting, starting with zero for high
--! #inc and #counter_max_value for high #dec. By setting #invert, the
--! indicators #full and #empty become active low. The registered output is
--! synchroneous to #clk and in-/decreases by one per clock cycle.
-------------------------------------------------------------------------------
--
-- Instantiation template:
--
--  [inst_name]: entity misc.counter
--  generic map (
--    --! maximum value of counter
--    counter_max_value => [positive := 1000],
--    --! value assigned upon #rst
--    counter_rst_value => [natural  := 0],
--    --! #full and #empty active high if set to true, active low otherwise
--    invert            => [boolean  := false],
--    --! if #full(#empty) is high and cyclic is set to true, #count is put back
--    --! to zero(#counter_max_value) on an increase(decrease)
--    cyclic            => [boolean  := true]
--  )
--  port map (
--    clk   => [in  std_logic],  --! clock
--    rst   => [in  std_logic],  --! reset: sets the counter to zero
--    inc   => [in  std_logic],  --! increase: counts up
--    dec   => [in  std_logic],  --! decrease: counts down
--    empty => [out std_logic],  --! indicates if #count is zero
--    full  => [out std_logic],  --! indicates if #count is on its upper limit
--    count => [out std_logic_vector(log2ceil(counter_max_value+1)-1 downto 0)] --! count-vector
--  );
--
-------------------------------------------------------------------------------
--! @cond
library IEEE;
use IEEE.std_logic_1164.all;
-- for the usage of
--   log2ceil (calculate bits required to encrypt arg binarily)
--   to_sl (boolean to std_logic)
library PoC;
use PoC.utils.all;
--! @endcond

entity counter is
  generic(
    --! maximum value of counter
    counter_max_value : positive := 1000;
    --! value assigned upon #rst. Must be less than or equal to #counter_max_value
    counter_rst_value : natural  := 0;
    --! #full and #empty active high if set to true, active low otherwise
    invert            : boolean  := false;
    --! if #full(#empty) is high and cyclic is set to true, #count is put back
    --! to zero(#counter_max_value) on an increase(decrease)
    cyclic            : boolean  := true
  );
  port(
    clk   : in  std_logic;  --! clock
    rst   : in  std_logic;  --! reset: sets the counter to zero
    inc   : in  std_logic;  --! increase: counts up
    dec   : in  std_logic;  --! decrease: counts down
    empty : out std_logic;  --! indicates if #count is zero
    full  : out std_logic;  --! indicates if #count is on its upper limit
    count : out std_logic_vector(log2ceil(counter_max_value+1)-1 downto 0)  --! count-vector
  );
end counter;

--! @cond
library IEEE;
use IEEE.numeric_std.all;
--! @endcond

--! Implementation of counter
architecture behavioral of counter is
  --! actual internal counter (as unsigned for ease of use)
  signal count_i    : unsigned(log2ceil(counter_max_value+1)-1 downto 0);
  --! internal #empty
  signal empty_i    : std_logic;
  --! internal #full
  signal full_i     : std_logic;

begin

  -- throw warning if #counter_rst_value is not in range [0, #counter_max_value]
  assert (counter_rst_value <= counter_max_value) report
  "counter_rst_value must be less than or equal to counter_max_value. counter_rst_value is "
  & natural'image(counter_rst_value) & ". counter_max_value is "
  & positive'image(counter_max_value) &"." severity warning;

  -- output assignment
  count <= std_logic_vector(count_i);

  -- assign #empty_i to #empty and #full_i to #full under consideration of #invert.
  -- xor is used for controlled inverting.
  empty <= empty_i xor to_sl(invert);
  full  <= full_i xor to_sl(invert);

  -- compare whole vector for full and empty signal
  -- other possibility: introduce two additional counter (count+1 and count-1)
  --   check over/underflow with these counters(log2ceil(counter_max_value)+2)
  --     -> only one bit is compared
  --     -> but: takes two registers and one combinational ALUT
  --     more than current design
  empty_i <= 'X' when Is_X(count_i) else
             '1' when count_i = 0 else
             '0';
  full_i  <= 'X' when Is_X(count_i) else
             '1' when count_i = counter_max_value else
             '0';

  --! @details
  --! Update #count_i upon clock:
  --! - set to #counter_rst_value for high #rst
  --! - increase by one for high #inc, low #dec and #full_i
  --! - decrease by one for high #dec, low #inc and #empty_i
  --! - if #cyclic is true, set zero for low #dec, high #inc and #full_i
  --! - if #cyclic is true, set to #counter_max_value for low #inc, high #dec and #empty_i
  --! - no change otherwise
  proc_cnt : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        count_i <= to_unsigned(counter_rst_value, log2ceil(counter_max_value+1));
      elsif inc = '1' and dec = '0' and full_i = '0' then
        count_i <= count_i + 1;
      elsif dec = '1' and inc = '0' and empty_i = '0' then
        count_i <= count_i - 1;
      elsif cyclic = true and inc = '1' and dec = '0' and full_i = '1' then
        count_i <= (others => '0');
      elsif cyclic = true and dec = '1' and inc = '0' and empty_i = '1' then
        count_i <= to_unsigned(counter_max_value, log2ceil(counter_max_value+1));
      else
        count_i <= count_i;
      end if;
    end if;
  end process;

end architecture behavioral;
