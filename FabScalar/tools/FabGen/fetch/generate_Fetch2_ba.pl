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
	print "Usage: perl ./generate_Fetch2_ba.pl -w <width> [-m] [-v] [-h]\n";
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
$outputFileName = "Fetch2.v";
$moduleName = "Fetch2";

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
# Purpose: This block implements Fetch2 for Block Ahead Fetch Unit. Fetch Width 
#	   is $width.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL

print <<LABEL;
module FetchStage2(	input clk,
	input reset,
	input flush_i,
	input stall_i,

	input f_trap_i,
	input f_recover_i,
	input [`SIZE_PC-1:0]recover_pc_i,

	/************************************** Inputs -> PC (from Fetch1aFetch1b)*********************************************************/
	input [`SIZE_PC-1:0]f1b_pc_i,
	input f1b_valid_pc_i,

	/************************************** Inputs -> PC (from Fetch1Fetch2)*********************************************************/
	input [`SIZE_PC-1:0]pc_i,
	input valid_pc_i,
	input [`INSTRUCTION_BUNDLE-1:0] instructionBundle_i,

	/************************************** Inputs -> BTB information (from Fetch1Fetch2)*********************************************************/
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

	input [`FIFO_SIZE-1:0]fifo_even_i,							/* Gives the FIFO information related to the index of the fetch block */
	input [`FIFO_SIZE-1:0]fifo_odd_i,

	/************************************** Inputs -> BP information (Fetch1Fetch2)*********************************************************/
LABEL
for($i=0; $i<$width; $i++)
{
	print "\tinput pred",$i,"_i,\n";
}
print <<LABEL;

	/************************************** Inputs -> BTB Hit Information (Fetch1Fetch2)*********************************************************/
	input btb_hit_i,
	input [`SIZE_PC-1:0]hit_target_i,
	input [`BRANCH_TYPE-1:0]hit_type_i,
	input [`FETCH_BANDWIDTH_LOG-1:0]hit_position_b_i,
	input hit_last_i,
	input pred_i,
	input [`TAG_TYPE_BITS-1:0]tag_type_i,
	input [`FETCH_BANDWIDTH_LOG-1:0]position_b_i,

	/************************************** Inputs -> Information about Earlier Block (from Decode)*********************************************************/
	input dec_valid_i,
	input [`SIZE_PC-1:0] dec_tag_pc_i,
	input [`BRANCH_TYPE-1:0]dec_br_type_i,
	input dec_btb_hit_i,
	input dec_br_dir_i,
	input dec_hit_l_i,
	input [`BRANCH_TYPE-1:0]dec_hit_t_i,
	input [`SIZE_PC-1:0]dec_hit_target_i,
	input [`FETCH_BANDWIDTH_LOG-1:0]dec_hit_b_i,
	input dec_old_br_dir_i,
	input dec_is_jalr_jr_i,
	input dec_is_ctrl_i,
	input [`FIFO_SIZE-1:0]dec_fifo_even_i,
	input [`FIFO_SIZE-1:0]dec_fifo_odd_i,

	/************************************** Inputs -> Information from SAS (from SAS)*********************************************************/
	input [`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:0]CP_pop_btb_entry_i,
	input CP_is_SAS_empty_i,

	/************************************** Inputs -> Information from RAS (from RAS)*********************************************************/
	input [`SIZE_PC-1:0]CP_pop_addr_i,
	input CP_is_RAS_empty_i,

	/**************** Following CTI Queue update comes from Execute unit when the Control instructions are resolved. ************************/
	input  [`SIZE_CTI_LOG-1:0] ctiQueueIndex_i,
	input  [`SIZE_PC-1:0] targetAddr_i,
	input  branchOutcome_i,
	input  flagRecoverEX_i,	
	input  ctrlVerified_i,
	input [`RETIRE_WIDTH-1:0] commitCti_i,	
	/************************************** Outputs -> Information to Decode (to Decode)*********************************************************/
	output valid_pc_o,
	output [`SIZE_PC-1:0]last_pc_o,
	output btb_hit_o,
	output [`BRANCH_TYPE-1:0]br_type_o,
	output br_dir_o,
	output hit_last_o,
	output [`BRANCH_TYPE-1:0]hit_type_o,
	output [`SIZE_PC-1:0]hit_target_o,
	output [`FETCH_BANDWIDTH_LOG-1:0]hit_position_b_o,
	output is_ctrl_o,
	output is_jalr_jr_o,
	output [`FIFO_SIZE-1:0]curr_fifo_even_o,
	output [`FIFO_SIZE-1:0]curr_fifo_odd_o,
	output old_br_dir_o,

	/************************************** Outputs -> Information to SAS (to SAS)*********************************************************/
	output [`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:0]CP_push_btb_entry_o,
	output CP_SAS_push_o,
	output CP_SAS_pop_o,

	/************************************** Outputs -> Information to RAS (to RAS)*********************************************************/
	output [`SIZE_PC-1:0]CP_push_addr_o,
	output CP_RAS_push_o,
	output CP_RAS_pop_o,

	/************************************** Outputs -> Information to Branch Predictor (to BP)*********************************************************/
	output [`SIZE_PC-1:0]bp_tag_pc_o,
	output bp_dir_o,
	output bp_update_o,

	/************************************** Outputs -> Wires (to Fetch1b)*********************************************************/
	output reg f2_valid_o,
	output reg [`FETCH_BANDWIDTH_LOG-1:0]f2_position_b_o,
	output reg [`TAG_TYPE_BITS-1:0]f2_tag_type_o,
	output reg f2_is_call_o,
	output reg f2_is_call_updated_o,
	output reg f2_is_return_updated_o,
	output [`SIZE_PC-1:0]f2_ras_top_addr_o,
	output f2_flush_pc_o,
	output [`SIZE_PC-1:0]f2_pc_o,
	output f2_flush_npc_o,
	output [`SIZE_PC-1:0]f2_npc_o,
	output reg f2_copy_stack_o,

	/************************************** Outputs -> update TO BTB (to BTB_4way_fifo)*********************************************************/
	output [`SIZE_PC-1:0] tag_pc_o,					/* Gives the PC which gives index and a part of tag */
	output [`TAG_TYPE_BITS-1:0] tag_type_o,			/* Gives the type of the direction giving the rest of tag (00 - Not Taken(N) 01 - Taken(T) 10 - Return(R))*/
	output [`SIZE_PC-1:0] target_o,					/* Target of the branch */
	output [`BRANCH_TYPE-1:0] type_o,				/* Ctrl Type of the Branch (00-Conditional 01-Jump 10-Call 11-Return)*/
	output [`FETCH_BANDWIDTH_LOG-1:0] position_b_o,	/* Position of branch in its fetch block */
	output last_o,									/* Last bit showing whehter the branch is the last branch in the fetch block */
	output [`FIFO_SIZE-1:0]fifo_even_o,				/* FIFO information as the last read from that index -> required to do direct write in a perticular way -> saves 1 read port*/
	output [`FIFO_SIZE-1:0]fifo_odd_o,
	output valid_o,									/* Shows whether there is an update or not */

	/************************************** Outputs -> Wires (to Fetch2Decode)*********************************************************/
	/* Maximum of 4 instructions can be filtered from the instruction bundle 
	and forwarded to next satge. 
	Follwing are instruction packet contents:
	(1) Instruction      : bits-`SIZE_INSTRUCTION+`2*`SIZE_PC+`SIZE_CTI_LOG:`2*SIZE_PC+`SIZE_CTI_LOG+1
	(2) Program Counter  : bits-2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1
	(3) Target Address   : bits-`SIZE_PC+`SIZE_CTI_LOG:`SIZE_CTI_LOG+1
	(4) Ctiq Tag         : bits-`SIZE_CTI_LOG:1
	(5) Branch Direction : bit-0
	*/
LABEL
for($i=0; $i<$width; $i++)
{
	print "\toutput instruction",$i,"Valid_o,\n";
	print "\toutput [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst",$i,"Packet_o,\n";
}
print <<LABEL;

	output ctiQueueFull_o    // If CTI Queue is full, further Inst fetching should be stalled
	);


reg f2_valid;
reg [`FETCH_BANDWIDTH_LOG-1:0]f2_position_b;
reg [`TAG_TYPE_BITS-1:0]f2_tag_type;
reg f2_is_call;
reg f2_is_call_updated;
reg f2_is_return_updated;
reg [`SIZE_PC-1:0]f2_ras_top_addr;
reg f2_pred;
reg f2_copy_stack;

reg [`FETCH_BANDWIDTH_LOG-1:0]curr_position_b;
reg [`BRANCH_TYPE-1:0]curr_br_type;
reg curr_last;
reg [`SIZE_PC-1:0]curr_target;
reg [`SIZE_PC-1:0]curr_br_pc;

LABEL
for($i=0; $i<$width; $i++)
{
	print "reg btb_hit",$i,";\n";
	print "reg [`SIZE_PC-1:0]target",$i,";\n";
	print "reg [`BRANCH_TYPE-1:0]type",$i,";\n";
	print "reg [`FETCH_BANDWIDTH_LOG-1:0]position_b",$i,";\n";
	print "reg last",$i,";\n\n";
}
print <<LABEL;
reg new_btb_hit;
reg [`SIZE_PC-1:0]new_target;
reg [`BRANCH_TYPE-1:0]new_type;
reg [`FETCH_BANDWIDTH_LOG-1:0]new_position_b;
reg new_last;

LABEL
for($i=0; $i<$width; $i++)
{
	print "reg btb_hit",$i,"_other;\n";
	print "reg [`SIZE_PC-1:0]target",$i,"_other;\n";
	print "reg [`BRANCH_TYPE-1:0]type",$i,"_other;\n";
	print "reg [`FETCH_BANDWIDTH_LOG-1:0]position_b",$i,"_other;\n";
	print "reg last",$i,"_other;\n\n";
}
print <<LABEL;
reg new_btb_hit_other;
reg [`SIZE_PC-1:0]new_target_other;
reg [`BRANCH_TYPE-1:0]new_type_other;
reg [`FETCH_BANDWIDTH_LOG-1:0]new_position_b_other;
reg new_last_other;

reg new_sas_hit;
reg [`SIZE_PC-1:0]new_sas_target;
reg [`BRANCH_TYPE-1:0]new_sas_type;
reg [`FETCH_BANDWIDTH_LOG-1:0]new_sas_position_b;
reg new_sas_last;

reg [`TAG_TYPE_BITS-1:0]prev_tag_type;
reg [`TAG_TYPE_BITS-1:0]new_tag_type;

reg new_br_dir;
reg is_ctrl_in_block;
reg is_jalr_jr;
reg [`FETCH_BANDWIDTH-1:0]filter_vector;

LABEL
for($i=0; $i<$width; $i++)
{
	print "wire [`SIZE_PC-1:0] pc",$i,";\n";
}
print "\n";
for($i=0; $i<$width; $i++)
{
	print "reg [`SIZE_INSTRUCTION-1:0] instruction",$i,";\n";
}
print "\n";
for($i=0; $i<$width; $i++)
{
	print "wire [`BRANCH_TYPE-1:0]ctrlType",$i,";\n";
	print "wire [`SIZE_PC-1:0]targetAddr",$i,";\n";
	print "wire isInst",$i,"Ctrl;\n";
	print "wire isInst",$i,"Ind;\n\n";
}

print <<LABEL;
reg [`TAG_TYPE_BITS-1:0]next_tag_type;

wire [`SIZE_PC-1:0]CP_pop_addr_final;
wire [`SIZE_PC-1:0]new_target_final;
wire [`SIZE_PC-1:0]ctiq_target;

LABEL
for($i=0; $i<$width; $i++)
{
	print "reg [`SIZE_PC-1:0]finalTarget",$i,";\n"
}

print <<LABEL;

wire [`SIZE_CTI_LOG-1:0]ctiqID;
wire [1+`SIZE_PC+1+`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1:0]ctiq_read_entry;
wire [1+`SIZE_PC+1+`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1+1+1-1:0]ctiq_head_entry;
wire [1+`SIZE_PC+1+`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1+1+1-1:0]ctiq_new_entry;
wire is_ctiq_full;
reg [`SIZE_PC-1:0]last_pc;

wire is_call_updated;
wire [`SIZE_PC-1:0]ras_top;
wire [`SIZE_PC-1:0]curr_final_target;

LABEL

for($i=0; $i<$width; $i++)
{
	print "assign pc",$i," = pc_i + ",$i*8,";\n"
}

print <<LABEL;

assign valid_pc_o = (~flagRecoverEX_i & ~flush_i & valid_pc_i&~stall_i) | f_recover_i;
assign last_pc_o = f_recover_i ? ctiq_read_entry[`SIZE_PC+1+`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1:1+`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1] : last_pc;
assign btb_hit_o = f_recover_i ? ctiq_read_entry[1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1] : new_btb_hit;
assign br_type_o = f_recover_i ? ctiq_read_entry[`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1:1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1] : curr_br_type;
assign br_dir_o = f_recover_i ? ctiq_read_entry[1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1] : new_br_dir;
assign hit_last_o = f_recover_i ? ctiq_read_entry[1+`FETCH_BANDWIDTH_LOG+1+1-1] : new_last;
assign hit_position_b_o = f_recover_i ? ctiq_read_entry[`FETCH_BANDWIDTH_LOG+1+1-1:1+1] : new_position_b;
assign hit_type_o = f_recover_i ? ctiq_read_entry[`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1:`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1] : new_type;
assign hit_target_o = f2_npc_o;
assign is_ctrl_o = f_recover_i ? 1'b1 : is_ctrl_in_block;
assign ctiQueueFull_o = is_ctiq_full;
assign is_jalr_jr_o = f_recover_i ? ctiq_read_entry[1+1-1] : is_jalr_jr;
assign curr_fifo_even_o = fifo_even_i;
assign curr_fifo_odd_o = fifo_odd_i;
assign old_br_dir_o = f_recover_i ? ~ctiq_read_entry[1+`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1] : dec_br_dir_i;

assign bp_tag_pc_o = ctiq_head_entry[`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1+1+1-1:1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1+1+1];
assign bp_dir_o = ctiq_head_entry[1];
assign bp_update_o = ctiq_head_entry[0] && ctiq_head_entry[`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1+1+1-1:1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1+1+1]==2'b00;

always @(*)
begin
LABEL

for($i=0; $i<$width; $i++)
{
	print "\tinstruction",$i,"  =  instructionBundle_i[",$i+1,"*`SIZE_INSTRUCTION-1:",$i,"*`SIZE_INSTRUCTION];\n";
}

print <<LABEL;
end

/* Instantiating predecode modules for each instruction in the fetch block. */
LABEL

for($i=0; $i<$width; $i++)
{
	print "\tPreDecode_PISA preDecode",$i,"( .pc_i(pc",$i,"),\n";
	print "\t.instruction_i(instruction",$i,"),\n";
	print "\t.isInstCtrl_o(isInst",$i,"Ctrl),\n";
	print "\t.isInstInd_o(isInst",$i,"Ind),\n";
	print "\t.targetAddr_o(targetAddr",$i,"),\n";
	print "\t.ctrlType_o(ctrlType",$i,")\n";
	print "\t);\n\n";
}

print <<LABEL;
/* Instantiating the Control Instruction Queue (CTIQ) */
CtrlQueue CtrlQ(	.clk(clk),
	.reset(reset|f_trap_i),
	.stall_i(stall_i),
	.flush_i(f_recover_i),
	.new_entry_i(ctiq_new_entry),
	.is_ctrl_resolved(ctrlVerified_i),
	.resolved_tag_i(ctiQueueIndex_i),
	.write_actual_dir_i(branchOutcome_i),
	.recover_EX_i(flagRecoverEX_i),
	.commitCti_i(commitCti_i),	
	.resolved_entry_o(ctiq_read_entry),
	.head_entry_o(ctiq_head_entry),
	.ctiq_entry_o(ctiqID),
	.is_CTIQ_full_o(is_ctiq_full)
	);

assign ctiq_new_entry = {is_ctrl_in_block,curr_br_pc,dec_br_dir_i,curr_br_type,new_btb_hit_other,new_target_other,new_type_other,dec_tag_pc_i,new_br_dir,is_call_updated,ras_top,new_last_other,new_position_b_other,is_jalr_jr,dec_btb_hit_i,1'b0,1'b0};

always@(*)
begin
	casex({btb_hit_i,valid_pc_i,f_recover_i})
	3'b000:	begin
		f2_valid_o = f2_valid;
		f2_position_b_o = f2_position_b;
		f2_tag_type_o = f2_tag_type;
		f2_is_call_o = f2_is_call;
		f2_is_call_updated_o = f2_is_call_updated;
		f2_is_return_updated_o = f2_is_return_updated;
		f2_copy_stack_o = f2_copy_stack;				
	end
	3'bxx1:	begin
		/* Put the Stuff from read from CTIQ for recovery*/
		f2_valid_o = 0;
		f2_position_b_o = 0;
		f2_tag_type_o = 0;
		f2_is_call_o = 0;
		f2_is_call_updated_o = 0;
		f2_is_return_updated_o = 0;
		f2_copy_stack_o = 0;								
	end
	3'b010:	begin
		f2_valid_o = 1'b1;
		f2_position_b_o = `FETCH_BANDWIDTH-1'b1;
		f2_tag_type_o = 0;
		f2_is_call_o = 0;
		f2_is_call_updated_o = 0;
		f2_is_return_updated_o = 0;
		f2_copy_stack_o = 0;					
	end
	3'b110:	begin
		case(hit_type_i)
		2'b00:	begin
			f2_valid_o = 1'b1;
			f2_position_b_o = hit_position_b_i;
			f2_tag_type_o = pred_i ? 2'b01 : 2'b00;
			f2_is_call_o = 0;
			f2_is_call_updated_o = 0;
			f2_is_return_updated_o = 0;
			f2_copy_stack_o = 0;
		end
		2'b01:	begin
			f2_valid_o = 1'b1;
			f2_position_b_o = hit_position_b_i;
			f2_tag_type_o = 2'b01;
			f2_is_call_o = 0;
			f2_is_call_updated_o = 0;
			f2_is_return_updated_o = 0;
			f2_copy_stack_o = 0;							
		end
		2'b10:	begin
			f2_valid_o = 1'b1;
			f2_position_b_o = hit_position_b_i;
			f2_tag_type_o = 2'b01;
			f2_is_call_o = 1'b1;
			f2_is_call_updated_o = 0;
			f2_is_return_updated_o = 0;
			f2_copy_stack_o = 0;							
		end
		2'b11:	begin
			f2_valid_o = 1'b1;
			f2_position_b_o = hit_position_b_i;
			f2_tag_type_o = 2'b10;
			f2_is_call_o = 1'b00;
			f2_is_call_updated_o = 0;
			f2_is_return_updated_o = 0;
			f2_copy_stack_o = 0;														
		end
		endcase
	end
	3'b100:	begin
		f2_valid_o = f2_valid;
		f2_position_b_o = f2_position_b;
		f2_tag_type_o = f2_tag_type;
		f2_is_call_o = f2_is_call;
		f2_is_call_updated_o = f2_is_call_updated;
		f2_is_return_updated_o = f2_is_return_updated;
		f2_copy_stack_o = f2_copy_stack;				
	end
	endcase
end

assign f2_ras_top_addr_o=f2_ras_top_addr;

always@(*)
begin
	casex({is_ctrl_in_block,curr_br_type})
	3'b0xx:	begin
		new_tag_type = 2'b00;
	end
	3'b100:	begin
		new_tag_type = dec_br_dir_i ? 2'b01 : 2'b00;
	end
	3'b101:	begin
		new_tag_type = 2'b01;
	end
	3'b110:	begin
		new_tag_type = 2'b01;
	end
	3'b111:	begin
		new_tag_type = 2'b10;
	end
	endcase
end

always@(*)
begin
	case(new_tag_type)
	2'b00:	begin
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t\tbtb_hit",$i," = btb_hit_N",$i,"_i;\n";
	print "\t\ttarget",$i," = target_N",$i,"_i;\n";
	print "\t\ttype",$i," = type_N",$i,"_i;\n";
	print "\t\tposition_b",$i," = position_b_N",$i,"_i;\n";
	print "\t\tlast",$i," = last_N",$i,"_i;\n";
}
for($i=0; $i<$width; $i++)
{
	print "\t\tbtb_hit",$i,"_other = btb_hit_T",$i,"_i;\n";
	print "\t\ttarget",$i,"_other = target_T",$i,"_i;\n";
	print "\t\ttype",$i,"_other = type_T",$i,"_i;\n";
	print "\t\tposition_b",$i,"_other = position_b_T",$i,"_i;\n";
	print "\t\tlast",$i,"_other = last_T",$i,"_i;\n";
}
print <<LABEL;
	end
	2'b01:	begin
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t\tbtb_hit",$i," = btb_hit_T",$i,"_i;\n";
	print "\t\ttarget",$i," = target_T",$i,"_i;\n";
	print "\t\ttype",$i," = type_T",$i,"_i;\n";
	print "\t\tposition_b",$i," = position_b_T",$i,"_i;\n";
	print "\t\tlast",$i," = last_T",$i,"_i;\n";
}
for($i=0; $i<$width; $i++)
{
	print "\t\tbtb_hit",$i,"_other = btb_hit_N",$i,"_i;\n";
	print "\t\ttarget",$i,"_other = target_N",$i,"_i;\n";
	print "\t\ttype",$i,"_other = type_N",$i,"_i;\n";
	print "\t\tposition_b",$i,"_other = position_b_N",$i,"_i;\n";
	print "\t\tlast",$i,"_other = last_N",$i,"_i;\n";
}
print <<LABEL;
	end
	2'b10:	begin
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t\tbtb_hit",$i," = CP_pop_btb_entry_i[0];\n";
	print "\t\ttarget",$i," = CP_pop_btb_entry_i[`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1];\n";
	print "\t\ttype",$i," = CP_pop_btb_entry_i[`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`FETCH_BANDWIDTH_LOG+1+1];\n";
	print "\t\tposition_b",$i," =  CP_pop_btb_entry_i[`FETCH_BANDWIDTH_LOG+1+1-1:1+1];\n";
	print "\t\tlast",$i," = CP_pop_btb_entry_i[1];\n";
}
for($i=0; $i<$width; $i++)
{
	print "\t\tbtb_hit",$i,"_other = CP_pop_btb_entry_i[0];\n";
	print "\t\ttarget",$i,"_other = CP_pop_btb_entry_i[`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1];\n";
	print "\t\ttype",$i,"_other = CP_pop_btb_entry_i[`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:`FETCH_BANDWIDTH_LOG+1+1];\n";
	print "\t\tposition_b",$i,"_other =  CP_pop_btb_entry_i[`FETCH_BANDWIDTH_LOG+1+1-1:1+1];\n";
	print "\t\tlast",$i,"_other = CP_pop_btb_entry_i[1];\n";
}
print <<LABEL;
	end
	2'b11:	begin
LABEL
for($i=0; $i<$width; $i++)
{
	print "\t\tbtb_hit",$i," = 0;\n";
	print "\t\ttarget",$i," = 0;\n";
	print "\t\ttype",$i," = 0;\n";
	print "\t\tposition_b",$i," = `FETCH_BANDWIDTH-1;\n";
	print "\t\tlast",$i," = 0;\n";
}
for($i=0; $i<$width; $i++)
{
	print "\t\tbtb_hit",$i,"_other = 0;\n";
	print "\t\ttarget",$i,"_other = 0;\n";
	print "\t\ttype",$i,"_other = 0;\n";
	print "\t\tposition_b",$i,"_other = `FETCH_BANDWIDTH-1;\n";
	print "\t\tlast",$i,"_other = 0;\n";
}
print <<LABEL;
	end
	endcase
end


always@(*)
begin
LABEL
print "\tcurr_position_b = ",log2($width),"'d",$width-1,";\n";
print "\tcurr_br_type = 0;\n";
print "\tnew_btb_hit = btb_hit",$width-1,";\n";
print "\tnew_target = (type",$width-1,"==2'b11) ?  CP_pop_addr_final : target",$width-1,";\n";
print "\tnew_type = type",$width-1,";\n";
print "\tnew_position_b = position_b",$width-1,";\n";
print "\tnew_last = last",$width-1,";\n";
print "\tnew_btb_hit_other = btb_hit",$width-1,";\n";
print "\tnew_target_other = new_target;\n";
print "\tnew_type_other = type",$width-1,";\n";
print "\tnew_position_b_other = position_b",$width-1,";\n";
print "\tnew_last_other = last",$width-1,";\n";
print "\tnew_sas_hit = btb_hit_R",$width-1,"_i;\n";
print "\tnew_sas_target = target_R",$width-1,"_i;\n";
print "\tnew_sas_type = type_R",$width-1,"_i;\n";
print "\tnew_sas_position_b = position_b_R",$width-1,"_i;\n";
print "\tnew_sas_last = last_R",$width-1,"_i;\n";
print "\tis_ctrl_in_block = 1'b0;\n";
print "\tnew_br_dir = pred",$width-1,"_i;\n";
print "\tcurr_last = 1'b0;\n";
print "\tis_jalr_jr = 0;\n";
print "\tcurr_target = pc_i + ",$width*8,";\n";
print "\tcurr_br_pc = pc",$width-1,";\n";
print "\tlast_pc = pc",$width-1,";\n";
print "\tfilter_vector = ",$width,"'d",2**$width-1,";\n";
print "\tcasex({";
for($i=0; $i<$width; $i++)
{
	print "isInst",$i,"Ctrl";
	if($i<$width-1)
	{
		print ",";
	}
}
print "})\n";

for($i=0; $i<$width; $i++)
{
	print "\t",$width,"'b";
	for($j=0; $j<$width; $j++)
	{
		if($j>$i)
		{
			print "x";
		} 
		elsif($i==$j)
		{
			print "1";
		}
		else
		{
			print "0";
		}
	}
	print ": begin\n";
	print "\t\tcurr_position_b = ",log2($width),"'d",$i,";\n";
	print "\t\tcurr_br_type = ctrlType",$i,";\n";
	print "\t\tnew_btb_hit = btb_hit",$i,";\n";
	print "\t\tnew_target = (type",$i,"==2'b11) ?  CP_pop_addr_final : target",$i,";\n";
	print "\t\tnew_type = type",$i,";\n";
	print "\t\tnew_position_b = position_b",$i,";\n";
	print "\t\tnew_last = last",$i,";\n";
	print "\t\tnew_btb_hit_other = (ctrlType",$i,"==2'b00) ? btb_hit",$i,"_other : (isInst",$i,"Ind ? 0 : btb_hit",$i,");\n";
	print "\t\tnew_target_other = (ctrlType",$i,"==2'b00) ? target",$i,"_other : (isInst",$i,"Ind ? 0 : new_target);\n";
	print "\t\tnew_type_other = (ctrlType",$i,"==2'b00) ? type",$i,"_other : (isInst",$i,"Ind ? 0 : type",$i,");\n";
	print "\t\tnew_position_b_other = (ctrlType",$i,"==2'b00) ? position_b",$i,"_other : (isInst",$i,"Ind ? `FETCH_BANDWIDTH-1 : position_b",$i,");\n";
	print "\t\tnew_last_other = (ctrlType",$i,"==2'b00) ? last",$i,"_other : (isInst",$i,"Ind ? 0 : last",$i,");\n";
	print "\t\tnew_sas_hit = btb_hit_R",$i,"_i;\n";
	print "\t\tnew_sas_target = target_R",$i,"_i;\n";
	print "\t\tnew_sas_type = type_R",$i,"_i;\n";
	print "\t\tnew_sas_position_b = position_b_R",$i,"_i;\n";
	print "\t\tnew_sas_last = last_R",$i,"_i;\n";
	print "\t\tis_ctrl_in_block = 1'b1;\n";
	if($i<$width-1)
	{
		print "\t\tcurr_last = (ctrlType",$i," == 2'b00) ? ~(";
		for($j=$i+1; $j<$width; $j++)
		{
			print "isInst",$j,"Ctrl";
			if($j<$width-1)
			{
				print " || ";
			}
		}
		print ") : 1'b0;\n";
	}
	else
	{
		print "\t\tcurr_last = (ctrlType",$i," == 2'b00) ? 1'b1 : 1'b0;\n";
	}
	print "\t\tis_jalr_jr = isInst",$i,"Ind;\n";
	print "\t\tcurr_target = (ctrlType",$i," == 2'b11) ? CP_pop_addr_final : targetAddr",$i,";\n";
	print "\t\tcurr_br_pc = pc",$i,";\n";
	print "\t\tnew_br_dir = pred",$i,"_i;\n";
	print "\t\tlast_pc = pc",$i,";\n";
	if($i<$width)
	{
		print "\t\tif(curr_br_type == 2'b00 & curr_last & ~dec_br_dir_i)\n";
		print "\t\t\tfilter_vector = ",$width,"'d",2**$width-1,";\n";
		print "\t\telse\n";
		print "\t\t\tfilter_vector = ",$width,"'d",2**$width - 2**($width-$i-1),";\n";
	}
	print "\tend\n";
}
print <<LABEL;
endcase
end

always@(*)
begin
	casex({dec_is_ctrl_i,dec_br_type_i})
	3'b0xx:	begin
		prev_tag_type = 2'b00;
	end
	3'b100:	begin
		prev_tag_type = dec_old_br_dir_i ? 2'b01 : 2'b00;
	end
	3'b101:	begin
		prev_tag_type = 2'b01;
	end
	3'b110:	begin
		prev_tag_type = 2'b01;
	end
	3'b111:	begin
		prev_tag_type = 2'b10;
	end
	endcase
end

assign tag_pc_o		= prev_tag_type==2'b10 ? pc_i - 8 : dec_tag_pc_i;
assign tag_type_o	= prev_tag_type;
assign target_o		= curr_target;
assign type_o		= curr_br_type;
assign position_b_o	= curr_position_b;
assign last_o		= curr_last;
assign fifo_even_o	= dec_fifo_even_i;
assign fifo_odd_o	= dec_fifo_odd_i;
assign valid_o		= ~dec_btb_hit_i & is_ctrl_in_block & valid_pc_i & dec_valid_i & ~flush_i;

LABEL
print "assign CP_pop_addr_final = (CP_pop_addr_i==0) ? pc_i+",$width*8," : CP_pop_addr_i;\n";

for($i=0; $i<$width; $i++)
{
print <<LABEL;
always@(*)
begin
LABEL
	print "\tcasex({isInst",$i,"Ctrl,ctrlType",$i,"})\n";
	print "\t3'b0xx:	begin\n";
	print "\t\tfinalTarget",$i," = pc",$i,"+8;\n";
	print "\tend\n";
	print "\t3'b100:	begin\n";
	print "\t\tfinalTarget",$i," = dec_br_dir_i ? targetAddr",$i," : pc",$i,"+8;\n";
	print "\tend\n";
	print "\t3'b101:	begin\n";
	print "\t\tfinalTarget",$i," = targetAddr",$i,";\n";
	print "\tend\n";
	print "\t3'b110:	begin\n";
	print "\t\tfinalTarget",$i," = targetAddr",$i,";\n";
	print "\tend\n";
	print "\t3'b111:	begin\n";
	print "\t\tfinalTarget",$i," = CP_pop_addr_final;\n";
	print "\tend\n";
print <<LABEL;
	endcase
end

LABEL
}

print <<LABEL;

/* Following filters instructions  */
LABEL
for($i=0; $i<$width; $i++)
{
	print "assign inst",$i,"Packet_o         = {instruction",$i,",pc",$i,",finalTarget",$i,",ctiqID,dec_br_dir_i};\n";
	print "assign instruction",$i,"Valid_o   = filter_vector[",$width-$i-1,"]&valid_pc_i&~flagRecoverEX_i&~stall_i;\n\n"; 
}

print <<LABEL;
assign CP_push_addr_o	= curr_br_pc;
assign CP_RAS_push_o	= (curr_br_type == 2'b10) ? 1'b1 : 1'b0;
assign CP_SAS_push_o	= (curr_br_type == 2'b10) ? 1'b1 : 1'b0;
assign CP_push_btb_entry_o = {new_sas_target,new_sas_type,new_sas_position_b,new_sas_last,new_sas_hit};
assign CP_RAS_pop_o = (curr_br_type == 2'b11) ? 1'b1 : 1'b0;
assign CP_SAS_pop_o = (curr_br_type == 2'b11) ? 1'b1 : 1'b0;

always@(posedge clk)
begin
	if(reset|f_trap_i)
	begin
		f2_valid <= 0;
		f2_position_b <= `FETCH_BANDWIDTH-1'b1;
		f2_tag_type <= 0;
		f2_is_call <= 0;
		f2_is_call_updated <= 0;
		f2_is_return_updated <= 0;
		f2_ras_top_addr <= 0;
		f2_copy_stack <= 0;	
	end
	else if((valid_pc_i & ~stall_i)|f_recover_i)
	begin
		f2_valid <= 1'b1;
		f2_position_b <= f_recover_i ? ctiq_read_entry[`FETCH_BANDWIDTH_LOG+1+1-1:1+1] : new_position_b;
		f2_tag_type <= f_recover_i ? {1'b0,~(ctiq_read_entry[`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1:`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1]==2'b00 && ~ctiq_read_entry[1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1]) && ctiq_read_entry[1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1]} : next_tag_type;
		f2_is_call <= f_recover_i ? 1'b0 : ((new_type==2'b10) ? 1'b1 : 1'b0);
		f2_is_call_updated <= f_recover_i ? ctiq_read_entry[1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1:`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1] : (~(hit_type_i==2'b10) & (new_type==2'b10));
		f2_is_return_updated <= f_recover_i ? 1'b0 : (~(hit_type_i==2'b11) & (new_type==2'b11)) | (f2_flush_pc_o & btb_hit_o & hit_type_o==2'b11);
		f2_ras_top_addr <= f_recover_i ? ctiq_read_entry[`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1:1+`FETCH_BANDWIDTH_LOG+1+1] : curr_final_target+(new_position_b<<3);
		f2_copy_stack <= f_recover_i ? 1'b0 : f2_flush_pc_o;
	end				
end

assign ras_top = (curr_br_type == 2'b00 && dec_br_dir_i) ? curr_br_pc + ((new_position_b_other+1'b1)<<3) : curr_target+(new_position_b_other<<3);
assign is_call_updated = (new_type_other==2'b10);
LABEL

print "assign curr_final_target = (curr_br_type==2'b00 && ~dec_br_dir_i) ? (curr_last) ? pc_i + ",$width*8," : curr_br_pc + 8 : curr_target;\n";
print "assign new_target_final = (new_type==2'b00 && ~new_br_dir) ? ((new_last) ? curr_final_target+ ",$width*8," : curr_final_target+((new_position_b+1'b1)<<3)) : new_target;\n";

print <<LABEL;

always@(*)
begin
	next_tag_type = 2'b00;
	casex({new_btb_hit,new_type})
	3'b0xx:	begin
		next_tag_type = 2'b00;
	end
	3'b100:	begin
		next_tag_type = new_br_dir ? 2'b01 : 2'b00;
	end
	3'b101:	begin
		next_tag_type = 2'b01;
	end
	3'b110:	begin
		next_tag_type = 2'b01;
	end
	3'b111:	begin
		next_tag_type = 2'b10;
	end
	endcase
end

LABEL


print "assign ctiq_target = (ctiq_read_entry[`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1:`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1]==2'b00 && ~ctiq_read_entry[1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1]) ? ((ctiq_read_entry[1+`FETCH_BANDWIDTH_LOG+1+1-1]) ? recover_pc_i+ ",$width*8," : recover_pc_i+((ctiq_read_entry[`FETCH_BANDWIDTH_LOG+1+1-1:1+1]+1'b1)<<3)) : ctiq_read_entry[`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1:`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1];\n";

print <<LABEL;

assign f2_flush_pc_o = 	f_recover_i|flagRecoverEX_i | 
		(~stall_i & valid_pc_i & ~dec_valid_i & is_ctrl_in_block) | 
		(~stall_i & valid_pc_i  & dec_valid_i & dec_btb_hit_i & ~is_ctrl_in_block) | 
		(~stall_i & valid_pc_i  & dec_valid_i & is_ctrl_in_block & ~dec_btb_hit_i & ~(curr_br_type==2'b00 & ~dec_br_dir_i & curr_last & curr_position_b==position_b_i)) | 
		(~stall_i & valid_pc_i & dec_valid_i & dec_btb_hit_i & is_ctrl_in_block & ~((dec_hit_b_i==curr_position_b) & (dec_hit_t_i==curr_br_type) & (dec_hit_l_i==curr_last) & (dec_hit_target_i== curr_final_target)));

assign f2_pc_o = f_recover_i ? recover_pc_i : curr_final_target;
assign f2_flush_npc_o = f2_flush_pc_o & ((~f_recover_i & new_btb_hit) | (f_recover_i & ctiq_read_entry[1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1]));
assign f2_npc_o = f_recover_i ? ctiq_target : new_target_final;

endmodule

LABEL

