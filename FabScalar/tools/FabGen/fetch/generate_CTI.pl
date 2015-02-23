#!/usr/bin/perl
use POSIX qw(ceil floor);


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
# Purpose: To gerate the CTIQ Module for the input configrations.
################################################################################

  sub error_ussage{
	print "Usage: perl ./generate_CTI.pl -w <fetch_width> \n";
        exit;
  }
  sub dec2bin {
      my $str 		= unpack("B32", pack("N", shift));
      #my @number 	= split("", $str); 
      #my $sting 	= 
      #$str =~ s/^0+(?=\d)//;   # otherwise you'll get leading zeros
      return $str;
  }
  #Read command line arguments
  $no_of_args = 0;
  while(@ARGV){
	$_ = shift;
	if(/^-w$/){
		$widthPipe = shift;
		$no_of_args++;
	}
	elsif(/^-c$/){
		$retireWidth = shift;
		$no_of_args++;
	}
	else{
		print "Error: Unrecognized argument $_.\n";
		&error_ussage();
	}
  }  

  if($no_of_args != 2){
	print "Too few arguments... \n";
	&error_ussage();
  }
  $width_dec = $widthPipe - 1;
  #$outfile="CtrlQueue.v";
  #open(FileHandle,">CtrlQueue.v") || die "Error: Could not open $outfile for writing";
  $FilePtr = STDOUT;
  print $FilePtr <<LABEL;
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
# Purpose: This block implements Control Queue for in-order update of branch
#	   predictor.
# Author:  FabGen
*******************************************************************************/


`timescale 1ns/100ps

module CtrlQueue( 

LABEL
  for($i=0; $i<$widthPipe; $i++){
  print $FilePtr <<LABEL;
                   input  [`BRANCH_TYPE-1:0]  inst${i}CtrlType_i,
                   input  [`SIZE_PC-1:0] pc${i}_i,
                   output [`SIZE_CTI_LOG-1:0] ctiqTag${i}_o,

LABEL
  }


  print $FilePtr <<LABEL;

		   input  clk,
                   input  reset,
                   input  recoverFlag_i,
                   input  stall_i,

                   input  fs1Ready_i,
                   input  [`FETCH_BANDWIDTH-1:0] ctrlVector_i,
                   input  [`SIZE_CTI_LOG-1:0] ctiQueueIndex_i,
                   input  [`SIZE_PC-1:0] targetAddr_i,
                   input  branchOutcome_i,
                   input  flagRecoverEX_i,
                   input  ctrlVerified_i,
                   input [`RETIRE_WIDTH-1:0] commitCti_i,

                   output updateEn_o,
                   output updateDir_o,
                   output [`SIZE_PC-1:0] updatePC_o,
                   output [`SIZE_PC-1:0] updateTarAddr_o,
                   output [`BRANCH_TYPE-1:0] updateCtrlType_o,
                   output ctiQueueFull_o
	);

reg [`SIZE_PC+`BRANCH_TYPE-1:0]         ctiqInfo0 [`SIZE_CTI_QUEUE-1:0];
reg [`SIZE_PC:0]                        ctiqInfo1 [`SIZE_CTI_QUEUE-1:0];
reg [`SIZE_CTI_QUEUE-1:0]               ctiqCommitted;

`ifdef GBP
reg [`BHR_WIDTH-1:0]                    ctiqBHR  [`SIZE_CTI_QUEUE-1:0];
`endif

reg [`SIZE_CTI_LOG-1:0]                 headPtr;
reg [`SIZE_CTI_LOG-1:0]                 tailPtr;
reg [`SIZE_CTI_LOG-1:0]                 commitPtr;

reg [`SIZE_CTI_LOG:0]                   ctrlCount;

wire                                    updateEn;
wire                                    updateDir;
wire [`SIZE_PC-1:0]                     updatePC;
wire [`SIZE_PC-1:0]                     updateTarAddr;
wire [`BRANCH_TYPE-1:0]                 updateCtrlType;
wire                                    ctiQueueFull;

reg [`CTRL_CNT_FETCH_BLOCK-1:0]         ctrlcount_fetchb;
reg [`SIZE_CTI_LOG:0]                   ctrlcount_mispre;
reg [`SIZE_CTI_LOG-1:0]                 tailPtr_mispre;
reg [`SIZE_CTI_LOG-1:0]                 commitCnt;

reg [`SIZE_CTI_LOG:0]                   ctrlcount_f0;
reg [`SIZE_CTI_LOG:0]                   ctrlcount_f1;
reg [`SIZE_CTI_LOG:0]                   ctrlcount_f2;
LABEL




  for($i=0; $i<$widthPipe; $i++){
  print $FilePtr <<LABEL;
reg [`SIZE_CTI_LOG-1:0]                 ctiq${i}Tag;

LABEL
  }

  for($i=0; $i<$retireWidth; $i++){
	print $FilePtr "wire [`SIZE_CTI_LOG-1:0]                commitPtr_t${i};\n";
  }
  for($i=1; $i<$widthPipe; $i++){
	print $FilePtr "wire [`SIZE_CTI_LOG-1:0]                tailPtr_t${i};\n";
  }

  print $FilePtr <<LABEL;
assign ctiQueueFull     = (ctrlcount_fetchb > (`SIZE_CTI_QUEUE-ctrlCount));
assign ctiQueueFull_o   = ctiQueueFull;
assign updatePC         = ctiqInfo0[headPtr][`SIZE_PC+`BRANCH_TYPE-1:`BRANCH_TYPE];
assign updateCtrlType   = ctiqInfo0[headPtr][`BRANCH_TYPE-1:0];
assign updateTarAddr    = ctiqInfo1[headPtr][`SIZE_PC:1];
assign updateDir        = ctiqInfo1[headPtr][0];
assign updateEn         = ctiqCommitted[headPtr] & (|ctrlCount) & ~recoverFlag_i;

assign updatePC_o       = updatePC;
assign updateCtrlType_o = updateCtrlType;
assign updateTarAddr_o  = updateTarAddr;
assign updateDir_o      = updateDir;
assign updateEn_o       = updateEn;

LABEL

  for($i=0; $i<$widthPipe; $i++){
	print $FilePtr "assign ctiqTag${i}_o       = ctiq${i}Tag;\n";
  }

print $FilePtr <<LABEL;
always @(*)
begin:COUNT_CTRL
 reg                            isWrap;
 reg [`SIZE_CTI_LOG-1:0]        diff1;
 reg [`SIZE_CTI_LOG-1:0]        diff2;
 reg [`SIZE_CTI_LOG-1:0]        cnt;
 reg [`SIZE_CTI_LOG-1:0]        tailPtr_t;
 reg [`SIZE_CTI_LOG-1:0]        headPtr_t;

LABEL

  print $FilePtr " ctrlcount_fetchb	= ";
  for($i=0; $i<$widthPipe; $i++){
	print $FilePtr "ctrlVector_i[${i}] ";
	if($i != $width_dec){
		print $FilePtr "+";
	}
	else {
		print $FilePtr ";\n";
	}

  }

print $FilePtr <<LABEL;
 if(fs1Ready_i && ~stall_i && ~ctiQueueFull)
        ctrlcount_f0         = ctrlCount + ctrlcount_fetchb;
 else
        ctrlcount_f0         = ctrlCount;


 if(updateEn) // CTIQ is releasing top of queue entry to update the BTB and BPB
 begin
        ctrlcount_f1 = ctrlcount_f0 - 1'b1;
        headPtr_t    = headPtr    + 1'b1;
 end
 else
 begin
        ctrlcount_f1 = ctrlcount_f0;
        headPtr_t    = headPtr;
 end

 ctrlcount_f2        = ctrlcount_f1;

 if(fs1Ready_i && ~stall_i && ~ctiQueueFull)
        tailPtr_t    = tailPtr + ctrlcount_fetchb;
 else
        tailPtr_t    = tailPtr;

LABEL

  print $FilePtr " commitCnt	= ";
  for($i=0; $i<$retireWidth; $i++){
        print $FilePtr "commitCti_i[${i}] ";
        if($i != $retireWidth - 1){
                print $FilePtr "+";
        }
        else {
                print $FilePtr ";\nend\n";
        }

  }

 print $FilePtr "\nalways @(*)\nbegin:TAG_ASSIGN\n";
 for($i=0; $i<$widthPipe; $i++){
	print $FilePtr " reg [`SIZE_CTI_LOG-1:0] tag${i};\n";
}

 for($i=0; $i<$widthPipe; $i++){
        print $FilePtr "  tag${i}     = tailPtr + $i;\n";
}

 for($i=0; $i<$widthPipe; $i++){
        print $FilePtr "  ctiq${i}Tag = 0;\n";
}

 print $FilePtr " case(ctrlVector_i)\n";
 $total_cases = 1 << $widthPipe;
 for($i=0;$i<$total_cases;$i++){
        $str = &dec2bin($i);
        @bin_case 	= split("", $str); 
	print $FilePtr "\t${widthPipe}'b";
	$start = 32 - $widthPipe;
	for($j=$start;$j<32;$j++){
		print $FilePtr "@bin_case[$j]";
	}
	print $FilePtr ":\n\tbegin\n";
	$tag_cnt = 0;
	for($j=31;$j>=$start;$j--){
		if(@bin_case[$j] == 1){
		$cti_tag = 31-$j;
		print $FilePtr "\t\tctiq${cti_tag}Tag = tag${tag_cnt} ; \n";
		$tag_cnt = $tag_cnt + 1;
		}
	}
	print $FilePtr "\tend\n";
 }
 print $FilePtr " endcase\nend\n";
 print $FilePtr <<LABEL;
always @(posedge clk)
begin
  if(reset)
  begin
        headPtr         <= 0;
        commitPtr       <= 0;
  end
  else
  begin
    if(updateEn)
        headPtr         <= headPtr + 1'b1;

    commitPtr           <= commitPtr+commitCnt;
  end
end

always @(posedge clk)
begin
  if(reset)
  begin
        ctrlCount       <= 0;
  end
  else if(recoverFlag_i)
  begin
        ctrlCount       <= (commitPtr >= headPtr) ? (commitPtr-headPtr):(`SIZE_CTI_QUEUE-(headPtr-commitPtr));
  end
  else
  begin
        ctrlCount       <= ctrlcount_f2;
  end
end

LABEL

 for($i=1;$i<$widthPipe;$i++){
	print $FilePtr " assign tailPtr_t${i}  =  tailPtr + ${i};\n";
 }
 for($i=0;$i<$retireWidth;$i++){
	print $FilePtr " assign commitPtr_t${i}  =  commitPtr + ${i};\n";
 }

 print $FilePtr <<LABEL;
always @(posedge clk)
begin:WRITE_CTIQ
 integer i;

 if(reset)
 begin
   tailPtr               <= 0;
   for(i=0;i<`SIZE_CTI_QUEUE;i=i+1)
   begin
        ctiqInfo0[i]     <= 0;
        ctiqInfo1[i]     <= 0;
        ctiqCommitted[i] <= 0;
   end
 end
 else
 begin
   if(recoverFlag_i)
   begin
        tailPtr         <= commitPtr;
   end
   else
   begin
     if(ctrlVerified_i)
     begin
        ctiqInfo1[ctiQueueIndex_i]      <= {targetAddr_i,branchOutcome_i};
     end

     case(commitCnt)
LABEL
	for($i=1;$i<=$retireWidth;$i++){
		print $FilePtr "\t${retireWidth}'d${i}:\n\tbegin\n";
		for($j=0;$j<$i;$j++){
			print $FilePtr "\t\tctiqCommitted[commitPtr_t${j}]  <= 1'b1;\n";
		}
		print $FilePtr "\tend\n";
	}
	print $FilePtr "     endcase\n    if(fs1Ready_i && ~stall_i && ~ctiQueueFull)\n     begin\n";
	print $FilePtr "\ttailPtr\t<=";
        for($i=0;$i<$widthPipe;$i++){
		print $FilePtr "ctrlVector_i[${i}] +";
	}
	print $FilePtr " tailPtr;\n\n\tcase(ctrlVector_i)\n";
	$total_cases = 1 << $widthPipe;
	for($i=0;$i<$total_cases;$i++){
		print $FilePtr "${widthPipe}'b";
        	$str 		= &dec2bin($i);
	        @bin_case 	= split("", $str); 
	        $start = 32 - $widthPipe;
        	for($j=$start;$j<32;$j++){
                print $FilePtr "@bin_case[$j]";
        	}
	        print $FilePtr ":\n\tbegin\n";
		$tag_cnt = 0;
		for($j=31;$j>=$start;$j--){
		if(@bin_case[$j] == 1){
		$cti_tag = 31-$j;
		if($tag_cnt ==0){
			print $FilePtr "\t\tctiqInfo0[tailPtr] <= {pc${cti_tag}_i,inst${cti_tag}CtrlType_i};\n";
			print $FilePtr "\t\tctiqCommitted[tailPtr]       <= 0;\n";
			print $FilePtr "\t\t`ifdef VERIFY\n\t\tctiqInfo1[tailPtr]           <= 0;\n\t\t`endif\n";
		}
		else {
			print $FilePtr "\t\tctiqInfo0[tailPtr_t${tag_cnt}] <= {pc${cti_tag}_i,inst${cti_tag}CtrlType_i};\n";
			print $FilePtr "\t\tctiqCommitted[tailPtr_t${tag_cnt}]       <= 0;\n";
			print $FilePtr "\t\t`ifdef VERIFY\n\t\tctiqInfo1[tailPtr_t${tag_cnt}]           <= 0;\n\t\t`endif\n";
		}
		$tag_cnt = $tag_cnt + 1;
		}
		}
	print $FilePtr "\tend\n";
	}
	print $FilePtr "    endcase\n    end\n   end\n  end\n end\nendmodule\n\n";


