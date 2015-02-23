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
# This is the Makefile for running the FabMem RAM estimation tool (ram_est),
# for an example RAM configuration.
#
# Notes:
# 1. You must first compile the tool in the "../source" directory.
# 2. This tool makes calls to "hspice".
################################################################################

# Use "make" or "make run" to run the tool for an example RAM configuration.
# Use "make clean" to clean the directory (including the output file).


TOOL_NAME = ../source/ram_est


run:
	$(TOOL_NAME) 0 32 7 8 4 25 output.dat
#
# Arguments, in order:
#    <F>:        Selects RAM vs. FIFO.  0=RAM, 1=FIFO.
#    <D>:        Depth, i.e., number of words. Must be a power of 2.
#    <W>:        Width, i.e., word size, in bits.
#    <Rp>:       Number of read ports.
#    <Wp>:       Number of write ports.
#    <T>:        Temperature, in degrees Celsius.
#    <FILENAME>: Output filename where results are reported.
#
# Therefore, "make run" will run the RAM estimation tool for the following
# configuration:
#
# RAM containing 32 7-bit words, 8Rx4W (8 read ports, 4 write ports),
# 25 degrees C.
#
# The results are placed in the file "output.dat".
#


clean:
	rm -f  output.dat simulate_*.* invec.dat *.sp
