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

module DispatchedStore (
			input 				inst0Store_i,
			input 				inst1Store_i,
			input 				inst2Store_i,
			input 				inst3Store_i,

			input [`SIZE_LSQ_LOG-1:0]  	stqHead_i,
			input [`SIZE_LSQ_LOG-1:0]  	stqTail_i,
			input [`SIZE_LSQ_LOG:0]  	stqInsts_i,
			
			output [`SIZE_LSQ_LOG-1:0] 	cntStNew_o,
			output [`SIZE_LSQ_LOG-1:0] 	stqId0_o,
			output [`SIZE_LSQ_LOG-1:0] 	stqId1_o,
			output [`SIZE_LSQ_LOG-1:0] 	stqId2_o,
			output [`SIZE_LSQ_LOG-1:0] 	stqId3_o,

			output [`SIZE_LSQ_LOG-1:0] 	index0StNew_o,
			output [`SIZE_LSQ_LOG-1:0] 	index1StNew_o,
			output [`SIZE_LSQ_LOG-1:0] 	index2StNew_o,
			output [`SIZE_LSQ_LOG-1:0] 	index3StNew_o,

            output [`SIZE_LSQ_LOG-1:0] 	lastST0_o,
            output [`SIZE_LSQ_LOG-1:0] 	lastST1_o,
            output [`SIZE_LSQ_LOG-1:0] 	lastST2_o,
            output [`SIZE_LSQ_LOG-1:0] 	lastST3_o

		      );


reg [`SIZE_LSQ_LOG-1:0] 	cntStNew;
reg [`SIZE_LSQ_LOG-1:0] 	stqId0;
reg [`SIZE_LSQ_LOG-1:0] 	stqId1;
reg [`SIZE_LSQ_LOG-1:0] 	stqId2;
reg [`SIZE_LSQ_LOG-1:0] 	stqId3;

reg [`SIZE_LSQ_LOG-1:0]         lastST0;
reg [`SIZE_LSQ_LOG-1:0]         lastST1;
reg [`SIZE_LSQ_LOG-1:0]         lastST2;
reg [`SIZE_LSQ_LOG-1:0]         lastST3;

assign cntStNew_o 	= cntStNew;
assign stqId0_o		= stqId0;
assign stqId1_o		= stqId1;
assign stqId2_o		= stqId2;
assign stqId3_o		= stqId3;

assign index0StNew_o	= stqTail_i+0;
assign index1StNew_o	= stqTail_i+1;
assign index2StNew_o	= stqTail_i+2;
assign index3StNew_o	= stqTail_i+3;

assign lastST0_o	= lastST0;
assign lastST1_o	= lastST1;
assign lastST2_o	= lastST2;
assign lastST3_o	= lastST3;

always @(*)
begin:DISPATCHED_ST
  reg [`SIZE_LSQ_LOG-1:0] lastst0;
  reg [`SIZE_LSQ_LOG-1:0] lastst1;
  reg [`SIZE_LSQ_LOG-1:0] lastst2;
  reg [`SIZE_LSQ_LOG-1:0] lastst3;

  lastst0       = stqTail_i-1;
  lastst1       = stqTail_i;
  lastst2       = stqTail_i+1;
  lastst3       = stqTail_i+2;

  cntStNew    = 0;
  stqId0      = 0;
  stqId1      = 0;
  stqId2      = 0;
  stqId3      = 0;

  lastST0       = (stqInsts_i == 0) ? stqHead_i:lastst0;
  lastST1       = (stqInsts_i == 0) ? stqHead_i:lastst0;
  lastST2       = (stqInsts_i == 0) ? stqHead_i:lastst0;
  lastST3       = (stqInsts_i == 0) ? stqHead_i:lastst0;

    /* Following combinational logic counts the number of ST instructions in the
 *      incoming set of instructions. 
 */
    cntStNew    = inst3Store_i+inst2Store_i+inst1Store_i+inst0Store_i;

    case({inst3Store_i,inst2Store_i,inst1Store_i,inst0Store_i})
          4'b0001:
          begin
                stqId0      = stqTail_i;

		lastST0     = 0;
                lastST1     = lastst1;
                lastST2     = lastst1;
                lastST3     = lastst1;
          end
          4'b0010:
          begin
                stqId1      = stqTail_i;

                lastST0     = lastst0;
		lastST1     = 0;
                lastST2     = lastst1;
                lastST3     = lastst1;
          end
          4'b0011:
          begin
                stqId0      = stqTail_i;
                stqId1      = stqTail_i+1;

		lastST0     = 0;
		lastST1     = 0;
                lastST2     = lastst2;
                lastST3     = lastst2;
          end
          4'b0100:
          begin
                stqId2      = stqTail_i;

                lastST0     = lastst0;
                lastST1     = lastst0;
		lastST2     = 0;
                lastST3     = lastst1;
          end
          4'b0101:
          begin
                stqId0      = stqTail_i;
                stqId2      = stqTail_i+1;

		lastST0     = 0;
                lastST1     = lastst1;
		lastST2     = 0;
                lastST3     = lastst2;
          end
          4'b0110:
          begin
                stqId1      = stqTail_i;
                stqId2      = stqTail_i+1;

                lastST0     = lastst0;
		lastST1     = 0;
		lastST2     = 0;
                lastST3     = lastst2;
          end
          4'b0111:
          begin
                stqId0      = stqTail_i;
                stqId1      = stqTail_i+1;
                stqId2      = stqTail_i+2;

		lastST0     = 0;
		lastST1     = 0;
		lastST2     = 0;
                lastST3     = lastst3;
          end
          4'b1000:
          begin
                stqId3      = stqTail_i;

                lastST0     = lastst0;
                lastST1     = lastst0;
                lastST2     = lastst0;
		lastST3     = 0;
          end
          4'b1001:
          begin
                stqId0      = stqTail_i;
                stqId3      = stqTail_i+1;

		lastST0     = 0;
                lastST1     = lastst1;
                lastST2     = lastst1;
		lastST3     = 0;
          end
          4'b1010:
          begin
                stqId1      = stqTail_i;
                stqId3      = stqTail_i+1;

                lastST0     = lastst0;
		lastST1     = 0;
                lastST2     = lastst1;
		lastST3     = 0;
          end
          4'b1011:
          begin
                stqId0      = stqTail_i;
                stqId1      = stqTail_i+1;
                stqId3      = stqTail_i+2;

		lastST0     = 0;
		lastST1     = 0;
                lastST2     = lastst2;
		lastST3     = 0;
          end
          4'b1100:
          begin
                stqId2      = stqTail_i;
                stqId3      = stqTail_i+1;

                lastST0     = lastst0;
                lastST1     = lastst0;
		lastST2     = 0;
		lastST3     = 0;
          end
          4'b1101:
          begin
                stqId0      = stqTail_i;
                stqId2      = stqTail_i+1;
                stqId3      = stqTail_i+2;

		lastST0     = 0;
                lastST1     = lastst1;
		lastST2     = 0;
		lastST3     = 0;
          end
          4'b1110:
          begin
                stqId1      = stqTail_i;
                stqId2      = stqTail_i+1;
                stqId3      = stqTail_i+2;

                lastST0     = lastst0;
		lastST1     = 0;
		lastST2     = 0;
		lastST3     = 0;
          end
          4'b1111:
          begin
                stqId0      = stqTail_i;
                stqId1      = stqTail_i+1;
                stqId2      = stqTail_i+2;
                stqId3      = stqTail_i+3;

		lastST0     = 0;
		lastST1     = 0;
		lastST2     = 0;
		lastST3     = 0;
          end
    endcase 
end

endmodule
