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
# Purpose:  Dispatch module dispatches renamed packets to Issue Queue, Active
#           List, and Load-Store queue.
#           Before dipatching it checks if there is enough space for incoming
#           instructions in Issue Queue, Active List, and Load-Store queue.
#           Dispatch width is same as rename width for the given configuration
#           of the processor.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

module Dispatch( input clk,
                 input reset,
                 input stall_i,
 		 input renameReady_i, // Rename stage is ready with 4-new instruction

		 input flagRecoverEX_i,
                 input ctrlVerified_i,
                 input [`CHECKPOINTS_LOG-1:0] ctrlVerifiedSMTid_i,

                 input [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
			`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
			`SIZE_CTI_LOG:0] renamedPacket0_i,
                 input [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
			`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
			`SIZE_CTI_LOG:0] renamedPacket1_i,
                 input [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
			`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
			`SIZE_CTI_LOG:0] renamedPacket2_i,
                 input [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
			`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
			`SIZE_CTI_LOG:0] renamedPacket3_i,

                 
		 input [`SIZE_LSQ_LOG:0] 	  	loadQueueCnt_i,         // Current count of instructions in Load Queue  
		 input [`SIZE_LSQ_LOG:0] 		storeQueueCnt_i,        // Current count of instructions in Store Queue
                 input [`SIZE_ISSUEQ_LOG:0] 		issueQueueCnt_i,       // Current count of instructions in Issue Queue
                 input [`SIZE_ACTIVELIST_LOG:0] 	activeListCnt_i, // Current count of instructions in Active List


		 output [3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
                         `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+
                         2*`SIZE_PC+`SIZE_CTI_LOG:0] issueqPacket0_o,
                 output [3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
                         `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+
                         2*`SIZE_PC+`SIZE_CTI_LOG:0] issueqPacket1_o,
                 output [3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
                         `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+
                         2*`SIZE_PC+`SIZE_CTI_LOG:0] issueqPacket2_o,
                 output [3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
                         `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+
                         2*`SIZE_PC+`SIZE_CTI_LOG:0] issueqPacket3_o,

                 output [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] alPacket0_o,
                 output [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] alPacket1_o,
                 output [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] alPacket2_o,
                 output [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] alPacket3_o,

		 output [`CHECKPOINTS+`LSQ_FLAGS-1:0] lsqPacket0_o,
		 output [`CHECKPOINTS+`LSQ_FLAGS-1:0] lsqPacket1_o,
		 output [`CHECKPOINTS+`LSQ_FLAGS-1:0] lsqPacket2_o,
		 output [`CHECKPOINTS+`LSQ_FLAGS-1:0] lsqPacket3_o,

		 /******************************************************************
		 * In case of front-end stall and a branch resolves correctly, the 
		 * branch mask of instructions waiting to be latched in back-end
		 * needs to be updated.	 
		 * The updated branch masks are sent to pipeline registers between
		 * the Rename and Dispatch stages. 
		 *******************************************************************/
		 output  [`CHECKPOINTS-1:0] updatedBranchMask0_o,
		 output  [`CHECKPOINTS-1:0] updatedBranchMask1_o,
		 output  [`CHECKPOINTS-1:0] updatedBranchMask2_o,
		 output  [`CHECKPOINTS-1:0] updatedBranchMask3_o,

                 /****************************************************************** 
                 *  If there is no empty space in Issue Queue or Active List or
		 *  Load-Store Queue, then backEndReady_o is low. Instructions  
		 *  reading from the Instructrion Queue should be stalled. Also
		 *  Front End pipe stages (Decode and Rename) after InstructionBuffer
		 *  should be stalled. 
                 *******************************************************************/
                 output backEndReady_o,
		 output stallfrontEnd_o
               ); 





/* wires and regs definition for combinational logic. */
reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
     `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] 
							dispatchPacket0;
reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
     `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] 
							dispatchPacket1;
reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
     `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] 
							dispatchPacket2;
reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
     `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] 
							dispatchPacket3;

reg [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] 	alPacket0;
reg [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] 	alPacket1;
reg [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] 	alPacket2;
reg [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] 	alPacket3;

reg [`CHECKPOINTS+`LSQ_FLAGS-1:0] 			lsqPacket0;
reg [`CHECKPOINTS+`LSQ_FLAGS-1:0] 			lsqPacket1;
reg [`CHECKPOINTS+`LSQ_FLAGS-1:0] 			lsqPacket2;
reg [`CHECKPOINTS+`LSQ_FLAGS-1:0] 			lsqPacket3;



reg 							inst0Load;    
reg 							inst0Store; 
reg 							inst1Load; 
reg 							inst1Store; 
reg 							inst2Load; 
reg 							inst2Store; 
reg 							inst3Load;  
reg 							inst3Store; 
reg [2:0] 						loadCnt;
reg [2:0] 						storeCnt;
wire 							stall0;
wire 							stall1;
wire 							stall2;
wire 							stall3;
wire 							stall4;

reg [`CHECKPOINTS-1:0] 					branch0mask;
reg [`CHECKPOINTS-1:0] 					branch1mask;
reg [`CHECKPOINTS-1:0] 					branch2mask;
reg [`CHECKPOINTS-1:0] 					branch3mask;



/*  Follwoing registers have been defined for functional verification purpose.
 *  Please see below for more details about these registers.
 */
`ifdef VERIFY
`endif




assign backEndReady_o 	  	= ~stall4 & renameReady_i & ~flagRecoverEX_i;
assign stallfrontEnd_o    	= stall4;

assign issueqPacket0_o    	= dispatchPacket0;			
assign issueqPacket1_o    	= dispatchPacket1;			
assign issueqPacket2_o    	= dispatchPacket2;			
assign issueqPacket3_o    	= dispatchPacket3;			

assign alPacket0_o	  	= alPacket0;
assign alPacket1_o	  	= alPacket1;
assign alPacket2_o	  	= alPacket2;
assign alPacket3_o	  	= alPacket3;

assign lsqPacket0_o	  	= lsqPacket0;
assign lsqPacket1_o	  	= lsqPacket1;
assign lsqPacket2_o	  	= lsqPacket2;
assign lsqPacket3_o	  	= lsqPacket3;

assign updatedBranchMask0_o 	= branch0mask;
assign updatedBranchMask1_o 	= branch1mask;
assign updatedBranchMask2_o 	= branch2mask;
assign updatedBranchMask3_o 	= branch3mask;


/*********************************************************************************** 
* Following combinational logic counts the number of LD/ST instructions in the
* incoming set of instructions. 
***********************************************************************************/
always @(*)
begin
  inst0Load   = renamedPacket0_i[1+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
			       `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+
			       2*`SIZE_PC+`SIZE_CTI_LOG];
  inst1Load   = renamedPacket1_i[1+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
			       `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+
			       2*`SIZE_PC+`SIZE_CTI_LOG];
  inst2Load   = renamedPacket2_i[1+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
			       `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+
			       2*`SIZE_PC+`SIZE_CTI_LOG];
  inst3Load   = renamedPacket3_i[1+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
			       `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+
			       2*`SIZE_PC+`SIZE_CTI_LOG];

  loadCnt     = (inst3Load+inst2Load+inst1Load+inst0Load);	

  inst0Store  = renamedPacket0_i[2+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
				`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+
				2*`SIZE_PC+`SIZE_CTI_LOG];
  inst1Store  = renamedPacket1_i[2+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
				`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+
				2*`SIZE_PC+`SIZE_CTI_LOG];
  inst2Store  = renamedPacket2_i[2+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
				`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+
				2*`SIZE_PC+`SIZE_CTI_LOG];
  inst3Store  = renamedPacket3_i[2+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
				`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+
				2*`SIZE_PC+`SIZE_CTI_LOG];

  storeCnt    = (inst3Store+inst2Store+inst1Store+inst0Store);	
end



/* Following updates the branch mask associated with each instruction being
 * dispatched if a control instruction executes and verifies correctly.
 */
always @(*)
begin:UPDATE_BRANCH_MASK
 integer i;
 reg [`CHECKPOINTS-1:0] branch0mask_t;
 reg [`CHECKPOINTS-1:0] branch1mask_t;
 reg [`CHECKPOINTS-1:0] branch2mask_t;
 reg [`CHECKPOINTS-1:0] branch3mask_t;

 branch0mask_t = renamedPacket0_i[`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
				  `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:
				  `CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+
				  `INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1]; 
 branch1mask_t = renamedPacket1_i[`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                                  `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:
                                  `CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+
                                  `INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 branch2mask_t = renamedPacket2_i[`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                                  `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:
                                  `CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+
                                  `INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];
 branch3mask_t = renamedPacket3_i[`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                                  `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:
                                  `CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+
                                  `INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1];

 for(i=0;i<`CHECKPOINTS;i=i+1)
 begin
   if(ctrlVerified_i && (i==ctrlVerifiedSMTid_i))
	branch0mask[i] = 1'b0;
   else
	branch0mask[i] = branch0mask_t[i];
 end

 for(i=0;i<`CHECKPOINTS;i=i+1)
 begin
   if(ctrlVerified_i && (i==ctrlVerifiedSMTid_i))
	branch1mask[i] = 1'b0;
   else
	branch1mask[i] = branch1mask_t[i];
 end

 for(i=0;i<`CHECKPOINTS;i=i+1)
 begin
   if(ctrlVerified_i && (i==ctrlVerifiedSMTid_i))
	branch2mask[i] = 1'b0;
   else
	branch2mask[i] = branch2mask_t[i];
 end

 for(i=0;i<`CHECKPOINTS;i=i+1)
 begin
   if(ctrlVerified_i && (i==ctrlVerifiedSMTid_i))
	branch3mask[i] = 1'b0;
   else
	branch3mask[i] = branch3mask_t[i];
 end
end



/* Following logic checks for empty spaces in Load-Store queue, Issue Queue and 
 * Active List for new instructions.
 */
assign stall0 = ((loadQueueCnt_i  + loadCnt)         > `SIZE_LSQ);
assign stall1 = ((storeQueueCnt_i + storeCnt)        > `SIZE_LSQ);
assign stall2 = ((issueQueueCnt_i + `DISPATCH_WIDTH) > `SIZE_ISSUEQ);
assign stall3 = ((activeListCnt_i + `DISPATCH_WIDTH) > `SIZE_ACTIVELIST);

assign stall4 = (stall0 | stall1 | stall2 | stall3);



/* Following creates instruction packets for back-end stages: Load-Store queue,
 * Issue Queue and Active List
 */
always @(*)
begin:CREATE_BACKEND_PACKET
  
  dispatchPacket0 = {renamedPacket0_i[`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
                     `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
                     `SIZE_CTI_LOG:3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
                     `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
                     `SIZE_CTI_LOG+1],
		     renamedPacket0_i[3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
		     `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG],inst0Store,inst0Load,
	             branch0mask,renamedPacket0_i[`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
	             `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0]};

  dispatchPacket1 = {renamedPacket1_i[`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
                     `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
                     `SIZE_CTI_LOG:3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
                     `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
                     `SIZE_CTI_LOG+1],
	             renamedPacket1_i[3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
	             `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG],inst1Store,inst1Load,
		     branch1mask,renamedPacket1_i[`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
	             `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0]};

   dispatchPacket2 = {renamedPacket2_i[`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
                      `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
                      `SIZE_CTI_LOG:3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
                      `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
                      `SIZE_CTI_LOG+1],
		      renamedPacket2_i[3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
		      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG],inst2Store,inst2Load,
		      branch2mask,renamedPacket2_i[`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
		      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0]};

   dispatchPacket3 = {renamedPacket3_i[`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
                      `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
                      `SIZE_CTI_LOG:3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
                      `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
                      `SIZE_CTI_LOG+1],
		      renamedPacket3_i[3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
		      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG],inst3Store,inst3Load,
		      branch3mask,renamedPacket3_i[`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
		      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0]};


   alPacket0       = {dispatchPacket0[1+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG],
                      dispatchPacket0[2+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG],
                      dispatchPacket0[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket0[`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket0[3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:1+2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket0[4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:1+3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket0[2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1]};

   alPacket1       = {dispatchPacket1[1+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG],
                      dispatchPacket1[2+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG],
                      dispatchPacket1[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket1[`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket1[3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:1+2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket1[4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:1+3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket1[2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1]};

   alPacket2       = {dispatchPacket2[1+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG],
                      dispatchPacket2[2+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG],
                      dispatchPacket2[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket2[`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket2[3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:1+2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket2[4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:1+3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket2[2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1]};

   alPacket3       = {dispatchPacket3[1+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG],
                      dispatchPacket3[2+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG],
                      dispatchPacket3[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket3[`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket3[3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:1+2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket3[4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:1+3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket3[2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1]};
	

   lsqPacket0 	   = {branch0mask,inst0Store,inst0Load};
   lsqPacket1 	   = {branch1mask,inst1Store,inst1Load};
   lsqPacket2 	   = {branch2mask,inst2Store,inst2Load};
   lsqPacket3 	   = {branch3mask,inst3Store,inst3Load};
   
end



/*  Following always block is only for verification purpose. These signals don't
 *  drive anything and has no relevance to the functionality of processor.
 *
 *  Individual values associated with an instruction is extraced from the packet,
 *  so that they can be studied in the waveform and also dumped into a file.
 *  These signals are eventually going to Backend modules which include Issue
 *  Queue, Active List and Load-Store Queue.
 *
 */


endmodule             
               
