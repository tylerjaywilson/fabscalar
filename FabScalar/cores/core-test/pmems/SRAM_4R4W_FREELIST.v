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
# Purpose: This module implements SRAM.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

module SRAM_4R4W_FREELIST(
	clk,
	reset,

	addr0_i,
	addr1_i,
	addr2_i,
	addr3_i,
	addr0wr_i,
	addr1wr_i,
	addr2wr_i,
	addr3wr_i,
	we0_i,
	we1_i,
	we2_i,
	we3_i,
	data0wr_i,
	data1wr_i,
	data2wr_i,
	data3wr_i,

	data0_o,
	data1_o,
	data2_o,
	data3_o
);

/* Parameters */
parameter SRAM_DEPTH = 16;
parameter SRAM_INDEX = 4;
parameter SRAM_WIDTH = 8;

/* Input and output wires and regs */
input wire clk;
input wire reset;

input wire [SRAM_INDEX-1:0] addr0_i;
input wire [SRAM_INDEX-1:0] addr1_i;
input wire [SRAM_INDEX-1:0] addr2_i;
input wire [SRAM_INDEX-1:0] addr3_i;
input wire [SRAM_INDEX-1:0] addr0wr_i;
input wire [SRAM_INDEX-1:0] addr1wr_i;
input wire [SRAM_INDEX-1:0] addr2wr_i;
input wire [SRAM_INDEX-1:0] addr3wr_i;
input wire we0_i;
input wire we1_i;
input wire we2_i;
input wire we3_i;
input wire [SRAM_WIDTH-1:0] data0wr_i;
input wire [SRAM_WIDTH-1:0] data1wr_i;
input wire [SRAM_WIDTH-1:0] data2wr_i;
input wire [SRAM_WIDTH-1:0] data3wr_i;

output wire [SRAM_WIDTH-1:0] data0_o;
output wire [SRAM_WIDTH-1:0] data1_o;
output wire [SRAM_WIDTH-1:0] data2_o;
output wire [SRAM_WIDTH-1:0] data3_o;

/* The SRAM reg */
reg [SRAM_WIDTH-1:0] sram [SRAM_DEPTH-1:0];

integer i;

/* Read operation */
assign data0_o = sram[addr0_i];
assign data1_o = sram[addr1_i];
assign data2_o = sram[addr2_i];
assign data3_o = sram[addr3_i];

/* Write operation */
always @(posedge clk)
begin

	if(reset == 1'b1)
	begin
		for(i=0; i<SRAM_DEPTH; i=i+1)
		begin
			sram[i] <= i + `SIZE_RMT;
		end
	end
	else
	begin
		if(we0_i == 1'b1)
		begin
			sram[addr0wr_i] <= data0wr_i;
		end

		if(we1_i == 1'b1)
		begin
			sram[addr1wr_i] <= data1wr_i;
		end

		if(we2_i == 1'b1)
		begin
			sram[addr2wr_i] <= data2wr_i;
		end

		if(we3_i == 1'b1)
		begin
			sram[addr3wr_i] <= data3wr_i;
		end

	end
end

endmodule


