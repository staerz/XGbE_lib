-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Dummy instantiation of a FIFO for XILINX
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--! @todo This is a bare dummy implementation without functionality.
--!       If ever this repository is used for Xilinx, it must be implemented
--!       using the Xilinx primitives accordingly.
--!       See the altera_fifo.vhd.
--------------------------------------------------------------------------------
--! @details Instantiation of a FIFO with XILINX primitives.
--!
--! Actually nothing is instantiated.
--------------------------------------------------------------------------------

--! @cond
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--! library required to include log2ceil for smooth port definitions
library PoC;
use PoC.utils.all;
--! @endcond

entity xilinx_fifo is
--! @cond
  generic (
    wr_d_width  : positive;
    wr_d_depth  : positive;
    rd_d_width  : natural := 0;
    dual_clk    : boolean := false;
    showahead   : boolean := false;
    max_depth   : integer range 6 to 17 := 6;
    ram_type    : string  := ""
  );
  port (
    -- reset
    rst       : in  std_logic := '0';
    -- write clock domain
    wr_clk    : in  std_logic;
    wr_en     : in  std_logic;
    wr_data   : in  std_logic_vector(wr_d_width-1 downto 0);
    wr_usedw  : out std_logic_vector(log2ceil(wr_d_depth)-1 downto 0);
    wr_empty  : out std_logic;
    wr_full   : out std_logic;
    -- read clock domain
    rd_clk    : in  std_logic := '0';
    rd_en     : in  std_logic;
    rd_data   : out std_logic_vector(ite(rd_d_width = 0, wr_d_width, rd_d_width)-1 downto 0);
    rd_usedw  : out std_logic_vector(log2ceil(ite(rd_d_width = 0, wr_d_depth, wr_d_depth * wr_d_width / rd_d_width))-1 downto 0);
    rd_empty  : out std_logic;
    rd_full   : out std_logic
  );
--! @endcond
end xilinx_fifo;

--! Actually nothing is instantiated.
architecture behavioral of xilinx_fifo is
begin
end behavioral;
