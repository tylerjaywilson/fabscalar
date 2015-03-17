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
# Purpose: This module implements CAM.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

module CAM_4R4W(
	clk,
	reset,

	tag0_i,
	tag1_i,
	tag2_i,
	tag3_i,
	addr0wr_i,
	addr1wr_i,
	addr2wr_i,
	addr3wr_i,
	we0_i,
	we1_i,
	we2_i,
	we3_i,
	tag0wr_i,
	tag1wr_i,
	tag2wr_i,
	tag3wr_i,

	match0_o,
	match1_o,
	match2_o,
	match3_o
);

/* Parameters */
parameter CAM_DEPTH  = 16;
parameter CAM_INDEX  = 4;
parameter CAM_WIDTH  = 8;

/* Input and output wires and regs */
input wire clk;
input wire reset;

input wire [CAM_WIDTH-1:0] tag0_i;
input wire [CAM_WIDTH-1:0] tag1_i;
input wire [CAM_WIDTH-1:0] tag2_i;
input wire [CAM_WIDTH-1:0] tag3_i;
input wire [CAM_INDEX-1:0] addr0wr_i;
input wire [CAM_INDEX-1:0] addr1wr_i;
input wire [CAM_INDEX-1:0] addr2wr_i;
input wire [CAM_INDEX-1:0] addr3wr_i;
input wire we0_i;
input wire we1_i;
input wire we2_i;
input wire we3_i;
input wire [CAM_WIDTH-1:0] tag0wr_i;
input wire [CAM_WIDTH-1:0] tag1wr_i;
input wire [CAM_WIDTH-1:0] tag2wr_i;
input wire [CAM_WIDTH-1:0] tag3wr_i;

output reg [CAM_DEPTH-1:0] match0_o;
output reg [CAM_DEPTH-1:0] match1_o;
output reg [CAM_DEPTH-1:0] match2_o;
output reg [CAM_DEPTH-1:0] match3_o;

/* The CAM reg */
reg [CAM_WIDTH-1:0] cam [CAM_DEPTH-1:0];

integer i;

/* Read operation */
always @(*)
begin

	for(i=0; i<CAM_DEPTH; i=i+1)
	begin
		match0_o[i] = 1'b0;
		match1_o[i] = 1'b0;
		match2_o[i] = 1'b0;
		match3_o[i] = 1'b0;
	end

	for(i=0; i<CAM_DEPTH; i=i+1)
	begin
		if(cam[i] == tag0_i)
		begin
			match0_o[i] = 1'b1;
		end
	end

	for(i=0; i<CAM_DEPTH; i=i+1)
	begin
		if(cam[i] == tag1_i)
		begin
			match1_o[i] = 1'b1;
		end
	end

	for(i=0; i<CAM_DEPTH; i=i+1)
	begin
		if(cam[i] == tag2_i)
		begin
			match2_o[i] = 1'b1;
		end
	end

	for(i=0; i<CAM_DEPTH; i=i+1)
	begin
		if(cam[i] == tag3_i)
		begin
			match3_o[i] = 1'b1;
		end
	end

end

/* Write operation */
always @(posedge clk)
begin

	if(reset == 1'b1)
	begin
		for(i=0; i<CAM_DEPTH; i=i+1)
		begin
			cam[i] <= 0;
		end
	end
	else
	begin
		if(we0_i == 1'b1)
		begin
			cam[addr0wr_i] <= tag0wr_i;
		end

		if(we1_i == 1'b1)
		begin
			cam[addr1wr_i] <= tag1wr_i;
		end

		if(we2_i == 1'b1)
		begin
			cam[addr2wr_i] <= tag2wr_i;
		end

		if(we3_i == 1'b1)
		begin
			cam[addr3wr_i] <= tag3wr_i;
		end

	end
end

endmodule


