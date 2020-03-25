# This is the Makefile for the xgbe_lib module.
# It expects to be checked out as a submodule of it, so a directory up, there should be a Makefile.
# If not, we complain.

# check if a Makefile exists one directory up:
MAKEFILE := $(shell pwd | sed -E 's|(.*)/XGbE_lib(/.*)?$$|\1/Makefile|')

ifeq ($(shell test -f $(MAKEFILE) && echo -n yes),yes)
	include $(MAKEFILE)
else ifeq ($(shell test -d $(MAKEFILE) && echo -n yes),yes)
$(error Cannot call make in the root directory of module xgbe_lib)
else
$(error Global Makefile $(MAKEFILE) not found)
endif

# Paths to the fpga project (central BSP etc.)
export FPGA_PATH := ${PROJECT_ROOT_PATH}/XGbE_lib/src/fpga

