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


print <<LABEL;
module BTB (
	input clk,					/* Global Clock */
	input reset,				/* Global Reset */
	input stall_i,				/* Stall signal to stall the ongoing reads only */ 
	input flush_i,				/* Flush signal to flush the registers (does not flush the tables) */
	input [`SIZE_PC-1:0] pc_i,	/* pc from the global PC Register from Fetch1a */

	input flush_pc_i,
	input [`SIZE_BTB_INDEX_LOG-1:0]new_fifo_read_i,

	/* inputs for updates (currently from Fetch2/Predecode) */
	input [`SIZE_PC-1:0] tag_pc_i,			/* Gives the PC which gives index and a part of tag */
	input [`TAG_TYPE_BITS-1:0] tag_type_i,	/* Gives the type of the direction giving the rest of tag (00 - Not Taken(N) 01 - Taken(T) 10 - Return(R))*/
/*
------------------------------------------------------			-------------------------------------------------------------------------------------
|	Last PC of the previous block    |   Type    |     ======>>     | First Part of PC (E) | Index | Position in the block (e) | byte offset | Type (Z) |
------------------------------------------------------			-------------------------------------------------------------------------------------	
EeZ => Full Tag stored in Tag Array */

	input [`SIZE_PC-1:0] target_i,					/* Target of the branch */
	input [`BRANCH_TYPE-1:0] type_i,				/* Ctrl Type of the Branch (00-Conditional 01-Jump 10-Call 11-Return)*/
	input [`FETCH_BANDWIDTH_LOG-1:0] position_b_i,	/* Position of branch in its fetch block */
	input last_i,									/* Last bit showing whehter the branch is the last branch in the fetch block */
	input [`FIFO_SIZE-1:0]fifo_even_i,				/* FIFO information as the last read from that index -> required to do direct write in a perticular way -> saves 1 read port*/
	input [`FIFO_SIZE-1:0]fifo_odd_i,
	input valid_i,									/* Shows whether there is an update or not */


	/*	Outputs corresponding to different Tag Matches
LABEL
print "\tSince the fetch block is of size $width, there are 4 PC's possible with three possible directions (T/N/R given by tag_type) => ",3*$width," possible entries */\n";

for($i=0; $i<$width; $i++)
{
	print "\t/* output corresponding to pc+",$i,"*8 and not taken */\n";		
	print "\toutput btb_hit_N",$i,"_o,\n";
	print "\toutput [`SIZE_PC-1:0]target_N",$i,"_o,\n";
	print "\toutput [`BRANCH_TYPE-1:0]type_N",$i,"_o,\n";
	print "\toutput [`FETCH_BANDWIDTH_LOG-1:0]position_b_N",$i,"_o,\n";
	print "\toutput last_N",$i,"_o,\n";
	print "\n";
}
for($i=0; $i<$width; $i++)
{
	print "\t/* output corresponding to pc+",$i,"*8 and taken */\n";		
	print "\toutput btb_hit_T",$i,"_o,\n";
	print "\toutput [`SIZE_PC-1:0]target_T",$i,"_o,\n";
	print "\toutput [`BRANCH_TYPE-1:0]type_T",$i,"_o,\n";
	print "\toutput [`FETCH_BANDWIDTH_LOG-1:0]position_b_T",$i,"_o,\n";
	print "\toutput last_T",$i,"_o,\n";
	print "\n";
}
for($i=0; $i<$width; $i++)
{
	print "\t/* output corresponding to pc+",$i,"*8 and return */\n";		
	print "\toutput btb_hit_R",$i,"_o,\n";
	print "\toutput [`SIZE_PC-1:0]target_R",$i,"_o,\n";
	print "\toutput [`BRANCH_TYPE-1:0]type_R",$i,"_o,\n";
	print "\toutput [`FETCH_BANDWIDTH_LOG-1:0]position_b_R",$i,"_o,\n";
	print "\toutput last_R",$i,"_o,\n";
	print "\n";
}

print <<LABEL;
	output [`FIFO_SIZE-1:0]fifo_even_o,							/* Gives the FIFO information related to the index of the fetch block */
	output [`FIFO_SIZE-1:0]fifo_odd_o
	);


/* Register for bypass the update to the write logic*/
reg [`SIZE_PC-1:0]tag_pc1;
reg [`TAG_TYPE_BITS-1:0]tag_type1;	
reg [`SIZE_BTB_INDEX_LOG-1:0] index1;
reg [`FIFO_SIZE-1:0]fifo1;
reg valid1;

reg [`SIZE_PC-1:0]tag_pc2;
reg [`TAG_TYPE_BITS-1:0]tag_type2;	
reg [`SIZE_BTB_INDEX_LOG-1:0] index2;
reg [`FIFO_SIZE-1:0]fifo2;
reg valid2;

reg [`SIZE_PC-1:0]tag_pc3;
reg [`TAG_TYPE_BITS-1:0]tag_type3;	
reg [`SIZE_BTB_INDEX_LOG-1:0] index3;
reg [`FIFO_SIZE-1:0]fifo3;
reg valid3;

/* Register for pc for register between Fetch1a and Fetch1b*/ 
LABEL
for($i=0; $i<$width; $i++)
{
	print "reg [`SIZE_PC-1:0]pc$i;\n";
}


print <<LABEL;
reg pc_valid;

/* Interim hit results from odd and even banks */ 
LABEL
for($i=0; $i<$width; $i++)
{
	print "reg btb_hit_N",$i,"_even;\n";								
	print "reg [`SIZE_PC-1:0]target_N",$i,"_even;\n";					
	print "reg [`BRANCH_TYPE-1:0]type_N",$i,"_even;\n";					
	print "reg [`FETCH_BANDWIDTH_LOG-1:0]position_b_N",$i,"_even;\n";	
	print "reg last_N",$i,"_even;\n";									
}
for($i=0; $i<$width; $i++)
{
	print "reg btb_hit_T",$i,"_even;\n";								
	print "reg [`SIZE_PC-1:0]target_T",$i,"_even;\n";					
	print "reg [`BRANCH_TYPE-1:0]type_T",$i,"_even;\n";					
	print "reg [`FETCH_BANDWIDTH_LOG-1:0]position_b_T",$i,"_even;\n";	
	print "reg last_T",$i,"_even;\n";									
}
for($i=0; $i<$width; $i++)
{
	print "reg btb_hit_R",$i,"_even;\n";								
	print "reg [`SIZE_PC-1:0]target_R",$i,"_even;\n";					
	print "reg [`BRANCH_TYPE-1:0]type_R",$i,"_even;\n";					
	print "reg [`FETCH_BANDWIDTH_LOG-1:0]position_b_R",$i,"_even;\n";	
	print "reg last_R",$i,"_even;\n";									
}
print "\n";


for($i=0; $i<$width; $i++)
{
	print "reg btb_hit_N",$i,"_odd;\n";								
	print "reg [`SIZE_PC-1:0]target_N",$i,"_odd;\n";					
	print "reg [`BRANCH_TYPE-1:0]type_N",$i,"_odd;\n";					
	print "reg [`FETCH_BANDWIDTH_LOG-1:0]position_b_N",$i,"_odd;\n";	
	print "reg last_N",$i,"_odd;\n";									
}
for($i=0; $i<$width; $i++)
{
	print "reg btb_hit_T",$i,"_odd;\n";								
	print "reg [`SIZE_PC-1:0]target_T",$i,"_odd;\n";					
	print "reg [`BRANCH_TYPE-1:0]type_T",$i,"_odd;\n";					
	print "reg [`FETCH_BANDWIDTH_LOG-1:0]position_b_T",$i,"_odd;\n";	
	print "reg last_T",$i,"_odd;\n";									
}
for($i=0; $i<$width; $i++)
{
	print "reg btb_hit_R",$i,"_odd;\n";								
	print "reg [`SIZE_PC-1:0]target_R",$i,"_odd;\n";					
	print "reg [`BRANCH_TYPE-1:0]type_R",$i,"_odd;\n";					
	print "reg [`FETCH_BANDWIDTH_LOG-1:0]position_b_R",$i,"_odd;\n";	
	print "reg last_R",$i,"_odd;\n";									
}

print <<LABEL;

wire [`SIZE_BTB_INDEX_LOG-1:0] rd_index;
wire [`SIZE_BTB_INDEX_LOG-1-1:0] rd_index_even;
wire [`SIZE_BTB_INDEX_LOG-1-1:0] rd_index_odd;

wire [`SIZE_BTB_INDEX_LOG-1:0] wr_index;
wire [`SIZE_BTB_INDEX_LOG-1-1:0] wr_index_out;

wire [`SIZE_BTB_INDEX_LOG-1:0] rd_index_fifo;
wire [`SIZE_BTB_INDEX_LOG-1-1:0] rd_index_fifo_even;
wire [`SIZE_BTB_INDEX_LOG-1-1:0] rd_index_fifo_odd;

reg new_fifo;
reg [`SIZE_BTB_INDEX_LOG-1:0]new_fifo_index;

LABEL

for($i=0; $i<4; $i++)
{
	print "wire [`SIZE_PC-`SIZE_BTB_INDEX_LOG-`SIZE_BYTE_OFFSET+`TAG_TYPE_BITS-1:0] rd_tag",$i,"_even;\n";
}
for($i=0; $i<4; $i++)
{
	print "wire [`SIZE_PC-`SIZE_BTB_INDEX_LOG-`SIZE_BYTE_OFFSET+`TAG_TYPE_BITS-1:0] rd_tag",$i,"_odd;\n";
}
print <<LABEL;

wire [`SIZE_PC-`SIZE_BTB_INDEX_LOG-`SIZE_BYTE_OFFSET+`TAG_TYPE_BITS-1:0] wr_tag;

LABEL
for($i=0; $i<4; $i++)
{
	print "wire [`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:0] rd_data",$i,"_even;\n";
}
for($i=0; $i<4; $i++)
{
	print "wire [`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:0] rd_data",$i,"_odd;\n";
}
print "\n";
for($i=0; $i<$width; $i++)
{
	print "wire [`SIZE_PC-`SIZE_BTB_INDEX_LOG-`SIZE_BYTE_OFFSET+`TAG_TYPE_BITS-1:0] comp_tag",$i,"_N;\n";
}
for($i=0; $i<$width; $i++)
{
	print "wire [`SIZE_PC-`SIZE_BTB_INDEX_LOG-`SIZE_BYTE_OFFSET+`TAG_TYPE_BITS-1:0] comp_tag",$i,"_T;\n";
}
for($i=0; $i<$width; $i++)
{
	print "wire [`SIZE_PC-`SIZE_BTB_INDEX_LOG-`SIZE_BYTE_OFFSET+`TAG_TYPE_BITS-1:0] comp_tag",$i,"_R;\n";
}


print <<LABEL;

wire wr_en0_even;
wire wr_en1_even;
wire wr_en2_even;
wire wr_en3_even;
wire wr_en_fifo_even;
wire wr_en0_odd;
wire wr_en1_odd;
wire wr_en2_odd;
wire wr_en3_odd;
wire wr_en_fifo_odd;

reg [`FIFO_SIZE-1:0] wr_fifo_in;
wire [`FIFO_SIZE-1:0] wr_fifo_out;
wire wr_valid;

LABEL
for($i=0; $i<$width; $i++)
{
	print "wire [`BTB_ASSOC-1:0]sel_mask_N",$i,"_even;\n";
}
print "\n";
for($i=0; $i<$width; $i++)
{
	print "wire [`BTB_ASSOC-1:0]sel_mask_T",$i,"_even;\n";
}
print "\n";
for($i=0; $i<$width; $i++)
{
	print "wire [`BTB_ASSOC-1:0]sel_mask_R",$i,"_even;\n";
}
print "\n";
for($i=0; $i<$width; $i++)
{
	print "wire [`BTB_ASSOC-1:0]sel_mask_N",$i,"_odd;\n";
}
print "\n";
for($i=0; $i<$width; $i++)
{
	print "wire [`BTB_ASSOC-1:0]sel_mask_T",$i,"_odd;\n";
}
print "\n";
for($i=0; $i<$width; $i++)
{
	print "wire [`BTB_ASSOC-1:0]sel_mask_R",$i,"_odd;\n";
}

print <<LABEL;


/* Initializing BTB Tag and BTB Data SRAMs. SRAM_1R1W_2stage_pipelined is the Verilog model of RAM
with 1 READ and 1 WRITE ports.*/

/* EVEN Arrays */
	SRAM_1R1W_2stage_pipelined #(`SIZE_BTB_INDEX/2, `SIZE_BTB_INDEX_LOG-1, `SIZE_PC-`SIZE_BTB_INDEX_LOG-`SIZE_BYTE_OFFSET+`TAG_TYPE_BITS+`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1)
		btb_way0_even(.addr0_i(rd_index_even),.re_i(1'b1),.addrWr_i(wr_index_out),.we_i(wr_en0_even),.data_i({wr_tag,target_i,type_i,position_b_i,last_i,valid_i}), .stall_i(stall_i), .flush_i(flush_i),
		.clk(clk),.reset(reset),.data0_o({rd_tag0_even,rd_data0_even}));

	SRAM_1R1W_2stage_pipelined #(`SIZE_BTB_INDEX/2, `SIZE_BTB_INDEX_LOG-1, `SIZE_PC-`SIZE_BTB_INDEX_LOG-`SIZE_BYTE_OFFSET+`TAG_TYPE_BITS+`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1)
		btb_way1_even(.addr0_i(rd_index_even),.re_i(1'b1),.addrWr_i(wr_index_out),.we_i(wr_en1_even),.data_i({wr_tag,target_i,type_i,position_b_i,last_i,valid_i}), .stall_i(stall_i), .flush_i(flush_i),
		.clk(clk),.reset(reset),.data0_o({rd_tag1_even,rd_data1_even}));

	SRAM_1R1W_2stage_pipelined #(`SIZE_BTB_INDEX/2, `SIZE_BTB_INDEX_LOG-1, `SIZE_PC-`SIZE_BTB_INDEX_LOG-`SIZE_BYTE_OFFSET+`TAG_TYPE_BITS+`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1)
		btb_way2_even(.addr0_i(rd_index_even),.re_i(1'b1),.addrWr_i(wr_index_out),.we_i(wr_en2_even),.data_i({wr_tag,target_i,type_i,position_b_i,last_i,valid_i}), .stall_i(stall_i), .flush_i(flush_i),
		.clk(clk),.reset(reset),.data0_o({rd_tag2_even,rd_data2_even}));

	SRAM_1R1W_2stage_pipelined #(`SIZE_BTB_INDEX/2, `SIZE_BTB_INDEX_LOG-1, `SIZE_PC-`SIZE_BTB_INDEX_LOG-`SIZE_BYTE_OFFSET+`TAG_TYPE_BITS+`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1)
		btb_way3_even(.addr0_i(rd_index_even),.re_i(1'b1),.addrWr_i(wr_index_out),.we_i(wr_en3_even),.data_i({wr_tag,target_i,type_i,position_b_i,last_i,valid_i}), .stall_i(stall_i), .flush_i(flush_i),
		.clk(clk),.reset(reset),.data0_o({rd_tag3_even,rd_data3_even}));

	SRAM_1R1W_2stage_pipelined_fifo #(`SIZE_BTB_INDEX/2, `SIZE_BTB_INDEX_LOG-1, `FIFO_SIZE)
		btbFIFO_even(.addr0_i(rd_index_fifo_even),.re_i(1'b1),.addrWr_i(wr_index_out),.we_i(wr_en_fifo_even),.data_i(wr_fifo_out), .stall_i(stall_i), .flush_i(flush_i),
		.clk(clk),.reset(reset),.data0_o(fifo_even_o));		  

/* ODD Arrays */

	SRAM_1R1W_2stage_pipelined #(`SIZE_BTB_INDEX/2, `SIZE_BTB_INDEX_LOG-1, `SIZE_PC-`SIZE_BTB_INDEX_LOG-`SIZE_BYTE_OFFSET+`TAG_TYPE_BITS+`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1)
		btb_way0_odd(.addr0_i(rd_index_odd),.re_i(1'b1),.addrWr_i(wr_index_out),.we_i(wr_en0_odd),.data_i({wr_tag,target_i,type_i,position_b_i,last_i,valid_i}), .stall_i(stall_i), .flush_i(flush_i),
		.clk(clk),.reset(reset),.data0_o({rd_tag0_odd,rd_data0_odd}));

	SRAM_1R1W_2stage_pipelined #(`SIZE_BTB_INDEX/2, `SIZE_BTB_INDEX_LOG-1, `SIZE_PC-`SIZE_BTB_INDEX_LOG-`SIZE_BYTE_OFFSET+`TAG_TYPE_BITS+`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1)
		btb_way1_odd(.addr0_i(rd_index_odd),.re_i(1'b1),.addrWr_i(wr_index_out),.we_i(wr_en1_odd),.data_i({wr_tag,target_i,type_i,position_b_i,last_i,valid_i}), .stall_i(stall_i), .flush_i(flush_i),
		.clk(clk),.reset(reset),.data0_o({rd_tag1_odd,rd_data1_odd}));

	SRAM_1R1W_2stage_pipelined #(`SIZE_BTB_INDEX/2, `SIZE_BTB_INDEX_LOG-1, `SIZE_PC-`SIZE_BTB_INDEX_LOG-`SIZE_BYTE_OFFSET+`TAG_TYPE_BITS+`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1)
		btb_way2_odd(.addr0_i(rd_index_odd),.re_i(1'b1),.addrWr_i(wr_index_out),.we_i(wr_en2_odd),.data_i({wr_tag,target_i,type_i,position_b_i,last_i,valid_i}), .stall_i(stall_i), .flush_i(flush_i),
		.clk(clk),.reset(reset),.data0_o({rd_tag2_odd,rd_data2_odd}));

	SRAM_1R1W_2stage_pipelined #(`SIZE_BTB_INDEX/2, `SIZE_BTB_INDEX_LOG-1, `SIZE_PC-`SIZE_BTB_INDEX_LOG-`SIZE_BYTE_OFFSET+`TAG_TYPE_BITS+`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1)
		btb_way3_odd(.addr0_i(rd_index_odd),.re_i(1'b1),.addrWr_i(wr_index_out),.we_i(wr_en3_odd),.data_i({wr_tag,target_i,type_i,position_b_i,last_i,valid_i}), .stall_i(stall_i), .flush_i(flush_i),
		.clk(clk),.reset(reset),.data0_o({rd_tag3_odd,rd_data3_odd}));

	SRAM_1R1W_2stage_pipelined_fifo #(`SIZE_BTB_INDEX/2, `SIZE_BTB_INDEX_LOG-1, `FIFO_SIZE)
		btbFIFO_odd(.addr0_i(rd_index_fifo_odd),.re_i(1'b1),.addrWr_i(wr_index_out),.we_i(wr_en_fifo_odd),.data_i(wr_fifo_out), .stall_i(stall_i), .flush_i(flush_i),
		.clk(clk),.reset(reset),.data0_o(fifo_odd_o));		  


always@(posedge clk)
begin
	if(reset)
	begin
		new_fifo <= 0;
		new_fifo_index <= 0;
	end
	else
	begin
		new_fifo <= flush_pc_i;
		new_fifo_index <= new_fifo_read_i;
	end
end

/* get the update register updated */
always @(posedge clk)
begin
	if(reset)
	begin
		tag_pc1 <= 0;
		tag_type1 <= 0;
		index1 <= 0;
		fifo1 <= 0;
		valid1 <= 0;
		tag_pc2 <= 0;
		tag_type2 <= 0;		
		index2 <= 0;
		fifo2 <= 0;
		valid2 <= 0;
		tag_pc3 <= 0;
		tag_type3 <= 0;		
		index3 <= 0;
		fifo3 <= 0;
		valid3 <= 0;
	end
	else if(wr_valid)
	begin
		tag_pc1 <= tag_pc_i;
		tag_type1 <= tag_type_i;	
		index1 <= wr_index;
		fifo1 <= wr_fifo_out;
		valid1 <= wr_valid;
		tag_pc2 <= tag_pc1;
		tag_type2 <= tag_type1;		
		index2 <= index1;
		fifo2 <= fifo1;
		valid2 <= valid1;
		tag_pc3 <= tag_pc2;
		tag_type3 <= tag_type2;		
		index3 <= index2;
		fifo3 <= fifo2;
		valid3 <= valid2;		
	end
end

/* get the pc correct */
always @(posedge clk) 
begin
	if(reset || flush_i)
	begin
LABEL

for($i=0; $i<$width; $i++)
{
	print "\t\tpc$i <= 0;\n";
}
print <<LABEL;
		pc_valid <= 0;
	end
	else if(!stall_i)
	begin
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t\tpc$i <= pc_i + ",$i*8,";\n";
}

print <<LABEL;
		pc_valid <= 1'b1;
	end
end

assign wr_valid = valid_i && !(((tag_pc_i==tag_pc1)&& (tag_type_i==tag_type1)) || ((tag_pc_i==tag_pc2)&& (tag_type_i==tag_type2)) || ((tag_pc_i==tag_pc3)&& (tag_type_i==tag_type3)));

assign wr_en3_even = wr_valid && ~wr_index[0] ? ~(wr_fifo_out[1] | wr_fifo_out[0]) : 0;
assign wr_en2_even = wr_valid && ~wr_index[0] ? ~(wr_fifo_out[3] | wr_fifo_out[2]) : 0;
assign wr_en1_even = wr_valid && ~wr_index[0] ? ~(wr_fifo_out[5] | wr_fifo_out[4]) : 0;
assign wr_en0_even = wr_valid && ~wr_index[0] ? ~(wr_fifo_out[7] | wr_fifo_out[6]) : 0;
assign wr_en3_odd = wr_valid && wr_index[0] ? ~(wr_fifo_out[1] | wr_fifo_out[0]) : 0;
assign wr_en2_odd = wr_valid && wr_index[0] ? ~(wr_fifo_out[3] | wr_fifo_out[2]) : 0;
assign wr_en1_odd = wr_valid && wr_index[0] ? ~(wr_fifo_out[5] | wr_fifo_out[4]) : 0;
assign wr_en0_odd = wr_valid && wr_index[0] ? ~(wr_fifo_out[7] | wr_fifo_out[6]) : 0;

assign wr_en_fifo_even = wr_en0_even|wr_en1_even|wr_en2_even|wr_en3_even;
assign wr_en_fifo_odd = wr_en0_odd|wr_en1_odd|wr_en2_odd|wr_en3_odd;

assign rd_index_fifo = new_fifo ? new_fifo_index : pc0[`SIZE_BTB_INDEX_LOG+`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET];
assign rd_index_fifo_even = rd_index_fifo[0] ? rd_index_fifo[`SIZE_BTB_INDEX_LOG-1:1] + 1'b1 : rd_index_fifo[`SIZE_BTB_INDEX_LOG-1:1];
assign rd_index_fifo_odd = rd_index_fifo[`SIZE_BTB_INDEX_LOG-1:1];	  

assign rd_index = pc_i[`SIZE_BTB_INDEX_LOG+`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET];
assign rd_index_even = rd_index[0] ? rd_index[`SIZE_BTB_INDEX_LOG-1:1] + 1'b1 : rd_index[`SIZE_BTB_INDEX_LOG-1:1];
assign rd_index_odd = rd_index[`SIZE_BTB_INDEX_LOG-1:1];

assign wr_index = tag_pc_i[`SIZE_BTB_INDEX_LOG+`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET];
assign wr_index_out = wr_index[`SIZE_BTB_INDEX_LOG-1:1];

LABEL

for($i=0; $i<$width; $i++)
{
	print "assign comp_tag",$i,"_N = {pc",$i,"[`SIZE_PC-1:`SIZE_BTB_INDEX_LOG+`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET],pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET],2'd0};\n";
}
for($i=0; $i<$width; $i++)
{
	print "assign comp_tag",$i,"_T = {pc",$i,"[`SIZE_PC-1:`SIZE_BTB_INDEX_LOG+`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET],pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET],2'd1};\n";
}
	for($i=0; $i<$width; $i++)
	{
	print "assign comp_tag",$i,"_R = {pc",$i,"[`SIZE_PC-1:`SIZE_BTB_INDEX_LOG+`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET],pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET],2'd2};\n";
}
print <<LABEL;
		
assign wr_tag = {tag_pc_i[`SIZE_PC-1:`SIZE_BTB_INDEX_LOG+`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET],tag_pc_i[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET],tag_type_i};
		
/* Get the Fifo information from the bypasses since we removed the bypasses from the read path
This is done to takle the window of vulnerability*/
always@(*)
begin
	if(wr_index==index1 && valid1 && valid_i)
	begin
		wr_fifo_in = fifo1;
	end
	else if (wr_index==index2 && valid2 && valid_i)
	begin
		wr_fifo_in = fifo2;
	end
	else if (wr_index==index3 && valid3 && valid_i)
	begin
		wr_fifo_in = fifo3;
	end
	else if (wr_index[0] && valid_i)
	begin
		wr_fifo_in = fifo_odd_i;
	end
	else
	begin
		wr_fifo_in = fifo_even_i;
	end
end

assign wr_fifo_out[1:0] = wr_fifo_in[1:0]+1'b1;
assign wr_fifo_out[3:2] = wr_fifo_in[3:2]+1'b1;
assign wr_fifo_out[5:4] = wr_fifo_in[5:4]+1'b1;
assign wr_fifo_out[7:6] = wr_fifo_in[7:6]+1'b1;

/* Compare the tags (comp_*) with the read tags from the BTB*/

LABEL
		
for($i=0; $i<$width; $i++)
{
	print "\n\n/* For getting hit_N",$i,"* for even bank*/\n";
	for($j=0; $j<4; $j++)
	{
		print "assign sel_mask_N",$i,"_even[$j] = (pc_valid && rd_data",$j,"_even[0] && rd_tag",$j,"_even==comp_tag",$i,"_N) ? 1'b1 : 1'b0;\n";
	}
	print "always@(*)\n";
	print "begin\n";
	print "\tbtb_hit_N",$i,"_even = 1'b0;\n";
	print "\ttarget_N",$i,"_even = 0;\n";
	print "\ttype_N",$i,"_even = 0;\n";
	print "\tposition_b_N",$i,"_even = `FETCH_BANDWIDTH-1'b1;\n";
	print "\tlast_N",$i,"_even = 0;\n";
	print "\tcase(sel_mask_N",$i,"_even)\n";
	for($j=0; $j<4; $j++)
	{
		print "\t4'd",1<<$j,":\n";
		print "\tbegin\n";
		print "\t\tbtb_hit_N",$i,"_even = 1'b1;\n";
		print "\t\ttarget_N",$i,"_even = rd_data",$j,"_even[`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1];\n";
		print "\t\ttype_N",$i,"_even = rd_data",$j,"_even[`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`FETCH_BANDWIDTH_LOG+1+1];\n";
		print "\t\tposition_b_N",$i,"_even = rd_data",$j,"_even[`FETCH_BANDWIDTH_LOG+1+1-1:1+1];\n";
		print "\t\tlast_N",$i,"_even = rd_data",$j,"_even[1];\n";		
		print "\tend\n";
	}
	print "\tendcase\n";
	print "end\n";
}

		
for($i=0; $i<$width; $i++)
{
	print "\n\n/* For getting hit_T",$i,"* for even bank*/\n";
	for($j=0; $j<4; $j++)
	{
		print "assign sel_mask_T",$i,"_even[$j] = (pc_valid && rd_data",$j,"_even[0] && rd_tag",$j,"_even==comp_tag",$i,"_T) ? 1'b1 : 1'b0;\n";
	}
	print "always@(*)\n";
	print "begin\n";
	print "\tbtb_hit_T",$i,"_even = 1'b0;\n";
	print "\ttarget_T",$i,"_even = 0;\n";
	print "\ttype_T",$i,"_even = 0;\n";
	print "\tposition_b_T",$i,"_even = `FETCH_BANDWIDTH-1'b1;\n";
	print "\tlast_T",$i,"_even = 0;\n";
	print "\tcase(sel_mask_T",$i,"_even)\n";
	for($j=0; $j<4; $j++)
	{
		print "\t4'd",1<<$j,":\n";
		print "\tbegin\n";
		print "\t\tbtb_hit_T",$i,"_even = 1'b1;\n";
		print "\t\ttarget_T",$i,"_even = rd_data",$j,"_even[`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1];\n";
		print "\t\ttype_T",$i,"_even = rd_data",$j,"_even[`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`FETCH_BANDWIDTH_LOG+1+1];\n";
		print "\t\tposition_b_T",$i,"_even = rd_data",$j,"_even[`FETCH_BANDWIDTH_LOG+1+1-1:1+1];\n";
		print "\t\tlast_T",$i,"_even = rd_data",$j,"_even[1];\n";		
		print "\tend\n";
	}
	print "\tendcase\n";
	print "end\n";
}
	
for($i=0; $i<$width; $i++)
{
	print "\n\n/* For getting hit_R",$i,"* for even bank*/\n";
	for($j=0; $j<4; $j++)
	{
		print "assign sel_mask_R",$i,"_even[$j] = (pc_valid && rd_data",$j,"_even[0] && rd_tag",$j,"_even==comp_tag",$i,"_R) ? 1'b1 : 1'b0;\n";
	}
	print "always@(*)\n";
	print "begin\n";
	print "\tbtb_hit_R",$i,"_even = 1'b0;\n";
	print "\ttarget_R",$i,"_even = 0;\n";
	print "\ttype_R",$i,"_even = 0;\n";
	print "\tposition_b_R",$i,"_even = `FETCH_BANDWIDTH-1'b1;\n";
	print "\tlast_R",$i,"_even = 0;\n";
	print "\tcase(sel_mask_R",$i,"_even)\n";
	for($j=0; $j<4; $j++)
	{
		print "\t4'd",1<<$j,":\n";
		print "\tbegin\n";
		print "\t\tbtb_hit_R",$i,"_even = 1'b1;\n";
		print "\t\ttarget_R",$i,"_even = rd_data",$j,"_even[`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1];\n";
		print "\t\ttype_R",$i,"_even = rd_data",$j,"_even[`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`FETCH_BANDWIDTH_LOG+1+1];\n";
		print "\t\tposition_b_R",$i,"_even = rd_data",$j,"_even[`FETCH_BANDWIDTH_LOG+1+1-1:1+1];\n";
		print "\t\tlast_R",$i,"_even = rd_data",$j,"_even[1];\n";		
		print "\tend\n";
	}
	print "\tendcase\n";
	print "end\n";
}		
		
for($i=0; $i<$width; $i++)
{
	print "\n\n/* For getting hit_N",$i,"* for odd bank*/\n";
	for($j=0; $j<4; $j++)
	{
		print "assign sel_mask_N",$i,"_odd[$j] = (pc_valid && rd_data",$j,"_odd[0] && rd_tag",$j,"_odd==comp_tag",$i,"_N) ? 1'b1 : 1'b0;\n";
	}
	print "always@(*)\n";
	print "begin\n";
	print "\tbtb_hit_N",$i,"_odd = 1'b0;\n";
	print "\ttarget_N",$i,"_odd = 0;\n";
	print "\ttype_N",$i,"_odd = 0;\n";
	print "\tposition_b_N",$i,"_odd = `FETCH_BANDWIDTH-1'b1;\n";
	print "\tlast_N",$i,"_odd = 0;\n";
	print "\tcase(sel_mask_N",$i,"_odd)\n";
	for($j=0; $j<4; $j++)
	{
		print "\t4'd",1<<$j,":\n";
		print "\tbegin\n";
		print "\t\tbtb_hit_N",$i,"_odd = 1'b1;\n";
		print "\t\ttarget_N",$i,"_odd = rd_data",$j,"_odd[`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1];\n";
		print "\t\ttype_N",$i,"_odd = rd_data",$j,"_odd[`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`FETCH_BANDWIDTH_LOG+1+1];\n";
		print "\t\tposition_b_N",$i,"_odd = rd_data",$j,"_odd[`FETCH_BANDWIDTH_LOG+1+1-1:1+1];\n";
		print "\t\tlast_N",$i,"_odd = rd_data",$j,"_odd[1];\n";		
		print "\tend\n";
	}
	print "\tendcase\n";
	print "end\n";
}
		
		
for($i=0; $i<$width; $i++)
{
	print "\n\n/* For getting hit_T",$i,"* for odd bank*/\n";
	for($j=0; $j<4; $j++)
	{
		print "assign sel_mask_T",$i,"_odd[$j] = (pc_valid && rd_data",$j,"_odd[0] && rd_tag",$j,"_odd==comp_tag",$i,"_T) ? 1'b1 : 1'b0;\n";
	}
	print "always@(*)\n";
	print "begin\n";
	print "\tbtb_hit_T",$i,"_odd = 1'b0;\n";
	print "\ttarget_T",$i,"_odd = 0;\n";
	print "\ttype_T",$i,"_odd = 0;\n";
	print "\tposition_b_T",$i,"_odd = `FETCH_BANDWIDTH-1'b1;\n";
	print "\tlast_T",$i,"_odd = 0;\n";
	print "\tcase(sel_mask_T",$i,"_odd)\n";
	for($j=0; $j<4; $j++)
	{
		print "\t4'd",1<<$j,":\n";
		print "\tbegin\n";
		print "\t\tbtb_hit_T",$i,"_odd = 1'b1;\n";
		print "\t\ttarget_T",$i,"_odd = rd_data",$j,"_odd[`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1];\n";
		print "\t\ttype_T",$i,"_odd = rd_data",$j,"_odd[`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`FETCH_BANDWIDTH_LOG+1+1];\n";
		print "\t\tposition_b_T",$i,"_odd = rd_data",$j,"_odd[`FETCH_BANDWIDTH_LOG+1+1-1:1+1];\n";
		print "\t\tlast_T",$i,"_odd = rd_data",$j,"_odd[1];\n";		
		print "\tend\n";
	}
	print "\tendcase\n";
	print "end\n";
}
		
for($i=0; $i<$width; $i++)
{
	print "\n\n/* For getting hit_R",$i,"* for odd bank*/\n";
	for($j=0; $j<4; $j++)
	{
		print "assign sel_mask_R",$i,"_odd[$j] = (pc_valid && rd_data",$j,"_odd[0] && rd_tag",$j,"_odd==comp_tag",$i,"_R) ? 1'b1 : 1'b0;\n";
	}
	print "always@(*)\n";
	print "begin\n";
	print "\tbtb_hit_R",$i,"_odd = 1'b0;\n";
	print "\ttarget_R",$i,"_odd = 0;\n";
	print "\ttype_R",$i,"_odd = 0;\n";
	print "\tposition_b_R",$i,"_odd = `FETCH_BANDWIDTH-1'b1;\n";
	print "\tlast_R",$i,"_odd = 0;\n";
	print "\tcase(sel_mask_R",$i,"_odd)\n";
	for($j=0; $j<4; $j++)
	{
		print "\t4'd",1<<$j,":\n";
		print "\tbegin\n";
		print "\t\tbtb_hit_R",$i,"_odd = 1'b1;\n";
		print "\t\ttarget_R",$i,"_odd = rd_data",$j,"_odd[`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1];\n";
		print "\t\ttype_R",$i,"_odd = rd_data",$j,"_odd[`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`FETCH_BANDWIDTH_LOG+1+1];\n";
		print "\t\tposition_b_R",$i,"_odd = rd_data",$j,"_odd[`FETCH_BANDWIDTH_LOG+1+1-1:1+1];\n";
		print "\t\tlast_R",$i,"_odd = rd_data",$j,"_odd[1];\n";		
		print "\tend\n";
	}
	print "\tendcase\n";
	print "end\n";
}	
		
print <<LABEL;
		
		
		
/* Routing from Odd and Even Banks to the actual outputs */
LABEL
for($i=0; $i<$width; $i++)
{
	print "assign btb_hit_N",$i,"_o = pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET] ? btb_hit_N",$i,"_odd : btb_hit_N",$i,"_even;\n";
	print "assign target_N",$i,"_o = pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET] ? target_N",$i,"_odd : target_N",$i,"_even;\n";
	print "assign type_N",$i,"_o = pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET] ? type_N",$i,"_odd : type_N",$i,"_even;\n";
	print "assign position_b_N",$i,"_o = pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET] ? position_b_N",$i,"_odd : position_b_N",$i,"_even;\n";
	print "assign last_N",$i,"_o = pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET] ? last_N",$i,"_odd : last_N",$i,"_even;\n\n";
}
for($i=0; $i<$width; $i++)
{
	print "assign btb_hit_T",$i,"_o = pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET] ? btb_hit_T",$i,"_odd : btb_hit_T",$i,"_even;\n";
	print "assign target_T",$i,"_o = pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET] ? target_T",$i,"_odd : target_T",$i,"_even;\n";
	print "assign type_T",$i,"_o = pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET] ? type_T",$i,"_odd : type_T",$i,"_even;\n";
	print "assign position_b_T",$i,"_o = pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET] ? position_b_T",$i,"_odd : position_b_T",$i,"_even;\n";
	print "assign last_T",$i,"_o = pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET] ? last_T",$i,"_odd : last_T",$i,"_even;\n\n";
}
for($i=0; $i<$width; $i++)
{
	print "assign btb_hit_R",$i,"_o = pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET] ? btb_hit_R",$i,"_odd : btb_hit_R",$i,"_even;\n";
	print "assign target_R",$i,"_o = pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET] ? target_R",$i,"_odd : target_R",$i,"_even;\n";
	print "assign type_R",$i,"_o = pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET] ? type_R",$i,"_odd : type_R",$i,"_even;\n";
	print "assign position_b_R",$i,"_o = pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET] ? position_b_R",$i,"_odd : position_b_R",$i,"_even;\n";
	print "assign last_R",$i,"_o = pc",$i,"[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET] ? last_R",$i,"_odd : last_R",$i,"_even;\n\n";
}	
		
print <<LABEL;
		
endmodule
LABEL
		
