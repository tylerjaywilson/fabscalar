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
# Purpose: To gerate the FetchStage2 Module for the input configrations.
################################################################################

  sub error_ussage{
        print "Usage: perl ./generate_FS2.pl -w <fetch_width> \n";
        exit;
  }
  sub dec2bin {
      my $str           = unpack("B32", pack("N", shift));
      #my @number       = split("", $str);
      #my $sting        =
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
        else{
                print "Error: Unrecognized argument $_.\n";
                &error_ussage();
        }
  }

  if($no_of_args != 1){
        print "Too few arguments... \n";
        &error_ussage();
  }
  $width_dec = $widthPipe - 1;
  #$outfile= <STDOUT>;
  #open(FileHandle,">FetchStage2.v") || die "Error: Could not open $outfile for writing";
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
# Purpose: This module implements FetchStage2.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

module FetchStage2( 
LABEL
  for($i=0; $i<$widthPipe; $i++){
  print $FilePtr <<LABEL;
                     input btbHit${i}_i,
                     input [`SIZE_PC-1:0] targetAddr${i}_i,
                     input prediction${i}_i,
		     output instruction${i}Valid_o,
                     output [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst${i}Packet_o,
LABEL
  }
  print $FilePtr <<LABEL;
		     input clk,
                     input reset,
                     input recoverFlag_i,
                     input stall_i,
                     input flush_i,

                     input fs1Ready_i,
                     input [`SIZE_PC-1:0] pc_i,
                     input [`INSTRUCTION_BUNDLE-1:0] instructionBundle_i,
                     input [`SIZE_PC-1:0] addrRAS_CP_i,

                     `ifdef ICACHE
                     input startBlock_i,
                     input [1:0] firstInst_i,
                     `endif

                     input  [`SIZE_CTI_LOG-1:0] ctiQueueIndex_i,
                     input  [`SIZE_PC-1:0] targetAddr_i,
                     input  branchOutcome_i,
                     input  flagRecoverEX_i,
                     input  ctrlVerified_i,
                     input [`RETIRE_WIDTH-1:0] commitCti_i,

                     output flagRecoverID_o,
                     output [`SIZE_PC-1:0] targetAddrID_o,
                     output flagRtrID_o,
                     output flagCallID_o,
                     output [`SIZE_PC-1:0] callPCID_o,

                     output [`SIZE_PC-1:0] updatePC_o,
                     output [`SIZE_PC-1:0] updateTargetAddr_o,
                     output [`BRANCH_TYPE-1:0] updateCtrlType_o,
                     output updateDir_o,
                     output updateEn_o,
                     output fs2Ready_o,
                     output ctiQueueFull_o    // If CTI Queue is full, further Inst fetching should be stalled
                   );


reg [`FETCH_BANDWIDTH-1:0]              filterVector;
reg [`FETCH_BANDWIDTH-1:0]              ctrlVector;

reg                                     flagRecover;
reg                                     flagRtr;
reg                                     flagCall;
reg [`SIZE_PC-1:0]                      targetAddr;
reg [`SIZE_PC-1:0]                      callPC;
wire                                    ctiQueueFull;

LABEL

  for($i=0; $i<$widthPipe; $i++){
  print $FilePtr <<LABEL;
wire [`SIZE_PC-1:0]                     pc${i};
reg [`SIZE_INSTRUCTION-1:0]             instruction${i};
wire [`SIZE_OPCODE_P-1:0]               opcode${i};
wire [`BRANCH_TYPE-1:0]                 ctrlType${i};
wire [`SIZE_PC-1:0]                     targetAddr${i};
wire                                    isInst${i}Ctrl;
wire                                    isInst${i}Rtr;
reg [`SIZE_PC-1:0]                      targetAddr${i}_f;
wire [`SIZE_CTI_LOG-1:0]                ctiqTag${i};
	
LABEL
  }
  
  print $FilePtr <<LABEL;
CtrlQueue ctiQueue( .clk(clk),
LABEL
  for($i=0; $i<$widthPipe; $i++){
  print $FilePtr <<LABEL;
                    .inst${i}CtrlType_i(ctrlType${i}),
                    .pc${i}_i(pc${i}),
                    .ctiqTag${i}_o(ctiqTag${i}),

LABEL
  }

  print $FilePtr <<LABEL;
                    .reset(reset),
                    .stall_i(stall_i),
                    .recoverFlag_i(recoverFlag_i),
                    .fs1Ready_i(fs1Ready_i),
                    .ctrlVector_i(ctrlVector),
                    .ctiQueueIndex_i(ctiQueueIndex_i),
                    .targetAddr_i(targetAddr_i),
                    .branchOutcome_i(branchOutcome_i),
                    .flagRecoverEX_i(flagRecoverEX_i),
                    .ctrlVerified_i(ctrlVerified_i),
                    .commitCti_i(commitCti_i),
                    .updatePC_o(updatePC_o),
                    .updateTarAddr_o(updateTargetAddr_o),
                    .updateCtrlType_o(updateCtrlType_o),
                    .updateDir_o(updateDir_o),
                    .updateEn_o(updateEn_o),
                    .ctiQueueFull_o(ctiQueueFull)
                  );

LABEL

  for($i=0; $i<$widthPipe; $i++){
	$pc_inc = $i * 8;
	print $FilePtr "assign pc${i}     = pc_i + ${pc_inc};\n";
  }
  
  print $FilePtr "\nalways @(*)\nbegin\n";
  for($i=0; $i<$widthPipe; $i++){
	$temp = $i + 1;
	print $FilePtr "\tinstruction${i} = instructionBundle_i[${temp}*`SIZE_INSTRUCTION-1:${i}*`SIZE_INSTRUCTION];\n";
  }
  print $FilePtr "end\n\n";

  for($i=0; $i<$widthPipe; $i++){
  print $FilePtr <<LABEL;
PreDecode_PISA preDecode${i}( .pc_i(pc${i}),
                           .instruction_i(instruction${i}),
                           .prediction_i(prediction${i}_i),
                           .targetAddr_i(targetAddr${i}_i),
                           .isInstCtrl_o(isInst${i}Ctrl),
                           .isInstRtr_o(isInst${i}Rtr),
                           .targetAddr_o(targetAddr${i}),
                           .ctrlType_o(ctrlType${i})
                         );

LABEL
  }

 print $FilePtr "always @(*)\nbegin:VALIDATE_BTB\n reg [`FETCH_BANDWIDTH-1:0] branchNT;\n";
  for($i=0; $i<$widthPipe; $i++){
        print $FilePtr " reg check${i}Branch;\n reg inst${i}Ctrl;\n";
  }
  for($i=0; $i<$widthPipe; $i++){
        print $FilePtr " targetAddr${i}_f = targetAddr${i};\n";
  }
  for($i=0; $i<$widthPipe; $i++){
        print $FilePtr " check${i}Branch =  ~(ctrlType${i}[0] & ctrlType${i}[1]);\n";
  }
  for($i=0; $i<$widthPipe; $i++){
        print $FilePtr " inst${i}Ctrl    = isInst${i}Ctrl & (prediction${i}_i | check${i}Branch);\n";
  }
  for($i=0; $i<$widthPipe; $i++){
        print $FilePtr " branchNT[${i}]  = isInst${i}Ctrl & ctrlType${i}[0] & ctrlType${i}[1] & ~prediction${i}_i;\n";
  }

 $filter = (1 << $widthPipe) -1 ;
 print $FilePtr <<LABEL;

 flagRecover  = 1'b0;
 flagRtr      = 1'b0;
 flagCall     = 1'b0;
 filterVector = ${widthPipe}'d${filter};
 ctrlVector   = branchNT;

LABEL
  print $FilePtr " casex({";
  for($i=0; $i<$widthPipe; $i++){
	if($i == $width_dec){
		print $FilePtr "inst${i}Ctrl})\n ";
	}
	else{
		print $FilePtr "inst${i}Ctrl, ";
	}
  }

  for($i=0; $i<$widthPipe; $i++){
	print $FilePtr "${widthPipe}'b";
  	for($j=0; $j<$widthPipe; $j++){
		if($j<$i){
			print $FilePtr "0"; }
		else {
			if($j == $i){
			print $FilePtr "1"; }
			else{ 
			print $FilePtr "x"; }
		}	
  	}
	print $FilePtr ":\n begin\n";
	print $FilePtr "\ttargetAddr   = targetAddr${i};\n";
	print $FilePtr "\tcallPC       = pc${i};\n";
	print $FilePtr "\tfilterVector = ${widthPipe}'b";
        for($j=0; $j<$widthPipe; $j++){
		if($j <= $i){
			print $FilePtr "1";
		}
		else{
			print $FilePtr "0";
		}
	}
	$temp = $widthPipe - $i;
	$temp_dec = $temp - 1;
	print $FilePtr ";\n\tctrlVector[${width_dec}:${i}]= ${temp}'b";
        for($j=0; $j<$temp; $j++){
                if($j == $temp_dec){
                        print $FilePtr "1";
                }
                else{
                        print $FilePtr "0";
                }
        }
	print $FilePtr ";\n\tif(~btbHit${i}_i)\n\tbegin\n\t\tflagRecover = 1'b1;\n";
	print $FilePtr "\t\tif(ctrlType${i} == 2'b00)\n\t\tbegin\n";
	print $FilePtr "\t\t\ttargetAddr${i}_f = addrRAS_CP_i;\n\t\t\tflagRtr  = 1'b1;\n";
	print $FilePtr "\t\tend\n\t\tif(ctrlType${i} == 2'b01)\n\t\t\tflagCall = 1'b1;\n";
	print $FilePtr "\tend\n end\n";
  }

  print $FilePtr " endcase\nend\n";
  print $FilePtr <<LABEL;
assign flagRecoverID_o = flagRecover & ~stall_i & ~ctiQueueFull;
assign flagRtrID_o     = flagRtr;
assign flagCallID_o    = flagCall;
assign targetAddrID_o  = targetAddr;
assign callPCID_o      = callPC;

LABEL

 for($i=0;$i<$widthPipe;$i++){
	$temp = $widthPipe-$i-1;
	print $FilePtr "assign inst${i}Packet_o         = {instruction${i},pc${i},targetAddr${i}_f,ctiqTag${i},prediction${i}_i};\n";
	print $FilePtr "assign instruction${i}Valid_o   = filterVector[${temp}];\n";
 }

 print $FilePtr <<LABEL;

assign ctiQueueFull_o = ctiQueueFull;
assign fs2Ready_o     = fs1Ready_i & ~ctiQueueFull;

LABEL
 print $FilePtr "\nendmodule\n\n";

