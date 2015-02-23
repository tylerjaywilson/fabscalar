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
# Purpose: This script creates all verilog files in memory folder.
################################################################################

require "../path.pl";

my $PATH = &returnPath();
my $stage = "memory";

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
my $comma;
my $temp;
my $temp2;
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

if(-d "$PATH/$stage")
{
	`rm -f $PATH/$stage/LoadStoreUnit_n.v $PATH/$stage/CommitLoad.v $PATH/$stage/CommitStore.v $PATH/$stage/DispatchedLoad.v $PATH/$stage/DispatchedStore.v $PATH/$stage/L1DataCache.v`;
}

print `perl generate_LSU.pl -w $dispatchWidth -c $retireWidth > $PATH/$stage/LoadStoreUnit.v`;

print `perl generate_CommitLoad.pl -r $retireWidth $mString > $PATH/$stage/CommitLoad.v`;
print `perl generate_CommitStore.pl -r $retireWidth $mString > $PATH/$stage/CommitStore.v`;

print `perl generate_DispatchedLoad.pl -d $dispatchWidth $mString > $PATH/$stage/DispatchedLoad.v`;
print `perl generate_DispatchedStore.pl -d $dispatchWidth $mString > $PATH/$stage/DispatchedStore.v`;

print `perl generate_L1DataCache.pl $mString > $PATH/$stage/L1DataCache.v`;

