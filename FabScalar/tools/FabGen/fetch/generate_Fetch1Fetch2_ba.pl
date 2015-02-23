#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw/ceil/;

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
# Purpose: This script creates a Verilog module of BTB.
################################################################################

my $width = 4;
my $version = "1.0";
my $minNoCliArgs = 1;
my $createFile = 0;
my $printHeader = 0;
my $moduleName;
my $outputFileName;
my $scriptName;
my $nearest_width;

my $i;
my $j;

sub fatalUsage
{
	print "Usage: perl ./generate_Fetch1Fetch2_ba.pl -w <width> [-m] [-v] [-h]\n";
	print "\t-m: Add header\n";
	print "\t-v: Print version and exit\n";
	print "\t-h: Show usage help and exit\n";
	exit;
}

sub log2 
{
	my $n = shift;
	return ceil(log($n)/log(2));
}

### START HERE ###
$scriptName = $0;

if($#ARGV < $minNoCliArgs)
{
	print "Error: Too few input arguments.\n";
	&fatalUsage();
}

while(@ARGV)
{
	$_ = shift;
	
	if(/^-w$/) 
	{
		$width = shift;
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

$nearest_width = 2**log2($width);
$outputFileName = "Fetch1Fetch2.v";
$moduleName = "Fetch1Fetch2";

print  <<LABEL;
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
# Purpose: This block implements pipeline registers between Fetch1 and Fetch2.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL

print <<LABEL;
module Fetch1Fetch2(input clk,
	input reset,
	input flush_i,
	input stall_i,

	/************************************** Inputs -> Icache *********************************************************/
	input [`INSTRUCTION_BUNDLE-1:0] instructionBundle_i,

	/************************************** Inputs -> PC *********************************************************/
	input [`SIZE_PC-1:0]pc_i,
	input valid_pc_i,

	/************************************** Inputs -> BTB information *********************************************************/
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t/* input corresponding to pc+",$i,"*8 and not taken */\n";		
	print "\tinput btb_hit_N",$i,"_i,\n";
	print "\tinput [`SIZE_PC-1:0]target_N",$i,"_i,\n";
	print "\tinput [`BRANCH_TYPE-1:0]type_N",$i,"_i,\n";
	print "\tinput [`FETCH_BANDWIDTH_LOG-1:0]position_b_N",$i,"_i,\n";
	print "\tinput last_N",$i,"_i,\n";
	print "\n";
}
print "\n";
for($i=0; $i<$width; $i++)
{
	print "\t/* input corresponding to pc+",$i,"*8 and taken */\n";		
	print "\tinput btb_hit_T",$i,"_i,\n";
	print "\tinput [`SIZE_PC-1:0]target_T",$i,"_i,\n";
	print "\tinput [`BRANCH_TYPE-1:0]type_T",$i,"_i,\n";
	print "\tinput [`FETCH_BANDWIDTH_LOG-1:0]position_b_T",$i,"_i,\n";
	print "\tinput last_T",$i,"_i,\n";
	print "\n";
}
print "\n";
for($i=0; $i<$width; $i++)
{
	print "\t/* input corresponding to pc+",$i,"*8 and return */\n";		
	print "\tinput btb_hit_R",$i,"_i,\n";
	print "\tinput [`SIZE_PC-1:0]target_R",$i,"_i,\n";
	print "\tinput [`BRANCH_TYPE-1:0]type_R",$i,"_i,\n";
	print "\tinput [`FETCH_BANDWIDTH_LOG-1:0]position_b_R",$i,"_i,\n";
	print "\tinput last_R",$i,"_i,\n";
	print "\n";
}
print <<LABEL;

	/************************************** Inputs from BP *********************************************************/
LABEL
for($i=0; $i<$width; $i++)
{
	print "\tinput pred",$i,"_i,\n";
}
print <<LABEL;

	/************************************** Inputs -> BTB Hit Information *********************************************************/
	input btb_hit_i,
	input [`SIZE_PC-1:0]hit_target_i,
	input [`BRANCH_TYPE-1:0]hit_type_i,
	input [`FETCH_BANDWIDTH_LOG-1:0]hit_position_b_i,
	input hit_last_i,
	input pred_i,
	input [`TAG_TYPE_BITS-1:0]tag_type_i,
	input [`FETCH_BANDWIDTH_LOG-1:0]position_b_i,

	/************************************** Outputs -> PC *********************************************************/
	output reg[`INSTRUCTION_BUNDLE-1:0] instructionBundle_o,

	/************************************** Outputs -> PC *********************************************************/
	output reg [`SIZE_PC-1:0]pc_o,
	output reg valid_pc_o,

	/************************************** Inputs -> BTB information *********************************************************/
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t/* output corresponding to pc+",$i,"*8 and not taken */\n";		
	print "\toutput reg btb_hit_N",$i,"_o,\n";
	print "\toutput reg [`SIZE_PC-1:0]target_N",$i,"_o,\n";
	print "\toutput reg [`BRANCH_TYPE-1:0]type_N",$i,"_o,\n";
	print "\toutput reg [`FETCH_BANDWIDTH_LOG-1:0]position_b_N",$i,"_o,\n";
	print "\toutput reg last_N",$i,"_o,\n";
	print "\n";
}
for($i=0; $i<$width; $i++)
{
	print "\t/* output corresponding to pc+",$i,"*8 and taken */\n";		
	print "\toutput reg btb_hit_T",$i,"_o,\n";
	print "\toutput reg [`SIZE_PC-1:0]target_T",$i,"_o,\n";
	print "\toutput reg [`BRANCH_TYPE-1:0]type_T",$i,"_o,\n";
	print "\toutput reg [`FETCH_BANDWIDTH_LOG-1:0]position_b_T",$i,"_o,\n";
	print "\toutput reg last_T",$i,"_o,\n";
	print "\n";
}
for($i=0; $i<$width; $i++)
{
	print "\t/* output corresponding to pc+",$i,"*8 and return */\n";		
	print "\toutput reg btb_hit_R",$i,"_o,\n";
	print "\toutput reg [`SIZE_PC-1:0]target_R",$i,"_o,\n";
	print "\toutput reg [`BRANCH_TYPE-1:0]type_R",$i,"_o,\n";
	print "\toutput reg [`FETCH_BANDWIDTH_LOG-1:0]position_b_R",$i,"_o,\n";
	print "\toutput reg last_R",$i,"_o,\n";
	print "\n";
}
print <<LABEL;

	/************************************** Inputs -> BP information *********************************************************/
LABEL

for($i=0; $i<$width; $i++)
{
	print "\toutput reg pred",$i,"_o,\n";
}

print <<LABEL;

	/************************************** Inputs -> BTB Hit Information *********************************************************/
	output reg btb_hit_o,
	output reg [`SIZE_PC-1:0]hit_target_o,
	output reg [`BRANCH_TYPE-1:0]hit_type_o,
	output reg [`FETCH_BANDWIDTH_LOG-1:0]hit_position_b_o,
	output reg hit_last_o,
	output reg pred_o,
	output reg [`TAG_TYPE_BITS-1:0]tag_type_o,
	output reg [`FETCH_BANDWIDTH_LOG-1:0]position_b_o		
	);

always@(posedge clk)
begin
	if(reset || flush_i)
	begin
		/************************************** Outputs -> PC *********************************************************/
		instructionBundle_o <= 0;
	
		/************************************** Outputs -> PC *********************************************************/
		pc_o <= 0;
		valid_pc_o <= 0;

		/************************************** Inputs -> BTB information *********************************************************/
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t\t/* input corresponding to pc+",$i,"*8 and not taken */\n";		
	print "\t\tbtb_hit_N",$i,"_o <= 0;\n";
	print "\t\ttarget_N",$i,"_o <= 0;\n";
	print "\t\ttype_N",$i,"_o <= 0;\n";
	print "\t\tposition_b_N",$i,"_o <= `FETCH_BANDWIDTH-1;\n";
	print "\t\tlast_N",$i,"_o <= 0;\n";
	print "\n";
}
print "\n";
for($i=0; $i<$width; $i++)
{
	print "\t\t/* input corresponding to pc+",$i,"*8 and taken */\n";		
	print "\t\tbtb_hit_T",$i,"_o <= 0;\n";
	print "\t\ttarget_T",$i,"_o <= 0;\n";
	print "\t\ttype_T",$i,"_o <= 0;\n";
	print "\t\tposition_b_T",$i,"_o <= `FETCH_BANDWIDTH-1;\n";
	print "\t\tlast_T",$i,"_o <= 0;\n";
	print "\n";
}
print "\n";
for($i=0; $i<$width; $i++)
{
	print "\t\t/* input corresponding to pc+",$i,"*8 and return */\n";		
	print "\t\tbtb_hit_R",$i,"_o <= 0;\n";
	print "\t\ttarget_R",$i,"_o <= 0;\n";
	print "\t\ttype_R",$i,"_o <= 0;\n";
	print "\t\tposition_b_R",$i,"_o <= `FETCH_BANDWIDTH-1;\n";
	print "\t\tlast_R",$i,"_o <= 0;\n";
	print "\n";
}
print <<LABEL;

		/************************************** Inputs -> BP information *********************************************************/
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t\tpred",$i,"_o <= 0;\n";
}

print <<LABEL;

		/************************************** Inputs -> BTB Hit Information *********************************************************/
		btb_hit_o <= 0;
		hit_target_o <= 0;
		hit_type_o <= 0;
		hit_position_b_o <= `FETCH_BANDWIDTH-1;
		hit_last_o <= 0;
		pred_o <= 0;
		tag_type_o <= 0;
		position_b_o <= `FETCH_BANDWIDTH-1;		
	end
	else if(~stall_i)
	begin
		instructionBundle_o <= instructionBundle_i;

		/************************************** Outputs -> PC *********************************************************/
		pc_o <= pc_i;
		valid_pc_o <= valid_pc_i;

		/************************************** Inputs -> BTB information *********************************************************/
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t\t/* input corresponding to pc+",$i,"*8 and not taken */\n";		
	print "\t\tbtb_hit_N",$i,"_o <= btb_hit_N",$i,"_i;\n";
	print "\t\ttarget_N",$i,"_o <= target_N",$i,"_i;\n";
	print "\t\ttype_N",$i,"_o <= type_N",$i,"_i;\n";
	print "\t\tposition_b_N",$i,"_o <= position_b_N",$i,"_i;\n";
	print "\t\tlast_N",$i,"_o <= last_N",$i,"_i;\n";
	print "\n";
}
for($i=0; $i<$width; $i++)
{
	print "\t\t/* input corresponding to pc+",$i,"*8 and taken */\n";		
	print "\t\tbtb_hit_T",$i,"_o <= btb_hit_T",$i,"_i;\n";
	print "\t\ttarget_T",$i,"_o <= target_T",$i,"_i;\n";
	print "\t\ttype_T",$i,"_o <= type_T",$i,"_i;\n";
	print "\t\tposition_b_T",$i,"_o <= position_b_T",$i,"_i;\n";
	print "\t\tlast_T",$i,"_o <= last_T",$i,"_i;\n";
	print "\n";
}
for($i=0; $i<$width; $i++)
{
	print "\t\t/* input corresponding to pc+",$i,"*8 and return */\n";		
	print "\t\tbtb_hit_R",$i,"_o <= btb_hit_R",$i,"_i;\n";
	print "\t\ttarget_R",$i,"_o <= target_R",$i,"_i;\n";
	print "\t\ttype_R",$i,"_o <= type_R",$i,"_i;\n";
	print "\t\tposition_b_R",$i,"_o <= position_b_R",$i,"_i;\n";
	print "\t\tlast_R",$i,"_o <= last_R",$i,"_i;\n";
	print "\n";
}
print <<LABEL;
		/************************************** Inputs -> BP information *********************************************************/
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t\tpred",$i,"_o <= pred",$i,"_i;\n";
}
print <<LABEL;

		/************************************** Inputs -> BTB Hit Information *********************************************************/
		btb_hit_o <= btb_hit_i;
		hit_target_o <= hit_target_i;
		hit_type_o <= hit_type_i;
		hit_position_b_o <= hit_position_b_i;
		hit_last_o <= hit_last_i;
		pred_o <= pred_i;
		tag_type_o <= tag_type_i;
		position_b_o <= position_b_i;		
	end
end

endmodule

LABEL
