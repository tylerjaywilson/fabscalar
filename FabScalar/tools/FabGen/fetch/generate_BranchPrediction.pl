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
# Purpose: This script creates a Verilog module of BranchPrediction.
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
	print "Usage: perl ./generate_FetchStage1.pl -w <width> [-m] [-v] [-h]\n";
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

print "module ",$moduleName,"(input [`SIZE_PC-1:0] pc_i,\n";
print "\t\t\tinput [`SIZE_PC-1:0] updatePC_i,\n";
print "\t\t\tinput updateDir_i,\n";
print "\t\t\tinput updateEn_i,\n";
print "\t\t\tinput stall_i,\n";
print "\t\t\tinput bpFlush_i,\n";
print "\t\t\tinput clk,\n";
print "\t\t\tinput reset,\n";

for($i=0; $i<$width; $i++)
{
	print "\t\t\toutput prediction",$i,"_o";
	if($i<$width-1)
	{
			print ",";
	}
	print "\n";
}
print "\t\t\t);\n";

print <<LABEL;
wire [`SIZE_CNT_TBL_LOG-1:0]addr;
wire [`SIZE_CNT_TBL_LOG-1-`FETCH_BANDWIDTH_LOG-1:0] rd_index;
wire select_bank;
wire [`FETCH_BANDWIDTH_LOG-1:0] select_pred;

wire [`SIZE_CNT_TBL_LOG-1-`FETCH_BANDWIDTH_LOG-1:0]rd_index_even;
wire [`SIZE_CNT_TBL_LOG-1-`FETCH_BANDWIDTH_LOG-1:0]rd_index_odd;
wire [`SIZE_PREDICTION_CNT*$nearest_width-1:0]rd_data_even;
wire [`SIZE_PREDICTION_CNT*$nearest_width-1:0]rd_data_odd;
wire [`SIZE_PREDICTION_CNT*$nearest_width-1:0]rd_data_first;
wire [`SIZE_PREDICTION_CNT*$nearest_width-1:0]rd_data_second;

LABEL

for($i=0; $i<$width; $i++)
{
	print "reg [`SIZE_PREDICTION_CNT-1:0] cntValue",$i,";\n";
}

print <<LABEL;
wire [`SIZE_CNT_TBL_LOG-1:0]addr_upd;
wire [`SIZE_CNT_TBL_LOG-1-1:0] rd_index_upd;
wire select_bank_upd;
wire rd_en_odd;
wire rd_en_even;
wire [`SIZE_PREDICTION_CNT-1:0] rd_upd_even;
wire [`SIZE_PREDICTION_CNT-1:0] rd_upd_odd;
wire [`SIZE_PREDICTION_CNT-1:0] rd_upd;

/******* To be Shifted to the Pipeline Register **********/
reg wr_en;
reg [`SIZE_CNT_TBL_LOG-1:0]wr_index;
reg [`SIZE_PREDICTION_CNT-1:0]wr_counter;
reg wr_dir;
/********************************************************/

wire [`SIZE_CNT_TBL_LOG-1-1:0] wr_index_upd;
wire wr_select_bank;
wire [`SIZE_PREDICTION_CNT-1:0]wr_data;
wire wr_en_odd;
wire wr_en_even;

SRAM_2R1W_HY #(`SIZE_CNT_TABLE/2,`SIZE_CNT_TBL_LOG-1,`SIZE_PREDICTION_CNT,$nearest_width,`FETCH_BANDWIDTH_LOG)
		CounterTable_even(.re0_i(1'b1), .addr0_i(rd_index_even),
		.re1_i(rd_en_even), .addr1_i(rd_index_upd),
		.we_i(wr_en_even), .addrWr_i(wr_index_upd), .data_i(wr_data),
		.reset(reset), .clk(clk), .data0_o(rd_data_even), .data1_o(rd_upd_even));
SRAM_2R1W_HY #(`SIZE_CNT_TABLE/2,`SIZE_CNT_TBL_LOG-1,`SIZE_PREDICTION_CNT,$nearest_width,`FETCH_BANDWIDTH_LOG)
		CounterTable_odd(.re0_i(1'b1), .addr0_i(rd_index_odd),
		.re1_i(rd_en_odd), .addr1_i(rd_index_upd),
		.we_i(wr_en_odd), .addrWr_i(wr_index_upd), .data_i(wr_data),
		.reset(reset), .clk(clk), .data0_o(rd_data_odd), .data1_o(rd_upd_odd));


/*
		--------------------------------------------------
	pc_i =>	| Remaining bits | addr/Index bits | offset bits |
		--------------------------------------------------
		-----------------------------------------------------
	addr =>	| rd_index bits | select_bank bit | select_pred bits|
		-----------------------------------------------------
*/

assign addr 		= pc_i[`SIZE_CNT_TBL_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET];
assign rd_index		= addr[`SIZE_CNT_TBL_LOG-1:`FETCH_BANDWIDTH_LOG+1];
assign select_bank 	= addr[`FETCH_BANDWIDTH_LOG];
assign select_pred	= addr[`FETCH_BANDWIDTH_LOG-1:0];

/*
We need to generate addresses corresponding to the Odd and even banks
select_bank = 0		Even (rd_index)		Odd (rd_index)
select_bank = 1		Even (rd_index+1)	Odd (rd_index)
*/

assign rd_index_even	= select_bank ? rd_index+1 : rd_index;
assign rd_index_odd	= rd_index;


/*
We need to get the blocks in the correct order from the odd and even banks
select_bank = 0		Even (first)	Odd (second)
select_bank = 1		Even (second)	Odd (first)
*/

assign rd_data_first	= select_bank ? rd_data_odd  : rd_data_even ;
assign rd_data_second	= select_bank ? rd_data_even : rd_data_odd  ;


/*
Following selects the correct predictions as read from the banks
This is required since the pc_i can start from the middle of nowhere.
select_pred provides the data required to do the final slection.
*/
always@(*)
begin
case(select_pred)
LABEL

for($i=0; $i<$nearest_width; $i++)
{
	print "\t",log2($width),"'d",$i,":\n";
	print "\tbegin\n";
	for($j=0; $j<$width; $j++)
	{
		if (($nearest_width-$j-$i) > 0)
		{
			print "\t\tcntValue",$j," = rd_data_first[`SIZE_PREDICTION_CNT*",($nearest_width-$j-$i),"-1 : `SIZE_PREDICTION_CNT*",($nearest_width-$j-1-$i),"];\n";
		}
		else
		{
			print "\t\tcntValue",$j," = rd_data_second[`SIZE_PREDICTION_CNT*",($nearest_width+$nearest_width-$j-$i),"-1 : `SIZE_PREDICTION_CNT*",($nearest_width+$nearest_width-$j-1-$i),"];\n";
		}
	}
	print "\tend\n";
}
print "endcase\nend\n";

print <<LABEL;

/* Following makes prediction based on the counter value in the table pointed by
the Branch Address. */
LABEL
for($i=0; $i<$width; $i++)
{
	print "assign prediction",$i,"_o = (cntValue",$i," > 2'b01) ? 1'b1:1'b0;\n";
}


print <<LABEL;
/*
The following code handles the Update logic of the Predictor
The Write will happen in 2 cycles.
	Cycle 1: The counter will be read from the SRAM.
		In case the counter is written to in this cycle, the counter will be bypassed.
	Cycle 2: The counter will be incremented/decremented according to the requirement.
		In case the counter is needed to be written (change in the counter value), it will be written to the SRAM.
Please note that the pipeleine register needed between the read and the write in the update lies in Fetch1Fetch2.v pipeline register file.
*/
assign addr_upd 	= updatePC_i[`SIZE_CNT_TBL_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET];
assign rd_index_upd     = {addr_upd[`SIZE_CNT_TBL_LOG-1:`FETCH_BANDWIDTH_LOG+1],addr_upd[`FETCH_BANDWIDTH_LOG-1:0]};
assign select_bank_upd  = addr_upd[`FETCH_BANDWIDTH_LOG];
	
assign rd_en_odd = updateEn_i & select_bank_upd;
assign rd_en_even = updateEn_i & ~select_bank_upd;
	
assign rd_upd = ((addr_upd == wr_index) && wr_en) ? wr_data : (select_bank_upd ? rd_upd_odd : rd_upd_even);	

always@(posedge clk)
begin
	if(reset)
	begin
		wr_en <= 0;
		wr_index <= 0;
		wr_counter <= 0;
		wr_dir <= 0;
	end
	else
	begin
		wr_en <= updateEn_i;
		wr_index <= addr_upd;
		wr_counter <= rd_upd;
		wr_dir <= updateDir_i; 
	end
end
	
assign wr_index_upd = {wr_index[`SIZE_CNT_TBL_LOG-1:`FETCH_BANDWIDTH_LOG+1],wr_index[`FETCH_BANDWIDTH_LOG-1:0]};
assign wr_select_bank = wr_index[`FETCH_BANDWIDTH_LOG];
assign wr_data = wr_dir ? ((wr_counter==2'b11) ? wr_counter : wr_counter+1) : ((wr_counter==2'b00) ? wr_counter : wr_counter-1);
assign wr_en_odd = wr_en & (wr_data!=wr_counter) & wr_select_bank;
assign wr_en_even = wr_en & (wr_data!=wr_counter) & ~wr_select_bank;
		
endmodule
		
LABEL
