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
# Purpose: This block implements Control Queue for in-order update of branch
#	   predictor.
# Author:  FabGen
*******************************************************************************/


`timescale 1ns/100ps

module CtrlQueue( 

                   input  [`BRANCH_TYPE-1:0]  inst0CtrlType_i,
                   input  [`SIZE_PC-1:0] pc0_i,
                   output [`SIZE_CTI_LOG-1:0] ctiqTag0_o,

                   input  [`BRANCH_TYPE-1:0]  inst1CtrlType_i,
                   input  [`SIZE_PC-1:0] pc1_i,
                   output [`SIZE_CTI_LOG-1:0] ctiqTag1_o,

                   input  [`BRANCH_TYPE-1:0]  inst2CtrlType_i,
                   input  [`SIZE_PC-1:0] pc2_i,
                   output [`SIZE_CTI_LOG-1:0] ctiqTag2_o,

                   input  [`BRANCH_TYPE-1:0]  inst3CtrlType_i,
                   input  [`SIZE_PC-1:0] pc3_i,
                   output [`SIZE_CTI_LOG-1:0] ctiqTag3_o,


		   input  clk,
                   input  reset,
                   input  recoverFlag_i,
                   input  stall_i,

                   input  fs1Ready_i,
                   input  [`FETCH_BANDWIDTH-1:0] ctrlVector_i,
                   input  [`SIZE_CTI_LOG-1:0] ctiQueueIndex_i,
                   input  [`SIZE_PC-1:0] targetAddr_i,
                   input  branchOutcome_i,
                   input  flagRecoverEX_i,
                   input  ctrlVerified_i,
                   input [`RETIRE_WIDTH-1:0] commitCti_i,

                   output updateEn_o,
                   output updateDir_o,
                   output [`SIZE_PC-1:0] updatePC_o,
                   output [`SIZE_PC-1:0] updateTarAddr_o,
                   output [`BRANCH_TYPE-1:0] updateCtrlType_o,
                   output ctiQueueFull_o
	);

reg [`SIZE_PC+`BRANCH_TYPE-1:0]         ctiqInfo0 [`SIZE_CTI_QUEUE-1:0];
reg [`SIZE_PC:0]                        ctiqInfo1 [`SIZE_CTI_QUEUE-1:0];
reg [`SIZE_CTI_QUEUE-1:0]               ctiqCommitted;

`ifdef GBP
reg [`BHR_WIDTH-1:0]                    ctiqBHR  [`SIZE_CTI_QUEUE-1:0];
`endif

reg [`SIZE_CTI_LOG-1:0]                 headPtr;
reg [`SIZE_CTI_LOG-1:0]                 tailPtr;
reg [`SIZE_CTI_LOG-1:0]                 commitPtr;

reg [`SIZE_CTI_LOG:0]                   ctrlCount;

wire                                    updateEn;
wire                                    updateDir;
wire [`SIZE_PC-1:0]                     updatePC;
wire [`SIZE_PC-1:0]                     updateTarAddr;
wire [`BRANCH_TYPE-1:0]                 updateCtrlType;
wire                                    ctiQueueFull;

reg [`CTRL_CNT_FETCH_BLOCK-1:0]         ctrlcount_fetchb;
reg [`SIZE_CTI_LOG:0]                   ctrlcount_mispre;
reg [`SIZE_CTI_LOG-1:0]                 tailPtr_mispre;
reg [`SIZE_CTI_LOG-1:0]                 commitCnt;

reg [`SIZE_CTI_LOG:0]                   ctrlcount_f0;
reg [`SIZE_CTI_LOG:0]                   ctrlcount_f1;
reg [`SIZE_CTI_LOG:0]                   ctrlcount_f2;
reg [`SIZE_CTI_LOG-1:0]                 ctiq0Tag;

reg [`SIZE_CTI_LOG-1:0]                 ctiq1Tag;

reg [`SIZE_CTI_LOG-1:0]                 ctiq2Tag;

reg [`SIZE_CTI_LOG-1:0]                 ctiq3Tag;

wire [`SIZE_CTI_LOG-1:0]                commitPtr_t0;
wire [`SIZE_CTI_LOG-1:0]                commitPtr_t1;
wire [`SIZE_CTI_LOG-1:0]                commitPtr_t2;
wire [`SIZE_CTI_LOG-1:0]                commitPtr_t3;
wire [`SIZE_CTI_LOG-1:0]                tailPtr_t1;
wire [`SIZE_CTI_LOG-1:0]                tailPtr_t2;
wire [`SIZE_CTI_LOG-1:0]                tailPtr_t3;
assign ctiQueueFull     = (ctrlcount_fetchb > (`SIZE_CTI_QUEUE-ctrlCount));
assign ctiQueueFull_o   = ctiQueueFull;
assign updatePC         = ctiqInfo0[headPtr][`SIZE_PC+`BRANCH_TYPE-1:`BRANCH_TYPE];
assign updateCtrlType   = ctiqInfo0[headPtr][`BRANCH_TYPE-1:0];
assign updateTarAddr    = ctiqInfo1[headPtr][`SIZE_PC:1];
assign updateDir        = ctiqInfo1[headPtr][0];
assign updateEn         = ctiqCommitted[headPtr] & (|ctrlCount) & ~recoverFlag_i;

assign updatePC_o       = updatePC;
assign updateCtrlType_o = updateCtrlType;
assign updateTarAddr_o  = updateTarAddr;
assign updateDir_o      = updateDir;
assign updateEn_o       = updateEn;

assign ctiqTag0_o       = ctiq0Tag;
assign ctiqTag1_o       = ctiq1Tag;
assign ctiqTag2_o       = ctiq2Tag;
assign ctiqTag3_o       = ctiq3Tag;
always @(*)
begin:COUNT_CTRL
 reg                            isWrap;
 reg [`SIZE_CTI_LOG-1:0]        diff1;
 reg [`SIZE_CTI_LOG-1:0]        diff2;
 reg [`SIZE_CTI_LOG-1:0]        cnt;
 reg [`SIZE_CTI_LOG-1:0]        tailPtr_t;
 reg [`SIZE_CTI_LOG-1:0]        headPtr_t;

 ctrlcount_fetchb	= ctrlVector_i[0] +ctrlVector_i[1] +ctrlVector_i[2] +ctrlVector_i[3] ;
 if(fs1Ready_i && ~stall_i && ~ctiQueueFull)
        ctrlcount_f0         = ctrlCount + ctrlcount_fetchb;
 else
        ctrlcount_f0         = ctrlCount;


 if(updateEn) // CTIQ is releasing top of queue entry to update the BTB and BPB
 begin
        ctrlcount_f1 = ctrlcount_f0 - 1'b1;
        headPtr_t    = headPtr    + 1'b1;
 end
 else
 begin
        ctrlcount_f1 = ctrlcount_f0;
        headPtr_t    = headPtr;
 end

 ctrlcount_f2        = ctrlcount_f1;

 if(fs1Ready_i && ~stall_i && ~ctiQueueFull)
        tailPtr_t    = tailPtr + ctrlcount_fetchb;
 else
        tailPtr_t    = tailPtr;

 commitCnt	= commitCti_i[0] +commitCti_i[1] +commitCti_i[2] +commitCti_i[3] ;
end

always @(*)
begin:TAG_ASSIGN
 reg [`SIZE_CTI_LOG-1:0] tag0;
 reg [`SIZE_CTI_LOG-1:0] tag1;
 reg [`SIZE_CTI_LOG-1:0] tag2;
 reg [`SIZE_CTI_LOG-1:0] tag3;
  tag0     = tailPtr + 0;
  tag1     = tailPtr + 1;
  tag2     = tailPtr + 2;
  tag3     = tailPtr + 3;
  ctiq0Tag = 0;
  ctiq1Tag = 0;
  ctiq2Tag = 0;
  ctiq3Tag = 0;
 case(ctrlVector_i)
	4'b0000:
	begin
	end
	4'b0001:
	begin
		ctiq0Tag = tag0 ; 
	end
	4'b0010:
	begin
		ctiq1Tag = tag0 ; 
	end
	4'b0011:
	begin
		ctiq0Tag = tag0 ; 
		ctiq1Tag = tag1 ; 
	end
	4'b0100:
	begin
		ctiq2Tag = tag0 ; 
	end
	4'b0101:
	begin
		ctiq0Tag = tag0 ; 
		ctiq2Tag = tag1 ; 
	end
	4'b0110:
	begin
		ctiq1Tag = tag0 ; 
		ctiq2Tag = tag1 ; 
	end
	4'b0111:
	begin
		ctiq0Tag = tag0 ; 
		ctiq1Tag = tag1 ; 
		ctiq2Tag = tag2 ; 
	end
	4'b1000:
	begin
		ctiq3Tag = tag0 ; 
	end
	4'b1001:
	begin
		ctiq0Tag = tag0 ; 
		ctiq3Tag = tag1 ; 
	end
	4'b1010:
	begin
		ctiq1Tag = tag0 ; 
		ctiq3Tag = tag1 ; 
	end
	4'b1011:
	begin
		ctiq0Tag = tag0 ; 
		ctiq1Tag = tag1 ; 
		ctiq3Tag = tag2 ; 
	end
	4'b1100:
	begin
		ctiq2Tag = tag0 ; 
		ctiq3Tag = tag1 ; 
	end
	4'b1101:
	begin
		ctiq0Tag = tag0 ; 
		ctiq2Tag = tag1 ; 
		ctiq3Tag = tag2 ; 
	end
	4'b1110:
	begin
		ctiq1Tag = tag0 ; 
		ctiq2Tag = tag1 ; 
		ctiq3Tag = tag2 ; 
	end
	4'b1111:
	begin
		ctiq0Tag = tag0 ; 
		ctiq1Tag = tag1 ; 
		ctiq2Tag = tag2 ; 
		ctiq3Tag = tag3 ; 
	end
 endcase
end
always @(posedge clk)
begin
  if(reset)
  begin
        headPtr         <= 0;
        commitPtr       <= 0;
  end
  else
  begin
    if(updateEn)
        headPtr         <= headPtr + 1'b1;

    commitPtr           <= commitPtr+commitCnt;
  end
end

always @(posedge clk)
begin
  if(reset)
  begin
        ctrlCount       <= 0;
  end
  else if(recoverFlag_i)
  begin
        ctrlCount       <= (commitPtr >= headPtr) ? (commitPtr-headPtr):(`SIZE_CTI_QUEUE-(headPtr-commitPtr));
  end
  else
  begin
        ctrlCount       <= ctrlcount_f2;
  end
end

 assign tailPtr_t1  =  tailPtr + 1;
 assign tailPtr_t2  =  tailPtr + 2;
 assign tailPtr_t3  =  tailPtr + 3;
 assign commitPtr_t0  =  commitPtr + 0;
 assign commitPtr_t1  =  commitPtr + 1;
 assign commitPtr_t2  =  commitPtr + 2;
 assign commitPtr_t3  =  commitPtr + 3;
always @(posedge clk)
begin:WRITE_CTIQ
 integer i;

 if(reset)
 begin
   tailPtr               <= 0;
   for(i=0;i<`SIZE_CTI_QUEUE;i=i+1)
   begin
        ctiqInfo0[i]     <= 0;
        ctiqInfo1[i]     <= 0;
        ctiqCommitted[i] <= 0;
   end
 end
 else
 begin
   if(recoverFlag_i)
   begin
        tailPtr         <= commitPtr;
   end
   else
   begin
     if(ctrlVerified_i)
     begin
        ctiqInfo1[ctiQueueIndex_i]      <= {targetAddr_i,branchOutcome_i};
     end

     case(commitCnt)
	4'd1:
	begin
		ctiqCommitted[commitPtr_t0]  <= 1'b1;
	end
	4'd2:
	begin
		ctiqCommitted[commitPtr_t0]  <= 1'b1;
		ctiqCommitted[commitPtr_t1]  <= 1'b1;
	end
	4'd3:
	begin
		ctiqCommitted[commitPtr_t0]  <= 1'b1;
		ctiqCommitted[commitPtr_t1]  <= 1'b1;
		ctiqCommitted[commitPtr_t2]  <= 1'b1;
	end
	4'd4:
	begin
		ctiqCommitted[commitPtr_t0]  <= 1'b1;
		ctiqCommitted[commitPtr_t1]  <= 1'b1;
		ctiqCommitted[commitPtr_t2]  <= 1'b1;
		ctiqCommitted[commitPtr_t3]  <= 1'b1;
	end
     endcase
    if(fs1Ready_i && ~stall_i && ~ctiQueueFull)
     begin
	tailPtr	<=ctrlVector_i[0] +ctrlVector_i[1] +ctrlVector_i[2] +ctrlVector_i[3] + tailPtr;

	case(ctrlVector_i)
4'b0000:
	begin
	end
4'b0001:
	begin
		ctiqInfo0[tailPtr] <= {pc0_i,inst0CtrlType_i};
		ctiqCommitted[tailPtr]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr]           <= 0;
		`endif
	end
4'b0010:
	begin
		ctiqInfo0[tailPtr] <= {pc1_i,inst1CtrlType_i};
		ctiqCommitted[tailPtr]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr]           <= 0;
		`endif
	end
4'b0011:
	begin
		ctiqInfo0[tailPtr] <= {pc0_i,inst0CtrlType_i};
		ctiqCommitted[tailPtr]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t1] <= {pc1_i,inst1CtrlType_i};
		ctiqCommitted[tailPtr_t1]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t1]           <= 0;
		`endif
	end
4'b0100:
	begin
		ctiqInfo0[tailPtr] <= {pc2_i,inst2CtrlType_i};
		ctiqCommitted[tailPtr]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr]           <= 0;
		`endif
	end
4'b0101:
	begin
		ctiqInfo0[tailPtr] <= {pc0_i,inst0CtrlType_i};
		ctiqCommitted[tailPtr]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t1] <= {pc2_i,inst2CtrlType_i};
		ctiqCommitted[tailPtr_t1]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t1]           <= 0;
		`endif
	end
4'b0110:
	begin
		ctiqInfo0[tailPtr] <= {pc1_i,inst1CtrlType_i};
		ctiqCommitted[tailPtr]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t1] <= {pc2_i,inst2CtrlType_i};
		ctiqCommitted[tailPtr_t1]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t1]           <= 0;
		`endif
	end
4'b0111:
	begin
		ctiqInfo0[tailPtr] <= {pc0_i,inst0CtrlType_i};
		ctiqCommitted[tailPtr]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t1] <= {pc1_i,inst1CtrlType_i};
		ctiqCommitted[tailPtr_t1]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t1]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t2] <= {pc2_i,inst2CtrlType_i};
		ctiqCommitted[tailPtr_t2]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t2]           <= 0;
		`endif
	end
4'b1000:
	begin
		ctiqInfo0[tailPtr] <= {pc3_i,inst3CtrlType_i};
		ctiqCommitted[tailPtr]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr]           <= 0;
		`endif
	end
4'b1001:
	begin
		ctiqInfo0[tailPtr] <= {pc0_i,inst0CtrlType_i};
		ctiqCommitted[tailPtr]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t1] <= {pc3_i,inst3CtrlType_i};
		ctiqCommitted[tailPtr_t1]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t1]           <= 0;
		`endif
	end
4'b1010:
	begin
		ctiqInfo0[tailPtr] <= {pc1_i,inst1CtrlType_i};
		ctiqCommitted[tailPtr]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t1] <= {pc3_i,inst3CtrlType_i};
		ctiqCommitted[tailPtr_t1]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t1]           <= 0;
		`endif
	end
4'b1011:
	begin
		ctiqInfo0[tailPtr] <= {pc0_i,inst0CtrlType_i};
		ctiqCommitted[tailPtr]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t1] <= {pc1_i,inst1CtrlType_i};
		ctiqCommitted[tailPtr_t1]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t1]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t2] <= {pc3_i,inst3CtrlType_i};
		ctiqCommitted[tailPtr_t2]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t2]           <= 0;
		`endif
	end
4'b1100:
	begin
		ctiqInfo0[tailPtr] <= {pc2_i,inst2CtrlType_i};
		ctiqCommitted[tailPtr]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t1] <= {pc3_i,inst3CtrlType_i};
		ctiqCommitted[tailPtr_t1]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t1]           <= 0;
		`endif
	end
4'b1101:
	begin
		ctiqInfo0[tailPtr] <= {pc0_i,inst0CtrlType_i};
		ctiqCommitted[tailPtr]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t1] <= {pc2_i,inst2CtrlType_i};
		ctiqCommitted[tailPtr_t1]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t1]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t2] <= {pc3_i,inst3CtrlType_i};
		ctiqCommitted[tailPtr_t2]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t2]           <= 0;
		`endif
	end
4'b1110:
	begin
		ctiqInfo0[tailPtr] <= {pc1_i,inst1CtrlType_i};
		ctiqCommitted[tailPtr]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t1] <= {pc2_i,inst2CtrlType_i};
		ctiqCommitted[tailPtr_t1]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t1]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t2] <= {pc3_i,inst3CtrlType_i};
		ctiqCommitted[tailPtr_t2]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t2]           <= 0;
		`endif
	end
4'b1111:
	begin
		ctiqInfo0[tailPtr] <= {pc0_i,inst0CtrlType_i};
		ctiqCommitted[tailPtr]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t1] <= {pc1_i,inst1CtrlType_i};
		ctiqCommitted[tailPtr_t1]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t1]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t2] <= {pc2_i,inst2CtrlType_i};
		ctiqCommitted[tailPtr_t2]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t2]           <= 0;
		`endif
		ctiqInfo0[tailPtr_t3] <= {pc3_i,inst3CtrlType_i};
		ctiqCommitted[tailPtr_t3]       <= 0;
		`ifdef VERIFY
		ctiqInfo1[tailPtr_t3]           <= 0;
		`endif
	end
    endcase
    end
   end
  end
 end
endmodule

