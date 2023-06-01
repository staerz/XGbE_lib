-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Instantiation of a single or dual clock,
--!   same or mixed-width FIFO for ALTERA
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--! @todo Doxygen doesn't support the 'if ... generate ... else ... generate'
--!  clause, so we exclude the parsing here. That's too bad ... :(
-------------------------------------------------------------------------------
--! @details Instantiation of a FIFO with ALTERA primitives.
--!
--! Generics and port definitions are identical to those of the #generic_fifo.
--! Depending on the generics, one of the ALTERA FIFO primitives
--! "SCFIFO", "DCFIFO" or "DCFIFO_MIXED_WIDTHS" is instantiated.
-------------------------------------------------------------------------------

--! @cond
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--! library required to include log2ceil for smooth port definitions
library PoC;
use PoC.utils.all;
--! @endcond

entity altera_fifo is
  --! @cond
  generic (
    wr_d_width      : positive;
    wr_d_depth      : positive;
    rd_d_width      : natural := 0;
    dual_clk        : boolean := false;
    showahead       : boolean := false;
    max_depth       : integer range 6 to 17 := 6;
    rd_sync_stages  : integer := 4;
    wr_sync_stages  : integer := 4;
    ram_type        : string  := ""
  );
  port (
    -- reset
    rst       : in  std_logic  := '0';
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
    rd_usedw  : out std_logic_vector(log2ceil(wr_d_depth * wr_d_width / ite(rd_d_width = 0, wr_d_width, rd_d_width))-1 downto 0);
    rd_empty  : out std_logic;
    rd_full   : out std_logic
  );
  --! @endcond
end altera_fifo;

-- library required to retrieve intended_device_family
--! @cond
library PoC;
use PoC.config.all;
--! @endcond

--! Instantiate "SCFIFO", "DCFIFO" or "DCFIFO_MIXED_WIDTHS", depending generics.
architecture behavioral of altera_fifo is

  --! Effective read width of the primitive determined from generics
  constant RD_D_WIDTH_EFFECTIVE : positive := ite(rd_d_width = 0, wr_d_width, rd_d_width);
  --! Width of the counter for the FIFO full indicator (write domain)
  -- (actually not used but to grant correct FIFO instantiation)
  constant WR_D_DEPTH_W   : positive := log2ceil(wr_d_depth);
  --! Width of the counter for the FIFO full indicator (read domain)
  constant RD_D_DEPTH_W   : positive := log2ceil(wr_d_depth * wr_d_width / RD_D_WIDTH_EFFECTIVE);

  -- various settings that run into 'lpm_hint':
  -- evaluate individually and concatenate at the end, use a trailing comma!
  --! Set block ram type if specified
  constant RAM_TYPE_S   : string := ite(ram_type'length /= 0,  "RAM_BLOCK_TYPE=" & ram_type & ",", "");
  --! Set maximum depth if specified
  constant MAX_DEPTH_S  : string := ite(max_depth /= 6, "MAXIMUM_DEPTH=" & integer'image(2**max_depth) & ",", "");
-- this is the setting when generating the dcfifo with the IP core gen
-- might need some attention
  constant DISABLE_EMBEDDED_SDC  : string := "DISABLE_DCFIFO_EMBEDDED_TIMING_CONSTRAINT=TRUE,";
  --! Preliminary lpm_hint to be used by concatenating all individual settings (add here if there are more)
  constant LPM_HINT_S_TMP   : string := RAM_TYPE_S & MAX_DEPTH_S & DISABLE_EMBEDDED_SDC;
  --! Actual lpm_hint: cut off trailing comma to make the actual instance happy
  constant LPM_HINT_S       : string := ite(LPM_HINT_S_TMP'length /= 0, LPM_HINT_S_TMP(1 to LPM_HINT_S_TMP'length-1), "");
  --! Convert showahead from boolean to string
  constant LPM_SHOWAHEAD_S  : string := ite(showahead, "ON", "OFF");
begin
  -- Instantiate a scfifo when dual_clk = false
  --! @cond
  gen_fifo: if not dual_clk generate
    -- declare component here to make this independent of altera library
    --! single clock FIFO primitive
    component scfifo
      generic (
        intended_device_family  : string;
        enable_ecc              : string;
        lpm_hint                : string;
        lpm_numwords            : natural;
        lpm_showahead           : string;
        lpm_type                : string;
        lpm_width               : natural;
        lpm_widthu              : natural;
        overflow_checking       : string;
        underflow_checking      : string;
        use_eab                 : string
      );
      port (
        aclr  : in  std_logic;
        clock : in  std_logic;
        sclr  : in  std_logic;
        wrreq : in  std_logic;
        data  : in  std_logic_vector(lpm_width-1 downto 0);
        usedw : out std_logic_vector(lpm_widthu-1 downto 0);
        rdreq : in  std_logic;
        q     : out std_logic_vector(lpm_width-1 downto 0);
        empty : out std_logic;
        full  : out std_logic
      );
    end component;

    signal full   : std_logic;
    signal empty  : std_logic;
    signal usedw  : std_logic_vector(log2ceil(wr_d_depth)-1 downto 0);
  begin
    gen_report: if POC_VERBOSE generate
      assert false report "Selected FIFO: scfifo" severity note;
    end generate;

    scfifo_inst : scfifo
      --! An single clock scfifo is instantiated in this case
      generic map (
        enable_ecc          => "FALSE",
        intended_device_family => getAlteraDeviceName(DEVICE),
        lpm_hint            => LPM_HINT_S,
        lpm_showahead       => LPM_SHOWAHEAD_S,
        lpm_numwords        => wr_d_depth,
        lpm_type            => "scfifo",
        lpm_width           => wr_d_width,
        lpm_widthu          => WR_D_DEPTH_W,
        overflow_checking   => "ON",
        underflow_checking  => "ON",
        use_eab             => "ON"
      )
      port map (
        aclr    => rst, -- for some reason this signal needs to be connected ...
        sclr    => rst,
        clock   => wr_clk,
        wrreq   => wr_en,
        data    => wr_data,
        usedw   => usedw,
        rdreq   => rd_en,
        q       => rd_data,
        empty   => empty,
        full    => full
      );

    -- declare status to both clock domain signals
    wr_usedw  <= usedw;
    wr_full   <= full;
    wr_empty  <= empty;
    rd_usedw  <= usedw;
    rd_full   <= full;
    rd_empty  <= empty;

  --! otherwise, check the width of the read port to use a dcfifo
  elsif rd_d_width = 0 or rd_d_width = wr_d_width generate
    -- declare component here to make this independent of altera library
    --! dual clock FIFO primitive
    component dcfifo
      generic (
        intended_device_family  : string;
        enable_ecc              : string;
        lpm_hint                : string;
        lpm_numwords            : natural;
        lpm_showahead           : string;
        lpm_type                : string;
        lpm_width               : natural;
        lpm_widthu              : natural;
        wrsync_delaypipe        : natural;
        rdsync_delaypipe        : natural;
        overflow_checking       : string;
        underflow_checking      : string;
        write_aclr_synch        : string;
        read_aclr_synch         : string;
        use_eab                 : string
      );
      port (
        aclr    : in  std_logic;
        wrclk   : in  std_logic;
        wrreq   : in  std_logic;
        data    : in  std_logic_vector(wr_d_width-1 downto 0);
        wrusedw : out std_logic_vector(WR_D_DEPTH_W-1 downto 0);
        wrempty : out std_logic;
        wrfull  : out std_logic;
        rdclk   : in  std_logic;
        rdreq   : in  std_logic;
        q       : out std_logic_vector(RD_D_WIDTH_EFFECTIVE-1 downto 0);
        rdusedw : out std_logic_vector(RD_D_DEPTH_W-1 downto 0);
        rdempty : out std_logic;
        rdfull  : out std_logic
      );
    end component;
  begin
    gen_report: if POC_VERBOSE generate
      assert false report "Selected FIFO: dcfifo" severity note;
    end generate;

    dcfifo_inst : dcfifo
    --! A dual clock dcfifo primitive is instantiated in this case
    generic map (
      enable_ecc          => "FALSE",
      intended_device_family => getAlteraDeviceName(DEVICE),
      lpm_hint            => LPM_HINT_S,
      lpm_showahead       => LPM_SHOWAHEAD_S,
      lpm_numwords        => wr_d_depth,
      lpm_type            => "dcfifo",
      lpm_width           => wr_d_width,
      lpm_widthu          => WR_D_DEPTH_W,
      wrsync_delaypipe    => rd_sync_stages,
      rdsync_delaypipe    => wr_sync_stages,
      overflow_checking   => "ON",
      underflow_checking  => "ON",
      write_aclr_synch    => "ON",
      read_aclr_synch     => "ON",
      use_eab             => "ON"
    )
    port map (
      aclr    => rst,
      -- write clock domain
      wrclk   => wr_clk,
      wrreq   => wr_en,
      data    => wr_data,
      wrusedw => wr_usedw,
      wrempty => wr_empty,
      wrfull  => wr_full,
      -- read clock domain
      rdclk   => rd_clk,
      rdreq   => rd_en,
      rdusedw => rd_usedw,
      q       => rd_data,
      rdempty => rd_empty,
      rdfull  => rd_full
    );

  --! otherwise use a mixed width FIFO
  else generate
    -- declare component here to make this independent of altera library
    --! dual clock, mixed width, FIFO primitive
    component dcfifo_mixed_widths
    generic (
      intended_device_family  : string;
      enable_ecc              : string;
      lpm_hint                : string;
      lpm_numwords            : natural;
      lpm_showahead           : string;
      lpm_type                : string;
      lpm_width               : natural;
      lpm_widthu              : natural;
      lpm_width_r             : natural;
      lpm_widthu_r            : natural;
      wrsync_delaypipe        : natural;
      rdsync_delaypipe        : natural;
      overflow_checking       : string;
      underflow_checking      : string;
      write_aclr_synch        : string;
      read_aclr_synch         : string;
      use_eab                 : string
    );
    port (
      aclr    : in  std_logic;
      wrclk   : in  std_logic;
      wrreq   : in  std_logic;
      data    : in  std_logic_vector(wr_d_width-1 downto 0);
      wrusedw : out std_logic_vector(WR_D_DEPTH_W-1 downto 0);
      wrempty : out std_logic;
      wrfull  : out std_logic;
      rdclk   : in  std_logic;
      rdreq   : in  std_logic;
      q       : out std_logic_vector(RD_D_WIDTH_EFFECTIVE-1 downto 0);
      rdusedw : out std_logic_vector(RD_D_DEPTH_W-1 downto 0);
      rdempty : out std_logic;
      rdfull  : out std_logic
    );
    end component;
  begin
    gen_report: if POC_VERBOSE generate
      assert false report "Selected FIFO: dcfifo_mixed_widths" severity note;
    end generate;

    dcfifo_mixed_widths_inst : dcfifo_mixed_widths
    --! A mixed width dual clock dcfifo_mixed_widths primitive is instantiated in this case
    generic map (
      enable_ecc          => "FALSE",
      -- this is a nasty hack to get this primitive simulation going properly
      -- without the need to have any fancy device installed
      intended_device_family  => ite(SIMULATION, "Cyclone IV", getAlteraDeviceName(DEVICE)),
      lpm_hint            => LPM_HINT_S,
      lpm_showahead       => LPM_SHOWAHEAD_S,
      lpm_numwords        => wr_d_depth,
      lpm_type            => "dcfifo_mixed_widths",
      lpm_width           => wr_d_width,
      lpm_widthu          => WR_D_DEPTH_W,
      lpm_width_r         => RD_D_WIDTH_EFFECTIVE,
      lpm_widthu_r        => RD_D_DEPTH_W,
      wrsync_delaypipe    => 4,
      rdsync_delaypipe    => 4,
      overflow_checking   => "ON",
      underflow_checking  => "ON",
      write_aclr_synch    => "ON",
      read_aclr_synch     => "ON",
      use_eab             => "ON"
    )
    port map (
      aclr    => rst,
      -- write clock domain
      wrclk   => wr_clk,
      wrreq   => wr_en,
      data    => wr_data,
      wrusedw => wr_usedw,
      wrempty => wr_empty,
      wrfull  => wr_full,
      -- read clock domain
      rdclk   => rd_clk,
      rdreq   => rd_en,
      rdusedw => rd_usedw,
      q       => rd_data,
      rdempty => rd_empty,
      rdfull  => rd_full
    );
  end generate;
  --! @endcond
end behavioral;
