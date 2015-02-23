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
# Purpose: This script creates Verilog for the execute stage.
################################################################################

my $version = "1.0";

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 4;

my $typesOfFUs = 4; # HARDWIRED!
my @fuNo;   # Number of execute ways of each instruction type (they are always adjacent)
my @whereFU;  # A two dimensional array with 4 rows (for each instruction type), telling which ways support that type.
my $issueWidth;

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
	print "Usage: perl $scriptName -n A B C D [-m] [-v] [-h]\n";
	print "\t-n: Number of instructions of type 1 (A), type 2 (B), type 3 (C), type 4 (D)\n";
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
$outputFileName = "Execute.v";
$moduleName = "Execute";

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

/* Algorithm

   It is assumed there are 4 functional units with functions described 
   below:
	FU0 -> Simple ALU
	FU1 -> Complex ALU (for MULTIPLY & DIVIDE)
	FU2 -> ALU for CONTROL Instructions
	FU3 -> LOAD/STORE Address Generator
 
   fuPacket0 corresponds to FU0
   fuPacket1 corresponds to FU1
   fuPacket2 corresponds to FU2
   fuPacket3 corresponds to FU3
   
   1. Receive new packet to execute each cycle, if there are ready instructions 
      in the Issue Queue.
	
   2. Execute packet contains following information:
       (.) Opcode
       (.) Source Data-1
       (.) Source Register-1
       (.) Source Data-2
       (.) Source Register-2 
       (.) Destination Register
       (.) Active List ID
       (.) Issue Queue ID
       (.) Load-Store Queue ID
       (.) Branch Mask
       (.) Shadow Map Table (SMT) ID
       (.) Ctiq Tag
       (.) Predicted Target Address (for control inst)
       (.) Predicted Direction      (for branch inst)
       (.) Packet Valid bit

   3. Receive bypass inputs from the previous cycle from all functional units. 
      Instruction entering into the Execute should compare its source registers
      to bypassed destination registers.
        If, comparision result is true pick the bypassed value.

   4. Bypassed data should contain following information:
       (.) Destination Register
       (.) Output Data
       (.) Shadow Map Table ID
       (.) Control Mispredict
       (.) ***Disambig Stall***********	

   5. [ For current implementation Load instruction's RSR latency is same as Load execution 
        latency plus register file read latency. This means load dependent instructions will not 
        have back to back execution in best case.
      ]
      For Load dependent instructions, source tag should be compared against the load destination.
      If there is a match and the disambi stall signal is high, the instruction should be terminated.
      And the corresponding scheduled bit for the load dependent instruction in the issue queue 
      should be set to 0. 

   6. Output of a global Functional unit would be:
       (12) Destination Valid	
       (11) Executed
       (10) Exception
       (9)  Mispredict	
       (8)  Destination Register
       (7)  Active List ID
       (6)  Output Data
       (5)  Issue Queue ID
       (4)  Load-Store Queue ID
       (3)  Shadow Map Table ID  
       (2)  Ctiq Tag
       (1)  Computed Target Address
       (0)  Computed Direction

   
   Note: It is assumed that there are 4 functional units in the execute 
         stage.

***************************************************************************/

LABEL

# Module header

print <<LABEL;
module $moduleName(
	input clk,
	input reset,

	/* Simple and complex ALU instructions contain following:
		    (9) Immediate Data  : bits-`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+
                       		         `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+
					 `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS	
		    (8) Opcode          : bits-`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (7) Source Data-1   : bits-`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS 
		    (6) Source Reg-1    : bits-`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (5) Source Data-2   : bits-`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
                    (4) Source Reg-2    : bits-`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (3) Destination Reg : bits-`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (2) Active List ID  : bits-`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (1) Issue Queue ID  : bits-`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`CHECKPOINTS
		    (0) Branch Mask     : bits-`CHECKPOINTS-1:0 
		*/
LABEL

for($i=0; $i<$whereFU[1][0]; $i++)
{
	print <<LABEL;
	input [`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+
		`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:0] fuPacket${i}_i,
	input fuPacketValid${i}_i,

LABEL
}

for($i=$whereFU[1][0]; $i<$whereFU[2][0]; $i++)
{
	print <<LABEL;
	input [`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+
		`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:0] fuPacket${i}_i,
	input fuPacketValid${i}_i,

LABEL
}

print <<LABEL;
	/* Branch instructions contains following:
		     (14) PC                    : bits-
		     (13) Immediate Data        : bits-
                     (12) Opcode                : bits-`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
		     (11) Source Data-1         : bits-2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_PHYSICAL_LOG+`SIZE_DATA+2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
                     (10) Source Reg-1          : bits-`SIZE_PHYSICAL_LOG+`SIZE_DATA+2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
                     (9)  Source Data-2         : bits-`SIZE_DATA+2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
                     (8)  Source Reg-2          : bits-2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
                     (7)  Destination Reg       : bits-`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
                     (6)  Active List ID        : bits-`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
                     (5)  Issue Queue ID        : bits-`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
                     (4)  Branch Mask           : bits-`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
		     (3) SMT ID                : bits-`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_CTI_LOG+`SIZE_PC+1
		     (2) Ctiq Tag              : bits-`SIZE_CTI_LOG+`SIZE_PC:`SIZE_PC+1
		     (1) Predicted Target Addr : bits-`SIZE_PC:1
		     (0) Predicted Direction   : bits-0
                */
LABEL

for($i=$whereFU[2][0]; $i<$whereFU[3][0]; $i++)
{
	print <<LABEL;
	input [`SIZE_PC+`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+
		`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] fuPacket${i}_i, 
	input fuPacketValid${i}_i,  

LABEL
}

print <<LABEL;
/* LD/ST instructions contains following:
		    (10)Immediate Data  : bits-	
		    (9) Opcode          : bits-`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (8) Source Data-1   : bits-`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS 
		    (7) Source Reg-1    : bits-`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (6) Source Data-2   : bits-`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
                    (5) Source Reg-2    : bits-`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (4) Destination Reg : bits-`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (3) LD-ST Queue ID  : bits-`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (2) Active List ID  : bits-`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (1) Issue Queue ID  : bits-`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`CHECKPOINTS
		    (0) Branch Mask     : bits-`CHECKPOINTS-1:0 
		*/ 
LABEL

for($i=$whereFU[3][0]; $i<$issueWidth; $i++)
{
	print <<LABEL;
	input  [`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+
		`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:0] fuPacket${i}_i, 
	input  fuPacketValid${i}_i,    

LABEL
}

print <<LABEL;
	/* Bypass Packet contains following:
		     (3)  Destination Register  : bits-`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:`SIZE_DATA+`CHECKPOINTS_LOG+1
		     (2)  Output Data           : bits-`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1
 		     (1)  Shadow Map Table ID   : bits-`CHECKPOINTS_LOG:1
                     (0)  Control Mispredict    : bits-0
                */
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
	input  [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket${i}_i,
	input  bypassValid${i}_i,
LABEL
}
print "\n";

print <<LABEL;
	input  ctrlVerified_i,
	input  ctrlMispredict_i,
	input  [`CHECKPOINTS_LOG-1:0] ctrlSMTid_i,

LABEL

for($i=0; $i<$whereFU[3][0]; $i++)
{
	print <<LABEL;
	output [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
		`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket${i}_o,
	output exePacketValid${i}_o,
LABEL
}

for($i=$whereFU[3][0]; $i<$issueWidth; $i++)
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
	output [`CHECKPOINTS+`LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
		`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket${i}_o,
	output exePacketValid${i}_o$comma
LABEL
}

print ");\n\n";

print <<LABEL;
/* Defining wire and regs for combinational logic. */
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
reg [`SIZE_PHYSICAL_LOG-1:0] fu${i}reg1;
reg [`SIZE_DATA-1:0] fu${i}data1;
reg [`SIZE_PHYSICAL_LOG-1:0] fu${i}reg2;
reg [`SIZE_DATA-1:0] fu${i}data2;
LABEL
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_PHYSICAL_LOG-1:0] bypassTag$i;
wire [`SIZE_DATA-1:0] bypassData$i;
LABEL
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_DATA-1:0] fu${i}FinalData1;
wire [`SIZE_DATA-1:0] fu${i}FinalData2;
LABEL
}
print "\n";

print <<LABEL;
/* Following instantiates FU0: simple ALU 
*/
LABEL

for($i=0; $i<$whereFU[1][0]; $i++)
{
	print <<LABEL;
 FU0 fu$i( .clk(clk),
          .reset(reset),

          .inPacket_i(fuPacket${i}_i),
	  .fuFinalData1_i(fu${i}FinalData1),
	  .fuFinalData2_i(fu${i}FinalData2),
          .inValid_i(fuPacketValid${i}_i),

          .ctrlVerified_i(ctrlVerified_i),
          .ctrlMispredict_i(ctrlMispredict_i),
          .ctrlSMTid_i(ctrlSMTid_i),

          .outPacket_o(exePacket${i}_o),
          .outValid_o(exePacketValid${i}_o)
	);

LABEL
}

print <<LABEL;
/* Following instantiates FU1: complex ALU
*/
LABEL

for($i=$whereFU[1][0]; $i<$whereFU[2][0]; $i++)
{
	print <<LABEL;
 FU1 fu$i( .clk(clk),
          .reset(reset),

          .inPacket_i(fuPacket${i}_i),
	  .fuFinalData1_i(fu${i}FinalData1),
	  .fuFinalData2_i(fu${i}FinalData2),
          .inValid_i(fuPacketValid${i}_i),

          .ctrlVerified_i(ctrlVerified_i),
          .ctrlMispredict_i(ctrlMispredict_i),
          .ctrlSMTid_i(ctrlSMTid_i),

          .outPacket_o(exePacket${i}_o),
          .outValid_o(exePacketValid${i}_o)
	);

LABEL
}

print <<LABEL;
/* Following instantiates FU2: control unit 
*/
LABEL

for($i=$whereFU[2][0]; $i<$whereFU[3][0]; $i++)
{
	print <<LABEL;
 FU2 fu$i( .clk(clk),
          .reset(reset),

          .inPacket_i(fuPacket${i}_i),
	  .fuFinalData1_i(fu${i}FinalData1),
	  .fuFinalData2_i(fu${i}FinalData2),
          .inValid_i(fuPacketValid${i}_i),

          .ctrlVerified_i(ctrlVerified_i),
          .ctrlMispredict_i(ctrlMispredict_i),
          .ctrlSMTid_i(ctrlSMTid_i),

          .outPacket_o(exePacket${i}_o),
          .outValid_o(exePacketValid${i}_o)
	);

LABEL
}

print <<LABEL;
/* Following instantiates FU3: address generation unit
*/
LABEL

for($i=$whereFU[3][0]; $i<$issueWidth; $i++)
{
	print <<LABEL;
 FU3 fu$i( .clk(clk),
          .reset(reset),

          .inPacket_i(fuPacket${i}_i),
	  .fuFinalData1_i(fu${i}FinalData1),
	  .fuFinalData2_i(fu${i}FinalData2),
          .inValid_i(fuPacketValid${i}_i),

          .ctrlVerified_i(ctrlVerified_i),
          .ctrlMispredict_i(ctrlMispredict_i),
          .ctrlSMTid_i(ctrlSMTid_i),

          .outPacket_o(exePacket${i}_o),
          .outValid_o(exePacketValid${i}_o)
	);

LABEL
}

print <<LABEL;
/* Following checks for any data forwarding required for the incoming 
   functional unit packet.
   Destination register of each bypassed packet is compared with source
   registers of each FU packet. If there is a match then bypassed
   data is forwarded to the corresponding functional unit.
*/

/* Extracts tag and data from bypass path for forward checking logic. */
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
assign bypassTag$i  = bypassPacket${i}_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:`SIZE_DATA+`CHECKPOINTS_LOG+1];
assign bypassData$i = bypassPacket${i}_i[`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1];
LABEL
}
print "\n";








for($i=0; $i<$whereFU[1][0]; $i++)
{
	print <<LABEL;
always @(*)
begin:FORWARD_CHECK_FU${i}
 fu${i}reg1   = fuPacket${i}_i[`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:
			 `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];
 fu${i}data1  = fuPacket${i}_i[`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+
			 `CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];

 fu${i}reg2   = fuPacket${i}_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+
			 `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_DATA+
			 `SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];
 fu${i}data2  = fuPacket${i}_i[2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+
			 `CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+
			 `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];
end

 ForwardCheck fu${i}_srcReg1 (.srcReg_i(fu${i}reg1),
                           .srcData_i(fu${i}data1),
LABEL

	for($j=0; $j<$issueWidth; $j++)
	{
		print <<L2;
                           .bypassValid${j}_i(bypassValid${j}_i),
                           .bypassTag${j}_i(bypassTag${j}),
                           .bypassData${j}_i(bypassData${j}),
L2
	}

	print <<LABEL;
                           .dataOut_o(fu${i}FinalData1)
                          );

 ForwardCheck fu${i}_srcReg2 (.srcReg_i(fu${i}reg2),
                           .srcData_i(fu${i}data2),
LABEL

	for($j=0; $j<$issueWidth; $j++)
	{
		print <<L2;
                           .bypassValid${j}_i(bypassValid${j}_i),
                           .bypassTag${j}_i(bypassTag${j}),
                           .bypassData${j}_i(bypassData${j}),
L2
	}

	print <<LABEL;

                           .dataOut_o(fu${i}FinalData2)
                          );

LABEL
}

for($i=$whereFU[1][0]; $i<$whereFU[2][0]; $i++)
{
	print <<LABEL;
always @(*)
begin:FORWARD_CHECK_FU${i}
 fu${i}reg1   = fuPacket${i}_i[`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:
			 `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];
 fu${i}data1  = fuPacket${i}_i[`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+
			 `CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];

 fu${i}reg2   = fuPacket${i}_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+
			 `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_DATA+
			 `SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];
 fu${i}data2  = fuPacket${i}_i[2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+
                         `CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+
                         `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];
end

 ForwardCheck fu${i}_srcReg1 (.srcReg_i(fu${i}reg1),
                           .srcData_i(fu${i}data1),
LABEL

	for($j=0; $j<$issueWidth; $j++)
	{
		print <<L2;
                           .bypassValid${j}_i(bypassValid${j}_i),
                           .bypassTag${j}_i(bypassTag${j}),
                           .bypassData${j}_i(bypassData${j}),
L2
	}

	print <<LABEL;
                           .dataOut_o(fu${i}FinalData1)
                          );

 ForwardCheck fu${i}_srcReg2 (.srcReg_i(fu${i}reg2),
                           .srcData_i(fu${i}data2),
LABEL

	for($j=0; $j<$issueWidth; $j++)
	{
		print <<L2;
                           .bypassValid${j}_i(bypassValid${j}_i),
                           .bypassTag${j}_i(bypassTag${j}),
                           .bypassData${j}_i(bypassData${j}),
L2
	}

	print <<LABEL;
                           .dataOut_o(fu${i}FinalData2)
                          );

LABEL
}

for($i=$whereFU[2][0]; $i<$whereFU[3][0]; $i++)
{
	print <<LABEL;
always @(*)
begin:FORWARD_CHECK_FU${i}
 fu${i}reg1   = fuPacket${i}_i[2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+
			 `SIZE_CTI_LOG+`SIZE_PC:`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+
			 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
 fu${i}data1  = fuPacket${i}_i[`SIZE_DATA+2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+
			 `SIZE_CTI_LOG+`SIZE_PC:2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+
			 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

 fu${i}reg2   = fuPacket${i}_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
			 `SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
			 `SIZE_DATA+2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+
			 `CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
 fu${i}data2  = fuPacket${i}_i[2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
			 `SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
			 `SIZE_PHYSICAL_LOG+`SIZE_DATA+2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
			 `SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
end


 ForwardCheck fu${i}_srcReg1 (.srcReg_i(fu${i}reg1),
                           .srcData_i(fu${i}data1),
LABEL

	for($j=0; $j<$issueWidth; $j++)
	{
		print <<L2;
                           .bypassValid${j}_i(bypassValid${j}_i),
                           .bypassTag${j}_i(bypassTag${j}),
                           .bypassData${j}_i(bypassData${j}),
L2
	}

	print <<LABEL;
                           .dataOut_o(fu${i}FinalData1)
                          );

 ForwardCheck fu${i}_srcReg2 (.srcReg_i(fu${i}reg2),
                           .srcData_i(fu${i}data2),
LABEL

	for($j=0; $j<$issueWidth; $j++)
	{
		print <<L2;
                           .bypassValid${j}_i(bypassValid${j}_i),
                           .bypassTag${j}_i(bypassTag${j}),
                           .bypassData${j}_i(bypassData${j}),
L2
	}

	print <<LABEL;
                           .dataOut_o(fu${i}FinalData2)
                          );

LABEL
}

for($i=$whereFU[3][0]; $i<$issueWidth; $i++)
{
	print <<LABEL;
always @(*)
begin:FORWARD_CHECK_FU${i}
 fu${i}reg1   = fuPacket${i}_i[`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+
			 `CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];
 fu${i}data1  = fuPacket${i}_i[`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+
			 `CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];

 fu${i}reg2   = fuPacket${i}_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+
			 `SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:
			 `SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
			 `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];
 fu${i}data2  = fuPacket${i}_i[`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+
			 `SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+
			 `SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+
			 `SIZE_ISSUEQ_LOG+`CHECKPOINTS];
end

 ForwardCheck fu${i}_srcReg1 (.srcReg_i(fu${i}reg1),
                           .srcData_i(fu${i}data1),
LABEL

	for($j=0; $j<$issueWidth; $j++)
	{
		print <<L2;
                           .bypassValid${j}_i(bypassValid${j}_i),
                           .bypassTag${j}_i(bypassTag${j}),
                           .bypassData${j}_i(bypassData${j}),
L2
	}

	print <<LABEL;
                           .dataOut_o(fu${i}FinalData1)
                          );

 ForwardCheck fu${i}_srcReg2 (.srcReg_i(fu${i}reg2),
                           .srcData_i(fu${i}data2),
LABEL

	for($j=0; $j<$issueWidth; $j++)
	{
		print <<L2;
                           .bypassValid${j}_i(bypassValid${j}_i),
                           .bypassTag${j}_i(bypassTag${j}),
                           .bypassData${j}_i(bypassData${j}),
L2
	}

	print <<LABEL;
                           .dataOut_o(fu${i}FinalData2)
                          );

LABEL
}

print "endmodule\n";

