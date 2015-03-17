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

module DispatchedLoad (
			input 				inst0Load_i,
			input 				inst1Load_i,
			input 				inst2Load_i,
			input 				inst3Load_i,

			input [`SIZE_LSQ_LOG-1:0]  	ldqHead_i,
			input [`SIZE_LSQ_LOG-1:0]  	ldqTail_i,
			input [`SIZE_LSQ_LOG:0]  	ldqInsts_i,
			
			output [`SIZE_LSQ_LOG-1:0] 	cntLdNew_o,
			output [`SIZE_LSQ_LOG-1:0] 	ldqId0_o,
			output [`SIZE_LSQ_LOG-1:0] 	ldqId1_o,
			output [`SIZE_LSQ_LOG-1:0] 	ldqId2_o,
			output [`SIZE_LSQ_LOG-1:0] 	ldqId3_o,

			output [`SIZE_LSQ_LOG-1:0] 	index0LdNew_o,
			output [`SIZE_LSQ_LOG-1:0] 	index1LdNew_o,
			output [`SIZE_LSQ_LOG-1:0] 	index2LdNew_o,
			output [`SIZE_LSQ_LOG-1:0] 	index3LdNew_o,

            output [`SIZE_LSQ_LOG-1:0] 	nextLD0_o,
            output [`SIZE_LSQ_LOG-1:0] 	nextLD1_o,
            output [`SIZE_LSQ_LOG-1:0] 	nextLD2_o,
            output [`SIZE_LSQ_LOG-1:0] 	nextLD3_o

		      );


reg [`SIZE_LSQ_LOG-1:0] 	cntLdNew;
reg [`SIZE_LSQ_LOG-1:0] 	ldqId0;
reg [`SIZE_LSQ_LOG-1:0] 	ldqId1;
reg [`SIZE_LSQ_LOG-1:0] 	ldqId2;
reg [`SIZE_LSQ_LOG-1:0] 	ldqId3;

reg [`SIZE_LSQ_LOG-1:0]         nextLD0;
reg [`SIZE_LSQ_LOG-1:0]         nextLD1;
reg [`SIZE_LSQ_LOG-1:0]         nextLD2;
reg [`SIZE_LSQ_LOG-1:0]         nextLD3;

assign cntLdNew_o 	= cntLdNew;
assign ldqId0_o		= ldqId0;
assign ldqId1_o		= ldqId1;
assign ldqId2_o		= ldqId2;
assign ldqId3_o		= ldqId3;

assign index0LdNew_o	= ldqTail_i+0;
assign index1LdNew_o	= ldqTail_i+1;
assign index2LdNew_o	= ldqTail_i+2;
assign index3LdNew_o	= ldqTail_i+3;

assign nextLD0_o	= nextLD0;
assign nextLD1_o	= nextLD1;
assign nextLD2_o	= nextLD2;
assign nextLD3_o	= nextLD3;

always @(*)
begin:DISPATCHED_LD
  reg [`SIZE_LSQ_LOG-1:0] nextld0;
  reg [`SIZE_LSQ_LOG-1:0] nextld1;
  reg [`SIZE_LSQ_LOG-1:0] nextld2;
  reg [`SIZE_LSQ_LOG-1:0] nextld3;

  nextld0       = ldqTail_i+0;
  nextld1       = ldqTail_i+1;
  nextld2       = ldqTail_i+2;
  nextld3       = ldqTail_i+3;

  cntLdNew    = 0;
  ldqId0      = 0;
  ldqId1      = 0;
  ldqId2      = 0;
  ldqId3      = 0;

  /*nextLD0       = (ldqInsts_i == 0) ? ldqHead_i:nextld0;
  nextLD1       = (ldqInsts_i == 0) ? ldqHead_i:nextld0;
  nextLD2       = (ldqInsts_i == 0) ? ldqHead_i:nextld0;
  nextLD3       = (ldqInsts_i == 0) ? ldqHead_i:nextld0;*/
  nextLD0       = nextld0;
  nextLD1       = nextld0;
  nextLD2       = nextld0;
  nextLD3       = nextld0;

    /* Following combinational logic counts the number of LD instructions in the
       incoming set of instructions. */
    cntLdNew    = inst3Load_i+inst2Load_i+inst1Load_i+inst0Load_i;

    case({inst3Load_i,inst2Load_i,inst1Load_i,inst0Load_i})
          4'b0001:
          begin
                ldqId0      = ldqTail_i;

		nextLD0     = 0;
                nextLD1     = nextld1;
                nextLD2     = nextld1;
                nextLD3     = nextld1;
          end
          4'b0010:
          begin
                ldqId1      = ldqTail_i;

                nextLD0     = nextld0;
		nextLD1     = 0;
                nextLD2     = nextld1;
                nextLD3     = nextld1;
          end
          4'b0011:
          begin
                ldqId0      = ldqTail_i;
                ldqId1      = ldqTail_i+1;

		nextLD0     = 0;
		nextLD1     = 0;
                nextLD2     = nextld2;
                nextLD3     = nextld2;
          end
          4'b0100:
          begin
                ldqId2      = ldqTail_i;

                nextLD0     = nextld0;
                nextLD1     = nextld0;
		nextLD2     = 0;
                nextLD3     = nextld1;
          end
          4'b0101:
          begin
                ldqId0      = ldqTail_i;
                ldqId2      = ldqTail_i+1;

		nextLD0     = 0;
                nextLD1     = nextld1;
		nextLD2     = 0;
                nextLD3     = nextld2;
          end
          4'b0110:
          begin
                ldqId1      = ldqTail_i;
                ldqId2      = ldqTail_i+1;

                nextLD0     = nextld0;
		nextLD1     = 0;
		nextLD2     = 0;
                nextLD3     = nextld2;
          end
          4'b0111:
          begin
                ldqId0      = ldqTail_i;
                ldqId1      = ldqTail_i+1;
                ldqId2      = ldqTail_i+2;

		nextLD0     = 0;
		nextLD1     = 0;
		nextLD2     = 0;
                nextLD3     = nextld3;
          end
          4'b1000:
          begin
                ldqId3      = ldqTail_i;

                nextLD0     = nextld0;
                nextLD1     = nextld0;
                nextLD2     = nextld0;
		nextLD3     = 0;
          end
          4'b1001:
          begin
                ldqId0      = ldqTail_i;
                ldqId3      = ldqTail_i+1;

		nextLD0     = 0;
                nextLD1     = nextld1;
                nextLD2     = nextld1;
		nextLD3     = 0;
          end
          4'b1010:
          begin
                ldqId1      = ldqTail_i;
                ldqId3      = ldqTail_i+1;

                nextLD0     = nextld0;
		nextLD1     = 0;
                nextLD2     = nextld1;
		nextLD3     = 0;
          end
          4'b1011:
          begin
                ldqId0      = ldqTail_i;
                ldqId1      = ldqTail_i+1;
                ldqId3      = ldqTail_i+2;

		nextLD0     = 0;
		nextLD1     = 0;
                nextLD2     = nextld2;
		nextLD3     = 0;
          end
          4'b1100:
          begin
                ldqId2      = ldqTail_i;
                ldqId3      = ldqTail_i+1;

                nextLD0     = nextld0;
                nextLD1     = nextld0;
		nextLD2     = 0;
		nextLD3     = 0;
          end
          4'b1101:
          begin
                ldqId0      = ldqTail_i;
                ldqId2      = ldqTail_i+1;
                ldqId3      = ldqTail_i+2;

		nextLD0     = 0;
                nextLD1     = nextld1;
		nextLD2     = 0;
		nextLD3     = 0;
          end
          4'b1110:
          begin
                ldqId1      = ldqTail_i;
                ldqId2      = ldqTail_i+1;
                ldqId3      = ldqTail_i+2;

                nextLD0     = nextld0;
		nextLD1     = 0;
		nextLD2     = 0;
		nextLD3     = 0;
          end
          4'b1111:
          begin
                ldqId0      = ldqTail_i;
                ldqId1      = ldqTail_i+1;
                ldqId2      = ldqTail_i+2;
                ldqId3      = ldqTail_i+3;

		nextLD0     = 0;
		nextLD1     = 0;
		nextLD2     = 0;
		nextLD3     = 0;
          end
    endcase 
end

endmodule
