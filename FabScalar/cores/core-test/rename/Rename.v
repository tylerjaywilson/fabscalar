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

module Rename(  input clk,
                input reset,
                input stall_i,

                input flagRecoverEX_i,
                input ctrlVerified_i,
                input [`CHECKPOINTS_LOG-1:0] ctrlVerifiedSMTid_i,

                input decodeReady_i,
                input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
                       3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket0_i,

                input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
                       3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket1_i,

                input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
                       3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket2_i,

                input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
                       3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket3_i,

		input [`BRANCH_COUNT-1:0] branchCount_i,
                input commitValid0_i,
                input [`SIZE_PHYSICAL_LOG-1:0] commitReg0_i,
                input commitValid1_i,
                input [`SIZE_PHYSICAL_LOG-1:0] commitReg1_i,
                input commitValid2_i,
                input [`SIZE_PHYSICAL_LOG-1:0] commitReg2_i,
                input commitValid3_i,
                input [`SIZE_PHYSICAL_LOG-1:0] commitReg3_i,
		input recoverFlag_i,
		input [`SIZE_RMT_LOG-1:0] recoverDest0_i,
		input [`SIZE_RMT_LOG-1:0] recoverDest1_i,
		input [`SIZE_RMT_LOG-1:0] recoverDest2_i,
		input [`SIZE_RMT_LOG-1:0] recoverDest3_i,
		input [`SIZE_PHYSICAL_LOG-1:0] recoverMap0_i,
		input [`SIZE_PHYSICAL_LOG-1:0] recoverMap1_i,
		input [`SIZE_PHYSICAL_LOG-1:0] recoverMap2_i,
		input [`SIZE_PHYSICAL_LOG-1:0] recoverMap3_i,
                output [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                        `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] renamedPacket0_o,
                output [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                        `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] renamedPacket1_o,
                output [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                        `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] renamedPacket2_o,
                output [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                        `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] renamedPacket3_o,

                output noFreeSMT_o,
                output freeListEmpty_o,
                output renameReady_o
             );


wire [`SIZE_RMT_LOG:0]                  src0logical1;
wire [`SIZE_RMT_LOG:0]                  src0logical2;
wire [`SIZE_RMT_LOG:0]                  inst0Dest;
wire                                    inst0branch;

wire [`SIZE_RMT_LOG:0]                  src1logical1;
wire [`SIZE_RMT_LOG:0]                  src1logical2;
wire [`SIZE_RMT_LOG:0]                  inst1Dest;
wire                                    inst1branch;

wire [`SIZE_RMT_LOG:0]                  src2logical1;
wire [`SIZE_RMT_LOG:0]                  src2logical2;
wire [`SIZE_RMT_LOG:0]                  inst2Dest;
wire                                    inst2branch;

wire [`SIZE_RMT_LOG:0]                  src3logical1;
wire [`SIZE_RMT_LOG:0]                  src3logical2;
wire [`SIZE_RMT_LOG:0]                  inst3Dest;
wire                                    inst3branch;
wire                                    reqFreeReg0;
wire                                    reqFreeReg1;
wire                                    reqFreeReg2;
wire                                    reqFreeReg3;
 wire   			noFreeSMT;
 wire  			freeListEmpty;
wire [`SIZE_PHYSICAL_LOG:0]             src0rmt1;
wire [`SIZE_PHYSICAL_LOG:0]             src0rmt2;
wire [`SIZE_PHYSICAL_LOG:0]             dest0PhyMap;
wire [`SIZE_PHYSICAL_LOG:0]             old0PhyMap;
wire [`SIZE_PHYSICAL_LOG:0]             src1rmt1;
wire [`SIZE_PHYSICAL_LOG:0]             src1rmt2;
wire [`SIZE_PHYSICAL_LOG:0]             dest1PhyMap;
wire [`SIZE_PHYSICAL_LOG:0]             old1PhyMap;
wire [`SIZE_PHYSICAL_LOG:0]             src2rmt1;
wire [`SIZE_PHYSICAL_LOG:0]             src2rmt2;
wire [`SIZE_PHYSICAL_LOG:0]             dest2PhyMap;
wire [`SIZE_PHYSICAL_LOG:0]             old2PhyMap;
wire [`SIZE_PHYSICAL_LOG:0]             src3rmt1;
wire [`SIZE_PHYSICAL_LOG:0]             src3rmt2;
wire [`SIZE_PHYSICAL_LOG:0]             dest3PhyMap;
wire [`SIZE_PHYSICAL_LOG:0]             old3PhyMap;
wire [`CHECKPOINTS_LOG-1:0]             id0SMT;
wire [`CHECKPOINTS_LOG-1:0]             id1SMT;
wire [`CHECKPOINTS_LOG-1:0]             id2SMT;
wire [`CHECKPOINTS_LOG-1:0]             id3SMT;
wire [`CHECKPOINTS-1:0]                 branch0Mask;
wire [`CHECKPOINTS-1:0]                 branch1Mask;
wire [`CHECKPOINTS-1:0]                 branch2Mask;
wire [`CHECKPOINTS-1:0]                 branch3Mask;
wire [`SIZE_PHYSICAL_LOG:0]             freeReg0;
wire [`SIZE_PHYSICAL_LOG:0]             freeReg1;
wire [`SIZE_PHYSICAL_LOG:0]             freeReg2;
wire [`SIZE_PHYSICAL_LOG:0]             freeReg3;
wire [`SIZE_FREE_LIST_LOG-1:0]          freeListHead;
wire [`SIZE_FREE_LIST_LOG-1:0]          freeListHeadCp;
reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] renamedPkt0;
reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] renamedPkt1;
reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] renamedPkt2;
reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] renamedPkt3;

SpecFreeList specfreelist( 		.reqFreeReg0_i(reqFreeReg0),
		.reqFreeReg1_i(reqFreeReg1),
		.reqFreeReg2_i(reqFreeReg2),
		.reqFreeReg3_i(reqFreeReg3),
		.commitValid0_i(commitValid0_i),
		.commitReg0_i(commitReg0_i),
		.commitValid1_i(commitValid1_i),
		.commitReg1_i(commitReg1_i),
		.commitValid2_i(commitValid2_i),
		.commitReg2_i(commitReg2_i),
		.commitValid3_i(commitValid3_i),
		.commitReg3_i(commitReg3_i),
                           .flagRecoverEX_i(flagRecoverEX_i),
                           .ctrlVerified_i(ctrlVerified_i),
                           .freeListHeadCp_i(freeListHeadCp),
                           .stall_i(stall_i | ~decodeReady_i | noFreeSMT),
                           .reset(reset),
                           .recoverFlag_i(recoverFlag_i),
                           .clk(clk),
.freeReg0_o(freeReg0),
.freeReg1_o(freeReg1),
.freeReg2_o(freeReg2),
.freeReg3_o(freeReg3),
                           .freeListHead_o(freeListHead),
                           .freeListEmpty_o(freeListEmpty)
                   );


RenameMapTable RMT( .clk(clk),
                    .reset(reset),
                    .stall_i(stall_i | ~decodeReady_i | freeListEmpty | noFreeSMT),
                    .src0logical1_i(src0logical1),
                    .src0logical2_i(src0logical2),
                    .inst0Dest_i(inst0Dest),

                    .src1logical1_i(src1logical1),
                    .src1logical2_i(src1logical2),
                    .inst1Dest_i(inst1Dest),

                    .src2logical1_i(src2logical1),
                    .src2logical2_i(src2logical2),
                    .inst2Dest_i(inst2Dest),

                    .src3logical1_i(src3logical1),
                    .src3logical2_i(src3logical2),
                    .inst3Dest_i(inst3Dest),

		.flagRecoverEX_i(flagRecoverEX_i),
		.dest0Physical_i(freeReg0),
		.dest1Physical_i(freeReg1),
		.dest2Physical_i(freeReg2),
		.dest3Physical_i(freeReg3),
.recoverFlag_i(recoverFlag_i),
		.recoverDest0_i(recoverDest0_i),
		.recoverDest1_i(recoverDest1_i),
		.recoverDest2_i(recoverDest2_i),
		.recoverDest3_i(recoverDest3_i),
		.recoverMap0_i(recoverMap0_i),
		.recoverMap1_i(recoverMap1_i),
		.recoverMap2_i(recoverMap2_i),
		.recoverMap3_i(recoverMap3_i),
		.src0rmt1_o(src0rmt1),
		.src0rmt2_o(src0rmt2),
		.dest0PhyMap_o(dest0PhyMap),
		.old0PhyMap_o(old0PhyMap),
		.src1rmt1_o(src1rmt1),
		.src1rmt2_o(src1rmt2),
		.dest1PhyMap_o(dest1PhyMap),
		.old1PhyMap_o(old1PhyMap),
		.src2rmt1_o(src2rmt1),
		.src2rmt2_o(src2rmt2),
		.dest2PhyMap_o(dest2PhyMap),
		.old2PhyMap_o(old2PhyMap),
		.src3rmt1_o(src3rmt1),
		.src3rmt2_o(src3rmt2),
		.dest3PhyMap_o(dest3PhyMap),
		.old3PhyMap_o(old3PhyMap)
  );
assign freeListHeadCp = 0;
assign id0SMT = 0;
assign id1SMT = 0;
assign id2SMT = 0;
assign id3SMT = 0;
assign branch0Mask = 0;
assign branch1Mask = 0;
assign branch2Mask = 0;
assign branch3Mask = 0;
assign checkPointedRMT = 0;
assign noFreeSMT = 0;
assign src0logical1  =  decodedPacket0_i[`SIZE_RMT_LOG+1+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign src0logical2  =  decodedPacket0_i[2*`SIZE_RMT_LOG+2+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_RMT_LOG+1+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign inst0Dest     =  decodedPacket0_i[3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:2*`SIZE_RMT_LOG+2+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign inst0branch   =  decodedPacket0_i[3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];

assign src1logical1  =  decodedPacket1_i[`SIZE_RMT_LOG+1+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign src1logical2  =  decodedPacket1_i[2*`SIZE_RMT_LOG+2+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_RMT_LOG+1+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign inst1Dest     =  decodedPacket1_i[3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:2*`SIZE_RMT_LOG+2+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign inst1branch   =  decodedPacket1_i[3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];

assign src2logical1  =  decodedPacket2_i[`SIZE_RMT_LOG+1+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign src2logical2  =  decodedPacket2_i[2*`SIZE_RMT_LOG+2+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_RMT_LOG+1+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign inst2Dest     =  decodedPacket2_i[3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:2*`SIZE_RMT_LOG+2+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign inst2branch   =  decodedPacket2_i[3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];

assign src3logical1  =  decodedPacket3_i[`SIZE_RMT_LOG+1+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign src3logical2  =  decodedPacket3_i[2*`SIZE_RMT_LOG+2+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_RMT_LOG+1+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign inst3Dest     =  decodedPacket3_i[3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:2*`SIZE_RMT_LOG+2+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign inst3branch   =  decodedPacket3_i[3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];

assign reqFreeReg0   =  (decodeReady_i & inst0Dest[0] & ~noFreeSMT & ~stall_i);
assign reqFreeReg1   =  (decodeReady_i & inst1Dest[0] & ~noFreeSMT & ~stall_i);
assign reqFreeReg2   =  (decodeReady_i & inst2Dest[0] & ~noFreeSMT & ~stall_i);
assign reqFreeReg3   =  (decodeReady_i & inst3Dest[0] & ~noFreeSMT & ~stall_i);
always @(*)
begin:PACKET_FORMATION
 reg [`INST_TYPES_LOG-1:0] inst0fu;
 reg [`LDST_TYPES_LOG-1:0] inst0ldstSize;
 reg [`SIZE_IMMEDIATE:0]   inst0immediate;
 reg inst0load;
 reg inst0store;
 reg inst0branch;

 reg [`INST_TYPES_LOG-1:0] inst1fu;
 reg [`LDST_TYPES_LOG-1:0] inst1ldstSize;
 reg [`SIZE_IMMEDIATE:0]   inst1immediate;
 reg inst1load;
 reg inst1store;
 reg inst1branch;

 reg [`INST_TYPES_LOG-1:0] inst2fu;
 reg [`LDST_TYPES_LOG-1:0] inst2ldstSize;
 reg [`SIZE_IMMEDIATE:0]   inst2immediate;
 reg inst2load;
 reg inst2store;
 reg inst2branch;

 reg [`INST_TYPES_LOG-1:0] inst3fu;
 reg [`LDST_TYPES_LOG-1:0] inst3ldstSize;
 reg [`SIZE_IMMEDIATE:0]   inst3immediate;
 reg inst3load;
 reg inst3store;
 reg inst3branch;

 inst0fu        = decodedPacket0_i[`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 inst0ldstSize  = decodedPacket0_i[`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 inst0immediate = decodedPacket0_i[`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 inst0load      = decodedPacket0_i[1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];
 inst0store     = decodedPacket0_i[2+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];
 inst0branch    = decodedPacket0_i[3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];

 renamedPkt0 = {inst0Dest[`SIZE_RMT_LOG:1],inst0branch,inst0store,inst0load,branch0Mask,id0SMT,old0PhyMap,
                dest0PhyMap,src0rmt2,src0rmt1,inst0immediate,inst0ldstSize,inst0fu,
                decodedPacket0_i[`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0]};

 inst1fu        = decodedPacket1_i[`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 inst1ldstSize  = decodedPacket1_i[`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 inst1immediate = decodedPacket1_i[`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 inst1load      = decodedPacket1_i[1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];
 inst1store     = decodedPacket1_i[2+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];
 inst1branch    = decodedPacket1_i[3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];

 renamedPkt1 = {inst1Dest[`SIZE_RMT_LOG:1],inst1branch,inst1store,inst1load,branch1Mask,id1SMT,old1PhyMap,
                dest1PhyMap,src1rmt2,src1rmt1,inst1immediate,inst1ldstSize,inst1fu,
                decodedPacket1_i[`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0]};

 inst2fu        = decodedPacket2_i[`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 inst2ldstSize  = decodedPacket2_i[`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 inst2immediate = decodedPacket2_i[`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 inst2load      = decodedPacket2_i[1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];
 inst2store     = decodedPacket2_i[2+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];
 inst2branch    = decodedPacket2_i[3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];

 renamedPkt2 = {inst2Dest[`SIZE_RMT_LOG:1],inst2branch,inst2store,inst2load,branch2Mask,id2SMT,old2PhyMap,
                dest2PhyMap,src2rmt2,src2rmt1,inst2immediate,inst2ldstSize,inst2fu,
                decodedPacket2_i[`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0]};

 inst3fu        = decodedPacket3_i[`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 inst3ldstSize  = decodedPacket3_i[`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 inst3immediate = decodedPacket3_i[`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 inst3load      = decodedPacket3_i[1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];
 inst3store     = decodedPacket3_i[2+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];
 inst3branch    = decodedPacket3_i[3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];

 renamedPkt3 = {inst3Dest[`SIZE_RMT_LOG:1],inst3branch,inst3store,inst3load,branch3Mask,id3SMT,old3PhyMap,
                dest3PhyMap,src3rmt2,src3rmt1,inst3immediate,inst3ldstSize,inst3fu,
                decodedPacket3_i[`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0]};


end

assign renamedPacket0_o  = renamedPkt0;
assign renamedPacket1_o  = renamedPkt1;
assign renamedPacket2_o  = renamedPkt2;
assign renamedPacket3_o  = renamedPkt3;
assign renameReady_o     = (decodeReady_i & ~noFreeSMT & ~freeListEmpty);
assign freeListEmpty_o   = freeListEmpty;
assign noFreeSMT_o       = noFreeSMT;

endmodule

