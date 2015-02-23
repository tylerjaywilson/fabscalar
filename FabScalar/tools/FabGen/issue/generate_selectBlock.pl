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
# Purpose: This script creates Verilog for a basic select block (Palacharla-style) 
#	   capable of muxing physical tags.
################################################################################

my $version = "3.0";

my $scriptName;
my $moduleName;
my $minEssentialCLIArgs = 1;

my $width = 4;
my $widthLog = 2;
my $muxTags = 0;

my $i;
my $temp;
my $comma;

sub fatalUsage
{
	print "Usage: perl $scriptName -w <width> [-t] [-v] [-h]\n";
	print "\t-w: Select block width of <width>\n";
	print "\t-t: Include a mux for selecting destination physical tags\n";
	print "\t-v: Print version and exit\n";
	print "\t-h: Show usage help and exit\n";
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

# Check mandatory command line arguments
my $essentialCLIArgs = 0;
while(@ARGV)
{
	$_ = shift;
	if(/^-w$/) 
	{
		$width = shift;
		$widthLog = log2($width);
		$essentialCLIArgs++;
	}
	elsif(/^-t$/)
	{
		$muxTags = 1;
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
	print "Error: Too few inputs\n";
	&fatalUsage();
}

# Include the parameter file if tags are to be muxed - Going to be included anyway
#if($muxTags == 1)
#{
#	print <<LABEL;
#`include "/afs/eos.ncsu.edu/lockers/research/ece/ericro/users/hmayukh/cvs/FabScalar/beta/verilog/FabScalarParam.v"
#LABEL
#}

# Create module name
$moduleName = "selectBlock_";
if($muxTags == 1)
{
	$moduleName = $moduleName."t_";
}
$moduleName = $moduleName.$width;

# Module header
print "module $moduleName(\n";

for($i=0; $i<$width; $i++)
{
	print <<LABEL;
	input wire req${i}_i,
LABEL
}

if($muxTags == 1)
{
	print "\n\t/* Destination's physical register tag + its valid bit */\n";
	for($i=0; $i<$width; $i++)
	{
		print "\tinput wire [`SIZE_PHYSICAL_LOG:0] tag${i}_i,\n";
	}
}

print "\n\t/* The grant signal coming in from the next stage of the select tree */\n";
print "\tinput wire grant_i,\n";
print "\n";

for($i=0; $i<$width; $i++)
{
	print <<LABEL;
	output wire grant${i}_o,
LABEL
}

if($muxTags == 1)
{
	print "\n\t/* This is the (tag + valid bit) selected among the $width input tags */\n";
	print "\toutput wire [`SIZE_PHYSICAL_LOG:0] tag_o,\n";
}

print "\n\t/* OR of the request signals, used as req_i for next stage of the select tree */\n";
print "\toutput wire req_o\n";

print ");\n\n";
# End of module header

# Wires and registers for combinational logic
$temp = $width-1;
print <<LABEL;
/* Wires and registers for combinatinal logic */
wire [$temp:0] req;
wire [$temp:0] grant;

LABEL
# End of wires and registers for combinational logic

print "/* Code to deal with vectors instead of individual wires */\n";
print "assign req = {";
for($i=$width-1; $i>=0; $i--) # This is done from higher request to lower request, just like any other array
{
	if($i != 0)
	{
		$comma = ", ";
	}
	else
	{
		$comma = "";
	}

	print "req${i}_i$comma";
}
print "};\n\n";

print "/* Gate the current grant output with the grant_i from the next stage of the select tree */\n";
for($i=0; $i<$width; $i++)
{
	print "assign grant${i}_o = grant[${i}] & grant_i;\n";
}
print "\n";

print <<LABEL;
/* Create the OR gate */
assign req_o = |req;

LABEL

# The priority logic
print <<LABEL;
/* Create the priority logic */
PriorityEncoder #($width) selectBlockPEncoder(
	.vector_i(req),
	.vector_o(grant)
);

LABEL

# always @(*)
# begin
# 	grant = 0;	
# 
# LABEL
# 
# print "\t";
# for($i=0; $i<$width; $i++)
# {
# 	$temp = sprintf("%0${widthLog}b", $i);
# 	print "if(req[${widthLog}'b$temp] == 1'b1)\n";
# 	print "\tbegin\n";	
# 	print "\t\tgrant[${widthLog}'b$temp] = 1'b1;\n";
# 	print "\tend\n";
# 	
# 	if($i < $width-1)
# 	{
# 		print "\telse ";
# 	}
# }
# print "end\n\n";
# # End of priority logic

# Tag mux
if($muxTags == 1)
{
print <<LABEL;
/* Create the tag select mux */
DecodedMux_$width #(`SIZE_PHYSICAL_LOG+1) selectBlockDecodedMux(
	.sel_i(grant),
LABEL

	for($i=0; $i<$width; $i++)
	{
		print "\t.tag${i}_i(tag${i}_i),\n"; 
	}

print <<LABEL
	.tag_o(tag_o)
);

LABEL
}

# always @(*)
# begin
# 	tag_o = 0;
# 
# 	/* The vector grant is one-hot */
# LABEL
# 
# 	print "\t";
# 	for($i=0; $i<$width; $i++)
# 	{
# 		print "if(grant[${i}] == 1'b1)\n";
# 		print "\tbegin\n";
# 		print "\t\ttag_o = tag${i}_i;\n";
# 		print "\tend\n";
# 	
# 		if($i < $width-1)
# 		{
# 			print "\telse ";
# 		}
# 	}	
# 	print "end\n\n";
# }
# # End of tag  mux

print "endmodule\n";

