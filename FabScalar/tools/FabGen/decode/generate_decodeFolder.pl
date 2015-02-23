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
# Purpose: This script creates all RTL files for decode stage.
################################################################################

require "../path.pl";

my $PATH = &returnPath();
my $stage = "decode";
my $pmemStage = "pmems";

my $version = "1.0";

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 3;

my $printHeader = 0;
my $supportBA = 0;

my $fetchWidth;
my $decodeWidth;
my $decodeDepth;

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
	print "Usage: perl $scriptName -f <fetch_width> -dw <decode_width> -dd <decode_depth> [-ba] [-m] [-v] [-h]\n";
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
	if(/^-dw$/)
	{
		$decodeWidth = shift;
		$essentialCLIArgs++;
	}	
	elsif(/^-f$/)
	{
		$fetchWidth = shift;
		$essentialCLIArgs++;
	}	
	elsif(/^-dd$/)
	{
		$decodeDepth = shift;
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
	`rm -f $PATH/$stage/Decode.v $PATH/$stage/Decode_PISA.v $PATH/$stage/PreDecode_PISA.v $PATH/$stage/InstBufRename.v $PATH/$stage/InstructionBuffer.v $PATH/$stage/DecodeRename.v` ;
}

if($supportBA)
{
	print `perl generate_Decode.pl -dw $decodeWidth -dd $decodeDepth $mString -ba > $PATH/$stage/Decode.v`;
	print `perl generate_PreDecode_PISA_ba.pl $mString > $PATH/$stage/PreDecode_PISA.v`;
} else
{
	print `perl generate_Decode.pl -dw $decodeWidth -dd $decodeDepth $mString > $PATH/$stage/Decode.v`;
	print `perl generate_PreDecode_PISA.pl $mString > $PATH/$stage/PreDecode_PISA.v`;
}
print `perl generate_Decode_PISA.pl $mString > $PATH/$stage/Decode_PISA.v`;


print `perl generate_InstBufRename.pl -dw $decodeWidth -dd $decodeDepth $mString > $PATH/$stage/InstBufRename.v`;
print `perl generate_InstructionBuffer.pl -dw $decodeWidth -dd $decodeDepth $mString > $PATH/$stage/InstructionBuffer.v`;

print `perl generate_DecodeRename.pl -w $decodeWidth $mString > $PATH/$stage/DecodeRename.v`;

# Generate the instruction buffer RAM
$temp = 2*$fetchWidth;
print `perl generate_RAM.pl -rd $decodeWidth -wr $temp -h > $PATH/$pmemStage/SRAM_${decodeWidth}R${temp}W.v`;

