#!/usr/bin/perl

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
# Purpose: This script creates rename folder.
################################################################################

require "../path.pl";

my $PATH = &returnPath();
my $stage = "rename";
my $pmemStage = "pmems";

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
my $k;
my $comma;
my $temp;
my $temp2;
my $temp3;
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

# Set up directory for generation
if(-d "$PATH/$stage")
{
	`rm -f $PATH/$stage/Rename.v  $PATH/$stage/RenameDispatch.v  $PATH/$stage/RenameMapTable.v  $PATH/$stage/SpecFreeList.v  $PATH/$pmemStage/SRAM_*_FREELIST.v $PATH/$pmemStage/SRAM_*_RMT.v`;
}


print `perl generate_Rename.pl -d $dispatchWidth -r $retireWidth -m > $PATH/$stage/Rename.v`;
print `perl generate_RenameDispatch.pl -d $dispatchWidth -m > $PATH/$stage/RenameDispatch.v`;
print `perl generate_RenameMapTable.pl -d $dispatchWidth -r $retireWidth -m > $PATH/$stage/RenameMapTable.v`;
print `perl generate_SpecFreeList.pl -d $dispatchWidth -r $retireWidth -m > $PATH/$stage/SpecFreeList.v`;

# Generate Freelist RAM
print `perl generate_FREELIST_RAM.pl -rd $dispatchWidth -wr $retireWidth -h > $PATH/$pmemStage/SRAM_${dispatchWidth}R${retireWidth}W_FREELIST.v`;

# Generate RMT RAM
$temp = 2*$dispatchWidth;
print `perl generate_RMT_RAM.pl -rd $temp -wr $dispatchWidth -h > $PATH/$pmemStage/SRAM_${temp}R${dispatchWidth}W_RMT.v`;

