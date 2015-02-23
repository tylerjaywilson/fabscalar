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
# Purpose: This script creates Verilog for the Issue stage.
################################################################################

my $version = "1.3";

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 7;

my $dispatchWidth = 4;
my $iqSize = 32;
my $depth = 2;
my $typesOfFUs = 4; # HARDWIRED!
my @fuNo;   # Number of execute ways of each instruction type (they are always adjacent)
my @whereFU;  # A two dimensional array with 4 rows (for each instruction type), telling which ways support that type.
my $issueWidth;
my $passTags = 0;

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
	print "Usage: perl $scriptName -w <dispatch_width> -i <IQ_entries> -d <issue_depth> -n A B C D [-m] [-v] [-h]\n";
	print "\t-w: Dispatch width\n";
	print "\t-i: Number of issue queue entires = width of select tree\n";
	print "\t-d: Degree of issue queue sub-pipelining (1, 2 or 3)\n"; 
	print "\t-n: Number of instructions of type 1 (A), type 2 (B), type 3 (C), type 4 (D)\n";
	print "\t-t: Pass destination physical register tags down the select tree\n";
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
	if(/^-w$/) 
	{
		$dispatchWidth = shift;
		$essentialCLIArgs++;
	}
	elsif(/^-i$/)
	{
		$iqSize = shift;
		$essentialCLIArgs++;
	}
	elsif(/^-d$/)
	{
		$depth = shift;
		$essentialCLIArgs++;
	}
	elsif(/^-n$/) 
	{
		for($i=0; $i<$typesOfFUs; $i++)
		{
			$fuNo[$i] = shift;
			$essentialCLIArgs++;
		}
	}	
	elsif(/^-t$/)
	{
		$passTags = 1;
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
		print "\nError: Unrecognized argument $_.\n";
		&fatalUsage();
	}
}

if($essentialCLIArgs < $minEssentialCLIArgs)
{
	print "\nError: Too few inputs\n";
	&fatalUsage();
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
$outputFileName = "IssueQueue.v";
$moduleName = "IssueQueue";

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
# Purpose: Verilog for $issueWidth wide Issue Stage pipelined into $depth stages.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

/***************************************************************************

  Assumption:  [1] $dispatchWidth-instructions can be renamed in one cycle.
               [2] There are 4-Functional Units (Integer Type) including 
                   AGEN block which is a dedicated FU for Load/Store.
                   FU0  2'b00     // Simple ALU
                   FU1  2'b01     // Complex ALU (for MULTIPLY & DIVIDE)
                   FU2  2'b10     // ALU for CONTROL Instructions
                   FU3  2'b11     // LOAD/STORE Address Generator
               [3] All the Functional Units are pipelined.

   granted packet contains following information:
    	(14) Branch mask:
	(13) Issue Queue ID:
	(12) Src Reg-1:
	(11) Src Reg-2:
	(10) LD/ST Queue ID:
	(9)  Active List ID:
	(8)  Checkpoint ID:
	(7)  Destination Reg:
	(6)  Immediate data:
	(5)  LD/ST Type:
	(4)  Opcode:
	(3)  Program Counter:
	(2)  Predicted Target Addr:
	(1)  CTI Queue ID:
	(0)  Branch Prediction:	

***************************************************************************/

LABEL


# Module header

print <<LABEL;
module IssueQueue(
	input clk,
	input reset,

	input backEndReady_i,	

LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
	input [3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
		`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+
		`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] dispatchPacket${i}_i,
LABEL
}
print "\n";

print <<LABEL;
	/*  Active List IDs */
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
	input [`SIZE_ACTIVELIST_LOG-1:0] inst${i}ALid_i,
LABEL
}
print "\n";

print <<LABEL;
	/*  LSQ entry numbers  */
LABEL


for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
	input [`SIZE_LSQ_LOG-1:0] lsqId${i}_i,
LABEL
}
print "\n";

print <<LABEL;
	/* Register File Valid bits */
	input [`SIZE_PHYSICAL_TABLE-1:0] phyRegRdy_i,

	/* Bypass tags + valid bit for LD/ST */
LABEL

$temp = $typesOfFUs-1;
for($i=0; $i<$fuNo[$temp]; $i++) # $typesOfFUs-1, the last type, is the LD/ST type
{
	print <<LABEL;
	input [`SIZE_PHYSICAL_LOG:0]  rsr$whereFU[$temp][$i]Tag_i,
LABEL
}
print "\n";

print <<LABEL;
	/* Control execution flags from the bypass path */
	input ctrlVerified_i,
	/*  if 1, there has been a mis-predict previous cycle */
	input ctrlMispredict_i,

	/* SMT id of the mispredicted branch */
	input [`CHECKPOINTS_LOG-1:0] ctrlSMTid_i,

	/* Count of Valid Issue Q Entries goes to Dispatch */
	output [`SIZE_ISSUEQ_LOG:0] cntInstIssueQ_o,

	/* Note: These have to be sent directly to the PRF (RSR
	 * broadcast to ensure ready bits are set for the PRF
	 * entries)
	 */
LABEL

$temp = $issueWidth - $fuNo[$typesOfFUs-1]; # All FUs except LD/ST
for($i=0; $i<$temp; $i++)
{
	print <<LABEL;
	output [`SIZE_PHYSICAL_LOG-1:0] rsr${i}Tag_o,
	output rsr${i}TagValid_o,
LABEL
}
print "\n";

print <<LABEL;
	/* Payload and Destination of instructions */
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	if($i == $issueWidth-1)
	{
		$comma = "";
	}
	else
	{
		$comma = ",";
	}

	print <<LABEL;
	output grantedValid${i}_o,
	output [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
		`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
		`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] grantedPacket${i}_o$comma
LABEL
}

print <<LABEL;
);

LABEL
# End of declaration of inputs and outputs

# Wires and registers for issue queue logic
print <<LABEL;
/************************************************************************************ 
*   Instantiating issue queue and payload ram for all the functional units. 
*   This is a unified structure.
*   
*   ISSUE_QUEUE Width: Src1 Reg Ready(1), Src2 Reg Ready(1)
************************************************************************************/
reg [`SIZE_ISSUEQ-1:0] SRC0_REG_VALID;
reg [`SIZE_ISSUEQ-1:0] SRC1_REG_VALID;

/************************************************************************************
*  ISSUEQ_FU: FU type of the instructions in the Issue Queue. This information is 
*	      used for selecting ready instructions for scheduling per functional
*             unit.	 	
************************************************************************************/
reg [`INST_TYPES_LOG-1:0] ISSUEQ_FU [`SIZE_ISSUEQ-1:0];

/************************************************************************************
*  BRANCH_MASK: Branch tag of the instructions in the Issue Queue, assigned during 
*	       renaming.	
*              Branch tag is used during the branch mis-prediction recovery process.
************************************************************************************/
reg [`CHECKPOINTS-1:0]   BRANCH_MASK [`SIZE_ISSUEQ-1:0];

/************************************************************************************
*  ISSUEQ_SCHEDULED: 1-bit indicating whether the issue queue entry has been issued 
*		     for execution.
************************************************************************************/
reg [`SIZE_ISSUEQ-1:0]   ISSUEQ_SCHEDULED;

/************************************************************************************
*  ISSUEQ_VALID: 1-bit indicating validity of each entry in the Issue Queue.
************************************************************************************/
reg [`SIZE_ISSUEQ-1:0]    ISSUEQ_VALID;

LABEL

if($passTags == 1)
{
print <<LABEL;
/************************************************************************************
 * 	DEST_REGS:	Used by the select tree to mux tags down so that wakeup can be
 * 	done a cycle earlier. It also contains the valid bit (the 0th bit)
 * 	Written into when writing into payload RAM
 * 	Every entry is read every cycle by the select tree 
 ***********************************************************************************/
reg [`SIZE_PHYSICAL_LOG:0] DEST_REGS [`SIZE_ISSUEQ-1:0];

LABEL
}

print <<LABEL;
/***********************************************************************************/

/* Wire & Regs definition for the combinational logic. */
LABEL

for($i=0; $i<$issueWidth; $i++)
{	
	print "wire freedValid$i;\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{	
	print "wire [`SIZE_ISSUEQ_LOG-1:0] freedEntry$i;\n";
}
print "\n";

print "/* Issue queue entries popped from the freeList */\n";
for($i=0; $i<$dispatchWidth; $i++)
{	
	print "wire [`SIZE_ISSUEQ_LOG-1:0] freeEntry$i;\n";
}
print "\n";

print <<LABEL;
reg [`SIZE_ISSUEQ-1:0] issueqValid_normal;
reg [`SIZE_ISSUEQ-1:0] issueqValid_mispre;
reg [`SIZE_ISSUEQ-1:0] freedValid_mispre;

reg [`SIZE_ISSUEQ-1:0] issueqSchedule_normal;

LABEL

print "/* instSource is used to extract source registers from the dispatched instruction. */\n";
for($i=0; $i<$dispatchWidth; $i++)
{	
	print "reg [`SIZE_PHYSICAL_LOG:0] inst${i}Source1;\n";
	print "reg [`SIZE_PHYSICAL_LOG:0] inst${i}Source2;\n";
}
print "\n";

if($passTags == 1)
{
	print <<LABEL;
/* instDest is used to extract the destination register of the dispatched
 * instruction. The valid bit is the 0th bit.
 */
LABEL

	for($i=0; $i<$dispatchWidth; $i++)
	{
		print <<LABEL;
reg [`SIZE_PHYSICAL_LOG:0] inst${i}Dest;
LABEL
	}
	print "\n";
}

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "reg [`CHECKPOINTS-1:0] branch${i}mask;\n";
}
print "reg [`CHECKPOINTS-1:0] update_mask;\n\n";

print "/* newInsReady is used to store ready bit computed on the dispatched instruction. */\n";
for($i=0; $i<$dispatchWidth; $i++)
{	
	print "reg newInsReady${i}1;\n";
	print "reg newInsReady${i}2;\n";
}
print "\n";

print <<LABEL;
/* Wires to handle next SRC0_REG_VALID and SRC1_REG_VALID bits */
wire [`SIZE_ISSUEQ-1:0] src0RegValid_t0;
wire [`SIZE_ISSUEQ-1:0] src1RegValid_t0;
reg [`SIZE_ISSUEQ-1:0] src0RegValid_t1;
reg [`SIZE_ISSUEQ-1:0] src1RegValid_t1;

LABEL

for($i=0; $i<$typesOfFUs; $i++)
{	
	print "reg [`SIZE_ISSUEQ-1:0] requestVector${i};\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{	
	print "wire grantedValid${i};\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{	
	print "wire [`SIZE_ISSUEQ_LOG-1:0] grantedEntry${i};\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{	
	print "wire grantedValid${i}_t;\n";
}
print "\n";

if($passTags != 1)
{
	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
	wire [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
		`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
		`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] grantedPacket${i}_t;
LABEL
	}
	print "\n";
}

if($passTags == 1)
{
	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
wire [`SIZE_PHYSICAL_LOG:0] grantedTag${i};
LABEL
	}
	print "\n";
}

print "`ifdef VERIFY\n";
for($i=0; $i<$issueWidth; $i++)
{	
	print "wire [`SIZE_PC-1:0] grantedPC", $i, ";\n";
}
print "`endif\n\n";


$temp = $issueWidth - $fuNo[$typesOfFUs-1]; # All FUs except LD/ST
for($i=0; $i<$temp; $i++)
{
	print <<LABEL;
wire freedValid${i}2;
LABEL
}
print "\n";

$temp = $issueWidth - $fuNo[$typesOfFUs-1]; # All FUs except LD/ST
for($i=0; $i<$temp; $i++)
{
	print <<LABEL;
wire [`SIZE_ISSUEQ_LOG-1:0] freedEntry${i}2;
LABEL
}
print "\n";

$temp = $issueWidth - $fuNo[$typesOfFUs-1]; # All FUs except LD/ST
for($i=0; $i<$temp; $i++)
{
	print <<LABEL;
wire [`SIZE_PHYSICAL_LOG-1:0] rsr${i}Tag;
wire rsr${i}TagValid;
LABEL
}
print "\n";

$temp = $issueWidth - $fuNo[$typesOfFUs-1]; # All FUs except LD/ST
for($i=0; $i<$temp; $i++)
{
	print <<LABEL;
wire [`SIZE_PHYSICAL_LOG-1:0] granted${i}Dest;
LABEL
}
print "\n";

$temp = $issueWidth - $fuNo[$typesOfFUs-1]; # All FUs except LD/ST
for($i=0; $i<$temp; $i++)
{
	print <<LABEL;
wire [`SIZE_ISSUEQ_LOG-1:0] granted${i}Entry;
LABEL
}
print "\n";

print <<LABEL;
/* Wires to "alias" the RSR + valid bit*/
LABEL

$temp = $issueWidth - $fuNo[$typesOfFUs-1]; # All FUs except LD/ST
for($i=0; $i<$temp; $i++)
{
	print <<LABEL;
wire [`SIZE_PHYSICAL_LOG:0]  rsr${i}Tag_t;
LABEL
}
print "\n";

print <<LABEL;
/* Wires for Issue Queue Payload RAM */
`define SIZE_PAYLOAD_WIDTH (2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1)

LABEL

if($passTags != 1)
{
	for($i=0; $i<$issueWidth; $i++)
	{	
		print "wire [`SIZE_PAYLOAD_WIDTH-1:0] payloadRAMData", $i, ";\n";
	}
	print "\n";
}

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "wire payloadRAMwe", $i, ";\n";
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "wire [`SIZE_PAYLOAD_WIDTH-1:0] payloadRAMDataWr", $i, ";\n";
}
print "\n";

print "/* Wires for wakeup CAM */\n";

for($i=0; $i<$issueWidth; $i++)
{	
	print "wire [`SIZE_ISSUEQ-1:0] src0_matchLines", $i, ";\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{	
	print "wire [`SIZE_ISSUEQ-1:0] src1_matchLines", $i, ";\n";
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "wire CAM0we", $i, ";\n";
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "wire CAM1we", $i, ";\n";
}
print "\n";


# Build, if necessary, a pipe register between select and payload
if($passTags == 1)
{

	print <<LABEL;
/****************************************************
 * THE PIPELINE STAGE IN BETWEEN SELECT AND PAYLOAD
 ***************************************************/

/* Wires to create the packet from the select pipeline stage */
LABEL

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
wire [`CHECKPOINTS+`SIZE_ISSUEQ_LOG-1:0] selectPacket$i;
LABEL
	}
	print "\n";

	print "/* Same as grantedValid_t - kept here for ease */\n";
	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
wire selectValid$i;
LABEL
	}
	print "\n";

	print <<LABEL;
/* The actual pipeline register */
LABEL


	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
reg [`CHECKPOINTS+`SIZE_ISSUEQ_LOG-1:0] selectPacket${i}_preg;
LABEL
	}
	print "\n";

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
reg selectValid${i}_preg;
LABEL
	}
	print "\n";


	print <<LABEL;
/* Wires to strip the branch mask off the select/payload pipeline register */
LABEL

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
wire [`CHECKPOINTS-1:0] payloadBranchMask${i}_t;
LABEL
	}
	print "\n";

	print <<LABEL;
/* This contains the grantedEntry stripped from the packet */
LABEL

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
wire [`SIZE_ISSUEQ_LOG-1:0] payloadGrantedEntry${i}_t;
LABEL
	}
	print "\n";

	print <<LABEL;
/* Wires for the actual payload read out of the payload RAM */
LABEL

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
wire [2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
	`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] payload${i}_t;
LABEL
	}
	print "\n";

	print <<LABEL;
/* Wires for the payload packet */
LABEL

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
wire [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
	`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
	`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] payloadPacket$i;
LABEL
	}
	print "\n";


	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
wire payloadValid${i};
LABEL
	}
	print "\n";

	print <<LABEL;
/* Wires to generate the updated branch mask for the payload packet */
LABEL

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
reg [`CHECKPOINTS-1:0] payloadBranchMask${i}_updated;
LABEL
	}
	print "\n";

	print <<LABEL;
/* Create the packet from the select pipeline stage */
LABEL

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
assign selectValid$i  = grantedValid$i && ~(ctrlMispredict_i && BRANCH_MASK[grantedEntry$i][ctrlSMTid_i]);
LABEL
	}
	print "\n";

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
assign selectPacket$i = {BRANCH_MASK[grantedEntry$i], grantedEntry$i};
LABEL
	}
	print "\n";

	print <<LABEL;
/* Put the created packet into the select/payload pipeline register */
always @(posedge clk)
begin: SELECT_PAYLOAD_PIPELINE_REGISTER
	if(reset)
	begin
LABEL

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
		selectPacket${i}_preg <= 0;
LABEL
	}
	print "\n";

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
		selectValid${i}_preg <= 0;
LABEL
	}

	print <<LABEL;
	end
	else
	begin
LABEL

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
		selectPacket${i}_preg <= selectPacket${i};
LABEL
	}
	print "\n";

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
		selectValid${i}_preg <= selectValid${i};
LABEL
	}

	print <<LABEL;
	end
end

LABEL

	print <<LABEL;
/* Strip the values from the pipe register */
LABEL

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
assign payloadBranchMask${i}_t = selectPacket${i}_preg[`CHECKPOINTS+`SIZE_ISSUEQ_LOG-1 : `SIZE_ISSUEQ_LOG];
LABEL
	}
	print "\n";

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
assign payloadGrantedEntry${i}_t = selectPacket${i}_preg[`SIZE_ISSUEQ_LOG-1:0];
LABEL
	}
	print "\n";

	print <<LABEL;
/* Update the branch mask */
always @(*)
begin: UPDATE_PAYLOAD_BRANCH_MASK
LABEL
	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
	payloadBranchMask${i}_updated = payloadBranchMask${i}_t;
LABEL
	}
	print "\n";

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
	if(ctrlVerified_i && ~ctrlMispredict_i && payloadBranchMask${i}_t[ctrlSMTid_i] == 1'b1)
		payloadBranchMask${i}_updated[ctrlSMTid_i] = 1'b0;
LABEL
	}

	print <<LABEL;
end

LABEL

	print <<LABEL;
/* Create payload packet using updated branch mask and read payload */
LABEL

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
assign payloadPacket${i} = {payloadBranchMask${i}_updated, payloadGrantedEntry${i}_t, payload${i}_t};
LABEL
	}
	print "\n";

	for($i=0; $i<$issueWidth; $i++)
	{
		print <<LABEL;
assign payloadValid${i} = selectValid${i}_preg && ~(ctrlMispredict_i && payloadBranchMask${i}_t[ctrlSMTid_i]);
LABEL
	}
	print "\n";

	print <<LABEL;
/***********************************************************
 * END OF THE PIPELINE STAGE IN BETWEEN SELECT AND PAYLOAD
 ***********************************************************/

LABEL

}

print <<LABEL;
/* Correctly "alias" rsr0Tag_t */
LABEL

$temp = $issueWidth - $fuNo[$typesOfFUs-1];
for($i=0; $i<$temp; $i++)
{
	print <<LABEL;
assign rsr${i}Tag_t = {rsr${i}Tag, rsr${i}TagValid};
LABEL
}
print "\n";

print <<LABEL;
/* Assign to output the rsrTags */
LABEL

$temp = $issueWidth - $fuNo[$typesOfFUs-1];
for($i=0; $i<$temp; $i++)
{
	print <<LABEL;
assign rsr${i}TagValid_o = rsr${i}TagValid;
LABEL
}
print "\n";

$temp = $issueWidth - $fuNo[$typesOfFUs-1];
for($i=0; $i<$temp; $i++)
{
	print <<LABEL;
assign rsr${i}Tag_o = rsr${i}Tag;
LABEL
}
print "\n";

print <<LABEL;
/************************************************************************************
* ISSUEQ_PAYLOAD: Has all the necessary information required by function unit to 
		  execute the instruction. Implemented as payloadRAM
	       (Source registers, LD/ST queue ID, Active List ID, Shadow Map ID, Destination register, 
		   Immediate data, LD/ST data size, Opcode, Program counter, Predicted
		   Target Address, Ctiq Tag, Predicted Branch direction)	  
************************************************************************************/
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "assign payloadRAMwe", $i, " = backEndReady_i && ~(ctrlVerified_i && ctrlMispredict_i);\n";
}
print "\n";


for($i=0; $i<$dispatchWidth; $i++)
{	
	print "assign payloadRAMDataWr${i} = {inst${i}Source2[`SIZE_PHYSICAL_LOG:1],inst${i}Source1[`SIZE_PHYSICAL_LOG:1],
\tlsqId${i}_i,inst${i}ALid_i,
\tdispatchPacket${i}_i[`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
\t`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+
\t2*`SIZE_PC+`SIZE_CTI_LOG:4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
\t`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
\tdispatchPacket${i}_i[3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+
\t`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
\t`SIZE_CTI_LOG:1+2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+
\t`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
\tdispatchPacket${i}_i[`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+
\t`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:1+`LDST_TYPES_LOG+`INST_TYPES_LOG+
\t`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
\tdispatchPacket${i}_i[`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
\t`SIZE_CTI_LOG:`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
\tdispatchPacket${i}_i[`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0]};\n\n";
}
print "\n";

# Instantiate the payload RAM
print "SRAM_${issueWidth}R${dispatchWidth}W_PAYLOAD #(`SIZE_ISSUEQ,`SIZE_ISSUEQ_LOG,`SIZE_PAYLOAD_WIDTH) payloadRAM(.clk(clk),\n";
print "\t.reset(reset),\n";

for($i=0; $i<$issueWidth; $i++)
{
	if($passTags != 1)
	{
		print "\t.addr", $i, "_i(grantedEntry", $i, "),\n";
	}
	elsif($passTags == 1)
	{
		print "\t.addr", $i, "_i(payloadGrantedEntry${i}_t),\n";
	}
}

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "\t.addr", $i, "wr_i(freeEntry", $i, "),\n";
}

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "\t.we", $i, "_i(payloadRAMwe", $i, "),\n";
}

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "\t.data", $i, "wr_i(payloadRAMDataWr", $i, "),\n";
}

for($i=0; $i<$issueWidth; $i++)
{
	if($passTags != 1)
	{
		print "\t.data", $i, "_o(payloadRAMData", $i, ")";
	}
	elsif($passTags == 1)
	{
		print "\t.data", $i, "_o(payload${i}_t)";
	}
	if($i != $issueWidth-1)
	{
		print ",";
	}

	print "\n";	
}


print ");\n\n";

print <<LABEL;
/************************************************************************************
* WAKEUP CAM: Has the source physical registers that try to match tags broadcasted by the RSR
************************************************************************************/
LABEL

print "assign src0RegValid_t0 = ISSUEQ_VALID & (~ISSUEQ_SCHEDULED) & (SRC0_REG_VALID | ";
for($i=0; $i<$issueWidth; $i++)
{	
	print "src0_matchLines", $i;
	
	if($i == $issueWidth-1)
	{
		print ");\n";
	}
	else
	{
		print " | ";
	}
}

print "assign src1RegValid_t0 = ISSUEQ_VALID & (~ISSUEQ_SCHEDULED) & (SRC1_REG_VALID | ";
for($i=0; $i<$issueWidth; $i++)
{	
	print "src1_matchLines", $i;
	
	if($i == $issueWidth-1)
	{
		print ");\n";
	}
	else
	{
		print " | ";
	}
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "assign CAM0we", $i, " = backEndReady_i && ~(ctrlVerified_i && ctrlMispredict_i);\n";
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "assign CAM1we", $i, " = backEndReady_i && ~(ctrlVerified_i && ctrlMispredict_i);\n";
}
print "\n";

print "/* Instantiate the CAM for the 2nd source operand */\n";
print "CAM_${issueWidth}R${dispatchWidth}W #(`SIZE_ISSUEQ,`SIZE_ISSUEQ_LOG, `SIZE_PHYSICAL_LOG) src1cam (.clk(clk),\n";
print "\t.reset(reset),\n";

for($i=0; $i<$issueWidth; $i++)
{	
	if($i < $issueWidth-$fuNo[$typesOfFUs-1]) # Non LD/ST guys get rsr from RSR module
	{
		$temp = "_t";
	}
	else # LD/ST guys get rsr from WB stage, hence input to this module
	{
		$temp = "_i";
	}

	print "\t.tag", $i, "_i(rsr", $i, "Tag${temp}\[`SIZE_PHYSICAL_LOG:1]),\n";
}

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "\t.addr", $i, "wr_i(freeEntry", $i, "),\n";
}

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "\t.we", $i, "_i(CAM1we", $i, "),\n";
}

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "\t.tag", $i, "wr_i(inst", $i, "Source2[`SIZE_PHYSICAL_LOG:1]),\n";
}

for($i=0; $i<$issueWidth; $i++)
{	
	print "\t.match", $i, "_o(src1_matchLines", $i, ")";

	if($i != $issueWidth-1)
	{
		print ",";
	}

	print "\n";	
}

print ");\n\n";


print "/* Instantiate the CAM for the 1st source operand */\n";
print "CAM_${issueWidth}R${dispatchWidth}W #(`SIZE_ISSUEQ,`SIZE_ISSUEQ_LOG, `SIZE_PHYSICAL_LOG) src0cam (.clk(clk),\n";
print "\t.reset(reset),\n";

for($i=0; $i<$issueWidth; $i++)
{	
	if($i < $issueWidth-$fuNo[$typesOfFUs-1]) # Non LD/ST guys get rsr from RSR module
	{
		$temp = "_t";
	}
	else # LD/ST guys get rsr from WB stage, hence input to this module
	{
		$temp = "_i";
	}

	print "\t.tag", $i, "_i(rsr", $i, "Tag${temp}\[`SIZE_PHYSICAL_LOG:1]),\n";
}

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "\t.addr", $i, "wr_i(freeEntry", $i, "),\n";
}

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "\t.we", $i, "_i(CAM0we", $i, "),\n";
}

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "\t.tag", $i, "wr_i(inst", $i, "Source1[`SIZE_PHYSICAL_LOG:1]),\n";
}

for($i=0; $i<$issueWidth; $i++)
{	
	print "\t.match", $i, "_o(src0_matchLines", $i, ")";

	if($i != $issueWidth-1)
	{
		print ",";
	}

	print "\n";	
}

print ");\n\n";

print <<LABEL;
/************************************************************************************ 
* Instantiate the Issue Queue Free List. 
* Issue queue free list is a circular buffer and keeps tracks of free entries.  
************************************************************************************/
LABEL

print "IssueQFreeList issueQfreelist(.clk(clk),\n";
print "\t.reset(reset),\n";
print "\t.ctrlVerified_i(ctrlVerified_i),\n";
print "\t.ctrlMispredict_i(ctrlMispredict_i),\n";
print "\t.mispredictVector_i(freedValid_mispre),\n";
print "\t.backEndReady_i(backEndReady_i),\n";
print "\t/* 4 entries being freed once they have been executed. */\n";

for($i=0; $i<$issueWidth; $i++)
{	
	print "\t.grantedEntry", $i, "_i(grantedEntry", $i, "),\n";
}

for($i=0; $i<$issueWidth; $i++)
{	
	print "\t.grantedValid", $i, "_i(grantedValid", $i, "_t),\n";
}

for($i=0; $i<$issueWidth; $i++)
{	
	print "\t.freedEntry", $i, "_o(freedEntry", $i, "),\n";
}

for($i=0; $i<$issueWidth; $i++)
{	
	print "\t.freedValid", $i, "_o(freedValid", $i, "),\n";
}

print "\t/* 4 free Issue Queue entries for the new coming instructions. */\n";

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "\t.freeEntry", $i, "_o(freeEntry", $i, "),\n";
}

print "\t/* Count of Valid Issue Q Entries goes to Dispatch */\n";
print "\t.cntInstIssueQ_o(cntInstIssueQ_o)\n";

print ");\n\n";

print <<LABEL;
/************************************************************************************ 
*   If the Issue Queue enrtry has been granted execution then the Instruction
*   Payload and Destination Tags should be pushed down the pipeline with proper
*   valid bit set.
*   
*   Granted Valid is also checked for any branch misprediction this cycles. So
*   that instruction from the wrong path is not issued for execution.
************************************************************************************/
LABEL

for($i=0; $i<$issueWidth; $i++)
{	
	print "assign grantedValid", $i, "_t  = grantedValid", $i, " && ~(ctrlMispredict_i && BRANCH_MASK[grantedEntry", $i, "][ctrlSMTid_i]);\n";
}
print "\n";

if($passTags != 1)
{
	for($i=0; $i<$issueWidth; $i++)
	{	
		print "assign grantedPacket${i}_t = {BRANCH_MASK[grantedEntry", $i, "], grantedEntry", $i, ", payloadRAMData", $i, "};\n";
	}
	print "\n";
}

if($passTags != 1)
{
	for($i=0; $i<$issueWidth; $i++)
	{	
		print "assign grantedValid", $i, "_o  = grantedValid", $i, "_t;\n";
	}
	print "\n";

	for($i=0; $i<$issueWidth; $i++)
	{	
		print "assign grantedPacket", $i, "_o  = grantedPacket", $i, "_t;\n";
	}
	print "\n";

	print "`ifdef VERIFY\n";
	for($i=0; $i<$issueWidth; $i++)
	{	
		print "assign grantedPC", $i, " = grantedPacket", $i, "_t[`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1];\n";
	}
	print "`endif\n\n";
}
elsif($passTags == 1)
{
	for($i=0; $i<$issueWidth; $i++)
	{	
		print "assign grantedValid", $i, "_o  = payloadValid", $i, ";\n";
	}
	print "\n";

	for($i=0; $i<$issueWidth; $i++)
	{	
		print "assign grantedPacket", $i, "_o  = payloadPacket", $i, ";\n";
	}
	print "\n";

	print "`ifdef VERIFY\n";
	for($i=0; $i<$issueWidth; $i++)
	{	
		print "assign grantedPC", $i, " = payloadPacket${i}\[`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1];\n";
	}
	print "`endif\n\n";
}

print <<LABEL;
/************************************************************************************ 
*  Logic to check new instructions source operand Ready for dispached 
*  instruction from rename stage. 
************************************************************************************/
always @(*)
begin:CHECK_NEW_INSTS_SOURCE_OPERAND

	/* Extracting source registers and branch mask from the dispatched packet */
LABEL


for($i=0; $i<$dispatchWidth; $i++)
{	
	print "\tinst", $i, "Source1 = dispatchPacket", $i, "_i[`SIZE_PHYSICAL_LOG+1+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+\n";
	print "\t\t`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_IMMEDIATE+1+\n";
	print "\t\t`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];\n\n";

	print "\tinst", $i, "Source2 = dispatchPacket", $i, "_i[2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+\n";
	print "\t\t`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PHYSICAL_LOG+1+\n";
	print "\t\t`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+\n";
	print "\t\t`SIZE_CTI_LOG+1];\n\n";
}

if($passTags == 1)
{
	for($i=0; $i<$dispatchWidth; $i++)
	{
		print <<LABEL;
	inst${i}Dest = dispatchPacket${i}_i[3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+
		`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG  :  2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+
		`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
LABEL
	}
	print "\n";
}

for($i=0; $i<$dispatchWidth; $i++)
{
	print "\tbranch", $i, "mask = dispatchPacket", $i, "_i[`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+\n";
	print "\t\t`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:\n";
	print "\t\t`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+\n";
	print "\t\t`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];\n\n";
}

print <<LABEL;
	/************************************************************************************ 
	 * Index into the Physical Register File valid bit vector to check if the source operand 
	 * is ready, or check the broadcasted RSR tags if there is any match to set the ready bit.
	 * This is the common "If reading a location being written into this cycle, bypass the 
	 * 'being written into' value instead of reading the currently stored value" logic.
	************************************************************************************/
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print "\tnewInsReady", $i, "1 = (phyRegRdy_i[inst", $i, "Source1[`SIZE_PHYSICAL_LOG:1]] ||\n";
	
	print "\t\t";
	for($j=0; $j<$issueWidth; $j++)
	{
		if($j < $issueWidth-$fuNo[$typesOfFUs-1]) # Non LD/ST guys get rsr from RSR module
		{
			$temp = "_t";
		}
		else
		{
			$temp = "_i";
		}

		print "(inst", $i, "Source1 == rsr", $j, "Tag$temp)";
		if($j == $issueWidth-1)
		{
			print "\n\t\t || ~inst", $i, "Source1[0]) ? 1'b1:0;\n\n";
		}
		else
		{
			print " || ";
		}
	}

	print "\tnewInsReady", $i, "2 = (phyRegRdy_i[inst", $i, "Source2[`SIZE_PHYSICAL_LOG:1]] ||\n";
	
	print "\t\t";
	for($j=0; $j<$issueWidth; $j++)
	{
		if($j < $issueWidth-$fuNo[$typesOfFUs-1]) # Non LD/ST guys get rsr from RSR module
		{
			$temp = "_t";
		}
		else
		{
			$temp = "_i";
		}

		print "(inst", $i, "Source2 == rsr", $j, "Tag$temp)";
		if($j == $issueWidth-1)
		{
			print "\n\t\t || ~inst", $i, "Source2[0]) ? 1'b1:0;\n\n";
		}
		else
		{
			print " || ";
		}
	}
}

print "end\n\n";


print <<LABEL;
/************************************************************************************ 
 * Generate the update_mask vector to unset the SMT id bit in the BRANCH MASK table.
************************************************************************************/
always @(*)
begin: UPDATE_BRANCH_MASK
	integer k;
 
	for(k=0; k<`CHECKPOINTS; k=k+1)
	begin
		if(ctrlVerified_i && (k==ctrlSMTid_i))
			update_mask[k] = 1'b0;
		else
			update_mask[k] = 1'b1;
	end
end


LABEL

print <<LABEL;
/************************************************************************************ 
* Following updates the Ready bit in the Issue Queue after matching bypassed Tags 
* from RSR.
* Each source's physical tag compares with the 4 bypassed tags to set its Ready bit
*
* On a mispredict, SRC0_REG_VALID and SRC1_REG_VALID arrays must not be affected by the
* dispatch instructions. When not a mispredict, next_src0Ready_normal is the same as
* next_src0Rea_mispre, except that bits of the dispatched instructions are updated
************************************************************************************/
LABEL

print <<LABEL;
always @(*)
begin: UPDATE_SRC_READY_BIT
	integer i;
	integer j;

	src0RegValid_t1 = 0; 
	src1RegValid_t1 = 0;

LABEL

print <<LABEL;
	for(j=0;j<`SIZE_ISSUEQ;j=j+1)
	begin
LABEL

print "\t\t";
for($i=0; $i<$dispatchWidth; $i++)
{
	print "if(backEndReady_i && (j == freeEntry", $i, "))\n";
	print "\t\tbegin\n";
	print "\t\t\tsrc0RegValid_t1[j]  =  newInsReady", $i, "1;\n";
	print "\t\t\tsrc1RegValid_t1[j]  =  newInsReady", $i, "2;\n";
	print "\t\tend\n";
	print "\t\telse "; 
}
print "\n"; 

print <<LABEL;
		begin
			src0RegValid_t1[j]  =  src0RegValid_t0[j];
			src1RegValid_t1[j]  =  src1RegValid_t0[j];
		end
	end
end

LABEL

print <<LABEL;
/************************************************************************************
* Logic to prepare Issue Queue valid array for next cycle during the normal 
* operation, i.e. there is no branch mis-prediction or exception this cycle.
* [i] New Entry position should be set to 1
* [ii] Freed Entry should be set to 0
************************************************************************************/
LABEL

print <<LABEL;
always @(*)
begin: PREPARE_VALID_ARRAY_NORMAL
	integer i;
	integer k;
	
	reg [`SIZE_ISSUEQ-1:0] issueqValid_tmp;

	issueqValid_tmp     = 0;
	issueqValid_normal  = 0;

	for(i=0; i<`SIZE_ISSUEQ; i=i+1)
	begin
LABEL

print "\t\tif(backEndReady_i && (";
for($i=0; $i<$dispatchWidth; $i++)
{
	print "(i == freeEntry", $i, ")";
	if($i == $dispatchWidth-1)
	{
		print "))\n";
	}
	else
	{
		print " || ";
	}
}

print "\t\t\tissueqValid_tmp[i] = 1'b1;\n";
print "\t\telse\n";
print "\t\t\tissueqValid_tmp[i] = ISSUEQ_VALID[i];\n";
print "\tend\n\n";

print "\tfor(k=0; k<`SIZE_ISSUEQ; k=k+1)\n";
print "\tbegin\n";
print "\t\tif(";

for($i=0; $i<$issueWidth; $i++)
{
	print "(freedValid", $i, " && k == freedEntry", $i, ")";
	if($i == $issueWidth-1)
	{
		print ")\n";
	}
	else
	{
		print " || ";
	}
}

print <<LABEL;
			issueqValid_normal[k] = 1'b0;
		else
			issueqValid_normal[k] = issueqValid_tmp[k];
	end
end

LABEL

print <<LABEL;
/************************************************************************************
* Logic to prepare Issue Queue valid array for next cycle during mis-prediction
* operation.
************************************************************************************/
always @(*)
begin: PREPARE_VALID_ARRAY_MISPRED
	integer i;
	integer k;
	reg [`SIZE_ISSUEQ-1:0] issueqValid_t;

	issueqValid_mispre = 0;
	freedValid_mispre  = 0;

	/* Unset the valid bit of the entries being freed this cycle. */
	for(k=0; k<`SIZE_ISSUEQ; k=k+1)
	begin
LABEL

print "\t\tif(";
for($i=0; $i<$issueWidth; $i++)
{
	print "(freedValid", $i, " && k == freedEntry", $i, ")";
	if($i == $issueWidth-1)
	{
		print ")\n";
	}
	else
	{
		print " || ";
	}
}

print <<LABEL;
			issueqValid_t[k] = 1'b0;
		else
			issueqValid_t[k] = ISSUEQ_VALID[k];
	end

LABEL

print <<LABEL;
	for(i=0; i<`SIZE_ISSUEQ; i=i+1)
	begin
		if(ctrlVerified_i && ctrlMispredict_i)    /* Unnecessary logic? */
		begin
			if(BRANCH_MASK[i][ctrlSMTid_i])
			begin
				issueqValid_mispre[i] = 1'b0;
				if(ISSUEQ_VALID[i]) 
					freedValid_mispre[i]  = 1'b1;
			end
			else
				issueqValid_mispre[i] = issueqValid_t[i];
		end
	end
end

LABEL

print <<LABEL;
/************************************************************************************
* Logic to prepare Issue Queue scheduled array for next cycle during the normal
* operation, i.e. there is no branch mis-prediction or exception this cycle.
*	[i]  New Entry position should be set to 0
*	[ii] Granted Entry position should be set 1 
************************************************************************************/
LABEL

print <<LABEL;
always @(*)
begin: PREPARE_SCHEDULE_ARRAY
	integer i;
	reg [`SIZE_ISSUEQ-1:0] issueqSchedule_tmp;	

	issueqSchedule_tmp     = 0;
	issueqSchedule_normal  = 0;

	for(i=0; i<`SIZE_ISSUEQ; i=i+1)
	begin
LABEL

print "\t\tif(backEndReady_i && (";

for($i=0; $i<$dispatchWidth; $i++)
{
	print "(i == freeEntry", $i, ")";
	if($i == $dispatchWidth-1)
	{
		print "))\n";
	}
	else
	{
		print " || ";
	}
}

print <<LABEL;
			issueqSchedule_tmp[i] = 1'b0;
		else
			issueqSchedule_tmp[i] = ISSUEQ_SCHEDULED[i];
	end

	for(i=0; i<`SIZE_ISSUEQ; i=i+1)
	begin
LABEL

print "\t\tif(";

for($i=0; $i<$issueWidth; $i++)
{
	print "(grantedValid", $i, "_t && i == grantedEntry", $i, ")";
	if($i == $issueWidth-1)
	{
		print ")\n";
	}
	else
	{
		print " || ";
	}
}

print <<LABEL;
			issueqSchedule_normal[i] = 1'b1;
		else
			issueqSchedule_normal[i] = issueqSchedule_tmp[i];
	end
end

LABEL

print <<LABEL;
/************************************************************************************
*  Update ISSUEQ_VALID and ISSUEQ_SCHEDULED array every cycle. Update is based on
*  the either normal execution or branch mis-prediction.
************************************************************************************/
always @(posedge clk)
begin
	if(reset)
	begin
		ISSUEQ_VALID <= 0;
		ISSUEQ_SCHEDULED <= 0;
	end 
	else
	begin
		if(ctrlVerified_i && ctrlMispredict_i)
		begin
			ISSUEQ_VALID <= issueqValid_mispre;
		end
		else
		begin
			ISSUEQ_VALID <= issueqValid_normal;
		end
	
		ISSUEQ_SCHEDULED <= issueqSchedule_normal;
	end
end

LABEL

print <<LABEL;
/************************************************************************************
* Writing new instruction into Issue Queue (payload already taken care of by the RAM)
* Write to Issue Queue is made only if backEndReady (from the dispatch) is high 
* and there is no control mis-predict. 
************************************************************************************/
always @(posedge clk)
begin: newInstructions
	integer i;

	if(reset)
	begin
		for(i=0;i<`SIZE_ISSUEQ;i=i+1)
		begin
			ISSUEQ_FU[i] <= 0;
LABEL

if($passTags == 1)
{
	print <<LABEL;
			DEST_REGS[i] <= 0;
LABEL
}

print <<LABEL;
		end
	end
	else
	begin
		if(backEndReady_i && ~(ctrlVerified_i && ctrlMispredict_i))
		begin
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{	
	print "\t\t\tISSUEQ_FU[freeEntry", $i, "] <= dispatchPacket", $i, "_i[`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+\n";
	print "\t\t\t\t`SIZE_CTI_LOG:`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];\n";

	if($passTags == 1)
	{
		print "\t\t\tDEST_REGS[freeEntry$i] <= inst${i}Dest;\n\n";
	}
}
print "\t\tend\n\n";

print "\t\t`ifdef VERIFY\n";
for($i=0; $i<$issueWidth; $i++)
{
	print "\t\tif(freedValid", $i, ")\n"; 
	print "\t\tbegin\n";
	print "\t\t\tISSUEQ_FU[freedEntry", $i, "] <= 0;\n";	
	print "\t\tend\n";
	
	if($i != $issueWidth-1)
	{
		print "\n";
	}
}
print "\t\t`endif\n";

print "\tend\n";
print "end\n\n";


print <<LABEL;
/************************************************************************************ 
* Update the branch mask table every cycle with the new incominig instruction and
* also update it if a branch resolves correctly.
************************************************************************************/ 
always @(posedge clk)
begin:UPDATE_BRANCH_MASK_POSEDGE_CLK
	integer l;

	if(reset)
	begin
		for(l=0; l<`SIZE_ISSUEQ; l=l+1)
		begin
			BRANCH_MASK[l] <= 0;
		end
	end
	else
	begin
		for(l=0;l<`SIZE_ISSUEQ;l=l+1)
		begin
LABEL

print "\t\t\t";
for($i=0; $i<$dispatchWidth; $i++)
{
	print "if(backEndReady_i && (l == freeEntry", $i, "))\n";
	print "\t\t\tbegin\n";
	print "\t\t\t\tBRANCH_MASK[l] <= branch", $i, "mask;\n";
	print "\t\t\tend\n";
	
	if($i != $dispatchWidth-1)
	{
		print "\t\t\telse "; 
	}
}

print "\t\t\t`ifdef VERIFY\n";
print "\t\t\t else if(";

for($i=0; $i<$issueWidth; $i++)
{
	print "(freedValid", $i, " && (l == freedEntry", $i, "))";
	if($i == $issueWidth-1)
	{
		print ")\n";
	}
	else
	{
		print " || ";
	}
}

print "\t\t\t\tBRANCH_MASK[l] <= 0;\n";
print "\t\t\t`endif\n";

print <<LABEL;
			else
				BRANCH_MASK[l] <= BRANCH_MASK[l] & update_mask;
		end
	end
end

LABEL

print <<LABEL;
/************************************************************************************
*  Update SRC0_REG_VALID and SRC1_REG_VALID based on rsrTag match. 
*  Update is based on the either normal execution or branch mis-prediction.
************************************************************************************/
always @(posedge clk)
begin
	if(reset)
	begin
		SRC0_REG_VALID  <= 0;
		SRC1_REG_VALID  <= 0;
	end
	else if(ctrlVerified_i && ctrlMispredict_i)
	begin
		SRC0_REG_VALID  <= src0RegValid_t0;
		SRC1_REG_VALID  <= src1RegValid_t0;
	end
	else
	begin	
		SRC0_REG_VALID  <= src0RegValid_t1;
		SRC1_REG_VALID  <= src1RegValid_t1;	
	end
end

LABEL


print <<LABEL;
/************************************************************************************ 
*  Logic to select $issueWidth Ready instructions and issue them for execution. For
*  each FU one instruction will be selected. 
************************************************************************************/

LABEL

$tempCount = 0; # It is cummulative of @fuNo upto this iteration

# Hardcoded, since there are only 4 instruction types
for($i=0; $i<$typesOfFUs; $i++)
{
	print "/* Following selects $fuNo[$i] instruction(s) of type", $i, " */\n";
	print "always @(*)\n";
	print "begin: preparing_request_vector_for_FU", $i, "\n"; # Actually means this instruction is of type $i
	print "\tinteger k;\n";
	print "\tfor(k=0; k<`SIZE_ISSUEQ; k=k+1)\n";
	print "\tbegin\n";

	$temp = sprintf("%02b", $i);
	
	print "\t\trequestVector", $i, "[k] = (ISSUEQ_VALID[k] & ~ISSUEQ_SCHEDULED[k] & SRC0_REG_VALID[k] & SRC1_REG_VALID[k] & (ISSUEQ_FU[k] == 2'b", $temp, ")) ? 1'b1:1'b0;\n";

	print "\tend\n";
	print "end\n\n";

	if($fuNo[$i] <= 1)
	{
		print "Select select", $i, "(.clk(clk),\n";
	}
	else
	{
		print "Select$fuNo[$i] select", $i, "(.clk(clk),\n";
	}
	print "\t.reset(reset),\n";
	print "\t.requestVector_i(requestVector", $i, "),\n";

	if($passTags == 1)
	{
		for($j=0; $j<$iqSize; $j++)
		{
			print "\t.reqTag${j}_i(DEST_REGS[${j}]),\n";
		}
	}
	
	if($fuNo[$i] <= 1)
	{
		if($passTags == 1)
		{
			print "\t.grantedTag_o(grantedTag$tempCount),\n";
		}
		print "\t.grantedEntry_o(grantedEntry", $tempCount, "),\n";
		print "\t.grantedValid_o(grantedValid", $tempCount, ")\n";	
	}
	else
	{
		for($j=0; $j<$fuNo[$i]; $j++)
		{
			$temp = chr($j+ord('A'));
			if($passTags == 1)
			{
				print "\t.grantedTag${temp}_o(grantedTag", $tempCount+$j, "),\n";
			}
			print "\t.grantedEntry", $temp,"_o(grantedEntry", $tempCount+$j, "),\n";
			print "\t.grantedValid", $temp,"_o(grantedValid", $tempCount+$j, ")";
	
			if($j != $fuNo[$i]-1)
			{
				print ",";
			}
			print "\n";
		}
	}
	
	$tempCount += $fuNo[$i];
	
	print ");\n\n";
}

print <<LABEL;
/****************************
 * RSR INSIDE ISSUEQ MODULE *
 * *************************/

LABEL

if($passTags != 1)
{
	$temp = $issueWidth - $fuNo[$typesOfFUs-1];
	for($i=0; $i<$temp; $i++)
	{
		print <<LABEL;
	assign granted${i}Dest  = grantedPacket${i}_t[`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+
		`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_IMMEDIATE+
		`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
LABEL
	}
	print "\n";

	$temp = $issueWidth - $fuNo[$typesOfFUs-1];
	for($i=0; $i<$temp; $i++)
	{
		print <<LABEL;
	assign granted${i}Entry = grantedPacket${i}_t[`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
		`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
		`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
		`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
		`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
LABEL
	}
	print "\n";
}

if($depth == 1)
{
	$temp = "";
}
else
{
	$temp = "2";
}

print <<LABEL;
RSR$temp rsr(
	.clk(clk),
	.reset(reset),
	.ctrlVerified_i(ctrlVerified_i),
	.ctrlMispredict_i(ctrlMispredict_i),
	.ctrlSMTid_i(ctrlSMTid_i),
LABEL


$temp = $issueWidth - $fuNo[$typesOfFUs-1];
for($i=0; $i<$temp; $i++)
{
	print <<LABEL;
	.validPacket${i}_i(grantedValid${i}_t),
LABEL
}
print "\n";

$temp = $issueWidth - $fuNo[$typesOfFUs-1];
for($i=0; $i<$temp; $i++)
{
	if($passTags != 1)
	{
		print <<LABEL;
	.granted${i}Dest_i(granted${i}Dest),
LABEL
	}
	elsif($passTags == 1)
	{
		print <<LABEL;
	.granted${i}Dest_i(grantedTag${i}\[`SIZE_PHYSICAL_LOG:1]),
LABEL
	}
}
print "\n";

# .granted${i}Entry_i(granted${i}Entry),

$temp = $issueWidth - $fuNo[$typesOfFUs-1];
for($i=0; $i<$temp; $i++)
{
	print <<LABEL;
	.branchMask${i}_i(BRANCH_MASK[grantedEntry$i]),
LABEL
}
print "\n";

$temp = $issueWidth - $fuNo[$typesOfFUs-1];
for($i=0; $i<$temp; $i++)
{
	$comma = ",";
	if($i == $temp-1)
	{
		$comma = "";
	}

	print <<LABEL;
	.rsr${i}Tag_o(rsr${i}Tag),   
	.rsr${i}TagValid_o(rsr${i}TagValid)$comma
LABEL
}
print "\n";

print ");\n\n";
print "endmodule\n";

