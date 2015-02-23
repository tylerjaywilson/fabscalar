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
# Purpose: This script creates an one-hot encoder.
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
module Encoder(vector_i,
	encoded_o
);

parameter ENCODER_WIDTH = 32;
parameter ENCODER_WIDTH_LOG = 5;

/* I/O definitions */
input wire [ENCODER_WIDTH-1:0] vector_i;
output wire [ENCODER_WIDTH_LOG-1:0] encoded_o;

/* Temporary regs and wires */
reg [ENCODER_WIDTH_LOG-1:0] s [ENCODER_WIDTH-1:0]; // Stores number itself. 
reg [ENCODER_WIDTH_LOG-1:0] t [ENCODER_WIDTH-1:0]; // Stores (s[i] if vector[i]==1'b1 else stores 0)
reg [ENCODER_WIDTH-1:0] u [ENCODER_WIDTH_LOG-1:0]; // Stores transpose of t (to use the | operator)

/* Wires and regs for combinational logic */
reg [ENCODER_WIDTH-1:0] compareVector;

/* Wires for outputs */
reg [ENCODER_WIDTH_LOG-1:0] encoded;

/* Assign outputs */
assign encoded_o = encoded;

integer i;
integer j;

always @(*)
begin: ENCODER_CONSTRUCT
	for(i=0; i<ENCODER_WIDTH; i=i+1)
	begin
		s[i] = i;
	end

	for(i=0; i<ENCODER_WIDTH; i=i+1)
	begin
		if(vector_i[i] == 1'b1)
			t[i] = s[i];
		else
			t[i] = 0;
	end

	for(i=0; i<ENCODER_WIDTH; i=i+1)
	begin
		for(j=0; j<ENCODER_WIDTH_LOG; j=j+1)
		begin
			u[j][i] = t[i][j];
		end
	end

	for(j=0; j<ENCODER_WIDTH_LOG; j=j+1)
	begin
		encoded[j] = |u[j];
	end
end

endmodule
LABEL

