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

/* Algorithm
   1. Bypassed data should contain at least following information:
       (.) Destination Register
       (.) Output Data
       (.) Shadow Map Table ID
       (.) Control Mispredict	
 **************************************************************************/



module WriteBack ( input clk,
		   input reset,

				   input [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                          `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket0_i,
                   input exePacketValid0_i,
                   input [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                          `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket1_i,
                   input exePacketValid1_i,
                   input [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                          `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket2_i,
                   input exePacketValid2_i,
                   input [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                          `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket3_i,
                   input exePacketValid3_i,
                   input [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                          `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket4_i,
                   input exePacketValid4_i,
                   input [`CHECKPOINTS+`LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
			  `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket5_i,
                   input exePacketValid5_i,

		   input lsuPacketValid0_i,	
		   input [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:0] lsuPacket0_i, 
		   input [`SIZE_ACTIVELIST_LOG:0] ldViolationPacket_i,	

		   output [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket0_o,
                   output bypassValid0_o,
                   output [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket1_o,
                   output bypassValid1_o,
                   output [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket2_o,
                   output bypassValid2_o,
                   output [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket3_o,
                   output bypassValid3_o,	
                   output [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket4_o,
                   output bypassValid4_o,	
                   output [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket5_o,
                   output bypassValid5_o,	

		   output agenIqFreedValid0_o,
                   output [`SIZE_ISSUEQ_LOG-1:0] agenIqEntry0_o,

		   output ctrlVerified_o,
                   output ctrlMispredict_o,
		   output ctrlConditional_o,
                   output [`CHECKPOINTS_LOG-1:0] ctrlSMTid_o,
		   output [`SIZE_PC-1:0] ctrlTargetAddr_o,
 		   output ctrlBrDirection_o,
 		   output [`SIZE_CTI_LOG-1:0] ctrlCtiQueueIndex_o,	

		   output writebkValid0_o,	
		   output writebkValid1_o,	
		   output writebkValid2_o,	
		   output writebkValid3_o,	
		   output writebkValid4_o,	
		   output writebkValid5_o,	
		   output [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU0_o,
		   output [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU1_o,
		   output [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU2_o,
		   output [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU3_o,
		   output [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU4_o,
		   output [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU5_o,

		   output [`SIZE_ACTIVELIST_LOG:0] ldViolationPacket_o
 		 );


 /*  Follwoing defines the pipeline registers for the Writeback.
  */
 reg [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] 
				exePacket0;
 reg 				exePacketValid0;
 reg [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] 
				exePacket1;
 reg 				exePacketValid1;
 reg [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] 
				exePacket2;
 reg 				exePacketValid2;
 reg [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] 
				exePacket3;
 reg 				exePacketValid3;
 reg [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] 
				exePacket4;
 reg 				exePacketValid4;
 reg [`CHECKPOINTS+`LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
      `SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] 
				exePacket5;
 reg 				exePacketValid5;
 

 reg 				lsuPacketValid0;
 reg [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:0] 
				lsuPacket0;
 reg [`SIZE_ACTIVELIST_LOG:0] 	ldViolationPacket;


 /* wires and regs definition for combinational logic. */
 reg 				invalidateFu0Packet;
 reg 				invalidateFu1Packet;
 reg 				invalidateFu2Packet;
 reg 				invalidateFu3Packet;
 reg 				invalidateFu4Packet;
 reg 				invalidateLsuPacket;

 wire [`EXECUTION_FLAGS-1:0]	exePacket0Flags;
 wire [`EXECUTION_FLAGS-1:0]	exePacket1Flags;
 wire [`EXECUTION_FLAGS-1:0]	exePacket2Flags;
 wire [`EXECUTION_FLAGS-1:0]	exePacket3Flags;
 wire [`EXECUTION_FLAGS-1:0]	exePacket4Flags;
 wire [`EXECUTION_FLAGS-1:0]	lsuPacket0Flags;

 wire				ctrlVerified;
 wire 				ctrlMispredict;
 wire 				ctrlConditional;
 wire [`CHECKPOINTS_LOG-1:0] 	ctrlSMTid;
 wire [`SIZE_PC-1:0] 		ctrlTargetAddr;
 wire 				ctrlBrDirection;
 wire [`SIZE_CTI_LOG-1:0] 	ctrlCtiQueueIndex;

 reg [`CHECKPOINTS-1:0]         fu0BranchMask;	
  reg [`CHECKPOINTS-1:0]         lsuBranchMask;	

/*  Follwoing registers have been defined for functional verification purpose.
 *  Please see below for more details about these registers.
 */
/*`ifdef VERIFY
 reg                            wb_inst0BrDir, 	  wb_inst1BrDir,   wb_inst2BrDir,   wb_inst3BrDir;
 reg [`SIZE_CTI_LOG-1:0]        wb_inst0CtiqTag,  wb_inst1CtiqTag, wb_inst2CtiqTag, wb_inst3CtiqTag;
 reg [`SIZE_PC-1:0]             wb_inst0TarAddr,  wb_inst1TarAddr, wb_inst2TarAddr, wb_inst3TarAddr;
 reg [`SIZE_PHYSICAL_LOG-1:0]   wb_inst0DestReg,  wb_inst1DestReg, wb_inst2DestReg, wb_inst3DestReg;
 reg [`CHECKPOINTS_LOG-1:0]     wb_inst0SMTid,    wb_inst1SMTid,   wb_inst2SMTid,   wb_inst3SMTid;
 reg [`SIZE_ISSUEQ_LOG-1:0]     wb_inst0IQentry,  wb_inst1IQentry, wb_inst2IQentry, wb_inst3IQentry;
 reg [`SIZE_ACTIVELIST_LOG-1:0] wb_inst0ALid,     wb_inst1ALid,    wb_inst2ALid,    wb_inst3ALid;
 reg [`SIZE_DATA-1:0]           wb_inst0Data,     wb_inst1Data,    wb_inst2Data,    wb_inst3Data;
 reg [`LDST_TYPES_LOG-1:0]      wb_inst3ldstSize;
 reg				wb_inst2ConditionalCtrl;
`endif
*/


 /*  Following generates the bypass valid and bypass packet. Bypass packet contains functional
  *  unit result output, the physical destination register and shawdow map id (in case of a 
  *  control FU). It may also contain the mis-predict signal at the 0th bit.
  */
 assign bypassValid0_o = exePacketValid0 & exePacket0Flags[4];
 assign bypassValid1_o = exePacketValid1 & exePacket1Flags[4];
 assign bypassValid2_o = exePacketValid2 & exePacket2Flags[4];
 assign bypassValid3_o = exePacketValid3 & exePacket3Flags[4];
 assign bypassValid4_o = exePacketValid4 & exePacket4Flags[4];

 assign bypassValid5_o = lsuPacketValid0 & lsuPacket0Flags[4];
 
 
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

 assign bypassPacket3_o = {exePacket3[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                           `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:1+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
                           `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC],
                           exePacket3[`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+
                           `SIZE_PC:1+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC],
                           exePacket3[`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:1+`SIZE_CTI_LOG+`SIZE_PC],
                           1'b0
                          };

 assign bypassPacket4_o = {exePacket4[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                           `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:1+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
                           `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC],
                           exePacket4[`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+
                           `SIZE_PC:1+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC],
                           exePacket4[`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:1+`SIZE_CTI_LOG+`SIZE_PC],
                           1'b0
                          };


 assign bypassPacket5_o = {lsuPacket0[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:
			   `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG],
			   lsuPacket0[`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:
			   `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG],`CHECKPOINTS_LOG'b0,
			   1'b0	
			  };

 assign agenIqFreedValid0_o  = lsuPacketValid0;
 assign agenIqEntry0_o       = lsuPacket0[`SIZE_ISSUEQ_LOG-1:0];



 /*  Following generates control path signals related to an executed control instruction. Signals are
  *  	control verified, 
  *  	control mispredict, 
  *	control shadow map id, 
  *	computed target address, 
  *   	branch direction, 
  *	cti queue index  
  */
 
 assign ctrlVerified        = exePacketValid4;
 assign ctrlConditional	    = exePacket4Flags[5];
 assign ctrlMispredict      = exePacket4Flags[0];
 assign ctrlSMTid           = exePacket4[`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_CTI_LOG+`SIZE_PC+1];

 assign ctrlTargetAddr      = exePacket4[`SIZE_PC:1];
 assign ctrlBrDirection     = exePacket4[0];
 assign ctrlCtiQueueIndex   = exePacket4[`SIZE_CTI_LOG+`SIZE_PC:`SIZE_PC+1];

 assign ctrlVerified_o	    = ctrlVerified;
 assign ctrlConditional_o   = ctrlConditional;
 assign ctrlMispredict_o    = ctrlMispredict;
 assign ctrlSMTid_o         = ctrlSMTid;
 assign ctrlTargetAddr_o    = ctrlTargetAddr;
 assign ctrlBrDirection_o   = ctrlBrDirection;
 assign ctrlCtiQueueIndex_o = ctrlCtiQueueIndex;	

 
/*  Following generates data corresponding to Active List. For every executed instruction ActiveList
 *  is updated with the completed, exception and mis-predict bits.
 */
always @(*)
 begin:INVALIDATE_WB_ON_MISPREDICT
  reg [`CHECKPOINTS-1:0]         fu1BranchMask;	
  reg [`CHECKPOINTS-1:0]         fu2BranchMask;	
  reg [`CHECKPOINTS-1:0]         fu3BranchMask;	
  reg [`CHECKPOINTS-1:0]         fu4BranchMask;	

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


  fu3BranchMask = exePacket3[`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      		  `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
		  `EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
		  `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

  if(ctrlVerified && ctrlMispredict && fu3BranchMask[ctrlSMTid])
        invalidateFu3Packet = 1'b1;
  else
        invalidateFu3Packet = 1'b0;

  fu4BranchMask = exePacket4[`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      		  `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
		  `EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
		  `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

  if(ctrlVerified && ctrlMispredict && fu4BranchMask[ctrlSMTid])
        invalidateFu4Packet = 1'b1;
  else
        invalidateFu4Packet = 1'b0;



  lsuBranchMask = lsuPacket0[`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:
		  `EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG];

  if(ctrlVerified && ctrlMispredict && lsuBranchMask[ctrlSMTid])
        invalidateLsuPacket = 1'b1;
  else
        invalidateLsuPacket = 1'b0;
end

 assign writebkValid0_o     = exePacketValid0 & ~invalidateFu0Packet;
 assign writebkValid1_o     = exePacketValid1 & ~invalidateFu1Packet;
 assign writebkValid2_o     = exePacketValid2 & ~invalidateFu2Packet;
 assign writebkValid3_o     = exePacketValid3 & ~invalidateFu3Packet;
 assign writebkValid4_o     = exePacketValid4 & ~invalidateFu4Packet;

 assign writebkValid5_o     = lsuPacketValid0 & ~invalidateLsuPacket; 

 assign ctrlFU0_o     = {exePacket0[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
      			 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
      			 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1],
			 exePacket0Flags[`WRITEBACK_FLAGS-1:0]
			};

 assign ctrlFU1_o     = {exePacket1[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
      		  	 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
      			 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1],
			 exePacket1Flags[`WRITEBACK_FLAGS-1:0]	
			};

 assign ctrlFU2_o     = {exePacket2[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
      			 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
      			 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1],
			 exePacket2Flags[`WRITEBACK_FLAGS-1:0]
			};

 assign ctrlFU3_o     = {exePacket3[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
      			 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
      			 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1],
			 exePacket3Flags[`WRITEBACK_FLAGS-1:0]
			};

 assign ctrlFU4_o     = {exePacket4[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
      			 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
      			 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1],
			 exePacket4Flags[`WRITEBACK_FLAGS-1:0]
			};

 assign ctrlFU5_o     = {lsuPacket0[`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:`SIZE_ISSUEQ_LOG],
			 lsuPacket0Flags[`WRITEBACK_FLAGS-1:0]
			};


 assign ldViolationPacket_o  = ldViolationPacket;




/*  Following extracts flag vector from the execution packet.
 */
assign exePacket0Flags = exePacket0[`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
      			 `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
			 `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
			 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

assign exePacket1Flags = exePacket1[`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
                         `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
                         `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                         `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

assign exePacket2Flags = exePacket2[`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
                         `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
                         `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                         `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

assign exePacket3Flags = exePacket3[`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
                         `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
                         `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                         `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

assign exePacket4Flags = exePacket4[`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
                         `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
                         `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                         `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

assign lsuPacket0Flags = lsuPacket0[`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
			 `SIZE_ISSUEQ_LOG-1:`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG];



/*  Following registers the output from the execution unit in the pipeline registers
 *  at the positive edge of the clock cycle.
 */
always @(posedge clk)
begin
 if(reset)
 begin
	exePacket0       <= 0;
	exePacketValid0  <= 0;
	exePacket1       <= 0;
	exePacketValid1  <= 0;
	exePacket2       <= 0;
	exePacketValid2  <= 0;
	exePacket3       <= 0;
	exePacketValid3  <= 0;
	exePacket4       <= 0;
	exePacketValid4  <= 0;
	
	lsuPacket0	 <= 0;
	lsuPacketValid0  <= 0;
 end
 else
 begin
	exePacketValid0  <= exePacketValid0_i;
	exePacketValid1  <= exePacketValid1_i;
	exePacketValid2  <= exePacketValid2_i;
	exePacketValid3  <= exePacketValid3_i;
	exePacketValid4  <= exePacketValid4_i;

	lsuPacketValid0  <= lsuPacketValid0_i;

	if(exePacketValid0_i)
		exePacket0  <= exePacket0_i;
	`ifdef VERIFY
	else
		exePacket0  <= 0;
	`endif

	if(exePacketValid1_i)
                exePacket1  <= exePacket1_i;
        `ifdef VERIFY
        else
                exePacket1  <= 0;
	`endif

	if(exePacketValid2_i)
                exePacket2  <= exePacket2_i;
        `ifdef VERIFY
        else
                exePacket2  <= 0;
	`endif

	if(exePacketValid3_i)
                exePacket3  <= exePacket3_i;
        `ifdef VERIFY
        else
                exePacket3  <= 0;
	`endif
	
	if(exePacketValid4_i)
                exePacket4  <= exePacket4_i;
        `ifdef VERIFY
        else
                exePacket4  <= 0;
	`endif
	

	if(lsuPacketValid0_i)
  	begin
                lsuPacket0  	   <= lsuPacket0_i;
		ldViolationPacket  <= ldViolationPacket_i;
	end
        `ifdef VERIFY
        else
	begin
                lsuPacket0  	   <= 0;
		ldViolationPacket  <= 0;
	end
        `endif
 end
end


/*  Following always block is only for verification purpose. These signals don't
 *  drive anything and has no relevance to the functionality of processor.
 *
 *  Individual values associated with an instruction is extraced from the packet,
 *  so that they can be studied in the waveform and also dumped into a file.
 *  These signals are eventually going to Active List, Bypass and control update. 
 *
 */
/*`ifdef VERIFY
always @(*)
begin
  wb_inst0BrDir    =  exePacket0[0];
  wb_inst0TarAddr  =  exePacket0[`SIZE_PC:1];
  wb_inst0CtiqTag  =  exePacket0[`SIZE_CTI_LOG+`SIZE_PC:`SIZE_PC+1];
  wb_inst0SMTid    =  exePacket0[`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst0IQentry  =  exePacket0[`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_LSQ_LOG+
      		      `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst0Data     =  exePacket0[`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+
		      `SIZE_PC:`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst0ALid     =  exePacket0[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+
		      `SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst0DestReg  =  exePacket0[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
      		      `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
      		      `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

  wb_inst1BrDir    =  exePacket1[0];
  wb_inst1TarAddr  =  exePacket1[`SIZE_PC:1];
  wb_inst1CtiqTag  =  exePacket1[`SIZE_CTI_LOG+`SIZE_PC:`SIZE_PC+1];
  wb_inst1SMTid    =  exePacket1[`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst1IQentry  =  exePacket1[`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_LSQ_LOG+
                      `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst1Data     =  exePacket1[`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+
                      `SIZE_PC:`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst1ALid     =  exePacket1[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+
                      `SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst1DestReg  =  exePacket1[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                      `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                      `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

  wb_inst2BrDir    =  exePacket2[0];
  wb_inst2TarAddr  =  exePacket2[`SIZE_PC:1];
  wb_inst2CtiqTag  =  exePacket2[`SIZE_CTI_LOG+`SIZE_PC:`SIZE_PC+1];
  wb_inst2SMTid    =  exePacket2[`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst2IQentry  =  exePacket2[`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_LSQ_LOG+
                      `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst2Data     =  exePacket2[`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+
                      `SIZE_PC:`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst2ALid     =  exePacket2[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+
                      `SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst2DestReg  =  exePacket2[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                      `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                      `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

  wb_inst3BrDir    =  exePacket3[0];
  wb_inst3TarAddr  =  exePacket3[`SIZE_PC:1];
  wb_inst3CtiqTag  =  exePacket3[`SIZE_CTI_LOG+`SIZE_PC:`SIZE_PC+1];
  wb_inst3SMTid    =  exePacket3[`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst3IQentry  =  exePacket3[`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_LSQ_LOG+
                      `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst3Data     =  exePacket3[`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+
                      `SIZE_PC:`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst3ALid     =  exePacket3[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+
                      `SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst3DestReg  =  exePacket3[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                      `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                      `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
  wb_inst3ldstSize =  exePacket3[`LDST_TYPES_LOG+1+1+1+1+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
                      `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:1+1+1+1+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
		      `SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
  
end
`endif */

endmodule
