# `XGbE_lib`

This repository provides `XGbE_lib`, a VHDL library for 10 GbE supporting UDP/IP and embedded support for ARP, ICMP and DHCP.

## Contact
This repository is maintained by Steffen Stärz (<steffen.staerz@cern.ch>).

Use the [GitLab issue tracker](/../issues) for reporting any bug or other issue.

## Description

`XGbE_lib` is a low latency and high throughput implementation of UDP/IP in ten Gigabit Ethernet for FPGAs in VHDL.
The `XGbE_lib` can also be embedded in 1 GbE applications when wrapping it accordingly in FIFO-based environment which respect the AVST interface.

`XGbE_lib` also implements DHCP for automatic IP address configuration and the supporting protocols of ARP and ICMP.

To achieve low latency, not all optional features are implemented.
Examples of such omitted features are the calculation of optional checksum (CRC) fields in headers or the `DHCP_INFORM` mechanism for static IP configuration of DHCP.

All required sources to build `XGbE_lib` are provided.
These sources are generic and target device unspecific such that it can be used for any FPGA family from any vendor.

The entire design is based on the Avalon Streaming Interface (AVST) as it is fully defined in the [Avalon Interface Specification](
https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/manual/mnl_avalon_spec.pdf).

For the purpose of 10 Gigabit Ethernet application, it's based on a clock of 156.25 MHz and a data bus width of 64 bit.

`ethernet_to_udp_module` is the top level entity to provide the user interface.

## Dependencies and prerequisites

`XGbE_lib` is based on a variant of [`hdlmake`](https://hdlmake.readthedocs.io/en/master/).

At least the following tools are requires:
- GNU Make 3.81
- Git 2.7.6
- Python 3.6

The project itself further uses the following tools:
- [doxygen](./doc/Doxygen) 1.8.18 (or higher) for generating the documentation
- [UVVM](https://github.com/UVVM/UVVM) for test benches

## Repository structure

- [`src`](./src): source files, organised by library
- [`simulation`](./simulation): test benches for all sources of `XGbE_lib`
- [`doc`](./doc): setup and auxiliary files for the generation of the [documenation via Doxygen](./doc/Doxygen)

## Documentation

All source code is documented using Doxygen.

To generate the documentation locally as `pdf` (using $`\LaTeX`$) or as HTML, see the [Doxygen](./doc/Doxygen) directory.

It uses [wavedrom](https://wavedrom.com/) to generate timing diagrams.
