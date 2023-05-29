-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Packet generator for the AVALON-ST interface, reads data from file
--! @details Uses the file_reader_hex to read data. See the file_reader_hex for
--! the description of the expected file format.
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--! @brief Packet generator for the AVALON stream interface.
--!
--! @details Generates the control signals of the AVALON stream interface
--! (packet type variant):
--!  - valid
--!  - sop (start of packet)
--!  - eop (end of packet)
--!  - error
--!  - empty
--!
--! These control signals are concatenated as output port #TX_ctrl in this order.
--!
--! @section AS_InstTemplate Instantiation template
--!
--! @code{.vhdl}
--! [inst_name]: entity sim.AV_ST_sender
--! generic map (
--!   filename      => [string := ""],
--!   comment_flag  => [character := '%'],
--!   counter_flag  => [character := '@'],
--!   bitsperword   => [positive := 16],
--!   wordsperline  => [positive := 4],
--!   bitspersymbol => [positive := 8],
--!   debug         => [boolean := false]
--! )
--! port map (
--!   clk       => [in  std_logic],
--!   rst       => [in  std_logic],
--!   cnt       => [in  natural := 0],
--!   TX_ready  => [in  std_logic := '1'],
--!   TX_data   => [out std_logic_vector(bitsperword*wordsperline-1 downto 0)],
--!   TX_ctrl   => [out std_logic_vector(3+log2ceil(div_ceil(bitsperword*wordsperline,bitspersymbol)) downto 0],
--!   eof       => [out std_logic]
--! );
--! @endcode
-------------------------------------------------------------------------------

--! @cond
library IEEE;
use IEEE.std_logic_1164.all;
-- used for empty bits calculation:
library PoC;
use PoC.utils.all;
library sim;
--! @endcond

entity AV_ST_sender is
generic (
  --! name of the file to read
  filename      : string := "";
  --! @brief Symbol to mark commented lines.
  --! Needs to be the first character of the line.
  comment_flag  : character := '%';
  --! @brief Symbol to indicate the counter when the following packet shall be read.
  --! Needs to be the first character of the line.
  counter_flag  : character := '@';
  --! input data formatting: how many bits per word (must be a multiple of 4)
  bitsperword   : positive := 16;
  --! number of words (with constant bit width of bitsperword) per line
  wordsperline  : positive := 4;
  --! number of bits per symbol (must be a multiple of 4)
  bitspersymbol : positive := 8;
  --! enable debug output of file_reader_hex (verbose!)
  debug         : boolean := false
);
port (
  --! clock
  clk       : in  std_logic;
  --! reset (synch with clk): starts reading the file from the beginning again
  rst       : in  std_logic;
  --! counter of the simulation (to match counters in file to read from)
  cnt       : in  natural := 0;
  --! AVST ready signal for back pressure
  TX_ready  : in  std_logic := '1';
  --! AVST data
  TX_data   : out std_logic_vector(bitsperword*wordsperline-1 downto 0);
  --! AVST controls: valid & sop & eop & error & empty
  TX_ctrl   : out std_logic_vector(3+log2ceil(div_ceil(bitsperword*wordsperline,bitspersymbol)) downto 0);
  --! End of file
  eof       : out std_logic
);
end AV_ST_sender;

--! Implementation of the AV_ST_sender
architecture behavioral of AV_ST_sender is
  --! width of the empty section of the TX_ctrl
  constant empty_w    : natural := log2ceil(div_ceil(bitsperword*wordsperline,bitspersymbol));
begin

  gen_TX_interface: block

    --! @name signals for ports of the data source
    signal ren        : std_logic := '0'; --! read enable
    signal dout       : std_logic_vector(bitsperword*wordsperline-1 downto 0) := (others => '0'); --! output data
    signal empty      : std_logic_vector(log2ceil(div_ceil(bitsperword*wordsperline,bitspersymbol))-1 downto 0) := (others => '0'); --! number of empty words
    signal eop        : std_logic := '0'; --! end of packet
    signal err        : std_logic := '0'; --! error indicator
    signal next_stim  : natural := 0; --! next stimulus (counter) read from file
    signal s_eof      : std_logic := '0'; --! end of file

    --! @name auxiliary signals for steering the ren
    signal ren_init   : std_logic := '0'; --! intermediate read enable to initialise procedure
    signal read_stim  : std_logic := '0'; --! intermediate read enable for actual data

    --! @name AV ST signals to be mapped to ports
    signal ready      : std_logic := '1'; --! (internal) ready, mapped to TX_ready
    signal avvalid    : std_logic := '0'; --! (internal) valid, mapped to TX_ctrl(TX_ctrl'high)
    signal avsof      : std_logic := '0'; --! (internal) sof, mapped to TX_ctrl(TX_ctrl'high-1)
    signal aveof      : std_logic := '0'; --! (internal) eof, mapped to TX_ctrl(TX_ctrl'high-2)
  begin
    --! Instantiate the file reader
    data_source: entity sim.file_reader_hex
    generic map (
      filename      => filename,
      comment_flag  => comment_flag,
      counter_flag  => counter_flag,
      bitsperword   => bitsperword,
      wordsperline  => wordsperline,
      bitspersymbol => bitspersymbol,
      debug         => debug
    )
    port map (
      clk       => clk,
      rst       => rst,
      ren       => ren,

      dout      => dout,
      empty     => empty,
      eop       => eop,
      err       => err,

      next_stim => next_stim,

      eof       => s_eof
    );

------------------------------<-    80 chars    ->------------------------------
-- steering of the file_reader_hex
--------------------------------------------------------------------------------
    -- reading pulse once counter has reached nest_stim
    -- this must not take ready into account as the data read will only become
    -- available on the next cycle. If we then are not ready, we just don't
    -- continue reading (via read_stim).
    ren_init <=
      '1' when cnt = next_stim-1 and rst = '0'
      else '0';

    -- regular read for new data (once launched from ren_init)
    read_stim <=
      '1' when cnt > next_stim-1 and ready = '1' and rst = '0'
      else '0';

    -- the actual read is the combination of the upper two,
    -- as long as there's still something to read
    -- note that this is a little different from the reading done in the tb
    -- for file_reader_hex as here control signals are also generated.
    ren <= (ren_init or read_stim) and not s_eof;

------------------------------<-    80 chars    ->------------------------------
--! @brief Generate frame delimiter signals from file_reader_hex input:
--! Makes use of default values for valid and sof and alters them if needed.
--------------------------------------------------------------------------------
    proc_steer_delimiters : process(clk)
    begin
      if rising_edge(clk) then
        avsof <= avsof;
        avvalid <= avvalid;
        if rst = '1' then
          avsof <= '0';
          avvalid <= '0';
        elsif ren_init = '1' then
          avsof <= '1';
          avvalid <= '1';
        elsif ready = '1' then
          avsof <= '0';
          if eop = '1' then
            avvalid <= '0';
          end if;
        end if;
      end if;
    end process;
    aveof <= eop and avvalid;

------------------------------<-    80 chars    ->------------------------------
-- Map internal signals to ports
--------------------------------------------------------------------------------
    -- Ready:
    ready <= TX_ready;
    -- Data:
    TX_data <= dout;
    -- Valid:
    TX_ctrl(TX_ctrl'high) <= avvalid;
    -- Start of frame:
    TX_ctrl(TX_ctrl'high-1) <= avsof;
    -- End of frame:
    TX_ctrl(TX_ctrl'high-2) <= aveof;
    -- Error:
    TX_ctrl(empty_w) <= err when aveof = '1' else '0';
    -- Empty:
    TX_ctrl(empty_w-1 downto 0) <= empty when aveof = '1' else (others => '0');
    -- End of File:
    eof <= s_eof;

  end block;

end architecture behavioral;
