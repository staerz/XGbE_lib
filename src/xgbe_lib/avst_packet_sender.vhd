-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Packet sender for AVALON-ST packet interface, reads data from file.
--! @details Uses the av_st_sender (which uses file_reader_hex) to read data.
--! See the file_reader_hex for the description of the expected file format.
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Packet writer for the AVALON-ST interface, writes data to file.
entity avst_packet_sender is
  generic (
    --! Name of the file to read
    FILENAME      : string := "";

    --! @brief Symbol to mark commented lines.
    --! Needs to be the first character of the line.
    COMMENT_FLAG  : character := '%';
    --! @brief Symbol to indicate the counter when the following packet shall be read.
    --! Needs to be the first character of the line.
    COUNTER_FLAG  : character := '@';

    --! Output data formatting: how many bits per word (must be a multiple of 4)
    BITSPERWORD   : positive := 16;
    --! Number of words (with constant bit width of bitsperword) per line
    WORDSPERLINE  : positive := 4;
    --! Number of bits per symbol (must be a multiple of 4)
    BITSPERSYMBOL : positive := 8
  );
  port (
    --! Clock
    clk         : in    std_logic;
    --! Reset, sync with #clk
    rst         : in    std_logic;
    --! Counter
    cnt_i       : in    natural;

    --! AVST TX ready
    tx_ready_i  : in    std_logic;
    --! AVST TX data and controls

    tx_packet_o : out   t_avst_packet(
      data(BITSPERWORD * WORDSPERLINE - 1 downto 0),
      empty(log2ceil(div_ceil(BITSPERWORD * WORDSPERLINE, BITSPERSYMBOL)) - 1 downto 0),
      error(0 downto 0)
    );
    eof_o       : out   std_logic
  );
end entity avst_packet_sender;

--! @cond
library sim;
--! @endcond

--! Implementation of avst_packet_sender
architecture emulational of avst_packet_sender is

  -- Intermediate signal to convert controls from av_st_sender to t_avst_packet
  signal tx_ctrl : std_logic_vector(4 + tx_packet_o.empty'length - 1 downto 0);

begin

  --! Instantiate av_st_sender to read rst_tx from RST_RXD_FILE
  inst_rx_gen : entity sim.av_st_sender
  generic map (
    FILENAME      => FILENAME,
    COMMENT_FLAG  => COMMENT_FLAG,
    COUNTER_FLAG  => COUNTER_FLAG,
    BITSPERWORD   => BITSPERWORD,
    WORDSPERLINE  => WORDSPERLINE,
    BITSPERSYMBOL => BITSPERSYMBOL
  )
  port map (
    clk => clk,
    rst => rst,
    cnt => cnt_i,

    tx_ready => tx_ready_i,
    tx_data  => tx_packet_o.data,
    tx_ctrl  => tx_ctrl,
    eof      => eof_o
  );

  -- conversion of controls
  tx_packet_o.valid    <= tx_ctrl(4 + tx_packet_o.empty'length - 1);
  tx_packet_o.sop      <= tx_ctrl(4 + tx_packet_o.empty'length - 2);
  tx_packet_o.eop      <= tx_ctrl(4 + tx_packet_o.empty'length - 3);
  tx_packet_o.error(0) <= tx_ctrl(4 + tx_packet_o.empty'length - 4);
  tx_packet_o.empty    <= tx_ctrl(tx_packet_o.empty'range);

end architecture emulational;
