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
# Purpose: To gerate the Fetch2Decode Module for the input configrations.
################################################################################

  sub error_ussage{
	print "Usage: perl ./generate_F2D.pl -w <fetch_width> \n";
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
  #$outfile="Fetch1Fetch2.v";
  #open(FileHandle,">Fetch1Fetch2.v") || die "Error: Could not open $outfile for writing";
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
# Purpose: This implements pipeline register between Fetch1 and Fetch2 stages.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

module Fetch1Fetch2( input clk,
LABEL
 
 for($i=0;$i<$widthPipe;$i++){
	print $FilePtr <<LABEL;
                     input btbHit${i}_i,
                     input [`SIZE_PC-1:0] targetAddr${i}_i,
                     input prediction${i}_i,

                     output reg btbHit${i}_o,
                     output reg [`SIZE_PC-1:0] targetAddr${i}_o,
                     output reg prediction${i}_o,

LABEL
 }
 print $FilePtr <<LABEL;
                     input reset,
                     input flush_i,
                     input stall_i,
                     input fs1Ready_i,
                     input [`SIZE_PC-1:0] pc_i,

                     input [`INSTRUCTION_BUNDLE-1:0] instructionBundle_i,

                     `ifdef ICACHE
                     input startBlock_i,
                     input [1:0] firstInst_i,
                     `endif

                     `ifdef ICACHE
                     output reg startBlock_o,
                     output reg [1:0] firstInst_o
                     `endif
                     output reg [`SIZE_PC-1:0] pc_o,
                     output reg [`INSTRUCTION_BUNDLE-1:0] instructionBundle_o,

                     output reg fs1Ready_o
                   );
always @(posedge clk)
begin
 if(reset || flush_i)
 begin
        fs1Ready_o          <= 0;
        pc_o                <= 0;
        instructionBundle_o <= 0;
        `ifdef ICACHE
        startBlock_o        <= 0;
        firstInst_o         <= 0;
        `endif
LABEL
 for($i=0;$i<$widthPipe;$i++){
	print $FilePtr "\tbtbHit${i}_o           <= 0;\n";
	print $FilePtr "\ttargetAddr${i}_o       <= 0;\n";
	print $FilePtr "\tprediction${i}_o       <= 0;\n";
 }
 print $FilePtr "  end\n else\n begin\n\n   if(~stall_i)\n   begin\n";
 print $FilePtr "\tfs1Ready_o          <= fs1Ready_i;\n";
 print $FilePtr "\tpc_o                <= pc_i;\n";
 print $FilePtr "\tinstructionBundle_o <= instructionBundle_i;\n";
 print $FilePtr "\t`ifdef ICACHE\n\tstartBlock_o        <= startBlock_i;\n\tfirstInst_o         <= firstInst_i;\n\t`endif\n";
 for($i=0;$i<$widthPipe;$i++){
	print $FilePtr "\tbtbHit${i}_o           <= btbHit${i}_i;\n";
	print $FilePtr "\ttargetAddr${i}_o       <= targetAddr${i}_i;\n";
	print $FilePtr "\tprediction${i}_o       <= prediction${i}_i;\n";
 }

 print $FilePtr "  end\n end\nend\n\nendmodule\n\n";


