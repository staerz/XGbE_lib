-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;

------------------------------<-    80 chars    ->------------------------------
--! @file
--! @brief Delays a signal of any type in a given clock domain (VHDL-2008).
--! @details Delays a signal of any type in a given clock domain (VHDL-2008).
--! It is a type-unspecific shift register!
--!
--! Two different architectures are provided:
--! - behavioral that prevents moving registers into memory-based altshift_taps
--! - altshift_taps that allows moving registers into memory-based altshift_taps
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--! @author Xin Cui <xin.cui@cern.ch>
--! @bug Doxygen doesn't (yet) recognise types as generics (VHDL-2008).
--!      Instead it spits a warning
--!        "explicit link request to 'datatype' could not be resolved"
--! @bug Doxygen doesn't recognise the VHDL-2008 construct of 'datatype'
--! @bug Doxygen doesn't (yet) recognise case generate (VHDL-2008).
--!      Instead it complains "syntax error at line: 74 : gen_delay"
--! @bug Doxygen doesn't recognise the alternative architecture 'altshift_taps'
--! which is the
--! exact same implementation as the behavioral architecture, except that no
--! attribute to the delay_reg is given such that indeed, shift registers can
--! be pushed into memory-based altshift_taps.
--! Instead the warning "syntax error 'architecture'" appears.
--------------------------------------------------------------------------------

------------------------------<-    80 chars    ->------------------------------
--! @brief Instantiation of type-independent shift register according to generics.
--!
--! @details Delays a signal of any type in the #clk clock domain (VHDL-2008).
--! It is a type-unspecific shift register!
--!
--! The delay_chain is determined by few generics:
--!     - datatype: The data type of the signal #sig_i to be delayed
--!     - #D_DEPTH (>= 0): Determines the number of #clk cycles to delay
--!       #sig_o. If set to 0, the signal is not delayed.
--!
--!     The #delay_chain can also be used to synchronise in a single bit signal.
--!
--! @warning
--!     Don't use it for synchronising std_logic_vectors over clock domains!
--!     For this purpose use DC FIFOs instead!
--!
--! @section instantiation_template Instantiation template
--!
--! @code{.vhdl}
--! [inst_name]: entity misc.delay_chain
--! generic map (
--!   -- Data type that shall be delayed, i.e. sig'subtype
--!   datatype  => [type],
--!   -- Number of clock cycles it shell be delayed. If set to 0, signal is not delayed.
--!   D_DEPTH   => [natural := 3]
--! )
--! port map (
--!   -- Clock
--!   clk       => [in  std_logic],
--!   -- Enable the delay chain output, otherwise the output keeps the last value
--!   en_i      => [in  std_logic := '1'],
--!   -- Input signal
--!   sig_i     => [in  datatype],
--!   -- Delayed output signal
--!   sig_o     => [out datatype]
--! );
--! @endcode
--------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.std_logic_1164.all;

library PoC;
  use PoC.utils.all;

--! @endcond
entity delay_chain is
  generic (
    --! Data type that shall be delayed, i.e. sig_i'subtype
    type datatype;
    --! Number of clock cycles it shall be delayed. If set to 0, signal is not delayed.
    D_DEPTH : natural := 3
  );
  port (
    --! Clock
    clk   : in    std_logic;
    --! Enable the delay chain output, otherwise the output keeps the last value
    en_i  : in    std_logic := '1';
    --! Input signal
    sig_i : in    datatype;
    --! Delayed output signal
    sig_o : out   datatype
  );
end entity delay_chain;

--! @cond
library altera;
  use altera.altera_syn_attributes.all;

--! @endcond

--! Implementation of the #delay_chain preventing altshift_taps
architecture behavioral of delay_chain is

  --! Array used for delaying #sig_o by #D_DEPTH clock cycles
  type t_delay_reg is array (ite(D_DEPTH=0, 0, D_DEPTH - 1) downto 0) of datatype;

  --! @brief Instance of the array used for delay.
  --! @details Due to the unknown type, an initial value cannot be given.
  signal delay_reg : t_delay_reg;

  --! @brief Prevent large hyperpipes from going into memory-based altshift_taps,
  --! since that won't take advantage of Hyper-Registers
  attribute altera_attribute of delay_reg :
    signal is "-name AUTO_SHIFT_REGISTER_RECOGNITION off";

begin

  -- output is always the last item in the chain
  sig_o <= delay_reg(0);

  -- now set the last item in the chain
  --! @cond
  gen_delay : case D_DEPTH generate
    -- No delay of #sig_i
    when 0 =>
      delay_reg(0) <= sig_i;
    -- Delay #sig_i by one clock cycle
    when 1 =>

      -- When the default value of en_i is used the related
      -- logic is automatically optimised away (by Quartus)
      proc_singledelay : process (clk)
      begin
        if rising_edge(clk) then
          if en_i = '1' then
            delay_reg(0) <= sig_i;
          else
            delay_reg(0) <= delay_reg(0);
          end if;
        end if;
      end process proc_singledelay;

    -- Delay #sig_i by multiple clock cycles
    when others =>

      proc_multipledelay : process (clk)
      begin
        if rising_edge(clk) then
          if en_i = '1' then
            -- shift right and insert sig_i on the left
            delay_reg(D_DEPTH - 1 downto 0) <= sig_i & delay_reg(D_DEPTH - 1 downto 1);
          else
            delay_reg <= delay_reg;
          end if;
        end if;
      end process proc_multipledelay;

  end generate gen_delay;

--! @endcond
end architecture behavioral;

--! Implementation of the #delay_chain allowing altshift_taps
--! @details
--! Exact same implementation as the behavioral architecture, except that no
--! attribute to the #delay_reg is given such that indeed, shift registers can
--! be pushed into memory-based altshift_taps.
architecture altshift_taps of delay_chain is

  --! Array used for delaying #sig_o by #D_DEPTH clock cycles
  type t_delay_reg is array (ite(D_DEPTH=0, 0, D_DEPTH - 1) downto 0) of datatype;

  --! @brief Instance of the array used for delay.
  --! @details Due to the unknown type, an initial value cannot be given.
  signal delay_reg : t_delay_reg;

begin

  -- output is always the last item in the chain
  sig_o <= delay_reg(0);

  -- now set the last item in the chain
  --! @cond
  gen_delay : case D_DEPTH generate
    -- No delay of #sig_i
    when 0 =>
      delay_reg(0) <= sig_i;
    -- Delay #sig_i by one clock cycle
    when 1 =>

      -- When the default value of en_i is used the related
      -- logic is automatically optimised away (by Quartus)
      proc_singledelay : process (clk)
      begin
        if rising_edge(clk) then
          if en_i = '1' then
            delay_reg(0) <= sig_i;
          else
            delay_reg(0) <= delay_reg(0);
          end if;
        end if;
      end process proc_singledelay;

    -- Delay #sig_i by multiple clock cycles
    when others =>

      proc_multipledelay : process (clk)
      begin
        if rising_edge(clk) then
          if en_i = '1' then
            -- shift right and insert sig_i on the left
            delay_reg(D_DEPTH - 1 downto 0) <= sig_i & delay_reg(D_DEPTH - 1 downto 1);
          else
            delay_reg <= delay_reg;
          end if;
        end if;
      end process proc_multipledelay;

  end generate gen_delay;

--! @endcond

end architecture altshift_taps;
