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
# Purpose: This script creates DispatchedLoad.v file.
################################################################################

my $version = "1.0";

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 1;

my $printHeader = 0;

my $dispatchWidth;

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
	print "Usage: perl $scriptName -d <dispatch_width> [-m] [-v] [-h]\n";
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
$outputFileName = "DispatchedLoad.v";
$moduleName = "DispatchedLoad";

print <<LABEL;
/*******************************************************************************
#                        NORTH CAROLINA STATE UNIVERSITY
#
#                               FabScalar Project
#
# FabScalar Copyright (c) 2007-2011 by Niket K. Choudhary, Salil Wadhavkar,
# and Eric Rotenberg.  All Rights Reserved.
#
# This is a beta-release version.  It must not be redistributed at this time.
#
# Purpose: 
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL

print <<LABEL;
module $moduleName (
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
			input 				inst${i}Load_i,
LABEL
}
print "\n";

print <<LABEL;
			input [`SIZE_LSQ_LOG-1:0]  	ldqHead_i,
			input [`SIZE_LSQ_LOG-1:0]  	ldqTail_i,
			input [`SIZE_LSQ_LOG:0]  	ldqInsts_i,
			
			output [`SIZE_LSQ_LOG-1:0] 	cntLdNew_o,
LABEL
			
for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
			output [`SIZE_LSQ_LOG-1:0] 	ldqId${i}_o,
LABEL
}
print "\n";
			
for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
			output [`SIZE_LSQ_LOG-1:0] 	index${i}LdNew_o,
LABEL
}
print "\n";
			
for($i=0; $i<$dispatchWidth; $i++)
{
	$comma = ($i == $dispatchWidth-1)? "" : ",";
	print <<LABEL;
            output [`SIZE_LSQ_LOG-1:0] 	nextLD${i}_o$comma
LABEL
}
print "\n";
			
print <<LABEL;
		      );


reg [`SIZE_LSQ_LOG-1:0] 	cntLdNew;
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
reg [`SIZE_LSQ_LOG-1:0] 	ldqId${i};
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
reg [`SIZE_LSQ_LOG-1:0]         nextLD${i};
LABEL
}
print "\n";

print <<LABEL;
assign cntLdNew_o 	= cntLdNew;
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
assign ldqId${i}_o		= ldqId${i};
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
assign index${i}LdNew_o	= ldqTail_i+${i};
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
assign nextLD${i}_o	= nextLD${i};
LABEL
}
print "\n";


print <<LABEL;
always @(*)
begin:DISPATCHED_LD
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
  reg [`SIZE_LSQ_LOG-1:0] nextld${i};
LABEL
}
print "\n";

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
  nextld${i}       = ldqTail_i+${i};
LABEL
}
print "\n";

print <<LABEL;
  cntLdNew    = 0;
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
  ldqId${i}      = 0;
LABEL
}
print "\n";

# Kept here for diffing
print <<LABEL;
  /*nextLD0       = (ldqInsts_i == 0) ? ldqHead_i:nextld0;
  nextLD1       = (ldqInsts_i == 0) ? ldqHead_i:nextld0;
  nextLD2       = (ldqInsts_i == 0) ? ldqHead_i:nextld0;
  nextLD3       = (ldqInsts_i == 0) ? ldqHead_i:nextld0;*/
LABEL

for($i=0; $i<$dispatchWidth; $i++)
{
	print <<LABEL;
  nextLD${i}       = nextld0;
LABEL
}
print "\n";

print <<LABEL;
    /* Following combinational logic counts the number of LD instructions in the
       incoming set of instructions. */
LABEL

# Switch case part
print "    cntLdNew    = ";
for($i=$dispatchWidth-1; $i>=0; $i--)
{
	$comma = ($i == 0)? ";" : "+";
	print "inst${i}Load_i$comma";
}
print "\n\n";

print "    case({";
for($i=$dispatchWidth-1; $i>=0; $i--)
{
	$comma = ($i == 0)? "})" : ",";
	print "inst${i}Load_i$comma";
}
print "\n";

for($j=1; $j<2**$dispatchWidth; $j++)
{
	$tempStr = sprintf("%0${dispatchWidth}b", $j);
	print <<LABEL;
          ${dispatchWidth}'b$tempStr:
          begin
LABEL

	@tempArr = split(//, $tempStr);

	$tempCount=0;
	for($i=0; $i<$dispatchWidth; $i++)
	{
		if($tempArr[$dispatchWidth-$i-1] eq "1")
		{
			$temp = ($tempCount == "0")? "" : "+$tempCount";
			print <<LABEL;		
                ldqId$i      = ldqTail_i$temp;
LABEL
			$tempCount++;
		}
	}
	print "\n";

	$tempCount=0;
	for($i=0; $i<$dispatchWidth; $i++)
	{
		if($tempArr[$dispatchWidth-$i-1] eq "1")
		{
			print <<LABEL;		
		nextLD$i     = 0;
LABEL
			$tempCount++;
		}
		else
		{
			print <<LABEL;
                nextLD$i     = nextld$tempCount;
LABEL
		}
	}

print <<LABEL;				
          end
LABEL
}

print <<LABEL;
    endcase 
end

endmodule
LABEL

