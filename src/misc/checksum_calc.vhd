-------------------------------------------------------------------------------
-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Calculates checksum of data input
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details Calculates a checksum of input data.
--! Data input must be 64, 32 or 16 bit long. Output is always 16 bit.
--! Module sums every 16 bit of the data input.
--! New data is accepted when #en = '1' (#en = '0' halts calculation).
--! The checksum is cleared when #rst = '1' (then #en is ignored).
--! @todo Make this with some generics adequate for different i/o widths
-------------------------------------------------------------------------------
--
-- Instantiation template:
--
--  [inst_name]: entity misc.checksum_calc
--    generic map (
--      i_width => [integer := 64],     --! width of input data
--      o_width => [integer := 16]      --! width of output data
--    )
--    port map (
--      clk             => [in  std_logic],     --! clock
--      rst             => [in  std_logic],     --! sync reset
--      en              => [in  std_logic],     --! enable
--
--      data_in => [in  std_logic_vector(i_width-1 downto 0)],  --! input data
--      sum_out => [out std_logic_vector(o_width-1 downto 0)},  --! output data
--    );
--
-------------------------------------------------------------------------------
--! @cond
library IEEE;
use IEEE.std_logic_1164.all;
--! @endcond

entity checksum_calc is
  generic (
    --! Width of #data_in
    i_width : integer := 64;
    --! Width of #sum_out
    o_width : integer := 16
  );
  port (
    --! Clock
    clk     : in  std_logic;
    --! Enable calculcation
    en      : in  std_logic;
    --! Sync reset
    rst     : in  std_logic;
    --! Input data of width #i_width
    data_in : in  std_logic_vector(i_width-1 downto 0);
    --! Output data of width #o_width
    sum_out : out std_logic_vector(o_width-1 downto 0)
  );
end checksum_calc;

--! @cond
library IEEE;
use IEEE.numeric_std.all;
--! @endcond

--! Implementation of the checksum_calc
architecture behavioral of checksum_calc is
  --! The 17 bit checksum of #data_in
  signal CRC : unsigned(o_width downto 0) := (others => '0');
begin

  assert (i_width = 64) or (i_width = 32) or (i_width = 16) report "i_width must be 64, 32 or 16" severity failure;
  assert (o_width = 16) report "o_width must be 16" severity failure;

  gen_64or32bit_input : if i_width >= 32 generate
    -- For a 32 bit #i_width or is the sum of #data_in (63 downto 32) and #data_in (31 downto 0) if #i_width is 64.
    signal CRC32 : unsigned(32 downto 0) := (others => '0');
  begin
    gen_64bit_input : if i_width = 64 generate
      -- For a 64 bit #i_width.
      signal CRC64 : unsigned(64 downto 0) := (others => '0');
    begin
      CRC64 <= '0' & unsigned(data_in);
      CRC32 <= ('0' & CRC64(63 downto 32)) + ('0' & CRC64(31 downto 0));
    end generate;

    gen_32bit_input : if i_width = 32 generate
      CRC32 <= '0' & unsigned(data_in);
    end generate;

    CRC <= ('0' & CRC32(31 downto 16)) + ('0' & CRC32(15 downto 0)) + (x"0000" & CRC32(32));
  end generate;

  gen_16bit_input : if i_width = 16 generate
  begin
    CRC <= '0' & unsigned(data_in);
  end generate;

  registered_add : block
    --! The current CRC calculation
    signal CRC_reg    : unsigned(o_width downto 0)   := (others => '0');
    --! The overflow bit of CRC
    signal carry      : unsigned(o_width downto 0)   := (others => '0');
    --! The overflow bit from the previous calculation
    signal carry_prev : unsigned(o_width-1 downto 0) := (others => '0');
    --! The CRC calculation from the previous cycle
    signal CRC_prev   : unsigned(o_width-1 downto 0) := (others => '0');
  begin
    -- The last bit in CRC is the carry bit. Generate a 17 bit wide unsigned
    -- with the carry bit on the right and 0's elsewhere.
    -- carry <= ( 0 => CRC(o_width), others => '0' );
    -- rewritten to satisfy Modelsim: Non-locally static OTHERS choice is allowed only if it is the only choice of the only association
    carry(0)                <= CRC(o_width);
    carry(o_width downto 1) <= (others => '0');

     --! Combines #CRC_prev with the current #CRC and the overflow (#carry).
    CRCCalc: process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          CRC_reg <= (others => '0');
        elsif en = '1' then
          CRC_reg <= ('0' & CRC_prev) + CRC(o_width-1 downto 0) + carry;
        end if;
      end if;
    end process;

    -- take care for carry bit of registered addition
    -- carry_prev <= ( 0 => CRC_reg(o_width), others => '0' );
    -- rewritten to satisfy Modelsim: Non-locally static OTHERS choice is allowed only if it is the only choice of the only association.
    carry_prev(0)                  <= CRC_reg(o_width);
    carry_prev(o_width-1 downto 1) <= (others => '0');

    CRC_prev <= CRC_reg(o_width-1 downto 0) + carry_prev;

    -- finally produce CRC value
    sum_out <= not std_logic_vector(CRC_prev(o_width-1 downto 0));

  end block;

end behavioral;
