################################################################################
#                       NORTH CAROLINA STATE UNIVERSITY
#
#                              FabScalar Project
#
# FabScalar Copyright (c) 2007-2011 by Niket K. Choudhary, Salil Wadhavkar,
# and Eric Rotenberg.  All Rights Reserved.
#
# This is a beta-release version.  It must not be redistributed at this time.
#
# Purpose:
# This Makefile compiles the LEF tool for RAMs.
################################################################################

# Use "make" to compile the LEF tool for RAMs.
# Use "make clean" to clean the directory.


TOOL_NAME = ram_lef


all:
	gcc -g -lm  -o $(TOOL_NAME) lef_sram.c

clean:
	rm -f $(TOOL_NAME)
