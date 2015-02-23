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
# This is the Makefile for generating full SPICE netlist for an example CAM
# configuration.
#
################################################################################

com: 
	gcc -g -lm -o gen_net generate_netlist.c

run: 
	./gen_net 48 6 4 4 
#
# Arguments, in order:
#    <D>:      Depth, i.e., number of words.
#    <W>:      Width, i.e., word size, in bits.
#    <Rp>:     Number of read ports (match ports).
#    <Wp>:     Number of write ports.

clean: 
	rm -rf gen_net
all:
	make clean; make com; make run;


