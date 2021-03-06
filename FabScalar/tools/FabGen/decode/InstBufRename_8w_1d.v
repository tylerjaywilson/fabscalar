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


module InstBufRename(input reset,
                     input clk,
                     input flush_i,                            // Flush the piepeline if there is Exception/Mis-prediction

		     input stall_i,

 		     input instBufferReady_i,

		     input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
			    3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket0_i,
                     input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
			    3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket1_i,
                     input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
			    3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket2_i,
                     input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
			    3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket3_i,
                     input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
			    3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket4_i,
                     input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
			    3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket5_i,
                     input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
			    3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket6_i,
                     input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
			    3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket7_i,

                     input [`BRANCH_COUNT-1:0] branchCount_i,


                     output reg instBufferReady_o,                   // For the Rename stage

		     output reg [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
				 3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket0_o,
                     output reg [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
				 3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket1_o,
                     output reg [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
				 3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket2_o,
                     output reg [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
				 3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket3_o,
                     output reg [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
				 3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket4_o,
                     output reg [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
				 3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket5_o,
                     output reg [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
                                 3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket6_o,
                     output reg [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+
                                 3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket7_o,

                     output reg [`BRANCH_COUNT-1:0] branchCount_o
                   );



always @(posedge clk)
begin
 if(reset || flush_i)
 begin
	instBufferReady_o    <= 0;

	decodedPacket0_o     <= 0;
	decodedPacket1_o     <= 0;
	decodedPacket2_o     <= 0;
	decodedPacket3_o     <= 0;
	decodedPacket4_o     <= 0;
	decodedPacket5_o     <= 0;
	decodedPacket6_o     <= 0;
	decodedPacket7_o     <= 0;

	branchCount_o        <= 0;
 end 
 else
 begin

  //if(instBufferReady_i && ~freeListEmpty_i && ~stallBackEnd_i)
  if(~stall_i)
  begin  
	instBufferReady_o    <= instBufferReady_i;
        decodedPacket0_o     <= decodedPacket0_i;
        decodedPacket1_o     <= decodedPacket1_i;
        decodedPacket2_o     <= decodedPacket2_i;
        decodedPacket3_o     <= decodedPacket3_i;
        decodedPacket4_o     <= decodedPacket4_i;
        decodedPacket5_o     <= decodedPacket5_i;
        decodedPacket6_o     <= decodedPacket6_i;
        decodedPacket7_o     <= decodedPacket7_i;

        branchCount_o        <= branchCount_i;
  end 
 end
end



endmodule
