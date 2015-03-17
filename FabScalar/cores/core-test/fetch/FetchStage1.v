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
# Purpose: This module implements FetchStage1.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

module FetchStage1(/* Following are control signals for stalling, flushing and reseting the module. */
		input flush_i,
		input stall_i,
		input clk,
		input reset,

		input recoverFlag_i,	
		input [`SIZE_PC-1:0] recoverPC_i,	

		input exceptionFlag_i,
		input [`SIZE_PC-1:0] exceptionPC_i,

		/* flagRecoverID_i and targetAddrID_i are used to if there has been Branch
		target misprediction for Direct control instruction (resolved during ID stage).
		flagCallID_i is used only if the BTB missed the Call instruction and the 
		callPCID_i has to be pushed into RAS.
		flagRtrID_i is used only if the BTB missed the Return instruction and the
		targetAddrID_i has to be popped from RAS. 
		*/
		input flagRecoverID_i,
		input flagCallID_i,
		input [`SIZE_PC-1:0] callPCID_i,
		input flagRtrID_i,
		input [`SIZE_PC-1:0] targetAddrID_i,

		/* flagRecoverEX_i,pcRecoverEX_i and targetAddrEX_i are used if there has been Branch 
		target misprediction for Indirect control instruction (resolved during Execute stage). 
		*/
		input flagRecoverEX_i,
		input [`SIZE_PC-1:0] targetAddrEX_i,
		
		/* Update signals are used to update the Branch Predictor and BTB. The update signal comes 
		from CTI Queue in the order of program sequence for the control instructions.
		Control Inst Types: 00 = Return; 01 = Call Direct/Indirect
		10 = Jump Direct/Indirect; 11 = Conditional Branch
		*/
		input [`SIZE_PC-1:0] updatePC_i,
		input [`SIZE_PC-1:0] updateTargetAddr_i,
		input [`BRANCH_TYPE-1:0] updateBrType_i,
		input updateDir_i,
		input updateEn_i,


		/* fs1Ready_o indicates if there is any cache miss and next stage will have to wait. */
		output fs1Ready_o,
		output [`INSTRUCTION_BUNDLE-1:0] instructionBundle_o,
		output [`SIZE_PC-1:0] pc_o,
		output [`SIZE_PC-1:0] addrRAS_CP_o,	
		
		`ifdef ICACHE
		output startBlock_o,       // 0 - Even, 1 - Odd
		/* First instruction in the starting block */
		output [1:0] firstInst_o,
		`endif

		output btbHit0_o,
		output [`SIZE_PC-1:0] targetAddr0_o,
		output prediction0_o,
		output btbHit1_o,
		output [`SIZE_PC-1:0] targetAddr1_o,
		output prediction1_o,
		output btbHit2_o,
		output [`SIZE_PC-1:0] targetAddr2_o,
		output prediction2_o,
		output btbHit3_o,
		output [`SIZE_PC-1:0] targetAddr3_o,
		output prediction3_o,

		/* Following I/O signals are for handling L1-Instruction cache miss.
		These signals go/come to/from lower level memory hierarchy.
		*/
		input  wrEnable_i,
		input  [`SIZE_PC-1:0] wrAddr_i,
		input  [`CACHE_WIDTH-1:0] instBlock_i,
		output miss_o,
		output [`SIZE_PC-1:0] missAddr_o
		);




/* Defining Program Counter register. */
reg [`SIZE_PC-1:0] 		PC;


/* wire and register definition for combinational logic */
wire 				updateBTB;
wire 				updateBPB;
wire 				prediction0;
wire 				prediction1;
wire 				prediction2;
wire 				prediction3;
wire 				btbHit0;
wire 				btbHit1;
wire 				btbHit2;
wire 				btbHit3;
wire [`SIZE_PC-1:0]		targetAddr0;
wire [`SIZE_PC-1:0]		targetAddr1;
wire [`SIZE_PC-1:0]		targetAddr2;
wire [`SIZE_PC-1:0]		targetAddr3;

reg 				btbhit0;
reg 				btbhit1;
reg 				btbhit2;
reg 				btbhit3;
reg 				pushras;
reg [`SIZE_PC-1:0] 		pushaddr;
reg 				popras;
wire [`SIZE_PC-1:0] 		addrRAS;
wire [`SIZE_PC-1:0] 		addrRAS_CP;
wire [1:0]			btbCtrlType0;
wire [1:0]			btbCtrlType1;
wire [1:0]			btbCtrlType2;
wire [1:0]			btbCtrlType3;
wire 				miss;

wire 				targetAddrID;
reg [`SIZE_PC-1:0] 		nextPC;



/* updateBPB signal is brach predictor table update enabler. This is 1 
* only if control instruction type is conditional branch. 
* In case of conditional branches, update the BTB only if the direction is
* Taken.
* The update signals come from CTI Queue in program order. 
*/
assign updateBPB = (updateEn_i & updateBrType_i[0] & updateBrType_i[1]);
assign updateBTB = (updateBrType_i == 2'b11) ? (updateDir_i&updateEn_i) : updateEn_i;


/* Instantiating Branch prediction and BTB Unit. 
*/
BTB btb(.PC_i(PC),
		.updateEn_i(updateBTB),
		.updatePC_i(updatePC_i),
		.updateBrType_i(updateBrType_i),
		.updateTargetAddr_i(updateTargetAddr_i),
		.stall_i(stall_i),
		.btbFlush_i(1'b0),
		.clk(clk),
		.reset(reset),
		.btbHit0_o(btbHit0),
		.ctrlType0_o(btbCtrlType0),
		.targetAddr0_o(targetAddr0),
		.btbHit1_o(btbHit1),
		.ctrlType1_o(btbCtrlType1),
		.targetAddr1_o(targetAddr1),
		.btbHit2_o(btbHit2),
		.ctrlType2_o(btbCtrlType2),
		.targetAddr2_o(targetAddr2),
		.btbHit3_o(btbHit3),
		.ctrlType3_o(btbCtrlType3),
		.targetAddr3_o(targetAddr3)
		);


BranchPrediction bp(.pc_i(PC),
		.updateDir_i(updateDir_i),
		.updatePC_i(updatePC_i),
		.updateEn_i(updateBPB),
		.stall_i(stall_i),
		.bpFlush_i(1'b0),
		.clk(clk),
		.reset(reset),
		.prediction0_o(prediction0),
		.prediction1_o(prediction1),
		.prediction2_o(prediction2),
		.prediction3_o(prediction3)
		); 



/* Instantiating Return Address Stack (RAS). 
*/
RAS ras(.flagRecoverID_i(flagRecoverID_i&~stall_i),
	.flagCallID_i(flagCallID_i),
	.callPCID_i(callPCID_i),
	.flagRtrID_i(flagRtrID_i),
	.flagRecoverEX_i(1'b0),
	.pop_i(popras&~stall_i),
	.push_i(pushras&~stall_i),
	.pushAddr_i(pushaddr),
	.stall_i(stall_i),
	.flushRas_i(1'b0),
	.pc_i(PC),
	.clk(clk),
	.reset(reset),
	.addrRAS_o(addrRAS),
	.addrRAS_CP_o(addrRAS_CP)
	);



/* Instantiating Level-1 Instruction Cache. 
*/
L1ICache l1icache(	.clk(clk),
			.reset(reset),
			.addr_i(PC),
			.rdEnable_i(stall_i),
			.wrEnabale_i(wrEnable_i),
			.wrAddr_i(wrAddr_i),
			.instBlock_i(instBlock_i),
			.instBundle_o(instructionBundle_o),
			.miss_o(miss),
			.missAddr_o(missAddr_o)
		);			



`ifdef ICACHE
/* Instantiating select instruction, this module generates control signal to 
select 4 contiguous instructions from the 2 read block in a cycle from 
instruction cache. 
*/
SelectInst selectinst(	.pc_i(PC),
			.startBlock_o(startBlock_o),	
			.firstInst_o(firstInst_o)
			);
`endif


/* Following logic generates the next PC. This is the priority encoder and higher priority 
is given to any recovery from Next stage or Execute stage. The least priority is given 
to PC plus 16. 

If there is BTB hit then the target address comes from BTB for the
non-return instruction else comes from the RAS for return instruction.
*/
always @(*)
begin:NEXT_PC
	reg [`SIZE_PC-1:0] pcPlus1;
	reg check0Branch;
	reg check1Branch;
	reg check2Branch;
	reg check3Branch;

	check0Branch  =  ~(btbCtrlType0[0] & btbCtrlType0[1]);
	check1Branch  =  ~(btbCtrlType1[0] & btbCtrlType1[1]);
	check2Branch  =  ~(btbCtrlType2[0] & btbCtrlType2[1]);
	check3Branch  =  ~(btbCtrlType3[0] & btbCtrlType3[1]);

	btbhit0  = btbHit0 & (prediction0 | check0Branch);
	btbhit1  = btbHit1 & (prediction1 | check1Branch);
	btbhit2  = btbHit2 & (prediction2 | check2Branch);
	btbhit3  = btbHit3 & (prediction3 | check3Branch);

	nextPC  = PC + 32;

	casex({flagRecoverEX_i,flagRecoverID_i,btbhit0,btbhit1,btbhit2,btbhit3})
	6'b1xxxxx:
	begin
		nextPC = targetAddrEX_i;
	end
	6'b01xxxx:
	begin
		if(flagRtrID_i)
			nextPC = addrRAS_CP;	
		else
			nextPC = targetAddrID_i;
	end
	6'b001xxx:
	begin
		if(btbCtrlType0 == 2'b00)
			nextPC = addrRAS;
		else
			nextPC = targetAddr0;
	end
	6'b0001xx:
	begin
		if(btbCtrlType1 == 2'b00)
			nextPC = addrRAS;
		else
			nextPC = targetAddr1;
	end
	6'b00001x:
	begin
		if(btbCtrlType2 == 2'b00)
			nextPC = addrRAS;
		else
			nextPC = targetAddr2;
	end
	6'b000001:
	begin
		if(btbCtrlType3 == 2'b00)
			nextPC = addrRAS;
		else
			nextPC = targetAddr3;
	end
	endcase
end



/* Following logic checks if there is any call instruction in the set  
of fetching instructions. If there is any call then the address is 
pushed into the RAS. 
*/
always @(*)
begin:PUSH_RAS
	pushras  = 0; 
	pushaddr = PC;
	casex({btbhit0,btbhit1,btbhit2,btbhit3})
	4'b1xxx:
	begin
		if(btbCtrlType0 == 2'b01)
		begin
			pushras  = 1'b1;
			pushaddr = PC + 8;
		end
	end
	4'b01xx:
	begin
		if(btbCtrlType1 == 2'b01)
		begin
			pushras  = 1'b1;
			pushaddr = PC + 16;
		end
	end
	4'b001x:
	begin
		if(btbCtrlType2 == 2'b01)
		begin
			pushras  = 1'b1;
			pushaddr = PC + 24;
		end
	end
	4'b0001:
	begin
		if(btbCtrlType3 == 2'b01)
		begin
			pushras  = 1'b1;
			pushaddr = PC + 32;
		end
	end
	endcase
end



/* Following logic checks if there is any return instruction in the set
of fetching instructions. If there is any return then the address is
popped from the RAS. 
*/
always @(*)
begin:POP_RAS
popras  = 0;
	casex({btbhit0,btbhit1,btbhit2,btbhit3})
	4'b1xxx:
	begin
		if(btbCtrlType0 == 2'b00)
		begin
			popras  = 1'b1;
		end
	end
	4'b01xx:
	begin
		if(btbCtrlType1 == 2'b00)
		begin
			popras  = 1'b1;
		end
	end
	4'b001x:
	begin
		if(btbCtrlType2 == 2'b00)
		begin
			popras  = 1'b1;
		end
	end
	4'b0001:
	begin
		if(btbCtrlType3 == 2'b00)
		begin
			popras  = 1'b1;
		end
	end
	endcase
end



/* Following drives signals for module's outputs */
assign pc_o 		= PC;
assign btbHit0_o	= btbHit0;
assign targetAddr0_o	= (btbCtrlType0 == 2'b00) ? addrRAS:targetAddr0;
assign prediction0_o	= prediction0;
assign btbHit1_o	= btbHit1;
assign targetAddr1_o	= (btbCtrlType1 == 2'b00) ? addrRAS:targetAddr1;
assign prediction1_o	= prediction1;
assign btbHit2_o	= btbHit2;
assign targetAddr2_o	= (btbCtrlType2 == 2'b00) ? addrRAS:targetAddr2;
assign prediction2_o	= prediction2;
assign btbHit3_o	= btbHit3;
assign targetAddr3_o	= (btbCtrlType3 == 2'b00) ? addrRAS:targetAddr3;
assign prediction3_o	= prediction3;
assign fs1Ready_o    	= ~miss;
assign miss_o        	= miss;

assign addrRAS_CP_o   	= addrRAS_CP;



/* Following updates the nextPC to the Program Counter. 
*/
always @(posedge clk)
begin
	if(reset)
	begin
		`ifdef VERIFY
		PC 	<= $getArchPC();
		`else
		PC      <= 0;
		`endif
	end
	else if(recoverFlag_i)
	begin
		PC 	<= recoverPC_i;
	end
	else if(exceptionFlag_i)
	begin
		PC      <= exceptionPC_i;
	end
	else
	begin
	if(flagRecoverEX_i || ~stall_i) 
		PC 	<= nextPC;
	end 
end


endmodule
