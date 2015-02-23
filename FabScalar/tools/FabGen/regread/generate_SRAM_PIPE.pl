#!/usr/bin/perl
use strict;
use warnings;

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
# Purpose: This script creates a Verilog module of a RAM using flip-flops.
################################################################################

my $version = "1.0";

my $scriptName;
my $minNoCliArgs = 4;
my $minEssentialCLIArgs = 2;

my $width = 8;
my $depth = 16;
my $depthLog = 4;
my $readPorts;
my $decodedRead = 1;
my $writePorts;

my $printHeader = 0;
my $moduleName;

my $i;
my $temp;

sub fatalUsage
{
	print "Usage: perl $scriptName -rd <read_ports> -wr <write_ports> [-w <width_in_bits>] [-d <depth>] [-h]\n";
	print "\t-h  : \"Print header\"\n";
	exit;
}

sub log2 
{
	my $n = shift;
	return(log($n)/log(2));
}


### START HERE ###

# Get this scripts name
$scriptName = $0;

my $essentialCLIArgs = 0;
while(@ARGV)
{
	$_ = shift;

	if(/^-rd$/)
	{
		$readPorts = shift;
		$essentialCLIArgs++;
	}
	elsif(/^-wr$/)
	{
		$writePorts = shift;
		$essentialCLIArgs++;
	}
	elsif(/^-w$/) 
	{
		$width = shift;
	}
	elsif(/^-d$/)
	{
		$depth = shift;
		$depthLog = log2($depth);
	}
	elsif(/^-h$/)
	{
		$printHeader = 1;
	}
	else
	{
		print "Error: Unrecognized argument $_.\n";
		&fatalUsage();
	}
}

if($essentialCLIArgs < $minEssentialCLIArgs)
{
	print "Error: Too few mandatory input arguments.\n";
	&fatalUsage();
}

$moduleName = "SRAM_".$readPorts."R".$writePorts."W_PIPE";

print <<LABEL;
/*******************************************************************************
#                        NORTH CAROLINA STATE UNIVERSITY
#
#                               FabScalar Project
#
# FabScalar Copyright (c) 2007-2011 by Niket K. Choudhary, Salil Wadhavkar,
# and Eric Rotenberg.  All Rights Reserved.
#
# This is a beta-release version.  It must not be redistributed at this time.
#
# Purpose: This module implements SRAM.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL

print <<LABEL;
module $moduleName(
	clk,
	reset,

LABEL

for($i=0; $i<$readPorts; $i++)
{
	print "\taddr${i}_i,\n";
}

for($i=0; $i<$writePorts; $i++)
{
	print "\taddr${i}wr_i,\n";
}

for($i=0; $i<$writePorts; $i++)
{
	print "\twe${i}_i,\n";
}

for($i=0; $i<$writePorts; $i++)
{
	print "\tdata${i}wr_i,\n";
}
print "\n";
for($i=0; $i<$readPorts; $i++){
	print "decoded_addr${i}_o,\n";
}

for($i=0; $i<$writePorts; $i++){
	print "decoded_addr${i}wr_o,\n";
	print "we${i}_o,\n";
}
for($i=0; $i<$readPorts; $i++)
{
	my $comma;
	if($i == $readPorts-1)
	{
		$comma = "";
	}
	else
	{
		$comma = ",";
	}
	print "\tdata${i}_o$comma\n";
}


print ");\n\n";

print <<LABEL;
/* Parameters */
parameter SRAM_DEPTH = $depth;
parameter SRAM_INDEX = $depthLog;
parameter SRAM_WIDTH = $width;

input clk;
input reset;
/* The SRAM reg */
LABEL

for($i=0; $i<$readPorts; $i++)
{
	print "\tinput [SRAM_INDEX-1:0] addr${i}_i;\n";
}

for($i=0; $i<$writePorts; $i++)
{
	print "\tinput [SRAM_INDEX-1:0] addr${i}wr_i;\n";
}

for($i=0; $i<$writePorts; $i++)
{
	print "\tinput we${i}_i;\n";
}

for($i=0; $i<$writePorts; $i++)
{
	print "\tinput [SRAM_WIDTH-1:0] data${i}wr_i;\n";
}
print "\n";
for($i=0; $i<$readPorts; $i++){
	print "output [SRAM_DEPTH-1:0] decoded_addr${i}_o;\n";
}

for($i=0; $i<$writePorts; $i++){
	print "output [SRAM_DEPTH-1:0] decoded_addr${i}wr_o;\n";
	print "output we${i}_o;\n";
}
for($i=0; $i<$readPorts; $i++)
{
	print "\toutput [SRAM_WIDTH-1:0] data${i}_o;\n";
}

print "\treg [SRAM_WIDTH-1:0] sram [SRAM_DEPTH-1:0];\n";
for($i=0; $i<$readPorts; $i++){
	print "assign data${i}_o = sram[addr${i}_i];\n";
	print "assign decoded_addr${i}_o = 1 << addr${i}_i;\n";
}

for($i=0; $i<$writePorts; $i++){
	print "assign decoded_addr${i}wr_o = we${i}_i << addr${i}wr_i;\n";
	print "assign we${i}_o = we${i}_i;\n";
}
print "integer i,j;\n\n";

print <<LABEL;
/* Write operation */
always @(posedge clk)
begin

LABEL

print <<LABEL;
	if(reset == 1\'b1)
	begin
		for(i=`SIZE_RMT; i<SRAM_DEPTH; i=i+1)
		begin
			sram[i] <= 0;
		end
	end
	else
	begin
LABEL

for($i=0; $i<$writePorts; $i++)
{
print <<LABEL;
		if(we${i}_i == 1\'b1)
		begin
			sram[addr${i}wr_i] <= data${i}wr_i;
		end

LABEL
}

print <<LABEL;
	end
end

endmodule


LABEL

