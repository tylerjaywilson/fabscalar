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
# Purpose: This script creates the bypass logic.
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
# Purpose: 
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL


print <<LABEL;

module ForwardCheck (
	input [`SIZE_PHYSICAL_LOG-1:0] srcReg_i,
	input [`SIZE_DATA-1:0] srcData_i,

LABEL

for($i=0; $i<$issueWidth; $i++)
{
print <<LABEL;
	input bypassValid${i}_i,		
	input [`SIZE_PHYSICAL_LOG-1:0] bypassTag${i}_i,
	input [`SIZE_DATA-1:0] bypassData${i}_i,
LABEL
}
print "\n";

print <<LABEL;
	output [`SIZE_DATA-1:0] dataOut_o
);	

 /* Defining wire and regs for combinational logic. */
 reg [`SIZE_DATA-1:0] dataOut;

 assign dataOut_o = dataOut;

always @(*)
begin:FORWARD_CHECK
LABEL


for($i=0; $i<$issueWidth; $i++)
{
print <<LABEL;
	reg match$i;
LABEL
}

print <<LABEL;
	reg match;
 
LABEL


for($i=0; $i<$issueWidth; $i++)
{
print <<LABEL;
	match$i = bypassValid${i}_i && (srcReg_i == bypassTag${i}_i);
LABEL
}
print "\n";

print "\tmatch  = ";
for($i=0; $i<$issueWidth; $i++)
{
	print "match$i";
	if($i == $issueWidth-1)
	{
		print ";\n\n";
	}
	else
	{
		print " | ";
	}
}

print <<LABEL;
	if(match)
	begin
LABEL

print "\t\tcase({";
for($i=$issueWidth-1; $i>=0; $i--)
{
	print "match$i";
	if($i == 0)
	{
		print "})\n";
	}
	else
	{
		print ",";
	}
}

for($i=0; $i<$issueWidth; $i++)
{
	my $onehot = sprintf("%0${issueWidth}b", 2**$i);

print <<LABEL;
			${issueWidth}'b$onehot: dataOut = bypassData${i}_i;
LABEL
}

print <<LABEL;
		endcase
	end
	else
		dataOut = srcData_i;
end

endmodule
LABEL
