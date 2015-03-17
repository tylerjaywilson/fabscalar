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
# Purpose: This module implements RSR.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps


/*
  Assumption:

  There are 4-Functional Units (Integer Type) including AGEN block which is a 
  dedicated FU for Load/Store.
     FU0  2'b00     // Simple ALU
     FU1  2'b01     // Complex ALU (for MULTIPLY & DIVIDE)
     FU2  2'b10     // ALU for CONTROL Instructions
     FU3  2'b11     // LOAD/STORE Address Generator

  Tag broadcast of the Load instruction is taken care by Load/Store Queue Unit 
  because of additional comlpexity of load miss.

  Algorithm:

  1. Each cycle RSR module receives physical tag of the 
     granted instructions (for only instruction type 0, 1 and 2)

  2. Physical destination tag for type 0/2 is broadcasted in the next 
     cycle only, as type 0/2 has single cycle execution latency.

  3. Physical destination tag for type 1 is broadcasted in FU1_LATENCY-2
     cycle only. Appropriate shift register is maintined for FU1 tag.

************************************************************************************/

module RSR2(
	input clk,
	input reset,

	input ctrlVerified_i,
	input ctrlMispredict_i,
	input [`CHECKPOINTS_LOG-1:0] ctrlSMTid_i,

	input validPacket0_i,
	input validPacket1_i,
	input validPacket2_i,

	input [`SIZE_PHYSICAL_LOG-1:0] granted0Dest_i,
	input [`SIZE_PHYSICAL_LOG-1:0] granted1Dest_i,
	input [`SIZE_PHYSICAL_LOG-1:0] granted2Dest_i,

	input [`CHECKPOINTS-1:0] branchMask0_i,
	input [`CHECKPOINTS-1:0] branchMask1_i,
	input [`CHECKPOINTS-1:0] branchMask2_i,

	output rsr0TagValid_o,
	output rsr1TagValid_o,
	output rsr2TagValid_o,

	output [`SIZE_PHYSICAL_LOG-1:0] rsr0Tag_o,
	output [`SIZE_PHYSICAL_LOG-1:0] rsr1Tag_o,
	output [`SIZE_PHYSICAL_LOG-1:0] rsr2Tag_o
);

/* Instantiation of RSR for Complex ALU (type 1)
 */
reg [`SIZE_PHYSICAL_LOG-1:0] RSR_CALU [`FU1_LATENCY-2:0];
reg [`FU1_LATENCY-2:0] RSR_CALU_VALID;
reg [`CHECKPOINTS-1:0] BRANCH_MASK [`FU1_LATENCY-2:0];

/* Wires and regs declaration for combinational logic */
reg validPacket0;
reg validPacket1;
reg validPacket2;

reg [`SIZE_PHYSICAL_LOG-1:0] granted0Dest;
reg [`SIZE_PHYSICAL_LOG-1:0] granted1Dest;
reg [`SIZE_PHYSICAL_LOG-1:0] granted2Dest;

reg [`SIZE_PHYSICAL_LOG-1:0] branchMask0;
reg [`SIZE_PHYSICAL_LOG-1:0] branchMask1;
reg [`SIZE_PHYSICAL_LOG-1:0] branchMask2;

/* Assign outputs */
assign rsr0Tag_o = (validPacket0 && ~(ctrlVerified_i && ctrlMispredict_i && branchMask0[ctrlSMTid_i]))? granted0Dest:0;
assign rsr2Tag_o = (validPacket2 && ~(ctrlVerified_i && ctrlMispredict_i && branchMask2[ctrlSMTid_i]))? granted2Dest:0;

assign rsr0TagValid_o = validPacket0 && ~(ctrlVerified_i && ctrlMispredict_i && branchMask0[ctrlSMTid_i]);
assign rsr2TagValid_o = validPacket2 && ~(ctrlVerified_i && ctrlMispredict_i && branchMask2[ctrlSMTid_i]);

assign rsr1Tag_o = (RSR_CALU_VALID[`FU1_LATENCY-2] && ~(ctrlVerified_i && ctrlMispredict_i && BRANCH_MASK[`FU1_LATENCY-2][ctrlSMTid_i])) ? RSR_CALU[`FU1_LATENCY-2]:0;
assign rsr1TagValid_o =  RSR_CALU_VALID[`FU1_LATENCY-2] && ~(ctrlVerified_i && ctrlMispredict_i && BRANCH_MASK[`FU1_LATENCY-2][ctrlSMTid_i]);

/* The 1-cycle delay */
always @(posedge clk)
begin
	if(reset)
	begin
		validPacket0 <= 0;
		granted0Dest <= 0;
		branchMask0 <= 0;

		validPacket1 <= 0;
		granted1Dest <= 0;
		branchMask1 <= 0;

		validPacket2 <= 0;
		granted2Dest <= 0;
		branchMask2 <= 0;
	end
	else
	begin
		validPacket0 <= validPacket0_i;
		granted0Dest <= granted0Dest_i;
		branchMask0 <= branchMask0_i;

		validPacket1 <= validPacket1_i;
		granted1Dest <= granted1Dest_i;
		branchMask1 <= branchMask1_i;

		validPacket2 <= validPacket2_i;
		granted2Dest <= granted2Dest_i;
		branchMask2 <= branchMask2_i;
	end
end

 /* Following acts like a shift register for high latency instruction
    (more than 1). 
 */
always @(posedge clk)
begin:UPDATE
	integer i;

	if(reset)
	begin
		for(i=0;i<`FU1_LATENCY-1;i=i+1)
		begin
			RSR_CALU[i] <= 0;
			BRANCH_MASK[i] <= 0;
		end

		RSR_CALU_VALID <= 0;
	end
	else
	begin
		if(validPacket1 && ~(ctrlVerified_i && ctrlMispredict_i && branchMask1[ctrlSMTid_i]))
		begin
			RSR_CALU[0] <= granted1Dest;
			RSR_CALU_VALID[0] <= 1'b1;
			BRANCH_MASK[0] <= branchMask1;
		end
		else
		begin
			RSR_CALU[0] <= 0;
			RSR_CALU_VALID[0] <= 1'b0;
			BRANCH_MASK[0] <= 0;
		end

		for(i=0; i<`FU1_LATENCY-2; i=i+1)
		begin
			if(ctrlVerified_i && ctrlMispredict_i && BRANCH_MASK[i][ctrlSMTid_i])
			begin
				RSR_CALU[i+1] <= 0;
				RSR_CALU_VALID[i+1] <= 0;
				BRANCH_MASK[i+1] <= 0;
			end
			else
			begin
				RSR_CALU[i+1] <= RSR_CALU[i];
				RSR_CALU_VALID[i+1] <= RSR_CALU_VALID[i];
				BRANCH_MASK[i+1] <= BRANCH_MASK[i];
			end
		end
	end
end

endmodule
