#!/usr/bin/perl
use POSIX qw(ceil floor);

################################################################################
#                       NORTH CAROLINA STATE UNIVERSITY
#
#                              FabScalar Project
#
# FabScalar Copyright (c) 2007-2011 by Niket K. Choudhary, Salil Wadhavkar,
# and Eric Rotenberg.  All Rights Reserved.
#
# This is a beta-release version.  It must not be redistributed at this time.
#
# Purpose: To gerate the LoadStoreUnit.
################################################################################

  sub error_ussage{
	print "Usage: perl ./generate_LSU.pl -w <dispatch_width> -c <commit width> \n";
        exit;
  }
  sub dec2bin {
      my $str 		= unpack("B32", pack("N", shift));
      #my @number 	= split("", $str); 
      #my $sting 	= 
      #$str =~ s/^0+(?=\d)//;   # otherwise you'll get leading zeros
      return $str;
  }
  #Read command line arguments
  $no_of_args = 0;
  while(@ARGV){
	$_ = shift;
	if(/^-w$/){
		$widthPipe = shift;
		$no_of_args++;
	}
	elsif(/^-c$/){
                $CommitWidth = shift;
                $no_of_args++;
	}
	else{
		print "Error: Unrecognized argument $_.\n";
		&error_ussage();
	}
  }  

  if($no_of_args != 2){
	print "Too few arguments... \n";
	&error_ussage();
  }
  $width_dec = $widthPipe - 1;
  #$outfile="LoadStoreUnit_n.v";
  #open(FileHandle,">LoadStoreUnit_n.v") || die "Error: Could not open $outfile for writing";
  #$FilePtr = FileHandle;
  $FilePtr = STDOUT;

  print $FilePtr <<LABEL;
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

LABEL

  for($i=0; $i<$widthPipe; $i++){
	print $FilePtr <<LABEL;
             input [`CHECKPOINTS+`LSQ_FLAGS-1:0] lsqPacket${i}_i,
             output [`SIZE_LSQ_LOG-1:0] lsqId${i}_o,          // LSQ entry num of inst-0 (for Issue Queue/ActiveList)

LABEL
  }

  for($i=0; $i<$CommitWidth; $i++){
        print $FilePtr <<LABEL;
             input commitStore${i}_i,                         // Is high, if commit0 inst is a Store
             input commitLoad${i}_i,                          // Is high, if commit0 inst is a Load

LABEL
  }
 print $FilePtr <<LABEL;
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

LABEL

  for($i=0; $i<$widthPipe; $i++){
        print $FilePtr <<LABEL;
wire                                    inst${i}Load;
wire                                    inst${i}Store;
wire [`CHECKPOINTS-1:0]                 inst${i}BrMask;
wire [`SIZE_LSQ_LOG-1:0]                stqId${i};
wire [`SIZE_LSQ_LOG-1:0]                ldqId${i};

LABEL
  }

 print $FilePtr <<LABEL;
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

LABEL

  for($i=0; $i<$widthPipe; $i++){
        print $FilePtr <<LABEL;
wire [`SIZE_LSQ_LOG-1:0]                index${i}LdNew;
wire [`SIZE_LSQ_LOG-1:0]                nextLD${i};
wire [`SIZE_LSQ_LOG-1:0]                index${i}StNew;
wire [`SIZE_LSQ_LOG-1:0]                lastST${i};

LABEL
  }

  for($i=0; $i<$CommitWidth; $i++){
	print $FilePtr " wire [`SIZE_LSQ_LOG-1:0]                index${i}LdCom;\n";
	print $FilePtr " wire [`SIZE_LSQ_LOG-1:0]                index${i}StCom;\n";
}

 print $FilePtr <<LABEL;
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

LABEL

  for($i=0; $i<$widthPipe; $i++){
        print $FilePtr <<LABEL;
assign lsqId${i}_o         = (inst${i}Load) ? ldqId${i}:(inst${i}Store) ? stqId${i}:0;
assign inst${i}Load        = lsqPacket${i}_i[0] & backEndReady_i;
assign inst${i}Store       = lsqPacket${i}_i[1] & backEndReady_i;

LABEL
 }

print $FilePtr <<LABEL;
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

LABEL

print $FilePtr <<LABEL;

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

LABEL

 print $FilePtr "   case({";

 for($i=$width_dec; $i>=0; $i--){
	if($i!=0){
		print $FilePtr "inst${i}Load,";
	}
	else{
		print $FilePtr "inst${i}Load})\n";
	}
 }

 $total_cases = 1 << $widthPipe;
 for($i=1;$i<$total_cases;$i++){
        $str = &dec2bin($i);
        @bin_case       = split("", $str);
        print $FilePtr "\t${widthPipe}'b";
        $start = 32 - $widthPipe;
        for($j=$start;$j<32;$j++){
                print $FilePtr "@bin_case[$j]";
        }
	print $FilePtr ":\n\tbegin\n";
	print $FilePtr "\t\tif((stqCount-stCommit";
        $start = 32 - $widthPipe;
	$flag = 0;
        for($j=$start;$j<32;$j++){
		if(1 == $flag && 0==@bin_case[$j]){
			#print "\ncheck.. \n";
			$tag = 31 - $j;
			print $FilePtr "+inst${tag}Store ";
		}
		if(@bin_case[$j] == '1'){
			$flag = 1;
		}
	}
	print $FilePtr ") > 0)\n\t\tbegin\n";
        $tag = 0;
        for($j=31;$j>=$start;$j--){
                if(@bin_case[$j] == 1){
			print $FilePtr "\t\t\tprecedingSTvalid_t1[index${tag}LdNew] = 1'b1;\n";
			$tag = $tag + 1;;
		}
	}
	print $FilePtr "\t\tend\n\tend\n";
 }
 print $FilePtr "   endcase\nend\n\n";
 for($i=$width_dec; $i>=0; $i--){
	print $FilePtr "assign inst${i}BrMask   = lsqPacket${i}_i[`CHECKPOINTS+`LSQ_FLAGS-1:`LSQ_FLAGS];\n";
 }

 print $FilePtr <<LABEL;
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

LABEL

 print $FilePtr "   case({";

 for($i=$width_dec; $i>=0; $i--){
        if($i!=0){
                print $FilePtr "inst${i}Load,";
        }
        else{
                print $FilePtr "inst${i}Load})\n";
        }
 }

 $total_cases = 1 << $widthPipe;
 for($i=1;$i<$total_cases;$i++){
        $str = &dec2bin($i);
        @bin_case       = split("", $str);
        print $FilePtr "\t${widthPipe}'b";
        $start = 32 - $widthPipe;
        for($j=$start;$j<32;$j++){
                print $FilePtr "@bin_case[$j]";
        }
        print $FilePtr ":\n\tbegin\n";
        $tag = 0;
        for($j=31;$j>=$start;$j--){
		$temp = 31 - $j;
                if(@bin_case[$j] == 1){
			print $FilePtr <<LABEL;
                ldqValid[index${tag}LdNew]      <= 1'b1;
                ldqAddrValid[index${tag}LdNew]  <= 1'b0;
                ldqBranchTag[index${tag}LdNew]  <= inst${temp}BrMask;
                precedingST[index${tag}LdNew]   <= lastST${temp};
LABEL
		$tag = $tag + 1;
		}
	}
	print $FilePtr "\tend\n";
	
 }
 print $FilePtr "\tendcase\n\n\tcase(cntLdCom)\n";
 for($i=1; $i<=$CommitWidth; $i++){
	$j = $i - 1;
	print $FilePtr "\t${CommitWidth}'d${i}:\n\tbegin\n";
	for($k=0 ; $k<$i ; $k++){
	print $FilePtr <<LABELL;
                ldqValid[index${k}LdCom]           <= 1'b0;
                ldqAddrValid[index${k}LdCom]       <= 1'b0;
                ldqWriteBack[index${k}LdCom]       <= 1'b0;
                `ifdef VERIFY
                precedingST[index${k}LdCom]        <= 0;
                precedingSTvalid[index${k}LdCom]   <= 0;
                `endif

LABELL
	}
	print $FilePtr "\tend\n";
 }
 print $FilePtr "\tendcase\nend\n\n";
 print $FilePtr <<LABEL;
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

LABEL

 print $FilePtr "   case({";
 for($i=$width_dec; $i>=0; $i--){
        if($i!=0){
                print $FilePtr "inst${i}Store,";
        }
        else{
                print $FilePtr "inst${i}Store})\n";
        }
 }
 $total_cases = 1 << $widthPipe;
 for($i=1;$i<$total_cases;$i++){
        $str = &dec2bin($i);
        @bin_case       = split("", $str);
        print $FilePtr "\t${widthPipe}'b";
        $start = 32 - $widthPipe;
        for($j=$start;$j<32;$j++){
                print $FilePtr "@bin_case[$j]";
        }
        print $FilePtr ":\n\tbegin\n";
        $tag = 0;
        for($j=31;$j>=$start;$j--){
                $temp = 31 - $j;
                if(@bin_case[$j] == 1){
                        print $FilePtr <<LABEL;
                stqValid[index${tag}StNew]      <= 1'b1;
                stqBranchTag[index${tag}StNew]  <= inst${temp}BrMask;
                followingLD[index${tag}StNew]   <= nextLD${temp};
                stqAddr1[index${tag}StNew]      <= 0;
                stqAddr2[index${tag}StNew]      <= 0;
                stqAddrValid[index${tag}StNew]  <= 0;
                stqData[index${tag}StNew]       <= 0;

LABEL
		$tag = $tag + 1;
		}
	}
	print $FilePtr "\tend\n";
 }

 print $FilePtr "\tendcase\n end\nend\n\n";
 print $FilePtr <<LABEL;
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
LABEL
 for($i=1; $i<=$CommitWidth; $i++){
        $j = $i - 1;
        print $FilePtr "\t${CommitWidth}'d${i}:\n\tbegin\n";
        for($k=0 ; $k<$i ; $k++){
        print $FilePtr <<LABELL;
                        stqCommit[index${k}StCom]      <= 1'b1;	
LABELL
	}
	print $FilePtr "\tend\n";
 }
 print $FilePtr "\tendcase\n\tend\nend\n\n";
 print $FilePtr <<LABEL;

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
                        \$writeByte(stCommitData_rf,wrAddr);
                end
                `LDST_HALF_WORD:
                begin
                        wrAddr = {stCommitAddr_rf[31:1],1'b0};
                        \$writeHalf(stCommitData_rf,wrAddr);
                end
                `LDST_WORD:
                begin
                        wrAddr = {stCommitAddr_rf[31:2],2'b0};
                        \$writeWord(stCommitData_rf,wrAddr);
                end
                endcase
           end
        end
 end
end
`endif

LABEL
 print $FilePtr "\nDispatchedLoad disLoad   (\n"; 
 for($i=0; $i<$widthPipe;$i++){
	print $FilePtr <<LABEL;
                           .inst${i}Load_i(inst${i}Load),
                           .ldqId${i}_o(ldqId${i}),
                           .index${i}LdNew_o(index${i}LdNew),
                           .nextLD${i}_o(nextLD${i}),

LABEL
 }
 print $FilePtr <<LABEL;
                           .ldqHead_i(ldqHead),
                           .ldqTail_i(ldqTail),
                           .ldqInsts_i(ldqCount),
                           .cntLdNew_o(cntLdNew)
                         );

LABEL

 print $FilePtr "\nDispatchedStore disStore   (\n"; 
 for($i=0; $i<$widthPipe;$i++){
	print $FilePtr <<LABEL;
                          .inst${i}Store_i(inst${i}Store),
                          .stqId${i}_o(stqId${i}),
                          .index${i}StNew_o(index${i}StNew),
                          .lastST${i}_o(lastST${i}),

LABEL
}
 print $FilePtr <<LABEL;
                          .stqTail_i(stqTail),
                          .stqHead_i((stqHead_f)),
                          .stqInsts_i(stqCount),
                          .cntStNew_o(cntStNew)
			);

LABEL

 print $FilePtr "\nCommitLoad commitLoad ( \n"; 
 for($i=0; $i<$CommitWidth;$i++){
	print $FilePtr "\t\t.commitLoad${i}_i(commitLoad${i}_i),\n\t\t.index${i}LdCom_o(index${i}LdCom),\n";
 }
 print $FilePtr <<LABEL;
                        .ldqHead_i(ldqHead),
                        .cntLdCom_o(cntLdCom)
			);

LABEL

 print $FilePtr "\nCommitStore commitStore ( \n"; 
 for($i=0; $i<$CommitWidth;$i++){
	print $FilePtr "\t\t.commitStore${i}_i(commitStore${i}_i),\n\t\t.index${i}StCom_o(index${i}StCom),\n";
 }
 print $FilePtr <<LABEL;
                          .stqCommitPtr_i(stqCommitPtr),
                          .cntStCom_o(cntStCom)
			);

endmodule

LABEL


