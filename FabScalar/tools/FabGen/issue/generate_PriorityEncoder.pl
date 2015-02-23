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
# Purpose: This script creates a priority encoder.
################################################################################

my $version = "3.0";

my $scriptName;
my $minNoCliArgs = 0;
my $minEssentialCLIArgs = 0;

sub fatalUsage
{
	print "Usage: perl $scriptName [-v] [-h]\n";
	print "\t-v: Print version and exit\n";
	print "\t-h: Show usage help and exit\n";
	exit;
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
	if(/^-h$/)
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
	print "Error: Too few mandatory input arguments.\n";
	&fatalUsage();
}

print <<LABEL;
module PriorityEncoder(vector_i,
	vector_o
);

parameter ENCODER_WIDTH = 32;

/* I/O definitions */
input wire [ENCODER_WIDTH-1:0] vector_i;
output wire [ENCODER_WIDTH-1:0] vector_o;

/* Wires and regs for combinational logic */

/* Mask to reset all other bits except the first */
reg [ENCODER_WIDTH-1:0] mask;

/* Wires for outputs */
wire [ENCODER_WIDTH-1:0] vector;

/* Assign outputs */
assign vector_o = vector;

/* Mask the input vector so that only the first 1'b1 is seen */
assign vector = vector_i & mask;

integer j;

always @(*)
begin: ENCODER_CONSTRUCT
	mask[0] = 1'b1;

	for(j=1; j<ENCODER_WIDTH; j=j+1)
	begin
		if(vector_i[j-1] == 1'b1)
			mask[j] = 0;
		else
			mask[j] = mask[j-1];
	end
end

endmodule
LABEL

