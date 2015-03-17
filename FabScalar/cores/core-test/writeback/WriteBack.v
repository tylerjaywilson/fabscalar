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


module WriteBack (
			input exePacketValid0_i,
			input [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                          `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket0_i,
			output writebkValid0_o,
			output [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU0_o,
			output bypassValid0_o,
			output [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket0_o,
			output [`SIZE_PC-1:0] computedAddr0_o,
			input exePacketValid1_i,
			input [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                          `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket1_i,
			output writebkValid1_o,
			output [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU1_o,
			output bypassValid1_o,
			output [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket1_o,
			output [`SIZE_PC-1:0] computedAddr1_o,
			input exePacketValid2_i,
			input [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                          `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket2_i,
			output writebkValid2_o,
			output [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU2_o,
			output bypassValid2_o,
			output [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket2_o,
			output [`SIZE_PC-1:0] computedAddr2_o,
			input exePacketValid3_i,
			input [`CHECKPOINTS+`LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
			  `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket3_i,
			output writebkValid3_o,
			output [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU3_o,
			output bypassValid3_o,
			output [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket3_o,
			output [`SIZE_PC-1:0] computedAddr3_o,
			input lsuPacketValid0_i,
			input [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:0] lsuPacket0_i,
			input [`SIZE_ACTIVELIST_LOG:0] ldViolationPacket_i,
			output agenIqFreedValid0_o,
			output [`SIZE_ISSUEQ_LOG-1:0] agenIqEntry0_o,
			output ctrlVerified_o,
			output ctrlMispredict_o,
			output ctrlConditional_o,
			output [`CHECKPOINTS_LOG-1:0] ctrlSMTid_o,
			output [`SIZE_PC-1:0] ctrlTargetAddr_o,
			output ctrlBrDirection_o,
			output [`SIZE_CTI_LOG-1:0] ctrlCtiQueueIndex_o,
			output [`SIZE_ACTIVELIST_LOG:0] ldViolationPacket_o,
			input clk,
			input reset
			);
 reg [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket0;
 reg			exePacketValid0;
 wire [`EXECUTION_FLAGS-1:0]    exePacket0Flags;
 reg			invalidateFu0Packet;
 reg [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket1;
 reg			exePacketValid1;
 wire [`EXECUTION_FLAGS-1:0]    exePacket1Flags;
 reg			invalidateFu1Packet;
 reg [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket2;
 reg			exePacketValid2;
 wire [`EXECUTION_FLAGS-1:0]    exePacket2Flags;
 reg			invalidateFu2Packet;
 reg [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket3;
 reg			exePacketValid3;
 wire [`EXECUTION_FLAGS-1:0]    lsuPacket0Flags;
 reg			invalidateLsuPacket;
 reg			invalidatelsuPacket;

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
 reg	writebkValid0_l0;
 reg  [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU0_l0;
 reg  [`SIZE_PC-1:0] computedAddr0_l0;
 reg	writebkValid1_l0;
 reg  [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU1_l0;
 reg  [`SIZE_PC-1:0] computedAddr1_l0;
 reg	writebkValid2_l0;
 reg  [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU2_l0;
 reg  [`SIZE_PC-1:0] computedAddr2_l0;
 reg	writebkValid3_l0;
 reg  [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU3_l0;
 reg  [`SIZE_PC-1:0] computedAddr3_l0;
 assign writebkValid0_o 	= writebkValid0_l0;
 assign ctrlFU0_o 		= ctrlFU0_l0;
 assign bypassValid0_o 	= exePacketValid0 & exePacket0Flags[4];
 assign computedAddr0_o 		= 0;
 assign writebkValid1_o 	= writebkValid1_l0;
 assign ctrlFU1_o 		= ctrlFU1_l0;
 assign bypassValid1_o 	= exePacketValid1 & exePacket1Flags[4];
 assign computedAddr1_o 		= 0;
 assign writebkValid2_o 	= writebkValid2_l0;
 assign ctrlFU2_o 		= ctrlFU2_l0;
 assign bypassValid2_o 	= exePacketValid2 & exePacket2Flags[4];
 assign computedAddr2_o 		= computedAddr2_l0;
 assign writebkValid3_o 	= writebkValid3_l0;
 assign ctrlFU3_o 		= ctrlFU3_l0;
 assign bypassValid3_o 	= lsuPacketValid0 & lsuPacket0Flags[4];
 assign computedAddr3_o 		= 0;
assign ldViolationPacket_o  = ldViolationPacket; 
 assign bypassPacket0_o = {exePacket0[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                             `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:1+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
                             `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC],
                              exePacket0[`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+
                             `SIZE_PC:1+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC],
                              exePacket0[`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:1+`SIZE_CTI_LOG+`SIZE_PC],
                              1'b0
                             };
 assign bypassPacket1_o = {exePacket1[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                             `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:1+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
                             `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC],
                              exePacket1[`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+
                             `SIZE_PC:1+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC],
                              exePacket1[`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:1+`SIZE_CTI_LOG+`SIZE_PC],
                              1'b0
                             };
 assign bypassPacket2_o = {exePacket2[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                             `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:1+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
                             `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC],
                              exePacket2[`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+
                             `SIZE_PC:1+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC],
                              exePacket2[`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:1+`SIZE_CTI_LOG+`SIZE_PC],
                              1'b0
                             };
 assign bypassPacket3_o = {lsuPacket0[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:
                           `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG],
                           lsuPacket0[`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:
                           `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG],`CHECKPOINTS_LOG'b0,
                           1'b0
                          };
 assign agenIqFreedValid0_o  = lsuPacketValid0;
 assign agenIqEntry0_o       = lsuPacket0[`SIZE_ISSUEQ_LOG-1:0];

 assign ctrlVerified        = exePacketValid2;
 assign ctrlConditional     = exePacket2Flags[5];
 assign ctrlMispredict      = 0;
 assign ctrlSMTid           = exePacket2[`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_CTI_LOG+`SIZE_PC+1];

 assign ctrlTargetAddr      = exePacket2[`SIZE_PC:1];
 assign ctrlBrDirection     = exePacket2[0];
 assign ctrlCtiQueueIndex   = exePacket2[`SIZE_CTI_LOG+`SIZE_PC:`SIZE_PC+1];

 assign ctrlVerified_o      = ctrlVerified;
 assign ctrlConditional_o   = ctrlConditional;
 assign ctrlMispredict_o    = ctrlMispredict;
 assign ctrlSMTid_o         = ctrlSMTid;
 assign ctrlTargetAddr_o    = ctrlTargetAddr;
 assign ctrlBrDirection_o   = ctrlBrDirection;
 assign ctrlCtiQueueIndex_o = ctrlCtiQueueIndex;

always @(*)
 begin:INVALIDATE_WB_ON_MISPREDICT
reg  [`CHECKPOINTS-1:0]	fu0BranchMask;
reg  [`CHECKPOINTS-1:0]	fu1BranchMask;
reg  [`CHECKPOINTS-1:0]	fu2BranchMask;
reg  [`CHECKPOINTS-1:0]	lsuBranchMask;
 fu0BranchMask = exePacket0[`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
                  `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
                  `EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                  `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

  if(ctrlVerified && ctrlMispredict && fu0BranchMask[ctrlSMTid])
        invalidateFu0Packet = 1'b1;
  else
        invalidateFu0Packet = 1'b0;

 fu1BranchMask = exePacket1[`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
                  `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
                  `EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                  `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

  if(ctrlVerified && ctrlMispredict && fu1BranchMask[ctrlSMTid])
        invalidateFu1Packet = 1'b1;
  else
        invalidateFu1Packet = 1'b0;

 fu2BranchMask = exePacket2[`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
                  `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
                  `EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                  `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

  if(ctrlVerified && ctrlMispredict && fu2BranchMask[ctrlSMTid])
        invalidateFu2Packet = 1'b1;
  else
        invalidateFu2Packet = 1'b0;

  lsuBranchMask = lsuPacket0[`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:
                  `EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG];

  if(ctrlVerified && ctrlMispredict && lsuBranchMask[ctrlSMTid])
        invalidateLsuPacket = 1'b1;
  else
        invalidateLsuPacket = 1'b0;
end


 always @(*)
 begin
 writebkValid0_l0 = exePacketValid0 & ~invalidateFu0Packet; 
 writebkValid1_l0 = exePacketValid1 & ~invalidateFu1Packet; 
 writebkValid2_l0 = exePacketValid2 & ~invalidateFu2Packet; 
 writebkValid3_l0 = lsuPacketValid0 & ~invalidateLsuPacket; 

 end

 always @(*)
 begin
 ctrlFU0_l0 =  {exePacket0[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                        `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                        `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1],
                         exePacket0Flags[`WRITEBACK_FLAGS-1:0]
                         }; 
 ctrlFU1_l0 =  {exePacket1[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                        `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                        `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1],
                         exePacket1Flags[`WRITEBACK_FLAGS-1:0]
                         }; 
 ctrlFU2_l0 =  {exePacket2[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                        `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                        `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1],
                         exePacket2Flags[`WRITEBACK_FLAGS-1:0]
                         }; 
 ctrlFU3_l0 =  {lsuPacket0[`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:`SIZE_ISSUEQ_LOG],
                           lsuPacket0Flags[`WRITEBACK_FLAGS-1:0]
                          }; 
 end

 always @(*)
 begin
 computedAddr2_l0 =  ctrlTargetAddr; 
 end
assign exePacket0Flags =  exePacket0[`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
                         `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
                         `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                         `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

assign exePacket1Flags =  exePacket1[`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
                         `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
                         `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                         `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

assign exePacket2Flags =  exePacket2[`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
                         `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
                         `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                         `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

assign lsuPacket0Flags = lsuPacket0[`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
                         `SIZE_ISSUEQ_LOG-1:`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG];

always @(posedge clk)
begin
 if(reset)
 begin
	exePacket0	<= 0;
	exePacketValid0	<= 0;
	exePacket1	<= 0;
	exePacketValid1	<= 0;
	exePacket2	<= 0;
	exePacketValid2	<= 0;
	lsuPacket0	<= 0;
	lsuPacketValid0	<= 0;
	end
	else
	begin
	exePacketValid0 <= exePacketValid0_i;
	if(exePacketValid0_i)
		exePacket0  <= exePacket0_i;
	`ifdef VERIFY
	else
		exePacket0  <= 0;
	`endif
	exePacketValid1 <= exePacketValid1_i;
	if(exePacketValid1_i)
		exePacket1  <= exePacket1_i;
	`ifdef VERIFY
	else
		exePacket1  <= 0;
	`endif
	exePacketValid2 <= exePacketValid2_i;
	if(exePacketValid2_i)
		exePacket2  <= exePacket2_i;
	`ifdef VERIFY
	else
		exePacket2  <= 0;
	`endif
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

	end
 end

endmodule

