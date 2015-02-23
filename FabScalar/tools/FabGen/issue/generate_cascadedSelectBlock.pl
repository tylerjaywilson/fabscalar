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
# Purpose: This script creates Verilog for a select block for a cascaded select 
#	   tree
################################################################################

my $version = "3.0";

my $scriptName;
my $moduleName;
my $minEssentialCLIArgs = 2;

my $width = 4;
my $widthLog = 2;
my $muxTags = 0;
my $cascade;
my @cascadeName;

my $i;
my $k;
my $count;
my $c;
my $temp;
my $temp2;
my $temp3;
my $comma;

sub fatalUsage
{
	print "Usage: perl $scriptName -w <width> -c <cascade> [-t] [-v] [-h]\n";
	print "\t-w: Issue width of <width>\n";
	print "\t-t: Include a mux for selecting destination physical tags\n";
	print "\t-c: <cascade>-cascaded select tree (must be >1)\n";
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
	elsif(/^-c$/) 
	{
		$cascade = shift;
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

# Create an array A, B, C ... for cascade tree variables
$temp = 'A';
foreach(0 .. $cascade-1)
{
	$cascadeName[$_] = chr(ord($temp)+$_);
}

# Include the parameter file if tags are to be muxed - Going to be included anyway.
#if($muxTags == 1)
#{
#	print <<LABEL;
#`include "/afs/eos.ncsu.edu/lockers/research/ece/ericro/users/hmayukh/cvs/FabScalar/beta/verilog/FabScalarParam.v"
#LABEL
#}

# Create module name
$moduleName = "cascadedSelectBlock_c${cascade}_";
if($muxTags == 1)
{
	$moduleName = $moduleName."t_";
}
$moduleName = $moduleName.$width;


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

# Module header
print "module ", $moduleName, "(\n";

for($c=0; $c<$cascade; $c++)
{
	for($i=0; $i<$width; $i++)
	{
		print "\tinput wire req$cascadeName[$c]${i}_i,\n";
	}
}
print "\n";

if($muxTags == 1)
{
	print "\t/* Destination's physical register tag + its valid bit */\n";
	for($c=0; $c<$cascade; $c++)
	{
		for($i=0; $i<$width; $i++)
		{
			print "\t", "input wire [`SIZE_PHYSICAL_LOG:0] tag$cascadeName[$c]${i}_i,\n";
		}
	}
}
print "\n";

for($c=0; $c<$cascade; $c++)
{
	print "\tinput wire grant$cascadeName[$c]_i,\n";
}
print "\n";

for($c=0; $c<$cascade; $c++)
{
	for($i=0; $i<$width; $i++)
	{
		print "\t", "output wire grant$cascadeName[$c]${i}_o,\n";
	}
}
print "\n";

if($muxTags == 1)
{
	print "\t/* These are the (tag + valid bit) selected among the $width input tags */\n";

	for($c=0; $c<$cascade; $c++)
	{
		print "\toutput wire [`SIZE_PHYSICAL_LOG:0] tag$cascadeName[$c]_o,\n";
	}
}
print "\n";

for($c=0; $c<$cascade; $c++)
{
	if($c == $cascade-1)
	{
		$comma = "";
	}
	else
	{
		$comma = ",";
	}

	print "\toutput wire req$cascadeName[$c]_o$comma\n";
}

print ");\n\n";
# End of module header

# Wires and registers for combinational logic
print <<LABEL;
/* Wires and registers for combinatinal logic */
LABEL

for($c=0; $c<$cascade; $c++)
{
	$temp = $width-1;
	print "wire [$temp:0] req$cascadeName[$c];\n";
}
print "\n";

for($c=0; $c<$cascade; $c++)
{
	$temp = $width-1;
	print "reg [$temp:0] grant$cascadeName[$c];\n";
}
print "\n";

for($c=0; $c<$cascade; $c++)
{
	$temp = $width-1;
	$temp2 = $c+1;
	print "wire [$temp:0] t$temp2;\n";
}
print "\n";

for($c=0; $c<$cascade; $c++)
{
	$temp = $width*$cascade-1;
	$temp2 = $c+1;
	print "wire [$temp:0] sFull$temp2;\n";
}
print "\n";

for($c=0; $c<$cascade; $c++)
{
	$temp = $width*$cascade-1;
	$temp2 = $c+1;
	print "wire [$temp:0] tFull$temp2;\n";
}
print "\n";
# End of wires and registers for combinational logic

print "/* Assign outputs */\n";
for($c=0; $c<$cascade; $c++)
{
	printf "assign {";
	for($i=$width-1; $i>=0; $i--)
	{
		if($i == 0)
		{
			$comma = "";
		}
		else
		{
			$comma = ", ";
		}

		print "grant$cascadeName[$c]${i}_o$comma";
	}
	print "} = grant$cascadeName[$c];\n";
}
print "\n";

print "/* Code to deal with vectors instead of individual wires */\n";
for($c=0; $c<$cascade; $c++)
{
	print "assign req$cascadeName[$c] = {";
	for($i=$width-1; $i>=0; $i--) # This is done from higher request to lower request, just like any other array
	{
		if($i == 0)
		{
			$comma = "";
		}
		else
		{
			$comma = ", ";
		}
		print "req$cascadeName[$c]${i}_i$comma";
	}
	print "};\n";
}
print "\n";

print <<LABEL;
/* Generate temporary sFull vectors */
LABEL

print "assign sFull1 = {";
for($i=$width-1; $i>=0; $i--)
{
	for($c=$cascade-1; $c>=0; $c--)
	{
		$comma = ", ";
		if($i==0 && $c==0)
		{
			$comma = "";
		}

		print "req$cascadeName[$c]\[$i\]$comma";
	}
}
print "};\n";
		
for($c=1; $c<$cascade; $c++)
{
	$temp = $c+1;
	print "assign sFull$temp = sFull$c & (~tFull$c);\n";
}
print "\n";


print <<LABEL;
/* Generate the t vectors */
LABEL

for($c=0; $c<$cascade; $c++)
{
	$temp = $c+1;
	print "assign t$temp = {";
	for($i=$width*$cascade; $i>0; $i=$i-$cascade)
	{
		$temp = $i-1;
		$temp2 = $i-$cascade;
		if($i==$cascade)
		{
			$comma = "";
		}
		else
		{
			$comma = ", ";
		}

		$temp3 = $c+1;
		print "|tFull$temp3\[$temp:$temp2]$comma";
	}
	print "};\n";
}
print "\n";

print <<LABEL;
/* Priority encoders */
LABEL

$temp2 = $cascade*$width;
for($c=0; $c<$cascade; $c++)
{
	$temp = $c+1;
	print <<LABEL;
PriorityEncoder #($temp2) tFull${temp}PEncoder(.vector_i(sFull$temp),
	.vector_o(tFull$temp)
);

LABEL
}

print <<LABEL;
/* Generate the OR gates for the req_o */
LABEL

for($c=0; $c<$cascade; $c++)
{
	$temp = $c+1;
	print "assign req$cascadeName[$c]_o = |sFull$temp;\n";
}
print "\n";

# Tag mux
if($muxTags == 1)
{
print <<LABEL;
/* Create the tag select mux */
LABEL

	for($c=0; $c<$cascade; $c++)
	{
		$temp = $c+1;
		$temp2 = $cascade*$width;
		print <<LABEL;		
DecodedMux_$temp2 #(`SIZE_PHYSICAL_LOG+1) selectBlockDecodedMux$temp(
	.sel_i(tFull$temp),
LABEL

		for($i=0; $i<$width; $i++)
		{
			for($k=0; $k<$cascade; $k++)
			{
				$temp = $i*$cascade+$k;
				print "\t.tag${temp}_i(tag$cascadeName[$k]${i}_i),\n"; 
			}
		}

		print <<LABEL
	.tag_o(tag$cascadeName[$c]_o)
);

LABEL
	}
	print "\n";
}

print <<LABEL;
/* Assign grant */
always @(*)
begin: GRANT_ASSIGNMENT_SELECT_BLOCK
LABEL

for($c=0; $c<$cascade; $c++)
{
	print "\tgrant$cascadeName[$c] = 0;\n";
}
print "\n";

print "\tcase({";

for($c=0; $c<$cascade; $c++)
{
	print "grant$cascadeName[$c]_i";
	if($c == $cascade - 1)
	{
		print "})\n";
	}
	else
	{
		print ", ";
	}
}

for($i=1; $i<2**$cascade; $i++) # Not from zero
{
	$temp = sprintf("%0${cascade}b", $i);
	print "\t\t${cascade}'b$temp:\n";
	print "\t\tbegin\n";

	$count = 0;
	for($k=0; $k<$cascade; $k++)
	{
		if((2**($cascade-1)>>$k) & $i)
		{
			$count++;
			print "\t\t\tgrant$cascadeName[$k] = t$count;\n";
		}	
	}
	print "\t\tend\n";
}

print <<LABEL;
	endcase
end

endmodule
LABEL

