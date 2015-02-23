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


/*************************************************************************** 
  FetchStage2 can deliver atmost Fetch-Width instructions to instBuffer. 
  Instructions are accompanied with valid signals.  

***************************************************************************/



module InstructionBuffer(  input clk,
                     	   input reset,

                           /* flush_i signal indicates that there is Control misprediction
                            * and instBuffer has to flush all its entries.
			    */
                           input flush_i,

                           /* stall_i is the signal from the further stages to indicate
                            * either physical registers or issue queue or Active List are
                            * full and can't accept more instructions.
			    */
                           input stall_i,

			   input decodeReady_i,
                           input [2*`FETCH_BANDWIDTH-1:0] decodedVector_i,
                	   input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                                  1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket0_i,
                           input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                                  1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket1_i,
                           input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                                  1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket2_i,
                           input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                                  1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket3_i,
                           input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                                  1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket4_i,
                           input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                                  1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket5_i,
                           input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                                  1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket6_i,
                           input [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                                  1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket7_i,
	
                           /* stallFetch_o is the signal for FetchStage1 and FetchStage2 if
                            * the instBuffer doesn't have enough space to store 4 (Fetch Bandwidth)
                            * instructions.
			    */ 
                           output stallFetch_o,

                     	   output instBufferReady_o,
		           output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                                   1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket0_o,
		           output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                                   1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket1_o,
		           output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                                   1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket2_o,
		           output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                                   1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket3_o,

			   output [`BRANCH_COUNT-1:0] branchCount_o
                        );




/* This defines the Fetch Queue, which decouples instruction fetch and 
   decode stage by a circular queue */
reg [`INST_QUEUE_LOG-1:0]  		headPtr;
reg [`INST_QUEUE_LOG-1:0]  		tailPtr;

/* Following counts the number of waiting instructions in the instBuffer.*/
reg [`INST_QUEUE_LOG:0]  		instCount;


/* wires and regs definition for combinational logic. */
integer i;
reg  [`INST_QUEUE_LOG:0]  		instcnt_f;

wire [`INST_QUEUE_LOG-1:0]              readAddr0;
wire [`INST_QUEUE_LOG-1:0]              readAddr1;
wire [`INST_QUEUE_LOG-1:0]              readAddr2;
wire [`INST_QUEUE_LOG-1:0]              readAddr3;

wire [`INST_QUEUE_LOG-1:0]  		writeAddr0;
wire [`INST_QUEUE_LOG-1:0]  		writeAddr1;
wire [`INST_QUEUE_LOG-1:0]  		writeAddr2;
wire [`INST_QUEUE_LOG-1:0]  		writeAddr3;
wire [`INST_QUEUE_LOG-1:0]  		writeAddr4;
wire [`INST_QUEUE_LOG-1:0]  		writeAddr5;
wire [`INST_QUEUE_LOG-1:0]  		writeAddr6;
wire [`INST_QUEUE_LOG-1:0]  		writeAddr7;
wire 					writeEnable0;
wire 					writeEnable1;
wire 					writeEnable2;
wire 					writeEnable3;
wire 					writeEnable4;
wire 					writeEnable5;
wire 					writeEnable6;
wire 					writeEnable7;

wire 					stallFetch;

wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
     1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket0;
wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
     1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket1;
wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
     1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket2;
wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
     1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket3;
wire 					inst0Branch;
wire 					inst1Branch;
wire 					inst2Branch;
wire 					inst3Branch;


/* Following instantiate multiported FIFO for Instruction Buffer.
 * There are 4 read ports for reading 4 decoded instruction, if there is no
 * front-end stall and there is enough free physical registers for renaming. 
 * There are 8 write ports for writing 4 bypassed data.
 */
 SRAM_4R8W #(`INST_QUEUE,`INST_QUEUE_LOG,2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1)
           instBuffer(  .addr0_i(readAddr0),
                        .addr1_i(readAddr1),
                        .addr2_i(readAddr2),
                        .addr3_i(readAddr3),
                        .we0_i(writeEnable0),
                        .addr0wr_i(writeAddr0),
                        .data0wr_i(decodedPacket0_i),
                        .we1_i(writeEnable1),
                        .addr1wr_i(writeAddr1),
                        .data1wr_i(decodedPacket1_i),
                        .we2_i(writeEnable2),
                        .addr2wr_i(writeAddr2),
                        .data2wr_i(decodedPacket2_i),
                        .we3_i(writeEnable3),
                        .addr3wr_i(writeAddr3),
                        .data3wr_i(decodedPacket3_i),
			.we4_i(writeEnable4),
                        .addr4wr_i(writeAddr4),
                        .data4wr_i(decodedPacket4_i),
                        .we5_i(writeEnable5),
                        .addr5wr_i(writeAddr5),
                        .data5wr_i(decodedPacket5_i),
                        .we6_i(writeEnable6),
                        .addr6wr_i(writeAddr6),
                        .data6wr_i(decodedPacket6_i),
                        .we7_i(writeEnable7),
                        .addr7wr_i(writeAddr7),
                        .data7wr_i(decodedPacket7_i),
                        .clk(clk),
                        .reset(reset | flush_i),
                        .data0_o(decodedPacket0),
                        .data1_o(decodedPacket1),
                        .data2_o(decodedPacket2),
                        .data3_o(decodedPacket3)
                     );




/* Following reads the instBuffer and CtrlTagQueue from the HEAD if the count 
 * of instructions is more than "DISPATCH_WIDTH-1". 
 */
assign instBufferReady_o  	= (instCount >= `DISPATCH_WIDTH) ? 1:0;
assign decodedPacket0_o		= decodedPacket0;
assign decodedPacket1_o		= decodedPacket1;
assign decodedPacket2_o		= decodedPacket2;
assign decodedPacket3_o		= decodedPacket3;
assign branchCount_o		= (inst0Branch+inst1Branch+inst2Branch+inst3Branch);



/* Following updates the head pointer if there is no stall signal from the 
 * further stages. 
 * If there is no stall from the later stages and there is atleast DISPATCH_WIDTH
 * instructions in the buffer, headPtr is increamented by DISPATCH_WIDTH;
 */
always @(posedge clk)
begin
 if(reset || flush_i)
 begin
  headPtr  <= 0;
 end
 else
 begin
  if(~stall_i)
  begin
   if(instCount >= `DISPATCH_WIDTH)
     headPtr <= headPtr + `DISPATCH_WIDTH;
  end
 end 
end



/* Following writes the instBuffer from the TAIL if the count of instructions 
   is less than "INST_QUEUE-DISPATCH_WIDTH+1". 
*/
assign stallFetch   = (instCount > (`INST_QUEUE-2*`DISPATCH_WIDTH)) ? 1:0;
assign stallFetch_o =  stallFetch;


/* Following generates addresses and write enable to write in the instruction 
 * buffer from the tail pointer.
 */
assign writeAddr0 = tailPtr;
assign writeAddr1 = tailPtr+1;
assign writeAddr2 = tailPtr+2;
assign writeAddr3 = tailPtr+3;
assign writeAddr4 = tailPtr+4;
assign writeAddr5 = tailPtr+5;
assign writeAddr6 = tailPtr+6;
assign writeAddr7 = tailPtr+7;

assign writeEnable0 = decodeReady_i & decodedVector_i[0] & ~stallFetch;
assign writeEnable1 = decodeReady_i & decodedVector_i[1] & ~stallFetch;
assign writeEnable2 = decodeReady_i & decodedVector_i[2] & ~stallFetch;
assign writeEnable3 = decodeReady_i & decodedVector_i[3] & ~stallFetch;
assign writeEnable4 = decodeReady_i & decodedVector_i[4] & ~stallFetch;
assign writeEnable5 = decodeReady_i & decodedVector_i[5] & ~stallFetch;
assign writeEnable6 = decodeReady_i & decodedVector_i[6] & ~stallFetch;
assign writeEnable7 = decodeReady_i & decodedVector_i[7] & ~stallFetch;


/* Following updates the tail pointer every cycle.
 */
always @(posedge clk)
begin
 if(reset || flush_i)
  tailPtr <= 0;
 else
 begin
  	tailPtr <= tailPtr+writeEnable0+writeEnable1+writeEnable2+writeEnable3+writeEnable4+
		   writeEnable5+writeEnable6+writeEnable7;	
 end 
end



/* Following updates the number of valid instructions in the instBuffer. The instrcution
   count is updated based on incoming valid instructions and outgoing instructions. 

   case1: upto DISPATCH_WIDTH instructions coming to buffer and DISPATCH_WIDTH instructions 
	  leaving from buffer (ideal case!!)
   
   case2: No instruction coming to buffer and DISPATCH_WIDTH instructions leaving from 
          buffer

   case3: upto DISPATCH_WIDTH instructions coming to buffer and no instruction leaving buffer

   case4: No instruction coming to buffer and no instruction leaving buffer
*/ 
always @(*)
begin:UPDATE_INST_COUNT
 reg [`INST_QUEUE_LOG:0] instcnt_1;
 
 instcnt_1 = instCount;

 if(decodeReady_i && ~stallFetch)
 begin
        instcnt_1 = instCount+decodedVector_i[0]+decodedVector_i[1]+decodedVector_i[2]+
                    decodedVector_i[3]+decodedVector_i[4]+decodedVector_i[5]+
                    decodedVector_i[6]+decodedVector_i[7];
 end

 if(~stall_i && (instCount >= `DISPATCH_WIDTH))
  	instcnt_f = instcnt_1 - `DISPATCH_WIDTH;
 else
	instcnt_f = instcnt_1;
end


always @(posedge clk)
begin
 if(reset || flush_i)
 begin
  instCount <= 0;
 end
 else
 begin
  instCount <= instcnt_f;
 end
end


/* Following extracts the total number of branch instructions in the dispatch 
 * window. 
 */
assign readAddr0		= headPtr;
assign readAddr1		= headPtr+1;
assign readAddr2		= headPtr+2;
assign readAddr3		= headPtr+3;

assign inst0Branch 		= decodedPacket0[3+`LDST_TYPES_LOG+`INST_TYPES_LOG+
				  `SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];
assign inst1Branch 		= decodedPacket1[3+`LDST_TYPES_LOG+`INST_TYPES_LOG+
				  `SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];
assign inst2Branch 		= decodedPacket2[3+`LDST_TYPES_LOG+`INST_TYPES_LOG+
				  `SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];
assign inst3Branch 		= decodedPacket3[3+`LDST_TYPES_LOG+`INST_TYPES_LOG+
				  `SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG];

 
endmodule
