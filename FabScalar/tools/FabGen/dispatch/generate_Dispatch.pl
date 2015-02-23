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
# Purpose:
################################################################################

my $version = "1.0";

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 2;

my $printHeader = 0;

my $dispatchWidth;
my $dispatchDepth;

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
	print "Usage: perl $scriptName -dw <dispatch_width> -dd <dispatch_depth> [-m] [-v] [-h]\n";
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
	if(/^-dw$/)
	{
		$dispatchWidth = shift;
		$essentialCLIArgs++;
	}	
	elsif(/^-dd$/)
	{
		$dispatchDepth = shift;
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
$outputFileName = "Dispatch.v";
$moduleName = "Dispatch";

# Quit if dispatch width and depth is not supported
my $copyFileName = "Dispatch_w${dispatchWidth}_d${dispatchDepth}.v";
unless(-e $copyFileName)
{
	die "This configuration (dispatchWidth=$dispatchWidth, dispatchDepth=$dispatchDepth) not supported yet.\n";
}

# Warning: -m option not working right now
print `cat $copyFileName`;

