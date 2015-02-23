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
# Purpose: This script creates a Verilog module of a CAM using flip-flops.
################################################################################

my $version = "1.2";

my $scriptName;
my $minNoCliArgs = 4;
my $minEssentialCLIArgs = 2;

my $width = 8;
my $depth = 16;
my $depthLog = 4;
my $readPorts;
my $writePorts;

my $printHeader = 0;
my $moduleName;

my $i;
my $temp;

sub fatalUsage
{
	print "Usage: perl $scriptName -rd <read_ports> -wr <write_ports> [-w <width_in_bits>] [-d <depth>] [-h]\n";
	print "\t-h: Print header\n";
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

# Check command line arguments
if($#ARGV < $minNoCliArgs-1)
{
	print "Error: Too few input arguments.\n";
	&fatalUsage();
}

# Check mandatory command line arguments
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

$moduleName = "CAM_".$readPorts."R".$writePorts."W";

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
# Purpose: This module implements CAM.
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
	print "\ttag${i}_i,\n";
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
	print "\ttag${i}wr_i,\n";
}
print "\n";

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

	print "\tmatch${i}_o$comma\n";
}


print ");\n\n";

print <<LABEL;
/* Parameters */
parameter CAM_DEPTH  = $depth;
parameter CAM_INDEX  = $depthLog;
parameter CAM_WIDTH  = $width;

LABEL

print <<LABEL;
/* Input and output wires and regs */
input wire clk;
input wire reset;

LABEL

for($i=0; $i<$readPorts; $i++)
{
	print "input wire [CAM_WIDTH-1:0] tag${i}_i;\n";
}

for($i=0; $i<$writePorts; $i++)
{
	print "input wire [CAM_INDEX-1:0] addr${i}wr_i;\n";
}

for($i=0; $i<$writePorts; $i++)
{
	print "input wire we${i}_i;\n";
}

for($i=0; $i<$writePorts; $i++)
{
	print "input wire [CAM_WIDTH-1:0] tag${i}wr_i;\n";
}
print "\n";

for($i=0; $i<$readPorts; $i++)
{
	print "output reg [CAM_DEPTH-1:0] match${i}_o;\n";
}
print "\n";

print <<LABEL;
/* The CAM reg */
reg [CAM_WIDTH-1:0] cam [CAM_DEPTH-1:0];

LABEL

print "integer i;\n\n";

print <<LABEL;
/* Read operation */
always @(*)
begin

	for(i=0; i<CAM_DEPTH; i=i+1)
	begin
LABEL

for($i=0; $i<$readPorts; $i++)
{
	print "\t\tmatch${i}_o\[i\] = 1\'b0;\n";
}
print "\tend\n\n";

for($i=0; $i<$readPorts; $i++)
{
print <<LABEL;
	for(i=0; i<CAM_DEPTH; i=i+1)
	begin
		if(cam[i] == tag${i}_i)
		begin
			match${i}_o\[i\] = 1\'b1;
		end
	end

LABEL
}
print "end\n\n";

print <<LABEL;
/* Write operation */
always @(posedge clk)
begin

LABEL

print <<LABEL;
	if(reset == 1\'b1)
	begin
		for(i=0; i<CAM_DEPTH; i=i+1)
		begin
			cam[i] <= 0;
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
			cam[addr${i}wr_i] <= tag${i}wr_i;
		end

LABEL
}

print <<LABEL;
	end
end

endmodule


LABEL

