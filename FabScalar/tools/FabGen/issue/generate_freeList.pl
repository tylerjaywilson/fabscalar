#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw(ceil floor);

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
# Purpose: This script creates Verilog for the free list management module.
################################################################################

my $version = "1.1";

my $scriptName;
my $outputFileName;
my $moduleName;
my $minEssentialCLIArgs = 3;

my $dispatchWidth = 4;
my $issueWidth = 4;
my $iqSize = 32;
my $iqSizeLog = 5;

my $printHeader = 0;

my $i;
my $j;
my $k;
my $temp;
my $temp2;
my $tempCount;
my $tempStr;
my @t;

sub fatalUsage
{
	print "Usage: perl $scriptName -d <dispatch_width> -i <issue_width> -s <iq_size> [-m] [-v] [-h]\n";
	print "-m:\tAdd header\n";
	print "\t-v: Print version and exit\n";
	print "\t-h: Show usage help and exit\n";
	exit;
}

sub log2 
{
	my $n = shift;
	my $ret_val = ceil(log($n)/log(2));
	return $ret_val;
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
	elsif(/^-i$/)
	{
		$issueWidth = shift;
		$essentialCLIArgs++;
	}
	elsif(/^-s$/)
	{
		$iqSize = shift;
		$iqSizeLog = &log2($iqSize);
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
		print "Error: Unrecognized argument $_.\n";
		&fatalUsage();
	}
}

if($essentialCLIArgs < $minEssentialCLIArgs)
{
	print "\nError: Too few inputs\n";
	&fatalUsage();
}

$outputFileName = "IssueQFreeList.v";
$moduleName = "IssueQFreeList";

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

/***************************************************************************

  Assumption:  $issueWidth-instructions can be issued and 
  4(?)-instructions will retire in one cycle from Active List.
	
There are $issueWidth ways and upto $issueWidth issue queue entries
can be freed in a clock cycle.

***************************************************************************/

LABEL

# Module header
print <<LABEL;
module IssueQFreeList(
	input clk,
	input reset,

	/* control execution flags from the Writeback Stage. If 
	* ctrlMispredict_i is 1, there has been a mis-predict. */
	input ctrlVerified_i,                    
	input ctrlMispredict_i,
	input [`SIZE_ISSUEQ-1:0] mispredictVector_i,

	input backEndReady_i,

	/* $issueWidth entries being freed once they have been issued. */
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print "\tinput [`SIZE_ISSUEQ_LOG-1:0] grantedEntry", $i, "_i,\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "\tinput grantedValid", $i, "_i,\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "\toutput [`SIZE_ISSUEQ_LOG-1:0] freedEntry", $i, "_o,\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "\toutput freedValid", $i, "_o,\n";
}
print "\n";

print <<LABEL;
	/* $dispatchWidth free Issue Queue entries for the new coming 
	* instructions. */
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print "\toutput [`SIZE_ISSUEQ_LOG-1:0] freeEntry", $i, "_o,\n";
}
print "\n";

print <<LABEL;
/* Count of Valid Issue Q Entries goes to Dispatch */
	output [`SIZE_ISSUEQ_LOG:0] cntInstIssueQ_o
);

LABEL
# Module head

print <<LABEL;
/***************************************************************************/
/* Instantiating SPEC FREE LIST Table & head/tail pointers */
reg [`SIZE_ISSUEQ_LOG-1:0] ISSUEQ_FREELIST [`SIZE_ISSUEQ-1:0];
reg [`SIZE_ISSUEQ_LOG-1:0] headPtr;
reg [`SIZE_ISSUEQ_LOG-1:0] tailPtr;

reg [`SIZE_ISSUEQ_LOG:0] issueQCount;	

/* Declaring wires and regs for Combinational Logic */
reg [`SIZE_ISSUEQ_LOG:0] issueQCount_f;
reg [`SIZE_ISSUEQ_LOG-1:0] headptr_f;
reg [`SIZE_ISSUEQ_LOG-1:0] tailptr_f;

integer i;

LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print "wire [`SIZE_ISSUEQ_LOG-1:0] freedEntry", $i, ";\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "wire freedValid", $i, ";\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "wire [`SIZE_ISSUEQ_LOG-1:0] wr_index", $i, ";\n";
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print "reg [`SIZE_ISSUEQ_LOG-1:0] rd_index", $i, ";\n";
}
print "\n\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "assign freedValid", $i, "_o = freedValid", $i, ";\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "assign freedEntry", $i, "_o = freedEntry", $i, ";\n";
}
print "\n";

print <<LABEL;
/* Sending Issue Queue occupied entries to Dispatch. */
assign cntInstIssueQ_o 	= issueQCount;

LABEL

print <<LABEL;
/* Pops 4 free Issue Queue entries from the FREE LIST for the new coming
* instructions. */
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print "assign freeEntry", $i, "_o = ISSUEQ_FREELIST[rd_index", $i, "];\n";
}
print "\n";

print <<LABEL;
/* Generates read addresses for the FREELIST FIFO, using head pointer. */
always @(*)
begin
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print "\trd_index", $i, " = headPtr + ", $i, ";\n";
}
print "end\n";


print <<LABEL;
always @(*)
begin: ISSUEQ_COUNT
	reg isWrap1;
	reg [`SIZE_ISSUEQ_LOG:0] diff1;
	reg [`SIZE_ISSUEQ_LOG:0] diff2;
	reg [`ISSUE_WIDTH-1:0] totalFreed;

	headptr_f = (backEndReady_i) ? (headPtr+`DISPATCH_WIDTH) : headPtr;
LABEL

print "\ttailptr_f = (tailPtr + (";
for($i=$issueWidth-1; $i>=0; $i--)
{
	print "freedValid", $i;
	if($i != 0)
	{
		print " + ";
	}
	else
	{
		print "));\n";
	}
}

print "\ttotalFreed = (";
for($i=$issueWidth-1; $i>=0; $i--)
{
	print "freedValid", $i;
	if($i != 0)
	{
		print " + ";
	}
	else
	{
		print ");\n";
	}
}

print <<LABEL;
	issueQCount_f = (issueQCount+ ((backEndReady_i) ? `DISPATCH_WIDTH:0)) - totalFreed;
end

LABEL

print <<LABEL;
/* Following updates the Free List Head Pointer, only if there is no control
* mispredict. */
always @(posedge clk)
begin
	if(reset)
	begin
		headPtr <= 0;
	end
	else
	begin
		if(~ctrlMispredict_i)
			headPtr <= headptr_f;
	end
end


/* Follwoing maintains the issue queue occupancy count each cycle. */
always @(posedge clk)
begin
	if(reset)
	begin
		issueQCount <= 0;
	end
	else
	begin
		issueQCount <= issueQCount_f;
	end
end

LABEL

print <<LABEL;
/* Following updates the FREE LIST counter and pushes the freed Issue 
*  Queue entry into the FREE LIST. */
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print "assign wr_index", $i, " = tailPtr + ", $i, ";\n";
}
print "\n";


print <<LABEL;
always @(posedge clk)
begin: WRITE_FREELIST
	if(reset)
	begin
		for (i=0;i<`SIZE_ISSUEQ;i=i+1)
			ISSUEQ_FREELIST[i] <= i;

		tailPtr <= 0;
	end
	else
	begin
		tailPtr	<= tailptr_f;		

LABEL

print "\t\tcase({";
for($i=$issueWidth-1; $i>=0; $i--)
{
	print "freedValid", $i;
	if($i != 0)
	{
		print ", ";
	}
	else
	{
		print "})\n";
	}
}

for($j=1; $j<(2**$issueWidth); $j++)
{
	$temp = sprintf("%0${issueWidth}b", $j);
	print "\t\t\t", $issueWidth, "'b", $temp,":\n";
	print "\t\t\tbegin\n";
	
	$tempCount = 0;
	for($i=0; $i<$issueWidth; $i++)
	{
		if(((1 << $i) & $j) != 0) 
		{
			print "\t\t\t\tISSUEQ_FREELIST[wr_index", $tempCount, "] <= freedEntry", $i, ";\n";
			$tempCount++;
		}
	}
	
	print "\t\t\tend\n";
}
print <<LABEL;
		endcase
	end
end

LABEL

print <<LABEL;
FreeIssueq freeIq (.clk(clk),
	.reset(reset),
	.ctrlVerified_i(ctrlVerified_i),
	.ctrlMispredict_i(ctrlMispredict_i),
	.mispredictVector_i(mispredictVector_i),
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print "\t.grantedEntry", $i, "_i(grantedEntry", $i, "_i),\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "\t.grantedValid", $i, "_i(grantedValid", $i, "_i),\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "\t.freedEntry", $i, "_o(freedEntry", $i, "),\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "\t.freedValid", $i, "_o(freedValid", $i, ")";
	if($i != $issueWidth - 1)
	{
		print ",";
	}
	print "\n";
}

print <<LABEL;
);

endmodule

LABEL


print <<LABEL;
module FreeIssueq (
	input clk,
	input reset,
		    
	/* control execution flags from the Writeback Stage. if
	* ctrlMispredict_i is 1, there has been a mis-predict. */
	input ctrlVerified_i,
	input ctrlMispredict_i,
	
	/* mispredicted vector is set of issue queue entries 
	* invalidated due to branch misprediction. These entries
	* should be inserted into issue queue free list. */
	input [`SIZE_ISSUEQ-1:0] mispredictVector_i,

	/* $issueWidth entries being freed once they have been issued. */
LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print "\tinput [`SIZE_ISSUEQ_LOG-1:0] grantedEntry", $i, "_i,\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "\tinput grantedValid", $i, "_i,\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "\toutput [`SIZE_ISSUEQ_LOG-1:0] freedEntry", $i, "_o,\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "\toutput freedValid", $i, "_o";
	if($i != $issueWidth - 1)
	{
		print ",";
	}
	print "\n";
}
print ");\n\n";

print <<LABEL;
reg [`SIZE_ISSUEQ-1:0] freedVector;

/* wires and regs declaration for combinational logic. */
reg [`SIZE_ISSUEQ-1:0] freedVector_t;

LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print "wire freeingScalar0", $i, ";\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "wire [`SIZE_ISSUEQ_LOG-1:0] freeingCandidate0", $i, ";\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "reg [`SIZE_ISSUEQ_LOG-1:0] freedEntry", $i, ";\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "reg freedValid", $i, ";\n";
}
print "\n";

print "reg [`SIZE_ISSUEQ-1:0] freedVector_t1;\n\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "assign freedValid", $i, "_o = freedValid", $i, ";\n";
}
print "\n";

for($i=0; $i<$issueWidth; $i++)
{
	print "assign freedEntry", $i, "_o = freedEntry", $i, ";\n";
}
print "\n";


print <<LABEL;
/* Following combinational logic updates the freedValid vector based on:
 *	1. if there are instructions issued this cycle from issue queue 
 *	  (they need to be freed)
 *      2. if there is a branch mispredict this cycle, freedVector need to
 *	   be updated with mispredictVector.
 *	3. if a issue queue entry has been freed this cycle, its corresponding
 *	   bit in the freedVector should be set to 0. */

always @(*)
begin: UPDATE_FREED_VECTOR
	integer i;

LABEL

for($i=0; $i<$issueWidth; $i++)
{
	print "\tfreedValid", $i, " = freeingScalar0", $i, ";\n";
}
print "\n";

# Now the issue queue size needs to be split into $issueWidth pieces. The case that the former is not a multiple of the latter must be handled
my @iqSplit;
my @iqSplitCumm; # Cummulative array of iqSplit
my @iqSplitUniq; # uniq of @iqSplit

for($i=0; $i<$issueWidth; $i++)
{
	if($i < $iqSize % $issueWidth)
	{
		$iqSplit[$i] = int($iqSize/$issueWidth)+1;
	}
	else
	{
		$iqSplit[$i] = int($iqSize/$issueWidth);
	}
}

$iqSplitCumm[0] = 0;
for($i=1; $i<($#iqSplit+2); $i++)
{
	$iqSplitCumm[$i] = $iqSplitCumm[$i-1] + $iqSplit[$i-1];
}

$iqSplitUniq[0] = $iqSplit[0];
$j = 0;
for($i=1; $i<($#iqSplit+1); $i++)
{
	if($iqSplitUniq[$j] != $iqSplit[$i])
	{
		$j++;
		$iqSplitUniq[$j] = $iqSplit[$i];
	}
}

for($i=0; $i<$issueWidth; $i++)
{
	print "\tif(freeingScalar0", $i, ")\n";
	print "\t\tfreedEntry", $i, " = ", $iqSizeLog, "'d", $iqSplitCumm[$i], " + freeingCandidate0", $i, ";\n";
	print "\telse\n";
	print "\t\tfreedEntry", $i, " = ", $iqSizeLog, "'d0;\n\n";
}

print <<LABEL;
	if(ctrlMispredict_i)
		freedVector_t1 = freedVector | mispredictVector_i;
	else
		freedVector_t1 = freedVector;
		
	for(i=0;i<`SIZE_ISSUEQ;i=i+1)	
	begin
LABEL

print "\t\tif(";
for($i=0; $i<$issueWidth; $i++)
{
	if($i != 0)
	{
		print "\t\t";
	}
	print "(grantedValid", $i, "_i && (i == grantedEntry", $i, "_i))";
	if($i != $issueWidth-1)
	{
		print " ||\n";
	}
	else
	{
		print ")\n";
	}
}
print "\t\t\tfreedVector_t[i] = 1'b1;\n";
print "\t\telse if(";
for($i=0; $i<$issueWidth; $i++)
{
	if($i != 0)
	{
		print "\t\t";
	}
	print "(freedValid", $i, " && (i == freedEntry", $i, "))";
	if($i != $issueWidth-1)
	{
		print " ||\n";
	}
	else
	{
		print ")\n";
	}
}

print <<LABEL;
			freedVector_t[i] = 1'b0;
		else
			freedVector_t[i] = freedVector_t1[i];
	end
end

LABEL


print <<LABEL;
/* Following writes newly computed freed vector to freedVector register every cycle. */
always @(posedge clk)
begin
	if(reset)
	begin
		freedVector <= 0;
	end
	else
	begin
		freedVector <= freedVector_t;
	end	 	
end

/* Following instantiate "selectFromBlock" module to get upto $issueWidth freed issue queue
 * entries this cycle. */
LABEL


for($i=0; $i<($#iqSplitCumm); $i++)
{
	if($i < $iqSize % $issueWidth) # meaning $iqSplit[$i] = int($iqSize/$issueWidth)+1;
	{
		print "selectFromBlock_1 selectFromBlock0", $i, "_l1(.blockVector_i(freedVector[", $iqSplitCumm[$i+1]-1, ":", $iqSplitCumm[$i], "]),\n";
	}
	else
	{
		print "selectFromBlock_0 selectFromBlock0", $i, "_l1(.blockVector_i(freedVector[", $iqSplitCumm[$i+1]-1, ":", $iqSplitCumm[$i], "]),\n";
	}
	

	print "\t.freeingScalar_o(freeingScalar0", $i, "),\n";
	print "\t.freeingCandidate_o(freeingCandidate0", $i, ")\n";
	
	print ");\n\n";
}

print "endmodule\n\n";


my $blockWidth;

# selectFromBlock_0 and selectFromBlock_1
for($j=0; $j<$#iqSplitUniq+1; $j++)
{

#$blockWidth = int($iqSize/$issueWidth)+$j;
$blockWidth = $iqSplitUniq[$j];
$temp = $blockWidth-1;

$temp2 = $#iqSplitUniq-$j;
print <<LABEL;

module selectFromBlock_${temp2}(input [$temp:0] blockVector_i,
	output freeingScalar_o,
	output [`SIZE_ISSUEQ_LOG-1:0] freeingCandidate_o   			
);

LABEL

print <<LABEL;
reg freeingScalar;
reg [`SIZE_ISSUEQ_LOG-1:0] freeingCandidate;

assign freeingCandidate_o = freeingCandidate;
assign freeingScalar_o = freeingScalar;

always @(*)
begin:FIND_FREEING_CANDIDATE_${j}
LABEL

print "\tcasex({";
for($i=$blockWidth-1; $i>=0; $i--)
{
	print "blockVector_i[$i]";
	if($i != 0)
	{
		print ", ";
	}	
}
print "})\n";

for($i=0; $i<$blockWidth; $i++)
{
	
	$temp = "";
	for($k=$blockWidth-1; $k>=0; $k--)
	{
		if($k == $i)
		{
			$temp = $temp."1";
		}
		elsif($k < $i)
		{
			$temp = $temp."0";
		}
		elsif($k > $i)
		{
			$temp = $temp."x";
		}
	}

	print "\t\t", $blockWidth, "'b", $temp, ":\n";
	print "\t\tbegin\n";

	$temp = sprintf("%0${iqSizeLog}b", $i);
	print "\t\t\tfreeingCandidate = ", $iqSizeLog, "'b", $temp, ";\n";
	print "\t\t\tfreeingScalar = 1'b1;\n";
	print "\t\tend\n";
}

print <<LABEL;
 		default:
 		begin
  			freeingCandidate = 0;
  			freeingScalar = 0;
  		end
LABEL

print "\tendcase\n";
print "end\n\n";
print "endmodule\n\n";


} # End of instantiations of selectFromBlock

