# Name

Simulation of the bare `ethernet_to_udp_module`

# Subject

A simulation testbench for the [`ethernet_to_udp_module`](../../../src/xgbe_lib/ethernet_to_udp_module.vhd).

The `ethernet_to_udp_module` is tested with data packets read from file.

## Variants

This simulation exists in 3 different variants:
1) With DHCP funcionality enabled (default, this directory)
1) With static IP configuration, i.e. DHCP disabled (in the [`static_ip`](./static_ip) sub-directory)
1) With DHCP dynamically switched on and off again (in the [`dynamic_dhcp`](./dynamic_dhcp) sub-directory)

All variants work in the exact same way and the `DHCP_SWITCH` in the related `Manifest.py` file determines the variant.

# Requirements

## Software

* Modelsim or Questasim and appropriate license.
* Quartus 20.4+ and appropriate license.

# Method

To run this simulation, run `make simulation` or `make simulation BATCH_MODE=1` at the command line in this directory.

The testbench instantiates the [`ethernet_to_udp_module`](../../../src/public/ethernet_to_udp_module.vhd) and sends input data packets for [Ethernet](sim_data_files/ETH_rx_in.dat) and [UDP](sim_data_files/UDP_rx_in.dat) to it and receives its output and compares it to the expected [Ethernet](sim_data_files/ETH_tx_expect.dat) and [UDP](sim_data_files/UDP_tx_expect.dat) output data packets which are all read from files provided with the testbench.

> Input data and expected output data files exist individually for each of the 3 provided [variants](#variants) to match/test the respective expected data flow.

UVVM checks are applied to compare the expected output against the produced output until there is no more data to be read from any file.

# Results

The simulation automatically finishes after having read all input data from the files.

A UVVM summary is produced with no errors expected, and an exit code of `0` if run in batch mode.

The output of the module is also written to files, one for each interface (`sim_data_files/ETH_tx_out.dat` and `sim_data_files/UDP_tx_out.dat`) for manual verification and should match the expected output with the exception of the counters not being written to that file.

## Waveform

The simulation comes with a predefined waveform setup to assist when manually inspecting it.

Basic configuration parameters, simulation signals and the instantiated entity are shown.

## UVVM

UVVM is used to monitor and test the unit under test and to report the success or failure of the simulation.

# Reproducibility

This simulation should be run each time modifications to the [`ethernet_to_udp_module`](../../../src/xgbe_lib/ethernet_to_udp_module.vhd) itself, the [`ethernet_module`](../../../src/xgbe_lib/ethernet_module.vhd), [`arp_module`](../../../src/xgbe_lib/arp_module.vhd), [`ip_module`](../../../src/xgbe_lib/ip_module.vhd), [`dhcp_module`](../../../src/xgbe_lib/dhcp_module.vhd) or the [`common` repository](https://gitlab.cern.ch/atlas-lar-be-firmware/shared/common) are done; and ideally by the CI each time a merge request is finalized.
