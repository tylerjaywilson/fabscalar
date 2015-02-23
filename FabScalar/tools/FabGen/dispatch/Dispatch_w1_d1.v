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
                 
		 input [`SIZE_LSQ_LOG:0] 	  	loadQueueCnt_i,         // Current count of instructions in Load Queue  
		 input [`SIZE_LSQ_LOG:0] 		storeQueueCnt_i,        // Current count of instructions in Store Queue
                 input [`SIZE_ISSUEQ_LOG:0] 		issueQueueCnt_i,       // Current count of instructions in Issue Queue
                 input [`SIZE_ACTIVELIST_LOG:0] 	activeListCnt_i, // Current count of instructions in Active List


		 output [3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
                         `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+
                         2*`SIZE_PC+`SIZE_CTI_LOG:0] issueqPacket0_o,

                 output [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] alPacket0_o,

		 output [`CHECKPOINTS+`LSQ_FLAGS-1:0] lsqPacket0_o,

		 /******************************************************************
		 * In case of front-end stall and a branch resolves correctly, the 
		 * branch mask of instructions waiting to be latched in back-end
		 * needs to be updated.	 
		 * The updated branch masks are sent to pipeline registers between
		 * the Rename and Dispatch stages. 
		 *******************************************************************/
		 output  [`CHECKPOINTS-1:0] updatedBranchMask0_o,

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

reg [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] 	alPacket0;

reg [`CHECKPOINTS+`LSQ_FLAGS-1:0] 			lsqPacket0;



reg 							inst0Load;    
reg 							inst0Store; 
reg [2:0] 						loadCnt;
reg [2:0] 						storeCnt;
wire 							stall0;
wire 							stall1;
wire 							stall2;
wire 							stall3;
wire 							stall4;

reg [`CHECKPOINTS-1:0]                                  branch0mask;

/*  Follwoing registers have been defined for functional verification purpose.
 *  Please see below for more details about these registers.
 */
`ifdef VERIFY
`endif




assign backEndReady_o 	  	= ~stall4 & renameReady_i & ~flagRecoverEX_i;
assign stallfrontEnd_o    	= stall4;

assign issueqPacket0_o    	= dispatchPacket0;			

assign alPacket0_o	  	= alPacket0;

assign lsqPacket0_o	  	= lsqPacket0;

assign updatedBranchMask0_o 	= branch0mask;


/*********************************************************************************** 
* Following combinational logic counts the number of LD/ST instructions in the
* incoming set of instructions. 
***********************************************************************************/
always @(*)
begin
  inst0Load   = renamedPacket0_i[1+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
			       `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+
			       2*`SIZE_PC+`SIZE_CTI_LOG];

  loadCnt     = (inst0Load);	

  inst0Store  = renamedPacket0_i[2+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
				`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+
				2*`SIZE_PC+`SIZE_CTI_LOG];

  storeCnt    = (inst0Store);	
end



/* Following updates the branch mask associated with each instruction being
 * dispatched if a control instruction executes and verifies correctly.
 */
always @(*)
begin:UPDATE_BRANCH_MASK
 integer i;
 reg [`CHECKPOINTS-1:0] branch0mask_t;

 branch0mask_t = renamedPacket0_i[`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
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


   alPacket0       = {dispatchPacket0[1+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG],
                      dispatchPacket0[2+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+
                      `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG],
                      dispatchPacket0[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket0[`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket0[3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:1+2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket0[4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:1+3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1],
                      dispatchPacket0[2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1]};


   lsqPacket0 	   = {branch0mask,inst0Store,inst0Load};
   
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
               
