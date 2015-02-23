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
# Purpose: This module is used for verification purpose.
# Author:  FabGen
*******************************************************************************/


`timescale 1ns/100ps
//`define ARCH_RAS
//`define PRINT
//`define PRINT_EVERYTHING

module simulate();

parameter PRINT_CNT =  0;
parameter STAT_DISPLAY_INTERVAL = 1000000;
parameter SIM_COUNT =  100000000;


parameter CLKPERIOD =  10;

reg clock;
reg reset;

reg [`SIZE_DATA-1:0] LOGICAL_REG [`SIZE_RMT-1:0];
reg [`SIZE_PC-1:0] archRAS [`SIZE_RAS-1:0];
reg [`SIZE_RAS_LOG-1:0] archTos;

integer sim_count;
integer fd0;
integer fd1;
integer fd2;
integer fd3;
integer fd4;
integer fd5;
integer fd6;
integer fd7;
integer fd8;
integer fd9;
integer fd10;
integer fd11;
integer fd12;
integer fd13;
integer fd14;
integer fd15;
integer fd16;

integer fd17;

integer i;
integer last_commit_cnt;

integer load_violation_count;
integer br_count;
integer br_mispredict_count;
integer ld_count;
integer btb_miss;
integer btb_miss_rtn;
integer fetch1_stall;
integer ctiq_stall;
integer instBuf_stall;
integer freelist_stall;
integer smt_stall;
integer backend_stall;
integer rob_stall;
integer iq_stall;
integer ldq_stall;
integer stq_stall;

real ipc;

// Following defines the clock for the simulation.
always 
begin 
 #(CLKPERIOD/2) clock = ~clock;
end

always @(posedge clock)
begin
  sim_count = sim_count+1;
  //if(sim_count == SIM_COUNT)
  //	$finish();

  if(fabScalar.activeList.commitCount > 10000000)
  begin

	ipc = $itor(fabScalar.activeList.commitCount)/$itor(sim_count);

	// Before the simulator is terminated, print all the stats:
	$display(" Fetch1-Stall:%d \n Ctiq-Stall:%d \n InstBuff-Stall:%d \n FreeList-Stall:%d \n SMT-Stall:%d \n Backend-Stall:%d \n LDQ-Stall:%d \n STQ-Stall:%d \n IQ-Stall:%d \n ROB-Stall:%d\n",
                        fetch1_stall,
                        ctiq_stall,
                        instBuf_stall,
                        freelist_stall,
                        smt_stall,
                        backend_stall,
                        ldq_stall,
                        stq_stall,
                        iq_stall,
                        rob_stall);

	$display("Cycle Count:%d Commit Count:%d    IPC:%2.2f     BTB-Miss:%d BTB-Miss-Rtn:%d  Br-Count:%d Br-Mispredict:%d Ld Count:%d Ld Violation:%d",
                        sim_count,
                        fabScalar.activeList.commitCount,
						ipc,
                        btb_miss,
                        btb_miss_rtn,
                        br_count,
                        br_mispredict_count,
			ld_count,
			load_violation_count);
	$finish;
  end		
end


initial
begin:Processor_Initialization
 integer i;
 

 reset = 0;
 
 load_violation_count 	= 0;
 br_count 		= 0;
 br_mispredict_count    = 0;
 ld_count 		= 0;
 btb_miss		= 0;
 btb_miss_rtn		= 0;
 fetch1_stall		= 0;
 ctiq_stall		= 0;
 instBuf_stall		= 0;
 freelist_stall		= 0;
 smt_stall		= 0;
 backend_stall		= 0;	
 rob_stall		= 0;
 iq_stall		= 0;
 ldq_stall		= 0;
 stq_stall		= 0;

 fd9 	= $fopen("results/fetch1_o.txt","w");
 fd14 	= $fopen("results/fetch2_o.txt","w");
 fd2 	= $fopen("results/decode_o.txt","w");
 fd1	= $fopen("results/instBuf_o.txt","w");
 fd0 	= $fopen("results/rename_o.txt","w");
 fd3 	= $fopen("results/dispatch_o.txt","w");
 fd4 	= $fopen("results/select_o.txt","w");
 fd5 	= $fopen("results/wakeup_o.txt","w");
 fd6 	= $fopen("results/regread_o.txt","w");
 fd13 	= $fopen("results/fu0_o.txt","w");
 fd12 	= $fopen("results/fu2_o.txt","w");
 fd11 	= $fopen("results/fu3_o.txt","w");
 fd7 	= $fopen("results/commit_o.txt","w");
 fd10 	= $fopen("results/lsu_o.txt","w");
 fd8 	= $fopen("results/writebk_o.txt","w");

 fd15 	= $fopen("results/predictor_o.txt","w");
 fd16 	= $fopen("results/statistics_o.txt","w");

 fd17 	= $fopen("results/test_o.txt","w");
 $initialize_sim();
 $copyMemory();


  $display("");
  $display("");
  $display("**********   ******   ********     *******    ********   ******   ****         ******   ********  ");
  $display("*        *  *      *  *       *   *      *   *       *  *      *  *  *        *      *  *       * ");
  $display("*  ******* *   **   * *  ***   * *   *****  *   ****** *   **   * *  *       *   **   * *  ***   *");
  $display("*  *       *  *  *  * *  *  *  * *  *       *  *       *  *  *  * *  *       *  *  *  * *  *  *  *");
  $display("*  *****   *  ****  * *  ***   * *   ****   *  *       *  ****  * *  *       *  ****  * *  ***   *");
  $display("*      *   *        * *       *   *      *  *  *       *        * *  *       *        * *       * ");
  $display("*  *****   *  ****  * *  ***   *   ****   * *  *       *  ****  * *  *       *  ****  * *  ***   *");
  $display("*  *       *  *  *  * *  *  *  *       *  * *  *       *  *  *  * *  *       *  *  *  * *  *  *  *");
  $display("*  *       *  *  *  * *  ***   *  *****   * *   ****** *  *  *  * *  ******* *  *  *  * *  *  *  *");
  $display("*  *       *  *  *  * *       *   *      *   *       * *  *  *  * *        * *  *  *  * *  *  *  *");
  $display("****       ****  **** ********    *******     ******** ****  **** ********** ****  **** ****  ****");
  $display("");
  $display("FabScalar Copyright (c) 2007-2011 by Niket K. Choudhary, Salil Wadhavkar, and Eric Rotenberg.");  
  $display("All Rights Reserved.");
  $display("");
  $display("");

 for(i=0;i<`SIZE_RMT-2;i=i+1) 
 begin
 	fabScalar.reg_read.PhyRegFile1.sram[i] = $getArchRegValue(i);
	LOGICAL_REG[i]			      = $getArchRegValue(i);	
 end
	fabScalar.reg_read.PhyRegFile1.sram[32] = $getArchRegValue(65);
	fabScalar.reg_read.PhyRegFile1.sram[33] = $getArchRegValue(64);
 	LOGICAL_REG[32]		= $getArchRegValue(65);
 	LOGICAL_REG[33]		= $getArchRegValue(64);
	

 $funcsimRunahead();

 // Initialize architectural RAS
 archTos = 0;
 for(i=0;i<`SIZE_RAS;i=i+1)
 	archRAS[i] = 0;

 sim_count = 0;
 clock = 0;
 #1 reset = 1;
 
 #(CLKPERIOD-4) reset = 0;
end


FABSCALAR fabScalar(.clock(clock),
		    .reset(reset),
		    .wrL1ICacheEnable_i(1'b0),
		    .wrAddrL1ICache_i(`PHYSICAL_ADDR'b0),
		    .wrBlockL1ICache_i(),
		    .missL1ICache_o(),
  		    .missAddrL1ICache_o()		
		   );	


`ifdef PRINT_EVERYTHING
/*****************************************
 * PRINTING OF EVERYTHING, CYCLE BY CYCLE
 * ***************************************/
integer fdfull;

initial
begin: PRINT_FULL_FILE_OPEN
	fdfull = $fopen("/tmp/jgandhi/full.txt", "w");
end

always @(posedge clock)
begin: PRINT_FULL
	integer i;

	if(sim_count > PRINT_CNT)
	begin
		$fwrite(fdfull,"----------------------------------------------------------------------\n");
		$fwrite(fdfull, "CYCLE:%d ", sim_count);
		if(fabScalar.issueq.ctrlVerified_i && fabScalar.issueq.ctrlMispredict_i)
			$fwrite(fdfull, "MISPREDICT with %04b at ALid:%d", (1 << fabScalar.issueq.ctrlSMTid_i), fabScalar.activeList.mispredictEntry);
		else if(fabScalar.rename.ctrlVerified_i)
			$fwrite(fdfull, "VERIFIED with %04b", (1 << fabScalar.rename.ctrlVerifiedSMTid_i));
		$fwrite(fdfull, "\n");
		$fwrite(fdfull,"----------------------------------------------------------------------\n");
		$fwrite(fdfull, "\n");

/* */
		///////////
		// DECODE
		///////////
		$fwrite(fdfull, "DECODE:\n");

		$fwrite(fdfull, "inst0PacketValid_i:%h\n", fabScalar.decode.inst0PacketValid_i);

		$fwrite(fdfull, "decodedPacketValid:%b\n", fabScalar.decode.decodedPacketValid);

		$fwrite(fdfull, "decodedPacket_f:%b\n\n", fabScalar.decode.decodedPacket_f[0]);

		$fwrite(fdfull, "decodedVector_o:%b\n", fabScalar.decode.decodedVector_o);
		
		$fwrite(fdfull, "decodedPacket0_o:%h\n", fabScalar.decode.decodedPacket0_o);
		$fwrite(fdfull, "decodedPacket1_o:%h\n", fabScalar.decode.decodedPacket1_o);
		$fwrite(fdfull, "decodedPacket2_o:%h\n", fabScalar.decode.decodedPacket2_o);
		$fwrite(fdfull, "decodedPacket3_o:%h\n", fabScalar.decode.decodedPacket3_o);
		$fwrite(fdfull, "decodedPacket4_o:%h\n", fabScalar.decode.decodedPacket4_o);
		$fwrite(fdfull, "decodedPacket5_o:%h\n", fabScalar.decode.decodedPacket5_o);
		$fwrite(fdfull, "decodedPacket6_o:%h\n", fabScalar.decode.decodedPacket6_o);
		$fwrite(fdfull, "decodedPacket7_o:%h\n", fabScalar.decode.decodedPacket7_o);
		$fwrite(fdfull, "decodedPacket8_o:%h\n", fabScalar.decode.decodedPacket8_o);
		$fwrite(fdfull, "decodedPacket9_o:%h\n", fabScalar.decode.decodedPacket9_o);
		$fwrite(fdfull, "decodedPacket10_o:%h\n", fabScalar.decode.decodedPacket10_o);
		$fwrite(fdfull, "decodedPacket11_o:%h\n", fabScalar.decode.decodedPacket11_o);
		$fwrite(fdfull, "decodedPacket12_o:%h\n", fabScalar.decode.decodedPacket12_o);
		$fwrite(fdfull, "decodedPacket13_o:%h\n", fabScalar.decode.decodedPacket13_o);
		$fwrite(fdfull, "decodedPacket14_o:%h\n", fabScalar.decode.decodedPacket14_o);
		$fwrite(fdfull, "decodedPacket15_o:%h\n", fabScalar.decode.decodedPacket15_o);

		$fwrite(fdfull, "\n\n");
// */

/* */
		//////////////////////
		// INSTRUCTION-BUFFER
		//////////////////////
		$fwrite(fdfull, "INSTRUCTION BUFFER:\n");

		$fwrite(fdfull, "head:%d tail:%d\n", fabScalar.instBuf.headPtr, fabScalar.instBuf.tailPtr);

		if(fabScalar.instBuf.writeEnable0)
			$fwrite(fdfull, "decodedPacket0_i:%h\n", fabScalar.instBuf.decodedPacket0_i);
		if(fabScalar.instBuf.writeEnable1)
			$fwrite(fdfull, "decodedPacket1_i:%h\n", fabScalar.instBuf.decodedPacket1_i);
		if(fabScalar.instBuf.writeEnable2)
			$fwrite(fdfull, "decodedPacket2_i:%h\n", fabScalar.instBuf.decodedPacket2_i);
		if(fabScalar.instBuf.writeEnable3)
			$fwrite(fdfull, "decodedPacket3_i:%h\n", fabScalar.instBuf.decodedPacket3_i);
		if(fabScalar.instBuf.writeEnable4)
			$fwrite(fdfull, "decodedPacket4_i:%h\n", fabScalar.instBuf.decodedPacket4_i);
		if(fabScalar.instBuf.writeEnable5)
			$fwrite(fdfull, "decodedPacket5_i:%h\n", fabScalar.instBuf.decodedPacket5_i);
		if(fabScalar.instBuf.writeEnable6)
			$fwrite(fdfull, "decodedPacket6_i:%h\n", fabScalar.instBuf.decodedPacket6_i);
		if(fabScalar.instBuf.writeEnable7)
			$fwrite(fdfull, "decodedPacket7_i:%h\n", fabScalar.instBuf.decodedPacket7_i);
		if(fabScalar.instBuf.writeEnable8)
			$fwrite(fdfull, "decodedPacket8_i:%h\n", fabScalar.instBuf.decodedPacket8_i);
		if(fabScalar.instBuf.writeEnable9)
			$fwrite(fdfull, "decodedPacket9_i:%h\n", fabScalar.instBuf.decodedPacket9_i);
		if(fabScalar.instBuf.writeEnable10)
			$fwrite(fdfull, "decodedPacket10_i:%h\n", fabScalar.instBuf.decodedPacket10_i);
		if(fabScalar.instBuf.writeEnable11)
			$fwrite(fdfull, "decodedPacket11_i:%h\n", fabScalar.instBuf.decodedPacket11_i);
		if(fabScalar.instBuf.writeEnable12)
			$fwrite(fdfull, "decodedPacket12_i:%h\n", fabScalar.instBuf.decodedPacket12_i);
		if(fabScalar.instBuf.writeEnable13)
			$fwrite(fdfull, "decodedPacket13_i:%h\n", fabScalar.instBuf.decodedPacket13_i);
		if(fabScalar.instBuf.writeEnable14)
			$fwrite(fdfull, "decodedPacket14_i:%h\n", fabScalar.instBuf.decodedPacket14_i);
		if(fabScalar.instBuf.writeEnable15)
			$fwrite(fdfull, "decodedPacket15_i:%h\n", fabScalar.instBuf.decodedPacket15_i);
		$fwrite(fdfull, "\n");

		$fwrite(fdfull, "decodedPacket0_o:%h\n", fabScalar.instBuf.decodedPacket0_o);

		$fwrite(fdfull, "\n\n");
		

/* */
		///////////
		// RENAME 
		//////////
		
		$fwrite(fdfull, "RENAME:\n");

		// decodedPacket(n)_i
		$fwrite(fdfull, "decodedPacket0_i:%h\n", fabScalar.rename.decodedPacket0_i);

		// renamedPacket(n)_i
		$fwrite(fdfull, "renamedPacket0_o:%h\n", fabScalar.rename.renamedPacket0_o);

		// newDestMap
		//if(fabScalar.newDestMap0[0] == 1'b1) $fwrite(fdfull, "%d ", fabScalar.newDestMap0[`SIZE_PHYSICAL_LOG:1]);
		//if(fabScalar.newDestMap1[0] == 1'b1) $fwrite(fdfull, "%d ", fabScalar.newDestMap1[`SIZE_PHYSICAL_LOG:1]);
		//if(fabScalar.newDestMap2[0] == 1'b1) $fwrite(fdfull, "%d ", fabScalar.newDestMap2[`SIZE_PHYSICAL_LOG:1]);
		//if(fabScalar.newDestMap3[0] == 1'b1) $fwrite(fdfull, "%d ", fabScalar.newDestMap3[`SIZE_PHYSICAL_LOG:1]);

		$fwrite(fdfull, "\n\n");
// */

/* /
		///////////////////
		// RENAME-DISPATCH
		///////////////////
		$fwrite(fdfull, "RENAME-DISPATCH:\n");

		$fwrite(fdfull, "reset:%b flush_i:%b stall_i:%b\n", fabScalar.renDis.reset, fabScalar.renDis.flush_i, fabScalar.renDis.stall_i);
		$fwrite(fdfull, "renamedPacket0_i:%b\n", fabScalar.renDis.renamedPacket0_i);
		$fwrite(fdfull, "renamedPacket0_o:%b\n", fabScalar.renDis.renamedPacket0_o);

		$fwrite(fdfull, "\n");
// */

		////////////
		// DISPATCH
		////////////
		$fwrite(fdfull, "DISPATCH:\n");
		$fwrite(fdfull, "stall0:%b stall1:%b stall2:%b stall3:%b \n", fabScalar.dispatch.stall0, fabScalar.dispatch.stall1, fabScalar.dispatch.stall2, fabScalar.dispatch.stall3);
		$fwrite(fdfull, "stall4:%b renameReady_i:%b flagRecoverEX_i:%b\n", fabScalar.dispatch.stall4, fabScalar.dispatch.renameReady_i, fabScalar.dispatch.flagRecoverEX_i);
		$fwrite(fdfull, "loadQueueCnt_i:%d loadCnt:%d storeQueueCnt_i:%d storeCnt:%d\n", fabScalar.dispatch.loadQueueCnt_i, fabScalar.dispatch.loadCnt, fabScalar.dispatch.storeQueueCnt_i, fabScalar.dispatch.storeCnt);
		$fwrite(fdfull, "inst(n)Load:%b%b%b%b%b%b%b%b\n", fabScalar.dispatch.inst0Load, fabScalar.dispatch.inst1Load, fabScalar.dispatch.inst2Load, fabScalar.dispatch.inst3Load, fabScalar.dispatch.inst4Load, fabScalar.dispatch.inst5Load, fabScalar.dispatch.inst6Load, fabScalar.dispatch.inst7Load);
		$fwrite(fdfull, "inst(n)Store:%b%b%b%b%b%b%b%b\n", fabScalar.dispatch.inst0Store, fabScalar.dispatch.inst1Store, fabScalar.dispatch.inst2Store, fabScalar.dispatch.inst3Store, fabScalar.dispatch.inst4Store, fabScalar.dispatch.inst5Store, fabScalar.dispatch.inst6Store, fabScalar.dispatch.inst7Store);
		$fwrite(fdfull, "renamedPacket0_i:%h\n", fabScalar.dispatch.renamedPacket0_i);
		$fwrite(fdfull, "\n");

/* /
		/////////////////
		// ISSUE QUEUE
		/////////////////
		$fwrite(fdfull, "ISSUE QUEUE:\n");
		for(i=0; i<`SIZE_ISSUEQ; i=i+1)
		begin
			if(fabScalar.issueq.ISSUEQ_VALID[i])
			begin
				$fwrite(fdfull, "%2d) ", i);

				// ALid
				$fwrite(fdfull, "ALid:%4d ", fabScalar.issueq.ISSUEQ_PAYLOAD[i][`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1]);

				// pc
				$fwrite(fdfull, "pc:%h ", fabScalar.issueq.ISSUEQ_PAYLOAD[i][`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1]);
			
				// FU
				$fwrite(fdfull, "fu%d ", fabScalar.issueq.ISSUEQ_FU[i]);
	
				// scheduled bit
				if(fabScalar.issueq.ISSUEQ_SCHEDULED[i])
					$fwrite(fdfull, "sched ");
				else
					$fwrite(fdfull, "----- ");
				
				// request bit
				if(fabScalar.issueq.requestVector0[i])
					$fwrite(fdfull, "req0 ");
				else if(fabScalar.issueq.requestVector1[i])
					$fwrite(fdfull, "req1 ");
				else if(fabScalar.issueq.requestVector2[i])
					$fwrite(fdfull, "req2 ");
				else if(fabScalar.issueq.requestVector3[i])
					$fwrite(fdfull, "req3 ");
				else
					$fwrite(fdfull, "---- ");
	
				// grant bit
				if(fabScalar.issueq.grantedValid0_o && (fabScalar.issueq.grantedEntry0 == i))
					$fwrite(fdfull, "grant0 ");
				else if(fabScalar.issueq.grantedValid1_o && (fabScalar.issueq.grantedEntry1 == i))
					$fwrite(fdfull, "grant1 ");
				else if(fabScalar.issueq.grantedValid2_o && (fabScalar.issueq.grantedEntry2 == i))
					$fwrite(fdfull, "grant2 ");
				else if(fabScalar.issueq.grantedValid3_o && (fabScalar.issueq.grantedEntry3 == i))
					$fwrite(fdfull, "grant3 ");
				else
					$fwrite(fdfull, "------ ");
	
				// freed bit
				if(fabScalar.issueq.freedValid0 && (fabScalar.issueq.freedEntry0 == i))
					$fwrite(fdfull, "freed0 ");
				else if(fabScalar.issueq.freedValid1 && (fabScalar.issueq.freedEntry1 == i))
					$fwrite(fdfull, "freed1 ");
				else if(fabScalar.issueq.freedValid2 && (fabScalar.issueq.freedEntry2 == i))
					$fwrite(fdfull, "freed2 ");
				else if(fabScalar.issueq.freedValid3 && (fabScalar.issueq.freedEntry3 == i))
					$fwrite(fdfull, "freed3 ");
				else
					$fwrite(fdfull, "------ ");
	
				// branch mask
				$fwrite(fdfull, "mask:%b ", fabScalar.issueq.BRANCH_MASK[i]);

				// Source valid (= ready) bits
				$fwrite(fdfull, "ready:%b%b ", fabScalar.issueq.SRC0_REG_VALID[i], fabScalar.issueq.SRC1_REG_VALID[i]);

				// Source tags
				$fwrite(fdfull, "(%d,%d) ", fabScalar.issueq.SRC_REGS[i][`SIZE_PHYSICAL_LOG-1:0], fabScalar.issueq.SRC_REGS[i][2*`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG]);
	
				$fwrite(fdfull, "\n");
			end
		end // for loop for the issue queue

		$fwrite(fdfull, "\n");


		////////
		// RSR 
		////////
		$fwrite(fdfull, "RSR:\n");
		
		if(fabScalar.issueq.rsr0TagValid) $fwrite(fdfull, "rsr0Tag:%d\n", fabScalar.issueq.rsr0Tag);
		if(fabScalar.issueq.rsr1TagValid) $fwrite(fdfull, "rsr1Tag:%d\n", fabScalar.issueq.rsr1Tag);
		if(fabScalar.issueq.rsr2TagValid) $fwrite(fdfull, "rsr2Tag:%d\n", fabScalar.issueq.rsr2Tag);
		if(fabScalar.issueq.rsr3Tag_i[0]) $fwrite(fdfull, "rsr3Tag:%d\n", fabScalar.issueq.rsr3Tag_i[`SIZE_PHYSICAL_LOG:1]);

		// This is a cross-check
		$fwrite(fdfull, "\n");
		if(fabScalar.rsr0TagValid) $fwrite(fdfull, "rsr0Tag:%d\n", fabScalar.rsr0Tag);
		if(fabScalar.rsr1TagValid) $fwrite(fdfull, "rsr1Tag:%d\n", fabScalar.rsr1Tag);
		if(fabScalar.rsr2TagValid) $fwrite(fdfull, "rsr2Tag:%d\n", fabScalar.rsr2Tag);


		$fwrite(fdfull, "\n");

		///////////////////////
		// PHYSICAL READY BITS 
		///////////////////////

		$fwrite(fdfull, "PHYSICAL READY:\n");

		for(i=0; i<`SIZE_PHYSICAL_TABLE; i=i+1)
		begin
			if(fabScalar.issueq.phyRegRdy_i[i] == 1'b1)
				$fwrite(fdfull, "%3d ", i);

			if(i%10==9)
				$fwrite(fdfull, "\n");
		end

		$fwrite(fdfull, "\n");
// */

		////////
		// LSU
		///////
		$fwrite(fdfull, "LSU:\n");
		
		// Counts


		$fwrite(fdfull, "\n");


		///////////////
		// ACTIVE LIST 
		///////////////
		$fwrite(fdfull, "ACTIVE LIST:\n");

		// target addr
		$fwrite(fdfull, "reset:%b recoverFlag:%b mispredFlag%b exceptionFlag:%b (recoverFlag_o:%b) PC:%h targetPC:%h recoverPC:%h\n", fabScalar.activeList.reset, fabScalar.activeList.recoverFlag, fabScalar.activeList.mispredFlag, fabScalar.activeList.exceptionFlag, fabScalar.activeList.recoverFlag_o, fabScalar.activeList.recoverPC_o, fabScalar.activeList.targetPC, fabScalar.activeList.recoverPC);
		$fwrite(fdfull, "head:%d tail:%d\n", fabScalar.activeList.headAL, fabScalar.activeList.tailAL);
		$fwrite(fdfull, "backEndReady_i:%b\n", fabScalar.activeList.backEndReady_i);

		for(i=0; i<`SIZE_ACTIVELIST; i=i+1)
		begin
			// Take care to print only between head and tail
			if( (fabScalar.activeList.headAL > fabScalar.activeList.tailAL && (i < fabScalar.activeList.tailAL || i >= fabScalar.activeList.headAL)) ||
			    (fabScalar.activeList.headAL <  fabScalar.activeList.tailAL && (i >= fabScalar.activeList.headAL && i <  fabScalar.activeList.tailAL)) )
			begin

				$fwrite(fdfull, "%4d) ", i);

				// isLoad and isStore
				if(fabScalar.activeList.activeList.sram[i][2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:1+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1])
					$fwrite(fdfull, "load  ");
				else if(fabScalar.activeList.activeList.sram[i][1+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1])
					$fwrite(fdfull, "store ");
				else
					$fwrite(fdfull, "----- ");
	
				// pc
				$fwrite(fdfull, "pc:%h ", fabScalar.activeList.activeList.sram[i][`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1]);

				// flags
				if(fabScalar.activeList.ctrlActiveList.sram[i][0])
					$fwrite(fdfull, "mispre ");
				else
					$fwrite(fdfull, "------ ");

				if(fabScalar.activeList.ctrlActiveList.sram[i][1])
					$fwrite(fdfull, "except ");
				else
					$fwrite(fdfull, "------ ");

				if(fabScalar.activeList.ctrlActiveList.sram[i][2])
					$fwrite(fdfull, "exec ");
				else
					$fwrite(fdfull, "---- ");

				if(fabScalar.activeList.ctrlActiveList.sram[i][3])
					$fwrite(fdfull, "fission ");
				else
					$fwrite(fdfull, "------- ");

				$fwrite(fdfull, "\n");
			end // if condition so that 'i' is between head and tail
		end // for loop for active list

		$fwrite(fdfull, "\n");
		$fwrite(fdfull, "Packet:%h Execution Flags:%b Active List: %d Valid:%b\n",
		fabScalar.execute.exePacket6_o,
		fabScalar.execute.exePacket6_o[`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC-1:`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC],
		fabScalar.execute.exePacket6_o[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC-1:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC],
		fabScalar.execute.exePacketValid6_o);
		

	end // clock cycle condition
end // always @(posedge clock) for PRINT_FULL

`endif // `ifdef PRINT_EVERYTHING


`ifdef PRINT

always @(posedge clock)
begin:TEST
 integer i;
 if(sim_count>PRINT_CNT)
 begin
  $fwrite(fd17,"CYCLE=%d\n",sim_count);
  $fwrite(fd17,"----------------------------------------------------------------------\n");
  /*$fwrite(fd17,"in:  updateEn:%b\n",fabScalar.fs2dec.updateEn_i);
  $fwrite(fd17,"out: updateEn:%b\n",fabScalar.fs2dec.updateEn_o);
  $fwrite(fd17,"FS1: updateEn:%b\n",fabScalar.fs1.updateEn_i);*/
  $fwrite(fd17,"tos:%d  tos_cp:%d\n",fabScalar.fs1.ras.tos,fabScalar.fs1.ras.tos_CP);

  $fwrite(fd17,"push_i:%b  pop_i:%b  flagRecoverID_i:%b  flagCallID_i:%b  callPCID_i:%x  flagRtrID_i:%b  addrRAS_o:%x\n",
  fabScalar.fs1.ras.push_i,fabScalar.fs1.ras.pop_i,fabScalar.fs1.ras.flagRecoverID_i,
  fabScalar.fs1.ras.flagCallID_i,fabScalar.fs1.ras.callPCID_i,fabScalar.fs1.ras.flagRtrID_i,
  fabScalar.fs1.ras.addrRAS_o);

  for(i=0;i<`SIZE_RAS;i=i+1)
     $fwrite(fd17,"RAS[%d]: %x\n",i,fabScalar.fs1.ras.stack[i]);
  $fwrite(fd17,"\n");
 end
end

/*  Prints fetch1 stage related latches in a file every cycle.
 */
always @(posedge clock)
begin:FETCH1
 if((sim_count>PRINT_CNT))
 begin
 $fwrite(fd9,"CYCLE=%d\n",sim_count);
 $fwrite(fd9,"----------------------------------------------------------------------\n");
 
 if(fabScalar.fs1.flagRecoverEX_i)
 	$fwrite(fd9,"Branch Mispredict: Correct PC=%h\n",fabScalar.fs1.targetAddrEX_i);

 if(fabScalar.fs1.stall_i)
	$fwrite(fd9,"Fetch-1 is stalled.....\n");
 
 $fwrite(fd9,"PC=%h nextPC=%h\n",fabScalar.fs1.PC,fabScalar.fs1.nextPC);

 /* printing BTB access information. */
 if(fabScalar.fs1.btbHit0)
	$fwrite(fd9,"BTB hit for PC0:%h Ctrl Type:%b Target Addr:%h direction:%b\n",fabScalar.fs1.PC,
		fabScalar.fs1.btbCtrlType0,fabScalar.fs1.targetAddr0,fabScalar.fs1.prediction0_o);
 if(fabScalar.fs1.btbHit1)
	$fwrite(fd9,"BTB hit for PC1:%h Ctrl Type:%b Target Addr:%h direction:%b\n",(fabScalar.fs1.PC+8),
		fabScalar.fs1.btbCtrlType1,fabScalar.fs1.targetAddr1,fabScalar.fs1.prediction1_o);
 if(fabScalar.fs1.btbHit2)
	$fwrite(fd9,"BTB hit for PC2:%h Ctrl Type:%b Target Addr:%h direction:%b\n",(fabScalar.fs1.PC+16),
		fabScalar.fs1.btbCtrlType2,fabScalar.fs1.targetAddr2,fabScalar.fs1.prediction2_o);
 if(fabScalar.fs1.btbHit3)
	$fwrite(fd9,"BTB hit for PC3:%h Ctrl Type:%b Target Addr:%h direction:%b\n",(fabScalar.fs1.PC+24),
		fabScalar.fs1.btbCtrlType3,fabScalar.fs1.targetAddr3,fabScalar.fs1.prediction3_o);

  if(fabScalar.fs1.ras.pop_i)
	$fwrite(fd9,"BTB hit for Rtr instr, TOS:%d, Pop Addr: %x",fabScalar.fs1.ras.tos,fabScalar.fs1.ras.addrRAS_o);
   if(fabScalar.fs1.ras.push_i)
        $fwrite(fd9,"BTB hit for CALL instr, Push Addr: %x",fabScalar.fs1.ras.pushAddr_i);

  $fwrite(fd9,"RAS POP Addr:%x   CP-RAS Pop Addr:%x\n",fabScalar.fs1.ras.addrRAS_o,fabScalar.fs1.ras.addrRAS_CP_o);

 /* printing the BTB and BPB update information. */
 if(fabScalar.fs1.btb.updateEn_i)
 begin
	$fwrite(fd9,"\nbtb update info.....\n");
	$fwrite(fd9,"update PC:%h Target Addr:%h Ctrl Type:%b\n",
		fabScalar.fs1.btb.updatePC_i,
		fabScalar.fs1.btb.updateTargetAddr_i,
		fabScalar.fs1.btb.updateBrType_i);
 end

 if(fabScalar.fs1.flagRecoverID_i)
 	$fwrite(fd9,"Fetch-2 fix BTB miss (target addr): %h\n",fabScalar.fs1.targetAddrID_i);

 end
end



/* Prints fetch2/Ctrl Queue related latches in a file every cycle.
 */
always @(posedge clock)
begin:FETCH2
 if((sim_count>PRINT_CNT))
 begin
 $fwrite(fd14,"CYCLE=%d\n",sim_count);
 $fwrite(fd14,"----------------------------------------------------------------------\n");
 if(fabScalar.fs2.ctiQueue.stall_i) $fwrite(fd14,"Fetch2 is stalled ....");
 if(fabScalar.fs2.ctiQueueFull_o)   $fwrite(fd14,"CTI Queue is full ....");

 $fwrite(fd14,"Control vector:%b fs1Ready:%b\n",fabScalar.fs2.ctiQueue.ctrlVector_i,
	 fabScalar.fs2.ctiQueue.fs1Ready_i);
 $fwrite(fd14,"PC0:%h Ctrl Type0:%b Prediction:%b \n PC1:%h Ctrl Type1:%b Prediction:%b \n PC2:%h Ctrl Type2:%b Prediction:%b \n PC3:%h Ctrl Type3:%b Prediction:%b\n",
	 fabScalar.fs2.ctiQueue.pc0_i,fabScalar.fs2.ctiQueue.inst0CtrlType_i,fabScalar.fs2.prediction0_i,
	 fabScalar.fs2.ctiQueue.pc1_i,fabScalar.fs2.ctiQueue.inst1CtrlType_i,fabScalar.fs2.prediction1_i,
	 fabScalar.fs2.ctiQueue.pc2_i,fabScalar.fs2.ctiQueue.inst2CtrlType_i,fabScalar.fs2.prediction2_i,
	 fabScalar.fs2.ctiQueue.pc3_i,fabScalar.fs2.ctiQueue.inst3CtrlType_i,fabScalar.fs2.prediction3_i);

 $fwrite(fd14,"ctiq Tag0:%d ctiq Tag1:%d ctiq Tag2:%d ctiq Tag3:%d\n",
	 fabScalar.fs2.ctiQueue.ctiqTag0_o,
	 fabScalar.fs2.ctiQueue.ctiqTag1_o,
	 fabScalar.fs2.ctiQueue.ctiqTag2_o,
	 fabScalar.fs2.ctiQueue.ctiqTag3_o);	
 
 if(fabScalar.fs2.ctiQueue.ctrlVerified_i)
 begin
	$fwrite(fd14,"\nwriting back a control instruction.....\n");
	$fwrite(fd14,"ctiq index:%d target addr:%h br outcome:%b\n",fabScalar.fs2.ctiQueue.ctiQueueIndex_i,
		fabScalar.fs2.ctiQueue.targetAddr_i,fabScalar.fs2.ctiQueue.branchOutcome_i);
 end

 if(fabScalar.fs2.ctiQueue.recoverFlag_i)
	$fwrite(fd14,"Recovery Flag is High....\n");

 if(fabScalar.fs2.ctiQueue.updateEn_o)
 begin
	$fwrite(fd14,"\nupdating the BTB and BPB.....\n");
	$fwrite(fd14,"PC:%h Target Addr:%h Ctrl Type:%b Direction:%b\n",fabScalar.fs2.ctiQueue.updatePC_o,
		fabScalar.fs2.ctiQueue.updateTarAddr_o,fabScalar.fs2.ctiQueue.updateCtrlType_o,fabScalar.fs2.updateDir_o);
 end

 $fwrite(fd14,"ctiq=> headptr:%d tailptr:%d commitPtr:%d instcount:%d commitCnt:%d\n",fabScalar.fs2.ctiQueue.headPtr,
	 fabScalar.fs2.ctiQueue.tailPtr,fabScalar.fs2.ctiQueue.commitPtr,
	 fabScalar.fs2.ctiQueue.ctrlCount, fabScalar.fs2.ctiQueue.commitCnt);

 $fwrite(fd14,"ctiq commit vec:%b\n",fabScalar.fs2.ctiQueue.ctiqCommitted);


 //check in branch predictor if the update is being done correctly.
 $fwrite(fd15,"CYCLE=%d\n",sim_count);
 if(fabScalar.fs1.bp.updateEn_i) 
 begin
	$fwrite(fd15,"\nBPB update.....\n");
	$fwrite(fd15,"PC:%h Direction:%b\n",fabScalar.fs1.bp.updatePC_i,fabScalar.fs1.bp.updateDir_i);
 end

 end
end



/*  Prints decode stage related latches in a file every cycle.
 */
always @(posedge clock)
begin:DECODE
 if(sim_count > PRINT_CNT)
 begin
 $fwrite(fd2,"CYCLE=%d\n",sim_count);
 $fwrite(fd2,"----------------------------------------------------------------------\n");
 $fwrite(fd2,"Fetch2 Ready: %b\n",fabScalar.decode.fs2Ready_i);

   if(fabScalar.decode.inst0PacketValid_i)
   begin
 	$fwrite(fd2,"inst0 pc:0x%h opcode:0x%2h ",fabScalar.decode.decode0_PISA.pc,
					 fabScalar.decode.decode0_PISA.opcode);
 	if(fabScalar.decode.decode0_PISA.instDest_0[0]) 
   		$fwrite(fd2,"dest_0:%d ",fabScalar.decode.decode0_PISA.instDest_0[`SIZE_RMT_LOG:1]);
 	if(fabScalar.decode.decode0_PISA.instLogical1_0[0]) 
   		$fwrite(fd2,"src1_0:%d ",fabScalar.decode.decode0_PISA.instLogical1_0[`SIZE_RMT_LOG:1]);
 	if(fabScalar.decode.decode0_PISA.instLogical2_0[0]) 
   		$fwrite(fd2,"src2_0:%d",fabScalar.decode.decode0_PISA.instLogical2_0[`SIZE_RMT_LOG:1]);
 	$fwrite(fd2,"\n");
   end
   if(fabScalar.decode.inst1PacketValid_i)
   begin
        $fwrite(fd2,"inst1 pc:0x%h opcode:0x%2h ",fabScalar.decode.decode1_PISA.pc,
                                         fabScalar.decode.decode1_PISA.opcode);
        if(fabScalar.decode.decode1_PISA.instDest_0[0])
                $fwrite(fd2,"dest_0:%d ",fabScalar.decode.decode1_PISA.instDest_0[`SIZE_RMT_LOG:1]);
        if(fabScalar.decode.decode1_PISA.instLogical1_0[0])
                $fwrite(fd2,"src1_0:%d ",fabScalar.decode.decode1_PISA.instLogical1_0[`SIZE_RMT_LOG:1]);
        if(fabScalar.decode.decode1_PISA.instLogical2_0[0])
                $fwrite(fd2,"src2_0:%d",fabScalar.decode.decode1_PISA.instLogical2_0[`SIZE_RMT_LOG:1]);
        $fwrite(fd2,"\n");
   end
   if(fabScalar.decode.inst2PacketValid_i)
   begin
        $fwrite(fd2,"inst2 pc:0x%h opcode:0x%2h ",fabScalar.decode.decode2_PISA.pc,
                                         fabScalar.decode.decode2_PISA.opcode);
        if(fabScalar.decode.decode2_PISA.instDest_0[0])
                $fwrite(fd2,"dest_0:%d ",fabScalar.decode.decode2_PISA.instDest_0[`SIZE_RMT_LOG:1]);
        if(fabScalar.decode.decode0_PISA.instLogical1_0[0])
                $fwrite(fd2,"src1_0:%d ",fabScalar.decode.decode2_PISA.instLogical1_0[`SIZE_RMT_LOG:1]);
        if(fabScalar.decode.decode2_PISA.instLogical2_0[0])
                $fwrite(fd2,"src2_0:%d",fabScalar.decode.decode2_PISA.instLogical2_0[`SIZE_RMT_LOG:1]);
        $fwrite(fd2,"\n");
   end
   if(fabScalar.decode.inst3PacketValid_i)
   begin
        $fwrite(fd2,"inst3 pc:0x%h opcode:0x%2h ",fabScalar.decode.decode3_PISA.pc,
                                         fabScalar.decode.decode3_PISA.opcode);
        if(fabScalar.decode.decode3_PISA.instDest_0[0])
                $fwrite(fd2,"dest_0:%d ",fabScalar.decode.decode3_PISA.instDest_0[`SIZE_RMT_LOG:1]);
        if(fabScalar.decode.decode3_PISA.instLogical1_0[0])
                $fwrite(fd2,"src1_0:%d ",fabScalar.decode.decode3_PISA.instLogical1_0[`SIZE_RMT_LOG:1]);
        if(fabScalar.decode.decode3_PISA.instLogical2_0[0])
                $fwrite(fd2,"src2_0:%d",fabScalar.decode.decode3_PISA.instLogical2_0[`SIZE_RMT_LOG:1]);
        $fwrite(fd2,"\n");
   end
 end
end


/*  Prints Instruction Buffer stage related latches in a file every cycle.
 */
always @(posedge clock)
begin:INSTBUF
 if((sim_count>PRINT_CNT))
 begin
 $fwrite(fd1,"CYCLE=%d\n",sim_count);
 $fwrite(fd1,"----------------------------------------------------------------------\n");
 $fwrite(fd1,"Inst Buffer Full:%b freelistEmpty:%b stallFrontEnd:%b\n",
	 fabScalar.instBuf.stallFetch,fabScalar.freeListEmpty,fabScalar.stallfrontEnd);

 $fwrite(fd1,"\n");

 $fwrite(fd1,"Decode Ready=%b\n",fabScalar.instBuf.decodeReady_i);
 if(fabScalar.instBuf.decodedVector_i[0]) 
	$fwrite(fd1,"fs2 PC0=%h\n",fabScalar.instBuf.decodedPacket0_i[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1]);
 if(fabScalar.instBuf.decodedVector_i[1]) 
	$fwrite(fd1,"fs2 PC1=%h\n",fabScalar.instBuf.decodedPacket1_i[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1]);
 if(fabScalar.instBuf.decodedVector_i[2]) 
	$fwrite(fd1,"fs2 PC2=%h\n",fabScalar.instBuf.decodedPacket2_i[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1]);
 if(fabScalar.instBuf.decodedVector_i[3]) 
	$fwrite(fd1,"fs2 PC3=%h\n",fabScalar.instBuf.decodedPacket3_i[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1]);
 if(fabScalar.instBuf.decodedVector_i[4])
        $fwrite(fd1,"fs2 PC4=%h\n",fabScalar.instBuf.decodedPacket4_i[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1]);
 if(fabScalar.instBuf.decodedVector_i[5])
        $fwrite(fd1,"fs2 PC5=%h\n",fabScalar.instBuf.decodedPacket5_i[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1]);
 if(fabScalar.instBuf.decodedVector_i[6])
        $fwrite(fd1,"fs2 PC6=%h\n",fabScalar.instBuf.decodedPacket6_i[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1]);
 if(fabScalar.instBuf.decodedVector_i[7])
        $fwrite(fd1,"fs2 PC7=%h\n",fabScalar.instBuf.decodedPacket7_i[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1]);

 $fwrite(fd1,"instbuffer head=%d instbuffer tail=%d inst count=%d\n",fabScalar.instBuf.headPtr,
	 fabScalar.instBuf.tailPtr,fabScalar.instBuf.instCount);

 $fwrite(fd1,"instBufferReady_o:%b\n",fabScalar.instBuf.instBufferReady_o); 
 $fwrite(fd1,"reset_ib:%b\n",fabScalar.instBuf.reset); 
 $fwrite(fd1,"reset_ib_sram:%b\n",fabScalar.instBuf.instBuffer.reset); 
 //if(fabScalar.instBuf.instBufferReady_o)
 //begin
/*	 $fwrite(fd1,"decodedPacket0:%h\n",fabScalar.instBuf.decodedPacket0);
	 $fwrite(fd1,"decodedPacket1:%h\n",fabScalar.instBuf.decodedPacket1);
	 $fwrite(fd1,"decodedPacket2:%h\n",fabScalar.instBuf.decodedPacket2);
	 $fwrite(fd1,"decodedPacket3:%h\n",fabScalar.instBuf.decodedPacket3);*/
 //end
 for(i=0;i<`INST_QUEUE;i=i+1)
 begin
	$fwrite(fd1,"instbuffer[%d] PC=%h\n",i,fabScalar.instBuf.instBuffer.sram[i]);
 end  
 $fwrite(fd1,"\n");
 end
end


/*  Prints rename stage related latches in a file every cycle.
 */
always @(posedge clock)
begin:RENAME
 if(sim_count > PRINT_CNT)
 begin
 $fwrite(fd0,"CYCLE=%d\n",sim_count);
 $fwrite(fd0,"----------------------------------------------------------------------\n");
 $fwrite(fd0,"Decode Ready=%b Branch Count=%d\n",fabScalar.rename.decodeReady_i,fabScalar.rename.branchCount_i);

 $fwrite(fd0,"freeListEmpty=%b\n",fabScalar.rename.freeListEmpty);

 $fwrite(fd0,"specfreelist: headptr=%d tailptr=%d freelist cnt=%d freelist top=%d committed no=%d\n",
	 fabScalar.rename.specfreelist.freeListHead,
	 fabScalar.rename.specfreelist.freeListTail,fabScalar.rename.specfreelist.freeListCnt,
	 fabScalar.rename.specfreelist.FREE_LIST.sram[fabScalar.rename.specfreelist.freeListHead],
	 fabScalar.rename.specfreelist.pushNumber);
 
 for(i=0;i<32;i=i+4)
 begin
	$fwrite(fd0,"RMT[%d]=%d RMT[%d]=%d RMT[%d]=%d RMT[%d]=%d\n",i,fabScalar.rename.RMT.RenameMap.sram[i],
		i+1,fabScalar.rename.RMT.RenameMap.sram[i+1],i+2,fabScalar.rename.RMT.RenameMap.sram[i+2],
		i+3,fabScalar.rename.RMT.RenameMap.sram[i+3]);	 
 end

 // following is for debugging Branch mask and checkpoint logic.
 /*if(fabScalar.rename.SMT.branchVector[0] == 1'b1)
 begin
	$fwrite(fd0,"\n");
  for(i=0;i<32;i=i+4)
  begin
        $fwrite(fd0,"SMT0[%d]=%d SMT0[%d]=%d SMT0[%d]=%d SMT0[%d]=%d\n",i,fabScalar.rename.SMT.SMT0[i],
                i+1,fabScalar.rename.SMT.SMT0[i+1],i+2,fabScalar.rename.SMT.SMT0[i+2],
                i+3,fabScalar.rename.SMT.SMT0[i+3]);
  end
 end
 
 if(fabScalar.rename.SMT.branchVector[1] == 1'b1)
 begin
	$fwrite(fd0,"\n");
  for(i=0;i<32;i=i+4)
  begin
        $fwrite(fd0,"SMT1[%d]=%d SMT1[%d]=%d SMT1[%d]=%d SMT1[%d]=%d\n",i,fabScalar.rename.SMT.SMT1[i],
                i+1,fabScalar.rename.SMT.SMT1[i+1],i+2,fabScalar.rename.SMT.SMT1[i+2],
                i+3,fabScalar.rename.SMT.SMT1[i+3]);
  end
 end

 if(fabScalar.rename.SMT.branchVector[2] == 1'b1)
 begin
	$fwrite(fd0,"\n");
  for(i=0;i<32;i=i+4)
  begin
        $fwrite(fd0,"SMT2[%d]=%d SMT2[%d]=%d SMT2[%d]=%d SMT2[%d]=%d\n",i,fabScalar.rename.SMT.SMT2[i],
                i+1,fabScalar.rename.SMT.SMT2[i+1],i+2,fabScalar.rename.SMT.SMT2[i+2],
                i+3,fabScalar.rename.SMT.SMT2[i+3]);
  end
 end

 if(fabScalar.rename.SMT.branchVector[3] == 1'b1)
 begin
	$fwrite(fd0,"\n");
  for(i=0;i<32;i=i+4)
  begin
        $fwrite(fd0,"SMT3[%d]=%d SMT3[%d]=%d SMT3[%d]=%d SMT3[%d]=%d\n",i,fabScalar.rename.SMT.SMT3[i],
                i+1,fabScalar.rename.SMT.SMT3[i+1],i+2,fabScalar.rename.SMT.SMT3[i+2],
                i+3,fabScalar.rename.SMT.SMT3[i+3]);
  end
 end*/

 $fwrite(fd0,"renamed packet0 PC:%h Branch Mask=%b\n",fabScalar.rename.renamedPacket0_o[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1],
		fabScalar.rename.renamedPacket0_o[`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1]);
 $fwrite(fd0,"renamed packet1 PC:%h Branch Mask=%b\n",fabScalar.rename.renamedPacket1_o[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1],
		fabScalar.rename.renamedPacket1_o[`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1]);
 $fwrite(fd0,"renamed packet2 PC:%h Branch Mask=%b\n",fabScalar.rename.renamedPacket2_o[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1],
		fabScalar.rename.renamedPacket2_o[`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1]);
 $fwrite(fd0,"renamed packet3 PC:%h Branch Mask=%b\n",fabScalar.rename.renamedPacket3_o[2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1],
		fabScalar.rename.renamedPacket3_o[`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1]);
 $fwrite(fd0,"rename ready:%b\n",fabScalar.rename.renameReady_o);

 $fwrite(fd0,"freelist pop info...\n");
 $fwrite(fd0,"addr0=%d pop reg0=%d\n",fabScalar.rename.specfreelist.readAddr0,fabScalar.rename.specfreelist.freeReg0_o[7:1]);
 $fwrite(fd0,"addr1=%d pop reg1=%d\n",fabScalar.rename.specfreelist.readAddr1,fabScalar.rename.specfreelist.freeReg1_o[7:1]);
 $fwrite(fd0,"addr2=%d pop reg2=%d\n",fabScalar.rename.specfreelist.readAddr2,fabScalar.rename.specfreelist.freeReg2_o[7:1]);
 $fwrite(fd0,"addr3=%d pop reg3=%d\n",fabScalar.rename.specfreelist.readAddr3,fabScalar.rename.specfreelist.freeReg3_o[7:1]);

 $fwrite(fd0,"commit info...\n");
 if(fabScalar.rename.specfreelist.commitValid0_i)
 $fwrite(fd0,"commit reg0=%d\n",fabScalar.rename.specfreelist.commitReg0_i);
 if(fabScalar.rename.specfreelist.commitValid1_i)
 $fwrite(fd0,"commit reg1=%d\n",fabScalar.rename.specfreelist.commitReg1_i);
 if(fabScalar.rename.specfreelist.commitValid2_i)
 $fwrite(fd0,"commit reg2=%d\n",fabScalar.rename.specfreelist.commitReg2_i);
 if(fabScalar.rename.specfreelist.commitValid3_i)
 $fwrite(fd0,"commit reg3=%d\n",fabScalar.rename.specfreelist.commitReg3_i);

 $fwrite(fd0,"\n");
 end
end


/* Prints dispatch related signals and latch value. 
 */
always @(posedge clock)
begin:DISPATCH
 if(sim_count > PRINT_CNT)
 begin
 $fwrite(fd3,"CYCLE=%d\n",sim_count);
 $fwrite(fd3,"----------------------------------------------------------------------\n");

 $fwrite(fd3,"load cnt=%d store cnt=%d\n",fabScalar.dispatch.loadCnt,fabScalar.dispatch.storeCnt);

 $fwrite(fd3,"Updated Branch Mask\n");
 $fwrite(fd3,"inst0 branch mask=%b\n",fabScalar.dispatch.branch0mask);
 $fwrite(fd3,"inst1 branch mask=%b\n",fabScalar.dispatch.branch1mask);
 $fwrite(fd3,"inst2 branch mask=%b\n",fabScalar.dispatch.branch2mask);
 $fwrite(fd3,"inst3 branch mask=%b\n",fabScalar.dispatch.branch3mask);

 $fwrite(fd3,"Backend Ready:%b\n",fabScalar.dispatch.backEndReady_o); 
 $fwrite(fd3,"al packet0 PC:%h\n",fabScalar.dispatch.alPacket0[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1]); 
 $fwrite(fd3,"al packet1 PC:%h\n",fabScalar.dispatch.alPacket1[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1]); 
 $fwrite(fd3,"al packet2 PC:%h\n",fabScalar.dispatch.alPacket2[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1]); 
 $fwrite(fd3,"al packet3 PC:%h\n",fabScalar.dispatch.alPacket3[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1]); 

 if(fabScalar.dispatch.stall0) $fwrite(fd3,"LDQ Stall\n");
 if(fabScalar.dispatch.stall1) $fwrite(fd3,"STQ Stall\n");
 if(fabScalar.dispatch.stall2) $fwrite(fd3,"IQ Stall: IQ Cnt:%d\n",fabScalar.dispatch.issueQueueCnt_i);
 if(fabScalar.dispatch.stall3) $fwrite(fd3,"Active List Stall\n");
 
 /*$fwrite(fd3,"Print values for Inst-0\n"); 
 	$fwrite(fd3,"Branch Direction=%b Ctiq Tag=%b Target Addr=0x%h\n",
		fabScalar.disBackend.vr_inst0BrDir,fabScalar.disBackend.vr_inst0CtiqTag,
		fabScalar.disBackend.vr_inst0TarAddr);
	$fwrite(fd3,"PC=0x%h Opcode=0x%2h FU Type=%b\n",fabScalar.disBackend.vr_inst0PC,
		fabScalar.disBackend.vr_inst0Opcode,fabScalar.disBackend.vr_inst0FuType);
	$fwrite(fd3,"LD/ST Type=%b Immd Valid=%d Immd=0x%h\n",fabScalar.disBackend.vr_inst0LdStType,
		fabScalar.disBackend.vr_inst0ImmdValid,fabScalar.disBackend.vr_inst0Immd);
	$fwrite(fd3,"SrcReg1 Valid=%b SrcReg1=%d SrcReg2 Valid=%b SrcReg2=%d\n",
		fabScalar.disBackend.vr_inst0srcReg1Valid,fabScalar.disBackend.vr_inst0srcReg1,
		fabScalar.disBackend.vr_inst0srcReg2Valid,fabScalar.disBackend.vr_inst0srcReg2);
 	$fwrite(fd3,"DestReg Valid=%b DestReg=%d SMT Id=%d Branch Mask=%b\n",
		fabScalar.disBackend.vr_inst0DestRegValid,fabScalar.disBackend.vr_inst0DestReg,
		fabScalar.disBackend.vr_inst0SMTid,fabScalar.disBackend.vr_inst0BranchMask);
	$fwrite(fd3,"isLoad=%b isStore=%b isBranch=%b DestReg Logical=%d\n",
		fabScalar.disBackend.vr_inst0Load,fabScalar.disBackend.vr_inst0Store,
		fabScalar.disBackend.vr_inst0Branch,fabScalar.disBackend.vr_inst0DestLogical);
 $fwrite(fd3,"\n",);

 $fwrite(fd3,"Print values for Inst-1\n");
        $fwrite(fd3,"Branch Direction=%b Ctiq Tag=%b Target Addr=0x%h\n",
                fabScalar.disBackend.vr_inst1BrDir,fabScalar.disBackend.vr_inst1CtiqTag,
                fabScalar.disBackend.vr_inst1TarAddr);
        $fwrite(fd3,"PC=0x%h Opcode=0x%2h FU Type=%b\n",fabScalar.disBackend.vr_inst1PC,
                fabScalar.disBackend.vr_inst1Opcode,fabScalar.disBackend.vr_inst1FuType);
        $fwrite(fd3,"LD/ST Type=%b Immd Valid=%d Immd=0x%h\n",fabScalar.disBackend.vr_inst1LdStType,
                fabScalar.disBackend.vr_inst1ImmdValid,fabScalar.disBackend.vr_inst1Immd);
        $fwrite(fd3,"SrcReg1 Valid=%b SrcReg1=%d SrcReg2 Valid=%b SrcReg2=%d\n",
                fabScalar.disBackend.vr_inst1srcReg1Valid,fabScalar.disBackend.vr_inst1srcReg1,
                fabScalar.disBackend.vr_inst1srcReg2Valid,fabScalar.disBackend.vr_inst1srcReg2);
        $fwrite(fd3,"DestReg Valid=%b DestReg=%d SMT Id=%d Branch Mask=%b\n",
                fabScalar.disBackend.vr_inst1DestRegValid,fabScalar.disBackend.vr_inst1DestReg,
                fabScalar.disBackend.vr_inst1SMTid,fabScalar.disBackend.vr_inst1BranchMask);
        $fwrite(fd3,"isLoad=%b isStore=%b isBranch=%b DestReg Logical=%d\n",
                fabScalar.disBackend.vr_inst1Load,fabScalar.disBackend.vr_inst1Store,
                fabScalar.disBackend.vr_inst1Branch,fabScalar.disBackend.vr_inst1DestLogical);
 $fwrite(fd3,"\n",);

 $fwrite(fd3,"Print values for Inst-2\n");
        $fwrite(fd3,"Branch Direction=%b Ctiq Tag=%b Target Addr=0x%h\n",
                fabScalar.disBackend.vr_inst2BrDir,fabScalar.disBackend.vr_inst2CtiqTag,
                fabScalar.disBackend.vr_inst2TarAddr);
        $fwrite(fd3,"PC=0x%h Opcode=0x%2h FU Type=%b\n",fabScalar.disBackend.vr_inst2PC,
                fabScalar.disBackend.vr_inst2Opcode,fabScalar.disBackend.vr_inst2FuType);
        $fwrite(fd3,"LD/ST Type=%b Immd Valid=%d Immd=0x%h\n",fabScalar.disBackend.vr_inst2LdStType,
                fabScalar.disBackend.vr_inst2ImmdValid,fabScalar.disBackend.vr_inst2Immd);
        $fwrite(fd3,"SrcReg1 Valid=%b SrcReg1=%d SrcReg2 Valid=%b SrcReg2=%d\n",
                fabScalar.disBackend.vr_inst2srcReg1Valid,fabScalar.disBackend.vr_inst2srcReg1,
                fabScalar.disBackend.vr_inst2srcReg2Valid,fabScalar.disBackend.vr_inst2srcReg2);
        $fwrite(fd3,"DestReg Valid=%b DestReg=%d SMT Id=%d Branch Mask=%b\n",
                fabScalar.disBackend.vr_inst2DestRegValid,fabScalar.disBackend.vr_inst2DestReg,
                fabScalar.disBackend.vr_inst2SMTid,fabScalar.disBackend.vr_inst2BranchMask);
        $fwrite(fd3,"isLoad=%b isStore=%b isBranch=%b DestReg Logical=%d\n",
                fabScalar.disBackend.vr_inst2Load,fabScalar.disBackend.vr_inst2Store,
                fabScalar.disBackend.vr_inst2Branch,fabScalar.disBackend.vr_inst2DestLogical);
 $fwrite(fd3,"\n",);

 $fwrite(fd3,"Print values for Inst-3\n");
        $fwrite(fd3,"Branch Direction=%b Ctiq Tag=%b Target Addr=0x%h\n",
                fabScalar.disBackend.vr_inst3BrDir,fabScalar.disBackend.vr_inst3CtiqTag,
                fabScalar.disBackend.vr_inst3TarAddr);
        $fwrite(fd3,"PC=0x%h Opcode=0x%2h FU Type=%b\n",fabScalar.disBackend.vr_inst3PC,
                fabScalar.disBackend.vr_inst3Opcode,fabScalar.disBackend.vr_inst3FuType);
        $fwrite(fd3,"LD/ST Type=%b Immd Valid=%d Immd=0x%h\n",fabScalar.disBackend.vr_inst3LdStType,
                fabScalar.disBackend.vr_inst3ImmdValid,fabScalar.disBackend.vr_inst3Immd);
        $fwrite(fd3,"SrcReg1 Valid=%b SrcReg1=%d SrcReg2 Valid=%b SrcReg2=%d\n",
                fabScalar.disBackend.vr_inst3srcReg1Valid,fabScalar.disBackend.vr_inst3srcReg1,
                fabScalar.disBackend.vr_inst3srcReg2Valid,fabScalar.disBackend.vr_inst3srcReg2);
        $fwrite(fd3,"DestReg Valid=%b DestReg=%d SMT Id=%d Branch Mask=%b\n",
                fabScalar.disBackend.vr_inst3DestRegValid,fabScalar.disBackend.vr_inst3DestReg,
                fabScalar.disBackend.vr_inst3SMTid,fabScalar.disBackend.vr_inst3BranchMask);
        $fwrite(fd3,"isLoad=%b isStore=%b isBranch=%b DestReg Logical=%d\n",
                fabScalar.disBackend.vr_inst3Load,fabScalar.disBackend.vr_inst3Store,
                fabScalar.disBackend.vr_inst3Branch,fabScalar.disBackend.vr_inst3DestLogical);
 */
 $fwrite(fd3,"\n",);
 end
end



/* Prints wakeup (issue queue) related signals and latch value.
 */ /*
always @(posedge clock)
begin:WAKEUP
 reg [`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] pc0;
 reg [`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] pc1;
 reg [`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] pc2;
 reg [`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] pc3;
 integer i;
 integer k;
 if(sim_count > PRINT_CNT)
 begin
 $fwrite(fd5,"CYCLE=%d\n",sim_count);
 $fwrite(fd5,"----------------------------------------------------------------------\n");

 $fwrite(fd5,"Back End Ready:%b\n",fabScalar.issueq.backEndReady_i);
 $fwrite(fd5,"Occupancy Count:%d Head Ptr:%d Tail Ptr:%d\n",fabScalar.issueq.issueQfreelist.issueQCount,
	 fabScalar.issueq.issueQfreelist.headPtr,fabScalar.issueq.issueQfreelist.tailPtr);

 $fwrite(fd5,"ALid0:%d ALid1:%d ALid2:%d ALid3:%d\n",fabScalar.issueq.inst0ALid_i,
	 fabScalar.issueq.inst1ALid_i,fabScalar.issueq.inst2ALid_i,fabScalar.issueq.inst3ALid_i);
 $fwrite(fd5,"IQ Entry0=%d IQ Entry1=%d IQ Entry2=%d IQ Entry3=%d\n",fabScalar.issueq.freeEntry0,
	 fabScalar.issueq.freeEntry1,fabScalar.issueq.freeEntry2,fabScalar.issueq.freeEntry3);
 $fwrite(fd5,"RSR-0 Valid=%b Tag:%d\n",fabScalar.issueq.rsr0Tag_i[0],fabScalar.issueq.rsr0Tag_i[`SIZE_PHYSICAL_LOG:1]); 
 $fwrite(fd5,"RSR-1 Valid=%b Tag:%d\n",fabScalar.issueq.rsr1Tag_i[0],fabScalar.issueq.rsr1Tag_i[`SIZE_PHYSICAL_LOG:1]); 
 $fwrite(fd5,"RSR-2 Valid=%b Tag:%d\n",fabScalar.issueq.rsr2Tag_i[0],fabScalar.issueq.rsr2Tag_i[`SIZE_PHYSICAL_LOG:1]); 
 $fwrite(fd5,"RSR-3 Valid=%b Tag:%d\n",fabScalar.issueq.rsr3Tag_i[0],fabScalar.issueq.rsr3Tag_i[`SIZE_PHYSICAL_LOG:1]); 

 //$fwrite(fd5,"freeingScalar00=%b freeingCandidate00=%d\n",fabScalar.issueq.issueQfreelist.freeIq.freeingScalar00,
 //	 fabScalar.issueq.issueQfreelist.freeIq.freeingCandidate00);
 //for(k=0;k<32;k=k+1)
 	//$fwrite(fd5,"ISSUEQ_FREELIST[%d]=%d\n",k,fabScalar.issueq.issueQfreelist.ISSUEQ_FREELIST[k]); 

 $fwrite(fd5,"FreedEntry-0 Valid:%b FreedEntry-0:%d\n",fabScalar.issueq.freedValid0,
	 fabScalar.issueq.freedEntry0); 
 $fwrite(fd5,"FreedEntry-1 Valid:%b FreedEntry-1:%d\n",fabScalar.issueq.freedValid1,
	 fabScalar.issueq.freedEntry1); 
 $fwrite(fd5,"FreedEntry-2 Valid:%b FreedEntry-2:%d\n",fabScalar.issueq.freedValid2,
	 fabScalar.issueq.freedEntry2); 
 $fwrite(fd5,"FreedEntry-3 Valid:%b FreedEntry-3:%d\n",fabScalar.issueq.freedValid3,
	 fabScalar.issueq.freedEntry3); 

 $fwrite(fd5,"\n"); 

 if(fabScalar.issueq.ctrlMispredict_i)
 begin
        $fwrite(fd5,"Branch Mispredict!!\n");
        for(i=0;i<32;i=i+4)
        begin
                pc0 = fabScalar.issueq.ISSUEQ_PAYLOAD[i];
                pc1 = fabScalar.issueq.ISSUEQ_PAYLOAD[i+1];
                pc2 = fabScalar.issueq.ISSUEQ_PAYLOAD[i+2];
                pc3 = fabScalar.issueq.ISSUEQ_PAYLOAD[i+3];
                $fwrite(fd5,"BRANCH_MASK[%d]=%b PC=%h BRANCH_MASK[%d]=%b PC=%h BRANCH_MASK[%d]=%b PC=%h BRANCH_MASK[%d]=%b PC=%h\n",
                i,fabScalar.issueq.BRANCH_MASK[i],
                pc0[`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1],
                i+1,fabScalar.issueq.BRANCH_MASK[i+1],
                pc1[`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1],
                i+2,fabScalar.issueq.BRANCH_MASK[i+2],
                pc2[`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1],
                i+3,fabScalar.issueq.BRANCH_MASK[i+3],
                pc3[`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1]);
        end
 end
 $fwrite(fd5,"Freed Vec       =%b\n",fabScalar.issueq.issueQfreelist.freeIq.freedVector);
 //if(fabScalar.issueq.ctrlMispredict_i)
 $fwrite(fd5,"MispredictVector=%b\n",fabScalar.issueq.freedValid_mispre);
 $fwrite(fd5,"Freed Vec_t1    =%b\n",fabScalar.issueq.issueQfreelist.freeIq.freedVector_t1);	
 $fwrite(fd5,"Freed Vec_t     =%b\n",fabScalar.issueq.issueQfreelist.freeIq.freedVector_t);	


 if(fabScalar.issueq.issueQfreelist.issueQCount == 0)
 begin
	for(i=0;i<`SIZE_ISSUEQ;i=i+1)
		$fwrite(fd5,"FreeList[%d]=%d\n",i,fabScalar.issueq.issueQfreelist.ISSUEQ_FREELIST[i]);
 end

 $fwrite(fd5,"\n");*/
 /*$fwrite(fd5,"Dest Reg-0:%b\n",fabScalar.issueq.dispatchPacket0_i[3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+
                                        `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
                                        `SIZE_CTI_LOG:1+2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+
                                        `INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1]);	 
 $fwrite(fd5,"Dest Reg-1:%b\n",fabScalar.issueq.dispatchPacket1_i[3*`SIZE_PHYSICAL_LOG+3+`SIZE_IMMEDIATE+1+
                                        `LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
                                        `SIZE_CTI_LOG:1+2*`SIZE_PHYSICAL_LOG+2+`SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+
                                        `INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1]);
 */ 
// end
//end


/* Prints selection (issue queue) related signals and latch value.
 */
always @(posedge clock)
begin:SELECT
 reg [`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] pc0;
 reg [`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] pc1;
 reg [`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] pc2;
 reg [`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] pc3;
 reg [`SIZE_ACTIVELIST_LOG-1:0] ALid0;
 reg [`SIZE_ACTIVELIST_LOG-1:0] ALid1;
 reg [`SIZE_ACTIVELIST_LOG-1:0] ALid2;
 reg [`SIZE_ACTIVELIST_LOG-1:0] ALid3;
 integer i;

 if(sim_count > PRINT_CNT)
 begin
 $fwrite(fd4,"CYCLE=%d\n",sim_count);
 $fwrite(fd4,"----------------------------------------------------------------------\n");

 $fwrite(fd4,"Issue Queue Valid: %b\n",fabScalar.issueq.ISSUEQ_VALID);
 $fwrite(fd4,"Issue Queue Sched: %b\n",fabScalar.issueq.ISSUEQ_SCHEDULED);
 $fwrite(fd4,"Source-1 Valid:    %b\n",fabScalar.issueq.SRC0_REG_VALID);
 $fwrite(fd4,"Source-2 Valid:    %b\n",fabScalar.issueq.SRC1_REG_VALID);

 $fwrite(fd4,"Request Vectors\n");
 $fwrite(fd4,"FU0: 		   %b\n",fabScalar.issueq.requestVector0);
 //$fwrite(fd4,"FU1: %b\n",fabScalar.issueq.requestVector1);
 $fwrite(fd4,"FU2: 		   %b\n",fabScalar.issueq.requestVector2);
 $fwrite(fd4,"FU3: 		   %b\n",fabScalar.issueq.requestVector3);
 $fwrite(fd4,"\n");

 $fwrite(fd4,"Granted signals\n");
 ALid0 = fabScalar.issueq.grantedPacket0_o[`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
         `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
         `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1];
 $fwrite(fd4,"FU0: Granted valid=%b PC=0x%h IQ_Entry=%d ALid=%d\n",fabScalar.issueq.grantedValid0_o,
         fabScalar.issueq.grantedPC0,fabScalar.issueq.grantedEntry0,ALid0);

 //$fwrite(fd4,"FU1: Granted valid=%b PC=0x%h IQ_Entry=%d\n",fabScalar.issueq.grantedValid1,
 //        fabScalar.issueq.grantedPC1,fabScalar.issueq.grantedEntry1);
 $fwrite(fd4,"FU2: Granted valid=%b PC=0x%h IQ_Entry=%d\n",fabScalar.issueq.grantedValid2_o,
         fabScalar.issueq.grantedPC2,fabScalar.issueq.grantedEntry2);
 $fwrite(fd4,"FU3: Granted valid=%b PC=0x%h IQ_Entry=%d\n",fabScalar.issueq.grantedValid3_o,
         fabScalar.issueq.grantedPC3,fabScalar.issueq.grantedEntry3);

 $fwrite(fd4,"\n",);
 end
end 


/* Prints register read related signals and latch value.
 */
always @(posedge clock)
begin:REG_READ
 if(sim_count > PRINT_CNT)
 begin
 $fwrite(fd6,"CYCLE=%d\n",sim_count);
 $fwrite(fd6,"----------------------------------------------------------------------\n");

 $fwrite(fd6,"FU0 Valid=%b PC=0x%h Src1=%d Src1Data=0x%h Src2=%d Src2Data=0x%h Mask=%b\n",
	 fabScalar.reg_read.fuPacketValid0_o,
	 fabScalar.reg_read.fuPacket0_i[`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1],
	 fabScalar.reg_read.inst0Source1,fabScalar.reg_read.inst0Data1,
         fabScalar.reg_read.inst0Source2,fabScalar.reg_read.inst0Data2,
         fabScalar.reg_read.inst0Mask_l1);
 $fwrite(fd6,"FU1 Valid=%b PC=0x%h Src1=%d Src1Data=0x%h Src2=%d Src2Data=0x%h Mask=%b\n",
         fabScalar.reg_read.fuPacketValid1_o,
	 fabScalar.reg_read.fuPacket1_i[`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1],
	 fabScalar.reg_read.inst1Source1,fabScalar.reg_read.inst1Data1,
         fabScalar.reg_read.inst1Source2,fabScalar.reg_read.inst1Data2,
         fabScalar.reg_read.inst1Mask_l1);
 $fwrite(fd6,"FU2 Valid=%b PC=0x%h Src1=%d Src1Data=0x%h Src2=%d Src2Data=0x%h Mask=%b\n",
	 fabScalar.reg_read.fuPacketValid2_o,
	 fabScalar.reg_read.fuPacket2_i[`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1],
	 fabScalar.reg_read.inst2Source1,fabScalar.reg_read.inst2Data1,
         fabScalar.reg_read.inst2Source2,fabScalar.reg_read.inst2Data2,
         fabScalar.reg_read.inst2Mask_l1);
 $fwrite(fd6,"FU3 Valid=%b PC=0x%h Src1=%d Src1Data=0x%h Src2=%d Src2Data=0x%h Mask=%b\n",
	 fabScalar.reg_read.fuPacketValid3_o,
	 fabScalar.reg_read.fuPacket3_i[`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1],
	 fabScalar.reg_read.inst3Source1,fabScalar.reg_read.inst3Data1,
	 fabScalar.reg_read.inst3Source2,fabScalar.reg_read.inst3Data2,
	 fabScalar.reg_read.inst3Mask_l1);

 $fwrite(fd6,"Bypass....\n");
 $fwrite(fd6,"BP0 Valid=%b Dest=%d Data=0x%h\n",fabScalar.reg_read.bypassValid0_i,
	 fabScalar.reg_read.bypassPacket0_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:`SIZE_DATA+`CHECKPOINTS_LOG+1],
	 fabScalar.reg_read.bypassPacket0_i[`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1]);
 $fwrite(fd6,"BP1 Valid=%b Dest=%d Data=0x%h\n",fabScalar.reg_read.bypassValid1_i,
         fabScalar.reg_read.bypassPacket1_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:`SIZE_DATA+`CHECKPOINTS_LOG+1],
         fabScalar.reg_read.bypassPacket1_i[`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1]);
 $fwrite(fd6,"BP2 Valid=%b Dest=%d Data=0x%h\n",fabScalar.reg_read.bypassValid2_i,
         fabScalar.reg_read.bypassPacket2_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:`SIZE_DATA+`CHECKPOINTS_LOG+1],
         fabScalar.reg_read.bypassPacket2_i[`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1]);
 $fwrite(fd6,"BP3 Valid=%b Dest=%d Data=0x%h\n",fabScalar.reg_read.bypassValid3_i,
         fabScalar.reg_read.bypassPacket3_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:`SIZE_DATA+`CHECKPOINTS_LOG+1],
         fabScalar.reg_read.bypassPacket3_i[`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1]);
 end
end



/* Prints functional unit-0.
 */
/*
always @(posedge clock)
begin:FU0
 if(sim_count > PRINT_CNT)
 begin
 $fwrite(fd13,"CYCLE=%d\n",sim_count);
 $fwrite(fd13,"----------------------------------------------------------------------\n");
 $fwrite(fd13,"valid:%b ALid:%d Data1:%h Data2:%h Result:%h Mask:%b\n",fabScalar.execute.fu0.inValid_i,
         fabScalar.execute.fu0.instALid,fabScalar.execute.fu0.fuFinalData1_i,
	 fabScalar.execute.fu0.fuFinalData2_i,fabScalar.execute.fu0.result,
	 fabScalar.execute.exePacket0_o[`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
         `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+
	 `SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1]);
  $fwrite(fd13,"FU0 Flag:%b\n",fabScalar.execute.exePacket0_o[`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
         `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_PHYSICAL_LOG+
         `SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1]);
 end
end
*/

/* Prints functional unit-2.
 */
/*
always @(posedge clock)
begin:FU2
 if(sim_count > PRINT_CNT)
 begin
 $fwrite(fd12,"CYCLE=%d\n",sim_count);
 $fwrite(fd12,"----------------------------------------------------------------------\n");
 $fwrite(fd12,"valid:%b PC:%h Data1:%h Data2:%h DestReg:%d Result:%h\n",fabScalar.execute.fu2.inValid_i,
         fabScalar.execute.fu2.instPC,fabScalar.execute.fu2.fuFinalData1_i,fabScalar.execute.fu2.fuFinalData2_i,
	 fabScalar.execute.fu2.instDestReg,fabScalar.execute.fu2.result);
 end
end
*/

/* Prints functional unit-2.
 */
/*
always @(posedge clock)
begin:FU6
 if(sim_count > PRINT_CNT)
 begin
 $fwrite(fd11,"CYCLE=%d\n",sim_count);
 $fwrite(fd11,"----------------------------------------------------------------------\n");
 $fwrite(fd11,"valid:%b PC:%h Data1:%h Data2:%h DestReg:%d Result:%h\n",fabScalar.execute.fu6.inValid_i,
         fabScalar.execute.fu6.instPC,fabScalar.execute.fu6.fuFinalData1_i,fabScalar.execute.fu6.fuFinalData2_i,
	 fabScalar.execute.fu6.instDestReg,fabScalar.execute.fu6.result);
 end
end
*/

/* Prints functional unit-3.
 */
always @(posedge clock)
begin:FU3
 if(sim_count > PRINT_CNT)
 begin
// $fwrite(fd11,"CYCLE=%d\n",sim_count);
// $fwrite(fd11,"----------------------------------------------------------------------\n");
// $fwrite(fd11,"data1:%h data2:%h immd:%h\n",fabScalar.execute.fu3.agen.data1_i,
//         fabScalar.execute.fu3.agen.data2_i,fabScalar.execute.fu3.agen.immd_i);
// $fwrite(fd11,"Dest valid=%b Addr= %h  Data=%h\n",fabScalar.execute.fu3.flags[4],
//	 fabScalar.execute.fu3.result,fabScalar.execute.fu3.fuFinalData2_i);
 end
end



/* Prints load-store related signals and latch value.
 */
always @(posedge clock)
begin:LSU
 reg [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] val;
 integer i;
 if(sim_count > PRINT_CNT)
 begin
 $fwrite(fd10,"CYCLE=%d\n",sim_count);
 $fwrite(fd10,"----------------------------------------------------------------------\n");

 if(fabScalar.lsu.ctrlVerified_i)
	$fwrite(fd10,"Branch Verified, SMTid:%d\n",fabScalar.lsu.ctrlSMTid_i);
 if(fabScalar.lsu.ctrlMispredict_i)
 begin
 	$fwrite(fd10,"Branch Mispredict!! SMT id=%d\n",fabScalar.lsu.ctrlSMTid_i);
	$fwrite(fd10,"ldq valid vector=%b\n",fabScalar.lsu.ldqValid_mispre);
	$fwrite(fd10,"stq valid vector=%b\n",fabScalar.lsu.stqValid_mispre);
	$fwrite(fd10,"\n");
	for(i=0;i<`SIZE_LSQ;i=i+1)
		$fwrite(fd10,"STQ[%d]=%b, %b\n",i,fabScalar.lsu.stqBranchTag[i],fabScalar.lsu.ldqBranchTag[i]);	
	$fwrite(fd10,"Invalidated LD=%d  Invalidated ST=%d\n",fabScalar.lsu.mispreLD_cnt,
		fabScalar.lsu.mispreST_cnt);
        $fwrite(fd10,"mis-pre LDQ: Head=%d  Tail=%d\n",fabScalar.lsu.ldqhead_mispre,
		fabScalar.lsu.ldqtail_mispre); 
        $fwrite(fd10,"mis-pre STQ: Head=%d  Tail=%d\n",fabScalar.lsu.stqhead_mispre,
		fabScalar.lsu.stqtail_mispre); 
 end


 /*if(fabScalar.lsu.inst0Load)
	$fwrite(fd10,"inst0Load=    %b	PC=%h\n",fabScalar.lsu.inst0Load,
	fabScalar.disBackend.vr_inst0PC);
 if(fabScalar.lsu.inst0Store)
        $fwrite(fd10,"inst0Store=   %b  PC=%h\n",fabScalar.lsu.inst0Store,
        fabScalar.disBackend.vr_inst0PC);

 if(fabScalar.lsu.inst1Load)
        $fwrite(fd10,"inst1Load=    %b  PC=%h\n",fabScalar.lsu.inst1Load,
        fabScalar.disBackend.vr_inst1PC);
 if(fabScalar.lsu.inst1Store)
        $fwrite(fd10,"inst1Store=   %b  PC=%h\n",fabScalar.lsu.inst1Store,
        fabScalar.disBackend.vr_inst1PC);

 if(fabScalar.lsu.inst2Load)
        $fwrite(fd10,"inst2Load=    %b  PC=%h\n",fabScalar.lsu.inst2Load,
        fabScalar.disBackend.vr_inst2PC);
 if(fabScalar.lsu.inst2Store)
        $fwrite(fd10,"inst2Store=   %b  PC=%h\n",fabScalar.lsu.inst2Store,
        fabScalar.disBackend.vr_inst2PC);

 if(fabScalar.lsu.inst3Load)
        $fwrite(fd10,"inst3Load=    %b  PC=%h\n",fabScalar.lsu.inst3Load,
        fabScalar.disBackend.vr_inst3PC);
 if(fabScalar.lsu.inst3Store)
        $fwrite(fd10,"inst3Store=   %b  PC=%h\n",fabScalar.lsu.inst3Store,
        fabScalar.disBackend.vr_inst3PC);
 */
 if(fabScalar.lsu.commitLoad0_i)
 	$fwrite(fd10,"commitLoad0=  %b ....\n",fabScalar.lsu.commitLoad0_i);
 if(fabScalar.lsu.commitLoad1_i)
 	$fwrite(fd10,"commitLoad1=  %b ....\n",fabScalar.lsu.commitLoad1_i);
 if(fabScalar.lsu.commitLoad2_i)
 	$fwrite(fd10,"commitLoad2=  %b ....\n",fabScalar.lsu.commitLoad2_i);
 if(fabScalar.lsu.commitLoad3_i)
 	$fwrite(fd10,"commitLoad3=  %b ....\n",fabScalar.lsu.commitLoad3_i);

 $fwrite(fd10,"ldq valid vector : %b\n",fabScalar.lsu.ldqValid);
 $fwrite(fd10,"ldq valid address: %b\n",fabScalar.lsu.ldqAddrValid); 

 if(fabScalar.lsu.commitStore0_i)
        $fwrite(fd10,"commitStore0= %b ....\n",fabScalar.lsu.commitStore0_i);
 if(fabScalar.lsu.commitStore1_i)
        $fwrite(fd10,"commitStore1= %b ....\n",fabScalar.lsu.commitStore1_i);
 if(fabScalar.lsu.commitStore2_i)
        $fwrite(fd10,"commitStore2= %b ....\n",fabScalar.lsu.commitStore2_i);
 if(fabScalar.lsu.commitStore3_i)
        $fwrite(fd10,"commitStore3= %b ....\n",fabScalar.lsu.commitStore3_i);

 $fwrite(fd10,"stq valid vector = %b\n",fabScalar.lsu.stqValid);
 $fwrite(fd10,"stq valid address= %b\n",fabScalar.lsu.stqAddrValid);
 $fwrite(fd10,"stq commit vector= %b   	commit ptr=%d\n",fabScalar.lsu.stqCommit,
	 fabScalar.lsu.stqCommitPtr); 
 
	

 $fwrite(fd10,"ldq head=%d ldq tail=%d ldq count=%d\n",fabScalar.lsu.ldqHead,
	 fabScalar.lsu.ldqTail,fabScalar.lsu.ldqCount);
 $fwrite(fd10,"stq head=%d stq tail=%d stq count=%d\n",fabScalar.lsu.stqHead,
	 fabScalar.lsu.stqTail,fabScalar.lsu.stqCount);


 if(sim_count == 148428)
 begin
 	//for(i=0;i<`SIZE_LSQ;i=i+1)
                $fwrite(fd10,"STQ Addr[%d]:%h\n",i,{fabScalar.lsu.stqAddr1[i],fabScalar.lsu.stqAddr2[i]});
 end
 
 if(fabScalar.lsu.agenPacketValid0_i)
 begin
	val  = fabScalar.activeList.activeList.sram[fabScalar.lsu.agenALid];
	if(fabScalar.lsu.agenLoad)
	begin
	$fwrite(fd10,"AGEN PC:%h isLoad:%b isStore:%b addr:%h data:%h size:%b lsq ID:%d ALid:%d BrMask:%b\n",
		val[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1],
		fabScalar.lsu.agenLoad,fabScalar.lsu.agenStore,fabScalar.lsu.agenAddress,
		fabScalar.lsu.agenLoadData,fabScalar.lsu.agenSize,fabScalar.lsu.agenLsqId,
		fabScalar.lsu.agenALid,fabScalar.lsu.agenBranchMask);
		$fwrite(fd10,"Data Read from DCache:%h\n",fabScalar.lsu.dcacheData);

		$fwrite(fd10,"Last Stq id    : %d\n",fabScalar.lsu.lastStore);
		$fwrite(fd10,"Prece Stq Valid: %b\n",fabScalar.lsu.precedingSTvalid);
		$fwrite(fd10,"Match Vector1  : %b\n",fabScalar.lsu.matchVector_ld1);
		$fwrite(fd10,"Match Vector2  : %b\n",fabScalar.lsu.matchVector_ld2);
		$fwrite(fd10,"Forward Vector1: %b\n",fabScalar.lsu.forwardVector1);
		$fwrite(fd10,"Forward Vector2: %b\n",fabScalar.lsu.forwardVector2);
		$fwrite(fd10,"STQ Match: %b STQ ID: %d\n",fabScalar.lsu.agenStqMatch,fabScalar.lsu.lastMatch);
	end
 	else if(fabScalar.lsu.agenStore)
 	begin
	$fwrite(fd10,"AGEN PC:%h isLoad:%b isStore:%b addr:%h data:%h size:%b lsq ID:%d ALid:%d BrMask:%b\n",
		val[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1],
		fabScalar.lsu.agenLoad,fabScalar.lsu.agenStore,fabScalar.lsu.agenAddress,
		fabScalar.lsu.agenData,fabScalar.lsu.agenSize,fabScalar.lsu.agenLsqId,
		fabScalar.lsu.agenALid,fabScalar.lsu.agenBranchMask);

		$fwrite(fd10,"Next Ldq id   : %d\n",fabScalar.lsu.nextLoad);
                $fwrite(fd10,"Match Vector  : %b\n",fabScalar.lsu.matchVector_st);
                $fwrite(fd10,"Violate Vector: %b\n",fabScalar.lsu.violateVector);
                $fwrite(fd10,"LDQ Violate: %b LDQ ID: %d ALid: %d\n",fabScalar.lsu.agenLdqMatch,fabScalar.lsu.firstMatch,
		fabScalar.lsu.violateLdALid);
	end

	if(fabScalar.lsu.lsuPacketValid0_o) 
	 	$fwrite(fd10,"The mem op is being written back....\n");	
	else
		$fwrite(fd10,"The mem op is stalled in the LSQ....\n");
 
	if(fabScalar.lsu.agenLoadReady == 1'b0)
 	begin
		$fwrite(fd10,"Normalize tail=%d Order Vector=%b\n",fabScalar.lsu.normalizeTail,
		fabScalar.lsu.orderVector_t3);	
		$fwrite(fd10,"lastMatch   = %d\n",fabScalar.lsu.lastMatch);
		$fwrite(fd10,"agenStqMatch= %b\n",fabScalar.lsu.agenStqMatch);
 	end
 end

 if(fabScalar.lsu.stCommit)
 begin
	$fwrite(fd10,"commiting store: stq id=%d  Addr=%h  Data=%h  ST Size=%b\n",
		fabScalar.lsu.stqHead,fabScalar.lsu.stCommitAddr,fabScalar.lsu.stCommitData,fabScalar.lsu.stCommitSize);
 end

 $fwrite(fd10,"\n");
 end
end

/* Prints write back related signals and latch value.
 */
always @(posedge clock)
begin:WRITE_BACK
 reg [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] val0;
 reg [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] val1;
 reg [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] val2;
 reg [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] val3;
 reg [2+`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:0] val4;

 if(sim_count > PRINT_CNT)
 begin
 $fwrite(fd8,"CYCLE=%d\n",sim_count);
 $fwrite(fd8,"----------------------------------------------------------------------\n");

/* if(fabScalar.writebk.exePacketValid0)
 begin
	val0 = fabScalar.activeList.activeList.sram[fabScalar.writebk.wb_inst0ALid];
	$fwrite(fd8,"FU0: PC0:%h ALid=%d DestReg=%d Result:%h Mask:%b WB_Flag:%b\n",
		val0[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1],
		fabScalar.writebk.wb_inst0ALid,fabScalar.writebk.wb_inst0DestReg,
		fabScalar.writebk.bypassPacket0_o[`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1],
		fabScalar.writebk.fu0BranchMask,
		fabScalar.writebk.exePacket0Flags);
 end
 if(fabScalar.writebk.exePacketValid1)
 begin
        val1 = fabScalar.activeList.activeList.sram[fabScalar.writebk.wb_inst1ALid];
        $fwrite(fd8,"FU1: PC1:%h WB_Flag:%b\n",val1[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1],
		fabScalar.writebk.exePacket1Flags);
 end
 if(fabScalar.writebk.exePacketValid2)
 begin
        val2 = fabScalar.activeList.activeList.sram[fabScalar.writebk.wb_inst2ALid];
        $fwrite(fd8,"FU2 WB: PC2=%h ALid=%d ",val2[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG-13:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1],
		fabScalar.writebk.wb_inst2ALid);
	$fwrite(fd8,"        Mispredict=%b Conditional Br=%b direction=%b SMT id=%d Ctiq id=%d Target Addr=%h\n",
		fabScalar.writebk.ctrlMispredict_o,
		fabScalar.writebk.ctrlConditional_o,
		fabScalar.writebk.ctrlBrDirection_o,
		fabScalar.writebk.ctrlSMTid_o,
		fabScalar.writebk.ctrlCtiQueueIndex_o,
		fabScalar.writebk.ctrlTargetAddr_o); 
 end
 if(fabScalar.writebk.exePacketValid3)
 begin
        val4 = fabScalar.activeList.activeList.sram[fabScalar.writebk.wb_inst3ALid];
        $fwrite(fd8,"to LSU: PC3=%h   Target Addr=%h     Data=%h\n",
		val4[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1],
		fabScalar.writebk.wb_inst3TarAddr,fabScalar.writebk.wb_inst3Data);
 end
 if(fabScalar.writebk.lsuPacketValid0)
 begin
        val3 = fabScalar.activeList.activeList.sram[fabScalar.writebk.lsuPacket0[`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:`SIZE_ISSUEQ_LOG]];
        $fwrite(fd8,"FU3 WB PC-lsu=%h ALid=%d DestReg:%d Result:%h WB flags:%b brMask:%b\n",
	val3[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1],
	fabScalar.writebk.lsuPacket0[`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:`SIZE_ISSUEQ_LOG],
	fabScalar.writebk.lsuPacket0[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:
                           `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG],
	fabScalar.writebk.lsuPacket0[`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:
                   `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG],
	fabScalar.writebk.lsuPacket0Flags,
	fabScalar.writebk.lsuBranchMask);
 end
*/ $fwrite(fd8,"\n");

 end
end

`endif

/* Prints commit related signals and latch value.
 */
always @(posedge clock)
begin:COMMIT
 reg [`SIZE_PC-1:0]      PC 	     	[`COMMIT_WIDTH-1:0];
 reg [`SIZE_RMT_LOG-1:0] logicalDest 	[`COMMIT_WIDTH-1:0];
 reg [`SIZE_DATA-1:0]    result      	[`COMMIT_WIDTH-1:0];
 reg			 isBranch	[`COMMIT_WIDTH-1:0];
 reg			 isMispredict 	[`COMMIT_WIDTH-1:0];
 reg			 eChecker    	[`COMMIT_WIDTH-1:0];
 reg                     isFission   	[`COMMIT_WIDTH-1:0];
 reg [`SIZE_PC-1:0]      lastCommitPC;
 integer i,j;
 integer l;



 PC[0] 		= fabScalar.activeList.commitPC0;
 PC[1] 		= fabScalar.activeList.commitPC1;
 PC[2] 		= fabScalar.activeList.commitPC2;
 PC[3] 		= fabScalar.activeList.commitPC3;

 logicalDest[0] = fabScalar.activeList.dataAl0[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:2*`SIZE_PHYSICAL_LOG+1];
 logicalDest[1] = fabScalar.activeList.dataAl1[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:2*`SIZE_PHYSICAL_LOG+1];
 logicalDest[2] = fabScalar.activeList.dataAl2[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:2*`SIZE_PHYSICAL_LOG+1];
 logicalDest[3] = fabScalar.activeList.dataAl3[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:2*`SIZE_PHYSICAL_LOG+1];

 result[0] 	= fabScalar.reg_read.PhyRegFile1.sram[fabScalar.activeList.dataAl0[2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1]];
 result[1] 	= fabScalar.reg_read.PhyRegFile1.sram[fabScalar.activeList.dataAl1[2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1]];
 result[2] 	= fabScalar.reg_read.PhyRegFile1.sram[fabScalar.activeList.dataAl2[2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1]];
 result[3] 	= fabScalar.reg_read.PhyRegFile1.sram[fabScalar.activeList.dataAl3[2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1]];

 eChecker[0]   	= fabScalar.activeList.commitVerify0 | fabScalar.activeList.commitStore0;
 eChecker[1]   	= fabScalar.activeList.commitVerify1 | fabScalar.activeList.commitStore1;
 eChecker[2]   	= fabScalar.activeList.commitVerify2 | fabScalar.activeList.commitStore2;
 eChecker[3]   	= fabScalar.activeList.commitVerify3 | fabScalar.activeList.commitStore3;

 isFission[0]   = fabScalar.activeList.commitVerify0 & fabScalar.activeList.commitFission0;
 isFission[1]   = fabScalar.activeList.commitVerify1 & fabScalar.activeList.commitFission1;
 isFission[2]   = fabScalar.activeList.commitVerify2 & fabScalar.activeList.commitFission2;
 isFission[3]   = fabScalar.activeList.commitVerify3 & fabScalar.activeList.commitFission3;
 


 // Following counts the Ctrl mis-predict
 isBranch[0]	 = fabScalar.activeList.ctrlAl0[5];	
 isBranch[1]	 = fabScalar.activeList.ctrlAl1[5];	
 isBranch[2]	 = fabScalar.activeList.ctrlAl2[5];	
 isBranch[3]	 = fabScalar.activeList.ctrlAl3[5];	

 isMispredict[0] = fabScalar.activeList.ctrlAl0[0] & fabScalar.activeList.ctrlAl0[5];
 isMispredict[1] = fabScalar.activeList.ctrlAl1[0];
 isMispredict[2] = fabScalar.activeList.ctrlAl2[0];
 isMispredict[3] = fabScalar.activeList.ctrlAl3[0];

 // Following counts number of control misprediction
 if(sim_count > 10)
 begin
 br_count 	= br_count + ((eChecker[0] & isBranch[0]) + (eChecker[1] & 
		  isBranch[1]) + (eChecker[2] & isBranch[2]) + (eChecker[3] & 
		  isBranch[3]));

 br_mispredict_count =  br_mispredict_count + isMispredict[0]; 

 ld_count = ld_count + ((eChecker[0] & fabScalar.activeList.commitLoad0_o) + (eChecker[1] & 
	    fabScalar.activeList.commitLoad1_o) + (eChecker[2] & fabScalar.activeList.commitLoad2_o) +
	    (eChecker[3] & fabScalar.activeList.commitLoad3_o));
 end

 // Following counts the Load violations
 if(fabScalar.activeList.recoverFlag)
 begin
	//$fwrite(fd7,"LD Violation Occured -> PC:%h\n",fabScalar.activeList.recoverPC);
        for(j=0;j<`SIZE_RMT;j=j+1)
        begin
        //      $display("LOGICAL_REG[%d]:%x\n",j,LOGICAL_REG[j]);
		if(fabScalar.reg_read.PhyRegFile1.sram[fabScalar.amt.AMT.sram[j]] != LOGICAL_REG[j])
		$display("Real[%d]:%h  Virt[%d]:%h",j,fabScalar.reg_read.PhyRegFile1.sram[fabScalar.amt.AMT.sram[j]],j,LOGICAL_REG[j]);
        end
                load_violation_count = load_violation_count+1;
 end


 if(sim_count % 10000 == 0) 
 begin
	if((fabScalar.activeList.commitCount-last_commit_cnt) < 10)
	begin
		$display("ERROR: instruction committing has stalled");
		$finish;
	end
	/*$display("Cycle Count:%d Commit Count:%d  Ld Count:%d Ld Violation:%d  Br-Count:%d Br-Mispredict:%d",
			sim_count,
			fabScalar.activeList.commitCount,
			ld_count,
			load_violation_count,
			br_count,
			br_mispredict_count);*/
        $display("Cycle Count:%d Commit Count:%d  BTB-Miss:%d BTB-Miss-Rtn:%d  Br-Count:%d Br-Mispredict:%d",
                        sim_count,
                        fabScalar.activeList.commitCount,
                        btb_miss,
                        btb_miss_rtn,
                        br_count,
                        br_mispredict_count);


	last_commit_cnt = fabScalar.activeList.commitCount;
 end

 `ifdef PRINT

 if(sim_count > PRINT_CNT)
 begin
 $fwrite(fd7,"CYCLE=%d\n",sim_count);
 $fwrite(fd7,"----------------------------------------------------------------------\n");


 $fwrite(fd7,"Occupancy Count:%d\n",fabScalar.activeList.activeListCount);
 $fwrite(fd7,"HeadAL:%d TailAL:%d\n",fabScalar.activeList.headAL,fabScalar.activeList.tailAL);
 
 if(fabScalar.activeList.recoverFlag)
 begin
        $fwrite(fd7,"LD Violation Occured -> PC:%h\n",fabScalar.activeList.recoverPC);
 end

 if(fabScalar.activeList.restoreStateFlag_o)
 begin
	$fwrite(fd7,"Restoring Processor State\n");
 end


 $fwrite(fd7,"Commit Count=%d\n",fabScalar.activeList.commitCount);

 if(fabScalar.activeList.mispredFlag)
 	$fwrite(fd7,"Branch Mispredict!!!Target addr=%h\n",fabScalar.activeList.targetPC);

						    
 if(fabScalar.activeList.commitVerify0 || fabScalar.activeList.commitStore0)
 begin
 $fwrite(fd7,"Commit Cnt=%d: PC:%h LogicDest=%d PhyDest=%d Value=%h FreedPhyReg=%d isStore=%b isLoad=%b isFission=%b CTI:%b\n", 
	 fabScalar.activeList.commitCnt0,
	 fabScalar.activeList.commitPC0,
	 fabScalar.activeList.dataAl0[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:2*`SIZE_PHYSICAL_LOG+1],
	 fabScalar.activeList.dataAl0[2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1],
	 fabScalar.reg_read.PhyRegFile1.sram[fabScalar.activeList.dataAl0[2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1]],
	 fabScalar.amt.releasedPhyMap0_o,
	 fabScalar.activeList.commitStore0_o,
	 fabScalar.activeList.commitLoad0_o,
	 fabScalar.activeList.commitFission0,
	 fabScalar.activeList.commitCti_o[0]	
	 ); 	
 end 

 if(fabScalar.activeList.commitVerify1 || fabScalar.activeList.commitStore1)
 begin
 $fwrite(fd7,"commit Cnt=%d: PC:%h LogicDest=%d PhyDest=%d Value=%h FreedPhyReg=%d isStore=%b isLoad=%b isFission=%b CTI:%b\n", 
	 fabScalar.activeList.commitCnt1,
         fabScalar.activeList.commitPC1,
         fabScalar.activeList.dataAl1[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:2*`SIZE_PHYSICAL_LOG+1],
	 fabScalar.activeList.dataAl1[2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1],
	 fabScalar.reg_read.PhyRegFile1.sram[fabScalar.activeList.dataAl1[2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1]],
	 fabScalar.amt.releasedPhyMap1_o,
	 fabScalar.activeList.commitStore1_o,
	 fabScalar.activeList.commitLoad1_o,
 	 fabScalar.activeList.commitFission1,
	 fabScalar.activeList.commitCti_o[1]
	 );
 end

 if(fabScalar.activeList.commitVerify2 || fabScalar.activeList.commitStore2)
 begin
 $fwrite(fd7,"commit Cnt=%d: PC:%h LogicDest=%d PhyDest=%d Value=%h FreedPhyReg=%d isStore=%b isLoad=%b isFission=%b CTI:%b\n", 
	 fabScalar.activeList.commitCnt2,
         fabScalar.activeList.commitPC2,
         fabScalar.activeList.dataAl2[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:2*`SIZE_PHYSICAL_LOG+1],
	 fabScalar.activeList.dataAl2[2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1],
	 fabScalar.reg_read.PhyRegFile1.sram[fabScalar.activeList.dataAl2[2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1]],
	 fabScalar.amt.releasedPhyMap2_o,
	 fabScalar.activeList.commitStore2_o,
	 fabScalar.activeList.commitLoad2_o,
	 fabScalar.activeList.commitFission2,
	 fabScalar.activeList.commitCti_o[2]
	 );
 end

 if(fabScalar.activeList.commitVerify3 || fabScalar.activeList.commitStore3)
 begin
 $fwrite(fd7,"commit Cnt=%d: PC:%h LogicDest=%d PhyDest=%d Value=%h FreedPhyReg=%d isStore=%b isLoad=%b isFission=%b CTI:%b\n", 
	 fabScalar.activeList.commitCnt3,
         fabScalar.activeList.commitPC3,
         fabScalar.activeList.dataAl3[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:2*`SIZE_PHYSICAL_LOG+1],
	 fabScalar.activeList.dataAl3[2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1],
	 fabScalar.reg_read.PhyRegFile1.sram[fabScalar.activeList.dataAl3[2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1]],
	 fabScalar.amt.releasedPhyMap3_o,
	 fabScalar.activeList.commitStore3_o,
	 fabScalar.activeList.commitLoad3_o,
	 fabScalar.activeList.commitFission3,
	 fabScalar.activeList.commitCti_o[3]
	);
 end


 $fwrite(fd7,"\n");
 end
 `endif

 if(lastCommitPC == PC[0] && eChecker[0])
        lastCommitPC = PC[0];
 else
 begin
        if(eChecker[0]) lastCommitPC = PC[0];
        $getRetireInstPC(eChecker[0],sim_count,PC[0],logicalDest[0],result[0],isFission[0]);
 end

 if(lastCommitPC == PC[1] && eChecker[1])
        lastCommitPC = PC[1];
 else
 begin
        if(eChecker[1]) lastCommitPC = PC[1];
        $getRetireInstPC(eChecker[1],sim_count,PC[1],logicalDest[1],result[1],isFission[1]);
 end

 if(lastCommitPC == PC[2] && eChecker[2])
        lastCommitPC = PC[2];
 else
 begin
        if(eChecker[2]) lastCommitPC = PC[2];
        $getRetireInstPC(eChecker[2],sim_count,PC[2],logicalDest[2],result[2],isFission[2]);
 end

 if(lastCommitPC == PC[3] && eChecker[3])
        lastCommitPC = PC[3];
 else
 begin
        if(eChecker[3]) lastCommitPC = PC[3];
        $getRetireInstPC(eChecker[3],sim_count,PC[3],logicalDest[3],result[3],isFission[3]);
 end
 

 /*$getRetireInstPC(eChecker[0],sim_count,PC[0],logicalDest[0],result[0]);
 $getRetireInstPC(eChecker[1],sim_count,PC[1],logicalDest[1],result[1]);
 $getRetireInstPC(eChecker[2],sim_count,PC[2],logicalDest[2],result[2]);
 $getRetireInstPC(eChecker[3],sim_count,PC[3],logicalDest[3],result[3]);*/
end


always @(posedge clock)
begin:UPDATE_LOGICAL_REG
 reg [`SIZE_RMT_LOG-1:0] logicalDest [`COMMIT_WIDTH-1:0];
 reg [`SIZE_DATA-1:0]    result      [`COMMIT_WIDTH-1:0];



 logicalDest[0] = fabScalar.activeList.dataAl0[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:2*`SIZE_PHYSICAL_LOG+1];
 logicalDest[1] = fabScalar.activeList.dataAl1[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:2*`SIZE_PHYSICAL_LOG+1];
 logicalDest[2] = fabScalar.activeList.dataAl2[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:2*`SIZE_PHYSICAL_LOG+1];
 logicalDest[3] = fabScalar.activeList.dataAl3[`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:2*`SIZE_PHYSICAL_LOG+1];

 result[0]      = fabScalar.reg_read.PhyRegFile1.sram[fabScalar.activeList.dataAl0[2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1]];
 result[1]      = fabScalar.reg_read.PhyRegFile1.sram[fabScalar.activeList.dataAl1[2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1]];
 result[2]      = fabScalar.reg_read.PhyRegFile1.sram[fabScalar.activeList.dataAl2[2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1]];
 result[3]      = fabScalar.reg_read.PhyRegFile1.sram[fabScalar.activeList.dataAl3[2*`SIZE_PHYSICAL_LOG:`SIZE_PHYSICAL_LOG+1]];

	if(fabScalar.activeList.commitVerify0)
        begin
                if(~(((logicalDest[0] == logicalDest[1]) && fabScalar.activeList.commitVerify1)
                   || ((logicalDest[0] == logicalDest[2]) && fabScalar.activeList.commitVerify2)
                   || ((logicalDest[0] == logicalDest[3]) && fabScalar.activeList.commitVerify3)))
                LOGICAL_REG[logicalDest[0]] <=  result[0];
        end
        if(fabScalar.activeList.commitVerify1)
        begin
                if(~(((logicalDest[1] == logicalDest[2]) && fabScalar.activeList.commitVerify2)
                   || ((logicalDest[1] == logicalDest[3]) && fabScalar.activeList.commitVerify3)))
                LOGICAL_REG[logicalDest[1]] <=  result[1];
        end
        if(fabScalar.activeList.commitVerify2)
        begin
                if(~((logicalDest[2] == logicalDest[3]) && fabScalar.activeList.commitVerify3))
                LOGICAL_REG[logicalDest[2]] <=  result[2];
        end
        if(fabScalar.activeList.commitVerify3)
        begin
                LOGICAL_REG[logicalDest[3]] <=  result[3];
        end
end


always @(posedge clock)
begin:HANDLE_EXCEPTION
 integer i,j;
 reg [`SIZE_PC-1:0] PC_TRAP;

 // Following code handles the SYSCALL (trap).
 if(fabScalar.activeList.exceptionBit0_f && (|fabScalar.activeList.activeListCount))
 begin
 	/* Functional simulator is stalled waiting to execute the trap.
         * Signal it to proceed with the trap.
         */
	PC_TRAP = fabScalar.activeList.dataAl0[`SIZE_PC+`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG:`SIZE_RMT_LOG+2*`SIZE_PHYSICAL_LOG+1];
	$display("TRAP PC: %x encountered in cycle: %d\n",PC_TRAP,sim_count);
        $handleTrap();

        /* The memory state of the timing simulator is now stale.
         * Copy values from the functional simulator.
         */
        $copyMemory();

        /* Registers of the timing simulator are now stale.
         * Copy values from the functional simulator.
         */
        for(i=0;i<`SIZE_RMT-2;i=i+1)
        begin
                LOGICAL_REG[i]                        = $getArchRegValue(i);
        end
 	LOGICAL_REG[32]		= $getArchRegValue(65);
 	LOGICAL_REG[33]		= $getArchRegValue(64);

        /* Functional simulator is waiting to resume after the trap.
         * Signal it to resume.
         */
        $resumeTrap();

	$getRetireInstPC(1,sim_count,PC_TRAP,0,0,0);
 end

 /* After the SYSCALL is handled by the functional simulator, architectural 
  * values from functional simulator should be copied to the Register File.
  */
 if(fabScalar.activeList.exceptionFlag)
 begin
	$display("CYCLE:%d Exception is High\n",sim_count);
        for(j=0;j<`SIZE_RMT;j=j+1)
        begin
                fabScalar.reg_read.PhyRegFile1.sram[j] = LOGICAL_REG[j];
        end
 end
end


/* Following maintains all the performance related counters.
 */
always @(posedge clock)
begin
	if(sim_count > 10) 	
	begin
//		fetch1_stall		= fetch1_stall+fabScalar.fs1.stall_i;
//		ctiq_stall             	= ctiq_stall+fabScalar.fs2.ctiQueueFull;
 		instBuf_stall          	= instBuf_stall+fabScalar.instBuf.stallFetch;
 		freelist_stall         	= freelist_stall+fabScalar.rename.freeListEmpty;
		backend_stall		= backend_stall+fabScalar.dispatch.stall4;
 		ldq_stall              	= ldq_stall+fabScalar.dispatch.stall0;
 		stq_stall	       	= stq_stall+fabScalar.dispatch.stall1;	 		
 		iq_stall               	= iq_stall+fabScalar.dispatch.stall2;
 		rob_stall              	= rob_stall+fabScalar.dispatch.stall3;

//		btb_miss		= btb_miss+(~fabScalar.fs1.stall_i&fabScalar.fs1.flagRecoverID_i);
//		btb_miss_rtn		= btb_miss_rtn+(~fabScalar.fs1.stall_i&fabScalar.fs1.flagRtrID_i&fabScalar.fs1.flagRecoverID_i);
	end

	if(sim_count % STAT_DISPLAY_INTERVAL == 0)
 	begin
 	$fwrite(fd16,"CYCLE=%d\n",sim_count);
 	$fwrite(fd16,"----------------------------------------------------------------------\n");
	$fwrite(fd16,"Cycle Count:%d Commit Count:%d\n",
                        sim_count,
                        fabScalar.activeList.commitCount);
        $fwrite(fd16, "Fetch1-Stall:%d Ctiq-Stall:%d InstBuff-Stall:%d FreeList-Stall:%d Backend-Stall:%d LDQ-Stall:%d STQ-Stall:%d IQ-Stall:%d ROB-Stall:%d Br-Count:%d Br-Mispredict:%d Ld-Count:%d Ld-Violation:%d\n",
                        fetch1_stall,
                        ctiq_stall,
                        instBuf_stall,
                        freelist_stall,
                        backend_stall,
			ldq_stall,
			stq_stall,
			iq_stall,
			rob_stall,
			br_count,
			br_mispredict_count,
			ld_count,
			load_violation_count);
        end
end


/* Following implements architectural RAS at the retirement of control
 * instruction. 
 * On a mis-predict architectural RAS is copied to the speculative RAS.
 */
`ifdef ARCH_RAS
always @(posedge clock)
begin:ARCH_RAS
 integer i;
 reg [`SIZE_CTI_LOG-1:0] cnt;

 if(fabScalar.fs2.ctiQueue.updateEn_o)
 begin
        if(fabScalar.fs2.ctiQueue.updateCtrlType_o == 2'b00)
	begin
		archTos = archTos-1'b1;
        end
	else if(fabScalar.fs2.ctiQueue.updateCtrlType_o == 2'b01)
	begin
		archRAS[archTos+1'b1] = fabScalar.fs2.ctiQueue.updatePC_o+8;
		archTos = archTos+1'b1;
        end
 end

 if(fabScalar.recoverFlag || fabScalar.exceptionFlag)	
 begin
	for(i=0;i<`SIZE_RAS;i=i+1)
	   fabScalar.fs1.ras.stack[i] = archRAS[i];	

 	fabScalar.fs1.ras.tos    = archTos;
 	fabScalar.fs1.ras.tos_CP = archTos;
 end
end
`endif

endmodule
