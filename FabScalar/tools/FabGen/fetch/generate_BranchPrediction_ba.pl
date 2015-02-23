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
# Purpose: This script creates a verilog module of BranchPrediction for Block 
# 	   Ahead Fetch Unit(used for synthesis purposes).
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
	print "Usage: perl ./generate_BranchPrediction_ba.pl -w <width> [-m] [-v] [-h]\n";
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


$outputFileName = "BranchPrediction.v";
$moduleName = "BranchPrediction";
$nearest_width = 2**log2($width);

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
# Purpose: This block implements 2-bit Smith Counter table branch predictor. 
#	   The Fetch Bandwidth is $width.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps
	
LABEL

print <<LABEL;
module BranchPrediction (	input clk,
				input reset,
				input stall_i,
				input flush_i,
				input [`SIZE_PC-1:0]pc_i,
				input [`SIZE_PC-1:0]bp_tag_pc_i,
				input bp_dir_i,
				input bp_update_i,
LABEL

for($i=0; $i<$width; $i++)
{
	print "\t\t\t\toutput pred",$i,"_o";
	if($i<$width-1)
	{
		print ",\n";
	}
	else
	{
		print "\n";
	}
}
print ");\n\n\n";






print "/* Registers for bits required for second cycle*/\n";
#Requires log(fetch_bandwidth) bits for reading and 1 bit more for bank selection
print "reg [",log2($width),":0]rd_index_bits;\n";
print <<LABEL;
reg valid_rd_index_bits;
reg [`SIZE_CNT_TBL_LOG-1:0]wr_rd_index_reg;
reg wr_rd_pred_reg;
reg valid_wr_rd_index_reg;
LABEL



print "\n\n/* Registers for write Bypassing for correct write update*/\n";
print "reg [`SIZE_CNT_TBL_LOG-1:0]wr_wr_index1;\n";
print "reg [",$nearest_width,"*`SIZE_PREDICTION_CNT-1:0]wr_wr_data1;\n";
print <<LABEL;
reg wr_wr_pred1;
reg wr_wr_valid1;
reg [`SIZE_CNT_TBL_LOG-1:0]wr_wr_index2;
LABEL
print "reg [",$nearest_width,"*`SIZE_PREDICTION_CNT-1:0]wr_wr_data2;\n";
print <<LABEL;
reg wr_wr_valid2;
reg [`SIZE_CNT_TBL_LOG-1:0]wr_wr_index3;
LABEL
print "reg [",$nearest_width,"*`SIZE_PREDICTION_CNT-1:0]wr_wr_data3;\n";
print "reg wr_wr_valid3;\n";

my $width_bits = log2($width);

print <<LABEL;
wire [`SIZE_CNT_TBL_LOG-1:0] rd_index;
wire [`SIZE_CNT_TBL_LOG-1-1-$width_bits:0] rd_index_even;
wire [`SIZE_CNT_TBL_LOG-1-1-$width_bits:0] rd_index_odd;

wire [`SIZE_CNT_TBL_LOG-1:0] wr_rd_index;
wire [`SIZE_CNT_TBL_LOG-1-1-$width_bits:0] wr_rd_index_pred;

wire wr_rd_en_even;
wire wr_rd_en_odd;

wire [$nearest_width*`SIZE_PREDICTION_CNT-1:0] data_rd_even;
wire [$nearest_width*`SIZE_PREDICTION_CNT-1:0] data_rd_odd;
wire [$nearest_width*`SIZE_PREDICTION_CNT-1:0] data_rd_first;
wire [$nearest_width*`SIZE_PREDICTION_CNT-1:0] data_rd_second;
LABEL
for($i=0; $i<$width; $i++)
{
	print "reg [`SIZE_PREDICTION_CNT-1:0] cntValue",$i,";\n";
}
print <<LABEL;
wire [$nearest_width*`SIZE_PREDICTION_CNT-1:0] data_wr_rd_even;
wire [$nearest_width*`SIZE_PREDICTION_CNT-1:0] data_wr_rd_odd;
reg [$nearest_width*`SIZE_PREDICTION_CNT-1:0] data_wr_rd;
reg [$nearest_width*`SIZE_PREDICTION_CNT-1:0] data_wr_wr;
reg update_wr_wr;
wire wr_wr_en_even;
wire wr_wr_en_odd;
LABEL

print "wire [",$nearest_width-1,":0] saturated_high;\n";
print "wire [",$nearest_width-1,":0] saturated_low;\n";


print "\n\nSRAM_2R1W_2stage_pipelined #(`SIZE_CNT_TABLE/",2*$nearest_width,", `SIZE_CNT_TBL_LOG-1-",$width_bits,", ",$nearest_width,"*`SIZE_PREDICTION_CNT)\n";
print "\t\tbp_even( .addr0_i(rd_index_even),.re0_i(1'b1), .addr1_i(wr_rd_index_pred), .re1_i(wr_rd_en_even), .addrWr_i(wr_wr_index1[`SIZE_CNT_TBL_LOG-1:",1+$width_bits,"]),\n";
print "\t\t.we_i(wr_wr_en_even),.data_i(data_wr_wr), .stall_i(stall_i), .flush_i(flush_i),.clk(clk),.reset(reset),.data0_o(data_rd_even), .data1_o(data_wr_rd_even));\n";

print "SRAM_2R1W_2stage_pipelined #(`SIZE_CNT_TABLE/",2*$nearest_width,", `SIZE_CNT_TBL_LOG-1-",$width_bits,", ",$nearest_width,"*`SIZE_PREDICTION_CNT)\n";
print "\t\tbp_odd( .addr0_i(rd_index_odd),.re0_i(1'b1), .addr1_i(wr_rd_index_pred), .re1_i(wr_rd_en_odd), .addrWr_i(wr_wr_index1[`SIZE_CNT_TBL_LOG-1:",1+$width_bits,"]),\n";
print "\t\t.we_i(wr_wr_en_odd),.data_i(data_wr_wr), .stall_i(stall_i), .flush_i(flush_i),.clk(clk),.reset(reset),.data0_o(data_rd_odd), .data1_o(data_wr_rd_odd));\n";

print "\n\nassign rd_index = pc_i[`SIZE_CNT_TBL_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET];\n";
print "assign rd_index_even = rd_index[",$width_bits,"] ? rd_index[`SIZE_CNT_TBL_LOG-1:",$width_bits+1,"] + 1'b1 :  rd_index[`SIZE_CNT_TBL_LOG-1:",$width_bits+1,"];\n";
print "assign rd_index_odd =  rd_index[`SIZE_CNT_TBL_LOG-1:",$width_bits+1,"];\n";

print "\n\nassign wr_rd_index = bp_tag_pc_i[`SIZE_CNT_TBL_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET];\n";
print "assign wr_rd_index_pred = wr_rd_index[`SIZE_CNT_TBL_LOG-1:",$width_bits+1,"];\n";

print "\nassign wr_rd_en_even = ~wr_rd_index[",$width_bits,"] & bp_update_i;\n";
print "assign wr_rd_en_odd = wr_rd_index[",$width_bits,"] & bp_update_i;\n";

print "\n\n/* Get the Write Enables for Even and Odd Banks*/\n";
print "assign wr_wr_en_even = update_wr_wr ? ~wr_wr_index1[",$width_bits,"] : 0;\n";
print "assign wr_wr_en_odd = update_wr_wr ? wr_wr_index1[",$width_bits,"] : 0;\n";

print "\n\n/* Get the Read Blocks in the correct order */\n";
print "assign data_rd_first = rd_index_bits[",$width_bits,"] ? data_rd_odd : data_rd_even;\n";
print "assign data_rd_second = rd_index_bits[",$width_bits,"] ? data_rd_even : data_rd_odd;\n";

print <<LABEL;
always@(*)
begin
LABEL
print "\tcase(rd_index_bits[",$width_bits-1,":0])\n";																	
for($i=0; $i<$nearest_width; $i++)
{
	print "\t",$width_bits,"'d",$i,":\n";
	print "\tbegin\n";
	for($j=0; $j<$width; $j++)
	{
		if($nearest_width-$i-$j>0)
		{
			print "\t\tcntValue",$j,"\t=\tdata_rd_first[",$nearest_width-$i-$j,"*`SIZE_PREDICTION_CNT-1:",$nearest_width-$i-$j-1,"*`SIZE_PREDICTION_CNT];\n";
		}
		else
		{
			print "\t\tcntValue",$j,"\t=\tdata_rd_second[",$nearest_width+$nearest_width-$i-$j,"*`SIZE_PREDICTION_CNT-1:",$nearest_width+$nearest_width-$i-$j-1,"*`SIZE_PREDICTION_CNT];\n";
		}
	}
	print "\tend\n";	
}
print "\tendcase\n";
print "end\n";

print <<LABEL;

/* Following makes prediction based on the counter value in the table pointed by
the Branch Address. */
LABEL
for($i=0; $i<$width; $i++)
{
	print "assign pred",$i,"_o = (cntValue",$i," > 2'b01 && valid_rd_index_bits) ? 1'b1 : 0;\n";
}

print <<LABEL;


/* Select the data from the odd and even bank as per the index also check with the write bypasses*/
always@(*)
begin
	if(wr_wr_valid2 && wr_wr_index2[`SIZE_CNT_TBL_LOG-1:$width_bits]==wr_wr_index1[`SIZE_CNT_TBL_LOG-1:$width_bits])
	begin
		data_wr_rd = wr_wr_data2;
	end
	else if(wr_wr_valid3 && wr_wr_index3[`SIZE_CNT_TBL_LOG-1:$width_bits]==wr_wr_index1[`SIZE_CNT_TBL_LOG-1:$width_bits])
	begin
		data_wr_rd = wr_wr_data3;
	end
	else
	begin
		data_wr_rd = wr_wr_data1;
	end
end


LABEL

for($i=0; $i<$nearest_width; $i++)
{
	print "assign saturated_high[",$i,"] = data_wr_rd[",$i+1,"*`SIZE_PREDICTION_CNT-1:",$i,"*`SIZE_PREDICTION_CNT]==`MAX_PREDICTION_CNT;\n";
}
print "\n";
for($i=0; $i<$nearest_width; $i++)
{
print "assign saturated_low[",$i,"] = data_wr_rd[",$i+1,"*`SIZE_PREDICTION_CNT-1:",$i,"*`SIZE_PREDICTION_CNT]==0;\n";
}

print <<LABEL;

/* Prepare the data for write */
always@(*)
begin
	data_wr_wr = data_wr_rd;
	update_wr_wr = 0;
LABEL

print "\tcase(wr_wr_index1[",$width_bits-1,":0])\n";
for($i=0; $i<$nearest_width; $i++)
{
	print "\t",$width_bits,"'d",$nearest_width-$i-1,":\n";
	print "\tbegin\n";
	print "\t\tcasex({saturated_high[",$i,"],saturated_low[",$i,"],wr_wr_pred1})\n";
	print "\t\t3'b0x1:\n";
	print "\t\tbegin\n";
	print "\t\t\tdata_wr_wr[",$i+1,"*`SIZE_PREDICTION_CNT-1:",$i,"*`SIZE_PREDICTION_CNT] = data_wr_rd[",$i+1,"*`SIZE_PREDICTION_CNT-1:",$i,"*`SIZE_PREDICTION_CNT] + 1'b1;\n";
	print "\t\t\tupdate_wr_wr = wr_wr_valid1;\n";
	print "\t\tend\n";
	print "\t\t3'bx00:\n";
	print "\t\tbegin\n";
	print "\t\t\tdata_wr_wr[",$i+1,"*`SIZE_PREDICTION_CNT-1:",$i,"*`SIZE_PREDICTION_CNT] = data_wr_rd[",$i+1,"*`SIZE_PREDICTION_CNT-1:",$i,"*`SIZE_PREDICTION_CNT] - 1'b1;\n";
	print "\t\t\tupdate_wr_wr = wr_wr_valid1;\n";
	print "\t\tend\n";
	print "\t\tendcase\n";
	print "\tend\n";
}
print "\tendcase\n";
print "end\n";


print <<LABEL;




always@(posedge clk)
begin
	if(reset||flush_i)
	begin
		rd_index_bits <= 0;
		valid_rd_index_bits <= 0;
	end
	else if(~stall_i)
	begin
		rd_index_bits <= rd_index[$width_bits:0];
		valid_rd_index_bits <= 1'b1;
	end
end

always@(posedge clk)
begin
	if(reset)
	begin
		wr_rd_index_reg <= 0;
		valid_wr_rd_index_reg <= 0;
		wr_rd_pred_reg <= 0;
		wr_wr_pred1 <= 0;
		wr_wr_data1 <= 0;
		wr_wr_index1 <= 0;
		wr_wr_valid1 <= 0;
		wr_wr_data2 <= 0;
		wr_wr_index2 <= 0;
		wr_wr_valid2 <= 0;
		wr_wr_data3 <= 0;
		wr_wr_index3 <= 0;
		wr_wr_valid3 <= 0;				
	end
	else
	begin
		wr_rd_index_reg <= wr_rd_index;
		valid_wr_rd_index_reg <= bp_update_i;
		wr_rd_pred_reg <= bp_dir_i;
		wr_wr_index1 <= wr_rd_index_reg;
		wr_wr_data1 <= wr_rd_index_reg[$width_bits] ? data_wr_rd_odd : data_wr_rd_even;
		wr_wr_valid1 <= valid_wr_rd_index_reg;
		wr_wr_pred1 <= wr_rd_pred_reg;
		wr_wr_index2 <= wr_wr_index1;
		wr_wr_data2 <= data_wr_wr;
		wr_wr_valid2 <= wr_wr_valid1;
		wr_wr_index3 <= wr_wr_index2;
		wr_wr_data3 <= wr_wr_data2;
		wr_wr_valid3 <= wr_wr_valid2;
	end
end


endmodule

LABEL



