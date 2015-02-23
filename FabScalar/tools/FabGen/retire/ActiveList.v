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

/* Algorithm:

   1. Active List is a circular buffer with head and tail pointers. 
      New instructions are written at the tail and old instructions are
      retired from the head.

   2. Receives 4 or 0 new insturctions from the Dispatch stage, along
      with back-end Ready signal. 
	If there is no empty space in Issue Queue or Active List or Load-Store
	Queue, then back-end Ready is low. 

   3. For each new instruction following information should be registered
      into ActiveList RAM:
	(a.) PC of instruction
	(b.) Logical destination register
	(c.) Current physical destination register mapping
	(d.) Old physical destination register mapping
	(e.) Control info -> [Executed, Exception, Mispredict for branches]
      Instruction info (a.,b.,c. & d.) doesn't change over time. Info e. is 
      writen by Functional Unit after the instruction has executed.	

   4. ActiveList ID is generated for each incoming instructions and sent to 
      Issue Queue module and Load-Store Queue module.

   5. Upto 4 instructions are commited each cycle based on the Executed bit   
      associated with each buffer entry.

   6. On a commit, current physical mapping is writen into Arch Map Table
      and old destination physical mapping is freed (written back to Spec
      free list). 

   7. Maintains a total entry counter, which counts number of valid 
      instructions in the ActiveList. The count value is used by the dispatch 
      unit to generate back-end Ready signal. 

   8. If there is a branch mis-predict the tail pointer is rolled back to 
      offending instruction in the ActiveList.

   9. Exception is handled at the head of the ActiveList. On an exception, AMT
      is copied into RMT.


****************************************************************************/



module ActiveList( input clk,
		   input reset,
		   input backEndReady_i,			   

                   /* Active List packet contains following information:
			(6) isInstLoad        "bit-2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG"
			(5) isInst Store      "bit-1+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG"	       	
			(4) Program Counter   "bits-`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1"
			(3) Logical Dest      "bits-`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:2*`SIZE_PHYSICAL_LOG+1"
			(2) Physical Dest     "bits-2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1"
			(1) Old Physical Dest "bits-`SIZE_PHYSICAL_LOG:1"
			(0) Valid Dest        "bit-0"
		   */ 
      		   input [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] alPacket0_i,
      		   input [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] alPacket1_i,
      		   input [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] alPacket2_i,
      		   input [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] alPacket3_i,

		   input validFU0_i,
 		   input [`SIZE_PC-1:0] computedAddr0_i,	
		   input [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU0_i,
		   input validFU1_i,
 		   input [`SIZE_PC-1:0] computedAddr1_i,	
                   input [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU1_i,
		   input validFU2_i, // From Control inst FU
 		   input [`SIZE_PC-1:0] computedAddr2_i,	
                   input [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU2_i,
		   input validFU3_i,
 		   input [`SIZE_PC-1:0] computedAddr3_i,	
                   input [`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:0] ctrlFU3_i,
		   input [`SIZE_ACTIVELIST_LOG:0]   ldViolationPacket_i,		

                   output [`SIZE_ACTIVELIST_LOG-1:0] activeListId0_o,
                   output [`SIZE_ACTIVELIST_LOG-1:0] activeListId1_o,
                   output [`SIZE_ACTIVELIST_LOG-1:0] activeListId2_o,
                   output [`SIZE_ACTIVELIST_LOG-1:0] activeListId3_o,

		   output [`SIZE_ACTIVELIST_LOG:0] activeListCnt_o,

		   output commitValid0_o,
		   output [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] commitPacket0_o,
 		   output commitStore0_o,
 		   output commitLoad0_o,

		   output commitValid1_o,
		   output [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] commitPacket1_o,
 		   output commitStore1_o,
 		   output commitLoad1_o,

		   output commitValid2_o,
		   output [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] commitPacket2_o,
 		   output commitStore2_o,
 		   output commitLoad2_o,

		   output commitValid3_o,
		   output [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] commitPacket3_o,
 		   output commitStore3_o,
 		   output commitLoad3_o,

		   output [`RETIRE_WIDTH-1:0] commitCti_o,

                   output recoverFlag_o,
		   output [`SIZE_PC-1:0] recoverPC_o,	

                   output exceptionFlag_o,
		   output [`SIZE_PC-1:0] exceptionPC_o
);



/* Following declares the Active head pointer and tail pointer.
*/
reg [`SIZE_ACTIVELIST_LOG-1:0] 			headAL;
reg [`SIZE_ACTIVELIST_LOG-1:0] 			tailAL;
reg [`SIZE_ACTIVELIST_LOG:0]			activeListCount;

reg 						recoverFlag;
reg [`SIZE_PC-1:0]                     		recoverPC;
reg 						mispredFlag;
reg [`SIZE_PC-1:0]                     		targetPC;
reg 						exceptionFlag;
reg [`SIZE_PC-1:0]                     		exceptionPC;



/* Following declares Wires and regs for the combinatorial logic.
*/
wire [`SIZE_ACTIVELIST_LOG-1:0] 		tailAddr0;
wire [`SIZE_ACTIVELIST_LOG-1:0] 		tailAddr1;
wire [`SIZE_ACTIVELIST_LOG-1:0] 		tailAddr2;
wire [`SIZE_ACTIVELIST_LOG-1:0] 		tailAddr3;

wire [`SIZE_ACTIVELIST_LOG-1:0] 		headAddr0;
wire [`SIZE_ACTIVELIST_LOG-1:0] 		headAddr1;
wire [`SIZE_ACTIVELIST_LOG-1:0] 		headAddr2;
wire [`SIZE_ACTIVELIST_LOG-1:0] 		headAddr3;

wire [`SIZE_ACTIVELIST_LOG-1:0] 		fuAddr0;
wire 						fuEn0;
wire [`WRITEBACK_FLAGS-1:0] 			fuData0;
wire [`SIZE_ACTIVELIST_LOG-1:0] 		fuAddr1;
wire 						fuEn1;
wire [`WRITEBACK_FLAGS-1:0] 			fuData1;
wire [`SIZE_ACTIVELIST_LOG-1:0] 		fuAddr2;
wire 						fuEn2;
wire [`WRITEBACK_FLAGS-1:0]			fuData2;
wire [`SIZE_ACTIVELIST_LOG-1:0] 		fuAddr3;
wire 						fuEn3;
wire [`WRITEBACK_FLAGS-1:0] 			fuData3;

wire 						ctrlMispredict;
wire 						ctrlMispredict_f;
wire [`SIZE_ACTIVELIST_LOG-1:0]			mispredictEntry;

reg [`SIZE_ACTIVELIST_LOG:0]			activeListCount_f;
reg [`SIZE_ACTIVELIST_LOG-1:0] 			newheadAL;
reg [`SIZE_ACTIVELIST_LOG-1:0] 			tailAL_f;

reg [`COMMIT_WIDTH-1:0]				totalCommit;

reg [`COMMIT_WIDTH-1:0]				commitVector;
reg 						commitValid0;
reg [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] 	commitPacket0;
reg 						commitStore0;
reg 						commitLoad0;
reg						commitFission0;

reg 						commitValid1;
reg [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] 	commitPacket1;
reg 						commitStore1;
reg 						commitLoad1;
reg						commitFission1;

reg 						commitValid2;
reg [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] 	commitPacket2;
reg 						commitStore2;
reg 						commitLoad2;
reg						commitFission2;

reg 						commitValid3;
reg [`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-1:0] 	commitPacket3;
reg 						commitStore3;
reg 						commitLoad3;
reg						commitFission3;

reg [`RETIRE_WIDTH-1:0]				commitCti;


wire [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] dataAl0;
wire [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] dataAl1;
wire [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] dataAl2;
wire [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] dataAl3;

wire [`WRITEBACK_FLAGS-1:0] 			ctrlAl0;
wire [`WRITEBACK_FLAGS-1:0] 			ctrlAl1;
wire [`WRITEBACK_FLAGS-1:0] 			ctrlAl2;
wire [`WRITEBACK_FLAGS-1:0] 			ctrlAl3;

wire [`BRANCH_TYPE-1:0]				ctiType0;
wire [`BRANCH_TYPE-1:0]				ctiType1;
wire [`BRANCH_TYPE-1:0]				ctiType2;
wire [`BRANCH_TYPE-1:0]				ctiType3;
reg [`SIZE_RAS_LOG-1:0] 			tos3;

wire						violateBit0;
wire						violateBit1;
wire						violateBit2;
wire						violateBit3;

wire 						mispredictBit0_f;
wire 						mispredictBit1_f;
wire 						mispredictBit2_f;
wire 						mispredictBit3_f;
wire						violateBit0_f;
wire						violateBit1_f;
wire						violateBit2_f;
wire						violateBit3_f;
wire						exceptionBit0_f;
wire						exceptionBit1_f;
wire						exceptionBit2_f;
wire						exceptionBit3_f;

wire [`SIZE_PC-1:0]				targetAddr0;
wire [`SIZE_PC-1:0]				targetAddr1;
wire [`SIZE_PC-1:0]				targetAddr2;
wire [`SIZE_PC-1:0]				targetAddr3;

`ifdef VERIFY
wire [`SIZE_PC-1:0] 				commitPC0;
wire [`SIZE_PC-1:0] 				commitPC1;
wire [`SIZE_PC-1:0] 				commitPC2;
wire [`SIZE_PC-1:0] 				commitPC3;
reg						commitVerify0;
reg						commitVerify1;
reg 						commitVerify2;
reg						commitVerify3;
integer 					commitCount;
integer 					commitCount_f;
integer 					commitCnt0;
integer 					commitCnt1;
integer 					commitCnt2;
integer 					commitCnt3;
`endif




/************************************************************************************ 
   Following instantiates RAM modules for Active List. 2 seperate RAM modules have
   been instantisted each for static and control information associated with each
   instruction.
   Modules "activeList" and "ctrlActiveList" have different Read/Write ports 
   requirements. "ctrlActiveList" needs additional write ports to write the control
   information when an instruction has completed execution.
************************************************************************************/
SRAM_4R4W #(`SIZE_ACTIVELIST,`SIZE_ACTIVELIST_LOG,2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1)
        activeList ( .clk(clk),
                     .reset(reset | recoverFlag | mispredFlag | exceptionFlag),
		     .addr0_i(headAddr0),
 		     .addr1_i(headAddr1),
		     .addr2_i(headAddr2),
		     .addr3_i(headAddr3),
                     .addr0wr_i(tailAddr0),
		     .we0_i(backEndReady_i),
		     .data0wr_i(alPacket0_i),
                     .addr1wr_i(tailAddr1),
                     .we1_i(backEndReady_i),
                     .data1wr_i(alPacket1_i),
                     .addr2wr_i(tailAddr2),
                     .we2_i(backEndReady_i),
                     .data2wr_i(alPacket2_i),
                     .addr3wr_i(tailAddr3),
                     .we3_i(backEndReady_i),
                     .data3wr_i(alPacket3_i),
                     .data0_o(dataAl0),
                     .data1_o(dataAl1),
                     .data2_o(dataAl2),
                     .data3_o(dataAl3)
		   );


SRAM_4R4W #(`SIZE_ACTIVELIST,`SIZE_ACTIVELIST_LOG,`WRITEBACK_FLAGS)
    ctrlActiveList ( .clk(clk),
                     .reset(reset | violateBit0_f | ctrlMispredict_f | exceptionBit0_f),
                     .addr0_i(headAddr0),
                     .addr1_i(headAddr1),
                     .addr2_i(headAddr2),
                     .addr3_i(headAddr3),
                     .addr0wr_i(fuAddr0),
                     .we0_i(fuEn0),
                     .data0wr_i(fuData0),
                     .addr1wr_i(fuAddr1),
                     .we1_i(fuEn1),
                     .data1wr_i(fuData1),
                     .addr2wr_i(fuAddr2),
                     .we2_i(fuEn2),
                     .data2wr_i(fuData2),
                     .addr3wr_i(fuAddr3),
                     .we3_i(fuEn3),
                     .data3wr_i(fuData3),
                     .data0_o(ctrlAl0),
                     .data1_o(ctrlAl1),
                     .data2_o(ctrlAl2),
                     .data3_o(ctrlAl3)
                   );

/* The "targetAddrActiveList" RAM contain computed target address of control
 * instructions. 
 * The target address is required for the mis-prediction recovery model being
 * supported, currently. The mis-predicted contol instruction is resolved when 
 * it reaches the head of the Active List.
 */
SRAM_4R4W #(`SIZE_ACTIVELIST,`SIZE_ACTIVELIST_LOG,`SIZE_PC)
    targetAddrActiveList ( .clk(clk),
                     .reset(reset | recoverFlag | mispredFlag | exceptionFlag),
                     .addr0_i(headAddr0),
                     .addr1_i(headAddr1),
                     .addr2_i(headAddr2),
                     .addr3_i(headAddr3),
                     .addr0wr_i(fuAddr0),
                     .we0_i(fuEn0),
                     .data0wr_i(computedAddr0_i),
                     .addr1wr_i(fuAddr1),
                     .we1_i(fuEn1),
                     .data1wr_i(computedAddr1_i),
                     .addr2wr_i(fuAddr2),
                     .we2_i(fuEn2),
                     .data2wr_i(computedAddr2_i),
                     .addr3wr_i(fuAddr3),
                     .we3_i(fuEn3),
                     .data3wr_i(computedAddr3_i),
                     .data0_o(targetAddr0),
                     .data1_o(targetAddr1),
                     .data2_o(targetAddr2),
                     .data3_o(targetAddr3)
                   );


SRAM_4R1W #(`SIZE_ACTIVELIST,`SIZE_ACTIVELIST_LOG,1)
    ldViolateVector( .clk(clk),
                     .reset(reset | recoverFlag | mispredFlag | exceptionFlag),
                     .addr0_i(headAddr0),
                     .addr1_i(headAddr1),
                     .addr2_i(headAddr2),
                     .addr3_i(headAddr3),
                     .addr0wr_i(ldViolationPacket_i[`SIZE_ACTIVELIST_LOG:1]),
                     .we0_i(ldViolationPacket_i[0]),
                     .data0wr_i(ldViolationPacket_i[0]),
                     .data0_o(violateBit0),
                     .data1_o(violateBit1),
                     .data2_o(violateBit2),
                     .data3_o(violateBit3)
                   );



/*******************************************************************************
* In case of load violation or control mis-prediction, recover flag is raised to 
* flush the pipeline.
*
* In case of load violation, nextPC is PC of the offending instruction. 
* In case of control mis-prediction, nextPC is the target address.
*******************************************************************************/
assign recoverFlag_o = recoverFlag | mispredFlag;
assign recoverPC_o   = (mispredFlag) ? targetPC:recoverPC;	


/*******************************************************************************
* In case of SYSCALL, exception flag is raised to flush the pipeline. 
* A behavioral code to handle SYSCALL is called.
*******************************************************************************/
assign exceptionFlag_o 	= exceptionFlag;
assign exceptionPC_o	= exceptionPC;


/* Following generates write address for writing into Active List, starting 
 * from the tail.
 */
assign tailAddr0  = tailAL;
assign tailAddr1  = tailAL+1;
assign tailAddr2  = tailAL+2;
assign tailAddr3  = tailAL+3;


/* Following generates read address for reading from Active List, starting 
 * from the head.
 */
assign headAddr0  = headAL;
assign headAddr1  = headAL+1;
assign headAddr2  = headAL+2;
assign headAddr3  = headAL+3;


/* Following extracts write addr, enable and data information from the control
 * packet sent by FU. 
 * The information is written into ctrlActiveList RAM module. 
 */
assign fuAddr0  = ctrlFU0_i[`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:`WRITEBACK_FLAGS]; 
assign fuData0  = ctrlFU0_i[`WRITEBACK_FLAGS-1:0];
assign fuEn0    = validFU0_i; 

assign fuAddr1  = ctrlFU1_i[`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:`WRITEBACK_FLAGS]; 
assign fuData1  = ctrlFU1_i[`WRITEBACK_FLAGS-1:0];
assign fuEn1    = validFU1_i; 

assign fuAddr2  = ctrlFU2_i[`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:`WRITEBACK_FLAGS]; 
assign fuData2  = ctrlFU2_i[`WRITEBACK_FLAGS-1:0];
assign fuEn2    = validFU2_i; 

assign fuAddr3  = ctrlFU3_i[`SIZE_ACTIVELIST_LOG+`WRITEBACK_FLAGS-1:`WRITEBACK_FLAGS]; 
assign fuData3  = ctrlFU3_i[`WRITEBACK_FLAGS-1:0];
assign fuEn3    = validFU3_i; 



assign ctrlMispredict_f  = mispredictBit0_f && ctrlAl0[2];



/* Following generates the active list empty entries count each cycle.
 *  
 * In the normal operation, difference between tail and head pointer (taking warpping into
 * account) is the count.
 *
 * In the case of branch misprediction, differnce between offending instruction's active
 * list ID and head pointer is the count. Active list ID of the offending instruction is
 * sent by the corresponding functional unit.
 */
always @(*)
begin:GENERATE_COUNT
 reg [`SIZE_ACTIVELIST_LOG-1:0] tailAL_mispre;
 reg                            isWrap1;
 reg [`SIZE_ACTIVELIST_LOG-1:0] diff1;
 reg [`SIZE_ACTIVELIST_LOG-1:0] diff2;
 reg [`SIZE_ACTIVELIST_LOG-1:0] cnt1;

 tailAL_f       = (backEndReady_i) ? (tailAL+`DISPATCH_WIDTH):tailAL;
 tailAL_mispre  = mispredictEntry + 1'b1;

 isWrap1        = (newheadAL > tailAL_mispre);

 diff1          =  tailAL_mispre - newheadAL;
 diff2          =  newheadAL     - tailAL_mispre;
 cnt1           = (isWrap1) ? (`SIZE_ACTIVELIST - diff2):diff1;

 activeListCount_f  = (activeListCount+((backEndReady_i) ? `DISPATCH_WIDTH:0))-totalCommit;
end

 

/* Following is the commit logic. Every cycle upto max COMMIT_WIDTH instructions
   can be retired. 
   "Executed" bit associated with each entry is checked from the head pointer. If
   the bit is one, then it is ready to retire (provided preceding entries have this
   bit set to 1). 
   
   IMP: commitValid is set to 1 only if the retiring instruction has a valid 
	destination register. 
 */ 

assign violateBit0_f	= violateBit0 & dataAl0[2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
assign violateBit1_f	= violateBit1 & dataAl1[2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
assign violateBit2_f	= violateBit2 & dataAl2[2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
assign violateBit3_f	= violateBit3 & dataAl3[2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];


/* Control mispredict bit is used to mark the misprediction. 
 * If there is a control instruction mispredicting in the commit group, the 
 * instruction is waited till it reaches head of the Active List. 
 */
assign mispredictBit0_f = ctrlAl0[0];
assign mispredictBit1_f = ctrlAl1[0];
assign mispredictBit2_f = ctrlAl2[0];
assign mispredictBit3_f = ctrlAl3[0];


/* Exception bit is used to mark the system call. If there is a system call 
 * in the commit group, the instruction is waited till it reaches head of 
 * the Active List. Following, an appropriate function (behavioral) is called
 * to handle it.
 */
assign exceptionBit0_f 	= ctrlAl0[1];
assign exceptionBit1_f 	= ctrlAl1[1];
assign exceptionBit2_f 	= ctrlAl2[1];
assign exceptionBit3_f 	= ctrlAl3[1];


always @(*)
begin:COMMIT
reg [`COMMIT_WIDTH-1:0]        commitVector_f;

 newheadAL     	= headAL; 
 totalCommit	= 0;

 commitValid0  	= 0; 
 commitPacket0 	= 0;
 commitStore0  	= 0;
 commitLoad0   	= 0;
 commitFission0 = 0;
	
 commitValid1  	= 0; 
 commitPacket1 	= 0;
 commitStore1  	= 0;
 commitLoad1   	= 0;
 commitFission1 = 0;

 commitValid2  	= 0; 
 commitPacket2 	= 0;
 commitStore2  	= 0;
 commitLoad2   	= 0;
 commitFission2 = 0;

 commitValid3  	= 0; 
 commitPacket3 	= 0;
 commitStore3  	= 0;
 commitLoad3   	= 0;
 commitFission3 = 0;

 commitCti	= 0;

 `ifdef VERIFY
 commitVerify0 	= 0;
 commitVerify1 	= 0;
 commitVerify2 	= 0;
 commitVerify3 	= 0;
 commitCount_f  = commitCount;
 `endif

 commitFission0  = ctrlAl0[3];
 commitFission1  = ctrlAl1[3];
 commitFission2  = ctrlAl2[3];
 commitFission3  = ctrlAl3[3];

 commitVector_f[0] = (activeListCount>0) & ctrlAl0[2] & ~violateBit0_f    & ~exceptionBit0_f;
 commitVector_f[1] = (activeListCount>1) & ctrlAl1[2] & ~mispredictBit1_f & ~mispredictBit0_f & ~violateBit1_f & ~exceptionBit1_f;
 commitVector_f[2] = (activeListCount>2) & ctrlAl2[2] & ~mispredictBit2_f & ~mispredictBit0_f & ~violateBit2_f & ~exceptionBit2_f;
 commitVector_f[3] = (activeListCount>3) & ctrlAl3[2] & ~mispredictBit3_f & ~mispredictBit0_f & ~violateBit3_f & ~exceptionBit3_f;

 /* Following makes sure the fission instrucitons retire together.
  */
 if(commitFission0)
	commitVector[0] = commitVector_f[0] & commitVector_f[1];
 else
	commitVector[0] = commitVector_f[0];

 if(commitFission1)
	commitVector[1] = commitVector_f[1] & commitVector_f[2];
 else
	commitVector[1] = commitVector_f[1];

 if(commitFission2)
	commitVector[2] = commitVector_f[2] & commitVector_f[3];
 else
	commitVector[2] = commitVector_f[2];

 if(commitFission3)
	commitVector[3] = 1'b0;
 else
	commitVector[3] = commitVector_f[3];

 casex(commitVector)
   4'bxx01:
   begin
      	newheadAL     	= headAL+1;    
	totalCommit	= 1;
	
	commitValid0  	= dataAl0[0];
	commitPacket0 	= dataAl0[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:1];
	commitStore0  	= dataAl0[1+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
	commitLoad0   	= dataAl0[2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
 	commitCti[0]	= ctrlAl0[7];

	`ifdef VERIFY
 	commitVerify0 	= 1'b1;
	commitCnt0      = commitCount+1;	
	commitCount_f   = commitCount+1;
	`endif
   end	
   4'bx011:
   begin
        newheadAL     	= headAL+2;
	totalCommit	= 2;

	commitValid0  	= dataAl0[0];
	commitPacket0 	= dataAl0[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:1];
	commitStore0  	= dataAl0[1+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
	commitLoad0   	= dataAl0[2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
 	commitCti[0]	= ctrlAl0[7];

	commitValid1  	= dataAl1[0];
	commitPacket1 	= dataAl1[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:1];
	commitStore1  	= dataAl1[1+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
	commitLoad1   	= dataAl1[2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
 	commitCti[1]	= ctrlAl1[7];

	`ifdef VERIFY
 	commitVerify0 	= 1'b1;
 	commitVerify1 	= 1'b1;
	commitCnt0      = commitCount+1;	
	commitCnt1      = commitCount+2;	
	commitCount_f   = commitCount+2;
	`endif
   end
   4'b0111:
   begin
        newheadAL     	= headAL+3;
	totalCommit	= 3;

	commitValid0  	= dataAl0[0];
	commitPacket0 	= dataAl0[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:1];
	commitStore0  	= dataAl0[1+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
	commitLoad0   	= dataAl0[2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
 	commitCti[0]	= ctrlAl0[7];

	commitValid1  	= dataAl1[0];
	commitPacket1 	= dataAl1[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:1];
	commitStore1  	= dataAl1[1+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
	commitLoad1   	= dataAl1[2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
 	commitCti[1]	= ctrlAl1[7];

	commitValid2  	= dataAl2[0];
	commitPacket2 	= dataAl2[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:1];
	commitStore2  	= dataAl2[1+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
	commitLoad2   	= dataAl2[2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
 	commitCti[2]	= ctrlAl2[7];

	`ifdef VERIFY
 	commitVerify0 	= 1'b1;
 	commitVerify1 	= 1'b1;
 	commitVerify2 	= 1'b1;
	commitCnt0      = commitCount+1;	
	commitCnt1      = commitCount+2;	
	commitCnt2      = commitCount+3;	
	commitCount_f   = commitCount+3;
	`endif
   end
   4'b1111:
   begin
        newheadAL     	= headAL+4;
	totalCommit	= 4;

	commitValid0  	= dataAl0[0];
	commitPacket0 	= dataAl0[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:1];
	commitStore0  	= dataAl0[1+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
	commitLoad0   	= dataAl0[2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
 	commitCti[0]	= ctrlAl0[7];

	commitValid1  	= dataAl1[0];
	commitPacket1 	= dataAl1[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:1];
	commitStore1  	= dataAl1[1+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
	commitLoad1   	= dataAl1[2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
 	commitCti[1]	= ctrlAl1[7];

	commitValid2  	= dataAl2[0];
	commitPacket2 	= dataAl2[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:1];
	commitStore2  	= dataAl2[1+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
	commitLoad2   	= dataAl2[2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
 	commitCti[2]	= ctrlAl2[7];

	commitValid3  	= dataAl3[0];
	commitPacket3 	= dataAl3[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:1];
	commitStore3  	= dataAl3[1+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
	commitLoad3   	= dataAl3[2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG];
 	commitCti[3]	= ctrlAl3[7];

	`ifdef VERIFY
 	commitVerify0 	= 1'b1;
 	commitVerify1 	= 1'b1;
 	commitVerify2 	= 1'b1;
 	commitVerify3 	= 1'b1;
	commitCnt0      = commitCount+1;	
	commitCnt1      = commitCount+2;	
	commitCnt2      = commitCount+3;	
	commitCnt3      = commitCount+4;	
	commitCount_f   = commitCount+4;
	`endif
   end
 endcase
end



/* Following assigns output signals of this module.
 */ 
assign activeListId0_o  = tailAL;
assign activeListId1_o  = tailAL+1;
assign activeListId2_o  = tailAL+2;
assign activeListId3_o  = tailAL+3;

assign activeListCnt_o  = activeListCount;


assign commitValid0_o   = commitValid0;
assign commitPacket0_o  = commitPacket0;
assign commitStore0_o   = commitStore0;
assign commitLoad0_o    = commitLoad0  & commitValid0;

assign commitValid1_o   = commitValid1;
assign commitPacket1_o  = commitPacket1;
assign commitStore1_o   = commitStore1;
assign commitLoad1_o    = commitLoad1  & commitValid1;

assign commitValid2_o   = commitValid2;
assign commitPacket2_o  = commitPacket2;
assign commitStore2_o   = commitStore2;
assign commitLoad2_o    = commitLoad2  & commitValid2;

assign commitValid3_o   = commitValid3;
assign commitPacket3_o  = commitPacket3;
assign commitStore3_o   = commitStore3;
assign commitLoad3_o    = commitLoad3  & commitValid3;

assign commitCti_o	= commitCti;


`ifdef VERIFY
assign commitPC0	= dataAl0[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1];
assign commitPC1	= dataAl1[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1];
assign commitPC2	= dataAl2[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1];
assign commitPC3	= dataAl3[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1];
`endif




/* Following updates the Active List tail pointer:
 * If, there is a branch mispredict, move the tail pointer to the next entry of
 * the offending instruction's entry.
 * Else if, back-end ready signal is high increament the tail pointer by dispatch
 * bandwidth.
 */
always @(posedge clk)
begin
 if(reset || recoverFlag || mispredFlag || exceptionFlag)
 begin
	tailAL  <= 0;
 end
 else
 begin
	tailAL <= tailAL_f;
 end
end


/* Following updates the Active List head pointer:
     newheadAL is computed above depending upto the number of instruction committing
     this cycle.    
*/
always @(posedge clk)
begin
 if(reset || recoverFlag || mispredFlag || exceptionFlag)
 begin
	headAL  <= 0;
 end
 else
 begin
	headAL  <= newheadAL;
 end
end


/*  Follwoing maintains the active list occupancy count each cycle.
 */
always @(posedge clk)
begin
 if(reset || recoverFlag || mispredFlag || exceptionFlag) 
 begin
	activeListCount	<= 0;
 end
 else
 begin
	activeListCount	<= activeListCount_f;
 end
end

 
/*  Following maintains the recover flag register. If the recover flag is high,
 *  it should be treated like an exception. 
 */
always @(posedge clk)
begin
 if(reset || recoverFlag || mispredFlag || exceptionFlag)
 begin
	recoverFlag	<= 1'b0;
	mispredFlag	<= 1'b0;
	exceptionFlag	<= 1'b0;
 end
 else
 begin
	if(ctrlMispredict_f && (|activeListCount))
	begin
		mispredFlag	<= 1'b1;
		targetPC	<= targetAddr0;
		
	end
	if(violateBit0_f && (|activeListCount))
	begin
		recoverFlag	<= 1'b1;
		recoverPC	<= dataAl0[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1];
	end
	if (exceptionBit0_f && (|activeListCount))
	begin
		$display("TRAP Instruction is being committed");
		exceptionFlag   <= 1'b1;
                exceptionPC     <= dataAl0[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1]+8;
	end
 end
end



`ifdef VERIFY
always @(posedge clk)
begin:CLEAR_CTRL_AL
 integer k,l;
 reg [`SIZE_ACTIVELIST_LOG-1:0] cnt;

 if(reset)
 begin
	commitCount 		       <= 0;	
 end
 else
 begin
	commitCount		       <= commitCount_f;
 end

 if(backEndReady_i)
 begin
	ctrlActiveList.sram[tailAddr0] 	<= 0;	
	ctrlActiveList.sram[tailAddr1] 	<= 0;	
	ctrlActiveList.sram[tailAddr2] 	<= 0;	
	ctrlActiveList.sram[tailAddr3] 	<= 0;	

	ldViolateVector.sram[tailAddr0] <= 0;
	ldViolateVector.sram[tailAddr1] <= 0;
	ldViolateVector.sram[tailAddr2] <= 0;
	ldViolateVector.sram[tailAddr3] <= 0;
 end

 if(1'b1)
 begin
	casex({commitVerify3,commitVerify2,commitVerify1,commitVerify0})
		4'bxx01: 	ctrlActiveList.sram[headAddr0] <= 0;
		4'bx011: begin
				ctrlActiveList.sram[headAddr0] <= 0;
				ctrlActiveList.sram[headAddr1] <= 0;
			 end
		4'b0111: begin
                                ctrlActiveList.sram[headAddr0] <= 0;
                                ctrlActiveList.sram[headAddr1] <= 0;
                                ctrlActiveList.sram[headAddr2] <= 0;
                         end
		4'b1111: begin
                                ctrlActiveList.sram[headAddr0] <= 0;
                                ctrlActiveList.sram[headAddr1] <= 0;
                                ctrlActiveList.sram[headAddr2] <= 0;
                                ctrlActiveList.sram[headAddr3] <= 0;
                         end
	endcase
 end
end
`endif

endmodule

