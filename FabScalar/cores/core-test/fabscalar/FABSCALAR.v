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
# Purpose: This module is top level block where all the pipeline stages are
#	   integrated.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

module FABSCALAR(  input clock,
                   input reset,
                   input wrL1ICacheEnable_i,
                   input [`SIZE_PC-1:0] wrAddrL1ICache_i,
                   input [`CACHE_WIDTH-1:0]   wrBlockL1ICache_i,
                   output missL1ICache_o,
                   output [`SIZE_PC-1:0] missAddrL1ICache_o
		);
/*****************************Wire Declaration**********************************/
// Wires from Interface module
wire wrL1ICacheEnable_l1;
wire [`SIZE_PC-1:0] wrAddrL1ICache_l1;
wire [`CACHE_WIDTH-1:0] wrBlockL1ICache_l1;
	// Wires from FetchStage1 module
	wire missL1ICache;
	wire [`SIZE_PC-1:0] missAddrL1ICache;

	wire fs1Ready;
	wire [`INSTRUCTION_BUNDLE-1:0] instructionBundle;
	wire [`SIZE_PC-1:0] pc;
	wire [`SIZE_PC-1:0] addrRAS_CP;
	wire startBlock;  
	wire [1:0] firstInst;
	wire btbHit0;
	wire [`SIZE_PC-1:0] targetAddr0;
	wire prediction0;
	wire btbHit1;
	wire [`SIZE_PC-1:0] targetAddr1;
	wire prediction1;
	wire btbHit2;
	wire [`SIZE_PC-1:0] targetAddr2;
	wire prediction2;
	wire btbHit3;
	wire [`SIZE_PC-1:0] targetAddr3;
	wire prediction3;

	// Wires from Fetch1Fetch2 module
	wire fs1Ready_l1;
	wire [`INSTRUCTION_BUNDLE-1:0] instructionBundle_l1;
	wire [`SIZE_PC-1:0] pc_l1;
	wire startBlock_l1;
	wire [1:0] firstInst_l1;
	wire btbHit0_l1;
	wire [`SIZE_PC-1:0] targetAddr0_l1;
	wire prediction0_l1;
	wire btbHit1_l1;
	wire [`SIZE_PC-1:0] targetAddr1_l1;
	wire prediction1_l1;
	wire btbHit2_l1;
	wire [`SIZE_PC-1:0] targetAddr2_l1;
	wire prediction2_l1;
	wire btbHit3_l1;
	wire [`SIZE_PC-1:0] targetAddr3_l1;
	wire prediction3_l1;

	// Wires from FetchStage2 module
	wire flagRecoverID;
	wire [`SIZE_PC-1:0] targetAddrID;
	wire flagRtrID;
	wire flagCallID;
	wire [`SIZE_PC-1:0] callPCID;
	wire [`SIZE_PC-1:0] updatePC;
	wire [`SIZE_PC-1:0] updateTargetAddr;
	wire [`BRANCH_TYPE-1:0] updateCtrlType;
	wire updateDir;
	wire updateEn;
	wire instruction0Valid;
	wire [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst0Packet;
	wire instruction1Valid;
	wire [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst1Packet;
	wire instruction2Valid;
	wire [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst2Packet;
	wire instruction3Valid;
	wire [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst3Packet;
	wire fs2Ready;
	wire ctiQueueFull;


	// Wires from Fetch2Decode module
	wire [`SIZE_PC-1:0] updatePC_l1;
	wire [`SIZE_PC-1:0] updateTargetAddr_l1;
	wire [`BRANCH_TYPE-1:0] updateCtrlType_l1;
	wire updateDir_l1;
	wire updateEn_l1;
	wire fs2Ready_l1;
	wire instruction0Valid_l1;
	wire [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst0Packet_l1;
	wire instruction1Valid_l1;
	wire [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst1Packet_l1;
	wire instruction2Valid_l1;
	wire [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst2Packet_l1;
	wire instruction3Valid_l1;
	wire [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst3Packet_l1;

	// Wires from Decode module
	wire decodeReady;
	wire [2*`FETCH_BANDWIDTH-1:0] decodedVector;
	wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket0;
	wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket1;
	wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket2;
	wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket3;
	wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket4;
	wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket5;
	wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket6;
	wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket7;

// Wires from Instruction Buffer module
wire instBufferFull;
wire instBufferReady;
wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket0_l1;
wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket1_l1;
wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket2_l1;
wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket3_l1;
wire [`BRANCH_COUNT-1:0] branchCount;


// Wires from InstBufRename
wire instBufferReady_l1;
wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket0_l2;
wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket1_l2;
wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket2_l2;
wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket3_l2;
wire [`BRANCH_COUNT-1:0] branchCount_l1;


// Wires from Rename module
wire noFreeSMT;
wire freeListEmpty;
wire renameReady;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] renamedPacket0;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] renamedPacket1;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] renamedPacket2;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] renamedPacket3;

// Wires from RenameDispatch module
wire renameReady_l1;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] renamedPacket0_l1;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] renamedPacket1_l1;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] renamedPacket2_l1;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] renamedPacket3_l1;

//wires from Dispatch module
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] dispatchPacket0;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] dispatchPacket1;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] dispatchPacket2;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] dispatchPacket3;

wire [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] dispatchPacket0_al;
wire [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] dispatchPacket1_al;
wire [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] dispatchPacket2_al;
wire [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] dispatchPacket3_al;

wire backEndReady;
wire stallfrontEnd;


//wires from Dispatch module
wire backEndReady_l1;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] dispatchPacket0_iq;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] dispatchPacket1_iq;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] dispatchPacket2_iq;
wire [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
`SIZE_CTI_LOG:0] dispatchPacket3_iq;

wire [`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] alPacket0_al;
wire [`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] alPacket1_al;
wire [`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] alPacket2_al;
wire [`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] alPacket3_al;

wire [`CHECKPOINTS+`LSQ_FLAGS-1:0] dispatchPacket0_lsq;
wire [`CHECKPOINTS+`LSQ_FLAGS-1:0] dispatchPacket1_lsq;
wire [`CHECKPOINTS+`LSQ_FLAGS-1:0] dispatchPacket2_lsq;
wire [`CHECKPOINTS+`LSQ_FLAGS-1:0] dispatchPacket3_lsq;

wire [`CHECKPOINTS-1:0] updatedBranchMask0_l1;
wire [`CHECKPOINTS-1:0] updatedBranchMask1_l1;
wire [`CHECKPOINTS-1:0] updatedBranchMask2_l1;
wire [`CHECKPOINTS-1:0] updatedBranchMask3_l1;

// wires for issueq module
wire [`SIZE_ISSUEQ_LOG:0]cntInstIssueQ;
wire grantedValid0;
wire [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] grantedPacket0;
wire grantedValid1;
wire [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] grantedPacket1;
wire grantedValid2;
wire [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] grantedPacket2;
wire grantedValid3;
wire [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] grantedPacket3;

// wires for iq_regread module
wire grantedValid0_l1;
wire [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] grantedPacket0_l1;
wire grantedValid1_l1;
wire [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] grantedPacket1_l1;
wire grantedValid2_l1;
wire [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] grantedPacket2_l1;
wire grantedValid3_l1;
wire [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] grantedPacket3_l1;

// wire for reg_read module
wire [`SIZE_PHYSICAL_LOG:0] newDestMap0;
wire [`SIZE_PHYSICAL_LOG:0] newDestMap1;
wire [`SIZE_PHYSICAL_LOG:0] newDestMap2;
wire [`SIZE_PHYSICAL_LOG:0] newDestMap3;

wire [`SIZE_PHYSICAL_TABLE-1:0] phyRegRdy;
wire [2*`SIZE_DATA+`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket0;
wire fuPacketValid0;
wire [2*`SIZE_DATA+`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket1;
wire fuPacketValid1;
wire [2*`SIZE_DATA+`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket2;
wire fuPacketValid2;
wire [2*`SIZE_DATA+`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket3;
wire fuPacketValid3;

// wires for rsr module
wire [`SIZE_PHYSICAL_LOG-1:0] granted0Dest;
wire [`SIZE_ISSUEQ_LOG-1:0] granted0Entry;
wire [`SIZE_PHYSICAL_LOG-1:0] granted1Dest;
wire [`SIZE_ISSUEQ_LOG-1:0] granted1Entry;
wire [`SIZE_PHYSICAL_LOG-1:0] granted2Dest;
wire [`SIZE_ISSUEQ_LOG-1:0] granted2Entry;
wire granted3Dest;
wire granted3Entry;

wire [`SIZE_ISSUEQ_LOG-1:0] freedEntry0;
wire freedValid0;
wire [`SIZE_ISSUEQ_LOG-1:0] freedEntry1;
wire freedValid1;
wire [`SIZE_ISSUEQ_LOG-1:0] freedEntry2;
wire freedValid2;

wire [`SIZE_PHYSICAL_LOG-1:0] rsr0Tag;
wire rsr0TagValid;
wire [`SIZE_PHYSICAL_LOG-1:0] rsr1Tag;
wire rsr1TagValid;
wire [`SIZE_PHYSICAL_LOG-1:0] rsr2Tag;
wire rsr2TagValid;

wire [`SIZE_PHYSICAL_LOG:0] rsr0Delayed1Tag;
wire [`SIZE_PHYSICAL_LOG:0] rsr1Delayed1Tag;
wire [`SIZE_PHYSICAL_LOG:0] rsr2Delayed1Tag;
wire [`SIZE_PHYSICAL_LOG:0] rsr0Delayed2Tag;
wire [`SIZE_PHYSICAL_LOG:0] rsr1Delayed2Tag;
wire [`SIZE_PHYSICAL_LOG:0] rsr2Delayed2Tag;
// wires from regread_execute module 
wire [`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+
      `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:0] fuPacket0_l1;
wire fuPacketValid0_l1;
wire [`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+
      `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:0] fuPacket1_l1;
wire fuPacketValid1_l1;
wire [`SIZE_PC+`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+
      `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+
      `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] fuPacket2_l1;
wire fuPacketValid2_l1;
wire [`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+
      `SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:0] fuPacket3_l1;
wire fuPacketValid3_l1;

// wires from execute module
wire [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket0;
wire exePacketValid0;
wire [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket1;
wire exePacketValid1;
wire [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket2;
wire exePacketValid2;
wire [`CHECKPOINTS+`LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
      `SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket3;
wire exePacketValid3;

// wire from writeback module
wire flagRecoverEX;
wire ctrlConditional;
wire ctrlVerified;
wire [1:0] ctrlVerifiedSMTid;
wire [`SIZE_PC-1:0] ctrlTargetAddr;
wire ctrlBrDirection;
wire [`SIZE_CTI_LOG-1:0] ctrlCtiQueueIndex;

wire [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket0;
wire [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket1;
wire [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket2;
wire [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket3;

wire bypassValid0;
wire bypassValid1;
wire bypassValid2;
wire bypassValid3;

wire [`SIZE_ISSUEQ_LOG-1:0] agenIqEntry0;
wire agenIqFreedValid0;

wire writebkValid0;
wire writebkValid1;
wire writebkValid2;
wire writebkValid3;

wire [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU0;
wire [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU1;
wire [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU2;
wire [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU3;

wire [`SIZE_PC-1:0] computedAddr0;
wire [`SIZE_PC-1:0] computedAddr1;
wire [`SIZE_PC-1:0] computedAddr2;
wire [`SIZE_PC-1:0] computedAddr3;

wire agenPacketValid0;
wire [`LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
      `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] agenPacket0;

// wire from Load-Store Unit
wire [`SIZE_LSQ_LOG-1:0] lsqId0;
wire [`SIZE_LSQ_LOG-1:0] lsqId1;
wire [`SIZE_LSQ_LOG-1:0] lsqId2;
wire [`SIZE_LSQ_LOG-1:0] lsqId3;
wire [`SIZE_LSQ_LOG:0]   loadQueueCnt;
wire [`SIZE_LSQ_LOG:0]   storeQueueCnt;
wire lsuPacketValid0;
wire [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:0] lsuPacket0;
wire [`SIZE_ACTIVELIST_LOG:0] ldViolationPacket_l1;
wire [`SIZE_ACTIVELIST_LOG:0] ldViolationPacket_l2;


// wires from activeList module
wire [`SIZE_ACTIVELIST_LOG-1:0] activeListId0;
wire [`SIZE_ACTIVELIST_LOG-1:0] activeListId1;
wire [`SIZE_ACTIVELIST_LOG-1:0] activeListId2;
wire [`SIZE_ACTIVELIST_LOG-1:0] activeListId3;
wire [`SIZE_ACTIVELIST_LOG:0] activeListCnt;
wire [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] commitPacket0;
wire commitStore0;
wire commitLoad0;
wire commitValid0;

wire commitValid0_l1;
wire [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] commitPacket0_l1;
wire commitStore0_l1;
wire commitLoad0_l1;

wire [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] commitPacket1;
wire commitStore1;
wire commitLoad1;
wire commitValid1;

wire commitValid1_l1;
wire [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] commitPacket1_l1;
wire commitStore1_l1;
wire commitLoad1_l1;

wire [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] commitPacket2;
wire commitStore2;
wire commitLoad2;
wire commitValid2;

wire commitValid2_l1;
wire [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] commitPacket2_l1;
wire commitStore2_l1;
wire commitLoad2_l1;

wire [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] commitPacket3;
wire commitStore3;
wire commitLoad3;
wire commitValid3;

wire commitValid3_l1;
wire [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] commitPacket3_l1;
wire commitStore3_l1;
wire commitLoad3_l1;

wire [`RETIRE_WIDTH-1:0] commitCti;
wire recoverFlag;
wire [`SIZE_PC-1:0] recoverPC;
wire exceptionFlag;
wire [`SIZE_PC-1:0] exceptionPC;


// wires from amt module
wire releasedValid0;
wire [`SIZE_PHYSICAL_LOG-1:0] releasedPhyMap0;
wire releasedValid1;
wire [`SIZE_PHYSICAL_LOG-1:0] releasedPhyMap1;
wire releasedValid2;
wire [`SIZE_PHYSICAL_LOG-1:0] releasedPhyMap2;
wire releasedValid3;
wire [`SIZE_PHYSICAL_LOG-1:0] releasedPhyMap3;
wire [`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:0] recoverPacket0;
wire [`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:0] recoverPacket1;
wire [`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:0] recoverPacket2;
wire [`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:0] recoverPacket3;

 /********************************************************************************** 
 *  "interface" module provides interface between Level-1 instruction cache 
 *  and lower level memory hierarchy. 
 **********************************************************************************/
 Interface interface(.clk(clock),
                     .reset(reset | recoverFlag),
                     .flush_i(1'b0),
                     .wrL1ICacheEnable_i(wrL1ICacheEnable_i),
                     .wrAddrL1ICache_i(wrAddrL1ICache_i),
                     .wrBlockL1ICache_i(wrBlockL1ICache_i),
                     .missL1ICache_i(missL1ICache),
                     .missAddrL1ICache_i(missAddrL1ICache),
                     .wrL1ICacheEnable_o(wrL1ICacheEnable_l1),
                     .wrAddrL1ICache_o(wrAddrL1ICache_l1),
                     .wrBlockL1ICache_o(wrBlockL1ICache_l1),
                     .missL1ICache_o(missL1ICache_o),
                     .missAddrL1ICache_o(missAddrL1ICache_o)
		    );	


 /********************************************************************************** 
 *  "fetch1" module is the first stage of the instruction fetching process. This
 *  module contains L1 Insturction Cache, Branch Target Buffer, Branch Prediction
 *  Buffer and Return Address Stack structures. 
 **********************************************************************************/
 FetchStage1 fs1( .flush_i(flagRecoverEX),
                  .stall_i(instBufferFull | ctiQueueFull),
                  .clk(clock),
                  .reset(reset),
		  .recoverFlag_i(recoverFlag),	
		  .recoverPC_i(recoverPC),
		  .exceptionFlag_i(exceptionFlag),
                  .exceptionPC_i(exceptionPC),

                  .flagRecoverID_i(flagRecoverID),
                  .flagCallID_i(flagCallID),
                  .callPCID_i(callPCID),
                  .flagRtrID_i(flagRtrID),
                  .targetAddrID_i(targetAddrID),

                  .flagRecoverEX_i(flagRecoverEX),
                  .targetAddrEX_i(ctrlTargetAddr),

                  .updatePC_i(updatePC_l1),
                  .updateTargetAddr_i(updateTargetAddr_l1),
                  .updateBrType_i(updateCtrlType_l1),
                  .updateDir_i(updateDir_l1),
                  .updateEn_i(updateEn_l1),

                  .fs1Ready_o(fs1Ready),
                  .instructionBundle_o(instructionBundle),
                  .pc_o(pc),
		  .addrRAS_CP_o(addrRAS_CP),

		  `ifdef ICACHE
                  .startBlock_o(startBlock),   
                  .firstInst_o(firstInst),
  		  `endif
                  .btbHit0_o(btbHit0),
                  .targetAddr0_o(targetAddr0),
                  .prediction0_o(prediction0),
                  .btbHit1_o(btbHit1),
                  .targetAddr1_o(targetAddr1),
                  .prediction1_o(prediction1),
                  .btbHit2_o(btbHit2),
                  .targetAddr2_o(targetAddr2),
                  .prediction2_o(prediction2),
                  .btbHit3_o(btbHit3),
                  .targetAddr3_o(targetAddr3),
                  .prediction3_o(prediction3),

                  .wrEnable_i(wrL1ICacheEnable_l1),
                  .wrAddr_i(wrAddrL1ICache_l1),
                  .instBlock_i(wrBlockL1ICache_l1),
                  .miss_o(missL1ICache),
                  .missAddr_o(missAddrL1ICache)
                );
 


 /********************************************************************************** 
 *  "fs1fs2" module is the pipeline stage between Fetch Stage-1 and Fetch
 *  Stage-2.
 **********************************************************************************/
 Fetch1Fetch2 fs1fs2( .clk(clock),
                      .reset(reset | recoverFlag | exceptionFlag),
                      .flush_i(flagRecoverID | flagRecoverEX),
                      .stall_i(instBufferFull | ctiQueueFull),
                      .fs1Ready_i(fs1Ready),
                      .pc_i(pc),
                      .instructionBundle_i(instructionBundle),
                      .btbHit0_i(btbHit0),
                      .targetAddr0_i(targetAddr0),
                      .prediction0_i(prediction0),
                      .btbHit1_i(btbHit1),
                      .targetAddr1_i(targetAddr1),
                      .prediction1_i(prediction1),
                      .btbHit2_i(btbHit2),
                      .targetAddr2_i(targetAddr2),
                      .prediction2_i(prediction2),
                      .btbHit3_i(btbHit3),
                      .targetAddr3_i(targetAddr3),
                      .prediction3_i(prediction3),

		      `ifdef ICACHE
                      .startBlock_i(startBlock),
                      .firstInst_i(firstInst),
                      .startBlock_o(startBlock_l1),
                      .firstInst_o(firstInst_l1),
		      `endif
                      .fs1Ready_o(fs1Ready_l1),
                      .pc_o(pc_l1),
                      .instructionBundle_o(instructionBundle_l1),
                      .btbHit0_o(btbHit0_l1),
                      .targetAddr0_o(targetAddr0_l1),
                      .prediction0_o(prediction0_l1),
                      .btbHit1_o(btbHit1_l1),
                      .targetAddr1_o(targetAddr1_l1),
                      .prediction1_o(prediction1_l1),
                      .btbHit2_o(btbHit2_l1),
                      .targetAddr2_o(targetAddr2_l1),
                      .prediction2_o(prediction2_l1),
                      .btbHit3_o(btbHit3_l1),
                      .targetAddr3_o(targetAddr3_l1),
                      .prediction3_o(prediction3_l1)

                   );



 /********************************************************************************** 
 *  "fetch2" module is the second stage of the instruction fetching process. This
 *  module contains small decode logic for control instructions and verifies the 
 *  target address provided by BTB or RAS in "fetch1". 
 *
 *  The module also contains CTI Queue structure, which keeps tracks of number of
 *  branch instructions in the processor.
 **********************************************************************************/ 
 FetchStage2 fs2(     .clk(clock),
                      .reset(reset | exceptionFlag),
		      .recoverFlag_i(recoverFlag),	
                      .stall_i(instBufferFull),
                      .flush_i(flagRecoverEX),

                      .fs1Ready_i(fs1Ready_l1),
                      .instructionBundle_i(instructionBundle_l1),
                      .pc_i(pc_l1),
		      .addrRAS_CP_i(addrRAS_CP),	

                      `ifdef ICACHE
                      .startBlock_i(startBlock_l1),
                      .firstInst_i(firstInst_l1),
		      `endif	
                      .btbHit0_i(btbHit0_l1),
                      .targetAddr0_i(targetAddr0_l1),
                      .prediction0_i(prediction0_l1),
                      .btbHit1_i(btbHit1_l1),
                      .targetAddr1_i(targetAddr1_l1),
                      .prediction1_i(prediction1_l1),
                      .btbHit2_i(btbHit2_l1),
                      .targetAddr2_i(targetAddr2_l1),
                      .prediction2_i(prediction2_l1),
                      .btbHit3_i(btbHit3_l1),
                      .targetAddr3_i(targetAddr3_l1),
                      .prediction3_i(prediction3_l1),

                      .ctiQueueIndex_i(ctrlCtiQueueIndex),
                      .targetAddr_i(ctrlTargetAddr),
                      .branchOutcome_i(ctrlBrDirection),
                      .flagRecoverEX_i(flagRecoverEX),
                      .ctrlVerified_i(ctrlVerified),

		      .commitCti_i(commitCti),	

                      .flagRecoverID_o(flagRecoverID),
                      .targetAddrID_o(targetAddrID),
                      .flagRtrID_o(flagRtrID),
                      .flagCallID_o(flagCallID),
                      .callPCID_o(callPCID),

                      .updatePC_o(updatePC),
                      .updateTargetAddr_o(updateTargetAddr),
                      .updateCtrlType_o(updateCtrlType),
                      .updateDir_o(updateDir),
                      .updateEn_o(updateEn),
                      .instruction0Valid_o(instruction0Valid),
                      .inst0Packet_o(inst0Packet),
                      .instruction1Valid_o(instruction1Valid),
                      .inst1Packet_o(inst1Packet),
                      .instruction2Valid_o(instruction2Valid),
                      .inst2Packet_o(inst2Packet),
                      .instruction3Valid_o(instruction3Valid),
                      .inst3Packet_o(inst3Packet),

                      .fs2Ready_o(fs2Ready),
                      .ctiQueueFull_o(ctiQueueFull) 
		   );



 /********************************************************************************** 
 * "fs2fs3" module is the pipeline stage between Fetch Stage-2 and decode stage.
 **********************************************************************************/
 Fetch2Decode fs2dec( .clk(clock),
                      .reset(reset),
                      .flush_i(flagRecoverEX | recoverFlag | exceptionFlag),
                      .stall_i(instBufferFull),
                      .updatePC_i(updatePC),
                      .updateTargetAddr_i(updateTargetAddr),
                      .updateCtrlType_i(updateCtrlType),
                      .updateDir_i(updateDir),
                      .updateEn_i(updateEn),

                      .fs2Ready_i(fs2Ready),
                      .instruction0Valid_i(instruction0Valid),
                      .inst0Packet_i(inst0Packet),

                      .instruction1Valid_i(instruction1Valid),
                      .inst1Packet_i(inst1Packet),

                      .instruction2Valid_i(instruction2Valid),
                      .inst2Packet_i(inst2Packet),

                      .instruction3Valid_i(instruction3Valid),
                      .inst3Packet_i(inst3Packet),


                      .updatePC_o(updatePC_l1),
                      .updateTargetAddr_o(updateTargetAddr_l1),
                      .updateCtrlType_o(updateCtrlType_l1),
                      .updateDir_o(updateDir_l1),
                      .updateEn_o(updateEn_l1),

                      .fs2Ready_o(fs2Ready_l1),
                      .instruction0Valid_o(instruction0Valid_l1),
                      .inst0Packet_o(inst0Packet_l1),
                      .instruction1Valid_o(instruction1Valid_l1),
                      .inst1Packet_o(inst1Packet_l1),
                      .instruction2Valid_o(instruction2Valid_l1),
                      .inst2Packet_o(inst2Packet_l1),
                      .instruction3Valid_o(instruction3Valid_l1),
                      .inst3Packet_o(inst3Packet_l1)

		    );



 /********************************************************************************** 
 * "decode" module decodes the incoming instruction and generate appropriate 
 * signals required by the rest of the pipeline stages. 
 **********************************************************************************/ 
 Decode decode
		( .reset(reset | recoverFlag | exceptionFlag),
                  .clk(clock),
                  .fs2Ready_i(fs2Ready_l1),
                  .inst0PacketValid_i(instruction0Valid_l1),
                  .inst0Packet_i(inst0Packet_l1),
                  .inst1PacketValid_i(instruction1Valid_l1),
                  .inst1Packet_i(inst1Packet_l1),
                  .inst2PacketValid_i(instruction2Valid_l1),
                  .inst2Packet_i(inst2Packet_l1),
                  .inst3PacketValid_i(instruction3Valid_l1),
                  .inst3Packet_i(inst3Packet_l1),

                  .decodeReady_o(decodeReady),
                  .decodedVector_o(decodedVector),
                  .decodedPacket0_o(decodedPacket0),
                  .decodedPacket1_o(decodedPacket1),
                  .decodedPacket2_o(decodedPacket2),
                  .decodedPacket3_o(decodedPacket3),
                  .decodedPacket4_o(decodedPacket4),
                  .decodedPacket5_o(decodedPacket5),
                  .decodedPacket6_o(decodedPacket6),
                  .decodedPacket7_o(decodedPacket7)
	        );	
 /**********************************************************************************
 *  "InstructionBuffer" module decouples instruction fetching process and the rest 
 *   of the pipeline stages.
 *  
 *  This module contains Instruction Queue structure, which can accept variable 
 *  number of instructions but always 4 instructions can be read from instruction
 *  buffer.
 **********************************************************************************/ 
 InstructionBuffer instBuf
			 ( .clk(clock),
                           .reset(reset | recoverFlag | exceptionFlag),
                           .flush_i(flagRecoverEX),
                           .stall_i(freeListEmpty | stallfrontEnd),
                           .decodeReady_i(decodeReady),
                           .decodedVector_i(decodedVector),
                           .decodedPacket0_i(decodedPacket0),
                           .decodedPacket1_i(decodedPacket1),
                           .decodedPacket2_i(decodedPacket2),
                           .decodedPacket3_i(decodedPacket3),
                           .decodedPacket4_i(decodedPacket4),
                           .decodedPacket5_i(decodedPacket5),
                           .decodedPacket6_i(decodedPacket6),
                           .decodedPacket7_i(decodedPacket7),

                           .stallFetch_o(instBufferFull),
                           .instBufferReady_o(instBufferReady),
                           .decodedPacket0_o(decodedPacket0_l1),
                           .decodedPacket1_o(decodedPacket1_l1),
                           .decodedPacket2_o(decodedPacket2_l1),
                           .decodedPacket3_o(decodedPacket3_l1),
                           .branchCount_o(branchCount)
			 );


 /********************************************************************************** 
 *  "InstBufRename" module is the pipeline stage between Instruction buffer and 
 *  Rename Stage.
 **********************************************************************************/
 InstBufRename instBufRen
			( .reset(reset | recoverFlag | exceptionFlag),
                     	  .clk(clock),
                     	  .flush_i(flagRecoverEX), 
                     	  .stall_i(freeListEmpty | stallfrontEnd),
                     	  .instBufferReady_i(instBufferReady),
                     	  .decodedPacket0_i(decodedPacket0_l1),
                     	  .decodedPacket1_i(decodedPacket1_l1),
                     	  .decodedPacket2_i(decodedPacket2_l1),
                     	  .decodedPacket3_i(decodedPacket3_l1),

                     	  .branchCount_i(branchCount),
                     	  .instBufferReady_o(instBufferReady_l1),
                     	  .decodedPacket0_o(decodedPacket0_l2),
                     	  .decodedPacket1_o(decodedPacket1_l2),
                     	  .decodedPacket2_o(decodedPacket2_l2),
                     	  .decodedPacket3_o(decodedPacket3_l2),
                    	  .branchCount_o(branchCount_l1)
                   	);


 /********************************************************************************** 
 *  "rename" module remaps logical source and destination registers to physical
 *  source and destination registers. 
 *  This module contains Rename Map Table and Speculative Free List structures.
 **********************************************************************************/
 Rename rename
			( .clk(clock),
                	  .reset(reset | exceptionFlag),
                	  .stall_i(stallfrontEnd),
                	  .flagRecoverEX_i(flagRecoverEX),
                	  .ctrlVerified_i(ctrlConditional),
                	  .ctrlVerifiedSMTid_i(ctrlVerifiedSMTid),
                	  .decodeReady_i(instBufferReady_l1),
                	  .decodedPacket0_i(decodedPacket0_l2),
                	  .decodedPacket1_i(decodedPacket1_l2),
                	  .decodedPacket2_i(decodedPacket2_l2),
                	  .decodedPacket3_i(decodedPacket3_l2),
                	  .branchCount_i(branchCount_l1),
                	  .commitValid0_i(releasedValid0),
                	  .commitReg0_i(releasedPhyMap0),
                	  .commitValid1_i(releasedValid1),
                	  .commitReg1_i(releasedPhyMap1),
                	  .commitValid2_i(releasedValid2),
                	  .commitReg2_i(releasedPhyMap2),
                	  .commitValid3_i(releasedValid3),
                	  .commitReg3_i(releasedPhyMap3),
                	  .recoverFlag_i(recoverFlag),
                	  .recoverDest0_i(recoverPacket0[`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG]),
                	  .recoverDest1_i(recoverPacket1[`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG]),
                	  .recoverDest2_i(recoverPacket2[`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG]),
                	  .recoverDest3_i(recoverPacket3[`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG]),
                	  .recoverMap0_i(recoverPacket0[`SIZE_PHYSICAL_LOG-1:0]),
                	  .recoverMap1_i(recoverPacket1[`SIZE_PHYSICAL_LOG-1:0]),
                	  .recoverMap2_i(recoverPacket2[`SIZE_PHYSICAL_LOG-1:0]),
                	  .recoverMap3_i(recoverPacket3[`SIZE_PHYSICAL_LOG-1:0]),

                	  .renamedPacket0_o(renamedPacket0),
                	  .renamedPacket1_o(renamedPacket1),
                	  .renamedPacket2_o(renamedPacket2),
                	  .renamedPacket3_o(renamedPacket3),
                	  .noFreeSMT_o(noFreeSMT),
                	  .freeListEmpty_o(freeListEmpty),
                 	  .renameReady_o(renameReady)
             		);


/********************************************************************************* 
* "renDis" module is the pipeline stage between Rename and Dispatch Stage.
* 
**********************************************************************************/
 RenameDispatch renDis
			( .clk(clock),
                          .reset(reset | recoverFlag | exceptionFlag),
                          .flush_i(flagRecoverEX),               
                          .stall_i(stallfrontEnd),
			  .ctrlVerified_i(ctrlConditional),

                          .renameReady_i(renameReady),   
                          .renamedPacket0_i(renamedPacket0),
                          .renamedPacket1_i(renamedPacket1),
                          .renamedPacket2_i(renamedPacket2),
                          .renamedPacket3_i(renamedPacket3),

                          .updatedBranchMask0_i(updatedBranchMask0_l1),
                          .updatedBranchMask1_i(updatedBranchMask1_l1),
                          .updatedBranchMask2_i(updatedBranchMask2_l1),
                          .updatedBranchMask3_i(updatedBranchMask3_l1),

                          .renamedPacket0_o(renamedPacket0_l1),
                          .renamedPacket1_o(renamedPacket1_l1),
                          .renamedPacket2_o(renamedPacket2_l1),
                          .renamedPacket3_o(renamedPacket3_l1),
                          .renameReady_o(renameReady_l1)                
                       	);
 


/***********************************************************************************
* "dispatch" module dispatches renamed packets to Issue Queue, Active List, and 
* Load-Store queue.
* 
***********************************************************************************/                    
 Dispatch dispatch
			( .clk(clock),
                    	  .reset(reset | recoverFlag | exceptionFlag),
                    	  .stall_i(1'b0),
 		    	  .renameReady_i(renameReady_l1),

		    	  .flagRecoverEX_i(flagRecoverEX),
                    	  .ctrlVerified_i(ctrlConditional),
                    	  .ctrlVerifiedSMTid_i(ctrlVerifiedSMTid),	
                    	  .renamedPacket0_i(renamedPacket0_l1),
                    	  .renamedPacket1_i(renamedPacket1_l1),
                    	  .renamedPacket2_i(renamedPacket2_l1),
                    	  .renamedPacket3_i(renamedPacket3_l1),

		    	  .loadQueueCnt_i(loadQueueCnt),
		    	  .storeQueueCnt_i(storeQueueCnt),       
                    	  .issueQueueCnt_i(cntInstIssueQ),      
                    	  .activeListCnt_i(activeListCnt), 
                    	  .issueqPacket0_o(dispatchPacket0_iq),
                    	  .issueqPacket1_o(dispatchPacket1_iq),
                    	  .issueqPacket2_o(dispatchPacket2_iq),
                    	  .issueqPacket3_o(dispatchPacket3_iq),

                          .alPacket0_o(dispatchPacket0_al),
                          .alPacket1_o(dispatchPacket1_al),
                          .alPacket2_o(dispatchPacket2_al),
                          .alPacket3_o(dispatchPacket3_al),

                  	  .lsqPacket0_o(dispatchPacket0_lsq),	
                  	  .lsqPacket1_o(dispatchPacket1_lsq),	
                  	  .lsqPacket2_o(dispatchPacket2_lsq),	
                  	  .lsqPacket3_o(dispatchPacket3_lsq),	

                	  .updatedBranchMask0_o(updatedBranchMask0_l1),
                	  .updatedBranchMask1_o(updatedBranchMask1_l1),
                	  .updatedBranchMask2_o(updatedBranchMask2_l1),
                	  .updatedBranchMask3_o(updatedBranchMask3_l1),

                    	  .backEndReady_o(backEndReady_l1),
		    	  .stallfrontEnd_o(stallfrontEnd)    
                  	);  


/************************************************************************************
* "issueq" module implements wake-up and select logic.
*  
************************************************************************************/                    
 IssueQueue issueq
			( .clk(clock),
		    	  .reset(reset | recoverFlag | exceptionFlag),
		    	  .backEndReady_i(backEndReady_l1),

		    	  .dispatchPacket0_i(dispatchPacket0_iq),
		    	  .dispatchPacket1_i(dispatchPacket1_iq),
		    	  .dispatchPacket2_i(dispatchPacket2_iq),
		    	  .dispatchPacket3_i(dispatchPacket3_iq),

		    	  .inst0ALid_i(activeListId0),  
		    	  .inst1ALid_i(activeListId1),  
		    	  .inst2ALid_i(activeListId2),  
		    	  .inst3ALid_i(activeListId3),  

		    	  .lsqId0_i(lsqId0),          
		    	  .lsqId1_i(lsqId1),          
		    	  .lsqId2_i(lsqId2),          
		    	  .lsqId3_i(lsqId3),          

                    	  .phyRegRdy_i(phyRegRdy),  

                    //	  .rsr0Tag_i({rsr0Tag,rsr0TagValid}),
                    //	  .rsr1Tag_i({rsr1Tag,rsr1TagValid}),
                    //	  .rsr2Tag_i({rsr2Tag,rsr2TagValid}),
                    	  .rsr3Tag_i({bypassPacket3[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:
				              `SIZE_DATA+`CHECKPOINTS_LOG+1],bypassValid3}),

                    	  .ctrlMispredict_i(flagRecoverEX),			  
                    	  .ctrlVerified_i(ctrlConditional),   
                    	  .ctrlSMTid_i(ctrlVerifiedSMTid),      

						  .rsr0Tag_o(rsr0Tag),
						  .rsr0TagValid_o(rsr0TagValid),
						  .rsr1Tag_o(rsr1Tag),
						  .rsr1TagValid_o(rsr1TagValid),
						  .rsr2Tag_o(rsr2Tag),
						  .rsr2TagValid_o(rsr2TagValid),

                    	  .cntInstIssueQ_o(cntInstIssueQ),     
                  .grantedValid0_o(grantedValid0),
		    	  .grantedPacket0_o(grantedPacket0),
                  .grantedValid1_o(grantedValid1),
		    	  .grantedPacket1_o(grantedPacket1),
                  .grantedValid2_o(grantedValid2),
		    	  .grantedPacket2_o(grantedPacket2),
                  .grantedValid3_o(grantedValid3),
		    	  .grantedPacket3_o(grantedPacket3)
		 	);


/************************************************************************************
* "iq_regread" module is the pipeline stage between Issue Queue stage and physical
* register file read stage.
*  
* This module also interfaces with RSR. 
* 
************************************************************************************/
 IssueqRegRead iq_regread( .clk(clock),
                           .reset(reset | recoverFlag | exceptionFlag),
                           .grantedValid0_i(grantedValid0),
                           .grantedPacket0_i(grantedPacket0),
                           .grantedValid1_i(grantedValid1),
                           .grantedPacket1_i(grantedPacket1),
                           .grantedValid2_i(grantedValid2),
                           .grantedPacket2_i(grantedPacket2),
                           .grantedValid3_i(grantedValid3),
                           .grantedPacket3_i(grantedPacket3),

                           .grantedValid0_o(grantedValid0_l1),
                           .grantedPacket0_o(grantedPacket0_l1),
                           .grantedValid1_o(grantedValid1_l1),
                           .grantedPacket1_o(grantedPacket1_l1),
                           .grantedValid2_o(grantedValid2_l1),
                           .grantedPacket2_o(grantedPacket2_l1),
                           .grantedValid3_o(grantedValid3_l1),
                           .grantedPacket3_o(grantedPacket3_l1)
                 	);


 
/************************************************************************************
* "rsr" module is the pipeline stage between Issue Queue stage and physical
* register file read stage. This module is used to broadcast destination tag of the
* issued instruction to the dependent instructions in the issue queue. 
*  
************************************************************************************/
/* /
 assign granted0Entry = grantedPacket0_l1[`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
 assign granted0Dest  = grantedPacket0_l1[`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+
			`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
 assign granted1Entry = grantedPacket1_l1[`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
 assign granted1Dest  = grantedPacket1_l1[`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+
                        `SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
 assign granted2Entry = grantedPacket2_l1[`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
 assign granted2Dest  = grantedPacket2_l1[`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+
                        `SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];

 RSR rsr( .clk(clock),
          .reset(reset | recoverFlag | exceptionFlag),
          .validPacket0_i(grantedValid0_l1),
          .granted0Dest_i(granted0Dest),
          .granted0Entry_i(granted0Entry),
          .validPacket1_i(grantedValid1_l1),
          .granted1Dest_i(granted1Dest),
          .granted1Entry_i(granted1Entry),
          .validPacket2_i(grantedValid2_l1),
          .granted2Dest_i(granted2Dest),
          .granted2Entry_i(granted2Entry),
          .rsr0Tag_o(rsr0Tag),   
          .rsr0TagValid_o(rsr0TagValid),
          .rsr1Tag_o(rsr1Tag),
          .rsr1TagValid_o(rsr1TagValid),
          .rsr2Tag_o(rsr2Tag),
          .rsr2TagValid_o(rsr2TagValid),
          .freedEntry0_o(freedEntry0),   
          .freedEntry1_o(freedEntry1),    
          .freedEntry2_o(freedEntry2),    
          .freedValid0_o(freedValid0),   
          .freedValid1_o(freedValid1),
          .freedValid2_o(freedValid2)
        );
// */


/************************************************************************************
* reg_read module has physical register file and all the executed values are written.
* The module has also the logic to pick data from the bypassed path. 
* 
************************************************************************************/             
assign newDestMap0 = renamedPacket0[3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+
                      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:
                      2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+
                      `SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign newDestMap1 = renamedPacket1[3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+
                      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:
                      2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+
                      `SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign newDestMap2 = renamedPacket2[3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+
                      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:
                      2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+
                      `SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
assign newDestMap3 = renamedPacket3[3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+
                      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:
                      2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+
                      `SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];

 RegRead reg_read( .clk(clock),
                   .reset(reset),
		     .exceptionFlag_i(exceptionFlag),	
		     .recoverFlag_i(recoverFlag | exceptionFlag),
                   .fuPacket0_i(grantedPacket0_l1),
                   .fuPacketValid0_i(grantedValid0_l1),
                   .fuPacket1_i(grantedPacket1_l1),
                   .fuPacketValid1_i(grantedValid1_l1),
                   .fuPacket2_i(grantedPacket2_l1),
                   .fuPacketValid2_i(grantedValid2_l1),
                   .fuPacket3_i(grantedPacket3_l1),
                   .fuPacketValid3_i(grantedValid3_l1),

                   .bypassPacket0_i(bypassPacket0),
                   .bypassValid0_i(bypassValid0),
                   .bypassPacket1_i(bypassPacket1),
                   .bypassValid1_i(bypassValid1),
                   .bypassPacket2_i(bypassPacket2),
                   .bypassValid2_i(bypassValid2),
                   .bypassPacket3_i(bypassPacket3),
                   .bypassValid3_i(bypassValid3),

		   .ctrlMispredict_i(flagRecoverEX),
                   .ctrlVerified_i(ctrlConditional),
                   .ctrlSMTid_i(ctrlVerifiedSMTid),
                   .unmapDest0_i(newDestMap0),
                   .unmapDest1_i(newDestMap1),
                   .unmapDest2_i(newDestMap2),
                   .unmapDest3_i(newDestMap3),

                   .rsr0Tag_i(rsr0Tag),
                   .rsr0TagValid_i(rsr0TagValid),	
                   .rsr1Tag_i(rsr1Tag),
                   .rsr1TagValid_i(rsr1TagValid),	
                   .rsr2Tag_i(rsr2Tag),
                   .rsr2TagValid_i(rsr2TagValid),	

                   .phyRegRdy_o(phyRegRdy),
                   .fuPacket0_o(fuPacket0),
                   .fuPacketValid0_o(fuPacketValid0),
                   .fuPacket1_o(fuPacket1),
                   .fuPacketValid1_o(fuPacketValid1),
                   .fuPacket2_o(fuPacket2),
                   .fuPacketValid2_o(fuPacketValid2),
                   .fuPacket3_o(fuPacket3),
                   .fuPacketValid3_o(fuPacketValid3)
                 );
 


/************************************************************************************
* regread_execute module has the pipeline latch between register read and execute
* stage.
*
************************************************************************************/
 RegReadExecute regread_execute( .clk(clock),
                        	 .reset(reset | recoverFlag | exceptionFlag),
                             .fuPacket0_i(fuPacket0),
                        	 .fuPacketValid0_i(fuPacketValid0),
                             .fuPacket1_i(fuPacket1),
                        	 .fuPacketValid1_i(fuPacketValid1),
                             .fuPacket2_i(fuPacket2),
                        	 .fuPacketValid2_i(fuPacketValid2),
                             .fuPacket3_i(fuPacket3),
                        	 .fuPacketValid3_i(fuPacketValid3),
                        	 .fuPacket0_o(fuPacket0_l1),
                        	 .fuPacketValid0_o(fuPacketValid0_l1),
                        	 .fuPacket1_o(fuPacket1_l1),
                        	 .fuPacketValid1_o(fuPacketValid1_l1),
                        	 .fuPacket2_o(fuPacket2_l1),
                        	 .fuPacketValid2_o(fuPacketValid2_l1),
                        	 .fuPacket3_o(fuPacket3_l1),
                        	 .fuPacketValid3_o(fuPacketValid3_l1)
                      	       );




/************************************************************************************
* execute module implements all the required functional units. 
*
************************************************************************************/
 Execute execute ( .clk(clock),
                   .reset(reset | recoverFlag | exceptionFlag),
                   .fuPacket0_i(fuPacket0_l1),
                   .fuPacketValid0_i(fuPacketValid0_l1),
                   .fuPacket1_i(fuPacket1_l1),
                   .fuPacketValid1_i(fuPacketValid1_l1),
                   .fuPacket2_i(fuPacket2_l1),
                   .fuPacketValid2_i(fuPacketValid2_l1),
                   .fuPacket3_i(fuPacket3_l1),
                   .fuPacketValid3_i(fuPacketValid3_l1),
                   .bypassPacket0_i(bypassPacket0),
                   .bypassValid0_i(bypassValid0),
                   .bypassPacket1_i(bypassPacket1),
                   .bypassValid1_i(bypassValid1),
                   .bypassPacket2_i(bypassPacket2),
                   .bypassValid2_i(bypassValid2),
                   .bypassPacket3_i(bypassPacket3),
                   .bypassValid3_i(bypassValid3),
		   .ctrlVerified_i(ctrlConditional),
                   .ctrlMispredict_i(flagRecoverEX),
                   .ctrlSMTid_i(ctrlVerifiedSMTid),	
                   .exePacket0_o(exePacket0),
                   .exePacketValid0_o(exePacketValid0),
                   .exePacket1_o(exePacket1),
                   .exePacketValid1_o(exePacketValid1),
                   .exePacket2_o(exePacket2),
                   .exePacketValid2_o(exePacketValid2),
                   .exePacket3_o(exePacket3),
                   .exePacketValid3_o(exePacketValid3)
                 );


/************************************************************************************
* writebk module writes back executed instruction to Active List. The module also
* generates bypass packets and  
*
************************************************************************************/

 WriteBack writebk ( .clk(clock),
                     .reset(reset | recoverFlag | exceptionFlag),
                     .exePacket0_i(exePacket0),
                     .exePacketValid0_i(exePacketValid0),
                     .exePacket1_i(exePacket1),
                     .exePacketValid1_i(exePacketValid1),
                     .exePacket2_i(exePacket2),
                     .exePacketValid2_i(exePacketValid2),
                     .exePacket3_i(),
                     .exePacketValid3_i(1'b0),
		     .lsuPacketValid0_i(lsuPacketValid0),
		     .lsuPacket0_i(lsuPacket0),	
		     .ldViolationPacket_i(ldViolationPacket_l1),	
                     .bypassPacket0_o(bypassPacket0),
                     .bypassValid0_o(bypassValid0),
                     .bypassPacket1_o(bypassPacket1),
                     .bypassValid1_o(bypassValid1),
                     .bypassPacket2_o(bypassPacket2),
                     .bypassValid2_o(bypassValid2),
                     .bypassPacket3_o(bypassPacket3),
                     .bypassValid3_o(bypassValid3),
		     .agenIqFreedValid0_o(agenIqFreedValid0),
		     .agenIqEntry0_o(agenIqEntry0),		

                     .ctrlVerified_o(ctrlVerified),
		     .ctrlConditional_o(ctrlConditional),	
                     .ctrlMispredict_o(flagRecoverEX),
                     .ctrlSMTid_o(ctrlVerifiedSMTid),
		     .ctrlTargetAddr_o(ctrlTargetAddr),
                     .ctrlBrDirection_o(ctrlBrDirection),
                     .ctrlCtiQueueIndex_o(ctrlCtiQueueIndex),	
                     .writebkValid0_o(writebkValid0),
                     .writebkValid1_o(writebkValid1),
                     .writebkValid2_o(writebkValid2),
                     .writebkValid3_o(writebkValid3),
                     .ctrlFU0_o(ctrlFU0),
                     .ctrlFU1_o(ctrlFU1),
                     .ctrlFU2_o(ctrlFU2),
                     .ctrlFU3_o(ctrlFU3),
		     .computedAddr0_o(computedAddr0),	
		     .computedAddr1_o(computedAddr1),	
		     .computedAddr2_o(computedAddr2),	
		     .computedAddr3_o(computedAddr3),	
		     .ldViolationPacket_o(ldViolationPacket_l2)		
                   );



/************************************************************************************
* agenLsu module has the pipeline latch between Address generation unit and LSU
* stage.
*
************************************************************************************/ 
 AgenLsu agenLsu ( .clk(clock),
                   .reset(reset | recoverFlag | exceptionFlag),
		   .ctrlMispredict_i(flagRecoverEX),
                   .ctrlSMTid_i(ctrlVerifiedSMTid),
                   // .exePacket3_i(exePacket3),
                   // .exePacketValid3_i(exePacketValid3),
                   .exePacket_i(exePacket3),
                   .exePacketValid_i(exePacketValid3),
                   .agenPacketValid0_o(agenPacketValid0),
                   .agenPacket0_o(agenPacket0)
                 );



/************************************************************************************
* "lsu" module is the pipeline stage between functional unit-3 (address generator) 
*  stage and data cache. The pipeline stage contains load-store address disambiguation
*  logic.
*
*  The module interfaces with AGEN and Writeback modules.
*
************************************************************************************/
 LSU lsu ( 	.clk(clock),
		.reset(reset | recoverFlag | exceptionFlag),
		.recoverFlag_i(recoverFlag),
           	.backEndReady_i(backEndReady_l1),            

             	.ctrlVerified_i(ctrlConditional),                     
             	.ctrlMispredict_i(flagRecoverEX),                      
             	.ctrlSMTid_i(ctrlVerifiedSMTid),  

                .lsqPacket0_i(dispatchPacket0_lsq),
                .lsqPacket1_i(dispatchPacket1_lsq),
                .lsqPacket2_i(dispatchPacket2_lsq),
                .lsqPacket3_i(dispatchPacket3_lsq),

             	.commitLoad0_i(commitLoad0),                       
             	.commitStore0_i(commitStore0),                     
             	.commitLoad1_i(commitLoad1),                     
             	.commitStore1_i(commitStore1),                     
             	.commitLoad2_i(commitLoad2),                      
             	.commitStore2_i(commitStore2),                      
             	.commitLoad3_i(commitLoad3),                        
             	.commitStore3_i(commitStore3),                    

             	.agenPacketValid0_i(agenPacketValid0),
                .agenPacket0_i(agenPacket0),
             	.lsqId0_o(lsqId0),       
             	.lsqId1_o(lsqId1),       
             	.lsqId2_o(lsqId2),       
             	.lsqId3_o(lsqId3),       

             	.loadQueueCnt_o(loadQueueCnt),   
             	.storeQueueCnt_o(storeQueueCnt),  

                .lsuPacketValid0_o(lsuPacketValid0),
                .lsuPacket0_o(lsuPacket0),
		.ldViolationPacket_o(ldViolationPacket_l1)
           );



/************************************************************************************
* "activeList" module is the pipeline stage between Dispatch stage and out-of-order
*  back-end. 
*  The module interfaces with Active List, Issue Queue and Load-Store Queue.
* 
************************************************************************************/

 ActiveList activeList( .clk(clock),
                        .reset(reset),
                   	.backEndReady_i(backEndReady_l1),
                    	.alPacket0_i(dispatchPacket0_al),
                    	.alPacket1_i(dispatchPacket1_al),
                    	.alPacket2_i(dispatchPacket2_al),
                    	.alPacket3_i(dispatchPacket3_al),
                   	.validFU0_i(writebkValid0),
			.computedAddr0_i(computedAddr0),
                    	.ctrlFU0_i(ctrlFU0),
                   	.validFU1_i(writebkValid1),
			.computedAddr1_i(computedAddr1),
                    	.ctrlFU1_i(ctrlFU1),
                   	.validFU2_i(writebkValid2),
			.computedAddr2_i(computedAddr2),
                    	.ctrlFU2_i(ctrlFU2),
                   	.validFU3_i(writebkValid3),
			.computedAddr3_i(computedAddr3),
                    	.ctrlFU3_i(ctrlFU3),
			.ldViolationPacket_i(ldViolationPacket_l2),
                    	.activeListId0_o(activeListId0),
                    	.activeListId1_o(activeListId1),
                    	.activeListId2_o(activeListId2),
                    	.activeListId3_o(activeListId3),
                    	.activeListCnt_o(activeListCnt),

                   	.commitValid0_o(commitValid0),
                   	.commitPacket0_o(commitPacket0),
			.commitStore0_o(commitStore0),
			.commitLoad0_o(commitLoad0),
                   	.commitValid1_o(commitValid1),
                   	.commitPacket1_o(commitPacket1),
			.commitStore1_o(commitStore1),
			.commitLoad1_o(commitLoad1),
                   	.commitValid2_o(commitValid2),
                   	.commitPacket2_o(commitPacket2),
			.commitStore2_o(commitStore2),
			.commitLoad2_o(commitLoad2),
                   	.commitValid3_o(commitValid3),
                   	.commitPacket3_o(commitPacket3),
			.commitStore3_o(commitStore3),
			.commitLoad3_o(commitLoad3),

			.commitCti_o(commitCti),

                   	.recoverFlag_o(recoverFlag),
			.recoverPC_o(recoverPC),

			.exceptionFlag_o(exceptionFlag),
                   	.exceptionPC_o(exceptionPC)
                      );


/*
 RetirePipe retirepipe( .clk(clock),
                   	.reset(reset),

                   	.commitValid0_i(commitValid0),
                   	.commitPacket0_i(commitPacket0),
                   	.commitStore0_i(commitStore0),
                   	.commitLoad0_i(commitLoad0),

                   	.commitValid1_i(commitValid1),
                   	.commitPacket1_i(commitPacket1),
                   	.commitStore1_i(commitStore1),
                   	.commitLoad1_i(commitLoad1),

                   	.commitValid2_i(commitValid2),
                   	.commitPacket2_i(commitPacket2),
                   	.commitStore2_i(commitStore2),
                   	.commitLoad2_i(commitLoad2),

                   	.commitValid3_i(commitValid3),
                   	.commitPacket3_i(commitPacket3),
                   	.commitStore3_i(commitStore3),
                   	.commitLoad3_i(commitLoad3),

                   	.commitValid0_o(commitValid0_l1),
                   	.commitPacket0_o(commitPacket0_l1),
                   	.commitStore0_o(commitStore0_l1),
                   	.commitLoad0_o(commitLoad0_l1),

                   	.commitValid1_o(commitValid1_l1),
                    	.commitPacket1_o(commitPacket1_l1),
                   	.commitStore1_o(commitStore1_l1),
                   	.commitLoad1_o(commitLoad1_l1),

                   	.commitValid2_o(commitValid2_l1),
                  	.commitPacket2_o(commitPacket2_l1),
                   	.commitStore2_o(commitStore2_l1),
                   	.commitLoad2_o(commitLoad2_l1),

                   	.commitValid3_o(commitValid3_l1),
                   	.commitPacket3_o(commitPacket3_l1),
                   	.commitStore3_o(commitStore3_l1),
                   	.commitLoad3_o(commitLoad3_l1)
		     );	 
*/

/************************************************************************************
* "amt" module is the pipeline stage between Dispatch stage and out-of-order
*  back-end. 
*  The module interfaces with ActiveList Pipe, Issue Queue and Load-Store Queue.
* 
************************************************************************************/                     
 ArchMapTable amt( .clk(clock),
                   .reset(reset | exceptionFlag),

                   .commitValid0_i(commitValid0),
                   .commitValid1_i(commitValid1),
                   .commitValid2_i(commitValid2),
                   .commitValid3_i(commitValid3),
                   .amtPacket0_i(commitPacket0[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG]),
                   .amtPacket1_i(commitPacket1[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG]),
                   .amtPacket2_i(commitPacket2[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG]),
                   .amtPacket3_i(commitPacket3[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG]),

		   .releasedValid0_o(releasedValid0),
	  	   .releasedPhyMap0_o(releasedPhyMap0),			
		   .releasedValid1_o(releasedValid1),
	  	   .releasedPhyMap1_o(releasedPhyMap1),			
		   .releasedValid2_o(releasedValid2),
	  	   .releasedPhyMap2_o(releasedPhyMap2),			
		   .releasedValid3_o(releasedValid3),
	  	   .releasedPhyMap3_o(releasedPhyMap3),			

                   .recoverFlag_i(recoverFlag),
                   .recoverPacket0_o(recoverPacket0),
                   .recoverPacket1_o(recoverPacket1),
                   .recoverPacket2_o(recoverPacket2),
                   .recoverPacket3_o(recoverPacket3)
                 );
                      
                   

endmodule
