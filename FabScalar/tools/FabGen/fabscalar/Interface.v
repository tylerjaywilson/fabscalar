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

module Interface( input clk,
		  input reset,
		  input flush_i,
		  input wrL1ICacheEnable_i,                      
		  input [`SIZE_PC-1:0] wrAddrL1ICache_i,
		  input [`CACHE_WIDTH-1:0] wrBlockL1ICache_i,	
		  input missL1ICache_i,
                  input [`SIZE_PC-1:0] missAddrL1ICache_i,
		  output reg wrL1ICacheEnable_o,            
                  output reg [`SIZE_PC-1:0] wrAddrL1ICache_o,
                  output reg [`CACHE_WIDTH-1:0] wrBlockL1ICache_o,
   	       	  output reg missL1ICache_o,
                  output reg [`SIZE_PC-1:0] missAddrL1ICache_o
                );


always @(posedge clk)
begin
 if(reset || flush_i)
 begin
	wrL1ICacheEnable_o  <= 0;
        wrAddrL1ICache_o    <= 0;
        wrBlockL1ICache_o   <= 0;
        missL1ICache_o      <= 0;  
        missAddrL1ICache_o  <= 0;
 end
 else
 begin
	wrL1ICacheEnable_o  <= wrL1ICacheEnable_i;
        wrAddrL1ICache_o    <= wrAddrL1ICache_i;
        wrBlockL1ICache_o   <= wrBlockL1ICache_i;
        missL1ICache_o      <= missL1ICache_i;  
        missAddrL1ICache_o  <= missAddrL1ICache_i;
 	
 end
end


endmodule
