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


module AgenLsu (
		 input clk,
		 input reset,
		 input ctrlMispredict_i, 	
		 input [`CHECKPOINTS_LOG-1:0] ctrlSMTid_i,
		 input [`CHECKPOINTS+`LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
                        `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket_i,
                 input exePacketValid_i,
		 
		 output agenPacketValid0_o,
                 output [`LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
                         `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] agenPacket0_o
	       );


/*  Follwoing defines the pipeline registers between AGEN and LSU.
 */
reg [`CHECKPOINTS+`LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
     `SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket3;
reg                            exePacketValid3;


/* wires and regs definition for combinational logic. */
reg                            invalidateLsuPacket;



/*  Following packet goes to Load-Store unit.
 */
assign agenPacketValid0_o  = exePacketValid3 & ~invalidateLsuPacket;
assign agenPacket0_o       = exePacket3;


always @(*)
begin:INVALIDATE_ON_MISPREDICT
  reg [`CHECKPOINTS-1:0]         lsuBranchMask;

  lsuBranchMask = exePacket3[`CHECKPOINTS+`LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
     		  `SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
		  `LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
		  `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

  if(ctrlMispredict_i && lsuBranchMask[ctrlSMTid_i])
        invalidateLsuPacket = 1'b1;
  else
        invalidateLsuPacket = 1'b0;
end


always @(posedge clk)
begin
 if(reset)
 begin
	exePacketValid3	<= 0;
	exePacket3	<= 0;
 end
 else
 begin
  	exePacketValid3  	<= exePacketValid_i;
	if(exePacketValid_i)
		exePacket3	<= exePacket_i;
	`ifdef VERIFY
        else
                exePacket3  	<= 0;
        `endif
 end
end


endmodule
