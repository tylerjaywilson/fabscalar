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
# This Makefile runs the LEF tool for an example RAM. Use the generated LEF for
# place-and-route.
#
# Notes:
# 1. You must first compile the tool in the "../source" directory.
################################################################################

# Use "make" to run the LEF tool for an example RAM.
# Use "make clean" to clean the directory (LEF files).


TOOL_NAME = ../source/ram_lef


all:
	$(TOOL_NAME) 32 7 8 4 34.00 91.00 8R4W_PRF
#
# Arguments, in order:
#    <D>:      Depth, i.e., number of words. Must be a power of 2.
#    <W>:      Width, i.e., word size, in bits.
#    <Rp>:     Number of read ports.
#    <Wp>:     Number of write ports.
#    <HEIGHT>: RAM height (in um) from RAM estimation tool.
#    <WIDTH>:  RAM width (in um) from RAM estimation tool.
#    <NAME>:   The generated LEF file is named SRAM_<NAME>.lef.
#              The "site name" in the LEF file is SITE_SRAM_<NAME>.
#
# Note:
# For easy integration of LEFs during place-and-route, keep the "site name"
# the same as the memory module name in the RTL.       
#  


clean:
	rm -f *.lef
