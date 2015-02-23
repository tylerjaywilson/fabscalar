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

module SRAM_4R4W_AMT( addr0_i,addr1_i,addr2_i,addr3_i,
                      addr0wr_i,we0_i,data0wr_i,
                      addr1wr_i,we1_i,data1wr_i,
                      addr2wr_i,we2_i,data2wr_i,
                      addr3wr_i,we3_i,data3wr_i,
                      clk,reset,
                      data0_o,data1_o,data2_o,data3_o);


parameter SRAM_DEPTH  =  32;
parameter SRAM_INDEX  =  5;
parameter SRAM_WIDTH  =  7;

input [SRAM_INDEX-1:0] addr0_i;
input [SRAM_INDEX-1:0] addr1_i;
input [SRAM_INDEX-1:0] addr2_i;
input [SRAM_INDEX-1:0] addr3_i;
input [SRAM_INDEX-1:0] addr0wr_i;
input [SRAM_INDEX-1:0] addr1wr_i;
input [SRAM_INDEX-1:0] addr2wr_i;
input [SRAM_INDEX-1:0] addr3wr_i;
input  [SRAM_WIDTH-1:0] data0wr_i;
input  [SRAM_WIDTH-1:0] data1wr_i;
input  [SRAM_WIDTH-1:0] data2wr_i;
input  [SRAM_WIDTH-1:0] data3wr_i;
input  we0_i;
input  we1_i;
input  we2_i;
input  we3_i;
input  clk;
input  reset;
output [SRAM_WIDTH-1:0] data0_o;
output [SRAM_WIDTH-1:0] data1_o;
output [SRAM_WIDTH-1:0] data2_o;
output [SRAM_WIDTH-1:0] data3_o;

/* Defining register file for SRAM */
reg [SRAM_WIDTH-1:0] sram [SRAM_DEPTH-1:0];

integer i;

assign data0_o = sram[addr0_i];
assign data1_o = sram[addr1_i];
assign data2_o = sram[addr2_i];
assign data3_o = sram[addr3_i];


always @(posedge clk)
begin
 if(reset)
 begin
  for(i=0;i<SRAM_DEPTH;i=i+1)
      sram[i] <= i;
 end
 else
 begin
  if(we0_i)
     sram[addr0wr_i] <= data0wr_i;
  if(we1_i)
     sram[addr1wr_i] <= data1wr_i;
  if(we2_i)
     sram[addr2wr_i] <= data2wr_i;
  if(we3_i)
     sram[addr3wr_i] <= data3wr_i;
 end
end

endmodule
