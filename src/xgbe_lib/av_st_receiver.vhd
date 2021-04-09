-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Packet writer for the AVALON-ST interface, writes data to file.
--! @details Uses the file_writer_hex to write data. See the file_writer_hex for
--! the description of the expected file format.
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.std_logic_1164.all;
--! @endcond

--! Packet writer for the AVALON-ST interface, writes data to file.
entity av_st_receiver is
  generic (
    --! File containing counters on which the RX interface is not ready
    READY_FILE    : string := "";
    --! File to write out the RX interface
    DATA_FILE     : string := "";

    --! @brief Symbol to mark commented lines.
    --! Needs to be the first character of the line.
    COMMENT_FLAG  : character := '%';

    --! Output data formatting: how many bits per word (must be a multiple of 4)
    BITSPERWORD   : positive := 16;
    --! Number of words (with constant bit width of bitsperword) per line
    WORDSPERLINE  : positive := 4;
    --! Number of bits per symbol (must be a multiple of 4)
    BITSPERSYMBOL : positive := 8
  );
  port (
    --! Clock
    clk        : in    std_logic;
    --! Reset, sync with #clk
    rst        : in    std_logic;
    --! Counter
    cnt_i      : in    natural;

    --! AVST RX ready
    rx_ready_o : out   std_logic;
    --! AVST RX data
    rx_data_i  : in    std_logic_vector(63 downto 0);
    --! AVST RX controls
    rx_ctrl_i  : in    std_logic_vector(6 downto 0)
  );
end entity av_st_receiver;

--! @cond
library sim;
--! @endcond

--! Implementation of av_st_receiver
architecture emulational of av_st_receiver is

  --! Write enable
  signal wren       : std_logic := '0';
  --! Not RX ready as read from file
  signal rx_ready_n : std_logic := '0';

begin

  --! Instantiate counter_matcher to generate rx_ready_n
  inst_rx_ready : entity sim.counter_matcher
  generic map (
    FILENAME     => READY_FILE,
    COMMENT_FLAG => COMMENT_FLAG
  )
  port map (
    clk      => clk,
    rst      => rst,
    cnt      => cnt_i,
    stimulus => rx_ready_n
  );

  rx_ready_o <= not rx_ready_n;

  -- logging block for RX interface
  wren <= rx_ctrl_i(6) and not rx_ready_n;

  --! Instantiate file_writer_hex to write ip_tx_data
  inst_rx_log : entity sim.file_writer_hex
  generic map (
    FILENAME      => DATA_FILE,
    COMMENT_FLAG  => COMMENT_FLAG,
    BITSPERWORD   => BITSPERWORD,
    WORDSPERLINE  => WORDSPERLINE,
    BITSPERSYMBOL => BITSPERSYMBOL
  )
  port map (
    clk  => clk,
    rst  => rst,
    wren => wren,

    empty => rx_ctrl_i(2 downto 0),
    eop   => rx_ctrl_i(4),
    err   => rx_ctrl_i(3),

    din => rx_data_i
  );

end architecture emulational;
