-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief File writer for hex data to a file of hex values (in ASCII strings)
--! @details See the file_reader_hex for the description of the format of the
--! file that is written to.
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--! @brief File writer for hex data.
--!
--! @details Writes (hex value) data to a file (in ASCII strings).
--!
--! Inverse functionality as file_reader_hex.
--!
--! Format of the output data file #filename:
--!  - #din is the correspondence of file_reader_hex#dout and organised in the
--!    same way (#wordsperline words of #bitsperword bit each)
--!  - the last data line is indicated via #eop and termination characters
--!    #empty and #err are written to the file
--!  - optionally, data blocks can be preceded with a line indicating a #cnt
--!    by raising #cnt_wren
--!  - optionally, data blocks can be preceded with a #comment
--!    by raising #cmt_wren
--!  - #wren, #cnt_wren and #cmt_wren can be risen simultaneously, the order in
--!    the output file #filename is
--!    -# #cnt
--!    -# #comment
--!    -# #din
--!
--! End of file writing:
--!
--! The end of file writing can be indicated by #eof. This ultimately closes
--! the file #filename. A consecutive #rst does NOT reopen the file for writing.
--! This final closing is usually not necessary as the simulation tool will do
--! it automatically when closing the simulation.
--!
--! Errors:
--! - An error is thrown when a #cnt is aimed to be written while a packet
--!   is not yet finished (by #eop).
--!
--! @section FWH_InstTemplate Instantiation template
--!
--! @code{.vhdl}
--! [inst_name]: entity sim.file_writer_hex
--! generic map (
--!   filename      => [string := ""],
--!   comment_flag  => [character := '%'],
--!   counter_flag  => [character := '@'],
--!   reset_append  => [boolean := true],
--!   log_eop       => [boolean := true],
--!   bitsperword   => [positive := 16],
--!   wordsperline  => [positive := 4],
--!   bitspersymbol => [positive := 8]
--! )
--! port map (
--!   clk           => [std_logic],
--!   rst           => [std_logic],
--!   wren          => [std_logic],
--!   din           => [std_logic_vector(bitsperword*wordsperline-1 downto 0) := (others => '0')],
--!   empty         => [std_logic_vector(log2ceil(div_ceil(bitsperword*wordsperline,bitspersymbol))-1 downto 0) := (others => '0')],
--!   eop           => [std_logic := '0'],
--!   err           => [std_logic := '0'],
--!   cmt_wren      => [std_logic := '0'],
--!   comment       => [string := ""],
--!   cnt_wren      => [std_logic := '0'],
--!   cnt           => [natural := 0],
--!   eof           => [std_logic := '0']
--! );
--! @endcode
--------------------------------------------------------------------------------

--! @cond
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all;
-- used for empty bits calculation:
library PoC;
use PoC.utils.all;
--! @endcond

entity file_writer_hex is
generic (
  --! Name of the file to read.
  filename      : string := "";
  --! Symbol to indicate a #comment line.
  comment_flag  : character := '%';
  --! Symbol to indicate the #cnt when the packet was started.
  counter_flag  : character := '@';
  --! Behaviour upon #rst: Re-open (overwrite existing) file or append data.
  reset_append  : boolean := true;
  --! End of packet behaviour: write (simulation) time of end as comment to file or not.
  log_eop       : boolean := true;
  --! Input data formatting: how many bits per word (must be a multiple of 4).
  bitsperword   : positive := 16;
  --! Number of words (with constant bit width of #bitsperword) per line.
  wordsperline  : positive := 4;
  --! Number of bits per symbol (must be a multiple of 4).
  bitspersymbol : positive := 8
);
port (
  --! clock
  clk       : in  std_logic;
  --! reset (synch with clk): starts writing to the file again (overwriting or appending, as set by #reset_append)
  rst       : in  std_logic;
  --! write enable (for #din)
  wren      : in  std_logic;
  --! input data
  din       : in  std_logic_vector(bitsperword*wordsperline-1 downto 0) := (others => '0');
  --! number of empty symbols in last #din of a packet:
  empty     : in  std_logic_vector(log2ceil(div_ceil(bitsperword*wordsperline,bitspersymbol))-1 downto 0) := (others => '0');
  --! end of packet
  eop       : in  std_logic := '0';
  --! error indicator
  err       : in  std_logic := '0';

  --! optional: write enable for #comment
  cmt_wren  : in  std_logic := '0';
  --! optional: actual comment text (without #comment_flag)
  comment   : in  string := "";

  --! optional: write enable for #cnt
  cnt_wren  : in  std_logic := '0';
  --! optional: counter (meant at the beginning when starting to write a packet to file)
  cnt       : in  natural := 0;

  --! optional: end of file (= end of simulation to properly close file at the end)
  eof       : in  std_logic := '0'
);
end file_writer_hex;

--! Implementation of the file_writer_hex
architecture behavioral of file_writer_hex is
begin
  assert bitsperword mod 4 = 0
    report "Generic 'bitsperword' must be multiple of 4!"
    severity failure;

--! @brief Main writing process:
--! Unclocked since with sensitivity to clk it would re-open the file each cycle
--! so use an infinite loop instead that is broken by #eof
  proc_writecmd : process
    -- file handle
    file cmdfile: TEXT;
    -- Line buffer
    variable line_out: Line;
    -- counter of packets
    variable packet_counter: natural := 0;
    -- counter of counter (to check invalid input)
    variable counter_counter: natural := 0;
  begin
    -- Open the command file for the first time
    FILE_OPEN(cmdfile,filename,WRITE_MODE);
    report "Overwriting file '" & filename & "'";

    loop
      wait until clk = '1';

      -- reset handling
      if rst = '1' then
        FILE_CLOSE(cmdfile);
        if reset_append then
          report "Reset: Appending data to file '" & filename & "'";
          FILE_OPEN(cmdfile,filename,APPEND_MODE);
        else
          packet_counter := 0;
          report "Reset: Re-opening file '" & filename & "' and overwriting";
          FILE_OPEN(cmdfile,filename,WRITE_MODE);
        end if;
      else
        -- handling of counters (can be in same clk as data)
        if cnt_wren = '1' then
          if counter_counter <= packet_counter then
            write(line_out, counter_flag);
            write(line_out, ' ');
            write(line_out, integer'image(cnt));
            writeline(cmdfile, line_out);
            counter_counter := counter_counter + 1;
          else
            report "Provided new counter while packet " & integer'image(packet_counter) & " is not finished.";
            report " Not writing counter to file!"
            severity error;
          end if;
        end if;

        -- handling of comments (can be in same clk as data)
        if cmt_wren = '1' then
          write(line_out, comment_flag);
          write(line_out, ' ');
          write(line_out, comment);
          writeline(cmdfile, line_out);
        end if;

        -- handling of writing of input data din
        if wren = '1' then
          for i in wordsperline-1 downto 0 loop
            -- write data
            hwrite(line_out, din((i+1)*bitsperword-1 downto i*bitsperword));
            if i /= 0 then
              -- write data separator (space)
              write(line_out, ' ');
            end if;
          end loop;

          -- on last frame, also write end frame flags
          if eop = '1' then
            packet_counter := packet_counter + 1;
            write(line_out, ' ');
            for i in empty'left downto 0 loop
              write(line_out, empty(i));
            end loop;
            write(line_out, ' ');
            write(line_out, err);
          end if;

          -- Finally actually write the line to the file
          writeline(cmdfile, line_out);

          -- do some reporting (and optionally writing to the file)
          if eop = '1' then
            report "Packet number " & integer'image(packet_counter) & " written to file.";
            if log_eop then
              -- add comment about arriving time of the (end of) packet:
              write(line_out, comment_flag);
              write(line_out, " Packet number " & integer'image(packet_counter) & " ended at time " & time'image(now));
              writeline(cmdfile, line_out);
            end if;
            -- add empty line to separate packets
            writeline(cmdfile, line_out);
          end if;
        end if;

        -- handling end of simulation
        if eof = '1' then
          -- exit loop to finally close file
          exit;
        end if;
      end if;
    end loop;

    -- finally close file
    FILE_CLOSE(cmdfile);
    wait;
  end process;

end architecture behavioral;
