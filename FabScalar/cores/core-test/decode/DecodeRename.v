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
# Purpose: This block implements Pipeline Latch between Decode and Rename
#          stages.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

module DecodeRename(
					 input reset,
                     input clk,
                     input flush_i,                            // Flush the piepeline if there is Exception/Mis-prediction

		     input stall_i,

                     //input freeListEmpty_i,                    // If there is not enough Phy register for renaming
                     //input stallBackEnd_i,                     // Issue Queue or LSQ or ActiveList has not enough space

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


                     output reg decodeReady_o,                   // For the Rename stage

	                     output reg [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
				 3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket0_o,
	                     output reg [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
				 3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket1_o,
	                     output reg [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
				 3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket2_o,
	                     output reg [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
				 3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket3_o,

                     output reg [`BRANCH_COUNT-1:0] branchCount_o
);


always @(posedge clk)
begin
 if(reset || flush_i)
 begin
	decodeReady_o    <= 0;

	decodedPacket0_o <= 0;
	decodedPacket1_o <= 0;
	decodedPacket2_o <= 0;
	decodedPacket3_o <= 0;

	branchCount_o    <= 0;
 end 
 else
 begin

  //if(decodeReady_i && ~freeListEmpty_i && ~stallBackEnd_i)
  if(~stall_i)
  begin  
	decodeReady_o    <= decodeReady_i;
        decodedPacket0_o <= decodedPacket0_i;
        decodedPacket1_o <= decodedPacket1_i;
        decodedPacket2_o <= decodedPacket2_i;
        decodedPacket3_o <= decodedPacket3_i;

        branchCount_o    <= branchCount_i;
  end 
  /*`ifdef VERIFY
   else
   begin
        decodedPacket0_o <= 0;
        decodedPacket1_o <= 0;
        decodedPacket2_o <= 0;
        decodedPacket3_o <= 0;
        branchCount_o    <= 0;
   end
   `endif*/
 end
end



endmodule
