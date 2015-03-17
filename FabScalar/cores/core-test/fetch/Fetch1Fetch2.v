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
# Purpose: This implements pipeline register between Fetch1 and Fetch2 stages.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

module Fetch1Fetch2( input clk,
                     input btbHit0_i,
                     input [`SIZE_PC-1:0] targetAddr0_i,
                     input prediction0_i,

                     output reg btbHit0_o,
                     output reg [`SIZE_PC-1:0] targetAddr0_o,
                     output reg prediction0_o,

                     input btbHit1_i,
                     input [`SIZE_PC-1:0] targetAddr1_i,
                     input prediction1_i,

                     output reg btbHit1_o,
                     output reg [`SIZE_PC-1:0] targetAddr1_o,
                     output reg prediction1_o,

                     input btbHit2_i,
                     input [`SIZE_PC-1:0] targetAddr2_i,
                     input prediction2_i,

                     output reg btbHit2_o,
                     output reg [`SIZE_PC-1:0] targetAddr2_o,
                     output reg prediction2_o,

                     input btbHit3_i,
                     input [`SIZE_PC-1:0] targetAddr3_i,
                     input prediction3_i,

                     output reg btbHit3_o,
                     output reg [`SIZE_PC-1:0] targetAddr3_o,
                     output reg prediction3_o,

                     input reset,
                     input flush_i,
                     input stall_i,
                     input fs1Ready_i,
                     input [`SIZE_PC-1:0] pc_i,

                     input [`INSTRUCTION_BUNDLE-1:0] instructionBundle_i,

                     `ifdef ICACHE
                     input startBlock_i,
                     input [1:0] firstInst_i,
                     `endif

                     `ifdef ICACHE
                     output reg startBlock_o,
                     output reg [1:0] firstInst_o
                     `endif
                     output reg [`SIZE_PC-1:0] pc_o,
                     output reg [`INSTRUCTION_BUNDLE-1:0] instructionBundle_o,

                     output reg fs1Ready_o
                   );
always @(posedge clk)
begin
 if(reset || flush_i)
 begin
        fs1Ready_o          <= 0;
        pc_o                <= 0;
        instructionBundle_o <= 0;
        `ifdef ICACHE
        startBlock_o        <= 0;
        firstInst_o         <= 0;
        `endif
	btbHit0_o           <= 0;
	targetAddr0_o       <= 0;
	prediction0_o       <= 0;
	btbHit1_o           <= 0;
	targetAddr1_o       <= 0;
	prediction1_o       <= 0;
	btbHit2_o           <= 0;
	targetAddr2_o       <= 0;
	prediction2_o       <= 0;
	btbHit3_o           <= 0;
	targetAddr3_o       <= 0;
	prediction3_o       <= 0;
  end
 else
 begin

   if(~stall_i)
   begin
	fs1Ready_o          <= fs1Ready_i;
	pc_o                <= pc_i;
	instructionBundle_o <= instructionBundle_i;
	`ifdef ICACHE
	startBlock_o        <= startBlock_i;
	firstInst_o         <= firstInst_i;
	`endif
	btbHit0_o           <= btbHit0_i;
	targetAddr0_o       <= targetAddr0_i;
	prediction0_o       <= prediction0_i;
	btbHit1_o           <= btbHit1_i;
	targetAddr1_o       <= targetAddr1_i;
	prediction1_o       <= prediction1_i;
	btbHit2_o           <= btbHit2_i;
	targetAddr2_o       <= targetAddr2_i;
	prediction2_o       <= prediction2_i;
	btbHit3_o           <= btbHit3_i;
	targetAddr3_o       <= targetAddr3_i;
	prediction3_o       <= prediction3_i;
  end
 end
end

endmodule

