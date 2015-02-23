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

module SRAM_1R1W( addr0_i,addrWr_i,we_i,data_i,
		  clk,reset,data0_o);


parameter SRAM_DEPTH  =  64;
parameter SRAM_INDEX  =  6;
parameter SRAM_WIDTH  =  32;

input [SRAM_INDEX-1:0] addr0_i;
input [SRAM_INDEX-1:0] addrWr_i;
input  we_i;
input  clk;
input  reset;
input  [SRAM_WIDTH-1:0] data_i;
output [SRAM_WIDTH-1:0] data0_o;

/* Defining register file for SRAM */
reg [SRAM_WIDTH-1:0] sram [SRAM_DEPTH-1:0];

integer i;

assign data0_o = sram[addr0_i];


always @(posedge clk)
begin
 if(reset)
 begin
  for(i=0;i<SRAM_DEPTH;i=i+1)
      sram[i] <= 0;
 end
 else
 begin
  if(we_i)
     sram[addrWr_i] <= data_i;
 end
end

endmodule


module SRAM_1R1W_i( addr0_i,addrWr_i,we_i,data_i,
                  clk,reset,data0_o);


parameter SRAM_DEPTH  =  64;
parameter SRAM_INDEX  =  6;
parameter SRAM_WIDTH  =  32;

input [SRAM_INDEX-1:0] addr0_i;
input [SRAM_INDEX-1:0] addrWr_i;
input  we_i;
input  clk;
input  reset;
input  [SRAM_WIDTH-1:0] data_i;
output [SRAM_WIDTH-1:0] data0_o;

/* Defining register file for SRAM */
reg [SRAM_WIDTH-1:0] sram [SRAM_DEPTH-1:0];

integer i;

assign data0_o = sram[addr0_i];


always @(posedge clk)
begin
  if(we_i)
     sram[addrWr_i] <= data_i;
end

endmodule

module SRAM_2R1W_HY( re0_i,addr0_i,re1_i,addr1_i,addrWr_i,we_i,data_i,
                  clk,reset,data0_o,data1_o);


parameter SRAM_DEPTH  =  64;
parameter SRAM_INDEX  =  6;
parameter SRAM_WIDTH  =  2;

parameter SRAM_FETCH_BANDWIDTH = 4;
parameter SRAM_FETCH_BANDWIDTH_LOG = 2;

input re0_i;
input [SRAM_INDEX-SRAM_FETCH_BANDWIDTH_LOG-1:0] addr0_i;
input re1_i;
input [SRAM_INDEX-1:0] addr1_i;
input [SRAM_INDEX-1:0] addrWr_i;
input  we_i;
input  clk;
input  reset;
input  [SRAM_WIDTH-1:0] data_i;
output [SRAM_FETCH_BANDWIDTH*SRAM_WIDTH-1:0] data0_o;
output [SRAM_WIDTH-1:0] data1_o;

reg [SRAM_INDEX-1:0]full_addr0;
reg [SRAM_FETCH_BANDWIDTH*SRAM_WIDTH-1:0] data0;
/* Defining register file for SRAM */
reg [SRAM_WIDTH-1:0] sram [SRAM_DEPTH-1:0];

integer i;
integer j;
integer k;

always@(*)
begin
	data0 = 0;
	full_addr0 = addr0_i << SRAM_FETCH_BANDWIDTH_LOG;
	for(j=0;j<SRAM_FETCH_BANDWIDTH;j=j+1)
	begin
		for(k=0; k<SRAM_WIDTH; k=k+1)
		begin
			data0[SRAM_WIDTH*(SRAM_FETCH_BANDWIDTH-j)-1-k] = sram[full_addr0+j][SRAM_WIDTH-k-1];
		end
	end
end
assign data0_o = re0_i ? data0 : 0;
assign data1_o = re1_i ? sram[addr1_i]: 0;


always @(posedge clk)
begin
  if (reset)
  begin
  for(i=0;i<SRAM_DEPTH;i=i+1)
      sram[i] <= 2'b10;
  end
  else if(we_i)
     sram[addrWr_i] <= data_i;
end

endmodule

