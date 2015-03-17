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
# Purpose: This script calls all the */*folder.pl and */*stage.pl scripts.
################################################################################

require "path.pl";

my $version = "FabGen (beta-release) version-1.0";

my $scriptName;
my $moduleName;
my $outputFileName;
#my $minEssentialCLIArgs = 14;
my $minEssentialCLIArgs = 10;

# Input parameters
my $fetchWidth;
my $fetchDepth;

my $decodeWidth;
my $decodeDepth;

my $dispatchWidth;
my $dispatchDepth;

my @fuNo;   # Number of execute ways of each instruction type (they are always adjacent)
my $issueDepth = 2;
my $iqSize = 32;
my $selectBlockSize = 8;
my $passTags = ""; # The "" is necessary!

my $rrDepth = 1;

my $retireWidth;

my $simulateFile;

# Internal variables
my $issueWidth;
my $typesOfFUs = 4; # HARDWIRED!
my @whereFU;  # A two dimensional array with 4 rows (for each instruction type), telling which ways support that type.

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

        print "Usage:\n";
        print "   perl $scriptName\n";
        print "   -fw <fetch width>\n";
        print "   -fd <fetch depth>\n";
        print "   -iq <issue queue size>\n";
        print "   -id <issue depth>\n";
        print "   -sel <select tree block size>\n";
        print "   [-t]\n";
        print "   -fumix <simple-alu> <complex-alu> <branch> <load/store>\n";
        print "   -rrd <register-read and writeback depth>\n";
        print "   [-m] [-v] [-h]\n";

        print "\n";

        print "Description of command-line arguments:\n";
        print "\n";
        print "-fw:    Fetch width: 1 to 8.\n";
        print "        NOTE: The fetch width determines the width of the entire front-end:\n";
        print "              Fetch-1, Fetch-2, Decode, Rename, and Dispatch.\n";
        print "        NOTE: Front-end width must be <= back-end width (# function units).\n";
        print "              This is an artifact of the current IQ free-list design.\n";
        print "        NOTE: Fetch width must be at least 2 if fetch depth = 2. This is an\n";
        print "              artifact of the current Block-Ahead Predictor design.\n";
        print "\n";
        print "-fd:    Fetch depth: 1 or 2.\n";
        print "        NOTE: This is the depth of the Fetch-1 stage only.\n";
        print "              It does not include the Fetch-2 stage.\n";
        print "        NOTE: For fetch depth = 2, Block-Ahead Prediction is employed to\n";
        print "              pipeline the branch prediction logic.\n";
        print "\n";
        # print "-ded:   Decode depth\n";
        # print "\n";
        # print "-dw:    Rename width\n";
        # print "\n";
        # print "-dd:    Rename depth\n";
        # print "\n";
        print "-iq:    Issue queue size: any power-of-2.\n";
        print "\n";
        print "-id:    Depth of issue stage: 1 to 3.\n";
        print "\n";
        print "-sel:   Select tree block size: any power-of-2, must be <= issue queue size.\n";
        print "\n";
        print "-t:     Remove issue queue payload RAM from the critical wakeup-select loop.\n";
        print "\n";
        print "-fumix: Number of the following function unit (FU) types:\n";
        print "        simple-alu (1 to 5), complex-alu (1), branch (1), load/store (1)\n";
	print "        NOTE: The total number of FUs determines the back-end width:\n";
        print "              Issue, Register-Read, Execute, and Writeback.\n";
        print "\n";
        print "-rrd:   Depth of the register read and writeback stages: 1 to 4.\n";
        print "        This is the degree of sub-pipelining the physical register file.\n";
        print "\n";
        # print "-rw:    Retire width\n";
        # print "\n";
        print "-m:     Add header.\n";
        print "\n";
        print "-v:     Print version and exit.\n";
        print "\n";
        print "-h:     Show usage help and exit.\n";
        print "\n";
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
	if(/^-fw$/) 
	{
		$fetchWidth = shift;
		$essentialCLIArgs++;
	}
	elsif(/^-fd$/) 
	{
		$fetchDepth = shift;
		$essentialCLIArgs++;
	}
#	elsif(/^-ded$/) 
#	{
#		$decodeDepth = shift;
#		$essentialCLIArgs++;
#	}
#	elsif(/^-dw$/) 
#	{
#		$dispatchWidth = shift;
#		$essentialCLIArgs++;
#	}
#	elsif(/^-dd$/) 
#	{
#		$dispatchDepth = shift;
#		$essentialCLIArgs++;
#	}
	elsif(/^-fumix$/) 
	{
		for($i=0; $i<$typesOfFUs; $i++)
		{
			$fuNo[$i] = shift;
			$essentialCLIArgs++;
		}
	}	
	elsif(/^-id$/)
	{
		$issueDepth = shift;
		$essentialCLIArgs++;
	}
	elsif(/^-iq$/)
	{
		$iqSize = shift;
		$essentialCLIArgs++;
	}
	elsif(/^-sel$/)
	{
		$selectBlockSize = shift;
		$essentialCLIArgs++;
	}
	elsif(/^-t$/)
	{
		$passTags = "-t";
	}	
	elsif(/^-rrd$/)
	{
		$rrDepth = shift;
		$essentialCLIArgs++;
	}
#	elsif(/^-rw$/) 
#	{
#		$retireWidth = shift;
#		$essentialCLIArgs++;
#	}
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
		print "$version\n";
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

$decodeWidth = $fetchWidth;
$decodeDepth = 1;
$dispatchWidth = $fetchWidth;
$dispatchDepth = 1;
$retireWidth = 4;

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

# create all directories required by FabGen
my $PATH    = &returnPath();
mkdir $PATH or die "$PATH directory already exists!!: $!.";

system("mkdir $PATH/decode");
system("mkdir $PATH/dispatch");
system("mkdir $PATH/execute");
system("mkdir $PATH/fabscalar");
system("mkdir $PATH/fetch");
system("mkdir $PATH/ISA");
system("mkdir $PATH/issue");
system("mkdir $PATH/memory");
system("mkdir $PATH/pmems");
system("mkdir $PATH/rename");
system("mkdir $PATH/retire");
system("mkdir $PATH/writeback");

# fetch 
print "Generating fetch stage";
chdir("fetch");
print `perl generate_fetch.pl -w $fetchWidth -d $fetchDepth -c $retireWidth $mString`;
chdir("..");
print "... Done!\n";

# decode
print "Generating decode stage";
chdir("decode");
if($fetchDepth==1)
{
	print `perl generate_decodeFolder.pl -f $fetchWidth -dw $decodeWidth -dd $decodeDepth $mString`;
}
elsif ($fetchDepth==2)
{
	print `perl generate_decodeFolder.pl -f $fetchWidth -dw $decodeWidth -dd $decodeDepth $mString -ba`;
}
chdir("..");
print "... Done!\n";

#rename
print "Generating rename stage";
chdir("rename");
print `perl generate_renameStage.pl -d $dispatchWidth -r $retireWidth $mString`;
chdir("..");
print "... Done!\n";

#dispatch
print "Generating dispatch stage";
chdir("dispatch");
print `perl generate_dispatchFolder.pl -dw $dispatchWidth -dd $dispatchDepth $mString`;
chdir("..");
print "... Done!\n";

# issue
print "Generating issue stage";
chdir("issue");
print `perl generate_IssueStage.pl -w $dispatchWidth -i $iqSize -d $issueDepth -s $selectBlockSize -n $nString $passTags $mString`;
chdir("..");
print "... Done!\n";

# regread
print "Generating regread stage";
chdir("regread");
print `perl generate_regreadStage.pl -d $dispatchWidth -n $nString -p $rrDepth $mString`;
chdir("..");
print "... Done!\n";

# execute
print "Generating execute stage";
chdir("execute");
print `perl generate_executeStage.pl -n $nString $mString`;
chdir("..");
print "... Done!\n";

# memory
print "Generating memory stage";
chdir("memory");
print `perl generate_memoryFolder.pl -d $dispatchWidth -r $retireWidth $mString`;
chdir("..");
print "... Done!\n";

# writeback
print "Generating writeback stage";
chdir("writeback");
print `perl generate_writebackStage.pl -n $nString -d $rrDepth $mString`;
chdir("..");
print "... Done!\n";

# retire
print "Generating retire stage";
chdir("retire");
print `perl generate_retireStage.pl -d $dispatchWidth -n $nString -r $retireWidth $mString`;
chdir("..");
print "... Done!\n";

# ISA and Parameter-file
print "Generating ISA folder";
chdir("common");
print `perl generate_ISAFolder.pl`;
print `perl generate_FabParam.pl -f $fetchWidth -d $dispatchWidth -i $issueWidth -r $retireWidth -is $iqSize > $PATH/FabScalarParam.v`;
$simulateFile = "simulate_rrd".$rrDepth.".v";
system("cp $simulateFile $PATH/fabscalar/simulate.v");
chdir("..");
print "... Done!\n";

# fabscalar
print "Generating fabscalar top module";
chdir("fabscalar");
if($fetchDepth==2)
{
	print `perl generate_fabscalarFolder.pl -f $fetchWidth -dc $decodeWidth -d $dispatchWidth -n $nString -r $retireWidth $mString -ba`;
}
else 
{
	print `perl generate_fabscalarFolder.pl -f $fetchWidth -dc $decodeWidth -d $dispatchWidth -n $nString -r $retireWidth $mString`;
}
chdir("..");
print "... Done!\n";

# simulate + benchmarks
#print "Generating files in simulate directory\n";
#chdir("simulate");
#my $output;
#if($fetchDepth==2)
#{
#	$output = `perl generate_simulateFolder.pl -d $dispatchWidth -n $nString -r $retireWidth $mString -ba`;
#} 
#else
#{
#	$output = `perl generate_simulateFolder.pl -d $dispatchWidth -n $nString -r $retireWidth $mString`;
#}
#print $output; # There are messages in generate_simulateFolder.pl
#chdir("..");
#print "... Done!\n";


