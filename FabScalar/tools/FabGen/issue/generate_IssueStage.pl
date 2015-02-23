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
# Purpose: This script creates Verilog for the issue folder.
################################################################################

require "../path.pl";

my $PATH = &returnPath();
my $stage = "issue";
my $pmemStage = "pmems";

my $version = "1.1";

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 8;

my $dispatchWidth = 4;
my $iqSize = 32;
my $depth = 2;
my $selectBlockSize = 8;
my $typesOfFUs = 4; # HARDWIRED!
my @fuNo;   # Number of execute ways of each instruction type (they are always adjacent)
my @whereFU;  # A two dimensional array with 4 rows (for each instruction type), telling which ways support that type.
my $issueWidth;
my $passTags = "";

my $printHeader = 0;

my $i;
my $j;
my $temp;
my $temp2;
my $tempCount;
my $tempStr;
my @tempArr;

sub fatalUsage
{
	print "\n";
	print "Usage: perl $scriptName -w <dispatch_width> -i <IQ_entries> -d <issue_depth> -s <selectTree_blocksize> -n A B C D [-t] [-m] [-v] [-h]\n";
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
	elsif(/^-s$/)
	{
		$selectBlockSize = shift;
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
		$passTags = "-t";
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

# Generate the -n string
my $nString = sprintf("%s", join(" ", @fuNo));

# Generate the -m string
my $mString;
if($printHeader == 1)
{
	$mString = "-m";
}
else
{
	$mString = "";
}

# Set up directory for generation
if(-d "$PATH/$stage")
{
	`rm -f $PATH/$stage/IssueQFreeList.v  $PATH/$stage/issueqRegRead.v  $PATH/$stage/IssueQSelect.v  $PATH/$stage/IssueQueue.v  $PATH/$stage/RSR.v`;
}

if(-d "$PATH/$pmemStage")
{
	`rm -f $PATH/$pmemStage/CAM_*.v`;
}


# Generate RSR
my $minusP = "";
if($depth == 2 || $depth == 3)
{
	$minusP = "-p";
}
`perl generate_rsr.pl -w $issueWidth -n $nString $minusP $mString > $PATH/$stage/RSR.v`;

# Generate all required select trees
my @fuNoSort;
@fuNoSort = sort { $a <=> $b } @fuNo;
my @fuNoUniq;
$fuNoUniq[0] = $fuNoSort[0];
$j = 0;
for($i=1; $i<($#fuNoSort+1); $i++)
{
	if($fuNoUniq[$j] != $fuNoSort[$i])
	{
		$j++;
		$fuNoUniq[$j] = $fuNoSort[$i];
	}
}

#my $passTags = "";
#if($depth == 3)
#{
#	$passTags = "-t";
#}
foreach (@fuNoUniq)
{
	if($_ == 1)
	{
		`perl generate_IssueQSelect.pl -w $iqSize -d $selectBlockSize -e $passTags $mString > $PATH/$stage/IssueQSelect.v`;
	}
	else
	{
		`perl generate_cascadedIssueQSelect.pl -w $iqSize -c $_ -d $selectBlockSize -e $passTags $mString >> $PATH/$stage/IssueQSelect.v`;
	}
}

# Generate the freeList
`perl generate_freeList.pl -d $dispatchWidth -i $issueWidth -s $iqSize $mString > $PATH/$stage/IssueQFreeList.v`;

# Generate the IssueQueue
`perl generate_IssueQueue.pl -w $dispatchWidth -i $iqSize -d $depth -n $nString $passTags $mString > $PATH/$stage/IssueQueue.v`;

# Generate the CAM
`perl generate_CAM.pl -rd $issueWidth -wr $dispatchWidth -h > $PATH/$pmemStage/CAM_${issueWidth}R${dispatchWidth}W.v`;

# Generate the SRAMs
`perl generate_PAYLOAD_RAM.pl -rd $issueWidth -wr $dispatchWidth -h >> $PATH/$pmemStage/SRAM.v`; # Hiran, change this to SRAM_*R*W_PAYLOAD.v

# Generate issueqRegRead pipe reg
`perl generate_issueqRegRead.pl -w $issueWidth $mString > $PATH/$stage/issueqRegRead.v`;


