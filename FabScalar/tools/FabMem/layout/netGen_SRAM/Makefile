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
# This is the Makefile for generating full SPICE netlist for an example SRAM 
# configuration.
#
################################################################################

com:
	gcc -g -lm  -o gen_net generate_netlist.c

run:
	./gen_net 64 16 8 4 2
#
# Arguments, in order:
#    <D>:      Depth, i.e., number of words. Must be a power of 2.
#    <W>:      Width, i.e., word size, in bits.
#    <Rp>:     Number of read ports.
#    <Wp>:     Number of write ports.
#    <DC>:     Degree of Column Mux(1 or 2 or 4).	

clean:
	rm -f gen_net

all:
	make clean; make com; make run

