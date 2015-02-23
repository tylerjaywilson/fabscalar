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


module PreDecode_PISA( 	input [`SIZE_PC-1:0] 		pc_i,
		     	input [`SIZE_INSTRUCTION-1:0] 	instruction_i,
			input [`SIZE_PC-1:0]		targetAddr_i,
			input 				prediction_i,
 			output 				isInstCtrl_o,
 			output 				isInstRtr_o,	
			output [`SIZE_PC-1:0] 		targetAddr_o,
 			output [`BRANCH_TYPE-1:0]	ctrlType_o
                     );



/* wires and regs definition for combinational logic. */
wire [`SIZE_OPCODE_P-1:0] 		opcode;
reg [`BRANCH_TYPE-1:0] 			ctrlType;
reg [`SIZE_PC-1:0] 			targetAddr;
reg 					isInstCtrl;
reg 					isInstRtr;


assign isInstCtrl_o	= isInstCtrl;
assign isInstRtr_o	= isInstRtr;
assign targetAddr_o  	= targetAddr;
assign ctrlType_o	= ctrlType;



/*   Following extracts the opcode from the instructions.  */
assign opcode  =  instruction_i[`SIZE_INSTRUCTION-1:`SIZE_INSTRUCTION-`SIZE_OPCODE_P];

always @(*)
begin:PRE_DECODE_FOR_CTRL
 reg [`SIZE_DATA-1:0] sign_ex_immd;

 targetAddr = 0;
 ctrlType   = 0;
 isInstCtrl = 1'b0;
 isInstRtr  = 0;

 if(instruction_i[`SIZE_IMMEDIATE-1] == 1'b1)
 	sign_ex_immd = {14'b11111111111111,instruction_i[`SIZE_IMMEDIATE-1:0],2'b00};
 else
 	sign_ex_immd = {14'b00000000000000,instruction_i[`SIZE_IMMEDIATE-1:0],2'b00};


 case(opcode)
   `JUMP: begin 
          targetAddr = (pc_i & 32'b1111_0000_0000_0000_0000_0000_0000_0000) | ({instruction_i[`SIZE_TARGET-1:0],2'b00});
          ctrlType   = 2'b10;
          isInstCtrl = 1'b1;
          isInstRtr  = 0;
         end
   
   `JAL: begin
          targetAddr = (pc_i & 32'b1111_0000_0000_0000_0000_0000_0000_0000) | ({instruction_i[`SIZE_TARGET-1:0],2'b00});
          ctrlType   = 2'b01;
          isInstCtrl = 1'b1;
          isInstRtr  = 0;
         end

  `JR:  begin
          targetAddr = targetAddr_i;
          isInstCtrl = 1'b1;//&(instruction_i[`SIZE_RMT_LOG-1+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU]);
          isInstRtr  = &(instruction_i[`SIZE_RMT_LOG-1+`SIZE_RT+`SIZE_RD+`SIZE_RU-1:`SIZE_RT+`SIZE_RD+`SIZE_RU]);  
          ctrlType   = {~isInstRtr,1'b0};
         end
  `JALR: begin
          targetAddr    = pc_i+32'h8;
          ctrlType 	= 2'b01;
          isInstCtrl    = 1'b1;
          isInstRtr     = 0;
         end

   `BEQ: begin
	  if(prediction_i)	
          	targetAddr = pc_i + 8 + sign_ex_immd;
	  else
		targetAddr = pc_i + 8;
          //targetAddr = pc_i + 8 + sign_ex_immd;
          ctrlType   = 2'b11; 
          isInstCtrl = 1'b1;
          isInstRtr  = 0;
         end

   `BNE: begin
	  if(prediction_i)	
          	targetAddr = pc_i + 8 + sign_ex_immd;
	  else
		targetAddr = pc_i + 8;
          //targetAddr = pc_i + 8 + sign_ex_immd;
          ctrlType   = 2'b11;
          isInstCtrl = 1'b1;
          isInstRtr  = 0;
         end

  `BLEZ: begin
	  if(prediction_i)	
          	targetAddr = pc_i + 8 + sign_ex_immd;
	  else
		targetAddr = pc_i + 8;
          //targetAddr = pc_i + 8 + sign_ex_immd;
          ctrlType   = 2'b11;
          isInstCtrl = 1'b1;
          isInstRtr  = 0;
         end

  `BGTZ: begin
	  if(prediction_i)	
          	targetAddr = pc_i + 8 + sign_ex_immd;
	  else
		targetAddr = pc_i + 8;
          //targetAddr = pc_i + 8 + sign_ex_immd;
          ctrlType   = 2'b11;
          isInstCtrl = 1'b1;
          isInstRtr  = 0;
         end

  `BLTZ: begin
	  if(prediction_i)	
          	targetAddr = pc_i + 8 + sign_ex_immd;
	  else
		targetAddr = pc_i + 8;
          //targetAddr = pc_i + 8 + sign_ex_immd;
          ctrlType   = 2'b11;
          isInstCtrl = 1'b1;
          isInstRtr  = 0;
         end

  `BGEZ: begin
	  if(prediction_i)	
          	targetAddr = pc_i + 8 + sign_ex_immd;
	  else
		targetAddr = pc_i + 8;
          //targetAddr = pc_i + 8 + sign_ex_immd;
          ctrlType   = 2'b11;
          isInstCtrl = 1'b1;
          isInstRtr  = 0;
         end

  `BC1T: begin
          targetAddr = pc_i + 8 + sign_ex_immd;
          ctrlType   = 2'b11;
          isInstCtrl = 1'b1;
          isInstRtr  = 0;
         end

  `BC1F: begin
          targetAddr = pc_i + 8 + sign_ex_immd;
          ctrlType   = 2'b11;
          isInstCtrl = 1'b1;
          isInstRtr  = 0;
         end
 endcase
end


endmodule
