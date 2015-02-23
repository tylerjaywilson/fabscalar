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
# Purpose: This script creates complex-alu.
################################################################################

my $version = "1.0";

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 0;

my $printHeader = 0;

my $i;
my $j;
my $k;
my $temp;

sub fatalUsage
{
	print "Usage: perl $scriptName [-m] [-v] [-h]\n";
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
	if(/^-m$/)
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
# Purpose: This is a Complex ALU module
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps


/* Algorithm
 1. result_o contains the result of the arithmetic operation.
 2. flags_o has following fields:
	(.) Executed  :"bit-2"
       	(.) Exception :"bit-1"
       	(.) Mispredict:"bit-0"

***************************************************************************/

LABEL

print <<LABEL;
module Complex_ALU (
			 input [`SIZE_DATA-1:0] 		data1_i,	
	     	 input [`SIZE_DATA-1:0] 		data2_i,	
		     input [`SIZE_IMMEDIATE-1:0] 	immd_i,
		     input [`SIZE_OPCODE_I-1:0] 	opcode_i,

		     output [(2*`SIZE_DATA)-1:0] 	result_o,
		     output [`EXECUTION_FLAGS-1:0] 	flags_o	
	           ); 


wire signed [`SIZE_DATA-1:0] 		data1_s;
wire signed [`SIZE_DATA-1:0] 		data2_s;
reg [(2*`SIZE_DATA)-1:0] 		result;
reg [`EXECUTION_FLAGS-1:0] 		flags;


assign result_o    = result;
assign flags_o     = flags;


assign data1_s     = data1_i;	
assign data2_s     = data2_i;	

always @(*)
begin:ALU_OPERATION
  reg signed [`SIZE_DATA-1:0] 	result1_s;
  reg signed [`SIZE_DATA-1:0] 	result2_s;
  reg [`SIZE_DATA-1:0] 		result1;
  reg [`SIZE_DATA-1:0] 		result2;
	
  result    = 0;
  flags     = 0;

  case(opcode_i)
	`MULT_L:
	 begin
		{result2_s,result1_s} = data1_s * data2_s;
		result		      = result1_s;
		flags                 = {1'b0,1'b1,1'b1,1'b1,1'b0,1'b0};
	 end
	`MULT_H:
	 begin
		{result2_s,result1_s} = data1_s * data2_s;
		result		      = result2_s;
		flags                 = {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`MULTU_L:
	 begin
		{result2,result1}     = data1_i * data2_i;
		result		      = result1;
		flags                 = {1'b0,1'b1,1'b1,1'b1,1'b0,1'b0};
	 end
	`MULTU_H:
	 begin
		{result2,result1}     = data1_i * data2_i;
		result		      = result2;
		flags                 = {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	 `DIV_L:
         begin
                {result2_s,result1_s} = data1_s / data2_s;
                result                = result1_s;
                flags                 = {1'b0,1'b1,1'b1,1'b1,1'b0,1'b0};
         end
        `DIV_H:
         begin
                {result1_s,result2_s} = data1_s % data2_s;
                result                = result2_s;
                flags                 = {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
         end
        `DIVU_L:
         begin
                {result2,result1}     = data1_i / data2_i;
                result                = result1;
                flags                 = {1'b0,1'b1,1'b1,1'b1,1'b0,1'b0};
         end
        `DIVU_H:
         begin
                {result1,result2}     = data1_i % data2_i;
                result                = result2;
                flags                 = {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
         end
	`SYSCALL:
	 begin
		result                = 0;
                flags                 = {1'b0,1'b0,1'b0,1'b1,1'b1,1'b0};
	 end
  endcase
end    


endmodule
LABEL

