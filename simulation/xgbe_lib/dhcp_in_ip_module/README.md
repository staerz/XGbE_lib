# Name

Simulation of the `dhcp_module` embedded in the `ip_module`.

# Subject

A simulation testbench for the [`dhcp_module`](../../../src/xgbe_lib/dhcp_module.vhd), in conjunction with the [`ip_module`](../../../src/xgbe_lib/ip_module.vhd).

The `dhcp_module` is tested with data packets read from file.

In this simulation the initialisation procedure (Discover, Offer, Request, Acknowledge) is cycled over in the beginning.

Once the `dhcp_module` runs into RENEWING, another Acknowledge is sent to rebind the `dhcp_module`.

Subsequently, the REBOOTING procedure is tested: The `dhcp_module` is reset (in reboot) and the request is replied with an Acknowledge which brings the `dhcp_module` back into BOUND state again.
Shortly later, the `dhcp_module` is reset (in reboot) again, but this time, a NAcknowledge is replied such that the module immediately goes back into the INIT/SELECTING state.

The final test can be altered to test the timeout procedure during REBOOTING:
This is achieved by omitting the final NAcknowledge (i.e. simply by making it an erroneous reply) and postponing the final reset to about 7000.
A transition to INIT would then be observed at `cnt = 6454`.

# Requirements

## Software

* Modelsim or Questasim and appropriate license.
* Quartus 20.4+ and appropriate license.

## Other modules

* LASP main repository with the default libraries for simulation (`PoC`, `common`, `testbench`)

# Method

To run this simulation, run `make simulation` or `make simulation BATCH_MODE=1` at the command line in this directory.

The testbench instantiates the [`dhcp_module`](../../../src/xgbe_lib/dhcp_module.vhd) and sends [IP-layer input data packets](sim_data_files/IP_rx_in.dat) to it and receives its output and compares it to the [expected IP-layer output data packets](sim_data_files/IP_tx_expect.dat) which are all read from files provided with the testbench.

UVVM checks are applied to compare the expected output against the produced output until there is no more data to be read from any file.

# Results

The simulation automatically finishes after having read all input data from the files.

A UVVM summary is produced with no errors expected, and an exit code of `0` if run in batch mode.

The output of the module is also written to a file (`sim_data_files/IP_tx_out.dat`) for manual verification and should match the expected output with the exception of the counters not being written to that file.

## Waveform

The simulation comes with a predefined waveform setup to assist when manually inspecting it.

Basic configuration parameters, simulation signals and the instantiated entity are shown.

## UVVM

UVVM is used to monitor and test the unit under test and to report the success or failure of the simulation.

# Reproducibility

This simulation should be run each time modifications to the [`dhcp_module`](../../../src/xgbe_lib/dhcp_module.vhd) itself or to the [`ip_module`](../../../src/xgbe_lib/op_module.vhd) are done; and ideally by the CI each time a merge request is finalized.
