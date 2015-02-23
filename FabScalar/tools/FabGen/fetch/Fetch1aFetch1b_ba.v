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
# Purpose: This block implements the register between Fetch 1a and Fetch 1b for 
#	   the look ahead predictor pipeline.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

module Fetch1aFetch1b(	input clk,
						input reset,
						input [`SIZE_PC-1:0]pc_i,
						input stall_i,
						input flush_i,
						output reg [`SIZE_PC-1:0]pc_o,
						output reg valid_pc_o
					);

always@(posedge clk)
begin
	if(reset || flush_i)
	begin
		pc_o <= 0;
		valid_pc_o <= 0;
	end
	else if(~stall_i)
	begin
		pc_o <= pc_i;
		valid_pc_o <= 1'b1;
	end
end

endmodule
						
