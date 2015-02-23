#!/usr/bin/perl
#use strict; # Keep this commented
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
# Purpose: This script creates a Verilog module of the CASCADED select tree.
################################################################################

my $version = "3.0";

my $scriptName;
my $moduleName;
my $minEssentialCLIArgs = 3;

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

my $cascade;
my @cascadeName;

my $printHeader = 0;
my $outputFileName;

my $i;
my $j;
my $k;
my $c;
my $temp;
my $temp2;
my $comma;

sub fatalUsage
{
	print "Usage: perl $scriptName -w <width> -c <cascade> -d <size> [-t] [-e] [-m] [-v] [-h]\n";
	print "\t-w: <width> number of issue queue entries\n";
	print "\t-c: Select tree selects <cascade> entries\n";
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
	elsif(/^-c$/) 
	{
		$cascade = shift;
		$essentialCLIArgs++;
		$temp++;
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

# Create an array A, B, C ... for cascade tree variables
$temp = 'A';
foreach(0 .. $cascade-1)
{
	$cascadeName[$_] = chr(ord($temp)+$_);
}

$moduleName = "Select$cascade";
$outputFileName = "IssueQSelect_c$cascade.v";

# Calculate the widths of the different levels
$temp = $width;
$i = 0;
while($temp > 1)
{
	$levelWidths[$i] = $temp; # Apparently, this is the better way in perl, rather than @levelWidths[$i]
	
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
# Purpose: This module implements CASCADED select tree made out of $selectBlockWidth:$cascade select 
#	   blocks
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL

# Start of module header
print <<LABEL;

module $moduleName(input wire clk,
	input wire reset,
	input wire [`SIZE_ISSUEQ-1:0] requestVector_i,
LABEL

for($c=0; $c<$cascade; $c++)
{
	print "\tinput wire grant$cascadeName[$c]_i,\n";
}
print "\n";

if($muxTags == 1)
{
	print "/* physical destination tag of the requesting instruction + its valid bit */\n";
	for($i=0; $i<$width; $i++)
	{
		# Note that we are muxing the tag+its valid bit hence SIZE_PHYSICAL_LOG+1 bits
		print "\tinput wire [`SIZE_PHYSICAL_LOG:0] reqTag${i}_i,\n";
	}
}

for($c=0; $c<$cascade; $c++)
{
	print "\toutput wire grantedValid$cascadeName[$c]_o,\n";
}

if($encodedGrant == 1)
{
	for($c=0; $c<$cascade; $c++)
	{
		print "\toutput wire [`SIZE_ISSUEQ_LOG-1:0] grantedEntry$cascadeName[$c]_o,\n";
	}
}

for($c=0; $c<$cascade; $c++)
{
	if($c != $cascade-1 or $muxTags == 1)
	{
		$comma = ",";
	}
	else
	{
		$comma = "";
	}
	print "\toutput wire [`SIZE_ISSUEQ-1:0] grantedVector$cascadeName[$c]_o$comma";
	print "\n";

}

if($muxTags == 1)
{
	for($c=0; $c<$cascade; $c++)
	{
		if($c != $cascade-1)
		{
			$comma = ",";
		}
		else
		{
			$comma = "";
		}


		print <<LABEL;
	output wire [`SIZE_PHYSICAL_LOG:0] grantedTag$cascadeName[$c]_o$comma
LABEL
	}
}


print <<LABEL;
);

LABEL
# End of module header

# Mid section
print <<LABEL;
/* Wires and regs for the combinational logic */
/* Wires for outputs */
LABEL

for($c=0; $c<$cascade; $c++)
{
	print "wire [`SIZE_ISSUEQ-1:0] grantedVector$cascadeName[$c];\n";
}

if($encodedGrant)
{
	for($c=0; $c<$cascade; $c++)
	{
		print "wire [`SIZE_ISSUEQ_LOG-1:0] grantedEntry$cascadeName[$c];\n";
	}
}
print "\n";

print <<LABEL;
/* reqOut signals propagating forwards from the back of the select tree to the front */
LABEL

for($i=0; $i<$levels; $i++)
{
	for($c=0; $c<$cascade; $c++)
	{
		for($j=0; $j<$levelSelectBlocks[$i]; $j++)
		{
			print "wire reqOut$cascadeName[$c]_u", $i, "_", $j, ";\n";
		}
	}
	print "\n";
}

print <<LABEL;
/* grantIn signals propagating backwards from the front of the select tree */
LABEL

for($i=0; $i<$levels; $i++)
{
	for($c=0; $c<$cascade; $c++)
	{
		for($j=0; $j<$levelSelectBlocks[$i]; $j++)
		{
			print "wire grantIn$cascadeName[$c]_u", $i, "_", $j, ";\n";
		}
	}
	print "\n";
}

if($muxTags == 1)
{
	print "/* Wires to pass the tag + valid bit forward */\n";
	for($c=0; $c<$cascade; $c++)
	{
		for($i=0; $i<$levels; $i++)
		{
			for($j=0; $j<$levelSelectBlocks[$i]; $j++)
			{
				print "wire [`SIZE_PHYSICAL_LOG:0] tag$cascadeName[$c]_u", $i, "_", $j, ";\n";
			}
			print "\n";
		}
	}
}

print <<LABEL;
/* Assign enable signal */
LABEL

for($c=0; $c<$cascade; $c++)
{
	$temp = $levels-1;
	print "//assign grantIn$cascadeName[$c]_u${temp}_0 = grant$cascadeName[$c]_i\n"; 
	print "assign grantIn$cascadeName[$c]_u${temp}_0 = 1'b1; // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< TEMPORARY FIX\n"
}
print "\n";

#for($c=0; $c<$cascade; $c++)
#{
#	print "//assign grantIn$cascadeName[$c]_u${temp}_0 = (";
#	for($k=0; $k<$cascade; $k++)
#	{
#		print "grant$cascadeName[$k]_i"; 
#		if($k == $cascade-1)
#		{
#			print ") > 2'd$c ? 1'b1 : 1'b0;\n";
#		}
#		else
#		{
#			print " + ";
#		}
#	}
#	
#	print "assign grantIn$cascadeName[$c]_u${temp}_0 = 1'b1; // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< TEMPORARY FIX\n"
#}


print <<LABEL;
/* Assign outputs */
LABEL

for($c=0; $c<$cascade; $c++)
{
	$temp = $levels-1;
	print "assign grantedValid$cascadeName[$c]_o = reqOut$cascadeName[$c]_u${temp}_0;\n";
}

for($c=0; $c<$cascade; $c++)
{
	print "assign grantedVector$cascadeName[$c]_o = grantedVector$cascadeName[$c];\n";
}

for($c=0; $c<$cascade; $c++)
{
	print "assign grantedEntry$cascadeName[$c]_o = grantedEntry$cascadeName[$c];\n";
}

if($muxTags == 1)
{
	$temp = $levels-1;
	for($c=0; $c<$cascade; $c++)
	{
		print "assign grantedTag$cascadeName[$c]_o = tag$cascadeName[$c]_u", $temp, "_0;\n";
	}
}

print <<LABEL;

integer i;

LABEL
# End of mid section


if($encodedGrant == 1)
{
	print <<LABEL;
/* Instantiate the encoder */
LABEL

	for($c=0; $c<$cascade; $c++)
	{
		print <<LABEL;
Encoder #(`SIZE_ISSUEQ, `SIZE_ISSUEQ_LOG) grantEncoder$cascadeName[$c](.vector_i(grantedVector$cascadeName[$c]),
	.encoded_o(grantedEntry$cascadeName[$c])
);

LABEL
	}

}

# Building of the tree
for($i=0; $i<$levels; $i++) # For each level
{
	$temp = $levelWidths[$i+1]*$cascade; # This is why $levelWidths[$level] (a non-existent level) was set at 1
	if($i == 0)
	{
		$temp2 = $levelWidths[$i];
	}
	else
	{
		$temp2 = $levelWidths[$i]*$cascade;
	}
	print "/******************************************\n";
	print "* Stage $i (deals with $temp2 -> $temp conversion) *\n";
	print "******************************************/\n\n";
	
	for($j=0; $j<$levelSelectBlocks[$i]; $j++) # For each block in a level
	{
		print "/* Stage $i, select block $j */\n";
		$temp = "cascadedSelectBlock_c${cascade}_";
		if($muxTags == 1)
		{
			$temp = $temp."t_";
		}
		print $temp, $levelSelectBlockWidth[$i], " U", $i, "_", $j, "(\n";
	
		# .reqx_i
		for($c=0; $c<$cascade; $c++)
		{
			for($k=0; $k<$levelSelectBlockWidth[$i]; $k++) # For each input in a block in a level
			{
				print "\t";
				if($i == 0) # 0th stage, requestVector_i are the inputs
				{
						if($c == 0)
						{
							$temp = $levelSelectBlockWidth[$i]*$j + $k;
							print ".req$cascadeName[$c]", $k, "_i(requestVector_i[", $temp, "]),\n";
						}
						else # All requests to 0th stage are zero except As.
						{
							print ".req$cascadeName[$c]", $k, "_i(1'b0),\n";
						}
							
				}
				else # Remaining stages, reqOut are the inputs
				{
					$temp = $levelSelectBlockWidth[$i]*$j + $k;
					$temp2 = $i-1;
					print ".req$cascadeName[$c]", $k, "_i(reqOut$cascadeName[$c]_u", $temp2, "_", $temp,"),\n";
				}
			}
		}
		print "\n";
		
		# .tagx_i
		if($muxTags == 1)
		{
			for($c=0; $c<$cascade; $c++)
			{
				for($k=0; $k<$levelSelectBlockWidth[$i]; $k++)
				{
					if($i == 0) # 0th stage, reqTag_i are the inputs for all A, B, C etc.
					{
						$temp = $levelSelectBlockWidth[$i]*$j + $k;
						print "\t.tag$cascadeName[$c]", $k, "_i(reqTag", $temp, "_i),\n";
					}			
					else
					{
						$temp = $levelSelectBlockWidth[$i]*$j + $k;
						$temp2 = $i-1;
						print "\t.tag$cascadeName[$c]", $k, "_i(tag$cascadeName[$c]_u", $temp2, "_", $temp,"),\n";
					}
				}
			}
		}
			
		# .grant_i and .req_o
		for($c=0; $c<$cascade; $c++)
		{
			print "\t.grant$cascadeName[$c]_i(grantIn$cascadeName[$c]_u", $i, "_", "$j", "),\n";
		}
		print "\n";

		# .grantx_i
		for($c=0; $c<$cascade; $c++)
		{
			for($k=0; $k<$levelSelectBlockWidth[$i]; $k++)
			{
				if($i == 0) # 0th stage
				{
					$temp = $levelSelectBlockWidth[$i]*$j + $k;
					print "\t.grant$cascadeName[$c]", $k, "_o(grantedVector$cascadeName[$c]\[", $temp, "]),\n";
				}
				else # Remaining stages, reqOut are the inputs
				{
					$temp = $levelSelectBlockWidth[$i]*$j + $k;
					$temp2 = $i-1;
					print "\t.grant$cascadeName[$c]", $k, "_o(grantIn$cascadeName[$c]_u", $temp2, "_", $temp,"),\n";
				}
			}
		}
		print "\n";
		
		# .tag_o				
		if($muxTags == 1)
		{
			for($c=0; $c<$cascade; $c++)
			{
				print "\t.tag$cascadeName[$c]_o(tag$cascadeName[$c]_u", $i, "_", "$j", "),\n";
			}
		}

		for($c=0; $c<$cascade; $c++)
		{
			print "\t.req$cascadeName[$c]_o(reqOut$cascadeName[$c]_u", $i, "_", "$j", ")";
			if($c == $cascade-1)
			{
				print "\n";
			}
			else
			{
				print ",\n";
			}
		}
		
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
	print `perl generate_cascadedSelectBlock.pl -t -w $selectBlockWidth -c $cascade`;
}
else
{
	print `perl generate_cascadedSelectBlock.pl -w $selectBlockWidth -c $cascade`;
}
print "\n\n";

$temp = $levelWidths[$levels-1];
if($temp != $selectBlockWidth)
{
	if($muxTags)
	{
		print `perl generate_cascadedSelectBlock.pl -t -w $temp -c $cascade`;
	}
	else
	{
		print `perl generate_cascadedSelectBlock.pl -w $temp -c $cascade`;
	}

	print "\n\n";
}

print `perl generate_PriorityEncoder.pl`;
print "\n\n";

print `perl generate_Encoder.pl`;
print "\n";

if($muxTags)
{
	$temp = $selectBlockWidth*$cascade;
	print `perl generate_DecodedMux.pl -w $temp`;
	print "\n\n";

	$temp2 = $levelWidths[$levels-1];
	if($temp2 != $selectBlockWidth)
	{
		$temp = $temp2*$cascade;
		print `perl generate_DecodedMux.pl -w $temp`;
		print "\n\n";
	}
}

