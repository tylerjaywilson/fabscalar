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
# Purpose: This script creates a Verilog module of BTB (used for synthesis 
#	   purposes).
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
	print "Usage: perl ./generate_Fetch1b_ba.pl -w <width> [-m] [-v] [-h]\n";
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
$outputFileName = "Fetch1b.v";
$moduleName = "Fetch1b";

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
# Purpose: This block implements the Fetch1b for Block Ahead Fetch Unit.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps
	
LABEL

print <<LABEL;
module FetchStage1b(	input clk,
	input reset,
	input flush_i,
	input stall_i,

	input f_exp_i,
	input [`SIZE_PC-1:0] exp_pc_i,

	/************************************** Inputs from Fetch1 *********************************************************/
	input [`SIZE_PC-1:0]f1a_pc_i,

	/************************************** Inputs from Fetch1aFetch1b *********************************************************/
	input [`SIZE_PC-1:0]pc_i,
	input valid_pc_i,

	/************************************** Inputs from BTB *********************************************************/
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

	/************************************** Inputs from RAS *********************************************************/
	input [`SIZE_PC-1:0]pop_addr_i,
	input is_RAS_empty_i,

	/************************************** Inputs from SAS *********************************************************/			
	input [`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:0]pop_btb_entry_i,
	input is_SAS_empty_i,

	/************************************** Inputs from Fetch2 *********************************************************/
	input f2_valid_i,
	input [`FETCH_BANDWIDTH_LOG-1:0]f2_position_b_i,
	input [`TAG_TYPE_BITS-1:0]f2_tag_type_i,
	input f2_is_call_i,
	input f2_is_call_updated_i,
	input f2_is_return_updated_i,
	input [`SIZE_PC-1:0]f2_ras_top_addr_i,
	input f2_flush_pc_i,
	input [`SIZE_PC-1:0]f2_pc_i,
	input f2_flush_npc_i,	
	input [`SIZE_PC-1:0]f2_npc_i,
	input f2_copy_stack_i,
		
	/************************************** Outputs -> PC (to Fetch1Fetch2)*********************************************************/
	output [`SIZE_PC-1:0]pc_o,
	output valid_pc_o,

	/************************************** Outputs -> BTB information (to Fetch1Fetch2)*********************************************************/
LABEL
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

	/************************************** Outputs -> BP information (to Fetch1Fetch2)*********************************************************/
LABEL
for($i=0; $i<$width; $i++)
{
	print "\toutput pred",$i,"_o,\n";
}

print <<LABEL;

	/************************************** Outputs -> next_pc (to Fetch1a) *********************************************************/
	output reg[`SIZE_PC-1:0] next_pc_o,
	
	/************************************** Outputs -> RAS Update Information (to ras_lookahead) *********************************************************/
	output [`SIZE_PC-1:0]push_addr_o,
	output copy_stack_o,
	output push_RAS_o,
	output pop_RAS_o,
	output [`SIZE_PC-1:0]ras_top_addr_o,
	output update_ras_top_o,

	/************************************** Outputs -> SAS Update Information (to SAS) *********************************************************/
	output [`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:0]push_btb_entry_o,
	output push_SAS_o,
	output pop_SAS_o,

	/************************************** Outputs -> BTB Hit Information (to Fetch1Fetch2) *********************************************************/
	output reg btb_hit_o,
	output reg [`SIZE_PC-1:0]hit_target_o,
	output reg [`BRANCH_TYPE-1:0]hit_type_o,
	output reg [`FETCH_BANDWIDTH_LOG-1:0]hit_position_b_o,
	output reg hit_last_o,
	output reg pred_o,
	output [`TAG_TYPE_BITS-1:0]tag_type_o,
	output [`FETCH_BANDWIDTH_LOG-1:0]position_b_o
	);

/* Registers for Storing NextPC */			
reg [`SIZE_PC-1:0]npc;
reg valid_npc;

/* Normal Wires */		
LABEL

for($i=0; $i<$width; $i++)
{
	print "reg hit_",$i,";\n";				
	print "reg [`SIZE_PC-1:0]target_",$i,";\n";
	print "reg [`BRANCH_TYPE-1:0]type_",$i,";\n";
	print "reg [`FETCH_BANDWIDTH_LOG-1:0]position_b_",$i,";\n";
	print "reg last_",$i,";\n";
}

print <<LABEL;
reg [`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:0]hit_stack;
wire [`SIZE_PC-1:0]fall_through_pc;
wire [`SIZE_PC-1:0]next_block_pc;
reg [`SIZE_PC-1:0] pred_next_pc;
wire push_RAS_cond0;
wire push_RAS_cond1;
wire push_RAS_cond2;
wire [`SIZE_PC-1:0]RAS_push_addr;
wire pop_RAS_cond0;
wire pop_RAS_cond1;

LABEL
print "assign next_block_pc = f1a_pc_i + ",$width*8,";\n";
print <<LABEL;
assign pc_o = pc_i;
assign valid_pc_o = valid_pc_i;

LABEL


for($i=0; $i<$width; $i++)
{
	print "assign btb_hit_N",$i,"_o = btb_hit_N",$i,"_i;\n";
	print "assign target_N",$i,"_o = target_N",$i,"_i;\n";
	print "assign type_N",$i,"_o = type_N",$i,"_i;\n";
	print "assign position_b_N",$i,"_o = position_b_N",$i,"_i;\n";
	print "assign last_N",$i,"_o = last_N",$i,"_i;\n\n";
}
for($i=0; $i<$width; $i++)
{
	print "assign btb_hit_T",$i,"_o = btb_hit_T",$i,"_i;\n";
	print "assign target_T",$i,"_o = target_T",$i,"_i;\n";
	print "assign type_T",$i,"_o = type_T",$i,"_i;\n";
	print "assign position_b_T",$i,"_o = position_b_T",$i,"_i;\n";
	print "assign last_T",$i,"_o = last_T",$i,"_i;\n\n";
}
for($i=0; $i<$width; $i++)
{
	print "assign btb_hit_R",$i,"_o = btb_hit_R",$i,"_i;\n";
	print "assign target_R",$i,"_o = target_R",$i,"_i;\n";
	print "assign type_R",$i,"_o = type_R",$i,"_i;\n";
	print "assign position_b_R",$i,"_o = position_b_R",$i,"_i;\n";
	print "assign last_R",$i,"_o = last_R",$i,"_i;\n\n";
}
for($i=0; $i<$width; $i++)
{
	print "assign pred",$i,"_o = pred",$i,"_i;\n";
}
print <<LABEL;

assign push_SAS_o = (f2_is_call_i | f2_is_call_updated_i)&valid_pc_i&~f2_flush_pc_i&~flush_i;
assign push_btb_entry_o = hit_stack;
assign pop_SAS_o = (valid_pc_i && (f2_tag_type_i==2'b10) && ~f2_flush_pc_i && ~flush_i) ? 1'b1 : 1'b0;

assign push_RAS_cond0 = (valid_pc_i && hit_type_o==2'b10) ? 1'b1 : 1'b0;
assign push_RAS_cond1 = (f2_copy_stack_i & f2_is_call_i & ~valid_pc_i) ? 1'b1 : 1'b0;
assign push_RAS_cond2 = (f2_is_call_updated_i & ~valid_pc_i) ? 1'b1 : 1'b0;

assign pop_RAS_cond0 = (valid_pc_i && hit_type_o==2'b11) ? 1'b1 : 1'b0;
assign pop_RAS_cond1 = (f2_is_return_updated_i & ~valid_pc_i) ? 1'b1 : 1'b0;

assign push_RAS_o = (push_RAS_cond0 | push_RAS_cond1 | push_RAS_cond2)&~f2_flush_pc_i&~flush_i;
assign push_addr_o = (push_RAS_cond1 | push_RAS_cond2) ? f2_ras_top_addr_i : RAS_push_addr; 
assign update_ras_top_o = f2_flush_pc_i & f2_is_call_i & ~f2_copy_stack_i;
assign ras_top_addr_o = f2_ras_top_addr_i;
assign copy_stack_o = f2_copy_stack_i&~valid_pc_i;
assign pop_RAS_o = (pop_RAS_cond0 | pop_RAS_cond1)&~f2_flush_pc_i&~flush_i;

assign tag_type_o = f2_tag_type_i;
assign position_b_o = f2_position_b_i;

assign RAS_push_addr = f1a_pc_i+(hit_position_b_o<<3);

always@(posedge clk)
begin
	if(reset|f_exp_i)
	begin
		npc <= 0;
		valid_npc <= 0;
	end
	else if(~stall_i|flush_i)
	begin
		npc <= f2_npc_i;
		valid_npc <= f2_flush_npc_i;
	end
end

always@(*)
begin
	case(f2_tag_type_i)	
	2'b00:	begin
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t\thit_",$i," = btb_hit_N",$i,"_i;\n";				
	print "\t\ttarget_",$i," = target_N",$i,"_i;\n";
	print "\t\ttype_",$i," = type_N",$i,"_i;\n";
	print "\t\tposition_b_",$i," = position_b_N",$i,"_i;\n";
	print "\t\tlast_",$i," = last_N",$i,"_i;\n";
}
print <<LABEL;
	end
	2'b01: begin
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t\thit_",$i," = btb_hit_T",$i,"_i;\n";				
	print "\t\ttarget_",$i," = target_T",$i,"_i;\n";
	print "\t\ttype_",$i," = type_T",$i,"_i;\n";
	print "\t\tposition_b_",$i," = position_b_T",$i,"_i;\n";
	print "\t\tlast_",$i," = last_T",$i,"_i;\n";
}
print <<LABEL;
	end
	2'b10:	begin
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t\thit_",$i," = pop_btb_entry_i[0];\n";				
	print "\t\ttarget_",$i," = pop_btb_entry_i[`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1];\n";
	print "\t\ttype_",$i," = pop_btb_entry_i[`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`FETCH_BANDWIDTH_LOG+1+1];\n";
	print "\t\tposition_b_",$i," = pop_btb_entry_i[`FETCH_BANDWIDTH_LOG+1+1-1:1+1];\n";
	print "\t\tlast_",$i," = pop_btb_entry_i[1];\n";
}
print <<LABEL;
	end
	2'b11:	begin
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t\thit_",$i," = 0;\n";				
	print "\t\ttarget_",$i," = 0;\n";
	print "\t\ttype_",$i," = 0;\n";
	print "\t\tposition_b_",$i," = `FETCH_BANDWIDTH-1;\n";
	print "\t\tlast_",$i," = 0;\n";
}
print <<LABEL;
	end
	endcase
end


always@(*)
begin
LABEL
	print "\tbtb_hit_o = hit_",$width-1,";\n";
	print "\thit_target_o = target_",$width-1,";\n";
	print "\thit_type_o = type_",$width-1,";\n";
	print "\thit_position_b_o = position_b_",$width-1,";\n";
	print "\thit_last_o = last_",$width-1,";\n";
	print "\tpred_o = pred",$width-1,"_i;\n";
	print "\thit_stack = {target_R",$width-1,"_i,type_R",$width-1,"_i,position_b_R",$width-1,"_i,last_R",$width-1,"_i,btb_hit_R",$width-1,"_i};\n";
	print "\tcase(f2_position_b_i)\n";
for($i=0; $i<$width; $i++)
{
	print "\t",log2($width),"'d",$i,": begin\n";
	print "\t\tbtb_hit_o = hit_",$i,";\n";
	print "\t\thit_target_o = target_",$i,";\n";
	print "\t\thit_type_o = type_",$i,";\n";
	print "\t\thit_position_b_o = position_b_",$i,";\n";
	print "\t\thit_last_o = last_",$i,";\n";
	print "\t\tpred_o = pred",$i,"_i;\n";
	print "\t\thit_stack = {target_R",$i,"_i,type_R",$i,"_i,position_b_R",$i,"_i,last_R",$i,"_i,btb_hit_R",$i,"_i};\n";
	print "\tend\n";
}
print <<LABEL;
	endcase
end

assign fall_through_pc = f1a_pc_i + ((hit_position_b_o+1'b1)<<3);

always@(*)
begin
	case(hit_type_o)
	2'b00:	begin
		if(pred_o)
		begin
			pred_next_pc = hit_target_o;
		end
		else
		begin
			if(hit_last_o)
				pred_next_pc = next_block_pc;
			else
				pred_next_pc = fall_through_pc;
		end
	end
	2'b01:	begin
		pred_next_pc = hit_target_o;
	end
	2'b10:	begin
		pred_next_pc = hit_target_o;
	end
	2'b11:	begin
		if(pop_addr_i!=0)
			pred_next_pc = pop_addr_i;
		else
LABEL
print "\t\t\tpred_next_pc = f1a_pc_i + ",$width*8,";\n";
print <<LABEL;
		end
	endcase
end

always@(*)
begin
	if(f_exp_i)
		next_pc_o = exp_pc_i;
	else if(f2_flush_pc_i)
		next_pc_o = f2_pc_i;
	else
	begin
		if(~valid_pc_i & valid_npc)
			next_pc_o = npc;
		else
		begin
			if(btb_hit_o)
				next_pc_o = pred_next_pc;
			else
LABEL
print "\t\t\t\tnext_pc_o = f1a_pc_i + ",$width*8,";\n";
print <<LABEL;
		end
	end
end

endmodule
LABEL

