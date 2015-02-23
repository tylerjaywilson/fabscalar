#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw/ceil/;

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
################################################################################

my $width = 4;
my $version = "1.0";
my $minNoCliArgs = 1;
my $createFile = 0;
my $printHeader = 0;
my $moduleName;
my $outputFileName;
my $scriptName;
my $nearest_width;

my $i;
my $j;

sub fatalUsage
{
	print "Usage: perl ./generate_L1Cache_ba.pl -w <width> [-m] [-v] [-h]\n";
	print "\t-m: Add header\n";
	print "\t-v: Print version and exit\n";
	print "\t-h: Show usage help and exit\n";
	exit;
}

sub log2 
{
	my $n = shift;
	return ceil(log($n)/log(2));
}

### START HERE ###
$scriptName = $0;

if($#ARGV < $minNoCliArgs)
{
	print "Error: Too few input arguments.\n";
	&fatalUsage();
}

while(@ARGV)
{
	$_ = shift;
	
	if(/^-w$/) 
	{
		$width = shift;
	}
	elsif(/^-m$/)
	{
		$printHeader = 1;
	}
	elsif(/^-h$/)
	{
		&fatalUsage();
	}
	elsif(/^-v$/)
	{
		print "$scriptName version $version\n";
		exit;
	}
	else
	{
		print "Error: Unrecognized argument $_.\n";
		&fatalUsage();
	}
}

$nearest_width = 2**log2($width);
$outputFileName = "L1ICache.v";
$moduleName = "L1ICache";

print  <<LABEL;
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
# Purpose: This block implements L1 Instruction Cache for Block Ahead Fetch. 
#	   Fetch Width is $width.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL


print <<LABEL;
module L1ICache ( input clk,
	input reset,
	input stall_i,
	input flush_i,
	input [`SIZE_PC-1:0] addr_i,					// Address of the insts to be fetched
	input rdEnable_i,								// Read enable for inst cache
	input wrEnabale_i,								// Write enable from lower level memory hierarchy
	input  [`SIZE_PC-1:0] wrAddr_i,					// Write address from the L1 inst Cache MSHR
	input  [$width*`SIZE_INSTRUCTION-1:0] instBlock_i,	// Inst block from lower level memory hierarchy
	output [`INSTRUCTION_BUNDLE-1:0] instBundle_o,	// Inst block read from the L1 Cache
	output miss_o,									// Signal for Inst Cache miss   
	output [`SIZE_PC-1:0] missAddr_o				// Physical Address for the cache miss
	);

LABEL


for($i=0; $i<$width; $i++)
{
	print "wire [(`SIZE_INSTRUCTION/2)-1:0] opcode",$i,";\n";
	print "wire [(`SIZE_INSTRUCTION/2)-1:0] operand",$i,";\n\n";
}
for($i=0; $i<$width; $i++)
{
	print "wire [`SIZE_PC-1:0] addr",$i,";\n";
}

print <<LABEL;

reg [`SIZE_PC-1:0]addr;

always@(posedge clk)
begin
	if(flush_i||reset)
	begin
		addr <= 0;
	end
	else if(~stall_i)
	begin
		addr <= addr_i;
	end
end

/* Keeping miss to be always zero. */
assign miss_o = 1'b0;

LABEL

for($i=0; $i<$width; $i++)
{
	print " assign addr",$i,"  = addr+",$i*8,";\n";
}
print <<LABEL;

/* Following read instruction from a huge virtual array. Virtual array
contains all the instruction and data required to execute a program. 
Virtual array has been implemented in C++ class and is being accessed
using VPI task/function (\$readOpcode/\$readOperand).    
*/ 
LABEL


for($i=0; $i<$width; $i++)
{
	print "assign opcode",$i,"  = \$read_opcode(addr",$i,");\n";
	print "assign operand",$i," = \$read_operand(addr",$i,");\n\n";
}


print "assign instBundle_o = {";
for($i=0; $i<$width; $i++)
{
	print "opcode",$width-$i-1,",";
	print "operand",$width-$i-1,"";
	if($i<$width-1)
	{
		print ",";
	}
}
print "};\n";
print <<LABEL;
endmodule
LABEL

