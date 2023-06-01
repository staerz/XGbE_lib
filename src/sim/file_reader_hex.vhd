-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief File reader for data from a file of hex values or counters.
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--! @todo Add note on offset of counter by one.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use std.textio.all;
use IEEE.std_logic_textio.all;
--! Requires PoC
library PoC;
--! ... for log2ceil calculation
use PoC.utils.all;

--------------------------------------------------------------------------------
--! @brief File reader for hex data.
--!
--! @details Reads data from a file of hex values (in ASCII strings).
--!
--! The entity is inspired by [this source](http://www.pldworld.com/_hdl/2/_ref/acc-eda/language_overview/test_benches/reading_and_writing_files_with_text_i_o.htm).
--!
--! Reading data from file is issued via read enable #ren = '1'.
--!  - Respecting #eof is recommended but not required (reading is prevented internally upon EOF).
--!  - Data #dout is available **one clock cycle after** setting #ren to '1'.
--!
--! It provides three use cases:
--!  1. Packet mode: Data packet reading indicated by counter.
--!
--!     In this mode, data packets are read to #dout line by line upon #ren per clock cycle.
--!     The counter for when the next packet starts is indicated by #next_stim
--!     and identical to the value read from the file.
--!
--!     To use the file reader in this mode, set #ren to '1' when the external counter is
--!     greater or equal to #next_stim.
--!     Also respecting possible signals like 'ready' is recommended.
--!
--!     If the data is supposed to be output at counts that match the counter indication in
--!     the file, simply an offset of 1 in the external comparison driving #ren can be applied.
--!
--!     The AV_ST_sender makes use of this mode.
--!  1. Loop mode: Data chunk reading without counter.
--!
--!     In this mode, data is read to #dout line by line upon #ren per clock cycle,
--!     not considering any counter indication.
--!
--!     To use the file reader in this mode, set #ren to '1' when desired.
--!     A cyclic reading of the file can be achieved by setting #ren to '1' (for one clock cycle)
--!     while also setting #rst to '1' at #eof = '1'.
--!
--!     Respecting possible signals like 'ready' is recommended.
--!
--!  1. Counter mode: Counter reading (range #next_stim to #last_stim).
--!
--!     In this mode, data packets are irrelevant and the file to be read simply contains
--!     a list of counters or ranges of counters.
--!
--!     To use the file reader in this mode, set #ren to '1' when the external counter is
--!     greater or equal to #last_stim.
--!
--!     If the data is supposed to be output at counts that match the counter indication in
--!     the file, simply an offset of 1 in the external comparison driving #ren can be applied.
--!
--!     The counter_matcher makes use of this mode.
--!
--! Reset behaviour:
--!  - Upon reset, the file is reopened.
--!  - If #ren is set to '1' in the clock cycle before applying #rst = '1', #dout is valid in the clock cycle of the first #rst = '1'.
--!  - In loop mode if #ren is set to '1' in the clock cycle when applying #rst = '1', #dout is valid in the clock cycle after the first #rst = '1'.
--!
--! Default format of the input data file #filename (packet mode):
--!  - #dout data is organised in blocks, each block consists of multiple lines
--!  - a usual data line consists of #wordsperline words
--!    with a constant bit width of #bitsperword each,
--!    a word consists of one or more symbols of size #bitspersymbol
--!  - #bitsperword and #bitspersymbol must be multiples of 4
--!  - allowed data characters are [0-9], [a-f], [A-F], [X,Z]
--!  - the default generics construct #dout of 64 bits:
--!    - grouped in 4 words of 16 bits (4 hex characters) each
--!    - the actual symbol size is 8 bit, hence 1 byte
--!    - Example (default settings): `0123 4567 89AB CDEF`
--!  - the last data line is indicated by #eop and has termination characters #empty and #err:
--!    - #empty is a bit-vector indicating the number of symbols not valid in the
--!      last data line (the default makes it the number of invalid bytes)
--!    - #err is a bit to indicate that the entire packet is invalid
--!      (its purpose is to inject invalid data packets)
--!    - Example of 6 last valid symbols with error (default settings): `DADA DADA DADA XXZZ 010 1`
--!  - a data block must have a preceding line indicating a counter when the
--!    data block is to be injected
--!    - counters must be decimal numbers and in increasing order
--!    - this line is indicated with a #counter_flag (`@` by default)
--!    - Example (default settings): `@42`
--!
--! Optional valid bit to accompany data (valid enabling):
--!  - When #vout_enable is `true`, each line of the input file is expected to contain
--!    a leading '0' or '1' to represent a valid bit #vout to accompany the data #dout in the same line
--!  - The actual data format is as for the packet mode
--!    - Example: `1 0123 4567 89AB CDEF`
--!  - Valid enabling can be combined with packet mode and loop mode
--!
--! Alternative format of the input data file #filename (counter mode):
--!  - #dout, #empty, #eop, #err absent in the file
--!  - A line can indicate a simple (decimal) counter with a #counter_flag (`@` by default)
--!    - Example (default settings): `@42`
--!  - A line can indicate a range of (decimal) counters in the following way
--!    - `counter_flag<counter1>range_flag<counter2>`
--!    - Example (default settings): `@42-45`
--!
--! Comments/ignored lines:
--!  - any line started with the #comment_flag (`%` by default)
--!  - any line shorter than length of a data line
--!  - any empty line
--!
--! Errors:
--!  - A "Text I/O read error" is thrown in case a line cannot be parsed as
--!    valid data.
--!
--! @section FRH_InstTemplate Instantiation template
--!
--! @code{.vhdl}
--! [inst_name]: entity sim.file_reader_hex
--! generic map (
--!   filename      => [string := ""],
--!   comment_flag  => [character := '%'],
--!   counter_flag  => [character := '@'],
--!   range_flag    => [character := '-'],
--!   vout_enable   => [boolean := false],
--!   bitsperword   => [positive := 16],
--!   wordsperline  => [positive := 4],
--!   bitspersymbol => [positive := 8],
--!   debug         => [boolean := false]
--! )
--! port map (
--!   clk       => [in  std_logic],
--!   rst       => [in  std_logic],
--!   ren       => [in  std_logic],
--!   vout      => [out std_logic := '0'],
--!   dout      => [out std_logic_vector(bitsperword*wordsperline-1 downto 0) := (others => '0')],
--!   empty     => [out std_logic_vector(log2ceil(div_ceil(bitsperword*wordsperline,bitspersymbol))-1 downto 0) := (others => '0')],
--!   eop       => [out std_logic := '0'],
--!   err       => [out std_logic := '0'],
--!   next_stim => [out natural := 0],
--!   last_stim => [out natural := 0],
--!   eof       => [out std_logic := '0']
--! );
--! @endcode
-------------------------------------------------------------------------------

entity file_reader_hex is
generic (
  --! Name of the file to read
  filename      : string := "";
  --! @brief Symbol to mark commented lines.
  --! Needs to be the first character of the line.
  comment_flag  : character := '%';
  --! @brief Symbol to indicate the counter (#next_stim) when the following packet shall be read.
  --! Needs to be the first character of the line.
  counter_flag  : character := '@';
  --! @brief Symbol to indicate the range counter (#last_stim) when using in counter mode.
  --! Is the character separating the two counters when indicating a range.
  range_flag    : character := '-';
  --! @brief Enable valid bit output #vout
  --! If enabled, the input data format expects a leading '0' or '1' for each data line.
  vout_enable   : boolean := false;
  --! Input data formatting: how many bits per word (must be a multiple of 4)
  bitsperword   : positive := 16;
  --! Number of words (with constant bit width of #bitsperword) per line
  wordsperline  : positive := 4;
  --! Number of bits per symbol (must be a multiple of 4)
  bitspersymbol : positive := 8;
  --! @brief Enable debug output which informs about file reading activity (verbose!)
  --! @details If debug output is enabled, information is printed on:
  --! - Successfully reading a counter line from file.
  --! - Successfully reading a data line from file.
  --! - Outputting counter (first, new, last).
  --! - Outputting data (from which buffer).
  --!
  --! Note that the end of file is reached before the last line's data is put out:
  --! The last debug message on outputting data is expected **after** reaching EOF.
  debug         : boolean := false
);
port (
  --! Clock
  clk       : in  std_logic;
  --! Reset (synch with #clk): starts reading the file from the beginning again
  rst       : in  std_logic;
  --! Read enable
  ren       : in  std_logic;

  --! Valid indicator
  vout      : out std_logic := '0';
  --! Output data (packet data)
  dout      : out std_logic_vector(bitsperword*wordsperline-1 downto 0) := (others => '0');
  --! Number of empty symbols in last #dout of a packet
  empty     : out std_logic_vector(log2ceil(div_ceil(bitsperword*wordsperline,bitspersymbol))-1 downto 0) := (others => '0');
  --! End of packet indicator
  eop       : out std_logic := '0';
  --! Error indicator
  err       : out std_logic := '0';

  --! Next stimulus (counter)
  next_stim : out natural := 0;
  --! Last stimulus (counter) for range indication
  last_stim : out natural := 0;

  --! End of file
  eof       : out std_logic := '0'
);
end file_reader_hex;

--! Implementation of the file_reader_hex
architecture behavioral of file_reader_hex is
begin
  -- check on the generic settings: bitsperword must be multiple of 4
  assert (bitsperword mod 4) = 0
    report "'bitsperword' must be a multiple of 4, " & integer'image(bitsperword) & " is not!"
    severity failure;

  -- check on the generic settings: bitspersymbol must also be multiple of 4
  assert (bitspersymbol mod 4) = 0
    report "'bitspersymbol' must be a multiple of 4, " & integer'image(bitspersymbol) & " is not!"
    severity failure;

  --! @brief Main reading process
  --!
  --! This process is unclocked since with sensitivity to #clk it would re-open the
  --! file each cycle so use an infinite loop instead.
  --!
  --! Only once having read 2 consecutive lines it is clear what to indicate to the output:
  --!
  --! Reading is continued until either one of the conditions is fulfilled:
  --! | previous line | current line | consequence |
  --! | ------------- | ------------ | ----------- |
  --! | data (2       | data (1)     | data (2) can be output to dout |
  --! | data          | counter      | data can be output to dout, counter indicated to next_stim |
  --! | data          | eof (*)      | data can be output to dout    |
  --! | counter (2    | counter (1)  | indicate counter (2) to next_stim |
  --! | counter       | eof (*)      | indicate counter to next_stim |
  --!
  --! Reading the sequence of (counter, data) or (counter, counter) results in directly outputting
  --! the (first) counter (if it is the overall first counter) and reading is continued until one
  --! of the above conditions is reached.
  --!
  --! (*): These 2 cases are identical to just checking the current line to be EOF.
  proc_readfile : process
    -- file handle
    file cmdfile: TEXT;
    -- File status after opening it
    variable filestatus: FILE_OPEN_STATUS;
    -- Line counter_dataers
    variable line_in: Line;
    -- Status of the read operations
    variable good: boolean;
    -- valid trial to read from file
    variable valid: std_logic;
    -- a line consists of multiple words
    type t_word is array(0 to wordsperline-1) of std_logic_vector(bitsperword-1 downto 0);
    variable word: t_word;
    -- empty trial to read from file
    variable empty_data: std_logic_vector(log2ceil(div_ceil(bitsperword*wordsperline,bitspersymbol))-1 downto 0);
    -- error trial to read from file
    variable err_data: std_logic;
    -- end of file
    variable eof_i: boolean := false;
    -- read space after counter_flag
    variable dummy_data: character;
    -- read counter (after counter_flag)
    variable counter_data: natural;
    -- line counter for error reporting
    variable linecounter: integer := 0;

    -- possible line content: Nothing, data, counter, end of input
    type t_line_conent is (NTG, DAT, CNT, EOI);
    type t_lines is array(2 downto 1) of t_line_conent;
    -- line content of last 2 lines
    variable previous_lines : t_lines := (others => NTG);
    -- array to store data, empty, err, eop and eventually valid
    -- 2 and 1 are buffers and 3 is actual output (chosen to be 2 or 1, depending sequence)
    type t_data is array(3 downto 1) of std_logic_vector(dout'length + empty'length + ite(vout_enable, 2, 1) downto 0);
    variable data : t_data := (others => (others => '0'));
    -- array to store 2 consecutive pairs of counters
    -- pair (4, 3) from previous and (2, 1) from current
    type t_counter is array(4 downto 1) of natural;
    variable counter : t_counter := (others => 0);
    -- flag to indicate if it's the very first counter in the file
    variable first_counter : boolean := true;
  begin

    -- Open the command file for the first time
    FILE_OPEN(filestatus,cmdfile,filename,READ_MODE);
    -- check the file status: if it is not ok, complain with error level
    -- simulator will throw a fatal if it's actually severe, but at least you get a hint here
    case filestatus is
      when NAME_ERROR =>
        assert false report "File '" & filename & "' not found!" severity error;
      when MODE_ERROR =>
        assert false report "Cannot open file '" & filename & "' in READ mode!" severity error;
      when STATUS_ERROR =>
        assert false report "Status error with file '" & filename & "'!" severity error;
      when OPEN_OK =>
        -- "nothing to report"
        null;
    end case;

    -- Overall loop to read entire file
    loop
      -- Reset everything there is to reset to start fresh (start reading the file again!)
      -- we assume(!) that there are no issues with the file in the meantime (not to repeat the entire check ...)
      if rst = '1' then
        FILE_CLOSE(cmdfile);
        FILE_OPEN(cmdfile,filename,READ_MODE);
        eof_i := false;
        linecounter := 0;
        previous_lines := (others => NTG);
        data := (others => (others => '0'));
        counter := (others => 0);
        first_counter := true;
      end if;

      -- First unclocked loop to fill the 2 previous_lines, to read first data or counter
      while not (
        (previous_lines(2) = DAT and previous_lines(1) = DAT) or
        (previous_lines(2) = DAT and previous_lines(1) = CNT) or
--        (previous_lines(2) = DAT and previous_lines(1) = EOI) or (*)
        (previous_lines(2) = CNT and previous_lines(1) = CNT) or
--        (previous_lines(2) = CNT and previous_lines(1) = EOI) or (*)
--      the (*) lines are identical to the shorter one line condition:
        (previous_lines(1) = EOI)
      ) loop
        -- check end of file first, eventually read line
        if not endfile(cmdfile) then
          readline(cmdfile,line_in);
          linecounter := linecounter + 1;

          -- evaluate line content
          if line_in'length > 0 then
            -- check for commented line
            if line_in(line_in'left) = comment_flag then
              -- actually nothing to do
              null;
            -- check for counter line
            elsif line_in(line_in'left) = counter_flag then
              -- read once more to skip space
              read(line_in, dummy_data);
              -- read actual counter
              read(line_in, counter_data, good);
              assert good
                report "Text I/O read error in " & filename & " (line " & integer'image(linecounter) & "): Failed to read counter in line starting with 'counter_flag' (" & counter_flag & ")!"
                severity error;
              -- mark a counter as found
              previous_lines(2) := previous_lines(1);
              previous_lines(1) := CNT;
              -- store counter (shift in)
              counter(4 downto 3) := counter(2 downto 1);
              counter(2 downto 1) := (others => counter_data);
              -- check if range indication is given, then override counter(1)
              if line_in'length > 0 then
                if line_in(line_in'left) = range_flag then
                  -- read once more to skip space
                  read(line_in, dummy_data);
                  -- read actual counter
                  read(line_in, counter_data, good);
                  if good then
                    counter(1) := counter_data;
                  end if;
                end if;
              end if;
              assert not (debug and rst = '0')
                report "Next counter found at line " & integer'image(linecounter)
                severity note;
            -- check for valid data line:
            -- a valid line has at least bpw/4*wpl valid characters and wpl-1 spaces
            elsif line_in'length >= (bitsperword/4 + 1)*wordsperline - 1 then
              -- mark a data as found
              previous_lines(2) := previous_lines(1);
              previous_lines(1) := DAT;
              -- store data (shift in)
              data(2) := data(1);
              assert not (debug and rst = '0')
                report "Next data found at line " & integer'image(linecounter)
                severity note;

              -- once a valid line is found, cast into 'data(1)'
              if line_in'length >= (bitsperword/4 + 1)*wordsperline - 1 then
                -- If in valid mode, attempt to read valid flag
                if vout_enable then
                  read(line_in,valid,good);
                  assert good
                    report "Text I/O read error in " & filename & " (line " & integer'image(linecounter) & "): Failed to read valid bit."
                    severity error;
                  data(1)(data(1)'high) := valid;
                end if;

                -- Read word by word from line and cast as hex values
                for i in wordsperline-1 downto 0 loop
                  hread(line_in,word(i),good);
                  assert good
                    report "Text I/O read error in " & filename & " (line " & integer'image(linecounter) & "): Failed to read data words."
                    severity error;

                  data(1)((i+1)*bitsperword-1 downto i*bitsperword) := word(i);
                end loop;

                -- try to read empty and error flag
                read(line_in,empty_data,good);
                read(line_in,err_data,good);

                -- cast into flags if successfully read
                if good then
                  data(1)(empty'length + 1 + dout'length downto dout'length) := '1' & err_data & empty_data;
                else
                  data(1)(empty'length + 1 + dout'length downto dout'length) := (others => '0');
                end if;

              end if;

            end if;
          end if;

          -- Only at the very beginning, the first counter must be indicated unconditionally.
          -- Later on the counter is updated after the data.
          if first_counter and previous_lines(2) = CNT and (
            previous_lines(1) = DAT or previous_lines(1) = CNT) then
            if previous_lines(1) = DAT then
              next_stim <= counter(2);
              last_stim <= counter(1);
            else
              next_stim <= counter(4);
              last_stim <= counter(3);
            end if;
            -- nullify condition to make sure this is output only once
            first_counter := false;
            assert not debug
              report "Outputting first counter."
              severity note;
            -- remove the counter from the list again to read the next item
            previous_lines(2) := NTG;
          end if;
        else
          -- if the file's end is reached
          FILE_CLOSE(cmdfile);
          -- mark file end as found
          previous_lines(2) := previous_lines(1);
          previous_lines(1) := EOI;
          assert not debug
            report "Reached end of file. " & integer'image(linecounter) & " lines read."
            severity note;
        end if;

      end loop;

      -- When reaching this point, valid data is in the buffers.
      -- Depending what was read, the data or counter is made availble at
      -- clocked cycles to the outside world via ren = '1'.

      wait until clk = '1';

      assert not (debug and rst = '1')
        report "Clock cycle in reset ..."
        severity note;

      -- Now output of actual data/counter is treated based on read enable
      -- Note: Here the internal eof_i is used as this is one clock behind previous_lines(1):
      -- If EOF is reached (in the non-clocked loop above), the actual data has not yet
      -- been output.
      -- It is important to remove the data from the buffer to allow the above non-clocked loop
      -- to fill it again with new data from the next line.
      -- Checking now is to catch an initialisation issue where the first word would possibly be
      -- output while no ren has actually been set (but is initialised to '1' mistakenly)
      if ren = '1' and not eof_i and now > 0 ns then

        -- only if we first read a counter and then something else, we update the indicator
        -- note that the case 2 = CNT and 1 = DAT is already treated in the non-clocked loop
        if (previous_lines(2) = CNT and previous_lines(1) = EOI) then
          next_stim <= counter(2);
          last_stim <= counter(1);
          assert not debug
            report "Outputting last counter."
            severity note;
        elsif (previous_lines(2) = CNT and previous_lines(1) = CNT) then
          assert not debug
            report "Outputting new counter."
            severity note;
          next_stim <= counter(4);
          last_stim <= counter(3);
        end if;

        -- upon 2 successive data fields in the buffer, the second field is to be output
        if (previous_lines(2) = DAT and previous_lines(1) = DAT) then
          data(3) := data(2);
          assert not debug
            report "Outputting data from buffer d2"
            severity note;
        -- upon data followed by counter or EOF, the first field is to be output
        elsif (previous_lines(2) = DAT and previous_lines(1) = CNT) or
          (previous_lines(2) = DAT and previous_lines(1) = EOI) then
          data(3) := data(1);
          assert not debug
            report "Outputting data from buffer d1"
            severity note;
        end if;

        -- upon data followed by a new counter, also the counter must be output
        if (previous_lines(2) = DAT and previous_lines(1) = CNT) then
          assert not debug
            report "Outputting counter from buffer c1 upon data output"
            severity note;
          next_stim <= counter(2);
          last_stim <= counter(1);
          -- and the line buffer must be emptied
          previous_lines(1) := NTG;
        end if;

        -- the line buffer for the data must be emptied
        previous_lines(2) := NTG;

        -- map the temporary buffer (data(3)) to the actual output
        if vout_enable then
          vout <= data(3)(2 + empty'length + dout'length);
        end if;
        dout <= data(3)(dout'length-1 downto 0);
        empty <= data(3)(empty'length-1 + dout'length downto dout'length);
        err <= data(3)(empty'length + dout'length);
        eop <= data(3)(1 + empty'length + dout'length);

        -- indicate end of file to outer world
        if previous_lines(1) = EOI then
          -- and also set internal EOF
          eof_i := true;
          eof <= '1';
        else
          eof <= '0';
        end if;
      end if;

      -- make sure to wait the other half of the clock cycle
      wait until clk = '0';
    end loop;

  end process;

end architecture behavioral;
