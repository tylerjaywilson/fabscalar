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
# Purpose:
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
	print "Usage: perl ./generate_Fetch2Decode_ba.pl -w <width> [-m] [-v] [-h]\n";
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
$outputFileName = "Fetch2Decode.v";
$moduleName = "Fetch2Decode";

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
# Purpose: This block implements pipeline register between Fetch2 and Decode.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL

print <<LABEL;
module Fetch2Decode(	input clk,
	input reset,
	input flush_i,
	input stall_i,	
	input f_recover_EX_i,

	input [`SIZE_PC-1:0] tag_pc_i,					/* Gives the PC which gives index and a part of tag */
	input [`TAG_TYPE_BITS-1:0] tag_type_i,			/* Gives the type of the direction giving the rest of tag (00 - Not Taken(N) 01 - Taken(T) 10 - Return(R))*/
	input [`SIZE_PC-1:0] target_i,					/* Target of the branch */
	input [`BRANCH_TYPE-1:0] type_i,				/* Ctrl Type of the Branch (00-Conditional 01-Jump 10-Call 11-Return)*/
	input [`FETCH_BANDWIDTH_LOG-1:0] position_b_i,	/* Position of branch in its fetch block */
	input last_i,									/* Last bit showing whehter the branch is the last branch in the fetch block */
	input [`FIFO_SIZE-1:0]fifo_even_i,				/* FIFO information as the last read from that index -> required to do direct write in a perticular way -> saves 1 read port*/
	input [`FIFO_SIZE-1:0]fifo_odd_i,
	input valid_i,									/* Shows whether there is an update or not */					

LABEL

for($i=0; $i<$width; $i++)
{
	print "\tinput instruction",$i,"Valid_i,\n";
	print "\tinput [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst",$i,"Packet_i,\n";
}

print <<LABEL;

	input [`SIZE_PC-1:0]bp_tag_pc_i,
	input bp_dir_i,
	input bp_update_i,

	input valid_pc_i,
	input [`SIZE_PC-1:0]last_pc_i,
	input btb_hit_i,
	input [`BRANCH_TYPE-1:0]br_type_i,
	input br_dir_i,
	input hit_last_i,
	input [`BRANCH_TYPE-1:0]hit_type_i,
	input [`SIZE_PC-1:0]hit_target_i,
	input [`FETCH_BANDWIDTH_LOG-1:0]hit_position_b_i,
	input is_ctrl_i,
	input is_jalr_jr_i,
	input [`FIFO_SIZE-1:0]curr_fifo_even_i,
	input [`FIFO_SIZE-1:0]curr_fifo_odd_i,
	input old_br_dir_i,						

	output reg valid_pc_o,
	output reg [`SIZE_PC-1:0]last_pc_o,
	output reg btb_hit_o,
	output reg [`BRANCH_TYPE-1:0]br_type_o,
	output reg br_dir_o,
	output reg hit_last_o,
	output reg [`BRANCH_TYPE-1:0]hit_type_o,
	output reg [`SIZE_PC-1:0]hit_target_o,
	output reg [`FETCH_BANDWIDTH_LOG-1:0]hit_position_b_o,
	output reg is_ctrl_o,
	output reg is_jalr_jr_o,						
	output reg [`FIFO_SIZE-1:0]curr_fifo_even_o,
	output reg [`FIFO_SIZE-1:0]curr_fifo_odd_o,
	output reg old_br_dir_o,						

	output reg [`SIZE_PC-1:0]bp_tag_pc_o,
	output reg bp_dir_o,
	output reg bp_update_o,

LABEL

for($i=0; $i<$width; $i++)
{
	print "\toutput reg instruction",$i,"Valid_o,\n";
	print "\toutput reg [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst",$i,"Packet_o,\n";
}

print <<LABEL;

	output reg [`SIZE_PC-1:0] tag_pc_o,					/* Gives the PC which gives index and a part of tag */
	output reg [`TAG_TYPE_BITS-1:0] tag_type_o,			/* Gives the type of the direction giving the rest of tag (00 - Not Taken(N) 01 - Taken(T) 10 - Return(R))*/
	output reg [`SIZE_PC-1:0] target_o,					/* Target of the branch */
	output reg [`BRANCH_TYPE-1:0] type_o,				/* Ctrl Type of the Branch (00-Conditional 01-Jump 10-Call 11-Return)*/
	output reg [`FETCH_BANDWIDTH_LOG-1:0] position_b_o,	/* Position of branch in its fetch block */
	output reg last_o,									/* Last bit showing whehter the branch is the last branch in the fetch block */
	output reg [`FIFO_SIZE-1:0]fifo_even_o,				/* FIFO information as the last read from that index -> required to do direct write in a perticular way -> saves 1 read port*/
	output reg [`FIFO_SIZE-1:0]fifo_odd_o,
	output reg valid_o									/* Shows whether there is an update or not */
	);

always@(posedge clk)
begin
	if(reset || flush_i)
	begin
		valid_pc_o <= 0;
		last_pc_o <= 0;
		btb_hit_o <= 0;
		br_type_o <= 0;
		br_dir_o <= 0;
		hit_last_o <= 0;
		hit_type_o <= 0;
		hit_target_o <= 0;
		hit_position_b_o <= `FETCH_BANDWIDTH-1;
		is_ctrl_o <= 0;
		is_jalr_jr_o <= 0;
		curr_fifo_even_o <= 0;
		curr_fifo_odd_o <= 0;
		old_br_dir_o <=0;						
	end
	else if(~stall_i|f_recover_EX_i)
	begin
		valid_pc_o <= valid_pc_i;
		last_pc_o <= last_pc_i;
		btb_hit_o <= btb_hit_i;
		br_type_o <= br_type_i;
		br_dir_o <= br_dir_i;
		hit_last_o <= hit_last_i;
		hit_type_o <= hit_type_i;
		hit_target_o <= hit_target_i;
		hit_position_b_o <= hit_position_b_i;
		is_ctrl_o <= is_ctrl_i;
		is_jalr_jr_o <= is_jalr_jr_i;	
		curr_fifo_even_o <= curr_fifo_even_i;
		curr_fifo_odd_o <= curr_fifo_odd_i;
		old_br_dir_o <= old_br_dir_i;					
	end
end

always@(posedge clk)
begin
	if(reset || flush_i)
	begin
		tag_pc_o <= 0;					/* Gives the PC which gives index and a part of tag */
		tag_type_o <= 0;				/* Gives the type of the direction giving the rest of tag (00 - Not Taken(N) 01 - Taken(T) 10 - Return(R))*/
		target_o <= 0;					/* Target of the branch */
		type_o <= 0;					/* Ctrl Type of the Branch (00-Conditional 01-Jump 10-Call 11-Return)*/
		position_b_o <= `FETCH_BANDWIDTH-1;		/* Position of branch in its fetch block */
		last_o <= 0;					/* Last bit showing whehter the branch is the last branch in the fetch block */
		fifo_even_o <= 0;				/* FIFO information as the last read from that index -> required to do direct write in a perticular way -> saves 1 read port*/
		fifo_odd_o <= 0;
		valid_o <= 0;					/* Shows whether there is an update or not */
	end
	else if(~stall_i)
	begin					
		tag_pc_o <= tag_pc_i;					/* Gives the PC which gives index and a part of tag */
		tag_type_o <= tag_type_i;				/* Gives the type of the direction giving the rest of tag (00 - Not Taken(N) 01 - Taken(T) 10 - Return(R))*/
		target_o <= target_i;					/* Target of the branch */
		type_o <= type_i	;					/* Ctrl Type of the Branch (00-Conditional 01-Jump 10-Call 11-Return)*/
		position_b_o <= position_b_i;			/* Position of branch in its fetch block */
		last_o <= last_i;						/* Last bit showing whehter the branch is the last branch in the fetch block */
		fifo_even_o <= fifo_even_i;				/* FIFO information as the last read from that index -> required to do direct write in a perticular way -> saves 1 read port*/
		fifo_odd_o <= fifo_odd_i;
		valid_o <= valid_i;						/* Shows whether there is an update or not */
	end	
end

always@(posedge clk)
begin
	if(reset || flush_i || f_recover_EX_i)
	begin
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t\tinstruction",$i,"Valid_o <= 0;\n";
	print "\t\tinst",$i,"Packet_o <= 0;\n";
}
print <<LABEL;
	end
	else if(~stall_i)
	begin					
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t\tinstruction",$i,"Valid_o <= instruction",$i,"Valid_i;\n";
	print "\t\tinst",$i,"Packet_o <= inst",$i,"Packet_i;\n";
}

print <<LABEL;
	end	
end

always@(posedge clk)
begin
	if(reset || flush_i)
	begin
		bp_tag_pc_o <= 0;
		bp_dir_o <= 0;
		bp_update_o <= 0;
	end
	else
	begin					
		bp_tag_pc_o <= bp_tag_pc_i;
		bp_dir_o <= bp_dir_i;
		bp_update_o <= bp_update_i;
	end	
end


endmodule

LABEL

