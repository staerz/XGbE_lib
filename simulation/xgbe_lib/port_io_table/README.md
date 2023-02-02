# Name

Simulation of the bare `port_io_table`

# Subject

A simulation testbench for the [`port_io_table`](../../../src/xgbe_lib/port_io_table.vhd).

The `port_io_table` is tested with recovery requests read from file.

# Requirements

## Software

* Modelsim or Questasim and appropriate license.
* Quartus 20.4+ and appropriate license.

## Other modules

* LASP main repository with the default libraries for simulation (`PoC`, `common`, `testbench`)

# Method

To run this simulation, run `make simulation` or `make simulation BATCH_MODE=1` at the command line in this directory.

The testbench instantiates the [`port_io_table`](../../../src/public/port_io_table.vhd) and sends [discovery data](sim_data_files/DISCO_rx_in.dat) and [recovery requests](sim_data_files/RECO_rx_in.dat) to it and receives its output and compares it to [the expected recovery data](sim_data_files/RECO_tx_expect.dat) which are all read from files provided with the testbench.

UVVM checks are applied to compare the expected output against the produced output until there is no more data to be read from any file.

# Results

The simulation automatically finishes after having read all input data from the files.

A UVVM summary is produced with no errors expected, and an exit code of `0` if run in batch mode.

The output of the module is also written to a file (`sim_data_files/RECO_tx_out.dat`) for manual verification and should match the expected output with the exception of the counters not being written to that file.

## Waveform

The simulation comes with a predefined waveform setup to assist when manually inspecting it.

Basic configuration parameters, simulation signals and the instantiated entity are shown.

## UVVM

UVVM is used to monitor and test the unit under test and to report the success or failure of the simulation.

# Reproducibility

This simulation should be run each time modifications to the [`port_io_table`](../../../src/xgbe_lib/port_io_table.vhd) itself; and ideally by the CI each time a merge request is finalized.