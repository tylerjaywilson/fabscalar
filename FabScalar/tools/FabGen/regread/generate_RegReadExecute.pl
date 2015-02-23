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
# Purpose: This script creates RR/EX pipe reg.
################################################################################

my $version = "1.1";

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 5;

my $issueWidth;
my @instType; # Number of ways for each instruction type
my $typesOfFUs = 4; # HARDWIRED!

my $printHeader = 0;

my $i;
my $j;
my $k;
my $temp;
my $temp2;
my $comma;

sub fatalUsage
{
	print "Usage: perl $scriptName -w <issue_width> -n A B C D [-m] [-v] [-h]\n";
	print "\t-n: Number of instructions of type 1 (A), type 2 (B), type 3 (C), type 4 (D)\n";
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
	elsif(/^-n$/) 
	{
		for($i=0; $i<$typesOfFUs; $i++)
		{
			$instType[$i] = shift;
			$essentialCLIArgs++;
		}
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
# Purpose: This module implements pipeline stage between register read and 
#	   execute stage.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL

print <<LABEL;

module RegReadExecute (
	input clk,
	input reset,
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
	input [2*`SIZE_DATA+`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
		`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
		`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket${i}_i,
	input fuPacketValid${i}_i,
LABEL
}
print "\n";

$temp = 0;
$temp2 = 0;
for($i=$temp; $i<$temp+$instType[0]+$instType[1]; $i++)
{
	print <<LABEL;
	output reg [`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+
		`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:0] fuPacket${i}_o,
	output reg fuPacketValid${i}_o,
LABEL
	$temp2++;
}

$temp += $temp2;
$temp2 = 0;
for($i=$temp; $i<$temp+$instType[2]; $i++)
{
	print <<LABEL;
	output reg [`SIZE_PC+`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+
		`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+
		`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] fuPacket${i}_o,
	output reg fuPacketValid${i}_o,
LABEL
	$temp2++;
}

$temp += $temp2;
$temp2 = 0;
for($i=$temp; $i<$temp+$instType[3]; $i++)
{
	my $comma = ",";

	if($i==$temp+$instType[3]-1)
	{
		$comma = "";
	}

	print <<LABEL;
	output reg [`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+
		`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:0] fuPacket${i}_o,
	output reg fuPacketValid${i}_o$comma
LABEL
	$temp2++;
}

print ");\n\n";

print "reg ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}BrDir$comma";
}
print "\n";

print "reg [`SIZE_CTI_LOG-1:0] ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}CtiqTag$comma";
}
print "\n";

print "reg [`SIZE_PC-1:0] ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}TarAddr$comma";
}
print "\n";

print "reg [`SIZE_PC-1:0] ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}PC$comma";
}
print "\n";

print "reg [`SIZE_OPCODE_I-1:0] ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}Opcode$comma";
}
print "\n";

print "reg [`LDST_TYPES_LOG-1:0] ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}LdStType$comma";
}
print "\n";

print "reg [`SIZE_IMMEDIATE-1:0] ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}Immd$comma";
}
print "\n";

print "reg [`SIZE_PHYSICAL_LOG-1:0] ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}srcReg1$comma";
}
print "\n";

print "reg [`SIZE_PHYSICAL_LOG-1:0] ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}srcReg2$comma";
}
print "\n";

print "reg [`SIZE_PHYSICAL_LOG-1:0] ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}DestReg$comma";
}
print "\n";

print "reg [`CHECKPOINTS_LOG-1:0] ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}SMTid$comma";
}
print "\n";

print "reg [`CHECKPOINTS-1:0] ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}BranchMask$comma";
}
print "\n";

print "reg [`SIZE_ISSUEQ_LOG-1:0] ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}IQentry$comma";
}
print "\n";

print "reg [`SIZE_ACTIVELIST_LOG-1:0] ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}ALid$comma";
}
print "\n";

print "reg [`SIZE_LSQ_LOG-1:0] ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}LSQid$comma";
}
print "\n";

print "reg [`SIZE_DATA-1:0] ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}Data1$comma";
}
print "\n";

print "reg [`SIZE_DATA-1:0] ";
for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = ";";
	}
	else
	{
		$comma = ", ";
	}

	print "gr_inst${i}Data2$comma";
}
print "\n\n";

print <<LABEL;
/* Following extracts indivisual information from each granted FU packet. The information is
 * repacked on the need basis for each FU.
 */ 
always @(*)
begin
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
gr_inst${i}BrDir        = fuPacket${i}_i[0];
gr_inst${i}CtiqTag      = fuPacket${i}_i[`SIZE_CTI_LOG:1];
gr_inst${i}TarAddr      = fuPacket${i}_i[`SIZE_PC+`SIZE_CTI_LOG:`SIZE_CTI_LOG+1];
gr_inst${i}PC           = fuPacket${i}_i[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1];
gr_inst${i}Opcode       = fuPacket${i}_i[`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:2*`SIZE_PC+`SIZE_CTI_LOG+1];
gr_inst${i}LdStType     = fuPacket${i}_i[`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:
                                   `SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
gr_inst${i}Immd         = fuPacket${i}_i[`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+
                                   `SIZE_CTI_LOG:`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
gr_inst${i}DestReg      = fuPacket${i}_i[`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+
                                   `SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_IMMEDIATE+`LDST_TYPES_LOG+
                                   `SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
gr_inst${i}SMTid        = fuPacket${i}_i[`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+
                                   `SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+
                                   `SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
gr_inst${i}ALid         = fuPacket${i}_i[`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                                   `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`CHECKPOINTS_LOG+
                                   `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+
                                   `SIZE_CTI_LOG+1];
gr_inst${i}LSQid        = fuPacket${i}_i[`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                                   `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_ACTIVELIST_LOG+
                                   `CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+
                                   `SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
gr_inst${i}srcReg1      = fuPacket${i}_i[`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+
                                   `SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_LSQ_LOG+
                                   `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+
                                   `SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
gr_inst${i}srcReg2      = fuPacket${i}_i[2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+
                                   `SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:
                                   `SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+
                                   `SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
gr_inst${i}IQentry      = fuPacket${i}_i[`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                                   `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+
                                   `SIZE_CTI_LOG:2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                                   `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
gr_inst${i}BranchMask   = fuPacket${i}_i[`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+
                                   `CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                                   `SIZE_PC+`SIZE_CTI_LOG:`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+
                                   `CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                                   `SIZE_PC+`SIZE_CTI_LOG+1];
gr_inst${i}Data1        = fuPacket${i}_i[`SIZE_DATA+`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+
                                   `CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+
                                   `SIZE_CTI_LOG:`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+
                                   `CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+
                                   `SIZE_CTI_LOG+1];
gr_inst${i}Data2        = fuPacket${i}_i[2*`SIZE_DATA+`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+
                                   `CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+
                                   `SIZE_CTI_LOG:`SIZE_DATA+`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                                   `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+
                                   `SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
LABEL

	if($i != $issueWidth-1)
	{
		print "\n";
	}
}
print "end\n\n";

print <<LABEL;
/*  Pipeline registers between RegRead and Execute stage.
 */
always @(posedge clk)
begin
	if(reset)
	begin
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
		fuPacketValid${i}_o <= 0;
		fuPacket${i}_o <= 0;
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
		fuPacketValid${i}_o <= fuPacketValid${i}_i;
LABEL
}
print "\n";

$temp = 0;
$temp2 = 0;
for($i=$temp; $i<$temp+$instType[0]+$instType[1]; $i++)
{
	print <<LABEL;
		if(fuPacketValid${i}_i == 1'b1)
		begin
			fuPacket${i}_o <= {gr_inst${i}Immd,gr_inst${i}Opcode,gr_inst${i}Data2,gr_inst${i}srcReg2,
				gr_inst${i}Data1,gr_inst${i}srcReg1,gr_inst${i}DestReg,gr_inst${i}ALid,
				gr_inst${i}IQentry,gr_inst${i}BranchMask};
		end

LABEL
	$temp2++;
}

$temp += $temp2;
$temp2 = 0;
for($i=$temp; $i<$temp+$instType[2]; $i++)
{
	print <<LABEL;
		if(fuPacketValid${i}_i == 1'b1)
		begin
			fuPacket${i}_o <= {gr_inst${i}PC,gr_inst${i}Immd,gr_inst${i}Opcode,gr_inst${i}Data2 ,gr_inst${i}srcReg2,
				gr_inst${i}Data1,gr_inst${i}srcReg1,gr_inst${i}DestReg,gr_inst${i}ALid,gr_inst${i}IQentry,
				gr_inst${i}BranchMask,gr_inst${i}SMTid,gr_inst${i}CtiqTag,gr_inst${i}TarAddr,gr_inst${i}BrDir};
		end

LABEL
	$temp2++;
}

$temp += $temp2;
$temp2 = 0;
for($i=$temp; $i<$temp+$instType[3]; $i++)
{
	print <<LABEL;
		if(fuPacketValid${i}_i == 1'b1)
		begin
			fuPacket${i}_o <= {gr_inst${i}Immd,gr_inst${i}Opcode,gr_inst${i}Data2,gr_inst${i}srcReg2,gr_inst${i}Data1,
				gr_inst${i}srcReg1,gr_inst${i}DestReg,gr_inst${i}LSQid,gr_inst${i}ALid,gr_inst${i}IQentry,gr_inst${i}BranchMask};
		end

LABEL
	$temp2++;
}

print <<LABEL;
	end
end

endmodule
LABEL

