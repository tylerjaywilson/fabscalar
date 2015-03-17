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
# Purpose: This is Load/Store address generation module.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps


/* Algorithm
 1. result_o contains the result of the address calculation operation.
***************************************************************************/


module AGEN (
		input [`SIZE_DATA-1:0] 		data1_i,	
	    input [`SIZE_DATA-1:0] 		data2_i,	
		input [`SIZE_IMMEDIATE-1:0] 	immd_i,
		input [`SIZE_OPCODE_I-1:0] 	opcode_i,

		output [`SIZE_DATA-1:0] 	result_o,
		output [`LDST_TYPES_LOG-1:0] 	ldstSize_o,
		output [`EXECUTION_FLAGS-1:0] 	flags_o
	    ); 


reg [`SIZE_DATA-1:0] 		result;
reg [`LDST_TYPES_LOG-1:0] 	ldstSize;
reg [`EXECUTION_FLAGS-1:0] 	flags;


assign result_o    = result;
assign ldstSize_o  = ldstSize;
assign flags_o     = flags;


always @(*)
begin:ALU_OPERATION
  reg [`SIZE_DATA-1:0] sign_ex_immd;
	
  if(immd_i[`SIZE_IMMEDIATE-1] == 1'b1)
        sign_ex_immd = {16'b1111111111111111,immd_i};
  else
        sign_ex_immd = {16'b0000000000000000,immd_i};

  result    = 0;
  ldstSize  = 0;
  flags	    = 0;	

  case(opcode_i)
	`LB: 
	 begin
		result 	   = data1_i + sign_ex_immd;
		ldstSize   = `LDST_BYTE;
		flags	   = {1'b1,1'b0,1'b1,1'b0,3'b000};	
	 end                     
	`LBU:                     
	 begin
		result 	   = data1_i + sign_ex_immd;
		ldstSize   = `LDST_BYTE;
		flags	   = {1'b0,1'b0,1'b1,1'b0,3'b000};	
	 end                     
	`LH:                      
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = `LDST_HALF_WORD;
		flags	   = {1'b1,1'b0,1'b1,1'b0,3'b000};	
	 end                     
	`LHU:                     
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = `LDST_HALF_WORD;
		flags	   = {1'b0,1'b0,1'b1,1'b0,3'b000};	
	 end                     
	`LW:                      
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = `LDST_WORD;
		flags	   = {1'b0,1'b1,1'b0,3'b000};	
	 end                     
	`DLW_H:                     
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = `LDST_WORD;
		flags	   = {1'b0,1'b1,1'b0,3'b000};	
	 end                     
	`DLW_L:
         begin
                result     = data1_i + sign_ex_immd;
                ldstSize   = `LDST_WORD;
                flags      = {1'b0,1'b1,1'b1,3'b000};
         end
	`L_S:                     
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = 0;
		flags	   = {1'b0,1'b1,1'b0,3'b000};	
	 end                     
	`L_D:                     
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = 0;
		flags	   = {1'b0,1'b1,1'b0,3'b000};	
	 end                     
	`LWL:                     
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = 0;
		flags	   = {1'b0,1'b1,1'b0,3'b000};	
	 end                     
	`LWR:                    
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = 0;
		flags	   = {1'b0,1'b1,1'b0,3'b000};	
	 end                     
	`SB:                     
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = `LDST_BYTE;
		flags	   = {1'b0,1'b0,1'b0,3'b100};	
	 end                     
	`SH:                      
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = `LDST_HALF_WORD;
		flags	   = {1'b0,1'b0,1'b0,3'b100};	
	 end                     
	`SW:                
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = `LDST_WORD;
		flags	   = {1'b0,1'b0,1'b0,3'b100};	
	 end                     
	`DSW_H:
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = `LDST_WORD;
		flags	   = {1'b0,1'b0,1'b0,3'b100};	
	 end  
	`DSW_L:
         begin
                result     = data1_i + sign_ex_immd;
                ldstSize   = `LDST_WORD;
                flags      = {1'b0,1'b0,1'b1,3'b100};
         end                   
	`DSZ:                     
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = 0;
		flags	   = 3'b000;	
	 end                     
	`S_S:                     
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = 0;
		flags	   = 3'b000;	
	 end                     
	`S_D:                     
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = 0;
		flags	   = 3'b000;	
	 end                     
	`SWL:                    
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = 0;
		flags	   = 3'b000;	
	 end                     
	`SWR:
	 begin
		result     = data1_i + sign_ex_immd;
		ldstSize   = 0;
		flags	   = 3'b000;	
	 end                     
  endcase
end    

endmodule
