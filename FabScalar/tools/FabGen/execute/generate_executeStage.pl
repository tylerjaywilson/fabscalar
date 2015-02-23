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
# Purpose: This script creates Verilog for the entire execute stage.
################################################################################

require "../path.pl";

my $PATH = &returnPath();
my $stage = "execute";

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
	`rm -f $PATH/$stage/AgenLsu.v  $PATH/$stage/AGEN.v  $PATH/$stage/Complex_ALU.v  $PATH/$stage/Ctrl_ALU.v  $PATH/$stage/Execute.v  $PATH/$stage/ForwardCheck.v  $PATH/$stage/fu0.v  $PATH/$stage/fu1.v  $PATH/$stage/fu2.v  $PATH/$stage/fu3.v  $PATH/$stage/Simple_ALU.v`;
}

# Generate the FUs
`perl generate_fu0.pl $mString > $PATH/$stage/fu0.v`;
`perl generate_fu1.pl $mString > $PATH/$stage/fu1.v`;
`perl generate_fu2.pl $mString > $PATH/$stage/fu2.v`;
`perl generate_fu3.pl $mString > $PATH/$stage/fu3.v`;

# Generate the ALUs
`perl generate_AGEN.pl $mString > $PATH/$stage/AGEN.v`;
`perl generate_AgenLsu.pl $mString > $PATH/$stage/AgenLsu.v`;
`perl generate_Simple_ALU.pl $mString > $PATH/$stage/Simple_ALU.v`;
`perl generate_Complex_ALU.pl $mString > $PATH/$stage/Complex_ALU.v`;
`perl generate_Ctrl_ALU.pl $mString > $PATH/$stage/Ctrl_ALU.v`;

# Generate the forward check logic
`perl generate_ForwardCheck.pl -w $issueWidth $mString > $PATH/$stage/ForwardCheck.v`;

# Generate the execute file
`perl generate_Execute.pl -n $nString $mString > $PATH/$stage/Execute.v`;

