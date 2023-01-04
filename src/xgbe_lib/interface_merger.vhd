-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;
--------------------------------------------------------------------------------
--! @file
--! @brief Interface merger for the Avalon streaming interface
--! @author Steffen Stärz <steffen.staerz@cern.ch>
--------------------------------------------------------------------------------
--! @details
--! Generates one output interface from two input interfaces.
--!
--! @todo Derive width of ctrl signals from DATA_W - depends on how many
--! symbols per words there are in the data interface.
--------------------------------------------------------------------------------

--! @cond
library fpga;
  context fpga.interfaces;
--! @endcond

--! Interface merger for the Avalon streaming interface
entity interface_merger is
  generic (
    --! Width of the input data interface
    DATA_W           : integer range 1 to 128 := 64;
    --! Width of the empty indicator of the input data interface
    EMPTY_W          : integer range 1 to 128 := 3;
    --! @brief Enable or disable interface interruption (interface locking)
    --! @details
    --! If true, the second (lower priority) interface will be interrupted
    --! (eop with error) upon start of transmission of the first interface.
    --! If false, the first interface will be halted until the transmission
    --! of the first interface has finished.
    INTERRUPT_ENABLE : boolean                := false;
    --! If true, a one clock idle is generated after each packet.
    GAP_ENABLE       : boolean                := true
  );
  port (
    --! Clock
    clk               : in    std_logic;
    --! Reset, sync with #clk
    rst               : in    std_logic;

    --! @name Avalon-ST from first priority interface
    --! @{

    --! RX ready
    avst1_rx_ready_o  : out   std_logic;
    --! RX data and controls
    avst1_rx_packet_i : in    t_avst_packet(data(DATA_W - 1 downto 0), empty(EMPTY_W - 1 downto 0), error(0 downto 0));
    --! @}

    --! @name Avalon-ST from second priority interface (possibly interrupted)
    --! @{

    --! RX ready
    avst2_rx_ready_o  : out   std_logic;
    --! RX data and controls
    avst2_rx_packet_i : in    t_avst_packet(data(DATA_W - 1 downto 0), empty(EMPTY_W - 1 downto 0), error(0 downto 0));
    --! @}

    --! @name Avalon-ST output interface
    --! @{

    --! TX ready
    avst_tx_ready_i   : in    std_logic;
    --! TX data and controls
    avst_tx_packet_o  : out   t_avst_packet(data(DATA_W - 1 downto 0), empty(EMPTY_W - 1 downto 0), error(0 downto 0));
    --! @}

    --! @brief Status of the module
    --! @details Status of the module
    --! - 2: avst2 is being forwarded
    --! - 1: avst1 is being forwarded
    --! - 0: module in idle
    status_vector_o   : out   std_logic_vector(2 downto 0)
  );
end entity interface_merger;

--! Implementation of the interface merger
architecture behavioral of interface_merger is

  --! @brief State definition for the TX FSM
  --! @details
  --! State definition for the TX FSM
  --! - IDLE:      No transmission running.
  --! - AVST1:     Data from avst1 is being received and transmission is started.
  --! - AVST2:     Data from avst2 is being received and transmission is started.
  --! - INTERRUPT: Data from avst2 is interrupted, sending eop and error flags
  --!              (only used for INTERRUPT_ENABLE is true)
  --! - IGAP:      Insert idle clock after INTERRUPT.
  --!              (only used for GAP_ENABLE is true)
  --! - FGAP:      Insert idle clock after forwarding avst2 (at start with avst1).
  --!              (only used for GAP_ENABLE is true)
  type t_tx_state is (IDLE, AVST1, AVST2, INTERRUPT, IGAP, FGAP);

  --! State of the TX FSM

  -- vsg_disable_next_line signal_007
  signal tx_state : t_tx_state := IDLE;

  --! AVST end of packet
  signal avst_tx_eop : std_logic;
  --! Indicator if avst2 wants to send a packet next
  signal avst2_next  : std_logic;

begin

  -- receiver specific status vector bits:
  status_vector_o(0) <= '1' when tx_state = idle else '0';
  status_vector_o(1) <= '1' when tx_state = avst1 else '0';
  status_vector_o(2) <= '1' when tx_state = avst2 else '0';

  --! TX FSM to handle merging of interfaces
  proc_tx_fsm : process (clk)
  begin
    if rising_edge(clk) then
      if (rst = '1') then
        tx_state <= IDLE;
      else
        if avst_tx_ready_i = '1' then

          case tx_state is

            when IDLE =>
              -- first priority: avst1 interface
              if avst1_rx_packet_i.sop = '1' then
                tx_state <= AVST1;
              -- second priority: avst2  interface
              elsif avst2_rx_packet_i.sop = '1' then
                tx_state <= AVST2;
              else
                tx_state <= IDLE;
              end if;

            when AVST1 =>
              -- once chosen the interface, only quit it upon end_of_packet
              if avst_tx_eop = '1' then
                -- watch out if second interface started transmission simultaneously with first
                -- start_of_packet is then still hold at the register
                if avst2_next = '1' then
                  -- so chose second interface state then directly
                  if GAP_ENABLE then
                    tx_state <= FGAP;
                  else
                    tx_state <= AVST2;
                  end if;
                else
                  tx_state <= IDLE;
                end if;
              else
                tx_state <= AVST1;
              end if;

            when AVST2 =>
              if INTERRUPT_ENABLE then
                -- if interrupt_enable is active:
                -- watch out for first interface and interrupt second if required,
                -- otherwise watch out for end_of_packet of second interface
                if avst1_rx_packet_i.sop = '1' and avst_tx_eop = '0' then
                  tx_state <= INTERRUPT;
                elsif avst_tx_eop = '1' then
                  tx_state <= IDLE;
                else
                  tx_state <= AVST2;
                end if;
              else
                -- if interrupt_enable is inactive:
                -- watch out for end_of_packet of second interface only
                if avst_tx_eop = '1' then
                  tx_state <= IDLE;
                else
                  tx_state <= AVST2;
                end if;
              end if;

            when INTERRUPT =>
              if GAP_ENABLE then
                tx_state <= IGAP;
              else
                tx_state <= AVST1;
              end if;

            when igap =>
              tx_state <= AVST1;

            when fgap =>
              tx_state <= AVST2;

          end case;

        end if;
      end if;
    end if;
  end process proc_tx_fsm;

------------------------------<-    80 chars    ->------------------------------
-- choose upon state machine which interface to be forwarded, based on the
-- registered first words of the rx interfaces
-- also generate the rx_ready signals for the two receiving interfaces
--------------------------------------------------------------------------------
  blk_merge_interfaces : block
    --! Buffer for first word of avst1 interface
    signal avst1_rx_dnc_reg : std_logic_vector(EMPTY_W + 3 + DATA_W downto 0);
    --! Buffer for first word of avst2 interface
    signal avst2_rx_dnc_reg : std_logic_vector(EMPTY_W + 3 + DATA_W downto 0);

    --! Data word to inject when interrupting a transmission (don't care)
    constant DONTCARE_DATA  : std_logic_vector(DATA_W - 1 downto 0) := (others => '-');
    --! Data word controls to inject when interrupting a transmission (eop with error)
    constant INTERRUPT_CTRL : std_logic_vector(EMPTY_W + 3 downto 0) := "1011" & (EMPTY_W - 1 downto 0 => '0');
    --! Data word controls when output interface inactive
    constant IDLE_CTRL      : std_logic_vector(EMPTY_W + 3 downto 0) := (others => '0');

    --! Internal ready signal for avst1
    signal avst1_rx_ready_r : std_logic;
    --! Internal ready signal for avst2
    signal avst2_rx_ready_r : std_logic;
  begin

    --! Buffer first word that each interface wants to transmit
    proc_save_first_words : process (clk)
    begin
      if rising_edge(clk) then
        if (rst = '1') then
          avst1_rx_dnc_reg <= (others => '0');
          avst2_rx_dnc_reg <= (others => '0');
        else
          if avst1_rx_ready_r = '1' then
            avst1_rx_dnc_reg <= avst_ctrl(avst1_rx_packet_i) & avst1_rx_packet_i.data;
          else
            avst1_rx_dnc_reg <= avst1_rx_dnc_reg;
          end if;

          if avst2_rx_ready_r = '1' then
            avst2_rx_dnc_reg <= avst_ctrl(avst2_rx_packet_i) & avst2_rx_packet_i.data;
          else
            avst2_rx_dnc_reg <= avst2_rx_dnc_reg;
          end if;
        end if;
      end if;
    end process proc_save_first_words;

    -- sop decides if there's AVST2 to follow next
    avst2_next <= avst2_rx_dnc_reg(EMPTY_W + 2 + DATA_W) or avst2_rx_packet_i.sop;

    -- if interrupt is disabled, first interface only ready if selected so by TX FSM

    gen_interrupt_off : if not INTERRUPT_ENABLE generate
    begin
      with tx_state select avst1_rx_ready_r <=
        avst_tx_ready_i when IDLE | AVST1,
        '0' when others;
    end generate gen_interrupt_off;

    -- else
    -- if interrupt is enabled, first interface is (almost) always ready

    gen_interrupt_on : if INTERRUPT_ENABLE generate
    begin
      with tx_state select avst1_rx_ready_r <=
        '0' when INTERRUPT | IGAP,
        avst_tx_ready_i when others;
    end generate gen_interrupt_on;

    avst1_rx_ready_o <= avst1_rx_ready_r;

    -- second interface is only ready if selected so by TX FSM
    with tx_state select avst2_rx_ready_r <=
      avst_tx_ready_i when IDLE | AVST2,
      '0' when others;

    avst2_rx_ready_o <= avst2_rx_ready_r;

    -- finally create the tx interface from previously set signals
    blk_avst_tx_interface : block
      --! Combination of controls and data to be sent out
      signal avst_tx_dnc : std_logic_vector(EMPTY_W + 3 + DATA_W downto 0);
    begin

      -- mux the data and control:
      with tx_state select avst_tx_dnc <=
        avst1_rx_dnc_reg when AVST1,
        avst2_rx_dnc_reg when AVST2,
        INTERRUPT_CTRL & DONTCARE_DATA when INTERRUPT,
        IDLE_CTRL & DONTCARE_DATA when others;

      avst_tx_packet_o <= (
        data  => avst_tx_dnc(DATA_W - 1 downto 0),
        valid => avst_tx_dnc(EMPTY_W - 1 + DATA_W + 4),
        sop   => avst_tx_dnc(EMPTY_W - 1 + DATA_W + 3),
        eop   => avst_tx_dnc(EMPTY_W - 1 + DATA_W + 2),
        error => avst_tx_dnc(EMPTY_W - 1 + DATA_W + 1 downto EMPTY_W - 1 + DATA_W + 1),
        empty => avst_tx_dnc(EMPTY_W - 1 + DATA_W downto DATA_W)
      );

      -- extract the eop (used in the TX FSM)
      avst_tx_eop <= avst_tx_dnc(EMPTY_W - 1 + DATA_W + 2);

    end block blk_avst_tx_interface;

  end block blk_merge_interfaces;

end architecture behavioral;
