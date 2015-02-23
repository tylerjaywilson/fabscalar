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
# Purpose: To generate the Fetch2Decode Module for the input configrations.
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
  #$outfile="Fetch2Decode.v";
  #open(FileHandle,">Fetch2Decode.v") || die "Error: Could not open $outfile for writing";
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
# Purpose: This module implements pipeline registers between Fetch2 and Decode
#          stage.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

module Fetch2Decode( input clk,
LABEL
 
 for($i=0;$i<$widthPipe;$i++){
	print $FilePtr <<LABEL;
                     input instruction${i}Valid_i,
                     input [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst${i}Packet_i,
                     output reg instruction${i}Valid_o,
                     output reg [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst${i}Packet_o,

LABEL
 }
 print $FilePtr <<LABEL;
                     input reset,
                     input flush_i,
                     input stall_i,

                     input [`SIZE_PC-1:0] updatePC_i,
                     input [`SIZE_PC-1:0] updateTargetAddr_i,
                     input [`BRANCH_TYPE-1:0] updateCtrlType_i,
                     input updateDir_i,
                     input updateEn_i,
                     input fs2Ready_i,

                     output reg [`SIZE_PC-1:0] updatePC_o,
                     output reg [`SIZE_PC-1:0] updateTargetAddr_o,
                     output reg [`BRANCH_TYPE-1:0] updateCtrlType_o,
                     output reg updateDir_o,
                     output reg updateEn_o,
                     output reg fs2Ready_o
                   );

always @(posedge clk)
begin
  if(reset)
  begin
        updatePC_o          <= 0;
        updateTargetAddr_o  <= 0;
        updateCtrlType_o    <= 0;
        updateDir_o         <= 0;
        updateEn_o          <= 0;
  end
  else
  begin
        updatePC_o          <= updatePC_i;
        updateTargetAddr_o  <= updateTargetAddr_i;
        updateCtrlType_o    <= updateCtrlType_i;
        updateDir_o         <= updateDir_i;
        updateEn_o          <= updateEn_i;
  end
end


always @(posedge clk)
begin
 if(reset || flush_i)
 begin
        fs2Ready_o          <= 0;

LABEL

 for($i=0;$i<$widthPipe;$i++){
	print $FilePtr "\tinstruction${i}Valid_o <= 0;\n";
	print $FilePtr "\tinst${i}Packet_o       <= 0;\n";
 }
 print $FilePtr " end\n else\n begin\n  if(~stall_i)\n   begin\n\tfs2Ready_o          <= fs2Ready_i;\n\n";
 for($i=0;$i<$widthPipe;$i++){
	print $FilePtr "\tinstruction${i}Valid_o <= instruction${i}Valid_i;\n";
	print $FilePtr "\tinst${i}Packet_o       <= inst${i}Packet_i;\n";
 }
 print $FilePtr "  end\n end\nend\n\nendmodule\n\n";


