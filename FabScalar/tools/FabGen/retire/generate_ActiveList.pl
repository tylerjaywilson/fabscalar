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
# Purpose: This script creates Verilog file for ActiveList.v.
################################################################################

my $version = "1.0";

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 6;

my $dispatchWidth;
my $issueWidth;
my $retireWidth;
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
	print "Usage: perl $scriptName -d <dispatch_width> -n A B C D -r <retire_width> [-m] [-v] [-h]\n";
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

if($retireWidth != 4)
{
	die "ActiveList.v not implemented for retires widths other than 4.\n";
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
# Purpose: This block implements Active List.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

/* Algorithm:

   1. Active List is a circular buffer with head and tail pointers. 
      New instructions are written at the tail and old instructions are
      retired from the head.

   2. Receives 4 or 0 new insturctions from the Dispatch stage, along
      with back-end Ready signal. 
	If there is no empty space in Issue Queue or Active List or Load-Store
	Queue, then back-end Ready is low. 

   3. For each new instruction following information should be registered
      into ActiveList RAM:
	(a.) PC of instruction
	(b.) Logical destination register
	(c.) Current physical destination register mapping
	(d.) Old physical destination register mapping
	(e.) Control info -> [Executed, Exception, Mispredict for branches]
      Instruction info (a.,b.,c. & d.) doesn't change over time. Info e. is 
      writen by Functional Unit after the instruction has executed.	

   4. ActiveList ID is generated for each incoming instructions and sent to 
      Issue Queue module and Load-Store Queue module.

   5. Upto 4 instructions are commited each cycle based on the Executed bit   
      associated with each buffer entry.

   6. On a commit, current physical mapping is writen into Arch Map Table
      and old destination physical mapping is freed (written back to Spec
      free list). 

   7. Maintains a total entry counter, which counts number of valid 
      instructions in the ActiveList. The count value is used by the dispatch 
      unit to generate back-end Ready signal. 

   8. If there is a branch mis-predict the tail pointer is rolled back to 
      offending instruction in the ActiveList.

   9. Exception is handled at the head of the ActiveList. On an exception, AMT
      is copied into RMT.


****************************************************************************/

LABEL

print <<LABEL;
module ActiveList(
		   input clk,
		   input reset,
		   input backEndReady_i,			   

                   /* Active List packet contains following information:
			(6) isInstLoad        "bit-2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG"
			(5) isInst Store      "bit-1+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG"	       	
			(4) Program Counter   "bits-`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1"
			(3) Logical Dest      "bits-`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:2*`SIZE_PHYSICAL_LOG+1"
			(2) Physical Dest     "bits-2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1"
			(1) Old Physical Dest "bits-`SIZE_PHYSICAL_LOG:1"
			(0) Valid Dest        "bit-0"
		   */ 
LABEL


for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
      		   input [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] alPacket${i}_i,
LABEL
}


for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
		   input validFU${i}_i,
 		   input [`SIZE_PC-1:0] computedAddr${i}_i,	
		   input [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU${i}_i,
LABEL
}
print "\n";

print <<LABEL;
		   input [`SIZE_ACTIVELIST_LOG:0]   ldViolationPacket_i,		

LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                   output [`SIZE_ACTIVELIST_LOG-1:0] activeListId${i}_o,
LABEL
}
print "\n";


print <<LABEL;
		   output [`SIZE_ACTIVELIST_LOG:0] activeListCnt_o,

LABEL

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
		   output commitValid${i}_o,
		   output [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] commitPacket${i}_o,
 		   output commitStore${i}_o,
 		   output commitLoad${i}_o,
LABEL
}
print "\n";

print <<LABEL;
		   output [`RETIRE_WIDTH-1:0] commitCti_o,

                   output recoverFlag_o,
		   output [`SIZE_PC-1:0] recoverPC_o,	

                   output exceptionFlag_o,
		   output [`SIZE_PC-1:0] exceptionPC_o
);



/* Following declares the Active head pointer and tail pointer.
*/
reg [`SIZE_ACTIVELIST_LOG-1:0] 			headAL;
reg [`SIZE_ACTIVELIST_LOG-1:0] 			tailAL;
reg [`SIZE_ACTIVELIST_LOG:0]			activeListCount;

reg 						recoverFlag;
reg [`SIZE_PC-1:0]                     		recoverPC;
reg 						mispredFlag;
reg [`SIZE_PC-1:0]                     		targetPC;
reg 						exceptionFlag;
reg [`SIZE_PC-1:0]                     		exceptionPC;



/* Following declares Wires and regs for the combinatorial logic.
*/
LABEL


for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_ACTIVELIST_LOG-1:0] 		tailAddr${i};
LABEL
}
print "\n";

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_ACTIVELIST_LOG-1:0] 		headAddr${i};
LABEL
}
print "\n";


for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_ACTIVELIST_LOG-1:0] 		fuAddr${i};
wire 						fuEn${i};
wire [`WRITEBACK_FLAGS-1:0] 			fuData${i};
LABEL
}
print "\n";

print <<LABEL;
wire 						ctrlMispredict;
wire 						ctrlMispredict_f;
wire [`SIZE_ACTIVELIST_LOG-1:0]			mispredictEntry;

reg [`SIZE_ACTIVELIST_LOG:0]			activeListCount_f;
reg [`SIZE_ACTIVELIST_LOG-1:0] 			newheadAL;
reg [`SIZE_ACTIVELIST_LOG-1:0] 			tailAL_f;

reg [`COMMIT_WIDTH-1:0]				totalCommit;

reg [`COMMIT_WIDTH-1:0]				commitVector;
LABEL


for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
reg 						commitValid${i};
reg [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] 	commitPacket${i};
reg 						commitStore${i};
reg 						commitLoad${i};
reg						commitFission${i};

LABEL
}

print <<LABEL;
reg [`RETIRE_WIDTH-1:0]				commitCti;

LABEL

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
wire [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] dataAl${i};
LABEL
}
print "\n";

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
wire [`WRITEBACK_FLAGS-1:0] 			ctrlAl${i};
LABEL
}
print "\n";

# Not used anywhere! Just kept here so that the diff checks out!
print <<LABEL;
wire [`BRANCH_TYPE-1:0]				ctiType0;
wire [`BRANCH_TYPE-1:0]				ctiType1;
wire [`BRANCH_TYPE-1:0]				ctiType2;
wire [`BRANCH_TYPE-1:0]				ctiType3;
reg [`SIZE_RAS_LOG-1:0] 			tos3;

LABEL

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
wire						violateBit${i};
LABEL
}
print "\n";

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
wire 						mispredictBit${i}_f;
LABEL
}
print "\n";

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
wire						violateBit${i}_f;
LABEL
}
print "\n";

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
wire						exceptionBit${i}_f;
LABEL
}
print "\n";

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_PC-1:0]				targetAddr${i};
LABEL
}
print "\n";

print "\`ifdef VERIFY\n";

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_PC-1:0] 				commitPC${i};
LABEL
}
print "\n";



for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
reg						commitVerify${i};
LABEL
}
print "\n";

print <<LABEL;
integer 					commitCount;
integer 					commitCount_f;

LABEL

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
integer 					commitCnt${i};
LABEL
}
print "\`endif\n\n";

print <<LABEL;
/************************************************************************************ 
   Following instantiates RAM modules for Active List. 2 seperate RAM modules have
   been instantisted each for static and control information associated with each
   instruction.
   Modules "activeList" and "ctrlActiveList" have different Read/Write ports 
   requirements. "ctrlActiveList" needs additional write ports to write the control
   information when an instruction has completed execution.
************************************************************************************/
SRAM_${retireWidth}R${dispatchWidth}W #(`SIZE_ACTIVELIST,`SIZE_ACTIVELIST_LOG,2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1)
        activeList ( .clk(clk),
                     .reset(reset | recoverFlag | mispredFlag | exceptionFlag),
LABEL


for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
		     .addr${i}_i(headAddr${i}),
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                     .addr${i}wr_i(tailAddr${i}),
		     .we${i}_i(backEndReady_i),
		     .data${i}wr_i(alPacket${i}_i),
LABEL
}
print "\n";

for($i=0; $i<$retireWidth; $i++)
{
	$comma = ",";
	if($i == $retireWidth -1)
	{
		$comma = "";
	}

	print <<LABEL;
                     .data${i}_o(dataAl${i})$comma
LABEL
}

print <<LABEL;
		   );


SRAM_${retireWidth}R${issueWidth}W #(`SIZE_ACTIVELIST,`SIZE_ACTIVELIST_LOG,`WRITEBACK_FLAGS)
    ctrlActiveList ( .clk(clk),
                     .reset(reset | violateBit0_f | ctrlMispredict_f | exceptionBit0_f),
LABEL

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
                     .addr${i}_i(headAddr${i}),
LABEL
}
print "\n";



for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
                     .addr${i}wr_i(fuAddr${i}),
                     .we${i}_i(fuEn${i}),
                     .data${i}wr_i(fuData${i}),
LABEL
}
print "\n";

for($i=0; $i<$retireWidth; $i++)
{
	$comma = ",";
	if($i == $retireWidth -1)
	{
		$comma = "";
	}

	print <<LABEL;
                     .data${i}_o(ctrlAl${i})$comma
LABEL
}

print <<LABEL;
		   );


/* The "targetAddrActiveList" RAM contain computed target address of control
 * instructions. 
 * The target address is required for the mis-prediction recovery model being
 * supported, currently. The mis-predicted contol instruction is resolved when 
 * it reaches the head of the Active List.
 */
SRAM_${retireWidth}R${issueWidth}W #(`SIZE_ACTIVELIST,`SIZE_ACTIVELIST_LOG,`SIZE_PC)
    targetAddrActiveList ( .clk(clk),
                     .reset(reset | recoverFlag | mispredFlag | exceptionFlag),
LABEL

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
                     .addr${i}_i(headAddr${i}),
LABEL
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
                     .addr${i}wr_i(fuAddr${i}),
                     .we${i}_i(fuEn${i}),
                     .data${i}wr_i(computedAddr${i}_i),
LABEL
}
print "\n";

for($i=0; $i<$retireWidth; $i++)
{
	$comma = ",";
	if($i == $retireWidth -1)
	{
		$comma = "";
	}

	print <<LABEL;
                     .data${i}_o(targetAddr${i})$comma
LABEL
}

print <<LABEL;
                   );


SRAM_${retireWidth}R1W #(`SIZE_ACTIVELIST,`SIZE_ACTIVELIST_LOG,1)
    ldViolateVector( .clk(clk),
                     .reset(reset | recoverFlag | mispredFlag | exceptionFlag),
LABEL

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
                     .addr${i}_i(headAddr${i}),
LABEL
}
print "\n";

print <<LABEL;
                     .addr0wr_i(ldViolationPacket_i[`SIZE_ACTIVELIST_LOG:1]),
                     .we0_i(ldViolationPacket_i[0]),
                     .data0wr_i(ldViolationPacket_i[0]),
LABEL


for($i=0; $i<$retireWidth; $i++)
{
	$comma = ",";
	if($i == $retireWidth -1)
	{
		$comma = "";
	}

	print <<LABEL;
                     .data${i}_o(violateBit${i})$comma
LABEL
}

print <<LABEL;
                   );



/*******************************************************************************
* In case of load violation or control mis-prediction, recover flag is raised to 
* flush the pipeline.
*
* In case of load violation, nextPC is PC of the offending instruction. 
* In case of control mis-prediction, nextPC is the target address.
*******************************************************************************/
assign recoverFlag_o = recoverFlag | mispredFlag;
assign recoverPC_o   = (mispredFlag) ? targetPC:recoverPC;	


/*******************************************************************************
* In case of SYSCALL, exception flag is raised to flush the pipeline. 
* A behavioral code to handle SYSCALL is called.
*******************************************************************************/
assign exceptionFlag_o 	= exceptionFlag;
assign exceptionPC_o	= exceptionPC;


/* Following generates write address for writing into Active List, starting 
 * from the tail.
 */
LABEL



for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
 assign tailAddr${i}  = tailAL+$i;
LABEL
}
print "\n";

print <<LABEL; 
 /* Following generates read address for reading from Active List, starting 
  * from the head.
  */
LABEL

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
 assign headAddr$i  = headAL+$i;
LABEL
}
print "\n";
 
 
print <<LABEL; 
 /* Following extracts write addr, enable and data information from the control
  * packet sent by FU. 
  * The information is written into ctrlActiveList RAM module. 
  */
LABEL


for($i=0; $i<$issueWidth; $i++)
{
	print <<LABEL;
 assign fuAddr${i}  = ctrlFU${i}_i[`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:`WRITEBACK_FLAGS]; 
 assign fuData${i}  = ctrlFU${i}_i[`WRITEBACK_FLAGS-1:0];
 assign fuEn${i}    = validFU${i}_i; 
LABEL
}
print "\n";
 
# Right now, we have only one branch resolving at a time
print <<LABEL;
 assign ctrlMispredict_f  = mispredictBit0_f && ctrlAl0[2];
LABEL
 
print <<LABEL;
 /* Following generates the active list empty entries count each cycle.
  *  
  * In the normal operation, difference between tail and head pointer (taking warpping into
  * account) is the count.
  *
  * In the case of branch misprediction, differnce between offending instruction's active
  * list ID and head pointer is the count. Active list ID of the offending instruction is
  * sent by the corresponding functional unit.
  */
 always @(*)
 begin:GENERATE_COUNT
  reg [`SIZE_ACTIVELIST_LOG-1:0] tailAL_mispre;
  reg                            isWrap1;
  reg [`SIZE_ACTIVELIST_LOG-1:0] diff1;
  reg [`SIZE_ACTIVELIST_LOG-1:0] diff2;
  reg [`SIZE_ACTIVELIST_LOG-1:0] cnt1;
 
  tailAL_f       = (backEndReady_i) ? (tailAL+`DISPATCH_WIDTH):tailAL;
  tailAL_mispre  = mispredictEntry + 1'b1;
 
  isWrap1        = (newheadAL > tailAL_mispre);
 
  diff1          =  tailAL_mispre - newheadAL;
  diff2          =  newheadAL     - tailAL_mispre;
  cnt1           = (isWrap1) ? (`SIZE_ACTIVELIST - diff2):diff1;
 
  activeListCount_f  = (activeListCount+((backEndReady_i) ? `DISPATCH_WIDTH:0))-totalCommit;
 end
 
  
 
 /* Following is the commit logic. Every cycle upto max COMMIT_WIDTH instructions
    can be retired. 
    "Executed" bit associated with each entry is checked from the head pointer. If
    the bit is one, then it is ready to retire (provided preceding entries have this
    bit set to 1). 
    
    IMP: commitValid is set to 1 only if the retiring instruction has a valid 
 	destination register. 
  */ 
LABEL


for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
 assign violateBit${i}_f	= violateBit${i} & dataAl${i}\[2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
LABEL
}
print "\n";
 
print <<LABEL; 
 /* Control mispredict bit is used to mark the misprediction. 
  * If there is a control instruction mispredicting in the commit group, the 
  * instruction is waited till it reaches head of the Active List. 
  */
LABEL

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
 assign mispredictBit${i}_f = ctrlAl${i}\[0];
LABEL
}
print "\n";
 
print <<LABEL; 
 /* Exception bit is used to mark the system call. If there is a system call 
  * in the commit group, the instruction is waited till it reaches head of 
  * the Active List. Following, an appropriate function (behavioral) is called
  * to handle it.
  */
LABEL

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
 assign exceptionBit${i}_f 	= ctrlAl${i}\[1];
LABEL
}
print "\n";
 
print <<LABEL; 
 always @(*)
 begin:COMMIT
 reg [`COMMIT_WIDTH-1:0]        commitVector_f;
 
  newheadAL     	= headAL; 
  totalCommit	= 0;
 
LABEL
 
for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
  commitValid$i  	= 0; 
  commitPacket$i 	= 0;
  commitStore$i  	= 0;
  commitLoad$i   	= 0;
  commitFission$i = 0;
LABEL
}
print "\n";
 	
print <<LABEL; 
  commitCti	= 0;
 
  `ifdef VERIFY
LABEL

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
  commitVerify$i 	= 0;
LABEL
}

print <<LABEL; 
  commitCount_f  = commitCount;
  `endif

LABEL

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
  commitFission${i}  = ctrlAl${i}\[3];
LABEL
}
print "\n";

print <<LABEL; 
  commitVector_f[0] = (activeListCount>0) & ctrlAl0[2] & ~violateBit0_f    & ~exceptionBit0_f;
LABEL

for($i=1; $i<$retireWidth; $i++)
{
	print <<LABEL;
  commitVector_f[${i}] = (activeListCount>${i}) & ctrlAl${i}\[2] & ~mispredictBit${i}_f & ~mispredictBit0_f & ~violateBit${i}_f & ~exceptionBit${i}_f;
LABEL
}
print "\n";

print <<LABEL;
  /* Following makes sure the fission instrucitons retire together.
   */
LABEL

for($i=0; $i<$retireWidth-1; $i++)
{	
	$temp = $i+1;
	print <<LABEL;
  if(commitFission$i)
 	commitVector[${i}] = commitVector_f[${i}] & commitVector_f[${temp}];
  else
 	commitVector[${i}] = commitVector_f[${i}];
 
LABEL
}
print "\n";

$temp = $retireWidth-1;
print <<LABEL;
  if(commitFission${temp})
 	commitVector[${temp}] = 1'b0;
  else
 	commitVector[${temp}] = commitVector_f[${temp}];

LABEL

print <<LABEL;
  casex(commitVector)
LABEL

for($i=1; $i<$retireWidth+1; $i++)
{
	# Making the cases
	@tempArr = "";
	for($j=0; $j<$retireWidth-$i-1; $j++)
	{
		push(@tempArr, "x");
	}

	if($i != $retireWidth)
	{
		push(@tempArr, "0");
	}

	for($j=0; $j<$i; $j++)
	{
		push(@tempArr, "1");
	}
	$temp = join('', @tempArr);		

    print <<LABEL;
	$retireWidth\'b$temp:
LABEL

	print <<LABEL;
    begin
       	newheadAL     	= headAL+$i;    
 	totalCommit	= $i;
LABEL

	for($j=0; $j<$i; $j++)
	{
		print <<LABEL;
	commitValid${j}  	= dataAl${j}\[0];
	commitPacket${j} 	= dataAl${j}\[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:1];
	commitStore${j}  	= dataAl${j}\[1+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
	commitLoad${j}   	= dataAl${j}\[2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
	commitCti[${j}]	= ctrlAl${j}\[7];

LABEL
	}

print <<LABEL;
 	\`ifdef VERIFY
LABEL

	for($j=0; $j<$i; $j++)
	{
		print <<LABEL;
  	commitVerify${j} 	= 1'b1;
LABEL
	}
	print "\n";

	for($j=0; $j<$i; $j++)
	{
		$temp = $j+1;
		print <<LABEL;
 	commitCnt${j}      = commitCount+$temp;
LABEL
	}
	print "\n";

	print <<LABEL;
 	commitCount_f   = commitCount+$i;
 	`endif
    end	

LABEL
} # End of for loop

print <<LABEL;
  endcase
 end
 
 
 /* Following assigns output signals of this module.
  */
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
 assign activeListId${i}_o  = tailAL+$i;
LABEL
}
print "\n";

print <<LABEL; 
 assign activeListCnt_o  = activeListCount;

LABEL

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
 assign commitValid${i}_o   = commitValid${i};
 assign commitPacket${i}_o  = commitPacket${i};
 assign commitStore${i}_o   = commitStore${i};
 assign commitLoad${i}_o    = commitLoad${i}  & commitValid${i};
 
LABEL
}
print "\n";

print <<LABEL; 
 assign commitCti_o	= commitCti;
 
 `ifdef VERIFY
LABEL

for($i=0; $i<$retireWidth; $i++)
{
	print <<LABEL;
 assign commitPC$i	= dataAl$i\[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1];
LABEL
}
print "\n";

print <<LABEL; 
 `endif
 
 /* Following updates the Active List tail pointer:
  * If, there is a branch mispredict, move the tail pointer to the next entry of
  * the offending instruction's entry.
  * Else if, back-end ready signal is high increament the tail pointer by dispatch
  * bandwidth.
  */
 always @(posedge clk)
 begin
  if(reset || recoverFlag || mispredFlag || exceptionFlag)
  begin
 	tailAL  <= 0;
  end
  else
  begin
 	tailAL <= tailAL_f;
  end
 end
 
 
 /* Following updates the Active List head pointer:
      newheadAL is computed above depending upto the number of instruction committing
      this cycle.    
 */
 always @(posedge clk)
 begin
  if(reset || recoverFlag || mispredFlag || exceptionFlag)
  begin
 	headAL  <= 0;
  end
  else
  begin
 	headAL  <= newheadAL;
  end
 end
 
 
 /*  Follwoing maintains the active list occupancy count each cycle.
  */
 always @(posedge clk)
 begin
  if(reset || recoverFlag || mispredFlag || exceptionFlag) 
  begin
 	activeListCount	<= 0;
  end
  else
  begin
 	activeListCount	<= activeListCount_f;
  end
 end
 
  
 /*  Following maintains the recover flag register. If the recover flag is high,
  *  it should be treated like an exception. 
  */
 always @(posedge clk)
 begin
  if(reset || recoverFlag || mispredFlag || exceptionFlag)
  begin
 	recoverFlag	<= 1'b0;
 	mispredFlag	<= 1'b0;
 	exceptionFlag	<= 1'b0;
  end
  else
  begin
 	if(ctrlMispredict_f && (|activeListCount))
 	begin
 		mispredFlag	<= 1'b1;
 		targetPC	<= targetAddr0;
 		
 	end
 	if(violateBit0_f && (|activeListCount))
 	begin
 		recoverFlag	<= 1'b1;
 		recoverPC	<= dataAl0[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1];
 	end
 	if (exceptionBit0_f && (|activeListCount))
 	begin
 		\$display("TRAP Instruction is being committed");
 		exceptionFlag   <= 1'b1;
                 exceptionPC     <= dataAl0[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1]+8;
 	end
  end
 end
 
 
 
 \`ifdef VERIFY
 always @(posedge clk)
 begin:CLEAR_CTRL_AL
  integer k,l;
  reg [\`SIZE_ACTIVELIST_LOG-1:0] cnt;
 
  if(reset)
  begin
 	commitCount 		       <= 0;	
  end
  else
  begin
 	commitCount		       <= commitCount_f;
  end
 
  if(backEndReady_i)
  begin
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
 	ctrlActiveList.sram[tailAddr$i] 	<= 0;	
LABEL
}
print "\n";
 
for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
 	ldViolateVector.sram[tailAddr$i] <= 0;
LABEL
}

print <<LABEL;
  end
 
  if(1'b1)
  begin
LABEL

print " 	casex({";
for($i=$retireWidth-1; $i>=0; $i--)
{
	$comma = ",";
	if($i == 0)
	{
		$comma = "";
	}
	print "commitVerify$i$comma";
}
print "})\n";

for($i=1; $i<$retireWidth+1; $i++)
{
	# Making the cases
	@tempArr = "";
	for($j=0; $j<$retireWidth-$i-1; $j++)
	{
		push(@tempArr, "x");
	}

	if($i != $retireWidth)
	{
		push(@tempArr, "0");
	}

	for($j=0; $j<$i; $j++)
	{
		push(@tempArr, "1");
	}
	$temp = join('', @tempArr);		

    print <<LABEL;
	$retireWidth\'b$temp: begin
LABEL

	for($j=0; $j<$i; $j++)
	{
		print <<LABEL;
 				ctrlActiveList.sram[headAddr${j}] <= 0;
LABEL
	}

print <<LABEL;
	end

LABEL
} # End of for loop

	print <<LABEL;
 	endcase
  end
 end
 \`endif
 
 endmodule
 
LABEL

