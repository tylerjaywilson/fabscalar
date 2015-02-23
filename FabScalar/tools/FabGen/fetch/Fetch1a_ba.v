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
# Purpose: This block implements Fetch 1a for the look ahead predictor pipeline.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps


module FetchStage1a	(	input clk,
					input reset,
					input stall_i,
					input f_recover_EX_i,
					input f_flush_trap_i,
					input [`SIZE_PC-1:0]next_pc_i,
					output [`SIZE_PC-1:0] pc_o
				);

reg [`SIZE_PC-1:0] PC;

assign pc_o = PC;

always@(posedge clk)
begin
	if(reset)
	begin
		`ifdef VERIFY
                PC      <= $getArchPC();
                `else
                PC      <= 0;
                `endif
	end
	else if(~stall_i || f_recover_EX_i || f_flush_trap_i)
	begin
		PC<=next_pc_i;
	end
end

endmodule
