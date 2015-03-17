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
# Purpose: This module implements pipeline registers between Fetch2 and Decode
#          stage.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

module Fetch2Decode( input clk,
                     input instruction0Valid_i,
                     input [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst0Packet_i,
                     output reg instruction0Valid_o,
                     output reg [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst0Packet_o,

                     input instruction1Valid_i,
                     input [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst1Packet_i,
                     output reg instruction1Valid_o,
                     output reg [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst1Packet_o,

                     input instruction2Valid_i,
                     input [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst2Packet_i,
                     output reg instruction2Valid_o,
                     output reg [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst2Packet_o,

                     input instruction3Valid_i,
                     input [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst3Packet_i,
                     output reg instruction3Valid_o,
                     output reg [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst3Packet_o,

                     input reset,
                     input flush_i,
                     input stall_i,

                     input [`SIZE_PC-1:0] updatePC_i,
                     input [`SIZE_PC-1:0] updateTargetAddr_i,
                     input [`BRANCH_TYPE-1:0] updateCtrlType_i,
                     input updateDir_i,
                     input updateEn_i,
                     input fs2Ready_i,

                     output reg [`SIZE_PC-1:0] updatePC_o,
                     output reg [`SIZE_PC-1:0] updateTargetAddr_o,
                     output reg [`BRANCH_TYPE-1:0] updateCtrlType_o,
                     output reg updateDir_o,
                     output reg updateEn_o,
                     output reg fs2Ready_o
                   );

always @(posedge clk)
begin
  if(reset)
  begin
        updatePC_o          <= 0;
        updateTargetAddr_o  <= 0;
        updateCtrlType_o    <= 0;
        updateDir_o         <= 0;
        updateEn_o          <= 0;
  end
  else
  begin
        updatePC_o          <= updatePC_i;
        updateTargetAddr_o  <= updateTargetAddr_i;
        updateCtrlType_o    <= updateCtrlType_i;
        updateDir_o         <= updateDir_i;
        updateEn_o          <= updateEn_i;
  end
end


always @(posedge clk)
begin
 if(reset || flush_i)
 begin
        fs2Ready_o          <= 0;

	instruction0Valid_o <= 0;
	inst0Packet_o       <= 0;
	instruction1Valid_o <= 0;
	inst1Packet_o       <= 0;
	instruction2Valid_o <= 0;
	inst2Packet_o       <= 0;
	instruction3Valid_o <= 0;
	inst3Packet_o       <= 0;
 end
 else
 begin
  if(~stall_i)
   begin
	fs2Ready_o          <= fs2Ready_i;

	instruction0Valid_o <= instruction0Valid_i;
	inst0Packet_o       <= inst0Packet_i;
	instruction1Valid_o <= instruction1Valid_i;
	inst1Packet_o       <= inst1Packet_i;
	instruction2Valid_o <= instruction2Valid_i;
	inst2Packet_o       <= inst2Packet_i;
	instruction3Valid_o <= instruction3Valid_i;
	inst3Packet_o       <= inst3Packet_i;
  end
 end
end

endmodule

