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

 reg [(`SIZE_INSTRUCTION/2)-1:0] opcode0;
 reg [(`SIZE_INSTRUCTION/2)-1:0] operand0;

 wire [`SIZE_PC-1:0] addr0;
 reg [`SIZE_PC-1:0] addr0_p;

 reg [(`SIZE_INSTRUCTION/2)-1:0] opcode1;
 reg [(`SIZE_INSTRUCTION/2)-1:0] operand1;

 wire [`SIZE_PC-1:0] addr1;
 reg [`SIZE_PC-1:0] addr1_p;

 reg [(`SIZE_INSTRUCTION/2)-1:0] opcode2;
 reg [(`SIZE_INSTRUCTION/2)-1:0] operand2;

 wire [`SIZE_PC-1:0] addr2;
 reg [`SIZE_PC-1:0] addr2_p;

 reg [(`SIZE_INSTRUCTION/2)-1:0] opcode3;
 reg [(`SIZE_INSTRUCTION/2)-1:0] operand3;

 wire [`SIZE_PC-1:0] addr3;
 reg [`SIZE_PC-1:0] addr3_p;


 assign miss_o = 1'b0;
 assign addr0  = addr_i+ 0;
 assign addr1  = addr_i+ 8;
 assign addr2  = addr_i+ 16;
 assign addr3  = addr_i+ 24;

 always @(*)
 begin
	opcode0  = $read_opcode(addr0);
	operand0 = $read_operand(addr0);
	opcode1  = $read_opcode(addr1);
	operand1 = $read_operand(addr1);
	opcode2  = $read_opcode(addr2);
	operand2 = $read_operand(addr2);
	opcode3  = $read_opcode(addr3);
	operand3 = $read_operand(addr3);
 end
  assign instBundle_o = {opcode3, operand3,opcode2, operand2,opcode1, operand1,opcode0, operand0};

endmodule

