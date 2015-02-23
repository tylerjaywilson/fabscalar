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
	print "Usage: perl ./generate_BTB.pl -w <width> [-m] [-v] [-h]\n";
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
$outputFileName = "BTB.v";
$moduleName = "BTB";

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
# Purpose: This block implements the Branch Target Buffer. Fetch Width is $width. 
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL

print  <<LABEL;

module BTB(	input [`SIZE_PC-1:0] PC_i,

		/* BTB updates from the Branch Order Buffer. */
		input updateEn_i,
		input [`SIZE_PC-1:0] updatePC_i,
		input [`SIZE_PC-1:0] updateTargetAddr_i,
		input [`BRANCH_TYPE-1:0] updateBrType_i,

		input btbFlush_i,
		input stall_i,
		input clk,
		input reset,

LABEL

for($i=0; $i<$width; $i++)
{
	print "\t\toutput btbHit",$i,"_o,\n";
	print "\t\toutput [`SIZE_PC-1:0] targetAddr",$i,"_o,\n";
	print "\t\toutput [`BRANCH_TYPE-1:0] ctrlType",$i,"_o";
	if($i<$width-1)
	{
		print ",\n";
	}
	print "\n";
}

print <<LABEL;
);


integer i;

LABEL

for($i=0; $i<$nearest_width; $i++)
{
	print "wire [`SIZE_PC-1:0] pc",$i,";\n";
}
print "\n";
for($i=0; $i<$nearest_width; $i++)
{
	print "reg [`SIZE_PC-1:0] ram_pc",$i,";\n";
}
print "\n";
for($i=0; $i<$width; $i++)
{
	print "wire [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] pctag",$i,";\n";
}
print "\n";
for($i=0; $i<$nearest_width; $i++)
{
	print "wire [`SIZE_BTB_LOG-`FETCH_BANDWIDTH_LOG-1:0] btbaddr",$i,";\n";
}
print "\n";
for($i=0; $i<$nearest_width; $i++)
{
	print "wire [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] ram_btbtag",$i,";\n";
}
print "\n";
for($i=0; $i<$nearest_width; $i++)
{
	print "wire [`SIZE_PC+`BRANCH_TYPE:0] ram_btbdata",$i,";\n";
}
print "\n";
for($i=0; $i<$width; $i++)
{
	print "reg [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] btbtag",$i,";\n";
}
print "\n";
for($i=0; $i<$width; $i++)
{
	print "reg [`SIZE_PC+`BRANCH_TYPE:0] btbdata",$i,";\n";
}

print <<LABEL;

wire [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] pctagupdate;
wire [`SIZE_BTB_LOG-1-`FETCH_BANDWIDTH_LOG:0] btbaddrupdate;
wire we[$nearest_width-1:0];

LABEL
print "\n";
for($i=0; $i<$width; $i++)
{
	print "wire btbHit",$i,"Btb;\n";
	print "wire [`SIZE_PC-1:0] targetAddr",$i,"Btb;\n";
	print "wire [`BRANCH_TYPE-1:0] brType",$i,"Btb;\n";
	print "\n";
}

print <<LABEL;


/* Initializing BTB Tag and BTB Data SRAMs. SRAM_4R1W is the Verilog model of RAM
* with required READ and WRITE ports.
*/

LABEL

print "\n";
for($i=0; $i<$nearest_width; $i++)
{
	print "SRAM_1R1W #(`SIZE_BTB/",$nearest_width,",`SIZE_BTB_LOG-`FETCH_BANDWIDTH_LOG,`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET)\n";
	print "\tbtbTag",$i,"(.addr0_i(btbaddr",$i,"),.addrWr_i(btbaddrupdate),.we_i(we[",$i,"]),.data_i(pctagupdate),\n";
	print "\t.clk(clk),.reset(reset),.data0_o(ram_btbtag",$i,"));\n";
}
print "\n";
for($i=0; $i<$nearest_width; $i++)
{
	print "SRAM_1R1W #(`SIZE_BTB/",$nearest_width,",`SIZE_BTB_LOG-`FETCH_BANDWIDTH_LOG,`SIZE_PC+`BRANCH_TYPE+1)\n";
	print "\tbtbData",$i,"(.addr0_i(btbaddr",$i,"),.addrWr_i(btbaddrupdate),.we_i(we[",$i,"]),.data_i({updateTargetAddr_i,updateBrType_i,1'b1}),\n";
	print "\t.clk(clk),.reset(reset),.data0_o(ram_btbdata",$i,"));\n";
}

print <<LABEL;
		
		
/* Creating addresses for the Program Counter to be used by the BTB. 
*/ 
LABEL
for($i=0; $i<$nearest_width; $i++)
{
	print "assign pc",$i,"     = PC_i + ",$i*8,";\n";
}

		
print <<LABEL;
		
		
/* Rotate the addresses to the correct SRAM
*/
always@(*)
begin
	case(PC_i[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET])
LABEL
for($i=0; $i<$nearest_width; $i++)
{
	print "\t",log2($width),"'d",$i,":\n";
	print "\tbegin\n";
	for($j=0; $j<$nearest_width; $j++)
	{
		if($j-$i >= 0)
		{
			print "\t\tram_pc",$j," = pc",$j-$i,";\n";
		}
		else
		{
			print "\t\tram_pc",$j," = pc",$j-$i+$nearest_width,";\n";
		}
	}
	print "\tend\n";
}
print "\tendcase\n";
print "end\n";
print <<LABEL;		
		
		
/* Extracting Tag and Index bits from the Program Counter for the BTB Tag
comparision and Indexing. */ 
LABEL
for($i=0; $i<$nearest_width; $i++)
{
	if($i<$width)
	{
		print "assign pctag",$i,"\t= pc",$i,"[`SIZE_PC-1:`SIZE_BTB_LOG+`SIZE_BYTE_OFFSET];\n";
	}
	print "assign btbaddr",$i,"\t= ram_pc",$i,"[`SIZE_BTB_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET+`FETCH_BANDWIDTH_LOG];\n";
	print "\n";
}
		
print <<LABEL;
/* Re-Rotate the from the SRAM output to the correct order
*/
always@(*)
begin
LABEL
for($i=0; $i<$width; $i++)
{	
	print "\tbtbtag",$i,"\t\t= 0;\n";
}	
for($i=0; $i<$width; $i++)
{	
	print "\tbtbdata",$i,"\t= 0;\n";
}						
print "\tcase(PC_i[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET])\n";
for($i=0; $i<$nearest_width; $i++)
{
	print "\t",log2($width),"'d",$i,":\n";
	print "\tbegin\n";
	for($j=0; $j<$width; $j++)
	{
		if($i+$j < $nearest_width)
		{
			print "\t\tbtbtag",$j,"\t\t= ram_btbtag",$i+$j,";\n";
		}
		else
		{
			print "\t\tbtbtag",$j,"\t\t= ram_btbtag",$i+$j-$nearest_width,";\n";	
		}
	}
	for($j=0; $j<$width; $j++)
	{
		if($i+$j < $nearest_width)
		{
			print "\t\tbtbdata",$j,"\t= ram_btbdata",$i+$j,";\n";
		}
		else
		{
			print "\t\tbtbdata",$j,"\t= ram_btbdata",$i+$j-$nearest_width,";\n";	
		}
	}		
	print "\tend\n";
}
print "\tendcase\n";
print "end\n";

for($i=0; $i<$width; $i++)
{
	print "/* Following checks for BTB Hit for PC$i and if there is a hit then reads the BTB\n";
	print"* data for Target Address and Branch Type.\n";
	print "*/\n";
	print "assign btbHit",$i,"Btb\t= (btbdata",$i,"[0] && (pctag",$i," == btbtag",$i,")) ? 1'b1:0;\n";
	print "assign targetAddr",$i,"Btb\t= btbdata",$i,"[`SIZE_PC+`BRANCH_TYPE:`BRANCH_TYPE+1];\n";
	print "assign brType",$i,"Btb\t= btbdata",$i,"[`BRANCH_TYPE:1];\n";
	print "\n";
	print "assign btbHit",$i,"_o\t= btbHit",$i,"Btb;\n";
	print "assign targetAddr",$i,"_o\t= targetAddr",$i,"Btb;\n";
	print "assign ctrlType",$i,"_o\t= brType",$i,"Btb;\n";
	print "\n\n";
}
		
print <<LABEL;		
		
		
/* Following updates the BTB if the prediction made by BTB was wrong or
* if BTB never saw this Control Instruction PC in past. The update comes 
* from Ctrl Queue in the program order. 
*/
		
assign pctagupdate   	= updatePC_i[`SIZE_PC-1:`SIZE_BTB_LOG+`SIZE_BYTE_OFFSET];
assign btbaddrupdate 	= updatePC_i[`SIZE_BTB_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET+`FETCH_BANDWIDTH_LOG];
		
LABEL
for($i=0; $i<$nearest_width; $i++)
{
	print "assign we[",$i,"] = updateEn_i && (updatePC_i[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET] == ",log2($width),"'d",$i,");\n";
}
print <<LABEL;
		
endmodule
LABEL
