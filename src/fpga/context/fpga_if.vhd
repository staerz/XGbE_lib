-- EMACS settings: -*- tab-width: 2; indent-tabs-mode: nil -*-
-- vim: tabstop=2:shiftwidth=2:expandtab
-- kate: tab-width 2; replace-tabs on; indent-width 2;

------------------------------<-    80 chars    ->------------------------------
--! @file
--! @brief Global interface definition
--! @authors Philipp Horn <philipp.horn@cern.ch>
--! @authors Steffen Stärz <steffen.staerz@cern.ch>
--!
--! This file contains the global interface definitions.
--!
--! # Records
--!
--! For an efficient and compact interface definitions, records are used.
--! Following <a href="https://www.gaisler.com/doc/vhdl2proc.pdf">
--! general VHDL standard recommendations for records</a>,
--! clock signals are explicitly **NOT** incorporated in a record:
--!
--! "If the clock was included in a record type, the assignment to the record
--! field would create a delta delay, skewing that part of the clock tree."
--!
--! Furthermore, signal directions are not mixed within a record.
--! @todo Doxygen 1.8.20 doesn't like the code environments anymore and hence
--! some sections disappeared - replaced by verbatim environment!
--------------------------------------------------------------------------------

--! @brief Package defining global data types.
--! @details This packages contains the definitions of global data types.
--! @bug Doxygen doesn't find the description of the package
--! if it's AFTER the library clause.

--! @cond
library IEEE;
  context IEEE.IEEE_STD_CONTEXT;
--! @endcond

package fpga_if is

------------------------------<-    80 chars    ->------------------------------
--! @name Vector Types
--! @bug Doxygen doesn't properly document the individual elements of the group.
--! @brief Generic vectors of predefined types.
--!
--! VHDL-2008 adds a number of new predefined array types as follows:
--!
--! @verbatim
--!  type boolean_vector is array (natural range <>) of boolean
--!  type integer_vector is array (natural range <>) of integer
--!  type real_vector is array (natural range <>) of real
--!  type time_vector is array (natural range <>) of time
--! @endverbatim
--!
--! It does though not introduce arrays of bit-vector-based types as
--! `std_logic_vector` and arrays of strings.
--!
--! Hence we introduce these array types here.
--!
--! Note that the naming convention adds a prefix `t_` to clearly distinguish custom-defined
--! vector types from VHDL(-2008) defined vector types.
--!
--! By default and as VHDL-2008 allows it, these array types are of unconstrained size in both dimensions.
--! To properly instantiate them, both dimensions must be constrained, e.g.
--! @verbatim
--!  signal slv_vector : t_slv_vector(WIDTH_DIM_A - 1 downto 0)(WIDTH_DIM_B - 1 downto 0);
--! @endverbatim
--------------------------------------------------------------------------------

  --! The types introduced are here:
  --! @{
  type t_slv_vector is array (natural range <>) of std_logic_vector;

  type t_signed_vector is array (natural range <>) of signed;

  type t_unsigned_vector is array (natural range <>) of unsigned;

  --! The actual size of the array is selected upon initialization, e.g.
  --! @verbatim
  --!  constant MY_STRING_ARR : t_string_vector(2 downto 0) :=
  --!  (
  --!    "first string",
  --!    "another string",
  --!    "yet another string"
  --!  );
  --! @endverbatim
  type t_string_vector is array (natural range <>) of string;

  --! @}
  --! @name Matrix Types
  --! @{

  --! Additionally, matrices of for the previously defined vector types are introduced:
  type t_slv_matrix is array (natural range <>) of t_slv_vector;

  type t_signed_matrix is array (natural range <>) of t_signed_vector;

  type t_unsigned_matrix is array (natural range <>) of t_unsigned_vector;

  type t_string_matrix is array (natural range <>) of t_string_vector;
  --! @}

------------------------------<-    80 chars    ->------------------------------
--! @page AVST AVST: Avalon Streaming Interface
--!
--! The Avalon Streaming Interface (AVST) is fully defined in the
--! <a href="https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/manual/mnl_avalon_spec.pdf">Avalon Interface Specifications</a>.
--!
--! To simplify the usage of the multitude of signals of the AVST interface,
--! dedicated records are defined to group them.
--! For the sake of unidirectional interfaces, these records are split
--! into data transfer direction (source-to-sink) and the back-pressure
--! indication direction (sink-to-source).
--!
--! @section sourcetosink Source to Sink
--!
--! A set of AVST interface variants of the source-to-sink
--! direction is defined:
--!  - @link t_avst_stream @endlink: A stream-type variant for continuous data flow.
--!  - @link t_avst_strobe @endlink: A strobe-type variant for continuous data flow with updates not every clock cycle.
--!  - @link t_avst_packet @endlink: A packet-type variant for packet-based data flow.
--!
--! These interfaces carry the data together with dedicated control signals.
--!
--! Compact interface types that combine multiple AVST interfaces into a single
--! one to transport data of multiple channels in parallel are also defined,
--! as arrays of the respective single interfaces:
--!  - @link t_avst_streams @endlink: Multiple stream-type AVST interface for continuous data flow.
--!  - @link t_avst_strobes @endlink: Multiple strobe-type AVST interface for continuous data flow
--!    with updates not every clock cycle.
--!  - @link t_avst_packets @endlink: Multiple packet-type AVST interface for packet-based data flow.
--!
--! The multiplicity, or the number of data channels, is an positive number that
--! is chosen when instantiating this interface.
--!
--! Note that although multiple @link t_avst_stream @endlink
--! (and @link t_avst_packet @endlink respectively) are grouped
--! together, their respective signals remain entirely independent.
--! That is, even if they might be driven by the same clock, their respective
--! data (and all other signals) do not necessarily need to be aligned in time.
--!
--! Refer to the linked types for more details on their full definition.
--!
--! @section sinktosource Sink to Source
--! Back-pressure allows a sink to signal a source to stop sending data.
--! Support for back-pressure is optional.
--!
--! Back-pressure is indicated by a 1-bit 'ready' signal:
--! Asserts high to indicate that the sink can accept data.
--! 'ready' is asserted by the sink on cycle n to mark cycle n as a ready cycle.
--! The source may only assert 'valid' and transfer data during ready cycles.
--! Sources without a 'ready' input do not support back-pressure.
--! Sinks without a 'ready' output never need to back-pressure.
--!
--! @section avstwaveforms Source to sink data transmission using the AVST (stream and packet) interface
--! In the following the transmission via an @link t_avst_packet @endlink and
--! via an @link t_avst_stream @endlink interface are given.
--!
--! For the packet-type interface the source must respect the ready signal of the sink.
--! @image latex avst_packet.pdf "AVST packet transaction. Note that the transaction is paused twice by the sink by de-asserting ready and once by the source by de-asserting valid." height=9\wdline
--!
--! For the stream-type and strobe-type interfaces actual data is transmitted
--! every clock cycle while the valid signal is asserted.
--! Data transfer can be interrupted by the source by temporarily de-asserting valid.
--! Optionally, back-pressure is indicated by the sink by temporarily de-asserting ready to pause data transfer.
--! @image latex avst_stream.pdf "AVST interface: stream-type variant transaction. Note that the data transfer is interrupted by the source for 2 cycle by de-asserting valid. Ready of the sink is not shown." height=5\wdline
--!
--! @section avstconstraints Naming convention for constraining the AVST interface
--! The AVST interface contains up to 3 elements of type `std_logic_vector`
--! which need to be constrained upon instantiation.
--!
--! The following naming convention is used:
--!
--! <table>
--! <caption id="avst_constraints">Naming convention for constraining the AVST interface</caption>
--! <tr><th> Element </th><th> Constant                  </th><th> Comment       </th>
--!   <th> Example                        </th></tr>
--! <tr><td> `data`  </td><td> `G_<interface>_{T|R}XD_W` </td><td> `D` for data  </td>
--!   <td> `data(G_IF_TXD_W - 1 downto 0)`  </td></tr>
--! <tr><td> `empty` </td><td> `G_<interface>_{T|R}XE_W` </td><td> `E` for empty </td>
--!   <td> `empty(G_IF_RXE_W - 1 downto 0)` </td></tr>
--! <tr><td> `error` </td><td> `G_<interface>_{T|R}XX_W` </td><td> `X` for error </td>
--!   <td> `error(G_IF_TXX_W - 1 downto 0)` </td></tr>
--! </table>
--!
--! The interface direction in indicated by the `RX` (Receive) or `TX` (Transmit) characters.
--! The characters `IF` are place holders for the actual (short) interface name, e.g. `GBE`, `XGBE`, etc.
--!
--! @section avstexamples Instantiation examples of the AVST interface
--! The following sections give a few instantiation examples.
--!
--! In all examples the `DATA_W` is used to constraint the actual width of
--! the data bus of the AVST interface via the `data(DATA_W - 1 downto 0)` indication.
--! `DATA_W` itself is of type <b>natural ranging from 1 to 4096</b>.
--!
--! @subsection avststreamport AVST stream-types in port definition
--!
--! @verbatim
--!   port (
--!     clk           : in  std_logic;
--!     avst_ready    : out std_logic;
--!     avst_stream   : in  t_avst_stream(data(DATA_W - 1 downto 0));
--!     ...
--!   );
--! @endverbatim
--!
--! @subsection avststrobeport AVST strobe-types in port definition
--!
--! @verbatim
--!   port (
--!     clk           : in  std_logic;
--!     avst_ready    : out std_logic;
--!     avst_strobe   : in  t_avst_strobe(data(DATA_W - 1 downto 0));
--!     ...
--!   );
--! @endverbatim
--!
--! @subsection avststreamsinport multiple AVST stream-type in port definition
--!
--! @verbatim
--!   port (
--!     clk           : in  std_logic;
--!     avst_streams  : in  t_avst_streams(AVST_STREAMS - 1 downto 0)(data(DATA_W - 1 downto 0));
--!     ...
--!   );
--! @endverbatim
--! Note that `AVST_STREAMS` is the number of AVST streams instantiated.
--!
--! @subsection avstpacketinport AVST packet-type in port definition
--!
--! @verbatim
--!   port (
--!     clk           : in  std_logic;
--!     avst_ready    : in  std_logic;
--!     avst_packet   : out t_avst_packet(data(DATA_W - 1 downto 0));
--!     ...
--!   );
--! @endverbatim
--!
--! @subsection avststreamsignals AVST stream-type in signal declaration
--!
--! @verbatim
--!   signal avst_ready  : std_logic;
--!   signal avst_stream : t_avst_stream(data(DATA_W - 1 downto 0));
--! @endverbatim
--!
--! @subsection avststrobesignals AVST strobe-type in signal declaration
--!
--! @verbatim
--!   signal avst_ready  : std_logic;
--!   signal avst_strobe : t_avst_strobe(data(DATA_W - 1 downto 0));
--! @endverbatim
--!
--! @subsection avststreamssignals multiple AVST stream-type in signal declaration
--!
--! @verbatim
--!   signal avst_streams  : t_avst_streams(AVST_STREAMS - 1 downto 0)(data(DATA_W - 1 downto 0));
--! @endverbatim
--!
--------------------------------------------------------------------------------

------------------------------<-    80 chars    ->------------------------------
--! @brief Stream-type variant of the AVST interface.
--!
--! The stream-type variant of the AVST interface for continuous data flow.
--!
--! Refer to the @ref avstconstraints when constraining it.
--!
--! It contains the following signals (parameters):
--! @param data type: <b>std_logic_vector</b> \n
--! A data bus of unconstrained width (constrained upon instantiation).
--! By the Avalon Interface Specifications, the maximum width is 4096.
--! @param valid type: <b>std_logic</b> \n
--! A valid control signal, asserted to indicate that the data bus contains valid data.
--------------------------------------------------------------------------------
  type t_avst_stream is record
    data  : std_logic_vector;
    valid : std_logic;
  end record t_avst_stream;

------------------------------<-    80 chars    ->------------------------------
--! @brief Strobe-type variant of the AVST interface.
--!
--! The strobe-type variant of the AVST interface for continuous data flow with updates not every clock cycles.
--!
--! Refer to the @ref avstconstraints when constraining it.
--!
--! It contains the following signals (parameters):
--! @param data type: <b>std_logic_vector</b> \n
--! A data bus of unconstrained width (constrained upon instantiation).
--! By the Avalon Interface Specifications, the maximum width is 4096.
--! @param valid type: <b>std_logic</b> \n
--! A valid control signal, asserted to indicate that the data bus contains valid data.
--! @param strobe type: <b>std_logic</b> \n
--! A strobe control signal, indicating updated data in the next clock cycle
--------------------------------------------------------------------------------
  type t_avst_strobe is record
    data   : std_logic_vector;
    valid  : std_logic;
    strobe : std_logic;
  end record t_avst_strobe;

------------------------------<-    80 chars    ->------------------------------
--! @brief Packet-type variant of the AVST interface.
--!
--! The packet-type variant of the AVST interface for packet-based data flow.
--!
--! Refer to the @ref avstconstraints when constraining it.
--!
--! It contains the following signals (parameters):
--! @param data type: <b>std_logic_vector</b> \n
--! A data bus of unconstrained width (constrained upon instantiation).
--! By the Avalon Interface Specifications, the maximum width is 4096.
--! A data word is composed of N symbols.
--! @param valid type: <b>std_logic</b> \n
--! A valid control signal, asserted to indicate that the data bus contains valid data.
--! @param sop type: <b>std_logic</b> \n
--! A start-of-packet control signal, asserted to mark the beginning of a packet.
--! @param eop type: <b>std_logic</b> \n
--! An end-of-packet control signal, asserted to mark the end of a packet.
--! @param empty type: <b>std_logic_vector</b> \n
--! An indicator of the number of symbols that are empty (no valid symbol)
--! in the data word transmitted at the end-of-packet.
--! It ranges from 0 to N - 1, its signal width is log2ceil(N).
--! Of unconstrained width, constrained upon instantiation. \n
--! The empty signal is not necessary (and hence not used) on interfaces where there is one symbol per beat.
--! @param error type: <b>std_logic_vector</b> \n
--! An optional bit mask to mark errors affecting the data being transferred in the current cycle.
--! A single bit of the error signal masks each of the errors the component recognizes.
--! Of unconstrained width, constrained upon instantiation.
--! By the Avalon Interface Specifications, the maximum width is 256.
--! If the error is used, it must be explicitly mentioned upon instantiation.
--------------------------------------------------------------------------------
  type t_avst_packet is record
    data  : std_logic_vector;
    valid : std_logic;
    sop   : std_logic;
    eop   : std_logic;
    empty : std_logic_vector;
    error : std_logic_vector;
  end record t_avst_packet;

------------------------------<-    80 chars    ->------------------------------
--! @brief Concatenate AVST interface control signals into `std_logic_vector`.
--------------------------------------------------------------------------------

  function avst_ctrl (avst_packet: t_avst_packet) return std_logic_vector;

------------------------------<-    80 chars    ->------------------------------
--! @brief An array of the stream-type variant of the AVST interface.
--!
--! An array of the stream-type variant of the AVST interface.
--! By default, this array is of unconstrained size.
--!
--! To properly instantiate it, use another constant to constrain it, e.g.
--!
--!```
--!  avst_streams   : t_avst_streams(AVST_CNT - 1 downto 0);
--!```
--! Where `AVST_CNT` is of type positive.
--------------------------------------------------------------------------------
  type t_avst_streams is array (natural range <>) of t_avst_stream;

------------------------------<-    80 chars    ->------------------------------
--! @brief An array of the strobe-type variant of the AVST interface.
--!
--! An array of the strobe-type variant of the AVST interface.
--! By default, this array is of unconstrained size.
--!
--! To properly instantiate it, use another constant to constrain it, e.g.
--!
--!```
--!  avst_strobes   : t_avst_strobes(AVST_CNT - 1 downto 0);
--!```
--! Where `AVST_CNT` is of type positive.
--------------------------------------------------------------------------------
  type t_avst_strobes is array (natural range <>) of t_avst_strobe;

------------------------------<-    80 chars    ->------------------------------
--! @brief An array of the packet-type variant of the AVST interface.
--!
--! An array of the packet-type variant of the AVST interface.
--! By default, this array is of unconstrained size.
--!
--! To properly instantiate it, use another constant to constrain it, e.g.
--!
--!```
--!  avst_packets   : t_avst_packets(AVST_CNT - 1 downto 0);
--!```
--! Where `AVST_CNT` is of type positive.
--------------------------------------------------------------------------------
  type t_avst_packets is array (natural range <>) of t_avst_packet;

------------------------------<-    80 chars    ->------------------------------
--! @brief Reset a AVST packet type signal.
--!
--! This procedure resets a signal of type #t_avst_packet.
--!
--! Control signals are set to zero (`0`), data is set to don't care (`-`).
--------------------------------------------------------------------------------
  procedure avst_reset (signal avst_packet: inout t_avst_packet);

------------------------------<-    80 chars    ->------------------------------
--! @brief Reset a AVST stream type signal.
--!
--! This procedure resets a signal of type #t_avst_stream.
--!
--! Control signals are set to zero (`0`), data is set to don't care (`-`).
--------------------------------------------------------------------------------
  procedure avst_reset (signal avst_stream: inout t_avst_stream);

------------------------------<-    80 chars    ->------------------------------
--! @brief Reset a AVST strobe type signal.
--!
--! This procedure resets a signal of type #t_avst_strobe.
--!
--! Control signals are set to zero (`0`), data is set to don't care (`-`).
--------------------------------------------------------------------------------
  procedure avst_reset (signal avst_strobe: inout t_avst_strobe);

------------------------------<-    80 chars    ->------------------------------
--! @brief Reset a AVST packets type signal.
--!
--! This procedure resets a signal of type #t_avst_packets.
--!
--! Control signals are set to zero (`0`), data is set to don't care (`-`).
--------------------------------------------------------------------------------
  procedure avst_reset (signal avst_packets: inout t_avst_packets);

------------------------------<-    80 chars    ->------------------------------
--! @brief Reset a AVST streams type signal.
--!
--! This procedure resets a signal of type #t_avst_streams.
--!
--! Control signals are set to zero (`0`), data is set to don't care (`-`).
--------------------------------------------------------------------------------
  procedure avst_reset (signal avst_streams: inout t_avst_streams);

------------------------------<-    80 chars    ->------------------------------
--! @brief Reset a AVST strobes type signal.
--!
--! This procedure resets a signal of type #t_avst_strobes.
--!
--! Control signals are set to zero (`0`), data is set to don't care (`-`).
--------------------------------------------------------------------------------
  procedure avst_reset (signal avst_strobes: inout t_avst_strobes);

------------------------------<-    80 chars    ->------------------------------
--! @brief Return the parameter if it is positive, or 1 otherwise.
--!
--! This function is intended for ports that depend on a width.
--!
--! In case this width would be zero, a non-allowed range (0-1 downto 0) would
--! result in a synthesis error.
--!
--! This function hence returns at least 1 such that the minimal range
--! would be (1-1 downto 0).
--------------------------------------------------------------------------------
  function one_or_more (n: integer) return positive;

  --! Conversion function of std_logic_vector to integer
  function to_integer (vec : std_logic_vector) return integer;

end package fpga_if;

--! Definition of functions
package body fpga_if is

  function avst_ctrl (avst_packet: t_avst_packet) return std_logic_vector is
  begin

    return avst_packet.valid & avst_packet.sop & avst_packet.eop & avst_packet.error & avst_packet.empty;

  end function avst_ctrl;

  procedure avst_reset (signal avst_packet: inout t_avst_packet) is
    variable ret : t_avst_packet(
      data(avst_packet.data'range),
      empty(avst_packet.empty'range),
      error(avst_packet.error'range)
    );
  begin

    ret := (
      data  => (others => '-'),
      valid => '0',
      sop   => '0',
      eop   => '0',
      empty => (others => '0'),
      error => (others => '0')
    );

    avst_packet <= ret;

  end procedure avst_reset;

  procedure avst_reset (signal avst_stream: inout t_avst_stream) is
    variable ret : t_avst_stream(data(avst_stream.data'range));
  begin

    ret := (
      data  => (others => '-'),
      valid => '0'
    );

    avst_stream <= ret;

  end procedure avst_reset;

  procedure avst_reset (signal avst_strobe: inout t_avst_strobe) is
    variable ret : t_avst_strobe(data(avst_strobe.data'range));
  begin

    ret := (
      data   => (others => '-'),
      valid  => '0',
      strobe => '0'
    );

    avst_strobe <= ret;

  end procedure avst_reset;

  procedure avst_reset (signal avst_packets: inout t_avst_packets) is
    variable ret : t_avst_packets(avst_packets'range)(
      data(avst_packets(avst_packets'high).data'range),
      empty(avst_packets(avst_packets'high).empty'range),
      error(avst_packets(avst_packets'high).error'range)
    );
  begin

    ret := (
      others => (
        data  => (others => '-'),
        valid => '0',
        sop   => '0',
        eop   => '0',
        empty => (others => '0'),
        error => (others => '0')
      )
    );

    avst_packets <= ret;

  end procedure avst_reset;

  procedure avst_reset (signal avst_streams: inout t_avst_streams) is
    variable ret : t_avst_streams(avst_streams'range)(
      data(avst_streams(avst_streams'high).data'range)
    );
  begin

    ret := (
      others => (
        data  => (others => '-'),
        valid => '0'
      )
    );

    avst_streams <= ret;

  end procedure avst_reset;

  procedure avst_reset (signal avst_strobes: inout t_avst_strobes) is
    variable ret : t_avst_strobes(avst_strobes'range)(
      data(avst_strobes(avst_strobes'high).data'range)
    );
  begin

    ret := (
      others => (
        data  => (others => '-'),
        valid => '0',
        strobe => '0'
      )
    );

    avst_strobes <= ret;

  end procedure avst_reset;

  function one_or_more (n: integer) return positive is
  begin

    if n > 0 then
      return n;
    else
      return 1;
    end if;

  end function one_or_more;

  function to_integer (vec : std_logic_vector) return integer is
  begin

    return to_integer(unsigned(vec));

  end function to_integer;

end package body fpga_if;
