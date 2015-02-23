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
# Purpose:
################################################################################

my $version = "1.1";

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 1;

my $decodeWidth = 4;

my $printHeader = 0;

my $i;
my $j;
my $k;
my $temp;

sub fatalUsage
{
	print "Usage: perl $scriptName -w <decode_width> [-m] [-v] [-h]\n";
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
		$decodeWidth = shift;
		$essentialCLIArgs++;
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

# Create module name
$outputFileName = "DecodeRename.v";
$moduleName = "DecodeRename";

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
# Purpose: This block implements Pipeline Latch between Decode and Rename
#          stages.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL


print <<LABEL;
module $moduleName(
					 input reset,
                     input clk,
                     input flush_i,                            // Flush the piepeline if there is Exception/Mis-prediction

		     input stall_i,

                     //input freeListEmpty_i,                    // If there is not enough Phy register for renaming
                     //input stallBackEnd_i,                     // Issue Queue or LSQ or ActiveList has not enough space

 		     input decodeReady_i,
LABEL

for($i=0; $i<$decodeWidth; $i++)
{
print <<LABEL;
                     input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
			    3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket${i}_i,
LABEL
}
print "\n";

print <<LABEL;
                     input [`BRANCH_COUNT-1:0] branchCount_i,


                     output reg decodeReady_o,                   // For the Rename stage

LABEL

for($i=0; $i<$decodeWidth; $i++)
{
	print <<LABEL;
	                     output reg [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
				 3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket${i}_o,
LABEL
}
print "\n";

print <<LABEL;
                     output reg [`BRANCH_COUNT-1:0] branchCount_o
);


LABEL
# End of head

print <<LABEL;
always @(posedge clk)
begin
 if(reset || flush_i)
 begin
	decodeReady_o    <= 0;

LABEL

for($i=0; $i<$decodeWidth; $i++)
{
	print <<LABEL;
	decodedPacket${i}_o <= 0;
LABEL
}
print "\n";

print <<LABEL;
	branchCount_o    <= 0;
 end 
 else
 begin

  //if(decodeReady_i && ~freeListEmpty_i && ~stallBackEnd_i)
  if(~stall_i)
  begin  
	decodeReady_o    <= decodeReady_i;
LABEL

for($i=0; $i<$decodeWidth; $i++)
{
	print <<LABEL;
        decodedPacket${i}_o <= decodedPacket${i}_i;
LABEL
}
print "\n";

print <<LABEL;
        branchCount_o    <= branchCount_i;
  end 
  /*`ifdef VERIFY
   else
   begin
        decodedPacket0_o <= 0;
        decodedPacket1_o <= 0;
        decodedPacket2_o <= 0;
        decodedPacket3_o <= 0;
        branchCount_o    <= 0;
   end
   `endif*/
 end
end



endmodule
LABEL

