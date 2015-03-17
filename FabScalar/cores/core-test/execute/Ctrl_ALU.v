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
 1.
 2. flags_o has following fields:
	(.) Executed  :"bit-2"
       	(.) Exception :"bit-1"
       	(.) Mispredict:"bit-0"
***************************************************************************/


module Ctrl_ALU (
		  input [`SIZE_DATA-1:0] 		data1_i,	
	      input [`SIZE_DATA-1:0] 		data2_i,	
		  input [`SIZE_IMMEDIATE-1:0] 		immd_i,
		  input [`SIZE_OPCODE_I-1:0] 		opcode_i,
		  input [`SIZE_PC-1:0]   		predictedTarget_i,
		  input 				predictedDir_i, 
		  input [`SIZE_PC-1:0] 			pc_i,	 	

		  output [`SIZE_PC-1:0] 		result_o,
		  output [`SIZE_PC-1:0] 		nextPC_o,
		  output 				direction_o,
		  output [`EXECUTION_FLAGS-1:0] 	flags_o	
	        ); 



reg [`SIZE_PC-1:0] 		result;
reg [`SIZE_PC-1:0] 		nextPC;
reg 				direction;
reg [`EXECUTION_FLAGS-1:0] 	flags;


assign result_o    		= result;
assign nextPC_o    		= nextPC;
assign direction_o 		= direction;
assign flags_o     		= flags;


always @(*)
begin:ALU_OPERATION
  reg [`SIZE_DATA-1:0] sign_ex_immd;
  reg mispredict;
	
  if(immd_i[`SIZE_IMMEDIATE-1] == 1'b1)
        sign_ex_immd = {14'b11111111111111,immd_i,2'b00};
  else
        sign_ex_immd = {14'b00000000000000,immd_i,2'b00};

  result    		= 0;
  nextPC    		= 0;
  direction 		= 0;	
  flags     		= 0;

  case(opcode_i)
    	`JUMP: 
	 begin
		nextPC			= (pc_i & 32'b1111_0000_0000_0000_0000_0000_0000_0000) | ({predictedTarget_i[`SIZE_TARGET-1:0],2'b00});
	   	flags   		= {1'b1,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0};		
	 end	     
	`JAL:        
	 begin
		result    		= pc_i + 8;
		nextPC			= (pc_i & 32'b1111_0000_0000_0000_0000_0000_0000_0000) | ({predictedTarget_i[`SIZE_TARGET-1:0],2'b00});
	   	flags     		= {1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,1'b0};		
	 end	     
	`JR:                      
	 begin
		mispredict 		= (data1_i != predictedTarget_i);
		nextPC     		= data1_i;
		flags      		= {1'b1,1'b0,1'b1,1'b1,1'b0,1'b1,1'b0,mispredict};	
		`ifdef VERIFY
			//$display("EXE-> PC:%x, predictedTarget_i:%x",pc_i,predictedTarget_i);
		`endif
	 end	     
	`JALR:                    
	 begin
		result     		= pc_i + 8;
		mispredict 		= (data1_i != predictedTarget_i);
		nextPC     		= data1_i;	
		flags      		= {1'b1,1'b0,1'b0,1'b1,1'b0,1'b1,1'b0,mispredict};
	 end	     
	`BEQ:                     
	 begin
		direction  		= (data1_i == data2_i);	
		nextPC     		= (direction) ? pc_i + 8 + sign_ex_immd : pc_i + 8;				
		mispredict 		= (direction != predictedDir_i);
		flags      		= {1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,1'b0,mispredict};

		`ifdef VERIFY
		if((nextPC == predictedTarget_i) && mispredict) 
		begin 
			$display("false mispredict...PC:%x direction:%b",pc_i,direction);
			$finish;
		end
		`endif
	 end	     
	`BNE:                     
	 begin
		direction  		= (data1_i != data2_i);
                nextPC     		= (direction) ? pc_i + 8 + sign_ex_immd : pc_i + 8;
                mispredict 		= (direction != predictedDir_i);
                flags      		= {1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,1'b0,mispredict};

		`ifdef VERIFY
		if((nextPC == predictedTarget_i) && mispredict) 
		begin 
			$display("false mispredict...");
			$finish;
		end
		`endif
	 end	     
	`BLEZ:                    
	 begin
		direction  		= ((data1_i[31] == 1'b1) || (data1_i == 0));
                nextPC     		= (direction) ? pc_i + 8 + sign_ex_immd : pc_i + 8;
                mispredict 		= (direction != predictedDir_i);
                flags      		= {1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,1'b0,mispredict};

		`ifdef VERIFY
		if((nextPC == predictedTarget_i) && mispredict) 
		begin 
			$display("false mispredict...");
			$finish;
		end
		`endif
	 end	     
	`BGTZ:                    
	 begin
		direction  		= ((data1_i[31] == 1'b0) && (data1_i != 0));
                nextPC     		= (direction) ? pc_i + 8 + sign_ex_immd : pc_i + 8;
                mispredict 		= (direction != predictedDir_i);
                flags      		= {1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,1'b0,mispredict};

		`ifdef VERIFY
		if((nextPC == predictedTarget_i) && mispredict) 
		begin 
			$display("false mispredict...");
			$finish;
		end
		`endif
	 end	     
	`BLTZ:                    
	 begin
		direction  		= (data1_i[31] == 1'b1);
                nextPC     		= (direction) ? pc_i + 8 + sign_ex_immd : pc_i + 8;
                mispredict 		= (direction != predictedDir_i);
                flags      		= {1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,1'b0,mispredict};

		`ifdef VERIFY
		if((nextPC == predictedTarget_i) && mispredict) 
		begin 
			$display("false mispredict...");
			$finish;
		end
		`endif
	 end	     
	`BGEZ:                    
	 begin
		direction  		= ((data1_i[31] == 1'b0) || (data1_i == 0));
                nextPC     		= (direction) ? pc_i + 8 + sign_ex_immd : pc_i + 8;
                mispredict 		= (direction != predictedDir_i);
                flags      		= {1'b1,1'b0,1'b1,1'b0,1'b0,1'b1,1'b0,mispredict};

		`ifdef VERIFY
		if((nextPC == predictedTarget_i) && mispredict) 
		begin 
			$display("false mispredict...");
			$finish;
		end
		`endif
	 end	     
	`BC1F:                    
	 begin
                flags      		= {1'b0,1'b0,1'b0,1'b1,1'b0,1'b0};
	 end	     
	`BC1T:	
	 begin
                flags      		= {1'b0,1'b0,1'b0,1'b1,1'b0,1'b0};
	 end	     
  endcase
end    



endmodule
