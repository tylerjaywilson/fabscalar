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
# Purpose: This script creates Verilog for the entire fetch stage.
################################################################################


require "../path.pl";

my $PATH = &returnPath();
my $stage = "fetch";
my $pmemStage = "pmems";

my $version = "1.0";

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 3;

my $Width;
my $retireWidth;
my $printHeader = 0;
my $depth;

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
	print "Usage: perl $scriptName -w <width> -c <commit> -d <depth>[-m] [-v] [-h]\n";
	print "\t-w: Width of the frontend\n";
	print "\t-c: Width of the Retire\n";
	print "\t-d: Depth of Fetch Stage 1\n";
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
		$Width = shift;
		$essentialCLIArgs = $essentialCLIArgs + 1;
	}
	elsif(/^-c$/){
		$retireWidth = shift;
		$essentialCLIArgs = $essentialCLIArgs + 1;
	}
	elsif(/^-d$/){
		$depth = shift;
		$essentialCLIArgs = $essentialCLIArgs + 1;
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
	`rm -f $PATH/$stage/BranchPrediction_2-bit.v  $PATH/$stage/BTB.v  $PATH/$stage/CtrlQueue.v  $PATH/$stage/Fetch1Fetch2.v  $PATH/$stage/Fetch2Decode.v  $PATH/$stage/FetchStage1.v  $PATH/$stage/FetchStage2.v  $PATH/$stage/L1ICache.v $PATH/$pmemStage/SRAM.v $PATH/$stage/FetchStage1a.v $PATH/$stage/FetchStage1b.v $PATH/$stage/SAS.v $PATH/$stage/SelectInst.v`;
}

if($depth==1)
{
	print `perl generate_BranchPrediction.pl 	$mString	-w $Width > $PATH/$stage/BranchPrediction_2-bit.v`;
	print `perl generate_FetchStage1.pl 		$mString	-w $Width > $PATH/$stage/FetchStage1.v`;
	print `perl generate_BTB.pl 			$mString	-w $Width > $PATH/$stage/BTB.v`;
	print `perl generate_CTI.pl 	-w $Width  -c $retireWidth > $PATH/$stage/CtrlQueue.v`;
	print `perl generate_F1F2.pl 	-w $Width > $PATH/$stage/Fetch1Fetch2.v`;
	print `perl generate_F2D.pl 	-w $Width > $PATH/$stage/Fetch2Decode.v`;
	print `perl generate_FS2.pl 	-w $Width > $PATH/$stage/FetchStage2.v`;
	print `perl generate_L1I.pl 	-w $Width > $PATH/$stage/L1ICache.v`;

	# Generate SRAM.v
	print `perl generate_SRAM_v.pl > $PATH/$pmemStage/SRAM.v`;

	print `perl generate_RAS.pl > $PATH/$stage/RAS.v`;
	print `perl generate_SelectInst.pl > $PATH/$stage/SelectInst.v`;
} 
elsif ($depth==2)
{
	print `perl generate_BranchPrediction_ba.pl 	$mString	-w $Width > $PATH/$stage/BranchPrediction_2-bit.v`;
	print `perl generate_Fetch1b_ba.pl 		$mString	-w $Width > $PATH/$stage/FetchStage1b.v`;
	print `perl generate_BTB_ba.pl 			$mString	-w $Width > $PATH/$stage/BTB.v`;
	print `perl generate_Fetch1Fetch2_ba.pl 	$mString	-w $Width > $PATH/$stage/Fetch1Fetch2.v`;
	print `perl generate_Fetch2Decode_ba.pl 	$mString	-w $Width > $PATH/$stage/Fetch2Decode.v`;
	print `perl generate_Fetch2_ba.pl 	$mString	-w $Width > $PATH/$stage/FetchStage2.v`;
	print `perl generate_L1Cache_ba.pl 	$mString	-w $Width > $PATH/$stage/L1ICache.v`;
	# Generate SRAM.v
	print `perl generate_SRAM_v_ba.pl > $PATH/$pmemStage/SRAM.v`;

	print `perl generate_RAS_ba.pl > $PATH/$stage/RAS.v`;
	print `perl generate_SAS_ba.pl > $PATH/$stage/SAS.v`;
	print `perl generate_CtrlQueue_ba.pl > $PATH/$stage/CtrlQueue.v`;
	print `perl generate_Fetch1a_ba.pl > $PATH/$stage/FetchStage1a.v`;
	print `perl generate_Fetch1aFetch1b_ba.pl > $PATH/$stage/Fetch1aFetch1b.v`;
}
