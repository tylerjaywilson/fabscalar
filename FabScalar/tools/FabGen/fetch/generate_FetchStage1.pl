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
# Purpose: This script creates a Verilog module of FetchStage1.
################################################################################

my $width = 4;
my $version = "1.0";
my $minNoCliArgs = 1;
my $createFile = 0;
my $printHeader = 0;
my $moduleName;
my $outputFileName;
my $scriptName;

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
	return(log($n)/log(2));
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


$outputFileName = "FetchStage1.v";
$moduleName = "FetchStage1";

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
# Purpose: This module implements FetchStage1.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL

print  "module ", $moduleName, "(/* Following are control signals for stalling, flushing and reseting the module. */\n";
print  <<LABEL;
		input flush_i,
		input stall_i,
		input clk,
		input reset,

		input recoverFlag_i,	
		input [`SIZE_PC-1:0] recoverPC_i,	

		input exceptionFlag_i,
		input [`SIZE_PC-1:0] exceptionPC_i,

		/* flagRecoverID_i and targetAddrID_i are used to if there has been Branch
		target misprediction for Direct control instruction (resolved during ID stage).
		flagCallID_i is used only if the BTB missed the Call instruction and the 
		callPCID_i has to be pushed into RAS.
		flagRtrID_i is used only if the BTB missed the Return instruction and the
		targetAddrID_i has to be popped from RAS. 
		*/
		input flagRecoverID_i,
		input flagCallID_i,
		input [`SIZE_PC-1:0] callPCID_i,
		input flagRtrID_i,
		input [`SIZE_PC-1:0] targetAddrID_i,

		/* flagRecoverEX_i,pcRecoverEX_i and targetAddrEX_i are used if there has been Branch 
		target misprediction for Indirect control instruction (resolved during Execute stage). 
		*/
		input flagRecoverEX_i,
		input [`SIZE_PC-1:0] targetAddrEX_i,
		
		/* Update signals are used to update the Branch Predictor and BTB. The update signal comes 
		from CTI Queue in the order of program sequence for the control instructions.
		Control Inst Types: 00 = Return; 01 = Call Direct/Indirect
		10 = Jump Direct/Indirect; 11 = Conditional Branch
		*/
		input [`SIZE_PC-1:0] updatePC_i,
		input [`SIZE_PC-1:0] updateTargetAddr_i,
		input [`BRANCH_TYPE-1:0] updateBrType_i,
		input updateDir_i,
		input updateEn_i,


		/* fs1Ready_o indicates if there is any cache miss and next stage will have to wait. */
		output fs1Ready_o,
		output [`INSTRUCTION_BUNDLE-1:0] instructionBundle_o,
		output [`SIZE_PC-1:0] pc_o,
		output [`SIZE_PC-1:0] addrRAS_CP_o,	
		
		`ifdef ICACHE
		output startBlock_o,       // 0 - Even, 1 - Odd
		/* First instruction in the starting block */
		output [1:0] firstInst_o,
		`endif

LABEL

for($i=0; $i<$width; $i++)
{
	print  "\t\toutput btbHit",$i,"_o,\n";
	print  "\t\toutput [`SIZE_PC-1:0] targetAddr",$i,"_o,\n";
	print  "\t\toutput prediction",$i,"_o,\n";
}
print  "\n";

print  <<LABEL;
		/* Following I/O signals are for handling L1-Instruction cache miss.
		These signals go/come to/from lower level memory hierarchy.
		*/
		input  wrEnable_i,
		input  [`SIZE_PC-1:0] wrAddr_i,
		input  [`CACHE_WIDTH-1:0] instBlock_i,
		output miss_o,
		output [`SIZE_PC-1:0] missAddr_o
		);




/* Defining Program Counter register. */
reg [`SIZE_PC-1:0] 		PC;


/* wire and register definition for combinational logic */
wire 				updateBTB;
wire 				updateBPB;
LABEL

for($i=0; $i<$width; $i++)
{
	print  "wire \t\t\t\tprediction",$i,";\n";
}
for($i=0; $i<$width; $i++)
{
	print  "wire \t\t\t\tbtbHit",$i,";\n";
}
for($i=0; $i<$width; $i++)
{
	print  "wire [`SIZE_PC-1:0]\t\ttargetAddr",$i,";\n";
}
print  "\n";
for($i=0; $i<$width; $i++)
{
	print  "reg \t\t\t\tbtbhit",$i,";\n";
}

print  <<LABEL;
reg 				pushras;
reg [`SIZE_PC-1:0] 		pushaddr;
reg 				popras;
wire [`SIZE_PC-1:0] 		addrRAS;
wire [`SIZE_PC-1:0] 		addrRAS_CP;
LABEL
for($i=0; $i<$width; $i++)
{
print  "wire [1:0]\t\t\tbtbCtrlType",$i,";\n";
}

print  <<LABEL;
wire 				miss;

wire 				targetAddrID;
reg [`SIZE_PC-1:0] 		nextPC;



/* updateBPB signal is brach predictor table update enabler. This is 1 
* only if control instruction type is conditional branch. 
* In case of conditional branches, update the BTB only if the direction is
* Taken.
* The update signals come from CTI Queue in program order. 
*/
assign updateBPB = (updateEn_i & updateBrType_i[0] & updateBrType_i[1]);
assign updateBTB = (updateBrType_i == 2'b11) ? (updateDir_i&updateEn_i) : updateEn_i;


/* Instantiating Branch prediction and BTB Unit. 
*/
BTB btb(.PC_i(PC),
		.updateEn_i(updateBTB),
		.updatePC_i(updatePC_i),
		.updateBrType_i(updateBrType_i),
		.updateTargetAddr_i(updateTargetAddr_i),
		.stall_i(stall_i),
		.btbFlush_i(1'b0),
		.clk(clk),
		.reset(reset),
LABEL


for($i=0; $i<$width; $i++)
{
	print  "\t\t.btbHit",$i,"_o(btbHit",$i,"),\n";
	print  "\t\t.ctrlType",$i,"_o(btbCtrlType",$i,"),\n";
	print  "\t\t.targetAddr",$i,"_o(targetAddr",$i,")";
	if($i<$width-1)
	{
		print  ",";
	}
	print  "\n";
}


print  <<LABEL;
		);


BranchPrediction bp(.pc_i(PC),
		.updateDir_i(updateDir_i),
		.updatePC_i(updatePC_i),
		.updateEn_i(updateBPB),
		.stall_i(stall_i),
		.bpFlush_i(1'b0),
		.clk(clk),
		.reset(reset),
LABEL
for($i=0; $i<$width; $i++)
{
	print  "\t\t.prediction",$i,"_o(prediction",$i,")";
	if($i<$width-1)
	{
		print  ",";
	}
	print  "\n";
}

print  <<LABEL;
		); 



/* Instantiating Return Address Stack (RAS). 
*/
RAS ras(.flagRecoverID_i(flagRecoverID_i&~stall_i),
	.flagCallID_i(flagCallID_i),
	.callPCID_i(callPCID_i),
	.flagRtrID_i(flagRtrID_i),
	.flagRecoverEX_i(1'b0),
	.pop_i(popras&~stall_i),
	.push_i(pushras&~stall_i),
	.pushAddr_i(pushaddr),
	.stall_i(stall_i),
	.flushRas_i(1'b0),
	.pc_i(PC),
	.clk(clk),
	.reset(reset),
	.addrRAS_o(addrRAS),
	.addrRAS_CP_o(addrRAS_CP)
	);



/* Instantiating Level-1 Instruction Cache. 
*/
L1ICache l1icache(	.clk(clk),
			.reset(reset),
			.addr_i(PC),
			.rdEnable_i(stall_i),
			.wrEnabale_i(wrEnable_i),
			.wrAddr_i(wrAddr_i),
			.instBlock_i(instBlock_i),
			.instBundle_o(instructionBundle_o),
			.miss_o(miss),
			.missAddr_o(missAddr_o)
		);			



`ifdef ICACHE
/* Instantiating select instruction, this module generates control signal to 
select 4 contiguous instructions from the 2 read block in a cycle from 
instruction cache. 
*/
SelectInst selectinst(	.pc_i(PC),
			.startBlock_o(startBlock_o),	
			.firstInst_o(firstInst_o)
			);
`endif


/* Following logic generates the next PC. This is the priority encoder and higher priority 
is given to any recovery from Next stage or Execute stage. The least priority is given 
to PC plus 16. 

If there is BTB hit then the target address comes from BTB for the
non-return instruction else comes from the RAS for return instruction.
*/
always @(*)
begin:NEXT_PC
	reg [`SIZE_PC-1:0] pcPlus1;
LABEL

for($i=0; $i<$width; $i++)
{
print  "\treg check",$i,"Branch;\n";
}
print  "\n";
for($i=0; $i<$width; $i++)
{
print  "\tcheck",$i,"Branch  =  ~(btbCtrlType",$i,"[0] & btbCtrlType",$i,"[1]);\n";
}
print  "\n";
for($i=0; $i<$width; $i++)
{
print  "\tbtbhit",$i,"  = btbHit",$i," & (prediction",$i," | check",$i,"Branch);\n";
}

my $pc_inc = $width * 8;
print  <<LABEL;

	nextPC  = PC + ${pc_inc};

LABEL


print  "\tcasex({flagRecoverEX_i,flagRecoverID_i";
for($i=0; $i<$width; $i++)
{
	print  ",btbhit",$i,"";
}
print  "})\n";
print  "\t",$width+2,"'b1";
for($i=0; $i<$width+1; $i++)
{
print  "x";
}
print  ":\n";
print  <<LABEL;
	begin
		nextPC = targetAddrEX_i;
	end
LABEL
print  "\t",$width+2,"'b01";
for($i=0; $i<$width; $i++)
{
	print  "x";
}
print  ":\n";
print  <<LABEL;
	begin
		if(flagRtrID_i)
			nextPC = addrRAS_CP;	
		else
			nextPC = targetAddrID_i;
	end
LABEL

for($i=$width; $i>0; $i--)
{
	print  "\t",$width+2,"'b";
	for($j=$width+2; $j>0; $j--) {
		if($j>$i)
		{
			print  "0";
		}
		elsif($j==$i)
		{
			print  "1";
		}
		else
		{
			print  "x";
		}
	}
	print  ":\n";
	print  "\tbegin\n";
	print  "\t\tif(btbCtrlType",$width-$i," == 2'b00)\n";
	print  "\t\t\tnextPC = addrRAS;\n";
	print  "\t\telse\n";
	print  "\t\t\tnextPC = targetAddr",$width-$i,";\n";
	print  "\tend\n";
}
print  "\tendcase\n";
print  "end\n";


print  <<LABEL;



/* Following logic checks if there is any call instruction in the set  
of fetching instructions. If there is any call then the address is 
pushed into the RAS. 
*/
always @(*)
begin:PUSH_RAS
	pushras  = 0; 
	pushaddr = PC;
LABEL


print  "\tcasex({";
for($i=0; $i<$width; $i++)
{
	print  "btbhit",$i,"";
	if($i<$width-1)
	{
		print  ","
	}
}
print  "})\n";
for($i=$width; $i>0; $i--)
{
	print  "\t",$width,"'b";
	for($j=$width; $j>0; $j--) {
		if($j>$i)
		{
			print  "0";
		}
		elsif($j==$i)
		{
			print  "1";
		}
		else
		{
			print  "x";
		}
	}
	print  ":\n";
	print  "\tbegin\n";
	print  "\t\tif(btbCtrlType",$width-$i," == 2'b01)\n";
	print  "\t\tbegin\n";
	print  "\t\t\tpushras  = 1'b1;\n";
	print  "\t\t\tpushaddr = PC + ",($width-$i+1)*8,";\n";	
	print  "\t\tend\n";	 
	print  "\tend\n";
}
print  "\tendcase\n";
print  "end\n";

print  <<LABEL;



/* Following logic checks if there is any return instruction in the set
of fetching instructions. If there is any return then the address is
popped from the RAS. 
*/
always @(*)
begin:POP_RAS
popras  = 0;
LABEL


print  "\tcasex({";
for($i=0; $i<$width; $i++)
{
	print  "btbhit",$i,"";
	if($i<$width-1)
	{
		print  ","
	}
}
print  "})\n";
for($i=$width; $i>0; $i--)
{
	print  "\t",$width,"'b";
	for($j=$width; $j>0; $j--) {
		if($j>$i)
		{
			print  "0";
		}
		elsif($j==$i)
		{
			print  "1";
		}
		else
		{
			print  "x";
		}
	}	
	print  ":\n";
	print  "\tbegin\n";
	print  "\t\tif(btbCtrlType",$width-$i," == 2'b00)\n";
	print  "\t\tbegin\n";
	print  "\t\t\tpopras  = 1'b1;\n";
	print  "\t\tend\n";	 
	print  "\tend\n";
}
print  "\tendcase\n";
print  "end\n";

print  <<LABEL;



/* Following drives signals for module's outputs */
assign pc_o 		= PC;
LABEL
for($i=0; $i<$width; $i++)
{
	print  "assign btbHit",$i,"_o\t= btbHit",$i,";\n";
	print  "assign targetAddr",$i,"_o\t= (btbCtrlType",$i," == 2'b00) ? addrRAS:targetAddr",$i,";\n";
	print  "assign prediction",$i,"_o\t= prediction",$i,";\n";
}
print  <<LABEL;
assign fs1Ready_o    	= ~miss;
assign miss_o        	= miss;

assign addrRAS_CP_o   	= addrRAS_CP;



/* Following updates the nextPC to the Program Counter. 
*/
always @(posedge clk)
begin
	if(reset)
	begin
		`ifdef VERIFY
		PC 	<= \$getArchPC();
		`else
		PC      <= 0;
		`endif
	end
	else if(recoverFlag_i)
	begin
		PC 	<= recoverPC_i;
	end
	else if(exceptionFlag_i)
	begin
		PC      <= exceptionPC_i;
	end
	else
	begin
	if(flagRecoverEX_i || ~stall_i) 
		PC 	<= nextPC;
	end 
end


endmodule
LABEL
