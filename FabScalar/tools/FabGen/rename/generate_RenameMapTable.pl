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
# Purpose: This script creates RenameMapTable.v file.
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
$outputFileName = "RenameMapTable.v";
$moduleName = "RenameMapTable";

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
# Purpose: This block implements the Rename Map Table (RMT).
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps



/***************************************************************************
  The Register Map Table (RMT) conatins the current logical register to 
  physical register mapping. 

  For each set of instructions in Rename stage the physical source register
  mapping is obtained by reading the RMT and the physical destination 
  register mapping is obtained by reading the Free List table. 
  Eventually, the new logical destination register and physical register 
  mapping is updated in the RMT for the future set of the instructions.

  While recovery RMT recieves 4 in-order logial to physical register mapping
  from each Architecture Map Table (AMT). Appropriate ports have been provided
  for the recovery purpose.
  
***************************************************************************/

/* Algorithm
 
 1. Receives 4 or 0 new decoded instructions from the previous (i.e. decode)
    stage.

 2. Also receives 4 new physical registers from the Speculative free list,
    if the list is not empty. 
    If list is empty, pipeline stages after instruction buffer and till 
    rename is stalled.

 3. 

***************************************************************************/


LABEL

print <<LABEL;
module $moduleName(
			input 				clk,
            input 				reset,
			input 				stall_i,

LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                        input [`SIZE_RMT_LOG:0] 	src${i}logical1_i,
                        input [`SIZE_RMT_LOG:0] 	src${i}logical2_i,
                        input [`SIZE_RMT_LOG:0] 	inst${i}Dest_i,
LABEL
}
print "\n";

print <<LABEL;
			input 				flagRecoverEX_i,	

		        /* Four physical registers are popped from the Spec free
                           list for logical to physical register mapping.
			*/

LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                        input [`SIZE_PHYSICAL_LOG:0] 	dest${i}Physical_i,
LABEL
}
print "\n";

print <<LABEL;
                        /* Recover flag is high if there is any exception. Architectural
                           map table is copied to RMT in a group of four mappings.
 			*/
                        input 				recoverFlag_i,						
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
			input [`SIZE_RMT_LOG-1:0] 	recoverDest${i}_i,
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
			input [`SIZE_PHYSICAL_LOG-1:0] 	recoverMap${i}_i,
LABEL
}

for($i=0; $i<$dispatchWidth; $i++)
{
	$comma = ($i == $dispatchWidth-1)? "" : ",";
	print <<LABEL;

		    output [`SIZE_PHYSICAL_LOG:0] 	src${i}rmt1_o,
            output [`SIZE_PHYSICAL_LOG:0] 	src${i}rmt2_o,
            output [`SIZE_PHYSICAL_LOG:0] 	dest${i}PhyMap_o,
			output [`SIZE_PHYSICAL_LOG:0] 	old${i}PhyMap_o$comma
LABEL
}
print "\n";

print <<LABEL;
                     );



/* Instantiating RMT register file */
reg [`SIZE_PHYSICAL_LOG-1:0] RMT [`SIZE_RMT-1:0];



/* wires and regs definition for combinational logic. */
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
reg  [`SIZE_PHYSICAL_LOG:0] 		dest${i}Physical;
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth-1; $i++)
{
	print <<LABEL;
reg 					dontWrite${i}RMT;
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
wire 					writeEn${i};
LABEL
}
print "\n";


print <<LABEL;
/* Following defines wires for checking true dependencies between 
   the source and preceding destination registers.
*/
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_PHYSICAL_LOG-1:0] 		src${i}physical1_r;
wire [`SIZE_PHYSICAL_LOG-1:0] 		src${i}physical2_r;
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
wire [`SIZE_PHYSICAL_LOG:0] 		src${i}physical1;
wire [`SIZE_PHYSICAL_LOG:0] 		src${i}physical2;
LABEL
	
	for($k=1; $k<=2; $k++) # For 1 and 2
	{
		for($j=0; $j<$i; $j++)
		{
			$temp = ($i == 1)? "" : "$j";
			print <<LABEL;
wire [`SIZE_PHYSICAL_LOG:0] 		src${i}physical${k}F$temp;
LABEL
		}
	}
	print "\n";
}

print <<LABEL;
/*******************************************************************************  
* Following instantiates RAM modules for Rename Map Table. The read and
* write ports depend on the commit width of the processor.
*
* An instruction updates the RMT only if it has valid destination register and 
* it does not matches with destination register of the newer instruction in the 
* same window.
*******************************************************************************/
LABEL

$temp = 2*$dispatchWidth;
print <<LABEL;
 SRAM_${temp}R${dispatchWidth}W_RMT #(`SIZE_RMT,`SIZE_RMT_LOG,`SIZE_PHYSICAL_LOG)
    RenameMap (
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	$temp=2*$i;
	$temp2 = $temp+1;
	print <<LABEL;
                 .addr${temp}_i(src${i}logical1_i[`SIZE_RMT_LOG:1]),
                 .addr${temp2}_i(src${i}logical2_i[`SIZE_RMT_LOG:1]),
LABEL
}

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
                 .we${i}_i(writeEn${i}),
                 .addr${i}wr_i(inst${i}Dest_i[`SIZE_RMT_LOG:1]),
                 .data${i}wr_i(dest${i}Physical[`SIZE_PHYSICAL_LOG:1]),
LABEL
}

print <<LABEL;
                 .clk(clk),
                 .reset(reset),
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	$temp=2*$i;
	$temp2 = $temp+1;
	$comma = ($i == $dispatchWidth-1)? "" : ",";
	print <<LABEL;
                 .data${temp}_o(src${i}physical1_r),
                 .data${temp2}_o(src${i}physical2_r)$comma
LABEL
}

print <<LABEL;
              );


/*******************************************************************************
* Following assigns physical registers (popped from the spec free list)
* to the destination registers.
*******************************************************************************/
always @(*)
begin
LABEL

print "case({";
for($i=$dispatchWidth-1; $i>=0; $i--)
{
	$comma = ($i == 0)? "" : ",";
	print "inst${i}Dest_i[0]$comma";
}
print "})\n";

for($i=0; $i<2**$dispatchWidth; $i++)
{
	$temp = sprintf("%0${dispatchWidth}b", $i);
	print <<LABEL;
  ${dispatchWidth}'b$temp:
    begin
LABEL
	
	@tempArr = split(//, $temp);
	$k = 0;
	for($j=0; $j<$dispatchWidth; $j++)
	{
		if($tempArr[$dispatchWidth-1-$j] == "0")
		{
			print <<LABEL;
      dest${j}Physical  = 0;
LABEL
		}
		else
		{
			print <<LABEL;
      dest${j}Physical  = dest${k}Physical_i;
LABEL
			$k++;
		}
	}
	print <<LABEL;
    end
LABEL
}

print <<LABEL;
 endcase
end



/*  Check if destination of an instruction matches with destination of the newer
 *  instruction in the rename window. If there is a match then this instruction
 *  doesn't update the RMT.
 */
always @(*)
begin
LABEL

for($i=0; $i<$dispatchWidth-1; $i++)
{
	print "\tif(";
	for($j=$i+1; $j<$dispatchWidth; $j++)
	{
		$comma = ($j == $dispatchWidth-1)? "" : " ||\n";
		$temp = ($j == $i+1)? "" : "\t\t";
		print "${temp}inst${i}Dest_i == inst${j}Dest_i$comma";
	}

	print ") dontWrite${i}RMT = 1;\n";
	print <<LABEL;
  else
     dontWrite${i}RMT = 0;

LABEL
}

print <<LABEL;
end




/* Reading Physical register mapping of each valid source register
 * from RMT if valid bit is 1. 
 */
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
assign src${i}physical1 = (src${i}logical1_i[0]) ? {src${i}physical1_r,1'b1}:0;
assign src${i}physical2 = (src${i}logical2_i[0]) ? {src${i}physical2_r,1'b1}:0;

LABEL
}


for($i=1; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
/* Checking data dependency between Instruction-$i source registers
   and preceding instructions' destination registers.  */
LABEL
	for($k=1; $k<=2; $k++) # For 1 and 2
	{
		for($j=0; $j<$i; $j++)
		{
			$temp = ($i == 1)? "" : "$j";
			$temp3 = $j-1;
			$temp2 = ($j == 0)? "" : "F$temp3"; 
			print <<LABEL;
assign src${i}physical${k}F$temp    = (src${i}logical${k}_i == inst${j}Dest_i) ? dest${j}Physical:src${i}physical${k}$temp2;
LABEL
		}
	}
	print "\n";
}
print "\n";


print <<LABEL;
/* Assigning renamed logical source and destination registers to output. */
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	$temp2 = $i-1;
	$temp = ($i == 0)? "" : (($i == 1)? "F" : "F$temp2");
	print <<LABEL;
assign src${i}rmt1_o    = src${i}physical1$temp;
assign src${i}rmt2_o    = src${i}physical2$temp;
assign dest${i}PhyMap_o = dest${i}Physical; 

LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
assign old${i}PhyMap_o   = 0;
LABEL
}
print "\n";

print <<LABEL;
/* Updating new Logical to Physical Mappings into the RMT table. */
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	$temp = ($i == $dispatchWidth-1)? ";" : "& ~dontWrite${i}RMT;";
	print <<LABEL;
assign writeEn$i       = ~recoverFlag_i & ~stall_i & inst${i}Dest_i[0]$temp
LABEL
}
print "\n";

print <<LABEL;
`ifdef VERIFY
always @(posedge clk)
begin:RMT_UPDATE
 integer i;
 if(recoverFlag_i)
 begin
	for(i=0;i<`SIZE_RMT;i=i+1)
     	begin
        	simulate.fabScalar.rename.RMT.RenameMap.sram[i]  <= simulate.fabScalar.amt.AMT.sram[i];
     	end
 end
end
`endif


endmodule
LABEL
