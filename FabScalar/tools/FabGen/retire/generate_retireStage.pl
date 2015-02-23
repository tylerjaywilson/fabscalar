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
# Purpose: This script creates Verilog files for the entire retire stage.
################################################################################

require "../path.pl";

my $PATH = &returnPath();
my $stage = "retire";
my $pmemStage = "pmems";

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

$issueWidth = 0;
foreach (@fuNo)
{
	$issueWidth += $_;
}

if($retireWidth != 4)
{
	die "ActiveList.v ArchMapTable.v not implemented for retire widths other than 4.\n";
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
	`rm -f $PATH/$stage/ActiveList.v  $PATH/$stage/ArchMapTable.v`;
}

if(-d "$PATH/$pmemStage")
{
	`rm -f $PATH/$pmemStage/SRAM_*_AMT.v`;
}

my $max;
if($retireWidth>$dispatchWidth)
{
	$max = $retireWidth;
}	
else
{
	$max = $dispatchWidth;
}

# Generate ActiveList.v plus required SRAMs
`perl generate_ActiveList.pl -d $dispatchWidth -n $nString -r $retireWidth $mString > $PATH/$stage/ActiveList.v`;
`perl generate_RAM.pl -rd $retireWidth -wr $dispatchWidth >> $PATH/$pmemStage/SRAM.v`;
`perl generate_RAM.pl -rd $retireWidth -wr $issueWidth >> $PATH/$pmemStage/SRAM.v`;
`perl generate_RAM.pl -rd $retireWidth -wr 1 >> $PATH/$pmemStage/SRAM.v`;

`perl generate_AMT_RAM.pl -wr $retireWidth -rd $max > $PATH/$pmemStage/SRAM_${max}R${retireWidth}W_AMT.v`;
`perl generate_ArchMapTable.pl -r $retireWidth -d $max > $PATH/$stage/ArchMapTable.v`;


