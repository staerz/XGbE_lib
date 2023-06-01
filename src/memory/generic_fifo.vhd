-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Generic instantiation of a single or dual clock,
--!   same or mixed-width FIFO
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details Instantiation of a FIFO according to generics.
--!
--! The generics #wr_d_width and #wr_d_depth define the size of the FIFO.
--! The generic #rd_d_width must be a power-of-2 ratio with #wr_d_width.
--! When #rd_d_width \f$ \neq 1\f$ #wr_d_width, #dual_clk must be true.
--! According to those settings, the different FIFO primitives (single clock,
--! dual clock or dual clock mixed width) are instantiated.
--------------------------------------------------------------------------------
--
-- Instantiation template:
--
--  [inst_name]: entity memory.generic_fifo
--  generic map (
--    wr_d_width  => [positive],        --! width of data words
--    wr_d_depth  => [positive],        --! depth of the FIFO
--    rd_d_width  => [natural := 0],    --! width of data words
--    dual_clk    => [boolean := false] --! set to true to enable dual clock FIFO
--    showahead   => [boolean := false] --! enable show-ahead option
--    max_depth   => [integer := 6]     --! maximum block depth (base value)
--    ram_type    => [string  := ""]    --! specify RAM type
--  )
--  port map (
--    rst       => [in    std_logic := '0'],  --! async reset, active high
-- -- write clock domain
--    wr_clk    => [in    std_logic],         --! write clk
--    wr_en     => [in    std_logic],         --! write enable
--    wr_data   => [in    std_logic_vector(WR_D_WIDTH-1 downto 0)],            --! write data
--    wr_usedw  => [out   std_logic_vector(log2ceil(WR_D_DEPTH)-1 downto 0)],  --! used data amount
--    wr_empty  => [out   std_logic],         --! write empty
--    wr_full   => [out   std_logic],         --! write full
-- -- read clock domain
--    rd_clk    => [in    std_logic := '0'],  --! read clk (only used if dual_clk = true)
--    rd_en     => [in    std_logic],         --! read enable
--    rd_data   => [out   std_logic_vector(ite(RD_D_WIDTH = 0, WR_D_WIDTH, RD_D_WIDTH)-1 downto 0)],  --! read data
--    rd_usedw  => [out   std_logic_vector(log2ceil(WR_D_DEPTH * WR_D_WIDTH / ite(RD_D_WIDTH = 0, WR_D_WIDTH, RD_D_WIDTH))-1 downto 0)], --! used data amount
--    rd_empty  => [out   std_logic],         --! read empty
--    rd_full   => [out   std_logic]          --! read full
--  );
--
-------------------------------------------------------------------------------

--! @cond
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
-- library required to include log2ceil for port definitions
library PoC;
use PoC.utils.all;
--! @endcond

entity generic_fifo is
  generic (
    --! Width of (write) data words #wr_data of the FIFO.
    wr_d_width      : positive;
    --! Depth of the FIFO.
    wr_d_depth      : positive;
    --! @brief (optional) width of (read) data words #rd_data of the FIFO.
    --! @details Can be set to instantiate a dual clock FIFO with different
    --! write and read port widths.
    --! Its value must be any power-of-2-ratio with #wr_d_width.
    --! Requires #dual_clk = true.
    rd_d_width      : natural := 0;
    --! Switch to use a dual clock FIFO. If active, #rd_clk must be provided.
    dual_clk        : boolean := false;
    --! Switch to enable the show-ahead mode.
    showahead       : boolean := false;
    --! @brief FIFO optimisation: Maximum block depth.
    --! @details FIFO optimisation: The actual value of the maximum block depth
    --! ranges from 128 to 131072, (2^7 to 2^17).
    --! The default value (6) indicates no selection.
    max_depth       : integer range 6 to 17 := 6;
    --! @brief Number of read synchronization stages.
    rd_sync_stages  : integer := 4;
    --! @brief Number of write synchronization stages.
    wr_sync_stages  : integer := 4;
    --! FIFO optimisation: Indicate which RAM type to use.
    ram_type        : string  := ""
  );
  port (
    --! Reset (asynchronous).
    rst       : in    std_logic  := '0';
    --! Write clock.
    wr_clk    : in    std_logic;
    --! Write enable.
    wr_en     : in    std_logic;
    --! Write data of width #wr_d_width.
    wr_data   : in    std_logic_vector(WR_D_WIDTH-1 downto 0);
    --! Number of used words in the FIFO (synchroneous to #wr_clk).
    wr_usedw  : out   std_logic_vector(log2ceil(WR_D_DEPTH)-1 downto 0);
    --! Indicator that the FIFO is empty (synchroneous to #wr_clk).
    wr_empty  : out   std_logic;
    --! Indicator that the FIFO is full (synchroneous to #wr_clk).
    wr_full   : out   std_logic;
    --! Read clock. Only required if #dual_clk is true.
    rd_clk    : in    std_logic := '0';
    --! Read enable.
    rd_en     : in    std_logic;
    --! Read data of width #wr_d_width (or #rd_d_width if provided).
    rd_data   : out   std_logic_vector(ite(RD_D_WIDTH = 0, WR_D_WIDTH, RD_D_WIDTH)-1 downto 0);
    --! Number of used words in the FIFO (synchroneous to #rd_clk).
    rd_usedw  : out   std_logic_vector(log2ceil(WR_D_DEPTH * WR_D_WIDTH / ite(RD_D_WIDTH = 0, WR_D_WIDTH, RD_D_WIDTH))-1 downto 0);
    --! Indicator that the FIFO is empty (synchroneous to #rd_clk).
    rd_empty  : out   std_logic;
    --! Indicator that the FIFO is full (synchroneous to #rd_clk).
    rd_full   : out   std_logic
  );
end generic_fifo;

-- library required to include VENDOR
--! @cond
library PoC;
use PoC.config.all;
--! @endcond

--! Depending on the vendor detected, either an altera_fifo or a xilinx_fifo is instantiated.
architecture behavioral of generic_fifo is
begin

  -- note level only if enabled
  gen_report: if POC_VERBOSE generate
    assert not ((VENDOR = VENDOR_ALTERA) or (VENDOR = VENDOR_XILINX))
      report "Supported vendor '" & getVendorName(VENDOR) & "' detected."
      severity note;

    assert (VENDOR /= VENDOR_ALTERA)
      report "Selected vendor: " & getVendorName(VENDOR) & ". Generating ALTERA-based rams."
      severity note;

    assert (VENDOR /= VENDOR_XILINX)
      report "Selected vendor: " & getVendorName(VENDOR) & ". Generating XILINX-based rams."
      severity note;
  end generate;

  -- always report severe issues
  assert ((VENDOR = VENDOR_ALTERA) or (VENDOR = VENDOR_XILINX))
    report "No supported vendor '" & getVendorName(VENDOR) & "' selected. Do sth. about it!"
    severity error;

  gen_altera_fifo: if VENDOR = VENDOR_ALTERA generate
  --! ALTERA version of a FIFO.
    component altera_fifo is
      generic (
        WR_D_WIDTH      : positive;
        WR_D_DEPTH      : positive;
        RD_D_WIDTH      : natural               := 0;
        DUAL_CLK        : boolean               := false;
        SHOWAHEAD       : boolean               := false;
        MAX_DEPTH       : integer range 6 to 17 := 6;
        RD_SYNC_STAGES  : integer               := 4;
        WR_SYNC_STAGES  : integer               := 4;
        RAM_TYPE        : string                := ""
      );
      port (
      -- reset
        rst       : in    std_logic := '0';
      -- write clock domain
        wr_clk    : in    std_logic;
        wr_en     : in    std_logic;
        wr_data   : in    std_logic_vector(WR_D_WIDTH-1 downto 0);
        wr_usedw  : out   std_logic_vector(log2ceil(WR_D_DEPTH)-1 downto 0);
        wr_empty  : out   std_logic;
        wr_full   : out   std_logic;
      -- read clock domain
        rd_clk    : in    std_logic := '0';
        rd_en     : in    std_logic;
        rd_data   : out   std_logic_vector(ite(RD_D_WIDTH = 0, WR_D_WIDTH, RD_D_WIDTH)-1 downto 0);
        rd_usedw  : out   std_logic_vector(log2ceil(WR_D_DEPTH * WR_D_WIDTH / ite(RD_D_WIDTH = 0, WR_D_WIDTH, RD_D_WIDTH))-1 downto 0);
        rd_empty  : out   std_logic;
        rd_full   : out   std_logic
      );
    end component;
  begin
    ALTERA_fifo_inst : altera_fifo
  --! An ALTERA FIFO is instantiated when ALTERA is detected as vendor.
    generic map (
      WR_D_WIDTH      => WR_D_WIDTH,
      WR_D_DEPTH      => WR_D_DEPTH,
      RD_D_WIDTH      => RD_D_WIDTH,
      DUAL_CLK        => DUAL_CLK,
      SHOWAHEAD       => SHOWAHEAD,
      MAX_DEPTH       => MAX_DEPTH,
      RD_SYNC_STAGES  => RD_SYNC_STAGES,
      WR_SYNC_STAGES  => WR_SYNC_STAGES,
      RAM_TYPE        => RAM_TYPE
    )
    port map (
      rst     => rst,
    -- write clock domain
      wr_clk    => wr_clk,
      wr_en     => wr_en,
      wr_data   => wr_data,
      wr_usedw  => wr_usedw,
      wr_empty  => wr_empty,
      wr_full   => wr_full,
    -- read clock domain
      rd_clk    => rd_clk,
      rd_en     => rd_en,
      rd_data   => rd_data,
      rd_usedw  => rd_usedw,
      rd_empty  => rd_empty,
      rd_full   => rd_full
    );
  end generate;

  gen_xilinx_fifo: if VENDOR = VENDOR_XILINX generate
    --! XILINX version of a FIFO.
    component xilinx_fifo is
      --! @cond
      generic (
        WR_D_WIDTH      : positive;
        WR_D_DEPTH      : positive;
        RD_D_WIDTH      : natural               := 0;
        DUAL_CLK        : boolean               := false;
        SHOWAHEAD       : boolean               := false;
        MAX_DEPTH       : integer range 6 to 17 := 6;
        RD_SYNC_STAGES  : integer               := 4;
        WR_SYNC_STAGES  : integer               := 4;
        RAM_TYPE        : string                := ""
      );
      port (
        -- reset
        rst       : in    std_logic  := '0';
        -- write clock domain
        wr_clk    : in    std_logic;
        wr_en     : in    std_logic;
        wr_data   : in    std_logic_vector(WR_D_WIDTH-1 downto 0);
        wr_usedw  : out   std_logic_vector(log2ceil(WR_D_DEPTH)-1 downto 0);
        wr_empty  : out   std_logic;
        wr_full   : out   std_logic;
        -- read clock domain
        rd_clk    : in    std_logic := '0';
        rd_en     : in    std_logic;
        rd_data   : out   std_logic_vector(ite(RD_D_WIDTH = 0, WR_D_WIDTH, RD_D_WIDTH)-1 downto 0);
        rd_usedw  : out   std_logic_vector(log2ceil(WR_D_DEPTH * WR_D_WIDTH / ite(RD_D_WIDTH = 0, WR_D_WIDTH, RD_D_WIDTH))-1 downto 0);
        rd_empty  : out   std_logic;
        rd_full   : out   std_logic
      );
    end component;
  begin
    XLINIX_fifo_inst : xilinx_fifo
  --! A XILINX FIFO is instantiated when XILINX is detected as vendor.
    generic map (
      WR_D_WIDTH      => WR_D_WIDTH,
      WR_D_DEPTH      => WR_D_DEPTH,
      RD_D_WIDTH      => RD_D_WIDTH,
      DUAL_CLK        => DUAL_CLK,
      SHOWAHEAD       => SHOWAHEAD,
      MAX_DEPTH       => MAX_DEPTH,
      RD_SYNC_STAGES  => RD_SYNC_STAGES,
      WR_SYNC_STAGES  => WR_SYNC_STAGES,
      RAM_TYPE        => RAM_TYPE
    )
    port map (
      rst       => rst,
    -- write clock domain
      wr_clk    => wr_clk,
      wr_en     => wr_en,
      wr_data   => wr_data,
      wr_usedw  => wr_usedw,
      wr_empty  => wr_empty,
      wr_full   => wr_full,
    -- read clock domain
      rd_clk    => rd_clk,
      rd_en     => rd_en,
      rd_data   => rd_data,
      rd_usedw  => rd_usedw,
      rd_empty  => rd_empty,
      rd_full   => rd_full
    );
  end generate;
end behavioral;
