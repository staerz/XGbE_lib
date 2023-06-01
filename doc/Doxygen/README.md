# Firmware Documentation with Doxygen

This directory contains the configuration files for creating the Manual for `XGbE_lib` via Doxygen.

See the [Doxygen Manual](http://www.doxygen.nl/manual/) for general information on Doxygen.

## Table of Contents
* [Contact](#contact)
* [Creating the Documentation](#creating-the-documentation)
* [Directory content](#directory-content)
   + [Doxyfile_local](#doxyfile_local)
   + [Makefile](#makefile)
   + [README.md](#readmemd)

## Contact

This directory is maintained by
- Steffen Stärz (<steffen.staerz@cern.ch>)

## Creating the documentation
To create the documentation locally, navigate to this directory (`doc/Doxygen`) and simply run `make` there.

## Directory content

### Doxyfile_local
It is a project-specific Doxygen configuration file, included by the main Doxygen configuration file.

Minimal expected parameters to set here are `INPUT` and `PROJECT_NAME`.

### Makefile
Makefile to start Doxygen and run the creation of the manual.

It sets the component name and includes the [main Doxygen Makefile](./config/#makefile).
