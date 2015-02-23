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

my $version = "1.2";

my $scriptName;
my $minNoCliArgs = 4;
my $minEssentialCLIArgs = 2;

my $width = 8;
my $depth = 16;
my $depthLog = 4;
my $readPorts;
my $decodedRead = 0;
my $writePorts;

my $printHeader = 0;
my $moduleName;

my $i;
my $temp;

sub fatalUsage
{
	print "Usage: perl $scriptName -rd <read_ports> [-dec] -wr <write_ports> [-w <width_in_bits>] [-d <depth>] [-h]\n";
	print "\t-dec: \"Use decoded bit-vector for read address\"\n";
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
	elsif(/^-dec$/)
	{
		$decodedRead = 1;
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

if($decodedRead == 1)
{
	$temp = "d";
}
else
{
	$temp = "";
}

$moduleName = "SRAM_".$readPorts."R".$temp.$writePorts."W_RMT";

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

LABEL

print <<LABEL;
/* Input and output wires and regs */
input wire clk;
input wire reset;

LABEL

for($i=0; $i<$readPorts; $i++)
{
	if($decodedRead == 1)
	{
		print "input wire [SRAM_DEPTH-1:0] addr${i}_i;\n";
	}
	else
	{
		print "input wire [SRAM_INDEX-1:0] addr${i}_i;\n";
	}
}

for($i=0; $i<$writePorts; $i++)
{
	print "input wire [SRAM_INDEX-1:0] addr${i}wr_i;\n";
}

for($i=0; $i<$writePorts; $i++)
{
	print "input wire we${i}_i;\n";
}

for($i=0; $i<$writePorts; $i++)
{
	print "input wire [SRAM_WIDTH-1:0] data${i}wr_i;\n";
}
print "\n";

for($i=0; $i<$readPorts; $i++)
{
	if($decodedRead == 1)
	{
		print "output reg [SRAM_WIDTH-1:0] data${i}_o;\n";
	}
	else
	{
		print "output wire [SRAM_WIDTH-1:0] data${i}_o;\n";
	}
}
print "\n";

print <<LABEL;
/* The SRAM reg */
reg [SRAM_WIDTH-1:0] sram [SRAM_DEPTH-1:0];

LABEL

print "integer i;\n\n";

print "/* Read operation */\n";
if($decodedRead == 1)
{
	print "always @(*)\n";
	print "begin\n\n";
	
	for($i=0; $i<$readPorts; $i++)
	{
		print "\t", "for(i=0; i<SRAM_DEPTH; i=i+1)\n";
		print "\t", "begin\n";
		print "\t\t", "if(addr${i}_i\[i\] == 1'b1)\n";
		print "\t\t", "begin\n";
		print "\t\t\t", "data${i}_o = sram[i];\n";
		print "\t\t", "end\n";
		print "\t", "end\n\n";
	}
	print "end\n";
}
else
{
	for($i=0; $i<$readPorts; $i++)
	{
		print "assign data${i}_o = sram[addr${i}_i];\n";
	}
}
print "\n";

print <<LABEL;
/* Write operation */
always @(posedge clk)
begin

LABEL

print <<LABEL;
	if(reset == 1\'b1)
	begin
		for(i=0; i<SRAM_DEPTH; i=i+1)
		begin
			sram[i] <= i;
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

