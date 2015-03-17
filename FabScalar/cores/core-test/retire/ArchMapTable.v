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
# Purpose: This block implements Architecture Map Table.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps


/* Algorithm

   1. Receive upto 4 instruction (commited) from Active List to update the
      new mapping in AMT.

   2. IMP: In the commit window if the multiple	instructions' logical 
      destination are same, only the youngest commiting instruction would
      update the AMT.
      The older instructions' physical mapping would be released to the free 
      list.
     
   2. If there is a recovery because of control mis-predict or exception
      (as indicated by Active List), AMT mapping are read in a group of 4 
      and sent to RMT for updation.
      
   3. In a cycle 4 AMT entries are sent because RMT is restricted with only
      4 write ports.
***************************************************************************/


module ArchMapTable( input clk,
                     input reset,
                     
		     /* From ActiveList: Upto 4 instructions can retire. AMT Packet
			contains following information:
			  (1) Logical Dest      "bits-`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG"
                          (2) Physical Dest     "bits-`SIZE_PHYSICAL_LOG-1:0"

			IMP: If the commitValid is 0, then there is no destination register associated with 
			     the instruction.
 		     */
                     input commitValid0_i,
                     input [`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:0] amtPacket0_i,
                     input commitValid1_i,
                     input [`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:0] amtPacket1_i,
                     input commitValid2_i,
                     input [`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:0] amtPacket2_i,
                     input commitValid3_i,
                     input [`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:0] amtPacket3_i,

                     input recoverFlag_i,  // From ActiveList if there is Exception or Branch Mis-prediction.

		     /* Release the old physical map to be inserted into speculative free list. */	
		     output releasedValid0_o,
		     output [`SIZE_PHYSICAL_LOG-1:0] releasedPhyMap0_o,
		     output releasedValid1_o,
		     output [`SIZE_PHYSICAL_LOG-1:0] releasedPhyMap1_o,
		     output releasedValid2_o,
		     output [`SIZE_PHYSICAL_LOG-1:0] releasedPhyMap2_o,
		     output releasedValid3_o,
		     output [`SIZE_PHYSICAL_LOG-1:0] releasedPhyMap3_o,

                     output [`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:0] recoverPacket0_o, 
                     output [`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:0] recoverPacket1_o, 
                     output [`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:0] recoverPacket2_o, 
                     output [`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:0] recoverPacket3_o 
                   );


/*  Followinig declares counter for recovery.
*/
reg [`SIZE_RMT_LOG-1:0] 	recoverCnt;


/*  regs and wires declaration for combinational logic.
 */
reg [`SIZE_RMT_LOG-1:0] 	inst0Dest; 
reg [`SIZE_RMT_LOG-1:0] 	inst1Dest; 
reg [`SIZE_RMT_LOG-1:0] 	inst2Dest; 
reg [`SIZE_RMT_LOG-1:0] 	inst3Dest; 
reg 				dontWrite0AMT;
reg 				dontWrite1AMT;
reg 				dontWrite2AMT;

wire [`SIZE_RMT_LOG-1:0] 	addr0;
wire [`SIZE_RMT_LOG-1:0] 	addr1;
wire [`SIZE_RMT_LOG-1:0] 	addr2;
wire [`SIZE_RMT_LOG-1:0] 	addr3;
wire [`SIZE_PHYSICAL_LOG-1:0] 	data0;
wire [`SIZE_PHYSICAL_LOG-1:0] 	data1;
wire [`SIZE_PHYSICAL_LOG-1:0] 	data2;
wire [`SIZE_PHYSICAL_LOG-1:0] 	data3;


/************************************************************************************
* Following instantiates RAM modules for Architectural Map Table. The read and 
* write ports depend on the commit width of the processor.
*
* The write address is always logical destination of the committing instruction. 
* The read address could be either logical destination of the committing instruction
* in the normal operation or "recoverCnt" in the case of exception.
************************************************************************************/
SRAM_4R4W_AMT #(`SIZE_RMT,`SIZE_RMT_LOG,`SIZE_PHYSICAL_LOG)
        AMT ( .clk(clk),
              .reset(reset),
              .addr0_i(addr0),
              .addr1_i(addr1),
              .addr2_i(addr2),
              .addr3_i(addr3),
              .we0_i(commitValid0_i && ~dontWrite0AMT),
              .addr0wr_i(inst0Dest),
              .data0wr_i(amtPacket0_i[`SIZE_PHYSICAL_LOG-1:0]),
              .we1_i(commitValid1_i && ~dontWrite1AMT),
              .addr1wr_i(inst1Dest),
              .data1wr_i(amtPacket1_i[`SIZE_PHYSICAL_LOG-1:0]),
              .we2_i(commitValid2_i && ~dontWrite2AMT),
              .addr2wr_i(inst2Dest),
              .data2wr_i(amtPacket2_i[`SIZE_PHYSICAL_LOG-1:0]),
              .we3_i(commitValid3_i),
              .addr3wr_i(inst3Dest),
              .data3wr_i(amtPacket3_i[`SIZE_PHYSICAL_LOG-1:0]),
              .data0_o(data0),
              .data1_o(data1),
              .data2_o(data2),
              .data3_o(data3)
            );

 
/*  Logic to select the physical register to be released this cycle.
 */
assign releasedValid0_o  	= commitValid0_i;
assign releasedPhyMap0_o 	= (dontWrite0AMT) ? amtPacket0_i[`SIZE_PHYSICAL_LOG-1:0]: data0;
assign releasedValid1_o  	= commitValid1_i;
assign releasedPhyMap1_o 	= (dontWrite1AMT) ? amtPacket1_i[`SIZE_PHYSICAL_LOG-1:0]: data1;
assign releasedValid2_o  	= commitValid2_i;
assign releasedPhyMap2_o 	= (dontWrite2AMT) ? amtPacket2_i[`SIZE_PHYSICAL_LOG-1:0]: data2;
assign releasedValid3_o  	= commitValid3_i;
assign releasedPhyMap3_o 	= data3;


/*  Recover packet in case of exception.
 */
assign recoverPacket0_o 	= {recoverCnt,data0};
assign recoverPacket1_o 	= {(recoverCnt+1),data1};
assign recoverPacket2_o 	= {(recoverCnt+2),data2};
assign recoverPacket3_o 	= {(recoverCnt+3),data3};



/*  Check if destination of an instruction matches with destination of the newer
 *  instruction in the commit window. If there is a match then this instruction
 *  doesn't update the AMT and is released to be written to speculative free list.
 */
always @(*)
begin:CHECK_DESTINATION_REG
  inst0Dest = amtPacket0_i[`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG];
  inst1Dest = amtPacket1_i[`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG];
  inst2Dest = amtPacket2_i[`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG];
  inst3Dest = amtPacket3_i[`SIZE_RMT_LOG+`SIZE_PHYSICAL_LOG-1:`SIZE_PHYSICAL_LOG];

  /*if(inst0Dest == inst1Dest ||
     inst0Dest == inst2Dest ||
     inst0Dest == inst3Dest) dontWrite0AMT = 1;
  else
     dontWrite0AMT = 0;

  if(inst1Dest == inst2Dest ||
     inst1Dest == inst3Dest) dontWrite1AMT = 1;
  else
     dontWrite1AMT = 0;

  if(inst2Dest == inst3Dest) dontWrite2AMT = 1;
  else
     dontWrite2AMT = 0;*/

  if((((inst0Dest == inst1Dest) && commitValid1_i)
                   || ((inst0Dest == inst2Dest) && commitValid2_i)
                   || ((inst0Dest == inst3Dest) && commitValid3_i)))
	dontWrite0AMT = 1;
  else
     	dontWrite0AMT = 0;

  if((((inst1Dest == inst2Dest) && commitValid2_i)
                   || ((inst1Dest == inst3Dest) && commitValid3_i)))
	dontWrite1AMT = 1;
  else
     	dontWrite1AMT = 0;

  if((inst2Dest == inst3Dest) && commitValid3_i) 
	dontWrite2AMT = 1;
  else
     	dontWrite2AMT = 0;
end


/* Following selects the address to be used for writing to the AMT. 
 * By default commiting instruction's logical destination reg is used as address. 
 *
 * In case of exception recoverCnt is used as address.
 */
assign addr0 = inst0Dest;
assign addr1 = inst1Dest;
assign addr2 = inst2Dest;
assign addr3 = inst3Dest;




/* Following updates the recover count each cycle if the recover flag is
 * high.
 */
always @(posedge clk)
begin
 if(reset)
	recoverCnt  <= 0;
 else
 begin
  if(recoverFlag_i)
  begin
    if(recoverCnt == `SIZE_RMT-1)
	recoverCnt  <= 0;
    else
	recoverCnt  <= recoverCnt + 4;
  end
 end
end


endmodule
