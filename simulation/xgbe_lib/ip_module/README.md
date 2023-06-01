# Name

Simulation of the bare `ip_module`

# Subject

A simulation testbench for the [`ip_module`](../../../src/xgbe_lib/ip_module.vhd).

The `ip_module` is tested with data packets read from file.

# Requirements

## Software

* Modelsim or Questasim and appropriate license.
* Quartus 20.4+ and appropriate license.

# Method

To run this simulation, run `make simulation` or `make simulation BATCH_MODE=1` at the command line in this directory.

The testbench instantiates the [`ip_module`](../../../src/public/ip_module.vhd) and sends input data packets for [IP](sim_data_files/IP_rx_in.dat) and [UDP](sim_data_files/UDP_rx_in.dat) to it and receives its output and compares it to the expected [IP](sim_data_files/IP_tx_expect.dat) and [UDP](sim_data_files/UDP_tx_expect.dat) output data packets which are all read from files provided with the testbench.

UVVM checks are applied to compare the expected output against the produced output until there is no more data to be read from any file.

# Results

The simulation automatically finishes after having read all input data from the files.

A UVVM summary is produced with no errors expected, and an exit code of `0` if run in batch mode.

The output of the module is also written to files, one for each interface (`sim_data_files/IP_tx_out.dat` and `sim_data_files/UDP_tx_out.dat`) for manual verification and should match the expected output with the exception of the counters not being written to that file.

## Waveform

The simulation comes with a predefined waveform setup to assist when manually inspecting it.

Basic configuration parameters, simulation signals and the instantiated entity are shown.

## UVVM

UVVM is used to monitor and test the unit under test and to report the success or failure of the simulation.

# Reproducibility

This simulation should be run each time modifications to the [`ip_module`](../../../src/xgbe_lib/ip_module.vhd) itself, the [`ip_header_module`](../../../src/xgbe_lib/ip_header_module.vhd), [`interface_merger`](../../../src/xgbe_lib/interface_merger.vhd), [`icmp_module`](../../../src/xgbe_lib/icmp_module.vhd), [`trailer_module`](../../../src/xgbe_lib/trailer_module.vhd) or the [`port_io_table`](../../../src/xgbe_lib/port_io_table.vhd); and ideally by the CI each time a merge request is finalized.
