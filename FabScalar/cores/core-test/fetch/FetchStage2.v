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
                     input btbHit0_i,
                     input [`SIZE_PC-1:0] targetAddr0_i,
                     input prediction0_i,
		     output instruction0Valid_o,
                     output [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst0Packet_o,
                     input btbHit1_i,
                     input [`SIZE_PC-1:0] targetAddr1_i,
                     input prediction1_i,
		     output instruction1Valid_o,
                     output [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst1Packet_o,
                     input btbHit2_i,
                     input [`SIZE_PC-1:0] targetAddr2_i,
                     input prediction2_i,
		     output instruction2Valid_o,
                     output [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst2Packet_o,
                     input btbHit3_i,
                     input [`SIZE_PC-1:0] targetAddr3_i,
                     input prediction3_i,
		     output instruction3Valid_o,
                     output [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst3Packet_o,
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

wire [`SIZE_PC-1:0]                     pc0;
reg [`SIZE_INSTRUCTION-1:0]             instruction0;
wire [`SIZE_OPCODE_P-1:0]               opcode0;
wire [`BRANCH_TYPE-1:0]                 ctrlType0;
wire [`SIZE_PC-1:0]                     targetAddr0;
wire                                    isInst0Ctrl;
wire                                    isInst0Rtr;
reg [`SIZE_PC-1:0]                      targetAddr0_f;
wire [`SIZE_CTI_LOG-1:0]                ctiqTag0;
	
wire [`SIZE_PC-1:0]                     pc1;
reg [`SIZE_INSTRUCTION-1:0]             instruction1;
wire [`SIZE_OPCODE_P-1:0]               opcode1;
wire [`BRANCH_TYPE-1:0]                 ctrlType1;
wire [`SIZE_PC-1:0]                     targetAddr1;
wire                                    isInst1Ctrl;
wire                                    isInst1Rtr;
reg [`SIZE_PC-1:0]                      targetAddr1_f;
wire [`SIZE_CTI_LOG-1:0]                ctiqTag1;
	
wire [`SIZE_PC-1:0]                     pc2;
reg [`SIZE_INSTRUCTION-1:0]             instruction2;
wire [`SIZE_OPCODE_P-1:0]               opcode2;
wire [`BRANCH_TYPE-1:0]                 ctrlType2;
wire [`SIZE_PC-1:0]                     targetAddr2;
wire                                    isInst2Ctrl;
wire                                    isInst2Rtr;
reg [`SIZE_PC-1:0]                      targetAddr2_f;
wire [`SIZE_CTI_LOG-1:0]                ctiqTag2;
	
wire [`SIZE_PC-1:0]                     pc3;
reg [`SIZE_INSTRUCTION-1:0]             instruction3;
wire [`SIZE_OPCODE_P-1:0]               opcode3;
wire [`BRANCH_TYPE-1:0]                 ctrlType3;
wire [`SIZE_PC-1:0]                     targetAddr3;
wire                                    isInst3Ctrl;
wire                                    isInst3Rtr;
reg [`SIZE_PC-1:0]                      targetAddr3_f;
wire [`SIZE_CTI_LOG-1:0]                ctiqTag3;
	
CtrlQueue ctiQueue( .clk(clk),
                    .inst0CtrlType_i(ctrlType0),
                    .pc0_i(pc0),
                    .ctiqTag0_o(ctiqTag0),

                    .inst1CtrlType_i(ctrlType1),
                    .pc1_i(pc1),
                    .ctiqTag1_o(ctiqTag1),

                    .inst2CtrlType_i(ctrlType2),
                    .pc2_i(pc2),
                    .ctiqTag2_o(ctiqTag2),

                    .inst3CtrlType_i(ctrlType3),
                    .pc3_i(pc3),
                    .ctiqTag3_o(ctiqTag3),

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

assign pc0     = pc_i + 0;
assign pc1     = pc_i + 8;
assign pc2     = pc_i + 16;
assign pc3     = pc_i + 24;

always @(*)
begin
	instruction0 = instructionBundle_i[1*`SIZE_INSTRUCTION-1:0*`SIZE_INSTRUCTION];
	instruction1 = instructionBundle_i[2*`SIZE_INSTRUCTION-1:1*`SIZE_INSTRUCTION];
	instruction2 = instructionBundle_i[3*`SIZE_INSTRUCTION-1:2*`SIZE_INSTRUCTION];
	instruction3 = instructionBundle_i[4*`SIZE_INSTRUCTION-1:3*`SIZE_INSTRUCTION];
end

PreDecode_PISA preDecode0( .pc_i(pc0),
                           .instruction_i(instruction0),
                           .prediction_i(prediction0_i),
                           .targetAddr_i(targetAddr0_i),
                           .isInstCtrl_o(isInst0Ctrl),
                           .isInstRtr_o(isInst0Rtr),
                           .targetAddr_o(targetAddr0),
                           .ctrlType_o(ctrlType0)
                         );

PreDecode_PISA preDecode1( .pc_i(pc1),
                           .instruction_i(instruction1),
                           .prediction_i(prediction1_i),
                           .targetAddr_i(targetAddr1_i),
                           .isInstCtrl_o(isInst1Ctrl),
                           .isInstRtr_o(isInst1Rtr),
                           .targetAddr_o(targetAddr1),
                           .ctrlType_o(ctrlType1)
                         );

PreDecode_PISA preDecode2( .pc_i(pc2),
                           .instruction_i(instruction2),
                           .prediction_i(prediction2_i),
                           .targetAddr_i(targetAddr2_i),
                           .isInstCtrl_o(isInst2Ctrl),
                           .isInstRtr_o(isInst2Rtr),
                           .targetAddr_o(targetAddr2),
                           .ctrlType_o(ctrlType2)
                         );

PreDecode_PISA preDecode3( .pc_i(pc3),
                           .instruction_i(instruction3),
                           .prediction_i(prediction3_i),
                           .targetAddr_i(targetAddr3_i),
                           .isInstCtrl_o(isInst3Ctrl),
                           .isInstRtr_o(isInst3Rtr),
                           .targetAddr_o(targetAddr3),
                           .ctrlType_o(ctrlType3)
                         );

always @(*)
begin:VALIDATE_BTB
 reg [`FETCH_BANDWIDTH-1:0] branchNT;
 reg check0Branch;
 reg inst0Ctrl;
 reg check1Branch;
 reg inst1Ctrl;
 reg check2Branch;
 reg inst2Ctrl;
 reg check3Branch;
 reg inst3Ctrl;
 targetAddr0_f = targetAddr0;
 targetAddr1_f = targetAddr1;
 targetAddr2_f = targetAddr2;
 targetAddr3_f = targetAddr3;
 check0Branch =  ~(ctrlType0[0] & ctrlType0[1]);
 check1Branch =  ~(ctrlType1[0] & ctrlType1[1]);
 check2Branch =  ~(ctrlType2[0] & ctrlType2[1]);
 check3Branch =  ~(ctrlType3[0] & ctrlType3[1]);
 inst0Ctrl    = isInst0Ctrl & (prediction0_i | check0Branch);
 inst1Ctrl    = isInst1Ctrl & (prediction1_i | check1Branch);
 inst2Ctrl    = isInst2Ctrl & (prediction2_i | check2Branch);
 inst3Ctrl    = isInst3Ctrl & (prediction3_i | check3Branch);
 branchNT[0]  = isInst0Ctrl & ctrlType0[0] & ctrlType0[1] & ~prediction0_i;
 branchNT[1]  = isInst1Ctrl & ctrlType1[0] & ctrlType1[1] & ~prediction1_i;
 branchNT[2]  = isInst2Ctrl & ctrlType2[0] & ctrlType2[1] & ~prediction2_i;
 branchNT[3]  = isInst3Ctrl & ctrlType3[0] & ctrlType3[1] & ~prediction3_i;

 flagRecover  = 1'b0;
 flagRtr      = 1'b0;
 flagCall     = 1'b0;
 filterVector = 4'd15;
 ctrlVector   = branchNT;

 casex({inst0Ctrl, inst1Ctrl, inst2Ctrl, inst3Ctrl})
 4'b1xxx:
 begin
	targetAddr   = targetAddr0;
	callPC       = pc0;
	filterVector = 4'b1000;
	ctrlVector[3:0]= 4'b0001;
	if(~btbHit0_i)
	begin
		flagRecover = 1'b1;
		if(ctrlType0 == 2'b00)
		begin
			targetAddr0_f = addrRAS_CP_i;
			flagRtr  = 1'b1;
		end
		if(ctrlType0 == 2'b01)
			flagCall = 1'b1;
	end
 end
4'b01xx:
 begin
	targetAddr   = targetAddr1;
	callPC       = pc1;
	filterVector = 4'b1100;
	ctrlVector[3:1]= 3'b001;
	if(~btbHit1_i)
	begin
		flagRecover = 1'b1;
		if(ctrlType1 == 2'b00)
		begin
			targetAddr1_f = addrRAS_CP_i;
			flagRtr  = 1'b1;
		end
		if(ctrlType1 == 2'b01)
			flagCall = 1'b1;
	end
 end
4'b001x:
 begin
	targetAddr   = targetAddr2;
	callPC       = pc2;
	filterVector = 4'b1110;
	ctrlVector[3:2]= 2'b01;
	if(~btbHit2_i)
	begin
		flagRecover = 1'b1;
		if(ctrlType2 == 2'b00)
		begin
			targetAddr2_f = addrRAS_CP_i;
			flagRtr  = 1'b1;
		end
		if(ctrlType2 == 2'b01)
			flagCall = 1'b1;
	end
 end
4'b0001:
 begin
	targetAddr   = targetAddr3;
	callPC       = pc3;
	filterVector = 4'b1111;
	ctrlVector[3:3]= 1'b1;
	if(~btbHit3_i)
	begin
		flagRecover = 1'b1;
		if(ctrlType3 == 2'b00)
		begin
			targetAddr3_f = addrRAS_CP_i;
			flagRtr  = 1'b1;
		end
		if(ctrlType3 == 2'b01)
			flagCall = 1'b1;
	end
 end
 endcase
end
assign flagRecoverID_o = flagRecover & ~stall_i & ~ctiQueueFull;
assign flagRtrID_o     = flagRtr;
assign flagCallID_o    = flagCall;
assign targetAddrID_o  = targetAddr;
assign callPCID_o      = callPC;

assign inst0Packet_o         = {instruction0,pc0,targetAddr0_f,ctiqTag0,prediction0_i};
assign instruction0Valid_o   = filterVector[3];
assign inst1Packet_o         = {instruction1,pc1,targetAddr1_f,ctiqTag1,prediction1_i};
assign instruction1Valid_o   = filterVector[2];
assign inst2Packet_o         = {instruction2,pc2,targetAddr2_f,ctiqTag2,prediction2_i};
assign instruction2Valid_o   = filterVector[1];
assign inst3Packet_o         = {instruction3,pc3,targetAddr3_f,ctiqTag3,prediction3_i};
assign instruction3Valid_o   = filterVector[0];

assign ctiQueueFull_o = ctiQueueFull;
assign fs2Ready_o     = fs1Ready_i & ~ctiQueueFull;


endmodule

