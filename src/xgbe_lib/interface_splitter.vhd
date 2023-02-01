-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Interface splitter for the Avalon streaming interface
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details
--! Fans out one RX interface to multiple TX interfaces multiplexing the
--! respective ready signal of the different end receivers.
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Interface splitter for the Avalon streaming interface
entity interface_splitter is
  generic (
    -- List of ports to be used for multiplexing (position relates to position in ready_i)
    -- Must be of positive range! (slot "0" is default and not part of this list)
    PORT_LIST     : t_slv_vector;
    --! Positional offset of where to find the port information in the avst_rx_packet_i.data word
    DATA_W_OFFSET : natural
  );
  port (
    --! Clock
    clk              : in    std_logic;
    --! Reset, sync with #clk
    rst              : in    std_logic;

    --! @name Avalon-ST input to be multiplexed
    --! @{

    --! RX ready
    avst_rx_ready_o  : out   std_logic;
    --! RX data and controls
    avst_rx_packet_i : in    t_avst_packet;
    --! @}

    --! @name Avalon-ST output interface
    --! @{

    --! TX ready
    avst_tx_readys_i : in    std_logic_vector(PORT_LIST'high downto PORT_LIST'low - 1);
    --! TX data and controls (all RX interfaces can be connected to this interface)
    avst_tx_packet_o : out   t_avst_packet;
    --! @}

    --! @brief Status of the module
    --! @details Status of the module
    --! - i (i in range of PORT_LIST): Multiplexing i-th interface (as given by PORT_LIST)
    --! - "0": Multiplexing default interface
    status_vector_o  : out   std_logic_vector(PORT_LIST'high downto PORT_LIST'low - 1)
  );
end entity interface_splitter;

--! Implementation of the interface splitter
architecture behavioral of interface_splitter is

  --! @brief State definition for the RX FSM
  --! @details
  --! State definition for the RX FSM
  --!  HEADER: analysing input data for port indicator
  --!  MUX:    packet forwarding (and non-default ready multiplexer selected)
  type t_rx_state is (HEADER, MUX);
  --! State of the RX FSM
  -- vsg_disable_next_line signal_007
  signal rx_state : t_rx_state := HEADER;

  --! Bit mask to indicate with port has been selected for multiplexing
  signal rx_mux   : std_logic_vector(PORT_LIST'range);
  --! Actual rx_ready signal indicated to outside world
  signal rx_ready : std_logic;

  --! Helper signal to identify significant part of avst_rx_packet_i.data
  signal first_port : std_logic_vector(PORT_LIST(PORT_LIST'low)'range);
  --! Actual significant part of avst_rx_packet_i.data to identify port
  signal port_info  : std_logic_vector(PORT_LIST(PORT_LIST'low)'range);

begin

  status_vector_o(PORT_LIST'high downto PORT_LIST'low) <= rx_mux;

  status_vector_o(PORT_LIST'low - 1) <= '0' when rx_state = MUX else '1';

  --! receiver is ready when data can be forwarded to the selected port
  --! @todo Maybe even more save when implementing that in a function
  proc_select_interface : process (rx_mux, avst_tx_readys_i)
  begin
    -- default: take the lowest interface's indication
    rx_ready <= avst_tx_readys_i(avst_tx_readys_i'low);
    -- loop over all other possible interfaces
    for i in PORT_LIST'range loop
      -- to find a matching one
      if rx_mux(i) = '1' then
        rx_ready <= avst_tx_readys_i(i);
      end if;
    end loop;
  end process proc_select_interface;

  first_port <= PORT_LIST(PORT_LIST'low);
  port_info  <= avst_rx_packet_i.data(first_port'high + DATA_W_OFFSET downto first_port'low + DATA_W_OFFSET);

  --! RX FSM to handle multiplexing of interfaces
  proc_rx_fsm : process (clk)
  begin
    if rising_edge(clk) then
      -- reset (but not at sop as that's needed to be analysed!)
      if (rst = '1') then
        rx_state <= HEADER;
        rx_mux   <= (others => '0');
      elsif rx_ready = '1' then

        case rx_state is

          -- check header data
          when HEADER =>

            if avst_rx_packet_i.sop = '1' then
              -- default:
              rx_mux <= (others => '0');

              for i in PORT_LIST'range loop
                if port_info = PORT_LIST(i) then
                  -- overwrite rx_mux and rx_state:
                  rx_mux(i) <= '1';
                  rx_state  <= MUX;
                end if;
              end loop;
            else
              rx_state <= HEADER;
            end if;

          -- stay in RX mode until the end of the packet
          when MUX =>
            if avst_rx_packet_i.eop = '1' then
              rx_mux   <= (others => '0');
              rx_state <= HEADER;
            else
              rx_state <= MUX;
            end if;

        end case;

      end if;
    end if;
  end process proc_rx_fsm;

  avst_tx_packet_o <= avst_rx_packet_i;

  avst_rx_ready_o <= rx_ready;

end architecture behavioral;
