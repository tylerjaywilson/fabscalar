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
# Purpose: This script creates a mux with one-hot select lines.
################################################################################

my $version = "3.0";

my $scriptName;
my $moduleName;
my $minEssentialCLIArgs = 1;

my $width;

my $temp;
my $i;

sub fatalUsage
{
	print "Usage: perl $scriptName -w <width> [-v] [-h]\n";
	print "\t-w: <width> select lines (one-hot)\n";
	print "\t-v: Print version and exit\n";
	print "\t-h: Show usage help and exit\n";
	exit;
}

### START HERE ###

# Get this scripts name
$scriptName = $0;

# Check mandatory command line arguments
my $essentialCLIArgs = 0;
while(@ARGV)
{
	$_ = shift;
	if(/^-h$/)
	{
		&fatalUsage();
	}
	elsif(/^-w$/)
	{
		$width = shift;
		$essentialCLIArgs++;
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
	print "Error: Too few mandatory input arguments.\n";
	&fatalUsage();
}

# Make module name
$moduleName = "DecodedMux_".$width;

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
module $moduleName(
	sel_i,
LABEL

for($i=0; $i<$width; $i++)
{
	print <<LABEL;
	tag${i}_i,
LABEL
}
print "\n";

$temp = $width-1;
print <<LABEL;
	tag_o
);

parameter TAG_WIDTH = 8;

/* Input and output wires and regs */
input wire [$temp:0] sel_i;
LABEL

for($i=0; $i<$width; $i++)
{
	print <<LABEL;
input wire [TAG_WIDTH-1:0] tag${i}_i;
LABEL
}
print "\n";

$temp = $width-1;
print <<LABEL;
output wire [TAG_WIDTH-1:0] tag_o;

/* Wires for combinational logic */
reg [$temp:0] inverter [TAG_WIDTH-1:0];
reg [TAG_WIDTH-1:0] tag;

/* Assign outputs */
assign tag_o = tag;

/* Transpose the tags after ANDing with sel */
always @(*)
begin: GENERATE_INVERTER
	integer i;

	for(i=0; i<TAG_WIDTH; i=i+1)
	begin
LABEL

for($i=0; $i<$width; $i++)
{
	print <<LABEL;
		inverter[i][$i] = tag${i}_i[i] & sel_i[$i];
LABEL
}
		
print <<LABEL;
	end
end

/* Do row-wise OR */
always @(*)
begin: ROWWISE_OR
	integer i;

	for(i=0; i<TAG_WIDTH; i=i+1)
	begin
		tag[i] = |inverter[i];
	end
end

endmodule
LABEL
