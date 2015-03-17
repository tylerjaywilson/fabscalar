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
# Purpose: This module implements speculative FreeList.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps

module SpecFreeList(
 input clk,
 input stall_i,
 input reset,
 input recoverFlag_i,
 input flagRecoverEX_i,
 input ctrlVerified_i,
 input [`SIZE_FREE_LIST_LOG-1:0] freeListHeadCp_i,
 input reqFreeReg0_i,
 input reqFreeReg1_i,
 input reqFreeReg2_i,
 input reqFreeReg3_i,
 input commitValid0_i,
 input [`SIZE_PHYSICAL_LOG-1:0] commitReg0_i,
 input commitValid1_i,
 input [`SIZE_PHYSICAL_LOG-1:0] commitReg1_i,
 input commitValid2_i,
 input [`SIZE_PHYSICAL_LOG-1:0] commitReg2_i,
 input commitValid3_i,
 input [`SIZE_PHYSICAL_LOG-1:0] commitReg3_i,
 output [`SIZE_FREE_LIST_LOG-1:0] freeListHead_o,
 output [`SIZE_PHYSICAL_LOG:0] freeReg0_o,
 output [`SIZE_PHYSICAL_LOG:0] freeReg1_o,
 output [`SIZE_PHYSICAL_LOG:0] freeReg2_o,
 output [`SIZE_PHYSICAL_LOG:0] freeReg3_o,
 output freeListEmpty_o
); 

reg [`SIZE_FREE_LIST_LOG-1:0]           freeListHead;
reg [`SIZE_FREE_LIST_LOG-1:0]           freeListTail;
reg [`SIZE_FREE_LIST_LOG:0]           freeListCnt;
wire                                    freeListEmpty;
wire                                    reqFreeReg0;
wire                                    reqFreeReg1;
wire                                    reqFreeReg2;
wire                                    reqFreeReg3;
reg [3:0]                               popNumber;
reg [3:0]                               pushNumber;
reg [`SIZE_FREE_LIST_LOG:0]           freelistcnt;
reg [`SIZE_FREE_LIST_LOG:0]           freelistcntCp;
reg [`SIZE_FREE_LIST_LOG-1:0]           freeListHead_t;
reg [`SIZE_FREE_LIST_LOG-1:0]           freeListTail_t;

reg [`SIZE_FREE_LIST_LOG-1:0]    		readAddr0;
reg [`SIZE_FREE_LIST_LOG-1:0]    		readAddr1;
reg [`SIZE_FREE_LIST_LOG-1:0]    		readAddr2;
reg [`SIZE_FREE_LIST_LOG-1:0]    		readAddr3;
wire [`SIZE_PHYSICAL_LOG:0]    		freeReg0;
wire [`SIZE_PHYSICAL_LOG:0]    		freeReg1;
wire [`SIZE_PHYSICAL_LOG:0]    		freeReg2;
wire [`SIZE_PHYSICAL_LOG:0]    		freeReg3;
reg [`SIZE_FREE_LIST_LOG-1:0]     	writeAddr0;
reg [`SIZE_FREE_LIST_LOG-1:0]     	writeAddr1;
reg [`SIZE_FREE_LIST_LOG-1:0]     	writeAddr2;
reg [`SIZE_FREE_LIST_LOG-1:0]     	writeAddr3;
reg 			    		writeEn0;
reg [`SIZE_FREE_LIST_LOG-1:0]             addr0wr;
reg [`SIZE_PHYSICAL_LOG:0]                data0wr;
reg 			    		writeEn1;
reg [`SIZE_FREE_LIST_LOG-1:0]             addr1wr;
reg [`SIZE_PHYSICAL_LOG:0]                data1wr;
reg 			    		writeEn2;
reg [`SIZE_FREE_LIST_LOG-1:0]             addr2wr;
reg [`SIZE_PHYSICAL_LOG:0]                data2wr;
reg 			    		writeEn3;
reg [`SIZE_FREE_LIST_LOG-1:0]             addr3wr;
reg [`SIZE_PHYSICAL_LOG:0]                data3wr;
integer                                 i;

SRAM_4R4W_FREELIST #(`SIZE_FREE_LIST,`SIZE_FREE_LIST_LOG,`SIZE_PHYSICAL_LOG)
  FREE_LIST ( .clk(clk),
		.reset(reset),
		.addr0_i(readAddr0),
		.addr1_i(readAddr1),
		.addr2_i(readAddr2),
		.addr3_i(readAddr3),
		.we0_i(writeEn0),
		.addr0wr_i(addr0wr),
		.data0wr_i(data0wr),
		.we1_i(writeEn1),
		.addr1wr_i(addr1wr),
		.data1wr_i(data1wr),
		.we2_i(writeEn2),
		.addr2wr_i(addr2wr),
		.data2wr_i(data2wr),
		.we3_i(writeEn3),
		.addr3wr_i(addr3wr),
		.data3wr_i(data3wr),
		.data0_o(freeReg0),
		.data1_o(freeReg1),
		.data2_o(freeReg2),
		.data3_o(freeReg3)
  );

assign freeReg0_o       = (freeListCnt >= `DISPATCH_WIDTH) ? {freeReg0,1'b1}:0;
assign freeReg1_o       = (freeListCnt >= `DISPATCH_WIDTH) ? {freeReg1,1'b1}:0;
assign freeReg2_o       = (freeListCnt >= `DISPATCH_WIDTH) ? {freeReg2,1'b1}:0;
assign freeReg3_o       = (freeListCnt >= `DISPATCH_WIDTH) ? {freeReg3,1'b1}:0;

assign freeListHead_o   = freeListHead;
always @(*)
begin:FREE_LIST_ADDR
reg [`SIZE_FREE_LIST_LOG:0]		readaddr1_f;
reg [`SIZE_FREE_LIST_LOG:0]		readaddr2_f;
reg [`SIZE_FREE_LIST_LOG:0]		readaddr3_f;
reg [`SIZE_FREE_LIST_LOG:0]		writeaddr1_f;
reg [`SIZE_FREE_LIST_LOG:0]		writeaddr2_f;
reg [`SIZE_FREE_LIST_LOG:0]		writeaddr3_f;
readAddr0    = freeListHead;
 readaddr1_f   = freeListHead + 1;
 readaddr2_f   = freeListHead + 2;
 readaddr3_f   = freeListHead + 3;
 if(readaddr1_f >= `SIZE_FREE_LIST)
 		readAddr1  = readaddr1_f - `SIZE_FREE_LIST;
 else
	 readAddr1 = readaddr1_f;
 if(readaddr2_f >= `SIZE_FREE_LIST)
 		readAddr2  = readaddr2_f - `SIZE_FREE_LIST;
 else
	 readAddr2 = readaddr2_f;
 if(readaddr3_f >= `SIZE_FREE_LIST)
 		readAddr3  = readaddr3_f - `SIZE_FREE_LIST;
 else
	 readAddr3 = readaddr3_f;
writeAddr0   = freeListTail;
 writeaddr1_f   = freeListTail + 1;
 writeaddr2_f   = freeListTail + 2;
 writeaddr3_f   = freeListTail + 3;
 if(writeaddr1_f >= `SIZE_FREE_LIST)
          writeAddr1 = writeaddr1_f - `SIZE_FREE_LIST;
 else
	 writeAddr1 = writeaddr1_f;
 if(writeaddr2_f >= `SIZE_FREE_LIST)
          writeAddr2 = writeaddr2_f - `SIZE_FREE_LIST;
 else
	 writeAddr2 = writeaddr2_f;
 if(writeaddr3_f >= `SIZE_FREE_LIST)
          writeAddr3 = writeaddr3_f - `SIZE_FREE_LIST;
 else
	 writeAddr3 = writeaddr3_f;
end

assign freeListEmpty    =  (freeListCnt < `DISPATCH_WIDTH) ? 1:0;
assign freeListEmpty_o  =   freeListEmpty;
assign reqFreeReg3 	= reqFreeReg3_i & ~freeListEmpty;
assign reqFreeReg2 	= reqFreeReg2_i & ~freeListEmpty;
assign reqFreeReg1 	= reqFreeReg1_i & ~freeListEmpty;
assign reqFreeReg0 	= reqFreeReg0_i & ~freeListEmpty;

always @(*)
begin:UPDATE_HEAD_TAIL_COUNT
reg                            isWrap_fl;
reg [`SIZE_FREE_LIST_LOG:0]  diff1_fl;
reg [`SIZE_FREE_LIST_LOG:0]  diff2_fl;
reg [`SIZE_FREE_LIST_LOG:0]  freelisthead;
reg [`SIZE_FREE_LIST_LOG:0]  freelisttail;
 popNumber  =  (reqFreeReg0 + reqFreeReg1 + reqFreeReg2 + reqFreeReg3);
 pushNumber  =  (commitValid0_i + commitValid1_i + commitValid2_i + commitValid3_i);

 freelistcnt    = freeListCnt  - popNumber;
 freelistcnt    = freelistcnt  + pushNumber;
 freelisthead   = freeListHead + popNumber;
 if(freelisthead >= `SIZE_FREE_LIST)
		freeListHead_t  = freelisthead - `SIZE_FREE_LIST;
 else
 	freeListHead_t  = freelisthead;
 freelisttail   = freeListTail + pushNumber;
 if(freelisttail >= `SIZE_FREE_LIST)
 	freeListTail_t  = freelisttail - `SIZE_FREE_LIST;
 else
 	freeListTail_t  = freelisttail;
 isWrap_fl             = (freeListTail_t > freeListHeadCp_i);
 diff1_fl              = (`SIZE_FREE_LIST - freeListHeadCp_i)+freeListTail_t;
 diff2_fl              = (freeListTail_t - freeListHeadCp_i);
 freelistcntCp         = (isWrap_fl) ? diff2_fl:diff1_fl;
end

always @(posedge clk)
begin
  if(reset)
  begin
    freeListCnt  <= `SIZE_FREE_LIST;
    freeListHead <= 0;
  end
  else if(recoverFlag_i)
  begin
    freeListCnt  <= `SIZE_FREE_LIST;
    freeListHead <= freeListTail;
  end
  else
  begin
    if(ctrlVerified_i && flagRecoverEX_i)
    begin
        freeListHead  <=  freeListHeadCp_i;
        freeListCnt   <=  freelistcntCp;
    end
    else if(stall_i || freeListEmpty)
    begin
        freeListHead  <=  freeListHead;
        freeListCnt   <=  freeListCnt + pushNumber;
    end
    else
    begin
        freeListHead  <=  freeListHead_t;
        freeListCnt   <=  freelistcnt;
    end
  end
end
always @(*)
begin:CALCULATE_WRITE_ADDR
 writeEn0 = 0;
 addr0wr  = 0;
 data0wr  = 0;
 writeEn1 = 0;
 addr1wr  = 0;
 data1wr  = 0;
 writeEn2 = 0;
 addr2wr  = 0;
 data2wr  = 0;
 writeEn3 = 0;
 addr3wr  = 0;
 data3wr  = 0;
  case({commitValid3_i,commitValid2_i,commitValid1_i,commitValid0_i})
     4'd1:
     begin

		writeEn0	= 1'b1;
             addr0wr 	= writeAddr0;
             data0wr 	=  commitReg0_i;
     end
     4'd2:
     begin

		writeEn0	= 1'b1;
             addr0wr 	= writeAddr0;
             data0wr 	=  commitReg1_i;
     end
     4'd3:
     begin

		writeEn0	= 1'b1;
             addr0wr 	= writeAddr0;
             data0wr 	=  commitReg0_i;

		writeEn1	= 1'b1;
             addr1wr 	= writeAddr1;
             data1wr 	=  commitReg1_i;
     end
     4'd4:
     begin

		writeEn0	= 1'b1;
             addr0wr 	= writeAddr0;
             data0wr 	=  commitReg2_i;
     end
     4'd5:
     begin

		writeEn0	= 1'b1;
             addr0wr 	= writeAddr0;
             data0wr 	=  commitReg0_i;

		writeEn1	= 1'b1;
             addr1wr 	= writeAddr1;
             data1wr 	=  commitReg2_i;
     end
     4'd6:
     begin

		writeEn0	= 1'b1;
             addr0wr 	= writeAddr0;
             data0wr 	=  commitReg1_i;

		writeEn1	= 1'b1;
             addr1wr 	= writeAddr1;
             data1wr 	=  commitReg2_i;
     end
     4'd7:
     begin

		writeEn0	= 1'b1;
             addr0wr 	= writeAddr0;
             data0wr 	=  commitReg0_i;

		writeEn1	= 1'b1;
             addr1wr 	= writeAddr1;
             data1wr 	=  commitReg1_i;

		writeEn2	= 1'b1;
             addr2wr 	= writeAddr2;
             data2wr 	=  commitReg2_i;
     end
     4'd8:
     begin

		writeEn0	= 1'b1;
             addr0wr 	= writeAddr0;
             data0wr 	=  commitReg3_i;
     end
     4'd9:
     begin

		writeEn0	= 1'b1;
             addr0wr 	= writeAddr0;
             data0wr 	=  commitReg0_i;

		writeEn1	= 1'b1;
             addr1wr 	= writeAddr1;
             data1wr 	=  commitReg3_i;
     end
     4'd10:
     begin

		writeEn0	= 1'b1;
             addr0wr 	= writeAddr0;
             data0wr 	=  commitReg1_i;

		writeEn1	= 1'b1;
             addr1wr 	= writeAddr1;
             data1wr 	=  commitReg3_i;
     end
     4'd11:
     begin

		writeEn0	= 1'b1;
             addr0wr 	= writeAddr0;
             data0wr 	=  commitReg0_i;

		writeEn1	= 1'b1;
             addr1wr 	= writeAddr1;
             data1wr 	=  commitReg1_i;

		writeEn2	= 1'b1;
             addr2wr 	= writeAddr2;
             data2wr 	=  commitReg3_i;
     end
     4'd12:
     begin

		writeEn0	= 1'b1;
             addr0wr 	= writeAddr0;
             data0wr 	=  commitReg2_i;

		writeEn1	= 1'b1;
             addr1wr 	= writeAddr1;
             data1wr 	=  commitReg3_i;
     end
     4'd13:
     begin

		writeEn0	= 1'b1;
             addr0wr 	= writeAddr0;
             data0wr 	=  commitReg0_i;

		writeEn1	= 1'b1;
             addr1wr 	= writeAddr1;
             data1wr 	=  commitReg2_i;

		writeEn2	= 1'b1;
             addr2wr 	= writeAddr2;
             data2wr 	=  commitReg3_i;
     end
     4'd14:
     begin

		writeEn0	= 1'b1;
             addr0wr 	= writeAddr0;
             data0wr 	=  commitReg1_i;

		writeEn1	= 1'b1;
             addr1wr 	= writeAddr1;
             data1wr 	=  commitReg2_i;

		writeEn2	= 1'b1;
             addr2wr 	= writeAddr2;
             data2wr 	=  commitReg3_i;
     end
     4'd15:
     begin

		writeEn0	= 1'b1;
             addr0wr 	= writeAddr0;
             data0wr 	=  commitReg0_i;

		writeEn1	= 1'b1;
             addr1wr 	= writeAddr1;
             data1wr 	=  commitReg1_i;

		writeEn2	= 1'b1;
             addr2wr 	= writeAddr2;
             data2wr 	=  commitReg2_i;

		writeEn3	= 1'b1;
             addr3wr 	= writeAddr3;
             data3wr 	=  commitReg3_i;
     end
  endcase
  end
always @(posedge clk)
begin
 if(reset)
 begin
  freeListTail    <= 0;
 end
 else
 begin
  freeListTail <= freeListTail_t;
  end
end


endmodule