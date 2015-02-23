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
# Purpose: This script creates IQ/RR pipe reg.
################################################################################

my $version = "1.1";

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 1;

my $issueWidth = 4;

my $printHeader = 0;

my $i;
my $j;
my $k;
my $temp;

sub fatalUsage
{
	print "Usage: perl $scriptName -w <issue_width> [-m] [-v] [-h]\n";
	print "\t-m: Add header\n";
	print "\t-v: Print version and exit\n";
	print "\t-h: Show usage help and exit\n";
	exit;
}

### START HERE ###

$scriptName = $0;

my $essentialCLIArgs = 0;
while(@ARGV)
{
	$_ = shift;
	if(/^-w$/) 
	{
		$issueWidth = shift;
		$essentialCLIArgs++;
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

if($essentialCLIArgs < $minEssentialCLIArgs)
{
	print "\nError: Too few inputs\n";
	&fatalUsage();
}

# Create module name
$outputFileName = "IssueQRegRead.v";
$moduleName = "IssueQRegRead";

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
# Purpose: This is the pipeline latch between Issue Queue and Register Read.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL


print <<LABEL;
module IssueqRegRead(
	input clk,
	input reset,

LABEL

print <<LABEL;
	/* Payload and Destination of incoming instructions */
LABEL
for($i=0; $i<$issueWidth; $i++)
{
print <<LABEL;
	input grantedValid${i}_i,
	input [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
		`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
		`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] grantedPacket${i}_i,    
LABEL
}
print "\n";

print <<LABEL;
	/* Payload and Destination of outgoing instructions */
LABEL
my $comma;
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = "";
	}
	else
	{
		$comma = ",";
	}
	
	print <<LABEL;
	output reg grantedValid${i}_o,
	output reg [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
		`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
		`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] grantedPacket${i}_o$comma
LABEL
}

print ");\n\n";


print <<LABEL;
always @(posedge clk)
begin
	if(reset)
	begin
LABEL


for($i=0; $i<$issueWidth; $i++)
{
print <<LABEL;
		grantedValid${i}_o  <= 0;
LABEL
}

for($i=0; $i<$issueWidth; $i++)
{
print <<LABEL;
		grantedPacket${i}_o <= 0;
LABEL
}

print <<LABEL;
	end
	else
	begin
LABEL


for($i=0; $i<$issueWidth; $i++)
{
print <<LABEL;
		grantedValid${i}_o  <= grantedValid${i}_i;
LABEL
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
print <<LABEL;
		if(grantedValid${i}_i)
			grantedPacket${i}_o <= grantedPacket${i}_i;
LABEL
}

print <<LABEL;
	end
end

endmodule
LABEL

