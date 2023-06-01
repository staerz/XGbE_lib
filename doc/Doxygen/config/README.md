# Firmware Documentation with Doxygen

This directory contains the main configuration files for creating the Manual for `XGbE_lib` via Doxygen.

See the [Doxygen Manual](http://www.doxygen.nl/manual/) for general information.

## Table of Contents
* [Contact](#contact)
* [Directory content](#directory-content)
   + [`beautifyDoxygen.sh`](#beautifydoxygensh)
   + [`Doxyfile`](#doxyfile)
   + [`doxygenJunitHelper.sh`](#doxygenjunithelpersh)
   + [`DoxyLayout.xml`](#doxylayoutxml)
   + [`LASP-defs.sty`](#lasp-defssty)
   + [`Makefile`](#makefile)
   + [`wavedrom`](#wavedrom)

## Contact

This directory is maintained by
- Steffen Stärz (<steffen.staerz@cern.ch>)

## Directory content
The Doxygen configuration is made up of several files with dedicated tasks.

### [`beautifyDoxygen.sh`](./beautifyDoxygen.sh)
This is a post-doxygen script to reformat the $`\LaTeX`$ output for better style and automatically invoked when calling `make`.

### [`Doxyfile`](./Doxyfile)
This file is contains the central Doxygen configuration.

### [`doxygenJunitHelper.sh`](./doxygenjunithelper.sh)
This is a post-doxygen script to extend the `doxygen-junit.xml` (see [`Makefile`](#makefile)) by the the files that have been parsed by Doxygen without errors.
It is automatically invoked when calling `make doxygen-junit.xml`.

### [`DoxyLayout.xml`](./DoxyLayout.xml)
This file is the [Doxygen layout file](http://www.doxygen.nl/manual/config.html#cfg_layout_file).

### [`LATEX-defs.sty`](./LATEX-defs.sty)
This file contains a few $`\LaTeX`$-specific commands that can be used in the Doxygen source code, i.e. certain constants or lengths.

### [`Makefile`](./Makefile)
This is the central `Makefile` to be included by a project specfic `Makefile` to start Doxygen and run the ($`\LaTeX`$) compilation of the manual.

The default target is `Manual_<component>.pdf`.

The following additional targets are defined:
- `html`: produce the manual in form of a website
- `doxygen-junit.xml`: produce the JUnit report

It defines the following cleaning targets:
- `clean`: remove temporary `doxytemp` directory and log files
- `cleanwave`: remove temporary wavedrom figures
- `cleanall`: `clean`, `cleanwave` and additionally remove produced manual and `html` directory
