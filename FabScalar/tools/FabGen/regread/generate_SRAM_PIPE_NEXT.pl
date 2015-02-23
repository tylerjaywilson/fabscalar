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
my $depth = 64;
my $depthLog = 6;
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

$moduleName = "SRAM_".$readPorts."R".$writePorts."W_PIPE_NEXT";

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

print "\nmodule $moduleName(\n";
for($i=0; $i<$writePorts; $i++)
{
	print "\tdata${i}wr_i,\n";
}
 print "\t\tclk,\n\t\treset,\n";
for($i=0; $i<$readPorts; $i++)
{
	print "\tdecoded_addr${i}_i,\n";
}

for($i=0; $i<$writePorts; $i++)
{
	print "\tdecoded_addr${i}wr_i,\n";
}

for($i=0; $i<$writePorts; $i++)
{
	print "\twe${i}_i,\n";
}
for($i=0; $i<$readPorts; $i++)
{
	print "\tdata${i}_o,\n";
}
print "\n";

for($i=0; $i<$readPorts; $i++)
{
        print "\tdecoded_addr${i}_o,\n";
}
for($i=0; $i<$writePorts; $i++)
{
        print "\tdecoded_addr${i}wr_o,\n";
}
for($i=0; $i<$writePorts; $i++)
{
	my $comma;
	if($i == $writePorts-1)
	{
		$comma = "";
	}
	else
	{
		$comma = ",";
	}

        print "\twe${i}_o$comma\n";
}




print ");\n\n";



print <<LABEL;
/* Parameters */
parameter SRAM_DEPTH = $depth;
parameter SRAM_INDEX = $depthLog;
parameter SRAM_WIDTH = $width;

LABEL

for($i=0; $i<$writePorts; $i++)
{
	print "\tinput [SRAM_WIDTH-1:0] data${i}wr_i;\n";
}
print "\n input clk; \n input reset;\n";

for($i=0; $i<$readPorts; $i++)
{
	print "\tinput [SRAM_DEPTH-1:0] decoded_addr${i}_i;\n";
}

for($i=0; $i<$writePorts; $i++)
{
	print "\tinput [SRAM_DEPTH-1:0] decoded_addr${i}wr_i;\n";
}

for($i=0; $i<$writePorts; $i++)
{
	print "\tinput we${i}_i;\n";
}

for($i=0; $i<$writePorts; $i++)
{
        print "\toutput we${i}_o;\n";
}

for($i=0; $i<$readPorts; $i++)
{
	print "\toutput [SRAM_WIDTH-1:0] data${i}_o;\n";
}

for($i=0; $i<$readPorts; $i++)
{
        print "\toutput [SRAM_DEPTH-1:0] decoded_addr${i}_o;\n";
}
for($i=0; $i<$writePorts; $i++)
{
        print "\toutput [SRAM_DEPTH-1:0] decoded_addr${i}wr_o;\n";
}


print "\treg [SRAM_WIDTH-1:0] sram [SRAM_DEPTH-1:0];\n";
for($i=0; $i<$readPorts; $i++)
{
	print "\treg [SRAM_WIDTH-1:0] data${i}_o;\n";
}

print "integer i,j;\n\n";
for($i=0; $i<$readPorts; $i++){
	print " assign decoded_addr${i}_o = decoded_addr${i}_i;\n";
}

for($i=0; $i<$writePorts; $i++){
	print " assign decoded_addr${i}wr_o = decoded_addr${i}wr_i;\n";
	print " assign we${i}_o = we${i}_i;\n";
}

print "/* Read operation */\n";
	print "always @(*)\n";
	print "begin\n\n";
        for($i=0; $i<$readPorts; $i++){
		print "\tdata${i}_o = 0;\n";
	}

	print "\t", "for(j=0; j<SRAM_DEPTH; j=j+1)\n";
	print "\t", "begin\n";

	for($i=0; $i<$readPorts; $i++)
	{
		print "\t\t", "if(decoded_addr${i}_i\[j\])\t";
		print "data${i}_o = sram[j];\n";
	}
	print "\t", "end\n\n";
	print "end\n";
print "\n";

print <<LABEL;
/* Write operation */
always @(posedge clk)
begin

LABEL

print <<LABEL;
	if(reset)
	begin
		for(i=`SIZE_RMT; i<SRAM_DEPTH; i=i+1)
		begin
			sram[i] <= 0;
		end
	end
	else
	begin
        for(i=0;i<SRAM_DEPTH;i=i+1)
        begin

LABEL

for($i=0; $i<$writePorts; $i++)
{
print <<LABEL;
		if(we${i}_i)
			if(decoded_addr${i}wr_i[i]) sram[i] <= data${i}wr_i;

LABEL
}

print <<LABEL;
	end
end
end

endmodule





LABEL

