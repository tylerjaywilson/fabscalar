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
# Purpose: This script creates Verilog for RSR.
################################################################################

my $version = "1.2";

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 5;

my $issueWidth;
my @instType; # Number of ways for each instruction type
my $typesOfFUs = 4; # HARDWIRED!
my $pipelined = 0; # If this is one, one shift FF is added to the RSR
my @simpleArray; # Holds the ways where a simple RSR is required (0 or 1 cycle depending on $pipelined)
my @complexArray; # Holds the ways where a complex RSR is required (multi-cycle)

my $printHeader = 0;

my $i;
my $j;
my $k;
my $temp;
my $comma;
my $tempCount;
my $tempStr;
my @t;

sub fatalUsage
{
	print "Usage: perl $scriptName -w <issue_width> -n A B C D -p [-m] [-v] [-h]\n";
	print "\t-n: Number of instructions of type 1 (A), type 2 (B), type 3 (C), type 4 (D)\n";
	print "\t-p: Pipelined RSR\n";
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
	elsif(/^-n$/) 
	{
		for($i=0; $i<$typesOfFUs; $i++)
		{
			$instType[$i] = shift;
			$essentialCLIArgs++;
		}
	}	
	elsif(/^-p$/)
	{
		$pipelined = 1;
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

$temp = 0;
($temp += $_) for @instType;
if($temp != $issueWidth)
{
	print "Error: Issue width must match total number of instructions of each type.\n";
	&fatalUsage();
}

# Create the simple and complex arrays
for($i=0; $i<$issueWidth-$instType[3]; $i++)
{
	if($i-$instType[0] >= 0 && $i-$instType[0] < $instType[1])
	{
		push(@complexArray, $i);
	}
	else
	{
		push(@simpleArray, $i);
	}
}

$outputFileName = "RSR.v";
$moduleName = "RSR";
if($pipelined == 1)
{
	$moduleName = $moduleName."2";
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
# Purpose: This module implements RSR.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps


/*
  Assumption:

  There are 4-Functional Units (Integer Type) including AGEN block which is a 
  dedicated FU for Load/Store.
     FU0  2'b00     // Simple ALU
     FU1  2'b01     // Complex ALU (for MULTIPLY & DIVIDE)
     FU2  2'b10     // ALU for CONTROL Instructions
     FU3  2'b11     // LOAD/STORE Address Generator

  Tag broadcast of the Load instruction is taken care by Load/Store Queue Unit 
  because of additional comlpexity of load miss.

  Algorithm:

  1. Each cycle RSR module receives physical tag of the 
     granted instructions (for only instruction type 0, 1 and 2)

  2. Physical destination tag for type 0/2 is broadcasted in the next 
     cycle only, as type 0/2 has single cycle execution latency.

  3. Physical destination tag for type 1 is broadcasted in FU1_LATENCY-2
     cycle only. Appropriate shift register is maintined for FU1 tag.

************************************************************************************/

LABEL

# Module header
print <<LABEL;
module $moduleName(
	input clk,
	input reset,

	input ctrlVerified_i,
	input ctrlMispredict_i,
	input [`CHECKPOINTS_LOG-1:0] ctrlSMTid_i,

LABEL

for($i=0; $i<$issueWidth-$instType[3]; $i++)
{
	print "\tinput validPacket", $i, "_i,\n";
}
print "\n";

for($i=0; $i<$issueWidth-$instType[3]; $i++)
{
	print "\tinput [`SIZE_PHYSICAL_LOG-1:0] granted", $i, "Dest_i,\n";
}
print "\n";

for($i=0; $i<$issueWidth-$instType[3]; $i++)
{
	print "\tinput [`CHECKPOINTS-1:0] branchMask${i}_i,\n";
}
print "\n";

for($i=0; $i<$issueWidth-$instType[3]; $i++)
{
	print "\toutput rsr", $i, "TagValid_o,\n";
}
print "\n";

for($i=0; $i<$issueWidth-$instType[3]; $i++)
{
	if($i == $issueWidth-$instType[3]-1)
	{
		$comma = "";
	}
	else
	{
		$comma = ",";
	}
	print "\toutput [`SIZE_PHYSICAL_LOG-1:0] rsr", $i, "Tag_o$comma\n";
}
print ");\n\n";
# Module head

print <<LABEL;
/* Instantiation of RSR for Complex ALU (type 1)
 */
LABEL

if($instType[1] <= 1)
{
	print <<LABEL;
reg [`SIZE_PHYSICAL_LOG-1:0] RSR_CALU [`FU1_LATENCY-2:0];
reg [`FU1_LATENCY-2:0] RSR_CALU_VALID;
reg [`CHECKPOINTS-1:0] BRANCH_MASK [`FU1_LATENCY-2:0];

LABEL
}
else
{
	for $i(@complexArray)
	{
	print <<LABEL;
reg [`SIZE_PHYSICAL_LOG-1:0] RSR_CALU_${i} [`FU1_LATENCY-2:0];
reg [`FU1_LATENCY-2:0] RSR_CALU_VALID_${i};
reg [`CHECKPOINTS-1:0] BRANCH_MASK_$i [`FU1_LATENCY-2:0];
LABEL
	}
	print "\n";
}

print "/* Wires and regs declaration for combinational logic */\n";
for($i=0; $i<$issueWidth-$instType[3]; $i++)
{
	print "reg validPacket$i;\n";
}
print "\n";

for($i=0; $i<$issueWidth-$instType[3]; $i++)
{
	print "reg [`SIZE_PHYSICAL_LOG-1:0] granted${i}Dest;\n";
}
print "\n";

for($i=0; $i<$issueWidth-$instType[3]; $i++)
{
	print "reg [`SIZE_PHYSICAL_LOG-1:0] branchMask${i};\n";
}
print "\n";

print <<LABEL;
/* Assign outputs */
LABEL

if($pipelined == 0) 
{
	foreach $i(@simpleArray)
	{
		print "assign rsr${i}Tag_o = (validPacket$i)? granted${i}Dest:0;\n";
	}
	print "\n";

	foreach $i(@simpleArray)
	{
		print "assign rsr${i}TagValid_o = validPacket${i};\n";
	}
	print "\n";
}
else
{
	foreach $i(@simpleArray)
	{
		print "assign rsr${i}Tag_o = (validPacket$i && ~(ctrlVerified_i && ctrlMispredict_i && branchMask$i\[ctrlSMTid_i]))? granted${i}Dest:0;\n";
	}
	print "\n";

	foreach $i(@simpleArray)
	{
		print "assign rsr${i}TagValid_o = validPacket${i} && ~(ctrlVerified_i && ctrlMispredict_i && branchMask$i\[ctrlSMTid_i]);\n";
	}
	print "\n";
}

if($instType[1] <= 1)
{
	$temp = $instType[0];
	print <<LABEL;
assign rsr${temp}Tag_o = (RSR_CALU_VALID[`FU1_LATENCY-2] && ~(ctrlVerified_i && ctrlMispredict_i && BRANCH_MASK[`FU1_LATENCY-2][ctrlSMTid_i])) ? RSR_CALU[`FU1_LATENCY-2]:0;
assign rsr${temp}TagValid_o =  RSR_CALU_VALID[`FU1_LATENCY-2] && ~(ctrlVerified_i && ctrlMispredict_i && BRANCH_MASK[`FU1_LATENCY-2][ctrlSMTid_i]);
LABEL
}
else
{	
	foreach $i(@complexArray)
	{
		print "assign rsr${i}Tag_o = (RSR_CALU_VALID_${i}\[`FU1_LATENCY-2] && ~(ctrlVerified_i && ctrlMispredict_i && BRANCH_MASK_${i}\[`FU1_LATENCY-2][ctrlSMTid_i])) ? RSR_CALU_${i}\[`FU1_LATENCY-2]:0;\n";
	}
	print "\n";

	foreach $i(@complexArray)
	{
		print "assign rsr${i}TagValid_o = RSR_CALU_VALID_${i}\[`FU1_LATENCY-2] && ~(ctrlVerified_i && ctrlMispredict_i && BRANCH_MASK_${i}\[`FU1_LATENCY-2][ctrlSMTid_i]);\n";
	}
	print "\n";
}
print "\n";

print <<LABEL;
/* The $pipelined-cycle delay */
LABEL

if($pipelined == 0)
{
	print <<LABEL;
always @(*)
begin
LABEL
	
	for($i=0; $i<$issueWidth-$instType[3]; $i++)
	{
		print <<LABEL;
	validPacket$i = validPacket${i}_i;
	granted${i}Dest = granted${i}Dest_i;
	branchMask${i} = branchMask${i}_i;
LABEL

		if($i != $issueWidth-$instType[3]-1)
		{
			print "\n";
		}
	}
	
	print <<LABEL;
end
LABEL

}
elsif($pipelined == 1)
{
	print <<LABEL;
always @(posedge clk)
begin
	if(reset)
	begin
LABEL
	
	for($i=0; $i<$issueWidth-$instType[3]; $i++)
	{
		print <<LABEL;
		validPacket$i <= 0;
		granted${i}Dest <= 0;
		branchMask${i} <= 0;
LABEL

		if($i != $issueWidth-$instType[3]-1)
		{
			print "\n";
		}
	}

	print <<LABEL;
	end
	else
	begin
LABEL

	for($i=0; $i<$issueWidth-$instType[3]; $i++)
	{
		print <<LABEL;
		validPacket$i <= validPacket${i}_i;
		granted${i}Dest <= granted${i}Dest_i;
		branchMask${i} <= branchMask${i}_i;
LABEL

		if($i != $issueWidth-$instType[3]-1)
		{
			print "\n";
		}
	}

	print <<LABEL;
	end
end
LABEL

}
print "\n";

print <<LABEL;
 /* Following acts like a shift register for high latency instruction
    (more than 1). 
 */
always @(posedge clk)
begin:UPDATE
	integer i;

	if(reset)
	begin
LABEL

if($instType[1] <= 1)
{
	$temp = $instType[0];
	print <<LABEL;
		for(i=0;i<`FU1_LATENCY-1;i=i+1)
		begin
			RSR_CALU[i] <= 0;
			BRANCH_MASK[i] <= 0;
		end

		RSR_CALU_VALID <= 0;
LABEL
}
else
{	
	foreach $i(@complexArray)
	{
		print "\t\tfor(i=0;i<`FU1_LATENCY-1;i=i+1)\n";
		print "\t\tbegin\n";
		print "\t\t\tRSR_CALU_";
		print $i;
		print "[i] <= 0;\n";
		print "\t\t\tBRANCH_MASK_";
		print $i;
		print "[i] <= 0;\n";
		print "\t\tend\n";
	}
	print "\n";

	foreach $i(@complexArray)
	{
		print "\t\tRSR_CALU_VALID_";
		print $i;
		print " <= 0;\n";
	}
	print "\n";
}

print <<LABEL;
	end
	else
	begin
LABEL

if($instType[1] <= 1)
{
	$temp = $complexArray[0];
	if($pipelined == 0)
	{
		print "\t\tif(validPacket$temp)\n";
	}
	elsif($pipelined == 1)
	{
		print "\t\tif(validPacket$temp && ~(ctrlVerified_i && ctrlMispredict_i && branchMask$temp\[ctrlSMTid_i]))\n";
	}
	print <<LABEL;
		begin
			RSR_CALU[0] <= granted${temp}Dest;
			RSR_CALU_VALID[0] <= 1'b1;
			BRANCH_MASK[0] <= branchMask$temp;
		end
		else
		begin
			RSR_CALU[0] <= 0;
			RSR_CALU_VALID[0] <= 1'b0;
			BRANCH_MASK[0] <= 0;
		end

LABEL
}
else
{	
	foreach $i(@complexArray)
	{
		if($pipelined == 0)
		{
			print "\t\tif(validPacket${i})\n";
		}
		elsif($pipelined == 1)
		{
			print "\t\tif(validPacket${i} && ~(ctrlVerified_i && ctrlMispredict_i && branchMask$i\[ctrlSMTid_i]))\n";
		}
		print <<LABEL;
		begin
			RSR_CALU_${i}\[0] <= granted${i}Dest;
			RSR_CALU_VALID_${i}\[0] <= 1'b1;
			BRANCH_MASK_${i}\[0] <= branchMask${i};
		end
		else
		begin
			RSR_CALU_${i}\[0] <= 0;
			RSR_CALU_VALID_${i}\[0] <= 1'b0
			BRANCH_MASK_${i}\[0] <= 0;
		end

LABEL
	}
}

if($instType[1] <= 1)
{
	print <<LABEL;
		for(i=0; i<`FU1_LATENCY-2; i=i+1)
		begin
			if(ctrlVerified_i && ctrlMispredict_i && BRANCH_MASK[i][ctrlSMTid_i])
			begin
				RSR_CALU[i+1] <= 0;
				RSR_CALU_VALID[i+1] <= 0;
				BRANCH_MASK[i+1] <= 0;
			end
			else
			begin
				RSR_CALU[i+1] <= RSR_CALU[i];
				RSR_CALU_VALID[i+1] <= RSR_CALU_VALID[i];
				BRANCH_MASK[i+1] <= BRANCH_MASK[i];
			end
		end
LABEL
}
else
{	
	foreach $i(@complexArray)
	{
		print <<LABEL;
		for(i=0; i<`FU1_LATENCY-2; i=i+1)
		begin
			if(ctrlVerified_i && ctrlMispredict_i && BRANCH_MASK_${i}\[i][ctrlSMTid_i])
			begin
				RSR_CALU_${i}\[i+1] <= 0;
				RSR_CALU_VALID_${i}\[i+1] <= 0;
				BRANCH_MASK_${i}\[i+1] <= 0;
			end
			else
			begin
				RSR_CALU_${i}\[i+1] <= RSR_CALU_${i}\[i];
				RSR_CALU_VALID_${i}\[i+1] <= RSR_CALU_VALID_${i}\[i];
				BRANCH_MASK_${i}\[i+1] <= BRANCH_MASK_${i}\[i];
			end
		end

LABEL
	}
}

print <<LABEL;
	end
end

endmodule
LABEL
