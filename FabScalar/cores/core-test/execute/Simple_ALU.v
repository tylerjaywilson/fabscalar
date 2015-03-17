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
# Purpose: This is a simple ALU module.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

/* Algorithm
 1. result_o contains the result of the arithmetic operation.
 2. flags_o has following fields:
	(.) Executed  :"bit-2"
       	(.) Exception :"bit-1"
       	(.) Mispredict:"bit-0"
***************************************************************************/


module Simple_ALU (
			input [`SIZE_DATA-1:0] 		data1_i,	
	        input [`SIZE_DATA-1:0] 		data2_i,	
		    input [`SIZE_IMMEDIATE-1:0] 	immd_i,
		    input [`SIZE_OPCODE_I-1:0] 		opcode_i,

		    output [`SIZE_DATA-1:0] 		result_o,
		    output [`EXECUTION_FLAGS-1:0] 	flags_o	
	          ); 



reg [`SIZE_DATA-1:0] 		result;
reg [`EXECUTION_FLAGS-1:0] 	flags;

assign result_o    = result;
assign flags_o     = flags;


always @(*)
begin:ALU_OPERATION
  reg [`SIZE_DATA-1:0] sign_ex_immd;
  reg signed [`SIZE_DATA-1:0] data_signed1;
  reg cout;
	
  if(immd_i[`SIZE_IMMEDIATE-1] == 1'b1)
        sign_ex_immd = {16'b1111111111111111,immd_i};
  else
        sign_ex_immd = {16'b0000000000000000,immd_i};

  result    = 0;
  cout      = 0;	
  flags     = 0;

  case(opcode_i)
	`ADD:    
	 begin
		{cout,result} 	= data1_i + data2_i;
		flags         	= {1'b0,1'b1,1'b0,1'b1,cout,1'b0};
	 end
	`ADDI:
	 begin
		{cout,result} 	= data1_i + sign_ex_immd;
		flags         	= {1'b0,1'b1,1'b0,1'b1,cout,1'b0};
	 end
	`ADDU:                    
	 begin
		{cout,result} 	= data1_i + data2_i;
		flags         	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`ADDIU:                   
	 begin
		{cout,result} 	= data1_i + sign_ex_immd;
		flags         	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`SUB:                     
	 begin
		{cout,result} 	= data1_i - data2_i;
                flags         	= {1'b0,1'b1,1'b0,1'b1,cout,1'b0};
	 end
	`SUBU:                    
	 begin
		{cout,result} 	= data1_i - data2_i;
                flags         	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`MFHI:                    
	 begin
		result		= data1_i;
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`MTHI:                    
	 begin
		result		= data1_i;
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`MFLO:                    
	 begin
		result		= data1_i;
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`MTLO:                    
	 begin
		result		= data1_i;
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`AND_:                    
	 begin
		result  	= data1_i & data2_i;
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`ANDI:                    
	 begin
		result  	= data1_i & {16'b0,immd_i};
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`OR:                      
	 begin
		result  	= data1_i | data2_i;
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`ORI:                     
	 begin
		result  	= data1_i | {16'b0,immd_i};
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`XOR:                     
	 begin
		result  	= data1_i ^ data2_i;
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`XORI:                    
	 begin
		result  	= data1_i ^ {16'b0,immd_i};
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`NOR:                     
	 begin
		result  	= ~(data1_i | data2_i);
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`SLL:                     
	 begin
		result  	= data1_i << immd_i;
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`SLLV:                    
	 begin
		result  	= data2_i << (data1_i & 32'h1f);
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`SRL:                     
	 begin
		result  	= data1_i >> immd_i;
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`SRLV:                    
	 begin
		result  	= data2_i >> (data1_i & 32'h1f);
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`SRA:                     
	 begin
		data_signed1	= data1_i;
		result 		= data_signed1 >>> immd_i;
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`SRAV:                    
	 begin
		data_signed1	= data2_i;
		result  	= data_signed1 >>> (data1_i & 32'h1f);
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`SLT:                    
	 begin
		case({data1_i[31],data2_i[31]})
		  2'b00: result = (data1_i < data2_i);
		  2'b01: result = 1'b0;
		  2'b10: result = 1'b1;
		  2'b11: result = (data1_i < data2_i);		
		endcase
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`SLTI:                    
	 begin
		case({data1_i[31],sign_ex_immd[31]})
		  2'b00: result = (data1_i < sign_ex_immd);
		  2'b01: result = 1'b0;
		  2'b10: result = 1'b1;
		  2'b11: result = (data1_i < sign_ex_immd);		
		endcase
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`SLTU:                    
	 begin
		result  	= (data1_i < data2_i);
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`SLTIU:
	 begin
		result  	= (data1_i < {16'b0,immd_i});
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`LUI:
	 begin
		result  	= {immd_i,16'b0};
                flags   	= {1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};
	 end
	`NOP:	
	 begin
                flags   	= {1'b0,1'b0,1'b0,1'b1,1'b0,1'b0};
	 end
  endcase
end    



endmodule
