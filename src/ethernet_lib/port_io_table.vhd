-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
-------------------------------------------------------------------------------
--! @file
--! @brief Port I/O Table (storing pairs of associated ports)
--! @author Steffen Stärz <steffen.staerz@cern.ch>
-------------------------------------------------------------------------------
--! @details
--! Stores entries as a pair of two ports to a table via a 'disco' interface.
--! Existing entries are updated.
--!
--! Provides the corresponding output port to a given input port
--! using the 'reco' interface with confirmation.
-------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.STD_LOGIC_1164.all;
--! @endcond

--! Port I/O Table (storing pairs of associated ports)
entity port_io_table is
  generic (
    --! Width of the port to be associated
    PIN_WIDTH    : integer range 1 to 64   := 32;
    --! Width of the associated port
    POUT_WIDTH   : integer range 1 to 64   := 48;
    --! Depth of the table
    TABLE_DEPTH  : integer range 1 to 1024 := 4
  );
  port (
    --! Clock
    clk           : in    std_logic;
    --! Reset, sync with #clk
    rst           : in    std_logic;

    --! @name Discovery interface for writing pair of associated addresses/ports
    --! @{

    --! Discovery write enable
    disco_wren     : in    std_logic;
    --! Discovery input port
    disco_pin      : in    std_logic_vector(PIN_WIDTH-1 downto 0);
    --! Discovery output port
    disco_pout     : in    std_logic_vector(POUT_WIDTH-1 downto 0);
    --! @}

    --! @name Recovery interface for reading pair of associated addresses/ports
    --! @{

    --! Recovery read enable
    reco_en        : in    std_logic;
    --! Recovery input port
    reco_pin       : in    std_logic_vector(PIN_WIDTH-1 downto 0);
    --! Recovery output port (response next clk cycle)
    reco_pout      : out   std_logic_vector(POUT_WIDTH-1 downto 0);
    --! Recovery success indicator
    reco_found     : out   std_logic;
    --! @}
    --! @brief Status of the portIO_table
    --! @details Status of the portIO_table
    --! - 1: table full
    --! - 0: table empty
    --!
    --! One could make the move to indicate the number of occupied entries instead...
    --! That would make #status_vector a #TABLE_DEPTH-dependent length vector.
    status_vector    : out   std_logic_vector(1 downto 0)
  );
end port_io_table;

--! @cond
library IEEE;
  use IEEE.numeric_std.all;
--! @endcond

--! Implementation of the port_io_table
architecture behavioral of port_io_table is

  --! Type definition for table to store port pair in one entry
  type   port_io_table_data_t is array(TABLE_DEPTH downto 1) of std_logic_vector((PIN_WIDTH+POUT_WIDTH-1) downto 0);
  --! Table to store port pair in one entry
  signal port_io_table_data : port_io_table_data_t := (others => (others => '0'));

  --! Recovery function to find pout in #port_io_table_data

  impure function find_pout_in_port_io_table(inport : std_logic_vector(PIN_WIDTH-1 downto 0)) return natural is
  begin
    if unsigned('0' & inport) = 0 then
      return 0;
    end if;
    for i in port_io_table_data'range loop
      if port_io_table_data(i)(PIN_WIDTH-1 downto 0) = inport then
        return i;
      end if;
    end loop;

    return 0;
  end;

begin

------------------------------  <-  80 chars  ->  ------------------------------
--! Handling of incoming data
--------------------------------------------------------------------------------
  write_block: block
    --! Internal pointer of current write address of table
    signal write_address  : integer range 1 to TABLE_DEPTH := 1;
    --! Internal pointer to entry with pin to discover
    signal old_address    : integer range 0 to TABLE_DEPTH := 1;
  begin
    -- check if discovered pin is already stored in table
    old_address <= find_pout_in_port_io_table(disco_pin);

    proc_table_fill : process (clk) is
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          port_io_table_data <= (others => (others => '0'));
          write_address      <= 1;
          status_vector(1)   <= '0';
          status_vector(0)   <= '1';
        else
          if disco_wren = '1' then
            if old_address /= 0 then
              -- data already found in table: update entry
              port_io_table_data(old_address) <= disco_pout & disco_pin;
            else
              -- otherwise add as new entry
              port_io_table_data(write_address) <= disco_pout & disco_pin;
              if write_address = TABLE_DEPTH then
                status_vector(1) <= '1';
                write_address    <= 1;
              else
                write_address <= write_address + 1;
              end if;
            end if;

            status_vector(0) <= '0';
          end if;
        end if;
      end if;
    end process;

  end block;

  --! Handling of port recovery: find corresponding out port to requested in port
  proc_table_read : process (clk) is
    variable read_address : natural range 0 to TABLE_DEPTH := 1;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        reco_pout  <= (others => '0');
        reco_found <= '0';
      else
        read_address := find_pout_in_port_io_table(reco_pin);

        -- default:
        reco_pout  <= (others => '0');
        reco_found <= '0';
        if reco_en = '1' then
          if read_address /= 0 then
            reco_pout  <= port_io_table_data(read_address)(PIN_WIDTH+POUT_WIDTH-1 downto PIN_WIDTH);
            reco_found <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

end behavioral;
