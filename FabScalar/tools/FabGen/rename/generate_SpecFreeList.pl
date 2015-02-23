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
# Purpose: generates SpecFreeList.v.
################################################################################

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

# Create module name
$outputFileName = "SpecFreeList.v";
$moduleName = "SpecFreeList";

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
# Purpose: This module implements speculative FreeList.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL

 print "module $moduleName(\n";  	
 print " input clk,\n";
 print " input stall_i,\n";
 print " input reset,\n";
 print " input recoverFlag_i,\n";
 print " input flagRecoverEX_i,\n";
 print " input ctrlVerified_i,\n";
 print " input [`SIZE_FREE_LIST_LOG-1:0] freeListHeadCp_i,\n";
 for($i=0;$i<$dispatchWidth;$i=$i+1)
 {
	$str1 = "reqFreeReg".$i."_i";
 	print " input $str1,\n";
 }

 for($i=0;$i<$retireWidth;$i=$i+1)
 {
        $str1 = "commitValid".$i."_i";
        print " input $str1,\n";
	$str1 = "commitReg".$i."_i";
	print " input [`SIZE_PHYSICAL_LOG-1:0] $str1,\n";
 }

 print " output [`SIZE_FREE_LIST_LOG-1:0] freeListHead_o,\n";
 for($i=0;$i<$dispatchWidth;$i=$i+1)
 {
	$str1 = "freeReg".$i."_o";
	print " output [`SIZE_PHYSICAL_LOG:0] $str1,\n";
 }
 print " output freeListEmpty_o\n";
 print "); \n\n";

# print "reg [`SIZE_PHYSICAL_LOG-1:0]            FREE_LIST [`SIZE_FREE_LIST-1:0];\n";
 print "reg [`SIZE_FREE_LIST_LOG-1:0]           freeListHead;\n";
 print "reg [`SIZE_FREE_LIST_LOG-1:0]           freeListTail;\n";

 print "reg [`SIZE_FREE_LIST_LOG:0]           freeListCnt;\n";

 print "wire                                    freeListEmpty;\n";
 for($i=0;$i<$dispatchWidth;$i=$i+1)
 {
	$str1 = "reqFreeReg".$i;
 	print "wire                                    $str1;\n";
 }
 print "reg [3:0]                               popNumber;\n";
 print "reg [3:0]                               pushNumber;\n";
 print "reg [`SIZE_FREE_LIST_LOG:0]           freelistcnt;\n";
 print "reg [`SIZE_FREE_LIST_LOG:0]           freelistcntCp;\n";
 print "reg [`SIZE_FREE_LIST_LOG-1:0]           freeListHead_t;\n";
 print "reg [`SIZE_FREE_LIST_LOG-1:0]           freeListTail_t;\n";
 print "\n";
 for($i=0;$i<$dispatchWidth;$i=$i+1)
 {
        $str1 = "readAddr".$i;
        print "reg [`SIZE_FREE_LIST_LOG-1:0]    		$str1;\n";
 }

 for($i=0;$i<$dispatchWidth;$i=$i+1)
 {
        $str1 = "freeReg".$i;
        print "wire [`SIZE_PHYSICAL_LOG:0]    		$str1;\n";
 }

 for($i=0;$i<$retireWidth;$i=$i+1)
 {
        $str1 = "writeAddr".$i;
        print "reg [`SIZE_FREE_LIST_LOG-1:0]     	$str1;\n";
 }
 for($i=0;$i<$retireWidth;$i=$i+1)
 {
        print "reg 			    		writeEn${i};\n";
        print "reg [`SIZE_FREE_LIST_LOG-1:0]             addr${i}wr;\n";
        print "reg [`SIZE_PHYSICAL_LOG:0]                data${i}wr;\n";
 }

 print "integer                                 i;\n\n";
 print "SRAM_${dispatchWidth}R${retireWidth}W_FREELIST #(`SIZE_FREE_LIST,`SIZE_FREE_LIST_LOG,`SIZE_PHYSICAL_LOG)\n";
 print "  FREE_LIST ( .clk(clk),\n\t\t.reset(reset),\n";
 for($i=0;$i<$dispatchWidth;$i=$i+1)
 {
	print "\t\t.addr${i}_i(readAddr${i}),\n";
 }
 for($i=0;$i<$retireWidth;$i=$i+1)
 {
	print "\t\t.we${i}_i(writeEn${i}),\n";
	print "\t\t.addr${i}wr_i(addr${i}wr),\n";
	print "\t\t.data${i}wr_i(data${i}wr),\n";
 }
 for($i=0;$i<$dispatchWidth;$i=$i+1)
 {
	if($i != $dispatchWidth - 1 ){
	print "\t\t.data${i}_o(freeReg${i}),\n";
	}
	else{
	print "\t\t.data${i}_o(freeReg${i})\n";
	}
 }
 print "  );\n\n";

 for($i=0;$i<$dispatchWidth;$i=$i+1)
 {
	$str1 = "freeReg".$i."_o";
 	$str2 = "readAddr".$i;
 	print "assign $str1       = (freeListCnt >= `DISPATCH_WIDTH) ? {freeReg${i},1'b1}:0;\n";
 }
 print "\n";
 print "assign freeListHead_o   = freeListHead;\n"; 

 print "always @(*)\n";
 print "begin:FREE_LIST_ADDR\n";

 for($i=1;$i<$dispatchWidth;$i=$i+1)
 {
        $str1 = "readaddr".$i."_f";
        print "reg [`SIZE_FREE_LIST_LOG:0]		$str1;\n";
 }
 for($i=1;$i<$retireWidth;$i=$i+1)
 {
        $str1 = "writeaddr".$i."_f";
        print "reg [`SIZE_FREE_LIST_LOG:0]		$str1;\n";
 }

 print "readAddr0    = freeListHead;\n";
 for($i=1;$i<$dispatchWidth;$i=$i+1)
 {
	$str1 = "readaddr".$i."_f";
	print " $str1   = freeListHead + $i;\n";
 }
 for($i=1;$i<$dispatchWidth;$i=$i+1)
 {
	$str1 = "readaddr".$i."_f";
	print " if($str1 >= `SIZE_FREE_LIST)\n";
	print " 		readAddr${i}  = $str1 - `SIZE_FREE_LIST;\n";	
	print " else\n\t readAddr${i} = readaddr${i}_f;\n";
 }

 print "writeAddr0   = freeListTail;\n";
 for($i=1;$i<$retireWidth;$i=$i+1)
 {
        $str1 = "writeaddr".$i."_f";
        print " $str1   = freeListTail + $i;\n";
 }
 for($i=1;$i<$retireWidth;$i=$i+1)
 {
        $str1 = "writeaddr".$i."_f";
        print " if($str1 >= `SIZE_FREE_LIST)\n";
        print "          writeAddr${i} = $str1 - `SIZE_FREE_LIST;\n";
	print " else\n\t writeAddr${i} = writeaddr${i}_f;\n";
 }
 print "end\n\n";

 print "assign freeListEmpty    =  (freeListCnt < `DISPATCH_WIDTH) ? 1:0;\n";
 print "assign freeListEmpty_o  =   freeListEmpty;\n";
 
 $temp = $dispatchWidth - 1;
 for($i=$temp;$i>=0;$i=$i-1)
 {
	$str1 = "reqFreeReg".$i;
	$str2 = "reqFreeReg".$i."_i";
	print "assign $str1 	= $str2 & ~freeListEmpty;\n";
 }
 
 print "\nalways @(*)\n";
 print "begin:UPDATE_HEAD_TAIL_COUNT\n";
 print "reg                            isWrap_fl;\n";
 print "reg [`SIZE_FREE_LIST_LOG:0]  diff1_fl;\n";
 print "reg [`SIZE_FREE_LIST_LOG:0]  diff2_fl;\n";
 print "reg [`SIZE_FREE_LIST_LOG:0]  freelisthead;\n";
 print "reg [`SIZE_FREE_LIST_LOG:0]  freelisttail;\n";

 print " popNumber  =  (";
 for($i=0;$i<$dispatchWidth;$i=$i+1)
 {
	if($i != $dispatchWidth-1)
	{
		$str1 = "reqFreeReg".$i;
		print "$str1 + ";
	}
	else
	{
		$str1 = "reqFreeReg".$i;
                print "$str1);\n";
	}
 }	

 print " pushNumber  =  (";
 for($i=0;$i<$retireWidth;$i=$i+1)
 {
        $str1 = "commitValid".$i."_i";
        if($i != $retireWidth-1)
        {
                print "$str1 + ";
        }
        else
        {
                print "$str1);\n";
        }
 }

 print "\n freelistcnt    = freeListCnt  - popNumber;\n";
 print " freelistcnt    = freelistcnt  + pushNumber;\n";

 print " freelisthead   = freeListHead + popNumber;\n";
 print " if(freelisthead >= `SIZE_FREE_LIST)\n";
 print "		freeListHead_t  = freelisthead - `SIZE_FREE_LIST;\n";
 print " else\n";
 print " 	freeListHead_t  = freelisthead;\n";

 print " freelisttail   = freeListTail + pushNumber;\n";
 print " if(freelisttail >= `SIZE_FREE_LIST)\n";
 print " 	freeListTail_t  = freelisttail - `SIZE_FREE_LIST;\n";
 print " else\n";
 print " 	freeListTail_t  = freelisttail;\n";

 print " isWrap_fl             = (freeListTail_t > freeListHeadCp_i);\n";
 print " diff1_fl              = (`SIZE_FREE_LIST - freeListHeadCp_i)+freeListTail_t;\n";
 print " diff2_fl              = (freeListTail_t - freeListHeadCp_i);\n";
 print " freelistcntCp         = (isWrap_fl) ? diff2_fl:diff1_fl;\n";
 print "end\n\n";

 print "always @(posedge clk)\n";
 print "begin\n";
 print "  if(reset)\n";
 print "  begin\n";
 print "    freeListCnt  <= `SIZE_FREE_LIST;\n";
 print "    freeListHead <= 0;\n";
 print "  end\n";
 print "  else if(recoverFlag_i)\n";
 print "  begin\n";
 print "    freeListCnt  <= `SIZE_FREE_LIST;\n";
 print "    freeListHead <= freeListTail;\n";
 print "  end\n";
 print "  else\n";
 print "  begin\n";
 print "    if(ctrlVerified_i && flagRecoverEX_i)\n";
 print "    begin\n";
 print "        freeListHead  <=  freeListHeadCp_i;\n";
 print "        freeListCnt   <=  freelistcntCp;\n";
 print "    end\n";
 print "    else if(stall_i || freeListEmpty)\n";
 print "    begin\n";
 print "        freeListHead  <=  freeListHead;\n";
 print "        freeListCnt   <=  freeListCnt + pushNumber;\n";
 print "    end\n";
 print "    else\n";
 print "    begin\n";
 print "        freeListHead  <=  freeListHead_t;\n";
 print "        freeListCnt   <=  freelistcnt;\n";
 print "    end\n";
 print "  end\n";
 print "end\n";

 print "always @(*)\n";
 print "begin:CALCULATE_WRITE_ADDR\n";

 for($i=0;$i<$retireWidth;$i=$i+1){
	print " writeEn${i} = 0;\n";
	print " addr${i}wr  = 0;\n";
	print " data${i}wr  = 0;\n";
 }
 print "  case({";
 for($i=$retireWidth-1; $i>=0; $i=$i-1)
 {
        $str1 = "commitValid".$i."_i";
        print "$str1";
        if($i != 0)
        {
                print ",";
        }
 }
 print "})\n"; 
 @in   = ();
 @out  = ();
 for($i=0;$i<$retireWidth;$i=$i+1)
 {
  $str1 = "commitReg".$i."_i";
  push(@in,$str1);
  $str2 = "writeAddr".$i;
  push(@out,$str2);
 }
 	$length = 2**$retireWidth;
        for($i=1;$i<$length;$i=$i+1)
        {
                $str1 = $retireWidth."'d".$i;
                print "     $str1";
                print ":\n     begin\n";
                $out_ptr = 0;
                for($j=0;$j<$retireWidth;$j=$j+1)
                {
                        $cal1 = ($i >> $j) & 00000000001;
                        if($cal1 == 1)
                        {
				print "\n\t\twriteEn${out_ptr}\t= 1'b1;\n";
                                print "             addr${out_ptr}wr \t= $out[$out_ptr];\n"; #  <=  $in[$j];\n";
                                print "             data${out_ptr}wr \t=  $in[$j];\n";
                                $out_ptr = $out_ptr+1;
                        }
                }
                print "     end\n";
        }
        print "  endcase\n";
 print "  end\n";
 print <<LABEL;
always @(posedge clk)
begin
 if(reset)
 begin
  freeListTail    <= 0;
 end
 else
 begin
LABEL
 print "  freeListTail <= freeListTail_t;\n";
 print "  end\nend\n";

 print "\n\nendmodule";
