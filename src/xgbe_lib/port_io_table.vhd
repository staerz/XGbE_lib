-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Port I/O Table (storing pairs of associated ports)
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details
--! Stores entries as a pair of two ports to a table via a 'disco' interface.
--! Existing entries are updated.
--!
--! Provides the corresponding output port to a given input port
--! using the 'reco' interface with confirmation.
--------------------------------------------------------------------------------

--! @cond
library IEEE;
  use IEEE.std_logic_1164.all;
--! @endcond

--! Port I/O Table (storing pairs of associated ports)
entity port_io_table is
  generic (
    --! Width of the port to be associated
    PORT_I_W    : integer range 1 to 64   := 32;
    --! Width of the associated port
    PORT_O_W    : integer range 1 to 64   := 48;
    --! Depth of the table
    TABLE_DEPTH : integer range 1 to 1024 := 4
  );
  port (
    --! Clock
    clk             : in    std_logic;
    --! Reset, sync with #clk
    rst             : in    std_logic;

    --! @name Discovery interface for writing pair of associated addresses/ports
    --! @{

    --! Discovery write enable
    disco_wren_i    : in    std_logic;
    --! Discovery input port
    disco_port_i    : in    std_logic_vector(PORT_I_W - 1 downto 0);
    --! Discovery output port
    disco_port_o    : in    std_logic_vector(PORT_O_W - 1 downto 0);
    --! @}

    --! @name Recovery interface for reading pair of associated addresses/ports
    --! @{

    --! Recovery read enable
    reco_en_i       : in    std_logic;
    --! Recovery input port
    reco_port_i     : in    std_logic_vector(PORT_I_W - 1 downto 0);
    --! Recovery output port (response next clk cycle)
    reco_port_o     : out   std_logic_vector(PORT_O_W - 1 downto 0);
    --! Recovery success indicator
    reco_found_o    : out   std_logic;
    --! @}
    --! @brief Status of the module
    --! @details Status of the module
    --! - 1: table full
    --! - 0: table empty
    --!
    --! One could make the move to indicate the number of occupied entries instead...
    --! That would make #status_vector_o a #TABLE_DEPTH-dependent length vector.
    status_vector_o : out   std_logic_vector(1 downto 0)
  );
end entity port_io_table;

--! @cond
library IEEE;
  use IEEE.numeric_std.all;
--! @endcond

--! Implementation of the port_io_table
architecture behavioral of port_io_table is

  --! Type definition for table to store port pair in one entry
  type t_port_io_table_data is array(TABLE_DEPTH downto 1) of std_logic_vector((PORT_I_W + PORT_O_W - 1) downto 0);

  --! Table to store port pair in one entry

  -- vsg_disable_next_line signal_007
  signal port_io_table_data : t_port_io_table_data := (others => (others => '0'));

  --! Recovery function to find pout in #port_io_table_data

  impure function find_pout_in_port_io_table (inport : std_logic_vector(PORT_I_W - 1 downto 0)) return natural is
  begin

    -- we must catch the Is_X in a stand-alone if statement
    if Is_X(inport) then
      return 0;
    elsif unsigned('0' & inport) = 0 then
      return 0;
    end if;
    for i in port_io_table_data'range loop
      if port_io_table_data(i)(PORT_I_W - 1 downto 0) = inport then
        return i;
      end if;
    end loop;

    return 0;

  end;

begin

------------------------------<-    80 chars    ->------------------------------
--! Handling of incoming data
--------------------------------------------------------------------------------
  blk_write : block
    --! Internal pointer of current write address of table

    -- vsg_disable_next_line signal_007
    signal write_address : integer range 1 to TABLE_DEPTH := 1;
    --! Internal pointer to entry with pin to discover
    signal old_address   : integer range 0 to TABLE_DEPTH;
  begin

    -- check if discovered pin is already stored in table
    old_address <= find_pout_in_port_io_table(disco_port_i);

    proc_table_fill : process (clk)
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          port_io_table_data <= (others => (others => '0'));
          write_address      <= 1;
          status_vector_o(1) <= '0';
          status_vector_o(0) <= '1';
        else
          if disco_wren_i = '1' then
            if old_address /= 0 then
              -- data already found in table: update entry
              port_io_table_data(old_address) <= disco_port_o & disco_port_i;
            else
              -- otherwise add as new entry
              port_io_table_data(write_address) <= disco_port_o & disco_port_i;
              if write_address = TABLE_DEPTH then
                status_vector_o(1) <= '1';
                write_address      <= 1;
              else
                write_address <= write_address + 1;
              end if;
            end if;

            status_vector_o(0) <= '0';
          end if;
        end if;
      end if;
    end process proc_table_fill;

  end block blk_write;

  --! Handling of port recovery: find corresponding out port to requested in port
  proc_table_read : process (clk)
    variable read_address : natural range 0 to TABLE_DEPTH;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        reco_port_o  <= (others => '0');
        reco_found_o <= '0';
      else
        read_address := find_pout_in_port_io_table(reco_port_i);

        -- default:
        reco_port_o  <= (others => '0');
        reco_found_o <= '0';
        if reco_en_i = '1' then
          if read_address /= 0 then
            reco_port_o  <= port_io_table_data(read_address)(PORT_I_W + PORT_O_W - 1 downto PORT_I_W);
            reco_found_o <= '1';
          end if;
        end if;
      end if;
    end if;
  end process proc_table_read;

end architecture behavioral;
