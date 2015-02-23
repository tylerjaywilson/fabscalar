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
# Purpose: This script creates a Verilog module of the select tree.
################################################################################

my $version = "3.0";

my $scriptName;
my $moduleName;
my $minEssentialCLIArgs = 2;

my $width = 32; # Number of request signals handled by the select tree
my $muxTags = 0;
my $encodedGrant = 0;

my $selectBlockWidth = 4; # The basic select block used will be of the ratio $selectBlockWidth:1
my $selectBlockWidthLog = 2;
my $levels;
my @levelWidths; # Array with the widths (number of request signals processed) of each level
my @levelSelectBlocks; # Array with number of select blocks at each level
my @levelSelectBlockWidth; # Array with the width of the basic select block at each level = $selectBlockWidth for all levels except, perhaps, the last
my @levelSelectBlockWidthLog;

my $printHeader = 0;
my $outputFileName;

my $i;
my $j;
my $k;
my $temp;
my $temp2;

sub fatalUsage
{
	print "Usage: perl $scriptName -w <width> -d <size> [-t] [-e] [-m] [-v] [-h]\n";
	print "\t-w: <width> number of issue queue entries\n";
	print "\t-d: <size>:1 basic select block is used to build this tree\n";
	print "\t-t: Grab destination physical tags and selects one\n";
	print "\t-e: Outputs granted entry in addition to granted vector\n";
	print "\t-m: Add header\n";
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
		$essentialCLIArgs++;
	}
	elsif(/^-d$/)
	{
		$selectBlockWidth = shift;
		$selectBlockWidthLog = log2($selectBlockWidth);
		$essentialCLIArgs++;
	}
	elsif(/^-t$/)
	{
		$muxTags = 1;
	}
	elsif(/^-e$/)
	{
		$encodedGrant = 1;
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
	print "Error: Too few inputs\n";
	&fatalUsage();
}

$moduleName = "Select";
$outputFileName = "IssueQSelect.v";

# Calculate the widths of the different levels
$temp = $width;
$i = 0;
while($temp > 1)
{
	$levelWidths[$i] = $temp;
	
	$levelSelectBlocks[$i] = $levelWidths[$i]/$selectBlockWidth;
	if($levelSelectBlocks[$i] < 1)
	{
		$levelSelectBlocks[$i] = 1;
	}
	$levelSelectBlockWidth[$i] = $levelWidths[$i]/$levelSelectBlocks[$i]; # Must be $selectBlockWidth for all levels except, perhaps, the last
	$levelSelectBlockWidthLog[$i] = log2($levelSelectBlockWidth[$i]);

	$temp = $temp/$selectBlockWidth;
	$i++;
};
$levels = $i;
$levelWidths[$i] = 1; # A lame hack required for later use (to print a comment). Level $levels does not exist

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
# Purpose: $width:1 select tree made out of $selectBlockWidth:1 select blocks.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL

# Start of module header
print <<LABEL;

module $moduleName(input wire clk,
	input wire reset,
	input wire [`SIZE_ISSUEQ-1:0] requestVector_i,
	input wire grant_i,									/* Enable signal for the select tree */
LABEL

if($muxTags == 1)
{
	for($i=0; $i<$width; $i++)
	{
		# Note that we are muxing the tag+its valid bit hence SIZE_PHYSICAL_LOG+1 bits
		if($i == 0)
		{
			print "\tinput wire [`SIZE_PHYSICAL_LOG:0] reqTag", $i, "_i,\t\t/* physical destination tag of the requesting instruction + its valid bit */\n";
		}
		else
		{
			print "\tinput wire [`SIZE_PHYSICAL_LOG:0] reqTag", $i, "_i,\n";
		}
	}
}

print <<LABEL;

	output wire grantedValid_o,
LABEL

if($muxTags == 1)
{
	print <<LABEL;
	output wire [`SIZE_PHYSICAL_LOG:0] grantedTag_o,
LABEL
}

if($encodedGrant == 1)
{
	print <<LABEL;
	output wire [`SIZE_ISSUEQ_LOG-1:0] grantedEntry_o,	/* Encoded form of grantedVector_o */
LABEL
}

print <<LABEL;
	output wire [`SIZE_ISSUEQ-1:0] grantedVector_o	 	/* One-hot grant vector */
);

LABEL
# End of module header

# Mid section
print <<LABEL;
/* Wires and regs for the combinational logic */
/* Wires for outputs */
wire [`SIZE_ISSUEQ-1:0] grantedVector;
wire [`SIZE_ISSUEQ_LOG-1:0] grantedEntry;

LABEL

print <<LABEL;
/* reqOut signals propagating forwards from the back of the select tree to the front */
LABEL
for($i=0; $i<$levels; $i++)
{
	for($j=0; $j<$levelSelectBlocks[$i]; $j++)
	{
		print "wire reqOut_u", $i, "_", $j, ";\n";
	}
	print "\n";
}

print <<LABEL;
/* grantIn signals propagating backwards from the front of the select tree */
LABEL
for($i=0; $i<$levels; $i++)
{
	for($j=0; $j<$levelSelectBlocks[$i]; $j++)
	{
		print "wire grantIn_u", $i, "_", $j, ";\n";
	}
	print "\n";
}

if($muxTags == 1)
{
	print "/* Wires to pass the tag + valid bit forward */\n";
	for($i=0; $i<$levels; $i++)
	{
		for($j=0; $j<$levelSelectBlocks[$i]; $j++)
		{
			print "wire [`SIZE_PHYSICAL_LOG:0] tag_u", $i, "_", $j, ";\n";
		}
		print "\n";
	}
}

print <<LABEL;
/* Assign enable signal */
assign grantIn_u1_0 = grant_i | 1'b1; // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< TEMPORARY FIX 

/* Assign outputs */
assign grantedValid_o = reqOut_u1_0;
assign grantedVector_o = grantedVector;
assign grantedEntry_o = grantedEntry;
LABEL

if($muxTags == 1)
{
	$temp = $levels-1;
	print "assign grantedTag_o = tag_u", $temp, "_0;\n";
}

print <<LABEL;

integer i;

LABEL
# End of mid section

if($encodedGrant == 1)
{
print <<LABEL;
/* Instantiate the encoder */
Encoder #(`SIZE_ISSUEQ, `SIZE_ISSUEQ_LOG) grantEncoder(.vector_i(grantedVector),
	.encoded_o(grantedEntry)
);

LABEL
}

# Building of the tree
for($i=0; $i<$levels; $i++) # For each level
{
	$temp = $levelWidths[$i+1]; # This is why $levelWidths[$level] (a non-existent level) was set at 1
	print "/******************************************\n";
	print "* Stage $i (deals with $levelWidths[$i] -> $temp conversion) *\n";
	print "******************************************/\n\n";
	
	for($j=0; $j<$levelSelectBlocks[$i]; $j++) # For each block in a level
	{
		print "/* Stage $i, select block $j */\n";
		$temp = "selectBlock_";
		if($muxTags == 1)
		{
			$temp = $temp."t_";
		}
		print $temp, $levelSelectBlockWidth[$i], " U", $i, "_", $j, "(";
	
		# .reqx_i
		for($k=0; $k<$levelSelectBlockWidth[$i]; $k++) # For each input in a block in a level
		{
			if($k > 0)
			{
				print "\t";
			}
		
			if($i == 0) # 0th stage, requestVector_i are the inputs
			{
				$temp = $levelSelectBlockWidth[$i]*$j + $k;
				print ".req", $k, "_i(requestVector_i[", $temp, "]),\n";
			}
			else # Remaining stages, reqOut are the inputs
			{
				$temp = $levelSelectBlockWidth[$i]*$j + $k;
				$temp2 = $i-1;
				print ".req", $k, "_i(reqOut_u", $temp2, "_", $temp,"),\n";
			}
		}
		
		# .tagx_i
		if($muxTags == 1)
		{
			for($k=0; $k<$levelSelectBlockWidth[$i]; $k++)
			{
				if($i == 0) # 0th stage, reqTag_i are the inputs
				{
					$temp = $levelSelectBlockWidth[$i]*$j + $k;
					print "\t.tag", $k, "_i(reqTag", $temp, "_i),\n";
				}			
				else
				{
					$temp = $levelSelectBlockWidth[$i]*$j + $k;
					$temp2 = $i-1;
					print "\t.tag", $k, "_i(tag_u", $temp2, "_", $temp,"),\n";
				}
			}
		}
			
		# .grant_i and .req_o
		print "\t.grant_i(grantIn_u", $i, "_", "$j", "),\n";

		# .grantx_i
		for($k=0; $k<$levelSelectBlockWidth[$i]; $k++)
		{
			if($i == 0) # 0th stage
			{
				$temp = $levelSelectBlockWidth[$i]*$j + $k;
				print "\t.grant", $k, "_o(grantedVector[", $temp, "]),\n";
			}
			else # Remaining stages, reqOut are the inputs
			{
				$temp = $levelSelectBlockWidth[$i]*$j + $k;
				$temp2 = $i-1;
				print "\t.grant", $k, "_o(grantIn_u", $temp2, "_", $temp,"),\n";
			}
		}
		
		# .tag_o				
		if($muxTags == 1)
		{
			print "\t.tag_o(tag_u", $i, "_", "$j", "),\n";
		}

		print "\t.req_o(reqOut_u", $i, "_", "$j", ")\n";
		
		print ");\n\n";
	}
	
	if($i < $levels-1)
	{
		print "\n";
	}
}
# End of tree building

print "endmodule\n";
# End of module Select

# Print out sub-modules required by the module Select
print "\n\n";
if($muxTags)
{
	print `perl generate_selectBlock.pl -t -w $selectBlockWidth`;
}
else
{
	print `perl generate_selectBlock.pl -w $selectBlockWidth`;
}
print "\n\n";

$temp = $levelWidths[$levels-1];
if($temp != $selectBlockWidth)
{
	if($muxTags)
	{
		print `perl generate_selectBlock.pl -t -w $temp`;
	}
	else
	{
		print `perl generate_selectBlock.pl -w $temp`;
	}

	print "\n\n";
}

print `perl generate_Encoder.pl`;
print "\n\n";

print `perl generate_PriorityEncoder.pl`;
print "\n\n";

if($muxTags)
{
	print `perl generate_DecodedMux.pl -w $selectBlockWidth`;
	print "\n\n";

	$temp = $levelWidths[$levels-1];
	if($temp != $selectBlockWidth)
	{
		print `perl generate_DecodedMux.pl -w $temp`;
		print "\n\n";
	}
}

