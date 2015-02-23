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
  #$outfile="L1ICache.v";
  #open(FileHandle,">L1ICache.v") || die "Error: Could not open $outfile for writing";
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
# Purpose: 
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

module L1ICache ( input clk,
                  input reset,
                  input [`SIZE_PC-1:0] addr_i,                  // Address of the insts to be fetched
                  input rdEnable_i,                             // Read enable for inst cache
                  input wrEnabale_i,                            // Write enable from lower level memory hierarchy
                  input  [`SIZE_PC-1:0] wrAddr_i,               // Write address from the L1 inst Cache MSHR
                  input  [4*`SIZE_INSTRUCTION-1:0] instBlock_i, // Inst block from lower level memory hierarchy
                  output [`INSTRUCTION_BUNDLE-1:0] instBundle_o,// Inst block read from the L1 Cache
                  output miss_o,                                // Signal for Inst Cache miss
                  output [`SIZE_PC-1:0] missAddr_o              // Physical Address for the cache miss
                );

LABEL

 for($i=0;$i<$widthPipe;$i++){
	print $FilePtr <<LABEL;
 reg [(`SIZE_INSTRUCTION/2)-1:0] opcode${i};
 reg [(`SIZE_INSTRUCTION/2)-1:0] operand${i};

 wire [`SIZE_PC-1:0] addr${i};
 reg [`SIZE_PC-1:0] addr${i}_p;

LABEL
 } 

 print $FilePtr "\n assign miss_o = 1'b0;\n";
 for($i=0;$i<$widthPipe;$i++){
	$temp = $i * 8;
	print $FilePtr " assign addr${i}  = addr_i+ ${temp};\n";
 }
 print $FilePtr "\n always @(*)\n begin\n";
 for($i=0;$i<$widthPipe;$i++){
	print $FilePtr "\topcode${i}  = \$read_opcode(addr${i});\n";
	print $FilePtr "\toperand${i} = \$read_operand(addr${i});\n";
 }
 print $FilePtr " end\n  assign instBundle_o = {";
 for($i=$width_dec;$i>=0 ;$i--){
	if($i == 0){
		print $FilePtr "opcode${i}, operand${i}};\n\nendmodule\n\n";
	}
	else{
		print $FilePtr "opcode${i}, operand${i},";
	}
 }




