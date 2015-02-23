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


module Decode_PISA ( input  instPacketValid_i,
		     input  [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] instPacket_i,
                     output decodedPacket0Valid_o,
                     output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                             1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket0_o,
                     output decodedPacket1Valid_o,
                     output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                             1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket1_o	
             	   );




/* Wires and regs definition for combinational logic. */
wire [`SIZE_INSTRUCTION-1:0]            instruction;
wire [`SIZE_PC-1:0]                     pc;
wire [`SIZE_PC-1:0]                     preTargetAddr;
wire [`SIZE_CTI_LOG-1:0]                ctiTag;
wire                                    preBranchDir;

wire [`SIZE_OPCODE_P-1:0] 		opcode;

reg 					valid_0;
reg [`SIZE_OPCODE_P-1:0]               	opcode_0;
reg [`SIZE_RMT_LOG:0] 			instLogical1_0;
reg [`SIZE_RMT_LOG:0] 			instLogical2_0;
reg [`SIZE_RMT_LOG:0] 			instDest_0;
reg [`SIZE_SPECIAL_REG-1:0] 		instSrcHL_0;
reg [`SIZE_SPECIAL_REG-1:0] 		instDestHL_0;
reg [`SIZE_IMMEDIATE:0] 		instImmediate_0;
reg [`SIZE_PC-1:0] 			instTarget_0;
reg [`INST_TYPES_LOG-1:0] 		instFU_0;
reg [`LDST_TYPES_LOG-1:0] 		instldstSize_0;
reg 					instLoad_0;
reg 					instStore_0;
reg 					instbranch_0; 

reg					valid_1;
reg [`SIZE_OPCODE_P-1:0]               	opcode_1;
reg [`SIZE_RMT_LOG:0]                   instLogical1_1;
reg [`SIZE_RMT_LOG:0]                   instLogical2_1;
reg [`SIZE_RMT_LOG:0]                   instDest_1;
reg [`SIZE_SPECIAL_REG-1:0]             instSrcHL_1;
reg [`SIZE_SPECIAL_REG-1:0]             instDestHL_1;
reg [`SIZE_IMMEDIATE:0]                 instImmediate_1;
reg [`SIZE_PC-1:0]                      instTarget_1;
reg [`INST_TYPES_LOG-1:0]               instFU_1;
reg [`LDST_TYPES_LOG-1:0]               instldstSize_1;
reg                                     instLoad_1;
reg                                     instStore_1;
reg                                     instbranch_1;



/* Following assigns decoded output of the instruction to appropriate port. */
assign decodedPacket0Valid_o = valid_0;
assign decodedPacket0_o      = {instDestHL_0,instSrcHL_0,instbranch_0,instStore_0,instLoad_0,instldstSize_0,
                                instFU_0,instImmediate_0,instDest_0,instLogical2_0,instLogical1_0,opcode_0[`SIZE_OPCODE_I-1:0],
                                pc,instTarget_0,ctiTag,preBranchDir};

assign decodedPacket1Valid_o = valid_1 & instPacketValid_i;
assign decodedPacket1_o      = {instDestHL_1,instSrcHL_1,instbranch_1,instStore_1,instLoad_1,instldstSize_1,
                                instFU_1,instImmediate_1,instDest_1,instLogical2_1,instLogical1_1,opcode_1[`SIZE_OPCODE_I-1:0],
                                pc,instTarget_1,ctiTag,preBranchDir};



/* Following extracts instructions from the packet, follows by opcode extraction
 * from the instructions.
 */
assign instruction             	= instPacket_i[`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign pc                      	= instPacket_i[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1];
assign preTargetAddr           	= instPacket_i[`SIZE_PC+`SIZE_CTI_LOG:`SIZE_CTI_LOG+1];
assign ctiTag                  	= instPacket_i[`SIZE_CTI_LOG:1];
assign preBranchDir            	= instPacket_i[0];


/* Following extracts source registers, destination register, immediate field and 
 * target address from instruction. Bit-0 of each wire is set to 1 if the field
 * is valid for the corresponding instruction.
 */
assign opcode     		= instruction[`SIZE_INSTRUCTION-1:`SIZE_INSTRUCTION-`SIZE_OPCODE_P];

always @(*)
begin
  valid_0		= instPacketValid_i;
  opcode_0		= opcode;
  instLogical1_0	= 0;
  instLogical2_0	= 0;
  instDest_0		= 0;
  instSrcHL_0		= 0;
  instDestHL_0		= 0;
  instImmediate_0	= 0;
  instTarget_0		= 0;
  instFU_0		= 0;
  instldstSize_0	= 0;
  instLoad_0		= 0;
  instStore_0		= 0;
  instbranch_0		= 0;

  valid_1		= 0;
  opcode_1		= 0;
  instLogical1_1        = 0;
  instLogical2_1        = 0;
  instDest_1            = 0;
  instSrcHL_1           = 0;
  instDestHL_1          = 0;
  instImmediate_1       = 0;
  instTarget_1          = 0;
  instFU_1              = 0;
  instldstSize_1        = 0;
  instLoad_1            = 0;
  instStore_1           = 0;
  instbranch_1          = 0;
 

  case(opcode)
    `JUMP: begin
          instLogical1_0  = 0;
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = 0;
	  instTarget_0	 = instruction[`SIZE_TARGET-1:0];
          instFU_0        = `INSTRUCTION_TYPE2;
        end
    
  `JAL: begin
          instLogical1_0  = 0;
          instLogical2_0  = 0;
          instDest_0      = {5'b11111,1'b1};
          instImmediate_0 = 0;
	  instTarget_0    = instruction[`SIZE_TARGET-1:0];
          instFU_0        = `INSTRUCTION_TYPE2;
        end

   `JR: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = 0;
          instTarget_0    = preTargetAddr;
          instFU_0        = `INSTRUCTION_TYPE2;
	  instbranch_0    = 1'b1;
        end

 `JALR: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = preTargetAddr;
          instFU_0        = `INSTRUCTION_TYPE2;
	  instbranch_0    = 1'b1;
        end

  `BEQ: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = preTargetAddr;
          instFU_0        = `INSTRUCTION_TYPE2;
  	  instbranch_0    = 1'b1;                      
        end

  `BNE: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = preTargetAddr;
          instFU_0        = `INSTRUCTION_TYPE2;
  	  instbranch_0    = 1'b1;                      
        end

 `BLEZ: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = preTargetAddr;
          instFU_0        = `INSTRUCTION_TYPE2;
  	  instbranch_0    = 1'b1;                      
        end

 `BGTZ: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = preTargetAddr;
          instFU_0        = `INSTRUCTION_TYPE2;
  	  instbranch_0    = 1'b1;                      
        end

 `BLTZ: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = preTargetAddr;
          instFU_0        = `INSTRUCTION_TYPE2;
  	  instbranch_0    = 1'b1;                      
        end

 `BGEZ: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = preTargetAddr;
          instFU_0        = `INSTRUCTION_TYPE2;
  	  instbranch_0    = 1'b1;                      
        end

   `LB: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE3;
          instldstSize_0  = `LDST_BYTE;
          instLoad_0      = 1'b1;                       
        end

  `LBU: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE3;
          instldstSize_0  = `LDST_BYTE;
          instLoad_0      = 1'b1;                       
        end

   `LH: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE3;
          instldstSize_0  = `LDST_HALF_WORD;
          instLoad_0      = 1'b1;                       
        end
 
  `LHU: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE3;
          instldstSize_0  = `LDST_HALF_WORD;
          instLoad_0      = 1'b1;                       
        end

   `LW: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE3;
          instldstSize_0  = `LDST_WORD;
          instLoad_0      = 1'b1;                       
        end

  `DLW: begin
	  // inst-fission performed for DLW
	  //$display("DLW instruction occured, PC:%h",pc);
	  opcode_0	  = `DLW_L;		
	  instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE3;
          instldstSize_0  = `LDST_WORD;
          instLoad_0      = 1'b1;

	  valid_1 	  = 1'b1; 
	  opcode_1        = `DLW_H;
          instLogical1_1  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_1  = 0;
          instDest_1      = {(instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU]+1),1'b1};
          instImmediate_1 = {(instruction[`SIZE_IMMEDIATE-1:0]+4),1'b1};
          instTarget_1    = 0;
          instFU_1        = `INSTRUCTION_TYPE3;
          instldstSize_1  = `LDST_WORD;
          instLoad_1      = 1'b1;	
	end  

   `SB: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE3;
          instldstSize_0  = `LDST_BYTE;
          instStore_0     = 1'b1;                       
        end

   `SH: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE3;
          instldstSize_0  = `LDST_HALF_WORD;
          instStore_0     = 1'b1;                       
        end

   `SW: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE3;
          instldstSize_0  = `LDST_WORD;
          instStore_0     = 1'b1;                       
        end

  `DSW: begin
	  // inst-fission performed for DSW
	  $display("DSW instruction occured, PC:%h",pc);
          opcode_0        = `DSW_L;
	  instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = 0;
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE3;
          instldstSize_0  = `LDST_WORD;
          instStore_0     = 1'b1;

	  valid_1 	  = 1'b1; 
	  opcode_1        = `DSW_H;
          instLogical1_1  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_1  = {(instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU]+1),1'b1};
          instDest_1      = 0;
          instImmediate_1 = {(instruction[`SIZE_IMMEDIATE-1:0]+4),1'b1};
          instTarget_1    = 0;
          instFU_1        = `INSTRUCTION_TYPE3;
          instldstSize_1  = `LDST_WORD;
          instStore_1     = 1'b1;	
	end

  `ADD: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

 `ADDU: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

  `SUB: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

 `SUBU: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

 `MULT: begin
	  // inst-fission performed for MULT
	  //$display("MULT instruction occured, PC:%h",pc);
	  opcode_0	  = `MULT_L;
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {`SIZE_RMT_LOG'd32,1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE1;
          //instDestHL_0    = 2'b10;

	  valid_1	  = 1'b1;	
	  opcode_1        = `MULT_H;
          instLogical1_1  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_1  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_1      = {`SIZE_RMT_LOG'd33,1'b1};
          instImmediate_1 = 0;
          instTarget_1    = 0;
          instFU_1        = `INSTRUCTION_TYPE1;
          //instDestHL_1    = 2'b11;	
        end

`MULTU: begin
	  // inst-fission performed for MULTU
	  //$display("MULTU instruction occured, PC:%h",pc);
	  opcode_0	  = `MULTU_L;
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {`SIZE_RMT_LOG'd32,1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE1;
          //instDestHL_0    = 2'b10;

	  valid_1	  = 1'b1;	
	  opcode_1        = `MULTU_H;
          instLogical1_1  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_1  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_1      = {`SIZE_RMT_LOG'd33,1'b1};
          instImmediate_1 = 0;
          instTarget_1    = 0;
          instFU_1        = `INSTRUCTION_TYPE1;
          //instDestHL_0    = 2'b11;
        end

  `DIV: begin
	  // inst-fission performed for DIV
	  //$display("DIV instruction occured, PC:%h",pc);
	  opcode_0	  = `DIV_L;
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {`SIZE_RMT_LOG'd32,1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE1;
          //instDestHL_0    = 2'b10;

	  valid_1	  = 1'b1;	
	  opcode_1        = `DIV_H;
          instLogical1_1  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_1  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_1      = {`SIZE_RMT_LOG'd33,1'b1};
          instImmediate_1 = 0;
          instTarget_1    = 0;
          instFU_1        = `INSTRUCTION_TYPE1;
          //instDestHL_1    = 2'b11;	
        end

 `DIVU: begin
	  // inst-fission performed for DIVU
	  //$display("DIVU instruction occured, PC:%h",pc);
	  opcode_0	  = `DIVU_L;
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {`SIZE_RMT_LOG'd32,1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE1;
          //instDestHL_0    = 2'b10;

	  valid_1         = 1'b1;
          opcode_1        = `DIVU_H;
          instLogical1_1  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_1  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_1      = {`SIZE_RMT_LOG'd33,1'b1};
          instImmediate_1 = 0;
          instTarget_1    = 0;
          instFU_1        = `INSTRUCTION_TYPE1;
          //instDestHL_1    = 2'b11;	
        end

 `MFHI: begin
          instLogical1_0  = {`SIZE_RMT_LOG'd33,1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
	  //instSrcHL_0     = 2'b11;
        end

 `MFLO: begin
          instLogical1_0  = {`SIZE_RMT_LOG'd32,1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
	  //instSrcHL_0     = 2'b10;
        end

 `MTHI: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {`SIZE_RMT_LOG'd33,1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
          //instDestHL_0    = 2'b11;
        end

 `MTLO: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {`SIZE_RMT_LOG'd32,1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
          //instDestHL_0    = 2'b10;
        end

  `AND_: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

   `OR: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

  `XOR: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

  `NOR: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

  `SLL: begin
          instLogical1_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_RU-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

  `SRL: begin
          instLogical1_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_RU-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

  `SRA: begin
          instLogical1_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_RU-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

  `SLT: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

 `SLTU: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

 `ADDI: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

`ADDIU: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

 `ANDI: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

  `ORI: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

 `XORI: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

 `SLLV: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

 `SRLV: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

 `SRAV: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instDest_0      = {instruction[`SIZE_RD+`SIZE_RU-1:`SIZE_RU],1'b1};
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

 `SLTI: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

`SLTIU: begin
          instLogical1_0  = {instruction[`SIZE_RS+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU],1'b1};
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

  `NOP: begin
          instLogical1_0  = 0;
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
        end

  `LUI: begin
	  instLogical1_0  = 0;
          instLogical2_0  = 0;
          instDest_0      = {instruction[`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RD+`SIZE_RU],1'b1};
          instImmediate_0 = {instruction[`SIZE_IMMEDIATE-1:0],1'b1};
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE0;
	end

 `SYSCALL: begin
	  //$display("\nDecode: PC:%x SYSCALL Encountered...",pc);
	  instLogical1_0  = 0;
          instLogical2_0  = 0;
          instDest_0      = 0;
          instImmediate_0 = 0;
          instTarget_0    = 0;
          instFU_0        = `INSTRUCTION_TYPE1; 
	   end

 default: begin
	   //$display("\nWARNING: PC:%x Opcode %x Not Found in Decode Unit",pc,opcode);
  	   //$finish;		
	  end
  endcase

end


endmodule

