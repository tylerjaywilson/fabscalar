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
# Purpose: This script creates top level FABSCALAR.v file.
################################################################################

my $version = "1.7"; # Make this 2.0 when retireWidths are supported fully.

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 8;

my $fetchWidth;
my $decodeWidth;
my $dispatchWidth;
my $issueWidth;
my $retireWidth;
my $supportBA = 0;

my $typesOfFUs = 4; # HARDWIRED!
my @fuNo;   # Number of execute ways of each instruction type (they are always adjacent)
my @whereFU;  # A two dimensional array with 4 rows (for each instruction type), telling which ways support that type.

my $printHeader = 0;

my $i;
my $j;
my $comma;
my $temp;
my $temp2;
my $tempCount;
my $tempStr;
my @tempArr;

sub fatalUsage
{
	print "\n";
	print "Usage: perl $scriptName -f <fetch_width> -d <dispatch_width> -n A B C D -r <retire_width> [-ba] [-m] [-v] [-h]\n";
	print "\t-n: Number of instructions of type 1 (A), type 2 (B), type 3 (C), type 4 (D)\n";
	print "\t-ba: Supports Block Ahead Fetch Unit\n";
	print "\t-m: Add header\n";
	print "\t-v: Print version and exit\n";
	print "\t-h: Show usage help and exit\n";
	exit;
}

sub log2 
{
	my $n = shift;
	return(log($n)/log(2));
}

### START HERE ###

$scriptName = $0;

my $essentialCLIArgs = 0;
while(@ARGV)
{
	$_ = shift;
	if(/^-n$/) 
	{
		for($i=0; $i<$typesOfFUs; $i++)
		{
			$fuNo[$i] = shift;
			$essentialCLIArgs++;
		}
	}	
	elsif(/^-f$/)
	{
		$fetchWidth = shift;
		$essentialCLIArgs++;
	}	
	elsif(/^-dc$/)
	{
		$decodeWidth = shift;
		$essentialCLIArgs++;
	}	
	elsif(/^-d$/)
	{
		$dispatchWidth = shift;
		$essentialCLIArgs++;
	}	
	elsif(/^-r$/)
	{
		$retireWidth = shift;
		$essentialCLIArgs++;
	}	
	elsif(/^-m$/)
	{
		$printHeader = 1;
	}	
	elsif(/^-ba$/)
	{
		$supportBA = 1;
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
		print "\nError: Unrecognized argument $_.\n";
		&fatalUsage();
	}
}

if($essentialCLIArgs < $minEssentialCLIArgs)
{
	print "\nError: Too few inputs\n";
	&fatalUsage();
}

# Check retire width
if($retireWidth != 4)
{
	print "Retire widths other than 4 not supported now\n";
	die;
}

$issueWidth = 0;
foreach (@fuNo)
{
	$issueWidth += $_;
}

if($#fuNo+1 != $typesOfFUs)
{
	print "\nError: Exactly $typesOfFUs types of FUs are to be present.\n";
}

# initialize @whereFU
$temp = 0;
$tempCount = 0;
foreach(@fuNo)
{
	@tempArr = ();
	for($i=0; $i<$_; $i++)
	{
		push(@tempArr, $tempCount);
		$tempCount++;
	}
	push(@whereFU, [ @tempArr ]);
	
	$temp++;
}

# Create module name
$outputFileName = "FABSCALAR.v";
$moduleName = "FABSCALAR";

# Check for FABSCALAR.v

for($i=1; $i<$typesOfFUs; $i++)
{
	if($fuNo[$i] != 1)
	{
		die "FABSCALAR.v not implemented for FU type $i with more than one way.\n";
	}
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
# Purpose: This module is top level block where all the pipeline stages are
#	   integrated.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps
LABEL

print <<LABEL;

module FABSCALAR(  input clock,
                   input reset,
                   input wrL1ICacheEnable_i,
                   input [`SIZE_PC-1:0] wrAddrL1ICache_i,
                   input [`CACHE_WIDTH-1:0]   wrBlockL1ICache_i,
                   output missL1ICache_o,
                   output [`SIZE_PC-1:0] missAddrL1ICache_o
		);
LABEL

print <<LABEL;
/*****************************Wire Declaration**********************************/
// Wires from Interface module
wire wrL1ICacheEnable_l1;
wire [`SIZE_PC-1:0] wrAddrL1ICache_l1;
wire [`CACHE_WIDTH-1:0] wrBlockL1ICache_l1;
LABEL
if ($supportBA)
{
	print <<LABEL;
	//Wires from Fetch1a
	wire [`SIZE_PC-1:0] pc;

	//Wires from BTB
LABEL
	for($i=0; $i<$fetchWidth; $i++)
	{
		print "wire btb_hit_N",$i,";\n";						
		print "wire [`SIZE_PC-1:0]target_N",$i,";\n";					
		print "wire [`BRANCH_TYPE-1:0]type_N",$i,";\n";					
		print "wire [`FETCH_BANDWIDTH_LOG-1:0]position_b_N",$i,";\n";	
		print "wire last_N",$i,";\n";										
	}
	for($i=0; $i<$fetchWidth; $i++)
	{
		print "wire btb_hit_T",$i,";\n";						
		print "wire [`SIZE_PC-1:0]target_T",$i,";\n";					
		print "wire [`BRANCH_TYPE-1:0]type_T",$i,";\n";					
		print "wire [`FETCH_BANDWIDTH_LOG-1:0]position_b_T",$i,";\n";	
		print "wire last_T",$i,";\n";										
	}
	for($i=0; $i<$fetchWidth; $i++)
	{
		print "wire btb_hit_R",$i,";\n";						
		print "wire [`SIZE_PC-1:0]target_R",$i,";\n";					
		print "wire [`BRANCH_TYPE-1:0]type_R",$i,";\n";					
		print "wire [`FETCH_BANDWIDTH_LOG-1:0]position_b_R",$i,";\n";	
		print "wire last_R",$i,";\n";										
	}
	print <<LABEL;
	wire [`FIFO_SIZE-1:0]fifo_even;							
	wire [`FIFO_SIZE-1:0]fifo_odd;
	
	
	//Wires from BranchPrediction
LABEL
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print "wire pred",$i,";\n";
	}
	
	print <<LABEL;
	

	//Wires from Fetch1aFetch1b
	wire [`SIZE_PC-1:0]pc_f1a1b;
	wire valid_pc_f1a1b;
	
	
	
	
	
	//Wires from RAS
	wire [`SIZE_PC-1:0]pop_addr;
	wire is_empty_RAS;
	wire [`SIZE_PC-1:0]CP_pop_addr;
	wire CP_is_empty_RAS;
	
	
	
	//Wires from SAS
	wire [`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:0]pop_btb_entry;
	wire is_empty_SAS;
	wire [`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:0]CP_pop_btb_entry;
	wire CP_is_empty_SAS;						
	
	
	
	//Wires from Fetch1b
	wire [`SIZE_PC-1:0]pc_f1b;
	wire valid_pc_f1b;
LABEL
	for($i=0; $i<$fetchWidth; $i++)
	{
		print "wire btb_hit_N",$i,"_f1b;\n";						
		print "wire [`SIZE_PC-1:0]target_N",$i,"_f1b;\n";					
		print "wire [`BRANCH_TYPE-1:0]type_N",$i,"_f1b;\n";					
		print "wire [`FETCH_BANDWIDTH_LOG-1:0]position_b_N",$i,"_f1b;\n";	
		print "wire last_N",$i,"_f1b;\n";										
	}
	for($i=0; $i<$fetchWidth; $i++)
	{
		print "wire btb_hit_T",$i,"_f1b;\n";						
		print "wire [`SIZE_PC-1:0]target_T",$i,"_f1b;\n";					
		print "wire [`BRANCH_TYPE-1:0]type_T",$i,"_f1b;\n";					
		print "wire [`FETCH_BANDWIDTH_LOG-1:0]position_b_T",$i,"_f1b;\n";	
		print "wire last_T",$i,"_f1b;\n";										
	}
	for($i=0; $i<$fetchWidth; $i++)
	{
		print "wire btb_hit_R",$i,"_f1b;\n";						
		print "wire [`SIZE_PC-1:0]target_R",$i,"_f1b;\n";					
		print "wire [`BRANCH_TYPE-1:0]type_R",$i,"_f1b;\n";					
		print "wire [`FETCH_BANDWIDTH_LOG-1:0]position_b_R",$i,"_f1b;\n";	
		print "wire last_R",$i,"_f1b;\n";										
	}
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print "wire pred",$i,"_f1b;\n";
	}
	print <<LABEL;
	wire[`SIZE_PC-1:0] next_pc;
	wire [`SIZE_PC-1:0]push_addr;
	wire copy_stack;
	wire push_RAS;
	wire pop_RAS;
	wire [`SIZE_PC-1:0]ras_top_addr;
	wire update_ras_top;
	wire [`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:0]push_btb_entry;
	wire push_SAS;
	wire pop_SAS;
	wire btb_hit;
	wire [`SIZE_PC-1:0]hit_target;
	wire [`BRANCH_TYPE-1:0]hit_type;
	wire [`FETCH_BANDWIDTH_LOG-1:0]hit_position_b;
	wire hit_last;
	wire pred;
	wire [`TAG_TYPE_BITS-1:0]tag_type;
	wire [`FETCH_BANDWIDTH_LOG-1:0]position_b;
	
	
	//Wires from L1Cache
	wire [`INSTRUCTION_BUNDLE-1:0] instBundle;	
	wire miss;									  
	wire [`SIZE_PC-1:0] missAddr;	
	
	//Wires from Fetch1Fetch2
	wire [`INSTRUCTION_BUNDLE-1:0] instructionBundle;
	wire [`SIZE_PC-1:0]pc_f12;
	wire valid_pc_f12;
LABEL
	for($i=0; $i<$fetchWidth; $i++)
	{
		print "wire btb_hit_N",$i,"_f12;\n";						
		print "wire [`SIZE_PC-1:0]target_N",$i,"_f12;\n";					
		print "wire [`BRANCH_TYPE-1:0]type_N",$i,"_f12;\n";					
		print "wire [`FETCH_BANDWIDTH_LOG-1:0]position_b_N",$i,"_f12;\n";	
		print "wire last_N",$i,"_f12;\n";										
	}
	for($i=0; $i<$fetchWidth; $i++)
	{
		print "wire btb_hit_T",$i,"_f12;\n";						
		print "wire [`SIZE_PC-1:0]target_T",$i,"_f12;\n";					
		print "wire [`BRANCH_TYPE-1:0]type_T",$i,"_f12;\n";					
		print "wire [`FETCH_BANDWIDTH_LOG-1:0]position_b_T",$i,"_f12;\n";	
		print "wire last_T",$i,"_f12;\n";										
	}
	for($i=0; $i<$fetchWidth; $i++)
	{
		print "wire btb_hit_R",$i,"_f12;\n";						
		print "wire [`SIZE_PC-1:0]target_R",$i,"_f12;\n";					
		print "wire [`BRANCH_TYPE-1:0]type_R",$i,"_f12;\n";					
		print "wire [`FETCH_BANDWIDTH_LOG-1:0]position_b_R",$i,"_f12;\n";	
		print "wire last_R",$i,"_f12;\n";										
	}
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print "wire pred",$i,"_f12;\n";
	}
	print <<LABEL;
	wire btb_hit_f12;
	wire [`SIZE_PC-1:0]hit_target_f12;
	wire [`BRANCH_TYPE-1:0]hit_type_f12;
	wire [`FETCH_BANDWIDTH_LOG-1:0]hit_position_b_f12;
	wire hit_last_f12;
	wire pred_f12;
	wire [`TAG_TYPE_BITS-1:0]tag_type_f12;
	wire [`FETCH_BANDWIDTH_LOG-1:0]position_b_f12;
	
	//Wires from Fetch2
	wire valid_pc_f2;
	wire [`SIZE_PC-1:0]last_pc_f2;
	wire btb_hit_f2;
	wire [`BRANCH_TYPE-1:0]br_type_f2;
	wire br_dir_f2;
	wire hit_last_f2;
	wire [`BRANCH_TYPE-1:0]hit_type_f2;
	wire [`SIZE_PC-1:0]hit_target_f2;
	wire [`FETCH_BANDWIDTH_LOG-1:0]hit_position_b_f2;
	wire is_ctrl_f2;
	wire is_jalr_jr_f2;
	wire [`FIFO_SIZE-1:0]curr_fifo_even_f2;
	wire [`FIFO_SIZE-1:0]curr_fifo_odd_f2;
	wire [`SIZE_PC+`BRANCH_TYPE+`FETCH_BANDWIDTH_LOG+1+1-1:0]CP_push_btb_entry;
	wire CP_SAS_push;
	wire CP_SAS_pop;
	wire [`SIZE_PC-1:0]CP_push_addr;
	wire CP_RAS_push;
	wire CP_RAS_pop;
	wire [`SIZE_PC-1:0]bp_tag_pc;
	wire bp_dir;
	wire bp_update;
	wire f2_valid;
	wire [`FETCH_BANDWIDTH_LOG-1:0]f2_position_b;
	wire [`TAG_TYPE_BITS-1:0]f2_tag_type;
	wire f2_is_call;
	wire f2_is_call_updated;
	wire f2_is_return_updated;
	wire [`SIZE_PC-1:0]f2_ras_top_addr;
	wire f2_flush_pc;
	wire [`SIZE_PC-1:0]f2_pc;
	wire f2_flush_npc;
	wire [`SIZE_PC-1:0]f2_npc;
	wire f2_copy_stack;
	wire [`SIZE_PC-1:0] tag_pc_f2;					
	wire [`TAG_TYPE_BITS-1:0] tag_type_f2;			
	wire [`SIZE_PC-1:0] target_f2;					
	wire [`BRANCH_TYPE-1:0] type_f2;				
	wire [`FETCH_BANDWIDTH_LOG-1:0] position_b_f2;	
	wire last_f2;									
	wire [`FIFO_SIZE-1:0]fifo_even_f2;				
	wire [`FIFO_SIZE-1:0]fifo_odd_f2;
	wire old_br_dir_f2;
	wire valid_f2;									
LABEL
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print "wire instruction",$i,"Valid;\n";
		print "wire [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst",$i,"Packet;\n";
	}
	print <<LABEL;
	wire ctiQueueFull;
	
	// Wires from Fetch2Decode module
	wire valid_pc_f2d;
	wire [`SIZE_PC-1:0]last_pc_f2d;
	wire btb_hit_f2d;
	wire [`BRANCH_TYPE-1:0]br_type_f2d;
	wire br_dir_f2d;
	wire hit_last_f2d;
	wire [`BRANCH_TYPE-1:0]hit_type_f2d;
	wire [`SIZE_PC-1:0]hit_target_f2d;
	wire [`FETCH_BANDWIDTH_LOG-1:0]hit_position_b_f2d;
	wire is_ctrl_f2d;
	wire is_jalr_jr_f2d;
	wire [`FIFO_SIZE-1:0]curr_fifo_even_f2d;
	wire [`FIFO_SIZE-1:0]curr_fifo_odd_f2d;
	wire old_br_dir_f2d;						
	wire [`SIZE_PC-1:0]bp_tag_pc_f2d;
	wire bp_dir_f2d;
	wire bp_update_f2d;
LABEL
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print "wire instruction",$i,"Valid_f2d;\n";
		print "wire [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst",$i,"Packet_f2d;\n";
	}
	print <<LABEL;
	wire [`SIZE_PC-1:0] tag_pc_f2d;		
	wire [`TAG_TYPE_BITS-1:0] tag_type_f2d;	
	wire [`SIZE_PC-1:0] target_f2d;	
	wire [`BRANCH_TYPE-1:0] type_f2d;
	wire [`FETCH_BANDWIDTH_LOG-1:0] position_b_f2d;
	wire last_f2d;
	wire [`FIFO_SIZE-1:0]fifo_even_f2d;	
	wire[`FIFO_SIZE-1:0]fifo_odd_f2d;
	wire valid_f2d;
	
	
	// Wires from Decode module
	wire decodeReady;
	wire [2*`FETCH_BANDWIDTH-1:0] decodedVector;
LABEL
	for($i=0; $i<2*$fetchWidth; $i++)
	{
	print <<LABEL;
	wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket${i};
LABEL
	}
	print <<LABEL;
	wire dec_valid;
	wire [`SIZE_PC-1:0]dec_tag_pc;
	wire [`BRANCH_TYPE-1:0]dec_br_type;
	wire dec_btb_hit;
	wire dec_br_dir;
	wire dec_hit_l;
	wire [`BRANCH_TYPE-1:0]dec_hit_t;
	wire [`SIZE_PC-1:0]dec_hit_target;
	wire [`FETCH_BANDWIDTH_LOG-1:0]dec_hit_b;
	wire dec_old_br_dir;
	wire dec_is_jalr_jr;
	wire dec_is_ctrl;
	wire [`FIFO_SIZE-1:0]dec_fifo_even;
	wire [`FIFO_SIZE-1:0]dec_fifo_odd;					
	
LABEL
	
}
else
{
	print <<LABEL;
	// Wires from FetchStage1 module
	wire missL1ICache;
	wire [`SIZE_PC-1:0] missAddrL1ICache;

	wire fs1Ready;
	wire [`INSTRUCTION_BUNDLE-1:0] instructionBundle;
	wire [`SIZE_PC-1:0] pc;
	wire [`SIZE_PC-1:0] addrRAS_CP;
	wire startBlock;  
	wire [1:0] firstInst;
LABEL

	for($i=0; $i<$fetchWidth; $i++)
	{
		print <<LABEL;
	wire btbHit$i;
	wire [`SIZE_PC-1:0] targetAddr$i;
	wire prediction$i;
LABEL
	}
	print "\n";

	print <<LABEL;
	// Wires from Fetch1Fetch2 module
	wire fs1Ready_l1;
	wire [`INSTRUCTION_BUNDLE-1:0] instructionBundle_l1;
	wire [`SIZE_PC-1:0] pc_l1;
	wire startBlock_l1;
	wire [1:0] firstInst_l1;
LABEL

	for($i=0; $i<$fetchWidth; $i++)
	{
		print <<LABEL;
	wire btbHit${i}_l1;
	wire [`SIZE_PC-1:0] targetAddr${i}_l1;
	wire prediction${i}_l1;
LABEL
	}
	print "\n";

	print <<LABEL;
	// Wires from FetchStage2 module
	wire flagRecoverID;
	wire [`SIZE_PC-1:0] targetAddrID;
	wire flagRtrID;
	wire flagCallID;
	wire [`SIZE_PC-1:0] callPCID;
	wire [`SIZE_PC-1:0] updatePC;
	wire [`SIZE_PC-1:0] updateTargetAddr;
	wire [`BRANCH_TYPE-1:0] updateCtrlType;
	wire updateDir;
	wire updateEn;
LABEL

	for($i=0; $i<$fetchWidth; $i++)
	{
		print <<LABEL;
	wire instruction${i}Valid;
	wire [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst${i}Packet;
LABEL
	}

	print <<LABEL;
	wire fs2Ready;
	wire ctiQueueFull;


	// Wires from Fetch2Decode module
	wire [`SIZE_PC-1:0] updatePC_l1;
	wire [`SIZE_PC-1:0] updateTargetAddr_l1;
	wire [`BRANCH_TYPE-1:0] updateCtrlType_l1;
	wire updateDir_l1;
	wire updateEn_l1;
	wire fs2Ready_l1;
LABEL

	for($i=0; $i<$fetchWidth; $i++)
	{
		print <<LABEL;
	wire instruction${i}Valid_l1;
	wire [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst${i}Packet_l1;
LABEL
	}
	print "\n";

	print <<LABEL;
	// Wires from Decode module
	wire decodeReady;
	wire [2*`FETCH_BANDWIDTH-1:0] decodedVector;
LABEL


	for($i=0; $i<2*$fetchWidth; $i++)
	{
		print <<LABEL;
	wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket${i};
LABEL
	}
	print "\n";
}
print <<LABEL;
// Wires from Instruction Buffer module
wire instBufferFull;
wire instBufferReady;
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket${i}_l1;
LABEL
}

print <<LABEL;
wire [`BRANCH_COUNT-1:0] branchCount;


// Wires from InstBufRename
wire instBufferReady_l1;
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket${i}_l2;
LABEL
}

print <<LABEL;
wire [`BRANCH_COUNT-1:0] branchCount_l1;


// Wires from Rename module
wire noFreeSMT;
wire freeListEmpty;
wire renameReady;
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] renamedPacket${i};
LABEL
}
print "\n";

print <<LABEL;
// Wires from RenameDispatch module
wire renameReady_l1;
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] renamedPacket${i}_l1;
LABEL
}
print "\n";

print <<LABEL;
//wires from Dispatch module
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] dispatchPacket${i};
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
wire [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] dispatchPacket${i}_al;
LABEL
}
print "\n";

print <<LABEL;
wire backEndReady;
wire stallfrontEnd;


//wires from Dispatch module
wire backEndReady_l1;
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] dispatchPacket${i}_iq;
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] alPacket${i}_al;
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
wire [`CHECKPOINTS+`LSQ_FLAGS-1:0] dispatchPacket${i}_lsq;
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
wire [`CHECKPOINTS-1:0] updatedBranchMask${i}_l1;
LABEL
}
print "\n";

# Issue queue
print <<LABEL;
// wires for issueq module
wire [`SIZE_ISSUEQ_LOG:0]cntInstIssueQ;
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
wire grantedValid$i;
wire [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] grantedPacket$i;
LABEL
}
print "\n";

# IssueQueue-RegRead pipe register
print <<LABEL;
// wires for iq_regread module
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
wire grantedValid${i}_l1;
wire [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] grantedPacket${i}_l1;
LABEL
}
print "\n";

# RegRead
print <<LABEL;
// wire for reg_read module
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_PHYSICAL_LOG:0] newDestMap${i};
LABEL
}
print "\n";

print <<LABEL;
wire [`SIZE_PHYSICAL_TABLE-1:0] phyRegRdy;
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
wire [2*`SIZE_DATA+`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket${i};
wire fuPacketValid${i};
LABEL
}
print "\n";

# RSR
print <<LABEL;
// wires for rsr module
LABEL

for($i=0; $i<$issueWidth-$fuNo[$typesOfFUs-1]; $i++) # All instructions except LD/ST
{
	print <<LABEL;
wire [`SIZE_PHYSICAL_LOG-1:0] granted${i}Dest;
wire [`SIZE_ISSUEQ_LOG-1:0] granted${i}Entry;
LABEL
}

for(; $i<$issueWidth; $i++) # For LD/ST - MUST BE DONE JUST AFTER the previous for loop (without changing $i)
{
	print <<LABEL;
wire granted${i}Dest;
wire granted${i}Entry;
LABEL
}
print "\n";

for($i=0; $i<$issueWidth-$fuNo[$typesOfFUs-1]; $i++) # All instructions except LD/ST
{
	print <<LABEL;
wire [`SIZE_ISSUEQ_LOG-1:0] freedEntry${i};
wire freedValid${i};
LABEL
}
print "\n";

for($i=0; $i<$issueWidth-$fuNo[$typesOfFUs-1]; $i++) # All instructions except LD/ST
{
	print <<LABEL;
wire [`SIZE_PHYSICAL_LOG-1:0] rsr${i}Tag;
wire rsr${i}TagValid;
LABEL
}
print "\n";

# Not used, kept here for diffing
print <<LABEL;
wire [`SIZE_PHYSICAL_LOG:0] rsr0Delayed1Tag;
wire [`SIZE_PHYSICAL_LOG:0] rsr1Delayed1Tag;
wire [`SIZE_PHYSICAL_LOG:0] rsr2Delayed1Tag;
wire [`SIZE_PHYSICAL_LOG:0] rsr0Delayed2Tag;
wire [`SIZE_PHYSICAL_LOG:0] rsr1Delayed2Tag;
wire [`SIZE_PHYSICAL_LOG:0] rsr2Delayed2Tag;
LABEL

# RegRead-Execute
print <<LABEL;
// wires from regread_execute module 
LABEL

for($i=0; $i<$issueWidth-$fuNo[$typesOfFUs-1]-$fuNo[$typesOfFUs-2]; $i++) # All instructions except LD/ST and BR
{
	print <<LABEL;
wire [`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+
      `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:0] fuPacket${i}_l1;
wire fuPacketValid${i}_l1;
LABEL
}

$temp = $i;
for(; $i<$temp+$fuNo[$typesOfFUs-2]; $i++) # For BR
{
	print <<LABEL;
wire [`SIZE_PC+`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+
      `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+
      `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] fuPacket${i}_l1;
wire fuPacketValid${i}_l1;
LABEL
}

$temp = $i;
for(; $i<$temp+$fuNo[$typesOfFUs-1]; $i++) # For LD/ST
{
	print <<LABEL;
wire [`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+
      `SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:0] fuPacket${i}_l1;
wire fuPacketValid${i}_l1;
LABEL
}
print "\n";

# Execute
print <<LABEL;
// wires from execute module
LABEL

for($i=0; $i<$issueWidth-$fuNo[$typesOfFUs-1]; $i++) # All instructions except LD/ST
{
	print <<LABEL;
wire [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket${i};
wire exePacketValid${i};
LABEL
}

for(; $i<$issueWidth; $i++) # For LD/ST - MUST BE DONE JUST AFTER the previous for loop (without changing $i)
{
	print <<LABEL;
wire [`CHECKPOINTS+`LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
      `SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket${i};
wire exePacketValid${i};
LABEL
}
print "\n";

# Writeback
print <<LABEL;
// wire from writeback module
wire flagRecoverEX;
wire ctrlConditional;
wire ctrlVerified;
wire [1:0] ctrlVerifiedSMTid;
wire [`SIZE_PC-1:0] ctrlTargetAddr;
wire ctrlBrDirection;
wire [`SIZE_CTI_LOG-1:0] ctrlCtiQueueIndex;

LABEL


for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket${i};
LABEL
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
wire bypassValid${i};
LABEL
}
print "\n";

print <<LABEL;
wire [`SIZE_ISSUEQ_LOG-1:0] agenIqEntry0;
wire agenIqFreedValid0;

LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
wire writebkValid${i};
LABEL
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU${i};
LABEL
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_PC-1:0] computedAddr${i};
LABEL
}
print "\n";

print <<LABEL;
wire agenPacketValid0;
wire [`LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
      `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] agenPacket0;

// wire from Load-Store Unit
LABEL

for($i=0; $i<$dispatchWidth; $i++){
print "wire [`SIZE_LSQ_LOG-1:0] lsqId${i};\n";
}

print <<LABEL;
wire [`SIZE_LSQ_LOG:0]   loadQueueCnt;
wire [`SIZE_LSQ_LOG:0]   storeQueueCnt;
wire lsuPacketValid0;
wire [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:0] lsuPacket0;
wire [`SIZE_ACTIVELIST_LOG:0] ldViolationPacket_l1;
wire [`SIZE_ACTIVELIST_LOG:0] ldViolationPacket_l2;


// wires from activeList module
LABEL

for($i=0; $i<$dispatchWidth; $i++){
 print "wire [`SIZE_ACTIVELIST_LOG-1:0] activeListId${i};\n";
}

print "wire [`SIZE_ACTIVELIST_LOG:0] activeListCnt;\n";

for($i=0; $i<$retireWidth; $i++){
print <<LABEL;
wire [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] commitPacket${i};
wire commitStore${i};
wire commitLoad${i};
wire commitValid${i};

wire commitValid${i}_l1;
wire [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] commitPacket${i}_l1;
wire commitStore${i}_l1;
wire commitLoad${i}_l1;

LABEL
}

print "wire [`RETIRE_WIDTH-1:0] commitCti;\n";

print <<LABEL;
wire recoverFlag;
wire [`SIZE_PC-1:0] recoverPC;
wire exceptionFlag;
wire [`SIZE_PC-1:0] exceptionPC;


// wires from amt module
LABEL

for($i=0; $i<$retireWidth; $i++){

print "wire releasedValid${i};\n";
print "wire [`SIZE_PHYSICAL_LOG-1:0] releasedPhyMap${i};\n";
}

for($i=0; $i<$fetchWidth; $i++){

print "wire [`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:0] recoverPacket${i};\n";
}




print <<LABEL;

 /********************************************************************************** 
 *  "interface" module provides interface between Level-1 instruction cache 
 *  and lower level memory hierarchy. 
 **********************************************************************************/
 Interface interface(.clk(clock),
                     .reset(reset | recoverFlag),
                     .flush_i(1'b0),
                     .wrL1ICacheEnable_i(wrL1ICacheEnable_i),
                     .wrAddrL1ICache_i(wrAddrL1ICache_i),
                     .wrBlockL1ICache_i(wrBlockL1ICache_i),
                     .missL1ICache_i(missL1ICache),
                     .missAddrL1ICache_i(missAddrL1ICache),
                     .wrL1ICacheEnable_o(wrL1ICacheEnable_l1),
                     .wrAddrL1ICache_o(wrAddrL1ICache_l1),
                     .wrBlockL1ICache_o(wrBlockL1ICache_l1),
                     .missL1ICache_o(missL1ICache_o),
                     .missAddrL1ICache_o(missAddrL1ICache_o)
		    );	

LABEL

if($supportBA)
{
print <<LABEL;
	
	
	/********************************************************************************** 
	*  "Fetch1a" module is the first stage of the instruction fetching process designed for
	*	Block Ahead Pipeline. This stage starts the access of BTB, Branch Predictor and 
	*	L1 Cache. This stage sets the new PC every cycle through next_pc given by Fetch1b.
	**********************************************************************************/
	FetchStage1a fs1a(	.clk(clock),
	.reset(reset),
	.stall_i(instBufferFull|ctiQueueFull),
	.f_recover_EX_i(flagRecoverEX),
	.f_flush_trap_i(recoverFlag|exceptionFlag),
	.next_pc_i(next_pc),
	.pc_o(pc)
	);
	
	/********************************************************************************** 
	*  "BTB" module is a 2 cycle pieplined BTB designed for Block Ahead Pipeline.
	*	It is separated in 2 banks (odd and even). Each bank has 4 ways which has FIFO 
	*	replacement policy.
	**********************************************************************************/
	BTB btb(	.clk(clock),					
	.reset(reset),			
	.stall_i(instBufferFull|ctiQueueFull),
	.flush_i(flagRecoverEX|recoverFlag|f2_flush_pc|exceptionFlag),
	.pc_i(pc),
	.flush_pc_i(f2_flush_pc),
	.new_fifo_read_i(tag_pc_f2[`SIZE_BTB_INDEX_LOG+`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET]),	
	.tag_pc_i(tag_pc_f2d),			
	.tag_type_i(tag_type_f2d),	
	.target_i(target_f2d),	
	.type_i(type_f2d),	
	.position_b_i(position_b_f2d),
	.last_i(last_f2d),	
	.fifo_even_i(fifo_even_f2d),	
	.fifo_odd_i(fifo_odd_f2d),
	.valid_i(valid_f2d),
LABEL

	for($i=0; $i<$fetchWidth; $i++)
	{	
		print ".btb_hit_N",$i,"_o(btb_hit_N",$i,"),\n";
		print ".target_N",$i,"_o(target_N",$i,"),\n";
		print ".type_N",$i,"_o(type_N",$i,"),\n";
		print ".position_b_N",$i,"_o(position_b_N",$i,"),\n";
		print ".last_N",$i,"_o(last_N",$i,"),\n";
	}
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print ".btb_hit_T",$i,"_o(btb_hit_T",$i,"),\n";
		print ".target_T",$i,"_o(target_T",$i,"),\n";
		print ".type_T",$i,"_o(type_T",$i,"),\n";
		print ".position_b_T",$i,"_o(position_b_T",$i,"),\n";
		print ".last_T",$i,"_o(last_T",$i,"),\n";
	}
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print ".btb_hit_R",$i,"_o(btb_hit_R",$i,"),\n";
		print ".target_R",$i,"_o(target_R",$i,"),\n";
		print ".type_R",$i,"_o(type_R",$i,"),\n";
		print ".position_b_R",$i,"_o(position_b_R",$i,"),\n";
		print ".last_R",$i,"_o(last_R",$i,"),\n";
	}
	print <<LABEL;
	.fifo_even_o(fifo_even),							
	.fifo_odd_o(fifo_odd)
	);
	
	/********************************************************************************** 
	*  "BranchPrediction" module is a 2 cycle pieplined Branch Predictor designed for 
		*	Block Ahead Pipeline. It is designed to give 4 predictions per cycle. It is made
		*	with 2 banks (odd and even). Each entry contains 4 counters. Update Reads the
		*	predictor first so that it knows the value of the counter at the time of update.
		**********************************************************************************/
		BranchPrediction bp(	.clk(clock),
		.reset(reset),
		.stall_i(instBufferFull|ctiQueueFull),
		.flush_i(flagRecoverEX|recoverFlag|f2_flush_pc|exceptionFlag),
		.pc_i(pc),
		.bp_tag_pc_i(bp_tag_pc_f2d),
		.bp_dir_i(bp_dir_f2d),
		.bp_update_i(bp_update_f2d),
LABEL
	for($i=0; $i<$fetchWidth; $i++)
	{
		print ".pred",$i,"_o(pred",$i,")";
		if($i<$fetchWidth-1)
		{
			print ",";
		}
		print "\n";
	}
	print <<LABEL;
	);
	
	/********************************************************************************** 
	*  "Fetch1aFetch1b" module works as a pipeline register between Fetch1a and Fetch1b.
	**********************************************************************************/
	Fetch1aFetch1b fs1afs1b(.clk(clock),
	.reset(reset),
	.pc_i(pc),
	.stall_i(instBufferFull|ctiQueueFull),
	.flush_i(flagRecoverEX|recoverFlag|f2_flush_pc|exceptionFlag),
	.pc_o(pc_f1a1b),
	.valid_pc_o(valid_pc_f1a1b)
	);
	
	/********************************************************************************** 
	*  "RAS" module stores the address of PC+1 for the call PC in LIFO structure.
		**********************************************************************************/						
		RAS ras(	.clk(clock),
		.reset(reset),
		.stall_i(instBufferFull|ctiQueueFull),
		.flush_RAS_i(flagRecoverEX|recoverFlag|exceptionFlag),
		.push_addr_i(push_addr),
		.recover_ID_i(copy_stack),
		.push_i(push_RAS),
		.pop_i(pop_RAS),
		.ras_top_addr_i(ras_top_addr),
		.update_ras_top_i(update_ras_top),
		.CP_push_addr_i(CP_push_addr),
		.CP_push_i(CP_RAS_push),
		.CP_pop_i(CP_RAS_pop),						
		.pop_addr_o(pop_addr),
		.is_empty_o(is_empty_RAS),
		.CP_pop_addr_o(CP_pop_addr),
		.CP_is_empty_o(CP_is_empty_RAS)
		);
	
	/********************************************************************************** 
	*  "SAS" module stores the information about the block after the return in LIFO structure.
	*	This helps in predicting the next PC at return point.
	**********************************************************************************/		
	SAS sas(	.clk(clock),
	.reset(reset),
	.stall_i(instBufferFull|ctiQueueFull),
	.flush_SAS_i(flagRecoverEX|recoverFlag|exceptionFlag),
	.push_btb_entry_i(push_btb_entry),
	.recover_ID_i(copy_stack),
	.push_i(push_SAS),
	.pop_i(pop_SAS),
	.CP_push_btb_entry_i(CP_push_btb_entry),
	.CP_push_i(CP_SAS_push),
	.CP_pop_i(CP_SAS_pop),						
	.pop_btb_entry_o(pop_btb_entry),
	.is_empty_o(is_empty_SAS),
	.CP_pop_btb_entry_o(CP_pop_btb_entry),
	.CP_is_empty_o(CP_is_empty_SAS)
	);
	
	
	/********************************************************************************** 
	*  "Fetch1b" module is the second stage of the instruction fetching process. This stage
	*	completes the access of BTB, Branch Predictor and L1 Cache. This Stage has the logic
	*	to compute the next PC which is sent to Fetch1a. This stage also updates the RAS and
	*	SAS if there is a CALL/RETURN instruction in the block fetch from I\$.
		**********************************************************************************/
		FetchStage1b fs1b(	.clk(clock),
		.reset(reset),
		.flush_i(flagRecoverEX|recoverFlag|exceptionFlag),
		.stall_i(instBufferFull|ctiQueueFull),
		.f_exp_i(exceptionFlag),
		.exp_pc_i(exceptionPC),
		.f1a_pc_i(pc),
		.pc_i(pc_f1a1b),
		.valid_pc_i(valid_pc_f1a1b),
LABEL
	for($i=0; $i<$fetchWidth; $i++)
	{
		print ".btb_hit_N",$i,"_i(btb_hit_N",$i,"),\n";							
		print ".target_N",$i,"_i(target_N",$i,"),\n";				
		print ".type_N",$i,"_i(type_N",$i,"),\n";				
		print ".position_b_N",$i,"_i(position_b_N",$i,"),\n";	
		print ".last_N",$i,"_i(last_N",$i,"),\n";
	}
	for($i=0; $i<$fetchWidth; $i++)
	{
		print ".btb_hit_T",$i,"_i(btb_hit_T",$i,"),\n";							
		print ".target_T",$i,"_i(target_T",$i,"),\n";				
		print ".type_T",$i,"_i(type_T",$i,"),\n";				
		print ".position_b_T",$i,"_i(position_b_T",$i,"),\n";	
		print ".last_T",$i,"_i(last_T",$i,"),\n";
	}
	for($i=0; $i<$fetchWidth; $i++)
	{
		print ".btb_hit_R",$i,"_i(btb_hit_R",$i,"),\n";							
		print ".target_R",$i,"_i(target_R",$i,"),\n";				
		print ".type_R",$i,"_i(type_R",$i,"),\n";				
		print ".position_b_R",$i,"_i(position_b_R",$i,"),\n";	
		print ".last_R",$i,"_i(last_R",$i,"),\n";
	}
	for($i=0; $i<$fetchWidth; $i++)
	{
		print ".pred",$i,"_i(pred",$i,"),\n";
	}
	print <<LABEL;
	.pop_addr_i(pop_addr),
	.is_RAS_empty_i(is_empty_RAS),	
	.pop_btb_entry_i(pop_btb_entry),
	.is_SAS_empty_i(is_empty_SAS),
	.f2_valid_i(f2_valid),
	.f2_position_b_i(f2_position_b),
	.f2_tag_type_i(f2_tag_type),
	.f2_is_call_i(f2_is_call),
	.f2_is_call_updated_i(f2_is_call_updated),
	.f2_is_return_updated_i(f2_is_return_updated),
	.f2_ras_top_addr_i(f2_ras_top_addr),
	.f2_flush_pc_i(f2_flush_pc),
	.f2_pc_i(f2_pc),
	.f2_flush_npc_i(f2_flush_npc),
	.f2_npc_i(f2_npc),
	.f2_copy_stack_i(f2_copy_stack),				
	.pc_o(pc_f1b),
	.valid_pc_o(valid_pc_f1b),
LABEL
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print ".btb_hit_N",$i,"_o(btb_hit_N",$i,"_f1b),\n";
		print ".target_N",$i,"_o(target_N",$i,"_f1b),\n";
		print ".type_N",$i,"_o(type_N",$i,"_f1b),\n";
		print ".position_b_N",$i,"_o(position_b_N",$i,"_f1b),\n";
		print ".last_N",$i,"_o(last_N",$i,"_f1b),\n";
	}
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print ".btb_hit_T",$i,"_o(btb_hit_T",$i,"_f1b),\n";
		print ".target_T",$i,"_o(target_T",$i,"_f1b),\n";
		print ".type_T",$i,"_o(type_T",$i,"_f1b),\n";
		print ".position_b_T",$i,"_o(position_b_T",$i,"_f1b),\n";
		print ".last_T",$i,"_o(last_T",$i,"_f1b),\n";
	}
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print ".btb_hit_R",$i,"_o(btb_hit_R",$i,"_f1b),\n";
		print ".target_R",$i,"_o(target_R",$i,"_f1b),\n";
		print ".type_R",$i,"_o(type_R",$i,"_f1b),\n";
		print ".position_b_R",$i,"_o(position_b_R",$i,"_f1b),\n";
		print ".last_R",$i,"_o(last_R",$i,"_f1b),\n";
	}
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print ".pred",$i,"_o(pred",$i,"_f1b),\n";
	}
	print <<LABEL;
	.next_pc_o(next_pc),
	.push_addr_o(push_addr),
	.copy_stack_o(copy_stack),
	.push_RAS_o(push_RAS),
	.pop_RAS_o(pop_RAS),
	.ras_top_addr_o(ras_top_addr),
	.update_ras_top_o(update_ras_top),
	.push_btb_entry_o(push_btb_entry),
	.push_SAS_o(push_SAS),
	.pop_SAS_o(pop_SAS),
	.btb_hit_o(btb_hit),
	.hit_target_o(hit_target),
	.hit_type_o(hit_type),
	.hit_position_b_o(hit_position_b),
	.hit_last_o(hit_last),
	.pred_o(pred),
	.tag_type_o(tag_type),
	.position_b_o(position_b)
	);
	
	/********************************************************************************** 
	*  "L1ICache" module is 2 cycle pipelined L1 Cache for Block Ahead Pipeline
		**********************************************************************************/			
		L1ICache l1(	.clk(clock),
		.reset(reset),
		.stall_i(instBufferFull|ctiQueueFull),
		.flush_i(flagRecoverEX|recoverFlag|f2_flush_pc|exceptionFlag),
		.addr_i(pc),					
		.rdEnable_i(instBufferFull),								
		.wrEnabale_i(wrL1ICacheEnable_l1),								
		.wrAddr_i(wrAddrL1ICache_l1),					
		.instBlock_i(wrBlockL1ICache_l1),
		.instBundle_o(instBundle),	
		.miss_o(miss),									
		.missAddr_o(missAddr)
		);
	
	
	/********************************************************************************** 
	*  "Fetch1Fetch2" module is th pipeline register between Fetch1b(end of Fetch1) and Fetch2.
	**********************************************************************************/
	Fetch1Fetch2 fs1fs2(	.clk(clock),
	.reset(reset),
	.flush_i(flagRecoverEX|recoverFlag|f2_flush_pc|exceptionFlag),
	.stall_i(instBufferFull|ctiQueueFull),
	.instructionBundle_i(instBundle),
	.pc_i(pc_f1b),
	.valid_pc_i(valid_pc_f1b),
LABEL
	for($i=0; $i<$fetchWidth; $i++)
	{
		print ".btb_hit_N",$i,"_i(btb_hit_N",$i,"_f1b),\n";							
		print ".target_N",$i,"_i(target_N",$i,"_f1b),\n";				
		print ".type_N",$i,"_i(type_N",$i,"_f1b),\n";				
		print ".position_b_N",$i,"_i(position_b_N",$i,"_f1b),\n";	
		print ".last_N",$i,"_i(last_N",$i,"_f1b),\n";
	}
	for($i=0; $i<$fetchWidth; $i++)
	{
		print ".btb_hit_T",$i,"_i(btb_hit_T",$i,"_f1b),\n";							
		print ".target_T",$i,"_i(target_T",$i,"_f1b),\n";				
		print ".type_T",$i,"_i(type_T",$i,"_f1b),\n";				
		print ".position_b_T",$i,"_i(position_b_T",$i,"_f1b),\n";	
		print ".last_T",$i,"_i(last_T",$i,"_f1b),\n";
	}
	for($i=0; $i<$fetchWidth; $i++)
	{
		print ".btb_hit_R",$i,"_i(btb_hit_R",$i,"_f1b),\n";							
		print ".target_R",$i,"_i(target_R",$i,"_f1b),\n";				
		print ".type_R",$i,"_i(type_R",$i,"_f1b),\n";				
		print ".position_b_R",$i,"_i(position_b_R",$i,"_f1b),\n";	
		print ".last_R",$i,"_i(last_R",$i,"_f1b),\n";
	}
	for($i=0; $i<$fetchWidth; $i++)
	{
		print ".pred",$i,"_i(pred",$i,"_f1b),\n";
	}
	print <<LABEL;
	.btb_hit_i(btb_hit),
	.hit_target_i(hit_target),
	.hit_type_i(hit_type),
	.hit_position_b_i(hit_position_b),
	.hit_last_i(hit_last),
	.pred_i(pred),
	.tag_type_i(tag_type),
	.position_b_i(position_b),
	.instructionBundle_o(instructionBundle),
	.pc_o(pc_f12),
	.valid_pc_o(valid_pc_f12),
LABEL
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print ".btb_hit_N",$i,"_o(btb_hit_N",$i,"_f12),\n";
		print ".target_N",$i,"_o(target_N",$i,"_f12),\n";
		print ".type_N",$i,"_o(type_N",$i,"_f12),\n";
		print ".position_b_N",$i,"_o(position_b_N",$i,"_f12),\n";
		print ".last_N",$i,"_o(last_N",$i,"_f12),\n";
	}
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print ".btb_hit_T",$i,"_o(btb_hit_T",$i,"_f12),\n";
		print ".target_T",$i,"_o(target_T",$i,"_f12),\n";
		print ".type_T",$i,"_o(type_T",$i,"_f12),\n";
		print ".position_b_T",$i,"_o(position_b_T",$i,"_f12),\n";
		print ".last_T",$i,"_o(last_T",$i,"_f12),\n";
	}
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print ".btb_hit_R",$i,"_o(btb_hit_R",$i,"_f12),\n";
		print ".target_R",$i,"_o(target_R",$i,"_f12),\n";
		print ".type_R",$i,"_o(type_R",$i,"_f12),\n";
		print ".position_b_R",$i,"_o(position_b_R",$i,"_f12),\n";
		print ".last_R",$i,"_o(last_R",$i,"_f12),\n";
	}
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print ".pred",$i,"_o(pred",$i,"_f12),\n";
	}
	print <<LABEL;
	.btb_hit_o(btb_hit_f12),
	.hit_target_o(hit_target_f12),
	.hit_type_o(hit_type_f12),
	.hit_position_b_o(hit_position_b_f12),
	.hit_last_o(hit_last_f12),
	.pred_o(pred_f12),
	.tag_type_o(tag_type_f12),
	.position_b_o(position_b_f12)
	);
	
	/********************************************************************************** 
	*  "Fetch2" module is the pipeline stage which Pre-Decodes the instructions to correct
	*	the BTB-Miss and wrond prediction if any, to recover the PC back on the correct path.
		*	It contains the Control Instruction Queue(CTIQ)
		**********************************************************************************/
		FetchStage2 fs2(	.clk(clock),
		.reset(reset),
		.flush_i(flagRecoverEX|recoverFlag|exceptionFlag),
		.stall_i(instBufferFull|ctiQueueFull),
		.f_trap_i(exceptionFlag),
		.f_recover_i(recoverFlag),
		.recover_pc_i(recoverPC),
		.f1b_pc_i(pc_f1a1b),
		.f1b_valid_pc_i(valid_pc_f1a1b),
		.pc_i(pc_f12),
		.valid_pc_i(valid_pc_f12),
		.instructionBundle_i(instructionBundle),
LABEL
		for($i=0; $i<$fetchWidth; $i++)
	{
		print ".btb_hit_N",$i,"_i(btb_hit_N",$i,"_f12),\n";							
		print ".target_N",$i,"_i(target_N",$i,"_f12),\n";				
		print ".type_N",$i,"_i(type_N",$i,"_f12),\n";				
		print ".position_b_N",$i,"_i(position_b_N",$i,"_f12),\n";	
		print ".last_N",$i,"_i(last_N",$i,"_f12),\n";
	}
	for($i=0; $i<$fetchWidth; $i++)
	{
		print ".btb_hit_T",$i,"_i(btb_hit_T",$i,"_f12),\n";							
		print ".target_T",$i,"_i(target_T",$i,"_f12),\n";				
		print ".type_T",$i,"_i(type_T",$i,"_f12),\n";				
		print ".position_b_T",$i,"_i(position_b_T",$i,"_f12),\n";	
		print ".last_T",$i,"_i(last_T",$i,"_f12),\n";
	}
	for($i=0; $i<$fetchWidth; $i++)
	{
		print ".btb_hit_R",$i,"_i(btb_hit_R",$i,"_f12),\n";							
		print ".target_R",$i,"_i(target_R",$i,"_f12),\n";				
		print ".type_R",$i,"_i(type_R",$i,"_f12),\n";				
		print ".position_b_R",$i,"_i(position_b_R",$i,"_f12),\n";	
		print ".last_R",$i,"_i(last_R",$i,"_f12),\n";
	}
	print <<LABEL;
	.fifo_even_i(fifo_even),
	.fifo_odd_i(fifo_odd),
LABEL
	for($i=0; $i<$fetchWidth; $i++)
	{
		print ".pred",$i,"_i(pred",$i,"_f12),\n";
	}
	print <<LABEL;
	.btb_hit_i(btb_hit_f12),
	.hit_target_i(hit_target_f12),
	.hit_type_i(hit_type_f12),
	.hit_position_b_i(hit_position_b_f12),
	.hit_last_i(hit_last_f12),
	.pred_i(pred_f12),
	.tag_type_i(tag_type_f12),
	.position_b_i(position_b_f12),
	.dec_valid_i(dec_valid),
	.dec_tag_pc_i(dec_tag_pc),
	.dec_br_type_i(dec_br_type),
	.dec_btb_hit_i(dec_btb_hit),
	.dec_br_dir_i(dec_br_dir),
	.dec_hit_l_i(dec_hit_l),
	.dec_hit_t_i(dec_hit_t),
	.dec_hit_target_i(dec_hit_target),
	.dec_hit_b_i(dec_hit_b),
	.dec_old_br_dir_i(dec_old_br_dir),
	.dec_is_jalr_jr_i(dec_is_jalr_jr),
	.dec_is_ctrl_i(dec_is_ctrl),
	.dec_fifo_even_i(dec_fifo_even),
	.dec_fifo_odd_i(dec_fifo_odd),
	.CP_pop_btb_entry_i(CP_pop_btb_entry),
	.CP_is_SAS_empty_i(CP_is_empty_SAS),
	.CP_pop_addr_i(CP_pop_addr),
	.CP_is_RAS_empty_i(CP_is_empty_RAS),
	.ctiQueueIndex_i(ctrlCtiQueueIndex),
	.targetAddr_i(ctrlTargetAddr),
	.branchOutcome_i(ctrlBrDirection),
	.flagRecoverEX_i(flagRecoverEX),	
	.ctrlVerified_i(ctrlVerified),
	.commitCti_i(commitCti),
	.valid_pc_o(valid_pc_f2),
	.last_pc_o(last_pc_f2),
	.btb_hit_o(btb_hit_f2),
	.br_type_o(br_type_f2),
	.br_dir_o(br_dir_f2),
	.hit_last_o(hit_last_f2),
	.hit_type_o(hit_type_f2),
	.hit_target_o(hit_target_f2),
	.hit_position_b_o(hit_position_b_f2),
	.is_ctrl_o(is_ctrl_f2),
	.is_jalr_jr_o(is_jalr_jr_f2),
	.curr_fifo_even_o(curr_fifo_even_f2),
	.curr_fifo_odd_o(curr_fifo_odd_f2),
	.old_br_dir_o(old_br_dir_f2),			
	.CP_push_btb_entry_o(CP_push_btb_entry),
	.CP_SAS_push_o(CP_SAS_push),
	.CP_SAS_pop_o(CP_SAS_pop),
	.CP_push_addr_o(CP_push_addr),
	.CP_RAS_push_o(CP_RAS_push),
	.CP_RAS_pop_o(CP_RAS_pop),
	.bp_tag_pc_o(bp_tag_pc),
	.bp_dir_o(bp_dir),
	.bp_update_o(bp_update),
	.f2_valid_o(f2_valid),
	.f2_position_b_o(f2_position_b),
	.f2_tag_type_o(f2_tag_type),
	.f2_is_call_o(f2_is_call),
	.f2_is_call_updated_o(f2_is_call_updated),
	.f2_is_return_updated_o(f2_is_return_updated),
	.f2_ras_top_addr_o(f2_ras_top_addr),
	.f2_flush_pc_o(f2_flush_pc),
	.f2_pc_o(f2_pc),
	.f2_flush_npc_o(f2_flush_npc),
	.f2_npc_o(f2_npc),
	.f2_copy_stack_o(f2_copy_stack),
	.tag_pc_o(tag_pc_f2),					
	.tag_type_o(tag_type_f2),			
	.target_o(target_f2),					
	.type_o(type_f2),				
	.position_b_o(position_b_f2),
	.last_o(last_f2),									
	.fifo_even_o(fifo_even_f2),	
	.fifo_odd_o(fifo_odd_f2),
	.valid_o(valid_f2),
LABEL
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print ".instruction",$i,"Valid_o(instruction",$i,"Valid),\n";
		print ".inst",$i,"Packet_o(inst",$i,"Packet),\n";
	}
	print <<LABEL;
	.ctiQueueFull_o(ctiQueueFull)
	);
	
	
	
	/********************************************************************************** 
	* "fs2dec" module is the pipeline stage between Fetch Stage-2 and decode stage.
	**********************************************************************************/
	Fetch2Decode fs2dec(	.clk(clock),
	.reset(reset),
	.flush_i(exceptionFlag),
	.f_recover_EX_i(recoverFlag),
	.stall_i(instBufferFull),						
	.tag_pc_i(tag_pc_f2),		
	.tag_type_i(tag_type_f2),	
	.target_i(target_f2),	
	.type_i(type_f2),
	.position_b_i(position_b_f2),
	.last_i(last_f2),	
	.fifo_even_i(fifo_even_f2),		
	.fifo_odd_i(fifo_odd_f2),
	.valid_i(valid_f2),				
LABEL
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print ".instruction",$i,"Valid_i(instruction",$i,"Valid),\n";
		print ".inst",$i,"Packet_i(inst",$i,"Packet),\n";
	}
	print <<LABEL;
	.bp_tag_pc_i(bp_tag_pc),
	.bp_dir_i(bp_dir),
	.bp_update_i(bp_update),
	.valid_pc_i(valid_pc_f2),
	.last_pc_i(last_pc_f2),
	.btb_hit_i(btb_hit_f2),
	.br_type_i(br_type_f2),
	.br_dir_i(br_dir_f2),
	.hit_last_i(hit_last_f2),
	.hit_type_i(hit_type_f2),
	.hit_target_i(hit_target_f2),
	.hit_position_b_i(hit_position_b_f2),
	.is_ctrl_i(is_ctrl_f2),
	.is_jalr_jr_i(is_jalr_jr_f2),
	.curr_fifo_even_i(curr_fifo_even_f2),
	.curr_fifo_odd_i(curr_fifo_odd_f2),
	.old_br_dir_i(old_br_dir_f2),						
	.valid_pc_o(valid_pc_f2d),
	.last_pc_o(last_pc_f2d),
	.btb_hit_o(btb_hit_f2d),
	.br_type_o(br_type_f2d),
	.br_dir_o(br_dir_f2d),
	.hit_last_o(hit_last_f2d),
	.hit_type_o(hit_type_f2d),
	.hit_target_o(hit_target_f2d),
	.hit_position_b_o(hit_position_b_f2d),
	.is_ctrl_o(is_ctrl_f2d),
	.is_jalr_jr_o(is_jalr_jr_f2d),		
	.curr_fifo_even_o(curr_fifo_even_f2d),
	.curr_fifo_odd_o(curr_fifo_odd_f2d),
	.old_br_dir_o(old_br_dir_f2d),																
	.bp_tag_pc_o(bp_tag_pc_f2d),
	.bp_dir_o(bp_dir_f2d),
	.bp_update_o(bp_update_f2d),
LABEL
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print ".instruction",$i,"Valid_o(instruction",$i,"Valid_f2d),\n";
		print ".inst",$i,"Packet_o(inst",$i,"Packet_f2d),\n";
	}
	print <<LABEL;
	.tag_pc_o(tag_pc_f2d),					
	.tag_type_o(tag_type_f2d),			
	.target_o(target_f2d),					
	.type_o(type_f2d),				
	.position_b_o(position_b_f2d),
	.last_o(last_f2d),									
	.fifo_even_o(fifo_even_f2d),	
	.fifo_odd_o(fifo_odd_f2d),
	.valid_o(valid_f2d)
	);
	
	
	/********************************************************************************** 
	* "decode" module decodes the incoming instruction and generate appropriate 
	* signals required by the rest of the pipeline stages. 
	**********************************************************************************/ 
	Decode decode(	  .reset(reset | recoverFlag| exceptionFlag),
	.clk(clock),
	.stall_i(instBufferFull),
	.fs2Ready_i(1'b1),
LABEL
	for($i=0; $i<$fetchWidth; $i++)
	{	
		print ".inst",$i,"PacketValid_i(instruction",$i,"Valid_f2d),\n";
		print ".inst",$i,"Packet_i(inst",$i,"Packet_f2d),\n";
	}
	print <<LABEL;
	.valid_pc_i(valid_pc_f2d),
	.last_pc_i(last_pc_f2d),
	.btb_hit_i(btb_hit_f2d),
	.br_type_i(br_type_f2d),
	.br_dir_i(br_dir_f2d),
	.hit_last_i(hit_last_f2d),
	.hit_type_i(hit_type_f2d),
	.hit_target_i(hit_target_f2d),
	.hit_position_b_i(hit_position_b_f2d),
	.is_jalr_jr_i(is_jalr_jr_f2d),
	.is_ctrl_i(is_ctrl_f2d),
	.fifo_even_i(curr_fifo_even_f2d),
	.fifo_odd_i(curr_fifo_odd_f2d),
	.old_br_dir_i(old_br_dir_f2d),
	.dec_valid_o(dec_valid),
	.dec_tag_pc_o(dec_tag_pc),
	.dec_br_type_o(dec_br_type),
	.dec_btb_hit_o(dec_btb_hit),
	.dec_br_dir_o(dec_br_dir),
	.dec_hit_l_o(dec_hit_l),
	.dec_hit_t_o(dec_hit_t),
	.dec_hit_target_o(dec_hit_target),
	.dec_hit_b_o(dec_hit_b),
	.dec_old_br_dir_o(dec_old_br_dir),
	.dec_is_jalr_jr_o(dec_is_jalr_jr),
	.dec_is_ctrl_o(dec_is_ctrl),
	.dec_fifo_even_o(dec_fifo_even),
	.dec_fifo_odd_o(dec_fifo_odd),
	.decodeReady_o(decodeReady),
	.decodedVector_o(decodedVector),
LABEL
	for($i=0; $i<2*$fetchWidth; $i++)
	{
	$comma = ($i == 2*$fetchWidth-1)? "" : ",";
	print <<LABEL;
	.decodedPacket${i}_o(decodedPacket${i})$comma
LABEL
	}
	
	print <<LABEL;
	);	
LABEL
	
	
}
else
{
print <<LABEL;

 /********************************************************************************** 
 *  "fetch1" module is the first stage of the instruction fetching process. This
 *  module contains L1 Insturction Cache, Branch Target Buffer, Branch Prediction
 *  Buffer and Return Address Stack structures. 
 **********************************************************************************/
 FetchStage1 fs1( .flush_i(flagRecoverEX),
                  .stall_i(instBufferFull | ctiQueueFull),
                  .clk(clock),
                  .reset(reset),
		  .recoverFlag_i(recoverFlag),	
		  .recoverPC_i(recoverPC),
		  .exceptionFlag_i(exceptionFlag),
                  .exceptionPC_i(exceptionPC),

                  .flagRecoverID_i(flagRecoverID),
                  .flagCallID_i(flagCallID),
                  .callPCID_i(callPCID),
                  .flagRtrID_i(flagRtrID),
                  .targetAddrID_i(targetAddrID),

                  .flagRecoverEX_i(flagRecoverEX),
                  .targetAddrEX_i(ctrlTargetAddr),

                  .updatePC_i(updatePC_l1),
                  .updateTargetAddr_i(updateTargetAddr_l1),
                  .updateBrType_i(updateCtrlType_l1),
                  .updateDir_i(updateDir_l1),
                  .updateEn_i(updateEn_l1),

                  .fs1Ready_o(fs1Ready),
                  .instructionBundle_o(instructionBundle),
                  .pc_o(pc),
		  .addrRAS_CP_o(addrRAS_CP),

		  `ifdef ICACHE
                  .startBlock_o(startBlock),   
                  .firstInst_o(firstInst),
  		  `endif
LABEL

for($i=0; $i<$fetchWidth; $i++)
{
	print <<LABEL;
                  .btbHit${i}_o(btbHit${i}),
                  .targetAddr${i}_o(targetAddr${i}),
                  .prediction${i}_o(prediction${i}),
LABEL
}
print "\n";

print <<LABEL;
                  .wrEnable_i(wrL1ICacheEnable_l1),
                  .wrAddr_i(wrAddrL1ICache_l1),
                  .instBlock_i(wrBlockL1ICache_l1),
                  .miss_o(missL1ICache),
                  .missAddr_o(missAddrL1ICache)
                );
 


 /********************************************************************************** 
 *  "fs1fs2" module is the pipeline stage between Fetch Stage-1 and Fetch
 *  Stage-2.
 **********************************************************************************/
 Fetch1Fetch2 fs1fs2( .clk(clock),
                      .reset(reset | recoverFlag | exceptionFlag),
                      .flush_i(flagRecoverID | flagRecoverEX),
                      .stall_i(instBufferFull | ctiQueueFull),
                      .fs1Ready_i(fs1Ready),
                      .pc_i(pc),
                      .instructionBundle_i(instructionBundle),
LABEL

for($i=0; $i<$fetchWidth; $i++)
{
	print <<LABEL;
                      .btbHit${i}_i(btbHit${i}),
                      .targetAddr${i}_i(targetAddr${i}),
                      .prediction${i}_i(prediction${i}),
LABEL
}
print "\n";

print <<LABEL;
		      `ifdef ICACHE
                      .startBlock_i(startBlock),
                      .firstInst_i(firstInst),
                      .startBlock_o(startBlock_l1),
                      .firstInst_o(firstInst_l1),
		      `endif
                      .fs1Ready_o(fs1Ready_l1),
                      .pc_o(pc_l1),
                      .instructionBundle_o(instructionBundle_l1),
LABEL

for($i=0; $i<$fetchWidth; $i++)
{
	$comma = ($i == $fetchWidth-1)? "" : ",";
	print <<LABEL;
                      .btbHit${i}_o(btbHit${i}_l1),
                      .targetAddr${i}_o(targetAddr${i}_l1),
                      .prediction${i}_o(prediction${i}_l1)$comma
LABEL
}
print "\n";

print <<LABEL;
                   );



 /********************************************************************************** 
 *  "fetch2" module is the second stage of the instruction fetching process. This
 *  module contains small decode logic for control instructions and verifies the 
 *  target address provided by BTB or RAS in "fetch1". 
 *
 *  The module also contains CTI Queue structure, which keeps tracks of number of
 *  branch instructions in the processor.
 **********************************************************************************/ 
 FetchStage2 fs2(     .clk(clock),
                      .reset(reset | exceptionFlag),
		      .recoverFlag_i(recoverFlag),	
                      .stall_i(instBufferFull),
                      .flush_i(flagRecoverEX),

                      .fs1Ready_i(fs1Ready_l1),
                      .instructionBundle_i(instructionBundle_l1),
                      .pc_i(pc_l1),
		      .addrRAS_CP_i(addrRAS_CP),	

                      `ifdef ICACHE
                      .startBlock_i(startBlock_l1),
                      .firstInst_i(firstInst_l1),
		      `endif	
LABEL

for($i=0; $i<$fetchWidth; $i++)
{
	print <<LABEL;
                      .btbHit${i}_i(btbHit${i}_l1),
                      .targetAddr${i}_i(targetAddr${i}_l1),
                      .prediction${i}_i(prediction${i}_l1),
LABEL
}
print "\n";

print <<LABEL;
                      .ctiQueueIndex_i(ctrlCtiQueueIndex),
                      .targetAddr_i(ctrlTargetAddr),
                      .branchOutcome_i(ctrlBrDirection),
                      .flagRecoverEX_i(flagRecoverEX),
                      .ctrlVerified_i(ctrlVerified),

		      .commitCti_i(commitCti),	

                      .flagRecoverID_o(flagRecoverID),
                      .targetAddrID_o(targetAddrID),
                      .flagRtrID_o(flagRtrID),
                      .flagCallID_o(flagCallID),
                      .callPCID_o(callPCID),

                      .updatePC_o(updatePC),
                      .updateTargetAddr_o(updateTargetAddr),
                      .updateCtrlType_o(updateCtrlType),
                      .updateDir_o(updateDir),
                      .updateEn_o(updateEn),
LABEL

for($i=0; $i<$fetchWidth; $i++)
{
	print <<LABEL;
                      .instruction${i}Valid_o(instruction${i}Valid),
                      .inst${i}Packet_o(inst${i}Packet),
LABEL
}
print "\n";

print <<LABEL;
                      .fs2Ready_o(fs2Ready),
                      .ctiQueueFull_o(ctiQueueFull) 
		   );



 /********************************************************************************** 
 * "fs2fs3" module is the pipeline stage between Fetch Stage-2 and decode stage.
 **********************************************************************************/
 Fetch2Decode fs2dec( .clk(clock),
                      .reset(reset),
                      .flush_i(flagRecoverEX | recoverFlag | exceptionFlag),
                      .stall_i(instBufferFull),
                      .updatePC_i(updatePC),
                      .updateTargetAddr_i(updateTargetAddr),
                      .updateCtrlType_i(updateCtrlType),
                      .updateDir_i(updateDir),
                      .updateEn_i(updateEn),

                      .fs2Ready_i(fs2Ready),
LABEL

for($i=0; $i<$fetchWidth; $i++)
{
	print <<LABEL;
                      .instruction${i}Valid_i(instruction${i}Valid),
                      .inst${i}Packet_i(inst${i}Packet),

LABEL
}
print "\n";

print <<LABEL;
                      .updatePC_o(updatePC_l1),
                      .updateTargetAddr_o(updateTargetAddr_l1),
                      .updateCtrlType_o(updateCtrlType_l1),
                      .updateDir_o(updateDir_l1),
                      .updateEn_o(updateEn_l1),

                      .fs2Ready_o(fs2Ready_l1),
LABEL

for($i=0; $i<$fetchWidth; $i++)
{
	$comma = ($i == $decodeWidth-1)? "" : ",";
	print <<LABEL;
                      .instruction${i}Valid_o(instruction${i}Valid_l1),
                      .inst${i}Packet_o(inst${i}Packet_l1)$comma
LABEL
}
print "\n";

print <<LABEL;
		    );



 /********************************************************************************** 
 * "decode" module decodes the incoming instruction and generate appropriate 
 * signals required by the rest of the pipeline stages. 
 **********************************************************************************/ 
 Decode decode
		( .reset(reset | recoverFlag | exceptionFlag),
                  .clk(clock),
                  .fs2Ready_i(fs2Ready_l1),
LABEL

for($i=0; $i<$fetchWidth; $i++)
{
	print <<LABEL;
                  .inst${i}PacketValid_i(instruction${i}Valid_l1),
                  .inst${i}Packet_i(inst${i}Packet_l1),
LABEL
}
print "\n";

print <<LABEL;
                  .decodeReady_o(decodeReady),
                  .decodedVector_o(decodedVector),
LABEL

for($i=0; $i<2*$fetchWidth; $i++)
{
	$comma = ($i == 2*$fetchWidth-1)? "" : ",";
	print <<LABEL;
                  .decodedPacket${i}_o(decodedPacket${i})$comma
LABEL
}

print <<LABEL;
	        );	
LABEL

}
print <<LABEL;	
 /**********************************************************************************
 *  "InstructionBuffer" module decouples instruction fetching process and the rest 
 *   of the pipeline stages.
 *  
 *  This module contains Instruction Queue structure, which can accept variable 
 *  number of instructions but always 4 instructions can be read from instruction
 *  buffer.
 **********************************************************************************/ 
 InstructionBuffer instBuf
			 ( .clk(clock),
                           .reset(reset | recoverFlag | exceptionFlag),
                           .flush_i(flagRecoverEX),
                           .stall_i(freeListEmpty | stallfrontEnd),
                           .decodeReady_i(decodeReady),
                           .decodedVector_i(decodedVector),
LABEL

for($i=0; $i<2*$fetchWidth; $i++)
{
	print <<LABEL;
                           .decodedPacket${i}_i(decodedPacket${i}),
LABEL
}
print "\n";


print <<LABEL;
                           .stallFetch_o(instBufferFull),
                           .instBufferReady_o(instBufferReady),
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                           .decodedPacket${i}_o(decodedPacket${i}_l1),
LABEL
}

print <<LABEL;
                           .branchCount_o(branchCount)
			 );


 /********************************************************************************** 
 *  "InstBufRename" module is the pipeline stage between Instruction buffer and 
 *  Rename Stage.
 **********************************************************************************/
 InstBufRename instBufRen
			( .reset(reset | recoverFlag | exceptionFlag),
                     	  .clk(clock),
                     	  .flush_i(flagRecoverEX), 
                     	  .stall_i(freeListEmpty | stallfrontEnd),
                     	  .instBufferReady_i(instBufferReady),
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                     	  .decodedPacket${i}_i(decodedPacket${i}_l1),
LABEL
}
print "\n";

print <<LABEL;
                     	  .branchCount_i(branchCount),
                     	  .instBufferReady_o(instBufferReady_l1),
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                     	  .decodedPacket${i}_o(decodedPacket${i}_l2),
LABEL
}

print <<LABEL;
                    	  .branchCount_o(branchCount_l1)
                   	);


 /********************************************************************************** 
 *  "rename" module remaps logical source and destination registers to physical
 *  source and destination registers. 
 *  This module contains Rename Map Table and Speculative Free List structures.
 **********************************************************************************/
 Rename rename
			( .clk(clock),
                	  .reset(reset | exceptionFlag),
                	  .stall_i(stallfrontEnd),
                	  .flagRecoverEX_i(flagRecoverEX),
                	  .ctrlVerified_i(ctrlConditional),
                	  .ctrlVerifiedSMTid_i(ctrlVerifiedSMTid),
                	  .decodeReady_i(instBufferReady_l1),
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                	  .decodedPacket${i}_i(decodedPacket${i}_l2),
LABEL
}

print <<LABEL;
                	  .branchCount_i(branchCount_l1),
LABEL

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
                	  .commitValid${i}_i(releasedValid${i}),
                	  .commitReg${i}_i(releasedPhyMap${i}),
LABEL
}

print <<LABEL;
                	  .recoverFlag_i(recoverFlag),
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                	  .recoverDest${i}_i(recoverPacket${i}\[`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG]),
LABEL
}

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                	  .recoverMap${i}_i(recoverPacket${i}\[`SIZE_PHYSICAL_LOG-1:0]),
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                	  .renamedPacket${i}_o(renamedPacket${i}),
LABEL
}

print <<LABEL;
                	  .noFreeSMT_o(noFreeSMT),
                	  .freeListEmpty_o(freeListEmpty),
                 	  .renameReady_o(renameReady)
             		);


/********************************************************************************* 
* "renDis" module is the pipeline stage between Rename and Dispatch Stage.
* 
**********************************************************************************/
 RenameDispatch renDis
			( .clk(clock),
                          .reset(reset | recoverFlag | exceptionFlag),
                          .flush_i(flagRecoverEX),               
                          .stall_i(stallfrontEnd),
			  .ctrlVerified_i(ctrlConditional),

                          .renameReady_i(renameReady),   
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                          .renamedPacket${i}_i(renamedPacket${i}),
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                          .updatedBranchMask${i}_i(updatedBranchMask${i}_l1),
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                          .renamedPacket${i}_o(renamedPacket${i}_l1),
LABEL
}

print <<LABEL;
                          .renameReady_o(renameReady_l1)                
                       	);
 


/***********************************************************************************
* "dispatch" module dispatches renamed packets to Issue Queue, Active List, and 
* Load-Store queue.
* 
***********************************************************************************/                    
 Dispatch dispatch
			( .clk(clock),
                    	  .reset(reset | recoverFlag | exceptionFlag),
                    	  .stall_i(1'b0),
 		    	  .renameReady_i(renameReady_l1),

		    	  .flagRecoverEX_i(flagRecoverEX),
                    	  .ctrlVerified_i(ctrlConditional),
                    	  .ctrlVerifiedSMTid_i(ctrlVerifiedSMTid),	
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                    	  .renamedPacket${i}_i(renamedPacket${i}_l1),
LABEL
}
print "\n";

print <<LABEL;
		    	  .loadQueueCnt_i(loadQueueCnt),
		    	  .storeQueueCnt_i(storeQueueCnt),       
                    	  .issueQueueCnt_i(cntInstIssueQ),      
                    	  .activeListCnt_i(activeListCnt), 
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                    	  .issueqPacket${i}_o(dispatchPacket${i}_iq),
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                          .alPacket${i}_o(dispatchPacket${i}_al),
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                  	  .lsqPacket${i}_o(dispatchPacket${i}_lsq),	
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                	  .updatedBranchMask${i}_o(updatedBranchMask${i}_l1),
LABEL
}
print "\n";

print <<LABEL;
                    	  .backEndReady_o(backEndReady_l1),
		    	  .stallfrontEnd_o(stallfrontEnd)    
                  	);  


/************************************************************************************
* "issueq" module implements wake-up and select logic.
*  
************************************************************************************/                    
 IssueQueue issueq
			( .clk(clock),
		    	  .reset(reset | recoverFlag | exceptionFlag),
		    	  .backEndReady_i(backEndReady_l1),

LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
		    	  .dispatchPacket${i}_i(dispatchPacket${i}_iq),
LABEL
}
print "\n";
	           
for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
		    	  .inst${i}ALid_i(activeListId${i}),  
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
		    	  .lsqId${i}_i(lsqId${i}),          
LABEL
}
print "\n";

print <<LABEL;
                    	  .phyRegRdy_i(phyRegRdy),  

LABEL

# Kept for diffing - remove later.
for($i=0; $i<$issueWidth-$fuNo[$typesOfFUs-1]; $i++) # All instructions except LD/ST
{
	print <<LABEL;
                    //	  .rsr${i}Tag_i({rsr${i}Tag,rsr${i}TagValid}),
LABEL
}

for(; $i<$issueWidth; $i++) # For LD/ST - MUST BE DONE JUST AFTER the previous for loop (without changing $i)
{
	print <<LABEL;
                    	  .rsr${i}Tag_i({bypassPacket${i}\[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:
				              `SIZE_DATA+`CHECKPOINTS_LOG+1],bypassValid${i}}),
LABEL
}
print "\n";

print <<LABEL;
                    	  .ctrlMispredict_i(flagRecoverEX),			  
                    	  .ctrlVerified_i(ctrlConditional),   
                    	  .ctrlSMTid_i(ctrlVerifiedSMTid),      

LABEL


for($i=0; $i<$issueWidth-$fuNo[$typesOfFUs-1]; $i++) # All instructions except LD/ST
{
	print <<LABEL;
						  .rsr${i}Tag_o(rsr${i}Tag),
						  .rsr${i}TagValid_o(rsr${i}TagValid),
LABEL
}
print "\n";

print <<LABEL;
                    	  .cntInstIssueQ_o(cntInstIssueQ),     
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	$comma = ($i == $issueWidth-1)? "" : ",";
	print <<LABEL;
                  .grantedValid${i}_o(grantedValid${i}),
		    	  .grantedPacket${i}_o(grantedPacket${i})$comma
LABEL
}

print <<LABEL;
		 	);


/************************************************************************************
* "iq_regread" module is the pipeline stage between Issue Queue stage and physical
* register file read stage.
*  
* This module also interfaces with RSR. 
* 
************************************************************************************/
 IssueqRegRead iq_regread( .clk(clock),
                           .reset(reset | recoverFlag | exceptionFlag),
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
                           .grantedValid${i}_i(grantedValid${i}),
                           .grantedPacket${i}_i(grantedPacket${i}),
LABEL
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	$comma = ($i == $issueWidth-1)? "" : ",";
	print <<LABEL;
                           .grantedValid${i}_o(grantedValid${i}_l1),
                           .grantedPacket${i}_o(grantedPacket${i}_l1)$comma
LABEL
}

# RSR not used, kept for diffing
print <<LABEL;						   
                 	);


 
/************************************************************************************
* "rsr" module is the pipeline stage between Issue Queue stage and physical
* register file read stage. This module is used to broadcast destination tag of the
* issued instruction to the dependent instructions in the issue queue. 
*  
************************************************************************************/
/* /
 assign granted0Entry = grantedPacket0_l1[`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
 assign granted0Dest  = grantedPacket0_l1[`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+
			`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
 assign granted1Entry = grantedPacket1_l1[`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
 assign granted1Dest  = grantedPacket1_l1[`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+
                        `SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
 assign granted2Entry = grantedPacket2_l1[`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
 assign granted2Dest  = grantedPacket2_l1[`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+
                        `SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];

 RSR rsr( .clk(clock),
          .reset(reset | recoverFlag | exceptionFlag),
          .validPacket0_i(grantedValid0_l1),
          .granted0Dest_i(granted0Dest),
          .granted0Entry_i(granted0Entry),
          .validPacket1_i(grantedValid1_l1),
          .granted1Dest_i(granted1Dest),
          .granted1Entry_i(granted1Entry),
          .validPacket2_i(grantedValid2_l1),
          .granted2Dest_i(granted2Dest),
          .granted2Entry_i(granted2Entry),
          .rsr0Tag_o(rsr0Tag),   
          .rsr0TagValid_o(rsr0TagValid),
          .rsr1Tag_o(rsr1Tag),
          .rsr1TagValid_o(rsr1TagValid),
          .rsr2Tag_o(rsr2Tag),
          .rsr2TagValid_o(rsr2TagValid),
          .freedEntry0_o(freedEntry0),   
          .freedEntry1_o(freedEntry1),    
          .freedEntry2_o(freedEntry2),    
          .freedValid0_o(freedValid0),   
          .freedValid1_o(freedValid1),
          .freedValid2_o(freedValid2)
        );
// */


/************************************************************************************
* reg_read module has physical register file and all the executed values are written.
* The module has also the logic to pick data from the bypassed path. 
* 
************************************************************************************/             
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
assign newDestMap${i} = renamedPacket${i}\[3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+
                      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:
                      2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+
                      `SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
LABEL
}
print "\n";

print <<LABEL;
 RegRead reg_read( .clk(clock),
                   .reset(reset),
		     .exceptionFlag_i(exceptionFlag),	
		     .recoverFlag_i(recoverFlag | exceptionFlag),
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
                   .fuPacket${i}_i(grantedPacket${i}_l1),
                   .fuPacketValid${i}_i(grantedValid${i}_l1),
LABEL
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
                   .bypassPacket${i}_i(bypassPacket${i}),
                   .bypassValid${i}_i(bypassValid${i}),
LABEL
}
print "\n";

print <<LABEL;
		   .ctrlMispredict_i(flagRecoverEX),
                   .ctrlVerified_i(ctrlConditional),
                   .ctrlSMTid_i(ctrlVerifiedSMTid),
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                   .unmapDest${i}_i(newDestMap${i}),
LABEL
}
print "\n";

for($i=0; $i<$issueWidth-$fuNo[$typesOfFUs-1]; $i++) # All instructions except LD/ST
{
	print <<LABEL;
                   .rsr${i}Tag_i(rsr${i}Tag),
                   .rsr${i}TagValid_i(rsr${i}TagValid),	
LABEL
}
print "\n";

print <<LABEL;
                   .phyRegRdy_o(phyRegRdy),
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	$comma = ($i == $issueWidth-1)? "" : ",";
	print <<LABEL;
                   .fuPacket${i}_o(fuPacket${i}),
                   .fuPacketValid${i}_o(fuPacketValid${i})$comma
LABEL
}

print <<LABEL;
                 );
 


/************************************************************************************
* regread_execute module has the pipeline latch between register read and execute
* stage.
*
************************************************************************************/
 RegReadExecute regread_execute( .clk(clock),
                        	 .reset(reset | recoverFlag | exceptionFlag),
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
                             .fuPacket${i}_i(fuPacket${i}),
                        	 .fuPacketValid${i}_i(fuPacketValid${i}),
LABEL
}

for($i=0; $i<$issueWidth; $i++)
{
	$comma = ($i == $issueWidth-1)? "" : ",";
	print <<LABEL;
                        	 .fuPacket${i}_o(fuPacket${i}_l1),
                        	 .fuPacketValid${i}_o(fuPacketValid${i}_l1)$comma
LABEL
}

print <<LABEL;
                      	       );




/************************************************************************************
* execute module implements all the required functional units. 
*
************************************************************************************/
 Execute execute ( .clk(clock),
                   .reset(reset | recoverFlag | exceptionFlag),
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
                   .fuPacket${i}_i(fuPacket${i}_l1),
                   .fuPacketValid${i}_i(fuPacketValid${i}_l1),
LABEL
}

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
                   .bypassPacket${i}_i(bypassPacket${i}),
                   .bypassValid${i}_i(bypassValid${i}),
LABEL
}

print <<LABEL;
		   .ctrlVerified_i(ctrlConditional),
                   .ctrlMispredict_i(flagRecoverEX),
                   .ctrlSMTid_i(ctrlVerifiedSMTid),	
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	$comma = ($i == $issueWidth-1)? "" : ",";
	print <<LABEL;
                   .exePacket${i}_o(exePacket${i}),
                   .exePacketValid${i}_o(exePacketValid${i})$comma
LABEL
}

print <<LABEL;
                 );


/************************************************************************************
* writebk module writes back executed instruction to Active List. The module also
* generates bypass packets and  
*
************************************************************************************/

 WriteBack writebk ( .clk(clock),
                     .reset(reset | recoverFlag | exceptionFlag),
LABEL

for($i=0; $i<$issueWidth-$fuNo[$typesOfFUs-1]; $i++) # All instructions except LD/ST
{
	print <<LABEL;
                     .exePacket${i}_i(exePacket${i}),
                     .exePacketValid${i}_i(exePacketValid${i}),
LABEL
}

for(; $i<$issueWidth; $i++) # For LD/ST - MUST BE DONE JUST AFTER the previous for loop (without changing $i)
{
	print <<LABEL;
                     .exePacket${i}_i(),
                     .exePacketValid${i}_i(1'b0),
LABEL
}

print <<LABEL;
		     .lsuPacketValid0_i(lsuPacketValid0),
		     .lsuPacket0_i(lsuPacket0),	
		     .ldViolationPacket_i(ldViolationPacket_l1),	
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
                     .bypassPacket${i}_o(bypassPacket${i}),
                     .bypassValid${i}_o(bypassValid${i}),
LABEL
}

print <<LABEL;
		     .agenIqFreedValid0_o(agenIqFreedValid0),
		     .agenIqEntry0_o(agenIqEntry0),		

                     .ctrlVerified_o(ctrlVerified),
		     .ctrlConditional_o(ctrlConditional),	
                     .ctrlMispredict_o(flagRecoverEX),
                     .ctrlSMTid_o(ctrlVerifiedSMTid),
		     .ctrlTargetAddr_o(ctrlTargetAddr),
                     .ctrlBrDirection_o(ctrlBrDirection),
                     .ctrlCtiQueueIndex_o(ctrlCtiQueueIndex),	
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
                     .writebkValid${i}_o(writebkValid${i}),
LABEL
}

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
                     .ctrlFU${i}_o(ctrlFU${i}),
LABEL
}

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
		     .computedAddr${i}_o(computedAddr${i}),	
LABEL
}

print <<LABEL;
		     .ldViolationPacket_o(ldViolationPacket_l2)		
                   );



/************************************************************************************
* agenLsu module has the pipeline latch between Address generation unit and LSU
* stage.
*
************************************************************************************/ 
 AgenLsu agenLsu ( .clk(clock),
                   .reset(reset | recoverFlag | exceptionFlag),
		   .ctrlMispredict_i(flagRecoverEX),
                   .ctrlSMTid_i(ctrlVerifiedSMTid),
LABEL

# Assumption: Only one LD/ST way. Hence the [0]
$i = $whereFU[$typesOfFUs-1][0];
print <<LABEL;
                   // .exePacket3_i(exePacket3),
                   // .exePacketValid3_i(exePacketValid3),
                   .exePacket_i(exePacket$i),
                   .exePacketValid_i(exePacketValid$i),
LABEL

print <<LABEL;
                   .agenPacketValid0_o(agenPacketValid0),
                   .agenPacket0_o(agenPacket0)
                 );



/************************************************************************************
* "lsu" module is the pipeline stage between functional unit-3 (address generator) 
*  stage and data cache. The pipeline stage contains load-store address disambiguation
*  logic.
*
*  The module interfaces with AGEN and Writeback modules.
*
************************************************************************************/
 LSU lsu ( 	.clk(clock),
		.reset(reset | recoverFlag | exceptionFlag),
		.recoverFlag_i(recoverFlag),
           	.backEndReady_i(backEndReady_l1),            

             	.ctrlVerified_i(ctrlConditional),                     
             	.ctrlMispredict_i(flagRecoverEX),                      
             	.ctrlSMTid_i(ctrlVerifiedSMTid),  

LABEL


for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                .lsqPacket${i}_i(dispatchPacket${i}_lsq),
LABEL
}
print "\n";


print <<LABEL;
             	.commitLoad0_i(commitLoad0),                       
             	.commitStore0_i(commitStore0),                     
             	.commitLoad1_i(commitLoad1),                     
             	.commitStore1_i(commitStore1),                     
             	.commitLoad2_i(commitLoad2),                      
             	.commitStore2_i(commitStore2),                      
             	.commitLoad3_i(commitLoad3),                        
             	.commitStore3_i(commitStore3),                    

             	.agenPacketValid0_i(agenPacketValid0),
                .agenPacket0_i(agenPacket0),
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
             	.lsqId${i}_o(lsqId${i}),       
LABEL
}
print "\n";

print <<LABEL;
             	.loadQueueCnt_o(loadQueueCnt),   
             	.storeQueueCnt_o(storeQueueCnt),  

                .lsuPacketValid0_o(lsuPacketValid0),
                .lsuPacket0_o(lsuPacket0),
		.ldViolationPacket_o(ldViolationPacket_l1)
           );



/************************************************************************************
* "activeList" module is the pipeline stage between Dispatch stage and out-of-order
*  back-end. 
*  The module interfaces with Active List, Issue Queue and Load-Store Queue.
* 
************************************************************************************/

 ActiveList activeList( .clk(clock),
                        .reset(reset),
                   	.backEndReady_i(backEndReady_l1),
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                    	.alPacket${i}_i(dispatchPacket${i}_al),
LABEL
}

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
                   	.validFU${i}_i(writebkValid${i}),
			.computedAddr${i}_i(computedAddr${i}),
                    	.ctrlFU${i}_i(ctrlFU${i}),
LABEL
}

print <<LABEL;
			.ldViolationPacket_i(ldViolationPacket_l2),
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                    	.activeListId${i}_o(activeListId${i}),
LABEL
}

print <<LABEL;
                    	.activeListCnt_o(activeListCnt),

                   	.commitValid0_o(commitValid0),
                   	.commitPacket0_o(commitPacket0),
			.commitStore0_o(commitStore0),
			.commitLoad0_o(commitLoad0),
                   	.commitValid1_o(commitValid1),
                   	.commitPacket1_o(commitPacket1),
			.commitStore1_o(commitStore1),
			.commitLoad1_o(commitLoad1),
                   	.commitValid2_o(commitValid2),
                   	.commitPacket2_o(commitPacket2),
			.commitStore2_o(commitStore2),
			.commitLoad2_o(commitLoad2),
                   	.commitValid3_o(commitValid3),
                   	.commitPacket3_o(commitPacket3),
			.commitStore3_o(commitStore3),
			.commitLoad3_o(commitLoad3),

			.commitCti_o(commitCti),

                   	.recoverFlag_o(recoverFlag),
			.recoverPC_o(recoverPC),

			.exceptionFlag_o(exceptionFlag),
                   	.exceptionPC_o(exceptionPC)
                      );


/*
 RetirePipe retirepipe( .clk(clock),
                   	.reset(reset),

                   	.commitValid0_i(commitValid0),
                   	.commitPacket0_i(commitPacket0),
                   	.commitStore0_i(commitStore0),
                   	.commitLoad0_i(commitLoad0),

                   	.commitValid1_i(commitValid1),
                   	.commitPacket1_i(commitPacket1),
                   	.commitStore1_i(commitStore1),
                   	.commitLoad1_i(commitLoad1),

                   	.commitValid2_i(commitValid2),
                   	.commitPacket2_i(commitPacket2),
                   	.commitStore2_i(commitStore2),
                   	.commitLoad2_i(commitLoad2),

                   	.commitValid3_i(commitValid3),
                   	.commitPacket3_i(commitPacket3),
                   	.commitStore3_i(commitStore3),
                   	.commitLoad3_i(commitLoad3),

                   	.commitValid0_o(commitValid0_l1),
                   	.commitPacket0_o(commitPacket0_l1),
                   	.commitStore0_o(commitStore0_l1),
                   	.commitLoad0_o(commitLoad0_l1),

                   	.commitValid1_o(commitValid1_l1),
                    	.commitPacket1_o(commitPacket1_l1),
                   	.commitStore1_o(commitStore1_l1),
                   	.commitLoad1_o(commitLoad1_l1),

                   	.commitValid2_o(commitValid2_l1),
                  	.commitPacket2_o(commitPacket2_l1),
                   	.commitStore2_o(commitStore2_l1),
                   	.commitLoad2_o(commitLoad2_l1),

                   	.commitValid3_o(commitValid3_l1),
                   	.commitPacket3_o(commitPacket3_l1),
                   	.commitStore3_o(commitStore3_l1),
                   	.commitLoad3_o(commitLoad3_l1)
		     );	 
*/

/************************************************************************************
* "amt" module is the pipeline stage between Dispatch stage and out-of-order
*  back-end. 
*  The module interfaces with ActiveList Pipe, Issue Queue and Load-Store Queue.
* 
************************************************************************************/                     
 ArchMapTable amt( .clk(clock),
                   .reset(reset | exceptionFlag),

                   .commitValid0_i(commitValid0),
                   .commitValid1_i(commitValid1),
                   .commitValid2_i(commitValid2),
                   .commitValid3_i(commitValid3),
                   .amtPacket0_i(commitPacket0[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG]),
                   .amtPacket1_i(commitPacket1[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG]),
                   .amtPacket2_i(commitPacket2[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG]),
                   .amtPacket3_i(commitPacket3[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG]),

		   .releasedValid0_o(releasedValid0),
	  	   .releasedPhyMap0_o(releasedPhyMap0),			
		   .releasedValid1_o(releasedValid1),
	  	   .releasedPhyMap1_o(releasedPhyMap1),			
		   .releasedValid2_o(releasedValid2),
	  	   .releasedPhyMap2_o(releasedPhyMap2),			
		   .releasedValid3_o(releasedValid3),
	  	   .releasedPhyMap3_o(releasedPhyMap3),			

                   .recoverFlag_i(recoverFlag),
                   .recoverPacket0_o(recoverPacket0),
                   .recoverPacket1_o(recoverPacket1),
                   .recoverPacket2_o(recoverPacket2),
                   .recoverPacket3_o(recoverPacket3)
                 );
                      
                   

endmodule
LABEL


