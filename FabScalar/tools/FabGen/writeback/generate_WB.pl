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
# Purpose: To gerate the WriteBack Module for the input configrations.
################################################################################

  sub error_ussage{
	print "Usage: perl ./generate_RR.pl -w <issue_width> -p <pipe depth> -dw <datawidth>\n";
        exit;
  }
  #Read command line arguments
  $no_of_args = 0;
  while(@ARGV){
	$_ = shift;
	if(/^-w$/){
		$widthPipe = shift;
		$no_of_args++;
	}
	elsif(/^-p$/){
		$depthPipe = shift;
	#	$iqSizeLog = log2($iqSize);
		$no_of_args++;
	}
	elsif(/^-dw$/){
		$data_width = shift;
		$no_of_args++;
        }
	else{
		print "Error: Unrecognized argument $_.\n";
		&error_ussage();
	}
  }  

  if($no_of_args != 3){
	print "Too few arguments... \n";
	&error_ussage();
  }
  else{
	#print "Issue Width: $widthPipe\n";
     #   print "Pipe Depth: $depthPipe\n";
  }
  #$outfile="WriteBack.v";
  #open(FileHandle,">WriteBack.v") || die "Error: Could not open $outfile for writing";
  #$FilePtr = FileHandle;

 $width_dec = $widthPipe -1;

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
# Purpose: This module implements Writeback.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

LABEL

  print "\nmodule WriteBack (\n";
  for($i=0;$i<$widthPipe;$i++){
	print "\t\t\tinput exePacketValid${i}_i,\n";

	if($i != $width_dec)
	{
		print "\t\t\tinput [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                          `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket${i}_i,\n";
	}
	else
	{
         print "\t\t\tinput [`CHECKPOINTS+`LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
			  `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket${i}_i,\n";
	}

	print "\t\t\toutput writebkValid${i}_o,\n";
	print "\t\t\toutput [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU${i}_o,\n";
	print "\t\t\toutput bypassValid${i}_o,\n";
	print "\t\t\toutput [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket${i}_o,\n";
	print "\t\t\toutput [`SIZE_PC-1:0] computedAddr${i}_o,\n";
  }
 print "\t\t\tinput lsuPacketValid0_i,\n";
 print "\t\t\tinput [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:0] lsuPacket0_i,\n";
 print "\t\t\tinput [`SIZE_ACTIVELIST_LOG:0] ldViolationPacket_i,\n";
 print "\t\t\toutput agenIqFreedValid0_o,\n\t\t\toutput [`SIZE_ISSUEQ_LOG-1:0] agenIqEntry0_o,\n";
 print "\t\t\toutput ctrlVerified_o,\n\t\t\toutput ctrlMispredict_o,\n\t\t\toutput ctrlConditional_o,\n";
 print "\t\t\toutput [`CHECKPOINTS_LOG-1:0] ctrlSMTid_o,\n\t\t\toutput [`SIZE_PC-1:0] ctrlTargetAddr_o,\n";
 print "\t\t\toutput ctrlBrDirection_o,\n\t\t\toutput [`SIZE_CTI_LOG-1:0] ctrlCtiQueueIndex_o,\n";
 print "\t\t\toutput [`SIZE_ACTIVELIST_LOG:0] ldViolationPacket_o,\n\t\t\tinput clk,\n\t\t\tinput reset\n\t\t\t);\n";

 ### 
 for($i=0;$i<$widthPipe;$i++){
 print " reg [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket${i};\n";
 print " reg\t\t\texePacketValid${i};\n";
 if($i != $width_dec){
	 print " wire [`EXECUTION_FLAGS-1:0]    exePacket${i}Flags;\n";
 	 print " reg\t\t\tinvalidateFu${i}Packet;\n";
 }
 else{
	 print " wire [`EXECUTION_FLAGS-1:0]    lsuPacket0Flags;\n";
 	 print " reg\t\t\tinvalidateLsuPacket;\n";
 }
 }

 print " reg\t\t\tinvalidatelsuPacket;\n";
 print <<LABEL;

 wire                           ctrlVerified;
 wire                           ctrlMispredict;
 wire                           ctrlConditional;
 wire [`CHECKPOINTS_LOG-1:0]    ctrlSMTid;
 wire [`SIZE_PC-1:0]            ctrlTargetAddr;
 wire                           ctrlBrDirection;
 wire [`SIZE_CTI_LOG-1:0]       ctrlCtiQueueIndex;

 reg                            lsuPacketValid0;
 reg [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:0]
                                lsuPacket0;
 reg [`SIZE_ACTIVELIST_LOG:0]   ldViolationPacket, ldViolationPacket_l1, ldViolationPacket_l2, ldViolationPacket_l3;
LABEL

 for($i=0;$i<$depthPipe;$i++){
	for($j=0;$j<$widthPipe;$j++){
		print " reg\twritebkValid${j}_l${i};\n";
		print " reg  [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU${j}_l${i};\n";
		print " reg  [`SIZE_PC-1:0] computedAddr${j}_l${i};\n";
	}
 }

 $depth_dec = $depthPipe -1 ;
 for($i=0;$i<$widthPipe;$i++){
	print " assign writebkValid${i}_o \t= writebkValid${i}_l${depth_dec};\n";
	print " assign ctrlFU${i}_o \t	= ctrlFU${i}_l${depth_dec};\n";
	if($i != $width_dec){
		print " assign bypassValid${i}_o \t= exePacketValid${i} & exePacket${i}Flags[4];\n";
	}
	else{
		print " assign bypassValid${i}_o \t= lsuPacketValid0 & lsuPacket0Flags[4];\n";
	}
	if($i == $widthPipe - 2){
		print " assign computedAddr${i}_o \t	= computedAddr${i}_l${depth_dec};\n";
	}
	else{
		print " assign computedAddr${i}_o \t	= 0;\n";
	}
 }

 if($depthPipe == 1){
	 print "assign ldViolationPacket_o  = ldViolationPacket; \n"; 
 }
 else{
	 print "assign ldViolationPacket_o  = ldViolationPacket_l${depth_dec}; \n"; 
 }

 for($i=0;$i<$widthPipe;$i++){
    if($i!=$widthPipe-1){
	print <<LABEL;
 assign bypassPacket${i}_o = {exePacket${i}[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                             `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:1+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
                             `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC],
                              exePacket${i}[`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+
                             `SIZE_PC:1+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC],
                              exePacket${i}[`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:1+`SIZE_CTI_LOG+`SIZE_PC],
                              1'b0
                             };
LABEL
}
   else{
	print <<LABEL;
 assign bypassPacket${width_dec}_o = {lsuPacket0[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:
                           `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG],
                           lsuPacket0[`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:
                           `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG],`CHECKPOINTS_LOG'b0,
                           1'b0
                          };
LABEL
   }
 }

$i = $widthPipe-2; # For branches

 print <<LABEL;
 assign agenIqFreedValid0_o  = lsuPacketValid0;
 assign agenIqEntry0_o       = lsuPacket0[`SIZE_ISSUEQ_LOG-1:0];

 assign ctrlVerified        = exePacketValid${i};
 assign ctrlConditional     = exePacket${i}Flags[5];
 assign ctrlMispredict      = 0;
 assign ctrlSMTid           = exePacket${i}[`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_CTI_LOG+`SIZE_PC+1];

 assign ctrlTargetAddr      = exePacket${i}[`SIZE_PC:1];
 assign ctrlBrDirection     = exePacket${i}[0];
 assign ctrlCtiQueueIndex   = exePacket${i}[`SIZE_CTI_LOG+`SIZE_PC:`SIZE_PC+1];

 assign ctrlVerified_o      = ctrlVerified;
 assign ctrlConditional_o   = ctrlConditional;
 assign ctrlMispredict_o    = ctrlMispredict;
 assign ctrlSMTid_o         = ctrlSMTid;
 assign ctrlTargetAddr_o    = ctrlTargetAddr;
 assign ctrlBrDirection_o   = ctrlBrDirection;
 assign ctrlCtiQueueIndex_o = ctrlCtiQueueIndex;

always @(*)
 begin:INVALIDATE_WB_ON_MISPREDICT
LABEL

 for($i=0;$i<$width_dec;$i++){
	print "reg  [`CHECKPOINTS-1:0]\tfu${i}BranchMask;\n";
 }
	print "reg  [`CHECKPOINTS-1:0]\tlsuBranchMask;\n";
 for($i=0;$i<$width_dec;$i++){
	print <<LABEL;
 fu${i}BranchMask = exePacket${i}[`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
                  `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
                  `EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                  `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

  if(ctrlVerified && ctrlMispredict && fu${i}BranchMask[ctrlSMTid])
        invalidateFu${i}Packet = 1'b1;
  else
        invalidateFu${i}Packet = 1'b0;

LABEL
 }

 print <<LABEL;
  lsuBranchMask = lsuPacket0[`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:
                  `EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG];

  if(ctrlVerified && ctrlMispredict && lsuBranchMask[ctrlSMTid])
        invalidateLsuPacket = 1'b1;
  else
        invalidateLsuPacket = 1'b0;
end

LABEL

 ### writebkValid
 if($depthPipe>1){
	print "\n always @(posedge clk)\n begin\n\tif(reset)\n\tbegin\n";
	for($i=1;$i<$depthPipe;$i++){
	   for($j=0;$j<$widthPipe;$j++){
		print "\t\twritebkValid${j}_l${i} <= 0;\n";
	   }
	}
	print "\tend\n\telse\n\tbegin\n";
	for($i=1;$i<$depthPipe;$i++){
	   $i_dec = $i-1;
           for($j=0;$j<$widthPipe;$j++){
		if($i==1){
		    if($j<$width_dec){
			$RHS = " exePacketValid${j} & ~invalidateFu${j}Packet;";
		    }
		    else{
			$RHS = " lsuPacketValid0 & ~invalidateLsuPacket;";
		    }
		}
	      else{
			$RHS = " writebkValid${j}_l${i_dec};";
	      }
	      print "\t\twritebkValid${j}_l${i} <= ${RHS}\n";
	   }
	}
 print "\tend\n end\n";
 }
 else{
	print "\n always @(*)\n begin\n";
	for($j=0;$j<$widthPipe;$j++){
		$LHS = "writebkValid${j}_l0";
		if($j!=$width_dec){
		$RHS = "exePacketValid${j} & ~invalidateFu${j}Packet;";
		}
		else{
		$RHS = "lsuPacketValid0 & ~invalidateLsuPacket;";
		}
		print " $LHS = $RHS \n";
	}
	print "\n end\n";
 }

 ### ctrlFU
 if($depthPipe>1){
        print "\n always @(posedge clk)\n begin\n\tif(reset)\n\tbegin\n";
	for($i=1;$i<$depthPipe;$i++){
	   for($j=0;$j<$widthPipe;$j++){
		print "\t\tctrlFU${j}_l${i} <= 0;\n";
	   }
	}
	print "\tend\n\telse\n\tbegin\n";

        for($i=1;$i<$depthPipe;$i++){
	   $i_dec = $i - 1;
           for($j=0;$j<$widthPipe;$j++){
		$LHS = "ctrlFU${j}_l${i}";
		if($i==1){
		    if($j<$width_dec){
		       $RHS = " {exePacket${j}[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                                `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                                `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1],
                                 exePacket${j}Flags[`WRITEBACK_FLAGS-1:0]
                                };";
		    }
		    else{
                       $RHS = " {lsuPacket0[`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:`SIZE_ISSUEQ_LOG],
                                 lsuPacket0Flags[`WRITEBACK_FLAGS-1:0]
                                };";
		    }
		}
		else{
		   $RHS = "ctrlFU${j}_l${i_dec};";
		}
		print "\t\t\t${LHS} <= ${RHS} \n";
    	   }
	}
 print "\tend\n end\n";
 }
 else{
        print "\n always @(*)\n begin\n";
        for($j=0;$j<$widthPipe;$j++){
                $LHS = "ctrlFU${j}_l0";
                if($j!=$width_dec){
                $RHS = " {exePacket${j}[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                        `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                        `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1],
                         exePacket${j}Flags[`WRITEBACK_FLAGS-1:0]
                         };";
		}
		else{
		$RHS =  " {lsuPacket0[`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:`SIZE_ISSUEQ_LOG],
                           lsuPacket0Flags[`WRITEBACK_FLAGS-1:0]
                          };";
		}
	  print " $LHS = $RHS \n";
	}
 	print " end\n";
 }

 ### computed address
 $wp_dec2 = $widthPipe - 2;
 if($depthPipe>1){
        print "\n always @(posedge clk)\n begin\n\tif(reset)\n\tbegin\n";
	for($i=1;$i<$depthPipe;$i++){
		print "\t\tcomputedAddr${wp_dec2}_l${i} <= 0;\n";
	}
	print "\tend\n\telse\n\tbegin\n";
        for($i=1;$i<$depthPipe;$i++){
	   $i_dec = $i - 1;
		$LHS = "computedAddr${wp_dec2}_l${i}";
		if($i==1){
                       $RHS = " ctrlTargetAddr;";
		}
		else{
		   $RHS = "computedAddr${wp_dec2}_l${i_dec};";
		}
		print "\t\t\t${LHS} <= ${RHS} \n";
	}
 print "\tend\n end\n";
 }
 else{
        print "\n always @(*)\n begin\n";
                $LHS = "computedAddr${wp_dec2}_l0";
		$RHS =  " ctrlTargetAddr;";
	  print " $LHS = $RHS \n";
 	  print " end\n";
 }

 ### extracts flag vector from the execution packet
 for($i=0;$i<$widthPipe;$i++){
	if($i<$width_dec){
		print "assign exePacket${i}Flags =  exePacket${i}[`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
                         `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
                         `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                         `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];\n\n";
	}
	else{
		print "assign lsuPacket0Flags = lsuPacket0[`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
                         `SIZE_ISSUEQ_LOG-1:`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG];\n\n";
	}
 }

 ### output from the execution unit
 print "always @(posedge clk)\nbegin\n if(reset)\n begin\n";
 for($i=0;$i<$widthPipe;$i++){
	if($i<$width_dec){
		print "\texePacket${i}\t<= 0;\n";
		print "\texePacketValid${i}\t<= 0;\n";
	}
	else{
		print "\tlsuPacket0\t<= 0;\n\tlsuPacketValid0\t<= 0;\n";
	}
 }
 print "\tend\n\telse\n\tbegin\n";
 for($i=0;$i<$widthPipe;$i++){
        if($i<$width_dec){
		print "\texePacketValid${i} <= exePacketValid${i}_i;\n";
		print "\tif(exePacketValid${i}_i)\n";
		print "\t\texePacket${i}  <= exePacket${i}_i;\n\t`ifdef VERIFY\n\telse\n";
		print "\t\texePacket${i}  <= 0;\n\t`endif\n";
        }
        else{
		print <<LABEL;
        if(lsuPacketValid0_i)
        begin
                lsuPacket0         <= lsuPacket0_i;
                ldViolationPacket  <= ldViolationPacket_i;
        end
        `ifdef VERIFY
        else
        begin
                lsuPacket0         <= 0;
                ldViolationPacket  <= 0;
        end
        `endif
	lsuPacketValid0  <= lsuPacketValid0_i;
LABEL
        }
 }
 print "\n\tend\n end\n";

 if($depthPipe>1){
   print "always @(posedge clk)\nbegin\n if(reset)\n begin\n";
	for($i=1;$i<$depthPipe;$i++){
		print "\t\tldViolationPacket_l${i} <= 0;\n"
	}
   print "\tend\n\telse\n\tbegin\n";
	for($i=1;$i<$depthPipe;$i++){
		$i_dec = $i-1;
		$LHS = "ldViolationPacket_l${i}";
		if($i_dec>0){
			$RHS = "ldViolationPacket_l${i_dec}";
		}
		else{
			$RHS = "ldViolationPacket";
		}
		print "\t\t${LHS} <= ${RHS}; \n";
	}
 print "\n\tend\n end\n";
 }
 print "\nendmodule\n\n";



# OLD VERSION 
# 
# #!/usr/bin/perl
# use POSIX qw(ceil floor);
# 
# 
# #########################################################################################################
# #######
# #######		File Name	: 	generate_WB.v
# #######		Purpose		:	To gerate the WriteBack Module for the input configrations
# #######		Date		:	MAR 22, 2010
# #######		Input Parameters:	1. Pipeline Width
# #######					2. Pipeline Stages
# #######		Author		:	Tanmay Shah
# #######
# #########################################################################################################
# 
#   sub error_ussage{
# 	print "Usage: perl ./generate_RR.pl -w <issue_width> -p <pipe depth> -dw <datawidth>\n";
#         exit;
#   }
#   #Read command line arguments
#   $no_of_args = 0;
#   while(@ARGV){
# 	$_ = shift;
# 	if(/^-w$/){
# 		$widthPipe = shift;
# 		$no_of_args++;
# 	}
# 	elsif(/^-p$/){
# 		$depthPipe = shift;
# 	#	$iqSizeLog = log2($iqSize);
# 		$no_of_args++;
# 	}
# 	elsif(/^-dw$/){
# 		$data_width = shift;
# 		$no_of_args++;
#         }
# 	else{
# 		print "Error: Unrecognized argument $_.\n";
# 		&error_ussage();
# 	}
#   }  
# 
#   if($no_of_args != 3){
# 	print "Too few arguments... \n";
# 	&error_ussage();
#   }
# 
#   print '`include "/afs/eos.ncsu.edu/lockers/research/ece/ericro/users/hmayukh/cvs/FabScalar/beta/verilog/FabScalarParam.v"';
# 
#   print "\nmodule WriteBack (\n";
#   for($i=0;$i<$widthPipe;$i++){
# 	print "\t\t\tinput exePacketValid${i}_i,\n";
# 	print "\t\t\tinput [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+\n
#                           `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket${i}_i,\n";
# 	print "\t\t\toutput writebkValid${i}_o,\n";
# 	print "\t\t\toutput [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU0_o,\n";
#   }
#  print "\t\t\tinput lsuPacketValid0_i,\n";
#  print "\t\t\tinput [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:0] lsuPacket0_i,\n";
#  print "\t\t\toutput bypassValid${i}_o,\n";
#  print "\t\t\toutput [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket${i}_o,\n";
#  print "\t\t\toutput agenIqFreedValid0_o,\n\t\t\toutput [`SIZE_ISSUEQ_LOG-1:0] agenIqEntry0_o,\n";
#  print "\t\t\toutput ctrlVerified_o,\n\t\t\toutput ctrlMispredict_o,\n\t\t\toutput ctrlConditional_o,\n";
#  print "\t\t\toutput [`CHECKPOINTS_LOG-1:0] ctrlSMTid_o,\n\t\t\toutput [`SIZE_PC-1:0] ctrlTargetAddr_o,\n";
#  print "\t\t\toutput ctrlBrDirection_o,\n\t\t\toutput [`SIZE_CTI_LOG-1:0] ctrlCtiQueueIndex_o,\n";
#  print "\t\t\toutput [`SIZE_ACTIVELIST_LOG:0] ldViolationPacket_o,\n\t\t\tinput clk,\n\t\t\tinput reset\n\t\t\t);\n";
# 
#  ### 
#  for($i=0;$i<$widthPipe;$i++){
#  print " reg [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
#       `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket${i};\n";
#  print " reg\t\t\texePacketValid${i};\n";
#  print " reg\t\t\tinvalidateFu${i}Packet;\n";
#  print " wire [`EXECUTION_FLAGS-1:0]    exePacket${i}Flags;\n";
#  }
# 
#  print <<LABEL;
# 
#  wire                           ctrlVerified;
#  wire                           ctrlMispredict;
#  wire                           ctrlConditional;
#  wire [`CHECKPOINTS_LOG-1:0]    ctrlSMTid;
#  wire [`SIZE_PC-1:0]            ctrlTargetAddr;
#  wire                           ctrlBrDirection;
#  wire [`SIZE_CTI_LOG-1:0]       ctrlCtiQueueIndex;
# 
#  reg                            lsuPacketValid0;
#  reg [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:0]
#                                 lsuPacket0;
#  reg [`SIZE_ACTIVELIST_LOG:0]   ldViolationPacket, ldViolationPacket_l1, ldViolationPacket_l2, ldViolationPacket_l3;
# LABEL
# 
#  for($i=0;$i<$depthPipe;$i++){
# 	for($j=0;$j<$widthPipe;$j++){
# 		print " reg\twritebkValid${j}_l${i};\n";
# 		print " reg  [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU${j}_l${i};\n";
# 	}
#  }
# 
#  $depth_dec = $depthPipe -1 ;
#  for($i=0;$i<$widthPipe;$i++){
# 	print " assign writebkValid${i}_o \t= writebkValid${i}_l${depth_dec};\n";
# 	print " assign ctrlFU${i}_o \t	= ctrlFU${i}_l${depth_dec};\n";
# 	print " assign bypassValid${i}_o \t= exePacketValid${i} & exePacket${i}Flags[4];\n";
#  }
# 
#  $width_dec = $widthPipe -1;
#  for($i=0;$i<$widthPipe;$i++){
#     if($i!=$widthPipe-1){
# 	print <<LABEL;
#  assign bypassPacket${i}_o = {exePacket${i}[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
#                              `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:1+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
#                              `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC],
#                               exePacket${i}[`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+
#                              `SIZE_PC:1+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC],
#                               exePacket${i}[`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:1+`SIZE_CTI_LOG+`SIZE_PC],
#                               1'b0
#                              };
# LABEL
# }
#    else{
# 	print <<LABEL;
#  assign bypassPacket${width_dec}_o = {lsuPacket0[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:
#                            `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG],
#                            lsuPacket0[`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:
#                            `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG],`CHECKPOINTS_LOG'b0,
#                            1'b0
#                           };
# LABEL
#    }
#  }
# 
#  print <<LABEL;
#  assign agenIqFreedValid0_o  = lsuPacketValid0;
#  assign agenIqEntry0_o       = lsuPacket0[`SIZE_ISSUEQ_LOG-1:0];
# 
#  assign ctrlVerified        = exePacketValid2;
#  assign ctrlConditional     = exePacket2Flags[5];
#  assign ctrlMispredict      = exePacket2Flags[0];
#  assign ctrlSMTid           = exePacket2[`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_CTI_LOG+`SIZE_PC+1];
# 
#  assign ctrlTargetAddr      = exePacket2[`SIZE_PC:1];
#  assign ctrlBrDirection     = exePacket2[0];
#  assign ctrlCtiQueueIndex   = exePacket2[`SIZE_CTI_LOG+`SIZE_PC:`SIZE_PC+1];
# 
#  assign ctrlVerified_o      = ctrlVerified;
#  assign ctrlConditional_o   = ctrlConditional;
#  assign ctrlMispredict_o    = ctrlMispredict;
#  assign ctrlSMTid_o         = ctrlSMTid;
#  assign ctrlTargetAddr_o    = ctrlTargetAddr;
#  assign ctrlBrDirection_o   = ctrlBrDirection;
#  assign ctrlCtiQueueIndex_o = ctrlCtiQueueIndex;
# 
# always @(*)
#  begin:INVALIDATE_WB_ON_MISPREDICT
# LABEL
# 
#  for($i=0;$i<$width_dec;$i++){
# 	print <<LABEL;
#  reg [`CHECKPOINTS-1:0]         fu${i}BranchMask;
#  fu${i}BranchMask = exePacket${i}[`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
#                   `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
#                   `EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
#                   `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
# 
#   if(ctrlVerified && ctrlMispredict && fu${i}BranchMask[ctrlSMTid])
#         invalidateFu${i}Packet = 1'b1;
#   else
#         invalidateFu${i}Packet = 1'b0;
# 
# LABEL
#  }
# 
#  print <<LABEL;
#   lsuBranchMask = lsuPacket0[`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:
#                   `EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG];
# 
#   if(ctrlVerified && ctrlMispredict && lsuBranchMask[ctrlSMTid])
#         invalidateLsuPacket = 1'b1;
#   else
#         invalidateLsuPacket = 1'b0;
# end
# 
# LABEL
# 
#  ### writebkValid
#  if($depthPipe>1){
# 	print "\n always @(posedge clk)\n begin\n\tif(reset)\n\tbegin\n";
# 	for($i=1;$i<$depthPipe;$i++){
# 	   for($j=0;$j<$widthPipe;$j++){
# 		print "\t\twritebkValid${j}_l${i} <= 0;\n";
# 	   }
# 	}
# 	print "\tend\n\telse\n\tbegin\n";
# 	for($i=1;$i<$depthPipe;$i++){
# 	   $i_dec = $i-1;
#            for($j=0;$j<$widthPipe;$j++){
# 		if($i==1){
# 		    if($j<$width_dec){
# 			$RHS = " exePacketValid${i} & ~invalidateFu${i}Packet;";
# 		    }
# 		    else{
# 			$RHS = " lsuPacketValid0 & ~invalidateLsuPacket;";
# 		    }
# 		}
# 	      else{
# 			$RHS = " writebkValid${j}_l${i_dec};";
# 	      }
# 	      print "\t\twritebkValid${j}_l${i} <= ${RHS}\n";
# 	   }
# 	}
#  print "\tend\n end\n";
#  }
#  else{
# 	for($j=0;$j<$widthPipe;$j++){
# 		$LHS = "writebkValid${j}_l0";
# 		if($j!=$width_dec){
# 		$RHS = "exePacketValid${j} & ~invalidateFu${j}Packet;";
# 		}
# 		else{
# 		$RHS = "lsuPacketValid${j} & ~invalidateLsu${j}Packet;";
# 		}
# 		print " assign $LHS = $RHS \n";
# 	}
#  }
# 
#  ### ctrlFU
#  if($depthPipe>1){
#         print "\n always @(posedge clk)\n begin\n\tif(reset)\n\tbegin\n";
# 	for($i=1;$i<$depthPipe;$i++){
# 	   for($j=0;$j<$widthPipe;$j++){
# 		print "\t\tctrlFU${j}_l${i} <= 0;\n";
# 	   }
# 	}
# 	print "\tend\n\telse\n\tbegin\n";
# 
#         for($i=1;$i<$depthPipe;$i++){
# 	   $i_dec = $i - 1;
#            for($j=0;$j<$widthPipe;$j++){
# 		$LHS = "ctrlFU${j}_l${i}";
# 		if($i==1){
# 		    if($j<$width_dec){
# 		       $RHS = " {exePacket${j}[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
#                                 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
#                                 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1],
#                                  exePacket${j}Flags[`WRITEBACK_FLAGS-1:0]
#                                 };";
# 		    }
# 		    else{
#                        $RHS = " {lsuPacket0[`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:`SIZE_ISSUEQ_LOG],
#                                  lsuPacket0Flags[`WRITEBACK_FLAGS-1:0]
#                                 };";
# 		    }
# 		}
# 		else{
# 		   $RHS = "ctrlFU${j}_l${i_dec}";
# 		}
# 		print "\t\t\t${LHS} <= ${RHS} \n";
#     	   }
# 	}
#  print "\tend\n end\n";
#  }
#  else{
#         for($j=0;$j<$widthPipe;$j++){
#                 $LHS = "ctrlFU${j}_l0";
#                 if($j!=$width_dec){
#                 $RHS = " {exePacket${j}[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
#                         `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
#                         `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1],
#                          exePacket${j}Flags[`WRITEBACK_FLAGS-1:0]
#                          };";
# 		}
# 		else{
# 		$RHS =  " {lsuPacket0[`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:`SIZE_ISSUEQ_LOG],
#                            lsuPacket0Flags[`WRITEBACK_FLAGS-1:0]
#                           };";
# 		}
# 	  print " assign $LHS = $RHS \n";
# 	}
#  }
# 
#  ### extracts flag vector from the execution packet
#  for($i=0;$i<$widthPipe;$i++){
# 	if($i<$width_dec){
# 		print "assign exePacket${i}Flags =  exePacket${i}[`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
#                          `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
#                          `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
#                          `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];\n\n";
# 	}
# 	else{
# 		print "assign lsuPacket0Flags = lsuPacket0[`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
#                          `SIZE_ISSUEQ_LOG-1:`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG];\n\n";
# 	}
#  }
# 
#  ### output from the execution unit
#  print "always @(posedge clk)\nbegin\n if(reset)\n begin\n";
#  for($i=0;$i<$widthPipe;$i++){
# 	if($i<$width_dec){
# 		print "\texePacket${i}\t<= 0;\n";
# 		print "\texePacketValid${i}\t<= 0;\n";
# 	}
# 	else{
# 		print "\tlsuPacket0\t<= 0;\n\tlsuPacketValid0\t<= 0;\n";
# 	}
#  }
#  print "\tend\n\telse\n\tbegin\n";
#  for($i=0;$i<$widthPipe;$i++){
#         if($i<$width_dec){
# 		print "\texePacketValid${i} <= exePacketValid${i}_i;\n";
# 		print "\tif(exePacketValid${i}_i)\n";
# 		print "\t\texePacket${i}  <= exePacket${i}_i;\n\t`ifdef VERIFY\n\telse\n";
# 		print "\t\texePacket0  <= 0;\n\t`endif";
#         }
#         else{
# 		print <<LABEL;
#         if(lsuPacketValid0_i)
#         begin
#                 lsuPacket0         <= lsuPacket0_i;
#                 ldViolationPacket  <= ldViolationPacket_i;
#         end
#         `ifdef VERIFY
#         else
#         begin
#                 lsuPacket0         <= 0;
#                 ldViolationPacket  <= 0;
#         end
#         `endif
# 	lsuPacketValid0  <= lsuPacketValid0_i;
# LABEL
#         }
#  }
#  print "\n\tend\n end\n";
# 
#  if($depthPipe>1){
#    print "always @(posedge clk)\nbegin\n if(reset)\n begin\n";
# 	for($i=1;$i<$depthPipe;$i++){
# 		print "\t\tldViolationPacket_l${i} <= 0;\n"
# 	}
#    print "\tend\n\telse\n\tbegin\n";
# 	for($i=1;$i<$depthPipe;$i++){
# 		$i_dec = $i-1;
# 		$LHS = "ldViolationPacket_l${i}";
# 		if($i_dec>0){
# 			$RHS = "ldViolationPacket_l${i_dec}";
# 		}
# 		else{
# 			$RHS = "ldViolationPacket";
# 		}
# 		print "\t\t${LHS} <= ${RHS}; \n";
# 	}
#  }
#  print "\n\tend\n end\nendmodule\n\n";
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
