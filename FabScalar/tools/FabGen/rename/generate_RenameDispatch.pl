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
# Purpose: This script creates Rename/Dispatch pipe reg.
################################################################################

my $version = "1.1";

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 1;

my $dispatchWidth = 4; # Rename width IS the SAME as dispatch width

my $printHeader = 0;

my $i;
my $j;
my $k;
my $temp;

sub fatalUsage
{
	print "Usage: perl $scriptName -d <dispatch_width> [-m] [-v] [-h]\n";
	print "\t-d: Dispatch width = Rename width\n";
	print "\t-m: Add header\n";
	print "\t-v: Print version and exit\n";
	print "\t-h: Show usage help and exit\n";
	exit;
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

# Create module name
$outputFileName = "RenameDispatch.v";
$moduleName = "RenameDispatch";

# Quit if dispatch width and depth is not supported
my $copyFileName = "RenameDispatch_w${dispatchWidth}_d1.v";
unless(-e $copyFileName)
{
	die "This configuration (dispatchWidth=$dispatchWidth) not supported yet (File $copyFileName not found)\n";
}

print `cat $copyFileName`;
