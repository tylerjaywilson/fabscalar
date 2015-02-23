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
# This is the Makefile for running the FabMem CAM estimation tool (cam_est),
# for an example CAM configuration.
#
# Notes:
# 1. You must first compile the tool in the "../source" directory.
# 2. This tool makes calls to "hspice".
################################################################################

# Use "make" or "make run" to run the tool for an example CAM configuration.
# Use "make clean" to clean the directory (including the output file).


TOOL_NAME = ../source/cam_est


run:
	$(TOOL_NAME) 16 16 2 2 25 output.dat
#
# Arguments, in order:
#    <D>:        Depth, i.e., number of words. Must be a power of 2.
#    <W>:        Width, i.e., word size, in bits.
#    <Rp>:       Number of read ports (match ports).
#    <Wp>:       Number of write ports.
#    <T>:        Temperature, in degrees Celsius.
#    <FILENAME>: Output filename where results are reported.
#
# Therefore, "make run" will run the CAM estimation tool for the following
# configuration:
#
# CAM containing 16 16-bit words, 2Rx2W (2 read ports, 2 write ports),
# 25 degrees C.
#
# The results are placed in the file "output.dat".
#


clean:
	rm -f output.dat *.sp simulate_*.* invec.dat
