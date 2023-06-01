-------------------------------------------------------------------------------
--! @file counter_matcher.vhd
--! @brief Generates a stimulus based on a counter read from a file.
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @file
--! @brief Stimulus generator based on counters provided by a file.
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------

--! Use default IEEE libraries
library ieee;
--! ... and packages
use ieee.std_logic_1164.all;

--------------------------------------------------------------------------------
--! @brief Stimulus generator reading from file.
--!
--! @details The stimulus is generated by reading a file, specified by #filename.
--!
--! This implies to have a simulation running that increases a counter as it is
--! done e.g. in the simulation_basics.vhd.
--!
--! It uses the file_reader_hex to read data.
--! See the file_reader_hex for the description of the expected file format.
--------------------------------------------------------------------------------
entity counter_matcher is
generic (
  --! Name of the file to read
  filename     : string := "";
  --! @brief Symbol to mark commented lines.
  --! Needs to be the first character of the line.
  comment_flag  : character := '%';
  --! @brief Symbol to indicate the counter (#next_stim) when the following packet shall be read.
  --! Needs to be the first character of the line.
  counter_flag  : character := '@';
  --! @brief Symbol to indicate the range counter (#last_stim) when using in range mode.
  --! Is the character separating the two counters when indicating a range.
  range_flag    : character := '-'
);
port (
  --! Clock
  clk       : in  std_logic;
  --! Reset (synch with #clk): starts reading the file from the beginning again
  rst       : in  std_logic;
  --! Counter of the simulation (to match counters in file to read from)
  cnt       : in  natural;
  --! Output stimulus
  stimulus  : out std_logic;
  --! End of file
  eof       : out std_logic
);
end counter_matcher;

--! Load sim for file_reader_hex
library sim;

--! Implementation of the counter_matcher
architecture behavior of counter_matcher is
  --! Read enable signal for the file_reader_hex
  signal read_next_stimulus : std_logic := '0';
  --! Next stimulus read from file_reader_hex
  signal next_stimulus    : natural := 0;
  --! Last stimulus read from file_reader_hex
  signal last_stimulus    : natural := 0;
  --! End of file of #filename
  signal stimulus_eof     : std_logic := '0';
  --! Internal stimulus (not yet sync to #clk)
  signal stimulus_r     : std_logic := '0';
begin

  --! Instantiate the file_reader_hex
  stimulus_reader: entity sim.file_reader_hex
  generic map (
    filename      => filename,
    comment_flag  => comment_flag,
    counter_flag  => counter_flag,
    range_flag    => range_flag,
    wordsperline  => 1
  )
  port map (
    clk       => clk,
    rst       => rst,
    ren       => read_next_stimulus,

    next_stim => next_stimulus,
    last_stim => last_stimulus,

    eof       => stimulus_eof
  );

  --! Set #stimulus_r and #read_next_stimulus according to #cnt, #next_stimulus and #last_stimulus
  proc_gen_stimulus: process(clk)
    -- Intermediate counter (one ahead to match with simulation)
    variable sim_cnt : natural := 0;
  begin
    sim_cnt := cnt + 1;
    -- the simulation could have reset, but counting goes on:
    -- just read the previous triggers again, but don't trigger
    -- Checking 'now > 0' is an important additional save guard in order to prevent
    -- the comparison of the counters to result in a fake 'true' upon initialisation
    -- Note: This behaviour has only been observed when using the UVVM clock generator!
    if sim_cnt > last_stimulus and now > 0 ns then
      stimulus_r <= '0';
      read_next_stimulus <= '1';
    -- wait for the counter to match the stimulus read from file
    elsif next_stimulus <= sim_cnt and sim_cnt < last_stimulus then
      stimulus_r <= '1';
      read_next_stimulus <= '0';
    elsif sim_cnt = last_stimulus then
      stimulus_r <= '1';
      read_next_stimulus <= not stimulus_eof;
    else
      stimulus_r <= '0';
      read_next_stimulus <= '0';
    end if;
  end process;

  --! Synchronise output to #clk as signals are updated upon falling edge
  proc_sync_stimulus: process(clk)
  begin
    if rising_edge(clk) then
      stimulus <= stimulus_r;
      eof <= stimulus_eof;
    end if;
  end process;

end;