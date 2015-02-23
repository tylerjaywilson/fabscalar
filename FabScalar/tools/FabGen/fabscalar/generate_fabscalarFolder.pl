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
# Purpose: This script creates all verilog files in the folder fabscalar.
################################################################################

require "../path.pl";

my $PATH = &returnPath();
my $stage = "fabscalar";

my $version = "1.0";

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 8;

my $typesOfFUs = 4; # HARDWIRED!
my @fuNo;   # Number of execute ways of each instruction type (they are always adjacent)
my @whereFU;  # A two dimensional array with 4 rows (for each instruction type), telling which ways support that type.

my $fetchWidth;
my $decodeWidth;
my $dispatchWidth;
my $issueWidth;
my $retireWidth;

my $printHeader = 0;
my $supportBA = 0;

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

# Check for FABSCALAR.v
for($i=1; $i<$typesOfFUs; $i++)
{
	if($fuNo[$i] != 1)
	{
		die "FABSCALAR.v not implemented for FU type $i with more than one way.\n";
	}
}

if(-d "$PATH/$stage")
{
	`rm -f $PATH/$stage/FABSCALAR.v`;
}

if($supportBA)
{
	`perl generate_FABSCALAR.pl -f $fetchWidth -dc $decodeWidth -d $dispatchWidth -n $nString -r $retireWidth $mString -ba > $PATH/$stage/FABSCALAR.v`;
}
else
{
	`perl generate_FABSCALAR.pl -f $fetchWidth -dc $decodeWidth -d $dispatchWidth -n $nString -r $retireWidth $mString > $PATH/$stage/FABSCALAR.v`;
}
# Interface.v
`perl generate_Interface.pl > $PATH/$stage/Interface.v`;

