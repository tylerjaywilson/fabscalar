#!/usr/bin/perl

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
# Purpose: This script generates rename.v.
################################################################################

my $version = "1.0";

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 2;

my $printHeader = 0;

my $dispatchWidth;
my $retireWidth;

my $i;
my $j;
my $k;
my $comma;
my $temp;
my $temp2;
my $temp3;
my $tempCount;
my $tempStr;
my @tempArr;

sub fatalUsage
{
	print "\n";
	print "Usage: perl $scriptName -d <dispatch_width> -r <retire_width> [-m] [-v] [-h]\n";
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
	if(/^-d$/)
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

# Create module name
$outputFileName = "Rename.v";
$moduleName = "Rename";


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
# Purpose: 
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL

print <<LABEL;
module $moduleName(  input clk,
                input reset,
                input stall_i,

                input flagRecoverEX_i,
                input ctrlVerified_i,
                input [`CHECKPOINTS_LOG-1:0] ctrlVerifiedSMTid_i,

                input decodeReady_i,
LABEL

 for($i=0; $i<$dispatchWidth; $i=$i+1){
	 print <<LABEL;
                input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
                       3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket${i}_i,

LABEL
 }

 print "\t\tinput [`BRANCH_COUNT-1:0] branchCount_i,\n";
 for($i=0; $i<$retireWidth; $i=$i+1){
	 print <<LABEL;
                input commitValid${i}_i,
                input [`SIZE_PHYSICAL_LOG-1:0] commitReg${i}_i,
LABEL
 }

 print "\t\tinput recoverFlag_i,\n";
 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print "\t\tinput [`SIZE_RMT_LOG-1:0] recoverDest${i}_i,\n";
 }
 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print "\t\tinput [`SIZE_PHYSICAL_LOG-1:0] recoverMap${i}_i,\n";
 }
 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print <<LABEL;
                output [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                        `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] renamedPacket${i}_o,
LABEL
 }
print <<LABEL;

                output noFreeSMT_o,
                output freeListEmpty_o,
                output renameReady_o
             );

LABEL
 for($i=0; $i<$dispatchWidth; $i=$i+1){
        print <<LABEL;

wire [`SIZE_RMT_LOG:0]                  src${i}logical1;
wire [`SIZE_RMT_LOG:0]                  src${i}logical2;
wire [`SIZE_RMT_LOG:0]                  inst${i}Dest;
wire                                    inst${i}branch;
LABEL
 }

 for($i=0; $i<$dispatchWidth; $i=$i+1){
        print "wire                                    reqFreeReg${i};\n";
 }
 print " wire   \t\t\tnoFreeSMT;\n wire  \t\t\tfreeListEmpty;\n";
 for($i=0; $i<$dispatchWidth; $i=$i+1){
        print <<LABEL;
wire [`SIZE_PHYSICAL_LOG:0]             src${i}rmt1;
wire [`SIZE_PHYSICAL_LOG:0]             src${i}rmt2;
wire [`SIZE_PHYSICAL_LOG:0]             dest${i}PhyMap;
wire [`SIZE_PHYSICAL_LOG:0]             old${i}PhyMap;
LABEL
 }

 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print "wire [`CHECKPOINTS_LOG-1:0]             id${i}SMT;\n";
 }
 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print "wire [`CHECKPOINTS-1:0]                 branch${i}Mask;\n";
 }
 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print "wire [`SIZE_PHYSICAL_LOG:0]             freeReg${i};\n";
 }

 print "wire [`SIZE_FREE_LIST_LOG-1:0]          freeListHead;\nwire [`SIZE_FREE_LIST_LOG-1:0]          freeListHeadCp;\n";
 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print "reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] renamedPkt${i};\n";
 }

 print "\nSpecFreeList specfreelist( ";
 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print "\t\t.reqFreeReg${i}_i(reqFreeReg${i}),\n";
 }
 for($i=0; $i<$retireWidth; $i=$i+1){
	print "\t\t.commitValid${i}_i(commitValid${i}_i),\n";
	print "\t\t.commitReg${i}_i(commitReg${i}_i),\n";
 }

 print <<LABEL;
                           .flagRecoverEX_i(flagRecoverEX_i),
                           .ctrlVerified_i(ctrlVerified_i),
                           .freeListHeadCp_i(freeListHeadCp),
                           .stall_i(stall_i | ~decodeReady_i | noFreeSMT),
                           .reset(reset),
                           .recoverFlag_i(recoverFlag_i),
                           .clk(clk),
LABEL
 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print ".freeReg${i}_o(freeReg${i}),\n";
 }

 print <<LABEL;
                           .freeListHead_o(freeListHead),
                           .freeListEmpty_o(freeListEmpty)
                   );


RenameMapTable RMT( .clk(clk),
                    .reset(reset),
                    .stall_i(stall_i | ~decodeReady_i | freeListEmpty | noFreeSMT),
LABEL
 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print <<LABEL;
                    .src${i}logical1_i(src${i}logical1),
                    .src${i}logical2_i(src${i}logical2),
                    .inst${i}Dest_i(inst${i}Dest),

LABEL
 }
 print "\t\t.flagRecoverEX_i(flagRecoverEX_i),\n";

 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print "\t\t.dest${i}Physical_i(freeReg${i}),\n";
 }
 print ".recoverFlag_i(recoverFlag_i),\n";
 for($i=0; $i<$dispatchWidth; $i=$i+1){
 	print "\t\t.recoverDest${i}_i(recoverDest${i}_i),\n";
 }

 for($i=0; $i<$dispatchWidth; $i=$i+1){
        print "\t\t.recoverMap${i}_i(recoverMap${i}_i),\n";
 }
 
 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print "\t\t.src${i}rmt1_o(src${i}rmt1),\n\t\t.src${i}rmt2_o(src${i}rmt2),\n\t\t.dest${i}PhyMap_o(dest${i}PhyMap),\n";
	if($i != $dispatchWidth - 1){
		print "\t\t.old${i}PhyMap_o(old${i}PhyMap),\n";
	}
	else {
		print "\t\t.old${i}PhyMap_o(old${i}PhyMap)\n";
	}
 }
 print "  );\nassign freeListHeadCp = 0;\n";

 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print "assign id${i}SMT = 0;\n";
 }

 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print "assign branch${i}Mask = 0;\n";
 }
 print "assign checkPointedRMT = 0;\n";
 print "assign noFreeSMT = 0;\n";

 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print <<LABEL;
assign src${i}logical1  =  decodedPacket${i}_i[`SIZE_RMT_LOG+1+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign src${i}logical2  =  decodedPacket${i}_i[2*`SIZE_RMT_LOG+2+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_RMT_LOG+1+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign inst${i}Dest     =  decodedPacket${i}_i[3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:2*`SIZE_RMT_LOG+2+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign inst${i}branch   =  decodedPacket${i}_i[3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];

LABEL
 }

 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print "assign reqFreeReg${i}   =  (decodeReady_i & inst${i}Dest[0] & ~noFreeSMT & ~stall_i);\n";
 }

 print "always @(*)\nbegin:PACKET_FORMATION\n";
 for($i=0; $i<$dispatchWidth; $i=$i+1){
 	print <<LABEL;
 reg [`INST_TYPES_LOG-1:0] inst${i}fu;
 reg [`LDST_TYPES_LOG-1:0] inst${i}ldstSize;
 reg [`SIZE_IMMEDIATE:0]   inst${i}immediate;
 reg inst${i}load;
 reg inst${i}store;
 reg inst${i}branch;

LABEL
 }
 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print <<LABEL;
 inst${i}fu        = decodedPacket${i}_i[`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 inst${i}ldstSize  = decodedPacket${i}_i[`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 inst${i}immediate = decodedPacket${i}_i[`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 inst${i}load      = decodedPacket${i}_i[1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];
 inst${i}store     = decodedPacket${i}_i[2+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];
 inst${i}branch    = decodedPacket${i}_i[3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];

 renamedPkt${i} = {inst${i}Dest[`SIZE_RMT_LOG:1],inst${i}branch,inst${i}store,inst${i}load,branch${i}Mask,id${i}SMT,old${i}PhyMap,
                dest${i}PhyMap,src${i}rmt2,src${i}rmt1,inst${i}immediate,inst${i}ldstSize,inst${i}fu,
                decodedPacket${i}_i[`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0]};

LABEL
}

 print "\nend\n\n";
 for($i=0; $i<$dispatchWidth; $i=$i+1){
	print "assign renamedPacket${i}_o  = renamedPkt${i};\n";
 }
 
 print <<LABEL;
assign renameReady_o     = (decodeReady_i & ~noFreeSMT & ~freeListEmpty);
assign freeListEmpty_o   = freeListEmpty;
assign noFreeSMT_o       = noFreeSMT;

endmodule

LABEL
 
