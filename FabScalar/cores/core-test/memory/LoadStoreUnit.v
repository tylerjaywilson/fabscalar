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
# Purpose: This module implements Load-Store unit.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

module LSU ( input clk,
             input reset,
             input recoverFlag_i,

             input ctrlVerified_i,                        // control execution flags from the bypass path
             input ctrlMispredict_i,                      // if 1, there has been a mis-predict previous cycle
             input [`CHECKPOINTS_LOG-1:0] ctrlSMTid_i,    // SMT id of the mispredicted branch

             input backEndReady_i,                        // If high, backend is ready to accept new instructions

             input [`CHECKPOINTS+`LSQ_FLAGS-1:0] lsqPacket0_i,
             output [`SIZE_LSQ_LOG-1:0] lsqId0_o,          // LSQ entry num of inst-0 (for Issue Queue/ActiveList)

             input [`CHECKPOINTS+`LSQ_FLAGS-1:0] lsqPacket1_i,
             output [`SIZE_LSQ_LOG-1:0] lsqId1_o,          // LSQ entry num of inst-0 (for Issue Queue/ActiveList)

             input [`CHECKPOINTS+`LSQ_FLAGS-1:0] lsqPacket2_i,
             output [`SIZE_LSQ_LOG-1:0] lsqId2_o,          // LSQ entry num of inst-0 (for Issue Queue/ActiveList)

             input [`CHECKPOINTS+`LSQ_FLAGS-1:0] lsqPacket3_i,
             output [`SIZE_LSQ_LOG-1:0] lsqId3_o,          // LSQ entry num of inst-0 (for Issue Queue/ActiveList)

             input commitStore0_i,                         // Is high, if commit0 inst is a Store
             input commitLoad0_i,                          // Is high, if commit0 inst is a Load

             input commitStore1_i,                         // Is high, if commit0 inst is a Store
             input commitLoad1_i,                          // Is high, if commit0 inst is a Load

             input commitStore2_i,                         // Is high, if commit0 inst is a Store
             input commitLoad2_i,                          // Is high, if commit0 inst is a Load

             input commitStore3_i,                         // Is high, if commit0 inst is a Store
             input commitLoad3_i,                          // Is high, if commit0 inst is a Load

             input agenPacketValid0_i,
             input [`LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
                    `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0]
                    agenPacket0_i,

             output [`SIZE_LSQ_LOG:0] loadQueueCnt_o,    // Current count of instructions in Load Queue
             output [`SIZE_LSQ_LOG:0] storeQueueCnt_o,   // Current count of instructions in Store Queue

             output lsuPacketValid0_o,
             output [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
                     `SIZE_ISSUEQ_LOG-1:0] lsuPacket0_o,
             output [`SIZE_ACTIVELIST_LOG:0] ldViolationPacket_o
           );

reg [`SIZE_LSQ-1:0]                     ldqValid;
reg [`SIZE_ISSUEQ_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG-1:0] ldq [`SIZE_LSQ-1:0];
reg [`LDST_TYPES_LOG-1:0]               ldqSizeofLD     [`SIZE_LSQ-1:0];
reg [`SIZE_DCACHE_ADDR-1:0]             ldqAddr1        [`SIZE_LSQ-1:0];
reg [`SIZE_DCACHE_ADDR-1:0]             ldqAddr2        [`SIZE_LSQ-1:0];
reg [`SIZE_LSQ-1:0]                     ldqAddrValid;
reg [`SIZE_DATA-1:0]                    ldqData         [`SIZE_LSQ-1:0];
reg [`CHECKPOINTS-1:0]                  ldqBranchTag    [`SIZE_LSQ-1:0];
reg [`SIZE_LSQ_LOG-1:0]                 precedingST     [`SIZE_LSQ-1:0];
reg [`SIZE_LSQ-1:0]                     precedingSTvalid;
reg [`SIZE_LSQ-1:0]                     ldqWriteBack;
reg [`SIZE_LSQ_LOG-1:0]                 ldqHead;
reg [`SIZE_LSQ_LOG-1:0]                 ldqTail;
reg [`SIZE_LSQ_LOG:0]                   ldqCount;

reg [`SIZE_LSQ-1:0]                     stqValid;
reg [`SIZE_ACTIVELIST_LOG-1:0]          stq             [`SIZE_LSQ-1:0];
reg [`LDST_TYPES_LOG-1:0]               stqSizeofST     [`SIZE_LSQ-1:0];
reg [`SIZE_DCACHE_ADDR-1:0]             stqAddr1        [`SIZE_LSQ-1:0];
reg [1:0]                               stqAddr2        [`SIZE_LSQ-1:0];
reg [`SIZE_LSQ-1:0]                     stqAddrValid;
reg [`SIZE_DATA-1:0]                    stqData         [`SIZE_LSQ-1:0];
reg [`CHECKPOINTS-1:0]                  stqBranchTag    [`SIZE_LSQ-1:0];
reg [`SIZE_LSQ_LOG-1:0]                 followingLD     [`SIZE_LSQ-1:0];
reg [`SIZE_LSQ-1:0]                     stqCommit;
reg [`SIZE_LSQ_LOG-1:0]                 stqHead;
reg [`SIZE_LSQ_LOG-1:0]                 stqTail;
reg [`SIZE_LSQ_LOG-1:0]                 stqCommitPtr;
reg [`SIZE_LSQ_LOG:0]                   stqCount;

wire                                    inst0Load;
wire                                    inst0Store;
wire [`CHECKPOINTS-1:0]                 inst0BrMask;
wire [`SIZE_LSQ_LOG-1:0]                stqId0;
wire [`SIZE_LSQ_LOG-1:0]                ldqId0;

wire                                    inst1Load;
wire                                    inst1Store;
wire [`CHECKPOINTS-1:0]                 inst1BrMask;
wire [`SIZE_LSQ_LOG-1:0]                stqId1;
wire [`SIZE_LSQ_LOG-1:0]                ldqId1;

wire                                    inst2Load;
wire                                    inst2Store;
wire [`CHECKPOINTS-1:0]                 inst2BrMask;
wire [`SIZE_LSQ_LOG-1:0]                stqId2;
wire [`SIZE_LSQ_LOG-1:0]                ldqId2;

wire                                    inst3Load;
wire                                    inst3Store;
wire [`CHECKPOINTS-1:0]                 inst3BrMask;
wire [`SIZE_LSQ_LOG-1:0]                stqId3;
wire [`SIZE_LSQ_LOG-1:0]                ldqId3;

wire [`SIZE_LSQ_LOG-1:0]                cntLdNew;
wire [`SIZE_LSQ_LOG-1:0]                cntLdCom;
reg [`SIZE_LSQ_LOG-1:0]                 ldqtail_t;
reg [`SIZE_LSQ_LOG-1:0]                 ldqhead_t;
reg [`SIZE_LSQ_LOG:0]                   ldqCount_f;

wire [`SIZE_LSQ_LOG-1:0]                cntStNew;
wire [`SIZE_LSQ_LOG-1:0]                cntStCom;
reg [`SIZE_LSQ_LOG-1:0]                 stqHead_f;
reg [`SIZE_LSQ_LOG:0]                   stqCount_f;

reg [`SIZE_LSQ-1:0]                     ldqready;
reg [`SIZE_DATA-1:0]                    ldqdata [`SIZE_LSQ-1:0];
reg [`SIZE_LSQ-1:0]                     ldqdatavalid;
reg [`SIZE_LSQ-1:0]                     stqaddrV_cb;
reg [`SIZE_DCACHE_ADDR-1:0]             stqaddr_cb [`SIZE_LSQ-1:0];
reg [`SIZE_LSQ-1:0]                     precedingSTvalid_t1;

reg                                     disambiguationStall;
reg                                     agenLoadReady;
reg [`SIZE_DATA-1:0]                    agenLoadData;
reg [`SIZE_LSQ_LOG-1:0]                 lastMatch;
reg                                     agenStqMatch;
reg                                     partialStMatch;

wire [`SIZE_LSQ_LOG-1:0]                index0LdNew;
wire [`SIZE_LSQ_LOG-1:0]                nextLD0;
wire [`SIZE_LSQ_LOG-1:0]                index0StNew;
wire [`SIZE_LSQ_LOG-1:0]                lastST0;

wire [`SIZE_LSQ_LOG-1:0]                index1LdNew;
wire [`SIZE_LSQ_LOG-1:0]                nextLD1;
wire [`SIZE_LSQ_LOG-1:0]                index1StNew;
wire [`SIZE_LSQ_LOG-1:0]                lastST1;

wire [`SIZE_LSQ_LOG-1:0]                index2LdNew;
wire [`SIZE_LSQ_LOG-1:0]                nextLD2;
wire [`SIZE_LSQ_LOG-1:0]                index2StNew;
wire [`SIZE_LSQ_LOG-1:0]                lastST2;

wire [`SIZE_LSQ_LOG-1:0]                index3LdNew;
wire [`SIZE_LSQ_LOG-1:0]                nextLD3;
wire [`SIZE_LSQ_LOG-1:0]                index3StNew;
wire [`SIZE_LSQ_LOG-1:0]                lastST3;

 wire [`SIZE_LSQ_LOG-1:0]                index0LdCom;
 wire [`SIZE_LSQ_LOG-1:0]                index0StCom;
 wire [`SIZE_LSQ_LOG-1:0]                index1LdCom;
 wire [`SIZE_LSQ_LOG-1:0]                index1StCom;
 wire [`SIZE_LSQ_LOG-1:0]                index2LdCom;
 wire [`SIZE_LSQ_LOG-1:0]                index2StCom;
 wire [`SIZE_LSQ_LOG-1:0]                index3LdCom;
 wire [`SIZE_LSQ_LOG-1:0]                index3StCom;
  reg [`SIZE_LSQ-1:0]       matchVector_ld1;
  reg [`SIZE_LSQ-1:0]       matchVector_ld2;
  reg [`SIZE_LSQ-1:0]       orderVector_t1;
  reg [`SIZE_LSQ-1:0]       orderVector_t2;
  reg [`SIZE_LSQ-1:0]       orderVector_t3;
  reg [`SIZE_LSQ-1:0]       forwardVector1;
  reg [`SIZE_LSQ-1:0]       forwardVector2;
  reg [`SIZE_LSQ_LOG-1:0]   lastStore;
  reg [`SIZE_LSQ_LOG-1:0]   normalizeTail;

  reg [`SIZE_LSQ-1:0]       matchVector_st;
  reg [`SIZE_LSQ-1:0]       matchVector_st1;
  reg [`SIZE_LSQ-1:0]       matchVector_st2;
  reg [`SIZE_LSQ-1:0]       matchVector_st3;
  reg [`SIZE_LSQ-1:0]       followVector_t1;
  reg [`SIZE_LSQ-1:0]       followVector_t2;
  reg [`SIZE_LSQ-1:0]       followVector_t3;
  reg [`SIZE_LSQ-1:0]       followVector_t4;
  reg [`SIZE_LSQ-1:0]       violateVector;
  reg [`SIZE_LSQ_LOG-1:0]   nextLoad;

reg                                     agenLdqMatch;
reg [`SIZE_LSQ_LOG-1:0]                 firstMatch;
reg                                     violateLoad;
reg [`SIZE_ACTIVELIST_LOG-1:0]          violateLdALid;
reg [`SIZE_LSQ-1:0]                     ldqValid_mispre;
reg [`SIZE_LSQ-1:0]                     stqValid_mispre;
reg [`SIZE_LSQ_LOG:0]                   mispreLD_cnt;
reg [`SIZE_LSQ_LOG:0]                   mispreST_cnt;
reg [`SIZE_LSQ_LOG-1:0]                 ldqhead_mispre;
reg [`SIZE_LSQ_LOG-1:0]                 ldqtail_mispre;
reg [`SIZE_LSQ_LOG-1:0]                 stqhead_mispre;
reg [`SIZE_LSQ_LOG-1:0]                 stqtail_mispre;
reg [`SIZE_LSQ_LOG-1:0]                 stqCommitPtr_mispre;
reg [`CHECKPOINTS-1:0]                  update_mask;

wire                                    agenLoad;
wire                                    agenStore;
wire [`EXECUTION_FLAGS-1:0]             agenFlags;
wire                                    agenLdSign;
wire [`SIZE_PC-1:0]                     agenAddress;
wire [`SIZE_DATA-1:0]                   agenData;
wire [`LDST_TYPES_LOG-1:0]              agenSize;
wire [`SIZE_LSQ_LOG-1:0]                agenLsqId;
wire [`SIZE_ISSUEQ_LOG-1:0]             agenIqId;
wire [`SIZE_ACTIVELIST_LOG-1:0]         agenALid;
wire [`SIZE_PHYSICAL_LOG-1:0]           agenDestination;
wire [`CHECKPOINTS-1:0]                 agenBranchMask_LD;
wire [`CHECKPOINTS-1:0]                 agenBranchMask_ST;
wire [`CHECKPOINTS-1:0]                 agenBranchMask;

wire                                    readHit;
wire [`SIZE_DATA-1:0]                   dcacheData;
wire                                    writeHit;

wire                                    stCommit;
wire [`SIZE_DCACHE_ADDR-1:0]            stCommitAddr;
wire [`SIZE_DATA-1:0]                   stCommitData;
wire [`LDST_TYPES_LOG-1:0]              stCommitSize;

reg                                     lsuPacketValid0;
reg [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG-1:0]
                                        lsuPacket0;
reg [`SIZE_ACTIVELIST_LOG:0]            ldViolationPacket;

L1DataCache L1dCache ( .clk(clk),
                       .reset(reset),
                       .rdEn_i(agenLoad),
                       .rdAddr_i(agenAddress),
                       .ldSize_i(agenSize),
                       `ifdef VERIFY
                       .agenALid_i(agenALid),
                       `endif
                       .ldSign_i(agenLdSign),
                       .wrEn_i(stCommit),
                       .wrAddr_i(stCommitAddr),
                       .wrData_i(stCommitData),
                       .stSize_i(stCommitSize),
                       .rdHit_o(readHit),
                       .rdData_o(dcacheData),
                       .wrHit_o(writeHit)
                     );

assign loadQueueCnt_o   =  ldqCount;
assign storeQueueCnt_o  =  stqCount;

always @(*)
begin:GENERATE_LD_CNT
 /* Following generates the final instruction count in the LD queue, taking into
  * affect New instructions and Commiting instructions in this cycle.
  */
 ldqhead_t              = ldqHead + cntLdCom;
 ldqtail_t              = ldqTail + cntLdNew;

 ldqCount_f             = (ldqCount+cntLdNew)-cntLdCom;
end

assign stCommit         = stqValid[stqHead] & stqCommit[stqHead] & ~ctrlMispredict_i & ~recoverFlag_i;
assign stCommitAddr     = {stqAddr1[stqHead],stqAddr2[stqHead]};
assign stCommitData     = stqData[stqHead];
assign stCommitSize     = stqSizeofST[stqHead];

always @(*)
begin:GENERATE_ST_CNT
 /* Following generates the final instruction count in the ST queue, taking into
  * affect New instructions and Commiting instructions in this cycle.
  */
 stqHead_f              = (stqHead+stCommit);
 stqCount_f             = (stqCount+cntStNew)-stCommit;
end

assign lsqId0_o         = (inst0Load) ? ldqId0:(inst0Store) ? stqId0:0;
assign inst0Load        = lsqPacket0_i[0] & backEndReady_i;
assign inst0Store       = lsqPacket0_i[1] & backEndReady_i;

assign lsqId1_o         = (inst1Load) ? ldqId1:(inst1Store) ? stqId1:0;
assign inst1Load        = lsqPacket1_i[0] & backEndReady_i;
assign inst1Store       = lsqPacket1_i[1] & backEndReady_i;

assign lsqId2_o         = (inst2Load) ? ldqId2:(inst2Store) ? stqId2:0;
assign inst2Load        = lsqPacket2_i[0] & backEndReady_i;
assign inst2Store       = lsqPacket2_i[1] & backEndReady_i;

assign lsqId3_o         = (inst3Load) ? ldqId3:(inst3Store) ? stqId3:0;
assign inst3Load        = lsqPacket3_i[0] & backEndReady_i;
assign inst3Store       = lsqPacket3_i[1] & backEndReady_i;

assign agenFlags           = agenPacket0_i[`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
                             `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
                             `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+
                             `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
assign agenLoad            = agenPacketValid0_i & agenFlags[4];
assign agenStore           = agenPacketValid0_i & ~agenFlags[4];
assign agenLdSign          = agenPacketValid0_i & agenFlags[6];
assign agenAddress         = agenPacket0_i[`SIZE_PC:1];
assign agenData            = agenPacket0_i[`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+
                             `SIZE_PC:`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
assign agenSize            = agenPacket0_i[`LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
                             `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+
                             `SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+
                             `SIZE_PC+1];
assign agenIqId            = agenPacket0_i[`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
                             `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
assign agenLsqId           = agenPacket0_i[`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`CHECKPOINTS_LOG+
                             `SIZE_CTI_LOG+`SIZE_PC+1];
assign agenALid            = agenPacket0_i[`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+
                             `SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+
                             `SIZE_PC+1];
assign agenDestination     = agenPacket0_i[`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+`SIZE_ISSUEQ_LOG+
                             `SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
                             `SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
assign agenBranchMask_LD   = ldqBranchTag[agenLsqId];
assign agenBranchMask_ST   = stqBranchTag[agenLsqId];
assign agenBranchMask      = (agenLoad) ? agenBranchMask_LD:agenBranchMask_ST;


always @(*)
begin:LD_Disambiguation
  integer i, j, k;
  reg [`SIZE_LSQ_LOG-1:0]       index;
  reg                           isWrap1;
  reg                           isValid;

  lastStore             = precedingST[agenLsqId];

  isWrap1               = (stqHead   > lastStore);
  isValid		= ((stqHead < stqTail) && (lastStore >= stqHead) && (lastStore < stqTail)) || 
			  ((stqTail<= stqHead) && ((lastStore<stqTail)   || (lastStore>=stqHead)));
 for(j=0;j<`SIZE_LSQ;j=j+1)
 begin
        if((stqHead <= j) && (j <= lastStore))
        begin
                orderVector_t1[j] = 1'b1;
        end
        else
        begin
                orderVector_t1[j] = 1'b0;
        end

        if((lastStore < j) && (j < stqHead))
        begin
                orderVector_t2[j] = 1'b1;
        end
        else
        begin
                orderVector_t2[j] = 1'b0;
        end
 end

 if(isWrap1 && isValid)
 begin
        orderVector_t3  =  ~orderVector_t2;
 end
 else if(isValid)
 begin
        orderVector_t3  = orderVector_t1;
 end
 else
 begin
	orderVector_t3 = 0;
 end

  for(k=0;k<`SIZE_LSQ;k=k+1)
  begin
        matchVector_ld1[k]      = (stqValid[k] & stqAddrValid[k] & (agenAddress[31:2] == stqAddr1[k]));
        matchVector_ld2[k]      = (stqValid[k] & stqAddrValid[k] & (agenAddress[1:0]  == stqAddr2[k]));
  end

  forwardVector1        = orderVector_t3 & matchVector_ld1 & matchVector_ld2;
  forwardVector2        = orderVector_t3 & matchVector_ld1 & ~matchVector_ld2;

  agenLoadReady         = readHit;
  agenLoadData          = dcacheData;

    agenStqMatch        = 0;
    lastMatch           = 0;
    partialStMatch      = 0;
    if(agenLoad && precedingSTvalid[agenLsqId])
    begin
        for(i=0;i<`SIZE_LSQ;i=i+1)
        begin
                index = i+stqHead;
                // following checks for any store-to-load forwarding case
                if(forwardVector1[index])
                begin
                        agenStqMatch    = 1'b1;
                        lastMatch       = index;
                end
                // following checks for any partial store-load match case
                if(forwardVector2[index])
                begin
                        partialStMatch  = 1'b1;
                end
        end

        if(agenStqMatch)
        begin
                agenLoadReady           = 1'b1;
                agenLoadData            = stqData[lastMatch];
        end
    end        // End of "agenLoad"
end


always @(*)
begin:LD_VIOLATION
  integer i, j, k;
  reg [`SIZE_LSQ_LOG-1:0] 	index;
  reg                           isWrap1;
  reg [`LDST_TYPES_LOG-1:0]	maxsize;
  nextLoad     		= followingLD[agenLsqId];

  //isWrap1               = (nextLoad > (ldqTail-1));
  isWrap1               = (nextLoad > ldqTail); //By Tanmay ???


 /* Create the vector corresponding to all following LDs i.e. LDs from following 
  * LD to the tail-1 of the LDQ. (these LDs might violate)
  * Check for the wrap condition.
  */
 for(j=0;j<`SIZE_LSQ;j=j+1)
 begin
        if((nextLoad <= j) && (j < ldqTail))
        begin
                followVector_t1[j] = 1'b1; 
	end
	else
	begin
		followVector_t1[j] = 1'b0;
	end

	if((ldqTail <= j) && (j < nextLoad))
        begin
                followVector_t2[j] = 1'b1;
        end
        else
        begin
                followVector_t2[j] = 1'b0;
        end
 end

 if(isWrap1)
 begin
	followVector_t3  = ~followVector_t2;
 end
 else
 begin
 	followVector_t3	 = followVector_t1;
 end
 if((ldqTail==nextLoad) && (nextLoad==ldqHead))
      for(j=0;j<`SIZE_LSQ;j=j+1)
	followVector_t4[j] = 1'b1;
 else
	followVector_t4 = followVector_t3;
  /* Following LD addr comparison with the ST addr (generated by AGEN) is pre-computed 
   * for LD violation detection. 
   */
  for(k=0;k<`SIZE_LSQ;k=k+1)
  begin
	matchVector_st1[k]= (ldqValid[k] & ldqAddrValid[k] & (agenAddress[31:2] == ldqAddr1[k])); 

	matchVector_st2[k]= (ldqValid[k] & ldqAddrValid[k] & (agenAddress[1] == ldqAddr2[k][1])); 
	matchVector_st3[k]= (ldqValid[k] & ldqAddrValid[k] & (agenAddress[0] == ldqAddr2[k][0])); 

	if(agenSize>ldqSizeofLD[k])
		maxsize = agenSize;
	else
		maxsize = ldqSizeofLD[k];
	if(maxsize==`LDST_BYTE)
		matchVector_st[k] = matchVector_st1[k] & matchVector_st2[k] & matchVector_st3[k];
	else if (maxsize==`LDST_HALF_WORD)
		 matchVector_st[k] = matchVector_st1[k] & matchVector_st2[k];
	else

 		matchVector_st[k] = matchVector_st1[k];
	
  end

  /* AND the Order vector and Match vector. Let's call it Forward Vector, a bit 
   * corresponds to the conflicting ST that would forward data to the LD.
   */ 
  violateVector 	= followVector_t4 & matchVector_st;


   /* Following logic does LD violation check. */
   /* If the address generated by AGEN is for ST instruction.
    */
    agenLdqMatch 	= 0;
    firstMatch		= 0;
    violateLoad		= 0;
    violateLdALid	= 0;	
    if(agenStore)
    begin
	for(i=0;i<`SIZE_LSQ;i=i+1)
	begin
		index = i+nextLoad;
		if(violateVector[index] & ~agenLdqMatch)
		begin	
			agenLdqMatch 	= 1'b1;	 
			firstMatch 	= index;
		end	
	
	end
	if(agenLdqMatch)
	begin
		violateLoad 		= 1'b1;
		violateLdALid		= ldq[firstMatch][`SIZE_ACTIVELIST_LOG-1:0];
	end
    end
end


assign ldViolationPacket_o = ldViolationPacket;
assign lsuPacketValid0_o   = lsuPacketValid0;
assign lsuPacket0_o        = lsuPacket0;


always @(*)
begin:SelfEvaluation
 reg [`SIZE_DATA-1:0]   agenLoadData_f;

 lsuPacketValid0        = 0;
 ldViolationPacket      = 0;
 agenLoadData_f         = 0;

 if(agenStqMatch)
 begin
        // if, Load byte instruction.
        if(agenSize == `LDST_BYTE)
        begin
                if(agenLoadData[7] && agenLdSign)
                        agenLoadData_f = {24'hFFFFFF,agenLoadData[7:0]};
                else
                        agenLoadData_f = {24'h000000,agenLoadData[7:0]};
        end

        else if(agenSize == `LDST_HALF_WORD)
        begin
                if(agenLoadData[15] && agenLdSign)
                        agenLoadData_f  = {16'hFFFF,agenLoadData[15:0]};
                else
                        agenLoadData_f  = {16'h0000,agenLoadData[15:0]};
                end
        else
                agenLoadData_f  = agenLoadData;
 end
 else
        agenLoadData_f  = agenLoadData;

 if(agenStore)
 begin
        lsuPacketValid0   = 1'b1;
        lsuPacket0        = {agenBranchMask,agenFlags,`SIZE_DATA'b0,`SIZE_PHYSICAL_LOG'b0,agenALid,agenIqId};
        ldViolationPacket = {violateLdALid,violateLoad};
 end
 else if(agenLoad && agenLoadReady)
 begin
        lsuPacketValid0   = 1'b1;
        lsuPacket0        = {agenBranchMask,(agenFlags|`EXECUTION_FLAGS'b010100),agenLoadData_f,agenDestination,agenALid,agenIqId};
        ldViolationPacket = {agenALid,partialStMatch};
 end
end

always @(*)
begin:MISPREDICT_RECOVERY
 integer                        i;
 integer                        k;
 reg [`SIZE_LSQ_LOG-1:0]        stqinsts_mispre;
 reg                            isWrap1_mispre;
 reg [`SIZE_LSQ_LOG-1:0]        diff1_mispre;
 reg [`SIZE_LSQ_LOG-1:0]        diff2_mispre;
 reg                            isWrap2_mispre;
 reg [`SIZE_LSQ_LOG-1:0]        diff3_mispre;
 reg [`SIZE_LSQ_LOG-1:0]        diff4_mispre;

 mispreLD_cnt           = 0;
 mispreST_cnt           = 0;

 for(i=0;i<`SIZE_LSQ;i=i+1)
 begin
        `ifdef VERIFY
        if(ctrlVerified_i && ctrlMispredict_i)
        begin
        `endif
                if(ldqBranchTag[i][ctrlSMTid_i] && ldqValid[i])
                begin
                        ldqValid_mispre[i] = 1'b0;
                        mispreLD_cnt       = mispreLD_cnt + 1'b1;
                end
                else
                        ldqValid_mispre[i] = ldqValid[i];

                if(stqBranchTag[i][ctrlSMTid_i] && stqValid[i])
                begin
                        stqValid_mispre[i] = 1'b0;
                        mispreST_cnt       = mispreST_cnt + 1'b1;
                end
                else
                        stqValid_mispre[i] = stqValid[i];
        `ifdef VERIFY
        end
        `endif
 end
        ldqhead_mispre = ldqHead;
        ldqtail_mispre = ldqTail - mispreLD_cnt;

        stqhead_mispre       = stqHead;
        stqtail_mispre       = stqTail - mispreST_cnt;
        stqCommitPtr_mispre  = stqCommitPtr;
end

always @(*)
begin:UPDATE_BRANCH_MASK
 integer k;

 for(k=0;k<`CHECKPOINTS;k=k+1)
 begin
   if(ctrlVerified_i && (k==ctrlSMTid_i))
        update_mask[k] = 1'b0;
   else
        update_mask[k] = 1'b1;
 end

end

always @(*)
begin:INVALIDATE_PRECEDE_ST_ON_COMMIT
 integer i;

  if(stCommit)
  begin
        for(i=0;i<`SIZE_LSQ;i=i+1)
        begin
                if(precedingST[i] == stqHead)
                begin
                        precedingSTvalid_t1[i] = 1'b0;
                end
                else
                begin
                        precedingSTvalid_t1[i] = precedingSTvalid[i];
                end
        end
  end
  else
          precedingSTvalid_t1 = precedingSTvalid;

   case({inst3Load,inst2Load,inst1Load,inst0Load})
	4'b0001:
	begin
		if((stqCount-stCommit) > 0)
		begin
			precedingSTvalid_t1[index0LdNew] = 1'b1;
		end
	end
	4'b0010:
	begin
		if((stqCount-stCommit+inst0Store ) > 0)
		begin
			precedingSTvalid_t1[index0LdNew] = 1'b1;
		end
	end
	4'b0011:
	begin
		if((stqCount-stCommit) > 0)
		begin
			precedingSTvalid_t1[index0LdNew] = 1'b1;
			precedingSTvalid_t1[index1LdNew] = 1'b1;
		end
	end
	4'b0100:
	begin
		if((stqCount-stCommit+inst1Store +inst0Store ) > 0)
		begin
			precedingSTvalid_t1[index0LdNew] = 1'b1;
		end
	end
	4'b0101:
	begin
		if((stqCount-stCommit+inst1Store ) > 0)
		begin
			precedingSTvalid_t1[index0LdNew] = 1'b1;
			precedingSTvalid_t1[index1LdNew] = 1'b1;
		end
	end
	4'b0110:
	begin
		if((stqCount-stCommit+inst0Store ) > 0)
		begin
			precedingSTvalid_t1[index0LdNew] = 1'b1;
			precedingSTvalid_t1[index1LdNew] = 1'b1;
		end
	end
	4'b0111:
	begin
		if((stqCount-stCommit) > 0)
		begin
			precedingSTvalid_t1[index0LdNew] = 1'b1;
			precedingSTvalid_t1[index1LdNew] = 1'b1;
			precedingSTvalid_t1[index2LdNew] = 1'b1;
		end
	end
	4'b1000:
	begin
		if((stqCount-stCommit+inst2Store +inst1Store +inst0Store ) > 0)
		begin
			precedingSTvalid_t1[index0LdNew] = 1'b1;
		end
	end
	4'b1001:
	begin
		if((stqCount-stCommit+inst2Store +inst1Store ) > 0)
		begin
			precedingSTvalid_t1[index0LdNew] = 1'b1;
			precedingSTvalid_t1[index1LdNew] = 1'b1;
		end
	end
	4'b1010:
	begin
		if((stqCount-stCommit+inst2Store +inst0Store ) > 0)
		begin
			precedingSTvalid_t1[index0LdNew] = 1'b1;
			precedingSTvalid_t1[index1LdNew] = 1'b1;
		end
	end
	4'b1011:
	begin
		if((stqCount-stCommit+inst2Store ) > 0)
		begin
			precedingSTvalid_t1[index0LdNew] = 1'b1;
			precedingSTvalid_t1[index1LdNew] = 1'b1;
			precedingSTvalid_t1[index2LdNew] = 1'b1;
		end
	end
	4'b1100:
	begin
		if((stqCount-stCommit+inst1Store +inst0Store ) > 0)
		begin
			precedingSTvalid_t1[index0LdNew] = 1'b1;
			precedingSTvalid_t1[index1LdNew] = 1'b1;
		end
	end
	4'b1101:
	begin
		if((stqCount-stCommit+inst1Store ) > 0)
		begin
			precedingSTvalid_t1[index0LdNew] = 1'b1;
			precedingSTvalid_t1[index1LdNew] = 1'b1;
			precedingSTvalid_t1[index2LdNew] = 1'b1;
		end
	end
	4'b1110:
	begin
		if((stqCount-stCommit+inst0Store ) > 0)
		begin
			precedingSTvalid_t1[index0LdNew] = 1'b1;
			precedingSTvalid_t1[index1LdNew] = 1'b1;
			precedingSTvalid_t1[index2LdNew] = 1'b1;
		end
	end
	4'b1111:
	begin
		if((stqCount-stCommit) > 0)
		begin
			precedingSTvalid_t1[index0LdNew] = 1'b1;
			precedingSTvalid_t1[index1LdNew] = 1'b1;
			precedingSTvalid_t1[index2LdNew] = 1'b1;
			precedingSTvalid_t1[index3LdNew] = 1'b1;
		end
	end
   endcase
end

assign inst3BrMask   = lsqPacket3_i[`CHECKPOINTS+`LSQ_FLAGS-1:`LSQ_FLAGS];
assign inst2BrMask   = lsqPacket2_i[`CHECKPOINTS+`LSQ_FLAGS-1:`LSQ_FLAGS];
assign inst1BrMask   = lsqPacket1_i[`CHECKPOINTS+`LSQ_FLAGS-1:`LSQ_FLAGS];
assign inst0BrMask   = lsqPacket0_i[`CHECKPOINTS+`LSQ_FLAGS-1:`LSQ_FLAGS];
always @(posedge clk)
begin:LDQ_UPDATE
 integer i;
 integer l;

 if(reset)
 begin
        ldqHead                 <= 0;
        ldqTail                 <= 0;
        ldqValid                <= 0;
        ldqAddrValid            <= 0;
        ldqWriteBack            <= 0;
        precedingSTvalid        <= 0;
        for(i=0;i<`SIZE_LSQ;i=i+1)
        begin
                ldq[i]          <= 0;
                ldqSizeofLD[i]  <= 0;
                ldqAddr1[i]     <= 0;
                ldqAddr2[i]     <= 0;
                ldqData[i]      <= 0;
                ldqBranchTag[i] <= 0;
                precedingST[i]  <= 0;
        end
 end

 else if(ctrlMispredict_i)
 begin
    ldqTail             <= ldqtail_mispre;
    ldqHead             <= ldqhead_mispre + cntLdCom;  // By Tanmay ???
    ldqValid            <= ldqValid_mispre;
    precedingSTvalid    <= precedingSTvalid & ldqValid_mispre;
 end
 else
 begin

    ldqTail  <= ldqtail_t;
    ldqHead  <= ldqhead_t;

    precedingSTvalid                       <= precedingSTvalid_t1;

    for(l=0;l<`SIZE_LSQ;l=l+1)
    begin
        ldqBranchTag[l] <= ldqBranchTag[l] & update_mask;
    end

   case({inst3Load,inst2Load,inst1Load,inst0Load})
	4'b0001:
	begin
                ldqValid[index0LdNew]      <= 1'b1;
                ldqAddrValid[index0LdNew]  <= 1'b0;
                ldqBranchTag[index0LdNew]  <= inst0BrMask;
                precedingST[index0LdNew]   <= lastST0;
	end
	4'b0010:
	begin
                ldqValid[index0LdNew]      <= 1'b1;
                ldqAddrValid[index0LdNew]  <= 1'b0;
                ldqBranchTag[index0LdNew]  <= inst1BrMask;
                precedingST[index0LdNew]   <= lastST1;
	end
	4'b0011:
	begin
                ldqValid[index0LdNew]      <= 1'b1;
                ldqAddrValid[index0LdNew]  <= 1'b0;
                ldqBranchTag[index0LdNew]  <= inst0BrMask;
                precedingST[index0LdNew]   <= lastST0;
                ldqValid[index1LdNew]      <= 1'b1;
                ldqAddrValid[index1LdNew]  <= 1'b0;
                ldqBranchTag[index1LdNew]  <= inst1BrMask;
                precedingST[index1LdNew]   <= lastST1;
	end
	4'b0100:
	begin
                ldqValid[index0LdNew]      <= 1'b1;
                ldqAddrValid[index0LdNew]  <= 1'b0;
                ldqBranchTag[index0LdNew]  <= inst2BrMask;
                precedingST[index0LdNew]   <= lastST2;
	end
	4'b0101:
	begin
                ldqValid[index0LdNew]      <= 1'b1;
                ldqAddrValid[index0LdNew]  <= 1'b0;
                ldqBranchTag[index0LdNew]  <= inst0BrMask;
                precedingST[index0LdNew]   <= lastST0;
                ldqValid[index1LdNew]      <= 1'b1;
                ldqAddrValid[index1LdNew]  <= 1'b0;
                ldqBranchTag[index1LdNew]  <= inst2BrMask;
                precedingST[index1LdNew]   <= lastST2;
	end
	4'b0110:
	begin
                ldqValid[index0LdNew]      <= 1'b1;
                ldqAddrValid[index0LdNew]  <= 1'b0;
                ldqBranchTag[index0LdNew]  <= inst1BrMask;
                precedingST[index0LdNew]   <= lastST1;
                ldqValid[index1LdNew]      <= 1'b1;
                ldqAddrValid[index1LdNew]  <= 1'b0;
                ldqBranchTag[index1LdNew]  <= inst2BrMask;
                precedingST[index1LdNew]   <= lastST2;
	end
	4'b0111:
	begin
                ldqValid[index0LdNew]      <= 1'b1;
                ldqAddrValid[index0LdNew]  <= 1'b0;
                ldqBranchTag[index0LdNew]  <= inst0BrMask;
                precedingST[index0LdNew]   <= lastST0;
                ldqValid[index1LdNew]      <= 1'b1;
                ldqAddrValid[index1LdNew]  <= 1'b0;
                ldqBranchTag[index1LdNew]  <= inst1BrMask;
                precedingST[index1LdNew]   <= lastST1;
                ldqValid[index2LdNew]      <= 1'b1;
                ldqAddrValid[index2LdNew]  <= 1'b0;
                ldqBranchTag[index2LdNew]  <= inst2BrMask;
                precedingST[index2LdNew]   <= lastST2;
	end
	4'b1000:
	begin
                ldqValid[index0LdNew]      <= 1'b1;
                ldqAddrValid[index0LdNew]  <= 1'b0;
                ldqBranchTag[index0LdNew]  <= inst3BrMask;
                precedingST[index0LdNew]   <= lastST3;
	end
	4'b1001:
	begin
                ldqValid[index0LdNew]      <= 1'b1;
                ldqAddrValid[index0LdNew]  <= 1'b0;
                ldqBranchTag[index0LdNew]  <= inst0BrMask;
                precedingST[index0LdNew]   <= lastST0;
                ldqValid[index1LdNew]      <= 1'b1;
                ldqAddrValid[index1LdNew]  <= 1'b0;
                ldqBranchTag[index1LdNew]  <= inst3BrMask;
                precedingST[index1LdNew]   <= lastST3;
	end
	4'b1010:
	begin
                ldqValid[index0LdNew]      <= 1'b1;
                ldqAddrValid[index0LdNew]  <= 1'b0;
                ldqBranchTag[index0LdNew]  <= inst1BrMask;
                precedingST[index0LdNew]   <= lastST1;
                ldqValid[index1LdNew]      <= 1'b1;
                ldqAddrValid[index1LdNew]  <= 1'b0;
                ldqBranchTag[index1LdNew]  <= inst3BrMask;
                precedingST[index1LdNew]   <= lastST3;
	end
	4'b1011:
	begin
                ldqValid[index0LdNew]      <= 1'b1;
                ldqAddrValid[index0LdNew]  <= 1'b0;
                ldqBranchTag[index0LdNew]  <= inst0BrMask;
                precedingST[index0LdNew]   <= lastST0;
                ldqValid[index1LdNew]      <= 1'b1;
                ldqAddrValid[index1LdNew]  <= 1'b0;
                ldqBranchTag[index1LdNew]  <= inst1BrMask;
                precedingST[index1LdNew]   <= lastST1;
                ldqValid[index2LdNew]      <= 1'b1;
                ldqAddrValid[index2LdNew]  <= 1'b0;
                ldqBranchTag[index2LdNew]  <= inst3BrMask;
                precedingST[index2LdNew]   <= lastST3;
	end
	4'b1100:
	begin
                ldqValid[index0LdNew]      <= 1'b1;
                ldqAddrValid[index0LdNew]  <= 1'b0;
                ldqBranchTag[index0LdNew]  <= inst2BrMask;
                precedingST[index0LdNew]   <= lastST2;
                ldqValid[index1LdNew]      <= 1'b1;
                ldqAddrValid[index1LdNew]  <= 1'b0;
                ldqBranchTag[index1LdNew]  <= inst3BrMask;
                precedingST[index1LdNew]   <= lastST3;
	end
	4'b1101:
	begin
                ldqValid[index0LdNew]      <= 1'b1;
                ldqAddrValid[index0LdNew]  <= 1'b0;
                ldqBranchTag[index0LdNew]  <= inst0BrMask;
                precedingST[index0LdNew]   <= lastST0;
                ldqValid[index1LdNew]      <= 1'b1;
                ldqAddrValid[index1LdNew]  <= 1'b0;
                ldqBranchTag[index1LdNew]  <= inst2BrMask;
                precedingST[index1LdNew]   <= lastST2;
                ldqValid[index2LdNew]      <= 1'b1;
                ldqAddrValid[index2LdNew]  <= 1'b0;
                ldqBranchTag[index2LdNew]  <= inst3BrMask;
                precedingST[index2LdNew]   <= lastST3;
	end
	4'b1110:
	begin
                ldqValid[index0LdNew]      <= 1'b1;
                ldqAddrValid[index0LdNew]  <= 1'b0;
                ldqBranchTag[index0LdNew]  <= inst1BrMask;
                precedingST[index0LdNew]   <= lastST1;
                ldqValid[index1LdNew]      <= 1'b1;
                ldqAddrValid[index1LdNew]  <= 1'b0;
                ldqBranchTag[index1LdNew]  <= inst2BrMask;
                precedingST[index1LdNew]   <= lastST2;
                ldqValid[index2LdNew]      <= 1'b1;
                ldqAddrValid[index2LdNew]  <= 1'b0;
                ldqBranchTag[index2LdNew]  <= inst3BrMask;
                precedingST[index2LdNew]   <= lastST3;
	end
	4'b1111:
	begin
                ldqValid[index0LdNew]      <= 1'b1;
                ldqAddrValid[index0LdNew]  <= 1'b0;
                ldqBranchTag[index0LdNew]  <= inst0BrMask;
                precedingST[index0LdNew]   <= lastST0;
                ldqValid[index1LdNew]      <= 1'b1;
                ldqAddrValid[index1LdNew]  <= 1'b0;
                ldqBranchTag[index1LdNew]  <= inst1BrMask;
                precedingST[index1LdNew]   <= lastST1;
                ldqValid[index2LdNew]      <= 1'b1;
                ldqAddrValid[index2LdNew]  <= 1'b0;
                ldqBranchTag[index2LdNew]  <= inst2BrMask;
                precedingST[index2LdNew]   <= lastST2;
                ldqValid[index3LdNew]      <= 1'b1;
                ldqAddrValid[index3LdNew]  <= 1'b0;
                ldqBranchTag[index3LdNew]  <= inst3BrMask;
                precedingST[index3LdNew]   <= lastST3;
	end
	endcase

	case(cntLdCom)
	4'd1:
	begin
                ldqValid[index0LdCom]           <= 1'b0;
                ldqAddrValid[index0LdCom]       <= 1'b0;
                ldqWriteBack[index0LdCom]       <= 1'b0;
                `ifdef VERIFY
                precedingST[index0LdCom]        <= 0;
                precedingSTvalid[index0LdCom]   <= 0;
                `endif

	end
	4'd2:
	begin
                ldqValid[index0LdCom]           <= 1'b0;
                ldqAddrValid[index0LdCom]       <= 1'b0;
                ldqWriteBack[index0LdCom]       <= 1'b0;
                `ifdef VERIFY
                precedingST[index0LdCom]        <= 0;
                precedingSTvalid[index0LdCom]   <= 0;
                `endif

                ldqValid[index1LdCom]           <= 1'b0;
                ldqAddrValid[index1LdCom]       <= 1'b0;
                ldqWriteBack[index1LdCom]       <= 1'b0;
                `ifdef VERIFY
                precedingST[index1LdCom]        <= 0;
                precedingSTvalid[index1LdCom]   <= 0;
                `endif

	end
	4'd3:
	begin
                ldqValid[index0LdCom]           <= 1'b0;
                ldqAddrValid[index0LdCom]       <= 1'b0;
                ldqWriteBack[index0LdCom]       <= 1'b0;
                `ifdef VERIFY
                precedingST[index0LdCom]        <= 0;
                precedingSTvalid[index0LdCom]   <= 0;
                `endif

                ldqValid[index1LdCom]           <= 1'b0;
                ldqAddrValid[index1LdCom]       <= 1'b0;
                ldqWriteBack[index1LdCom]       <= 1'b0;
                `ifdef VERIFY
                precedingST[index1LdCom]        <= 0;
                precedingSTvalid[index1LdCom]   <= 0;
                `endif

                ldqValid[index2LdCom]           <= 1'b0;
                ldqAddrValid[index2LdCom]       <= 1'b0;
                ldqWriteBack[index2LdCom]       <= 1'b0;
                `ifdef VERIFY
                precedingST[index2LdCom]        <= 0;
                precedingSTvalid[index2LdCom]   <= 0;
                `endif

	end
	4'd4:
	begin
                ldqValid[index0LdCom]           <= 1'b0;
                ldqAddrValid[index0LdCom]       <= 1'b0;
                ldqWriteBack[index0LdCom]       <= 1'b0;
                `ifdef VERIFY
                precedingST[index0LdCom]        <= 0;
                precedingSTvalid[index0LdCom]   <= 0;
                `endif

                ldqValid[index1LdCom]           <= 1'b0;
                ldqAddrValid[index1LdCom]       <= 1'b0;
                ldqWriteBack[index1LdCom]       <= 1'b0;
                `ifdef VERIFY
                precedingST[index1LdCom]        <= 0;
                precedingSTvalid[index1LdCom]   <= 0;
                `endif

                ldqValid[index2LdCom]           <= 1'b0;
                ldqAddrValid[index2LdCom]       <= 1'b0;
                ldqWriteBack[index2LdCom]       <= 1'b0;
                `ifdef VERIFY
                precedingST[index2LdCom]        <= 0;
                precedingSTvalid[index2LdCom]   <= 0;
                `endif

                ldqValid[index3LdCom]           <= 1'b0;
                ldqAddrValid[index3LdCom]       <= 1'b0;
                ldqWriteBack[index3LdCom]       <= 1'b0;
                `ifdef VERIFY
                precedingST[index3LdCom]        <= 0;
                precedingSTvalid[index3LdCom]   <= 0;
                `endif

	end
	endcase
end

 if(agenLoad)
 begin
    ldq[agenLsqId]                        <=  {agenIqId,agenDestination,agenALid};
    ldqAddrValid[agenLsqId]               <=  1'b1;
    ldqAddr1[agenLsqId]                   <=  agenAddress[31:2];
    ldqAddr2[agenLsqId]                   <=  agenAddress[1:0];
    ldqSizeofLD[agenLsqId]                <=  agenSize;

    if(agenStqMatch)
        begin
                ldqData[agenLsqId]        <=  agenLoadData;
        end
        else if(readHit)
        begin
                ldqData[agenLsqId]        <=  dcacheData;
    end

    // Following updates the WriteBack bit for Load Queue, if the result is
    // broadcasted this cycle and writen back to Active List.
    if(agenLoad && agenLoadReady)
    begin
        ldqWriteBack[agenLsqId]           <= 1'b1;
    end
 end

end

always @(posedge clk)
begin
 if(reset)
 begin
        ldqCount     <= 0;
 end
 else
 begin
        if(ctrlMispredict_i)
                ldqCount     <= ldqCount - mispreLD_cnt+ cntLdNew -cntLdCom; // By Tanmay ???
        else
                ldqCount     <= ldqCount_f;
 end
end

always @(posedge clk)
begin:STQ_UPDATE
 integer i;
 integer l;

 if(reset)
 begin
        stqHead                 <= 0;
        stqTail                 <= 0;
        stqValid                <= 0;
        stqAddrValid            <= 0;
        stqCommitPtr            <= 0;
        for(i=0;i<`SIZE_LSQ;i=i+1)
        begin
                stq[i]          <= 0;
                stqSizeofST[i]  <= 0;
                stqAddr1[i]     <= 0;
                stqAddr2[i]     <= 0;
                stqData[i]      <= 0;
                stqBranchTag[i] <= 0;
        end
 end

 else if(ctrlMispredict_i)
 begin
        stqTail                 <= stqtail_mispre;
        stqHead                 <= stqhead_mispre;
        stqValid                <= stqValid_mispre;
        stqCommitPtr            <= stqCommitPtr_mispre + cntStCom; // By Tanmay ???
 end

 else
 begin
    stqTail  <= stqTail + cntStNew;
    stqHead  <= stqHead + stCommit;

    if(stCommit)
    begin
        stqValid[stqHead]       <= 1'b0;
        stqAddrValid[stqHead]   <= 1'b0;
        //stqCommit[stqHead]      <= 1'b0;
    end

    for(l=0;l<`SIZE_LSQ;l=l+1)
    begin
        stqBranchTag[l] <= stqBranchTag[l] & update_mask;
    end

    stqCommitPtr                <= stqCommitPtr + cntStCom;

    if(backEndReady_i)
    begin

   case({inst3Store,inst2Store,inst1Store,inst0Store})
	4'b0001:
	begin
                stqValid[index0StNew]      <= 1'b1;
                stqBranchTag[index0StNew]  <= inst0BrMask;
                followingLD[index0StNew]   <= nextLD0;
                stqAddr1[index0StNew]      <= 0;
                stqAddr2[index0StNew]      <= 0;
                stqAddrValid[index0StNew]  <= 0;
                stqData[index0StNew]       <= 0;

	end
	4'b0010:
	begin
                stqValid[index0StNew]      <= 1'b1;
                stqBranchTag[index0StNew]  <= inst1BrMask;
                followingLD[index0StNew]   <= nextLD1;
                stqAddr1[index0StNew]      <= 0;
                stqAddr2[index0StNew]      <= 0;
                stqAddrValid[index0StNew]  <= 0;
                stqData[index0StNew]       <= 0;

	end
	4'b0011:
	begin
                stqValid[index0StNew]      <= 1'b1;
                stqBranchTag[index0StNew]  <= inst0BrMask;
                followingLD[index0StNew]   <= nextLD0;
                stqAddr1[index0StNew]      <= 0;
                stqAddr2[index0StNew]      <= 0;
                stqAddrValid[index0StNew]  <= 0;
                stqData[index0StNew]       <= 0;

                stqValid[index1StNew]      <= 1'b1;
                stqBranchTag[index1StNew]  <= inst1BrMask;
                followingLD[index1StNew]   <= nextLD1;
                stqAddr1[index1StNew]      <= 0;
                stqAddr2[index1StNew]      <= 0;
                stqAddrValid[index1StNew]  <= 0;
                stqData[index1StNew]       <= 0;

	end
	4'b0100:
	begin
                stqValid[index0StNew]      <= 1'b1;
                stqBranchTag[index0StNew]  <= inst2BrMask;
                followingLD[index0StNew]   <= nextLD2;
                stqAddr1[index0StNew]      <= 0;
                stqAddr2[index0StNew]      <= 0;
                stqAddrValid[index0StNew]  <= 0;
                stqData[index0StNew]       <= 0;

	end
	4'b0101:
	begin
                stqValid[index0StNew]      <= 1'b1;
                stqBranchTag[index0StNew]  <= inst0BrMask;
                followingLD[index0StNew]   <= nextLD0;
                stqAddr1[index0StNew]      <= 0;
                stqAddr2[index0StNew]      <= 0;
                stqAddrValid[index0StNew]  <= 0;
                stqData[index0StNew]       <= 0;

                stqValid[index1StNew]      <= 1'b1;
                stqBranchTag[index1StNew]  <= inst2BrMask;
                followingLD[index1StNew]   <= nextLD2;
                stqAddr1[index1StNew]      <= 0;
                stqAddr2[index1StNew]      <= 0;
                stqAddrValid[index1StNew]  <= 0;
                stqData[index1StNew]       <= 0;

	end
	4'b0110:
	begin
                stqValid[index0StNew]      <= 1'b1;
                stqBranchTag[index0StNew]  <= inst1BrMask;
                followingLD[index0StNew]   <= nextLD1;
                stqAddr1[index0StNew]      <= 0;
                stqAddr2[index0StNew]      <= 0;
                stqAddrValid[index0StNew]  <= 0;
                stqData[index0StNew]       <= 0;

                stqValid[index1StNew]      <= 1'b1;
                stqBranchTag[index1StNew]  <= inst2BrMask;
                followingLD[index1StNew]   <= nextLD2;
                stqAddr1[index1StNew]      <= 0;
                stqAddr2[index1StNew]      <= 0;
                stqAddrValid[index1StNew]  <= 0;
                stqData[index1StNew]       <= 0;

	end
	4'b0111:
	begin
                stqValid[index0StNew]      <= 1'b1;
                stqBranchTag[index0StNew]  <= inst0BrMask;
                followingLD[index0StNew]   <= nextLD0;
                stqAddr1[index0StNew]      <= 0;
                stqAddr2[index0StNew]      <= 0;
                stqAddrValid[index0StNew]  <= 0;
                stqData[index0StNew]       <= 0;

                stqValid[index1StNew]      <= 1'b1;
                stqBranchTag[index1StNew]  <= inst1BrMask;
                followingLD[index1StNew]   <= nextLD1;
                stqAddr1[index1StNew]      <= 0;
                stqAddr2[index1StNew]      <= 0;
                stqAddrValid[index1StNew]  <= 0;
                stqData[index1StNew]       <= 0;

                stqValid[index2StNew]      <= 1'b1;
                stqBranchTag[index2StNew]  <= inst2BrMask;
                followingLD[index2StNew]   <= nextLD2;
                stqAddr1[index2StNew]      <= 0;
                stqAddr2[index2StNew]      <= 0;
                stqAddrValid[index2StNew]  <= 0;
                stqData[index2StNew]       <= 0;

	end
	4'b1000:
	begin
                stqValid[index0StNew]      <= 1'b1;
                stqBranchTag[index0StNew]  <= inst3BrMask;
                followingLD[index0StNew]   <= nextLD3;
                stqAddr1[index0StNew]      <= 0;
                stqAddr2[index0StNew]      <= 0;
                stqAddrValid[index0StNew]  <= 0;
                stqData[index0StNew]       <= 0;

	end
	4'b1001:
	begin
                stqValid[index0StNew]      <= 1'b1;
                stqBranchTag[index0StNew]  <= inst0BrMask;
                followingLD[index0StNew]   <= nextLD0;
                stqAddr1[index0StNew]      <= 0;
                stqAddr2[index0StNew]      <= 0;
                stqAddrValid[index0StNew]  <= 0;
                stqData[index0StNew]       <= 0;

                stqValid[index1StNew]      <= 1'b1;
                stqBranchTag[index1StNew]  <= inst3BrMask;
                followingLD[index1StNew]   <= nextLD3;
                stqAddr1[index1StNew]      <= 0;
                stqAddr2[index1StNew]      <= 0;
                stqAddrValid[index1StNew]  <= 0;
                stqData[index1StNew]       <= 0;

	end
	4'b1010:
	begin
                stqValid[index0StNew]      <= 1'b1;
                stqBranchTag[index0StNew]  <= inst1BrMask;
                followingLD[index0StNew]   <= nextLD1;
                stqAddr1[index0StNew]      <= 0;
                stqAddr2[index0StNew]      <= 0;
                stqAddrValid[index0StNew]  <= 0;
                stqData[index0StNew]       <= 0;

                stqValid[index1StNew]      <= 1'b1;
                stqBranchTag[index1StNew]  <= inst3BrMask;
                followingLD[index1StNew]   <= nextLD3;
                stqAddr1[index1StNew]      <= 0;
                stqAddr2[index1StNew]      <= 0;
                stqAddrValid[index1StNew]  <= 0;
                stqData[index1StNew]       <= 0;

	end
	4'b1011:
	begin
                stqValid[index0StNew]      <= 1'b1;
                stqBranchTag[index0StNew]  <= inst0BrMask;
                followingLD[index0StNew]   <= nextLD0;
                stqAddr1[index0StNew]      <= 0;
                stqAddr2[index0StNew]      <= 0;
                stqAddrValid[index0StNew]  <= 0;
                stqData[index0StNew]       <= 0;

                stqValid[index1StNew]      <= 1'b1;
                stqBranchTag[index1StNew]  <= inst1BrMask;
                followingLD[index1StNew]   <= nextLD1;
                stqAddr1[index1StNew]      <= 0;
                stqAddr2[index1StNew]      <= 0;
                stqAddrValid[index1StNew]  <= 0;
                stqData[index1StNew]       <= 0;

                stqValid[index2StNew]      <= 1'b1;
                stqBranchTag[index2StNew]  <= inst3BrMask;
                followingLD[index2StNew]   <= nextLD3;
                stqAddr1[index2StNew]      <= 0;
                stqAddr2[index2StNew]      <= 0;
                stqAddrValid[index2StNew]  <= 0;
                stqData[index2StNew]       <= 0;

	end
	4'b1100:
	begin
                stqValid[index0StNew]      <= 1'b1;
                stqBranchTag[index0StNew]  <= inst2BrMask;
                followingLD[index0StNew]   <= nextLD2;
                stqAddr1[index0StNew]      <= 0;
                stqAddr2[index0StNew]      <= 0;
                stqAddrValid[index0StNew]  <= 0;
                stqData[index0StNew]       <= 0;

                stqValid[index1StNew]      <= 1'b1;
                stqBranchTag[index1StNew]  <= inst3BrMask;
                followingLD[index1StNew]   <= nextLD3;
                stqAddr1[index1StNew]      <= 0;
                stqAddr2[index1StNew]      <= 0;
                stqAddrValid[index1StNew]  <= 0;
                stqData[index1StNew]       <= 0;

	end
	4'b1101:
	begin
                stqValid[index0StNew]      <= 1'b1;
                stqBranchTag[index0StNew]  <= inst0BrMask;
                followingLD[index0StNew]   <= nextLD0;
                stqAddr1[index0StNew]      <= 0;
                stqAddr2[index0StNew]      <= 0;
                stqAddrValid[index0StNew]  <= 0;
                stqData[index0StNew]       <= 0;

                stqValid[index1StNew]      <= 1'b1;
                stqBranchTag[index1StNew]  <= inst2BrMask;
                followingLD[index1StNew]   <= nextLD2;
                stqAddr1[index1StNew]      <= 0;
                stqAddr2[index1StNew]      <= 0;
                stqAddrValid[index1StNew]  <= 0;
                stqData[index1StNew]       <= 0;

                stqValid[index2StNew]      <= 1'b1;
                stqBranchTag[index2StNew]  <= inst3BrMask;
                followingLD[index2StNew]   <= nextLD3;
                stqAddr1[index2StNew]      <= 0;
                stqAddr2[index2StNew]      <= 0;
                stqAddrValid[index2StNew]  <= 0;
                stqData[index2StNew]       <= 0;

	end
	4'b1110:
	begin
                stqValid[index0StNew]      <= 1'b1;
                stqBranchTag[index0StNew]  <= inst1BrMask;
                followingLD[index0StNew]   <= nextLD1;
                stqAddr1[index0StNew]      <= 0;
                stqAddr2[index0StNew]      <= 0;
                stqAddrValid[index0StNew]  <= 0;
                stqData[index0StNew]       <= 0;

                stqValid[index1StNew]      <= 1'b1;
                stqBranchTag[index1StNew]  <= inst2BrMask;
                followingLD[index1StNew]   <= nextLD2;
                stqAddr1[index1StNew]      <= 0;
                stqAddr2[index1StNew]      <= 0;
                stqAddrValid[index1StNew]  <= 0;
                stqData[index1StNew]       <= 0;

                stqValid[index2StNew]      <= 1'b1;
                stqBranchTag[index2StNew]  <= inst3BrMask;
                followingLD[index2StNew]   <= nextLD3;
                stqAddr1[index2StNew]      <= 0;
                stqAddr2[index2StNew]      <= 0;
                stqAddrValid[index2StNew]  <= 0;
                stqData[index2StNew]       <= 0;

	end
	4'b1111:
	begin
                stqValid[index0StNew]      <= 1'b1;
                stqBranchTag[index0StNew]  <= inst0BrMask;
                followingLD[index0StNew]   <= nextLD0;
                stqAddr1[index0StNew]      <= 0;
                stqAddr2[index0StNew]      <= 0;
                stqAddrValid[index0StNew]  <= 0;
                stqData[index0StNew]       <= 0;

                stqValid[index1StNew]      <= 1'b1;
                stqBranchTag[index1StNew]  <= inst1BrMask;
                followingLD[index1StNew]   <= nextLD1;
                stqAddr1[index1StNew]      <= 0;
                stqAddr2[index1StNew]      <= 0;
                stqAddrValid[index1StNew]  <= 0;
                stqData[index1StNew]       <= 0;

                stqValid[index2StNew]      <= 1'b1;
                stqBranchTag[index2StNew]  <= inst2BrMask;
                followingLD[index2StNew]   <= nextLD2;
                stqAddr1[index2StNew]      <= 0;
                stqAddr2[index2StNew]      <= 0;
                stqAddrValid[index2StNew]  <= 0;
                stqData[index2StNew]       <= 0;

                stqValid[index3StNew]      <= 1'b1;
                stqBranchTag[index3StNew]  <= inst3BrMask;
                followingLD[index3StNew]   <= nextLD3;
                stqAddr1[index3StNew]      <= 0;
                stqAddr2[index3StNew]      <= 0;
                stqAddrValid[index3StNew]  <= 0;
                stqData[index3StNew]       <= 0;

	end
	endcase
 end
end

 if(agenStore)  // If the address generated by AGEN is for ST instruction
 begin
        stqAddrValid[agenLsqId] <= 1'b1;
        stq[agenLsqId]          <= {agenIqId,agenALid};
        stqSizeofST[agenLsqId]  <= agenSize;
        stqAddr1[agenLsqId]     <= agenAddress[31:2];
        stqAddr2[agenLsqId]     <= agenAddress[1:0];
        stqData[agenLsqId]      <= agenData;

 end
end

always @(posedge clk)
begin:STQ_COMMIT_VEC_UPDATE
        if(reset)
                stqCommit               <= 0;
        else
        begin
	if(stCommit & ~ctrlMispredict_i)
        begin
                stqCommit[stqHead]      <= 1'b0;
        end

        case(cntStCom)
	4'd1:
	begin
                        stqCommit[index0StCom]      <= 1'b1;	
	end
	4'd2:
	begin
                        stqCommit[index0StCom]      <= 1'b1;	
                        stqCommit[index1StCom]      <= 1'b1;	
	end
	4'd3:
	begin
                        stqCommit[index0StCom]      <= 1'b1;	
                        stqCommit[index1StCom]      <= 1'b1;	
                        stqCommit[index2StCom]      <= 1'b1;	
	end
	4'd4:
	begin
                        stqCommit[index0StCom]      <= 1'b1;	
                        stqCommit[index1StCom]      <= 1'b1;	
                        stqCommit[index2StCom]      <= 1'b1;	
                        stqCommit[index3StCom]      <= 1'b1;	
	end
	endcase
	end
end


always @(posedge clk)
begin
 if(reset)
 begin
        stqCount     <= 0;
 end
 else
 begin
        if(ctrlMispredict_i)
                stqCount     <= stqCount - mispreST_cnt;
        else
                stqCount     <= stqCount_f;
 end
end

`ifdef VERIFY
always @(*)
begin:WRITE_PENDING_COMMIT_TO_DCACHE_ON_RECOVERY
 reg [`SIZE_DCACHE_ADDR-1:0]            wrAddr;
 reg [`SIZE_DCACHE_ADDR-1:0]            stCommitAddr_rf;
 reg [`SIZE_DATA-1:0]                   stCommitData_rf;
 reg [`LDST_TYPES_LOG-1:0]              stCommitSize_rf;
 reg [`SIZE_LSQ_LOG-1:0]                index;
 reg                                    stCommit_rf;

 if(recoverFlag_i)
 begin
        for(index=stqHead; index != stqCommitPtr; index=index+1'b1)
        begin
           stCommit_rf = stqValid[index] & stqCommit[index];
           if(stCommit_rf)
           begin
                stCommitAddr_rf     = {stqAddr1[index],stqAddr2[index]};
                stCommitData_rf     = stqData[index];
                stCommitSize_rf     = stqSizeofST[index];
                case(stCommitSize_rf)
                `LDST_BYTE:
                begin
                        wrAddr = stCommitAddr_rf;
                        $writeByte(stCommitData_rf,wrAddr);
                end
                `LDST_HALF_WORD:
                begin
                        wrAddr = {stCommitAddr_rf[31:1],1'b0};
                        $writeHalf(stCommitData_rf,wrAddr);
                end
                `LDST_WORD:
                begin
                        wrAddr = {stCommitAddr_rf[31:2],2'b0};
                        $writeWord(stCommitData_rf,wrAddr);
                end
                endcase
           end
        end
 end
end
`endif


DispatchedLoad disLoad   (
                           .inst0Load_i(inst0Load),
                           .ldqId0_o(ldqId0),
                           .index0LdNew_o(index0LdNew),
                           .nextLD0_o(nextLD0),

                           .inst1Load_i(inst1Load),
                           .ldqId1_o(ldqId1),
                           .index1LdNew_o(index1LdNew),
                           .nextLD1_o(nextLD1),

                           .inst2Load_i(inst2Load),
                           .ldqId2_o(ldqId2),
                           .index2LdNew_o(index2LdNew),
                           .nextLD2_o(nextLD2),

                           .inst3Load_i(inst3Load),
                           .ldqId3_o(ldqId3),
                           .index3LdNew_o(index3LdNew),
                           .nextLD3_o(nextLD3),

                           .ldqHead_i(ldqHead),
                           .ldqTail_i(ldqTail),
                           .ldqInsts_i(ldqCount),
                           .cntLdNew_o(cntLdNew)
                         );


DispatchedStore disStore   (
                          .inst0Store_i(inst0Store),
                          .stqId0_o(stqId0),
                          .index0StNew_o(index0StNew),
                          .lastST0_o(lastST0),

                          .inst1Store_i(inst1Store),
                          .stqId1_o(stqId1),
                          .index1StNew_o(index1StNew),
                          .lastST1_o(lastST1),

                          .inst2Store_i(inst2Store),
                          .stqId2_o(stqId2),
                          .index2StNew_o(index2StNew),
                          .lastST2_o(lastST2),

                          .inst3Store_i(inst3Store),
                          .stqId3_o(stqId3),
                          .index3StNew_o(index3StNew),
                          .lastST3_o(lastST3),

                          .stqTail_i(stqTail),
                          .stqHead_i((stqHead_f)),
                          .stqInsts_i(stqCount),
                          .cntStNew_o(cntStNew)
			);


CommitLoad commitLoad ( 
		.commitLoad0_i(commitLoad0_i),
		.index0LdCom_o(index0LdCom),
		.commitLoad1_i(commitLoad1_i),
		.index1LdCom_o(index1LdCom),
		.commitLoad2_i(commitLoad2_i),
		.index2LdCom_o(index2LdCom),
		.commitLoad3_i(commitLoad3_i),
		.index3LdCom_o(index3LdCom),
                        .ldqHead_i(ldqHead),
                        .cntLdCom_o(cntLdCom)
			);


CommitStore commitStore ( 
		.commitStore0_i(commitStore0_i),
		.index0StCom_o(index0StCom),
		.commitStore1_i(commitStore1_i),
		.index1StCom_o(index1StCom),
		.commitStore2_i(commitStore2_i),
		.index2StCom_o(index2StCom),
		.commitStore3_i(commitStore3_i),
		.index3StCom_o(index3StCom),
                          .stqCommitPtr_i(stqCommitPtr),
                          .cntStCom_o(cntStCom)
			);

endmodule

