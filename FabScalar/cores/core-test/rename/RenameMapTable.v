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
# Purpose: This block implements the Rename Map Table (RMT).
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps



/***************************************************************************
  The Register Map Table (RMT) conatins the current logical register to 
  physical register mapping. 

  For each set of instructions in Rename stage the physical source register
  mapping is obtained by reading the RMT and the physical destination 
  register mapping is obtained by reading the Free List table. 
  Eventually, the new logical destination register and physical register 
  mapping is updated in the RMT for the future set of the instructions.

  While recovery RMT recieves 4 in-order logial to physical register mapping
  from each Architecture Map Table (AMT). Appropriate ports have been provided
  for the recovery purpose.
  
***************************************************************************/

/* Algorithm
 
 1. Receives 4 or 0 new decoded instructions from the previous (i.e. decode)
    stage.

 2. Also receives 4 new physical registers from the Speculative free list,
    if the list is not empty. 
    If list is empty, pipeline stages after instruction buffer and till 
    rename is stalled.

 3. 

***************************************************************************/


module RenameMapTable(
			input 				clk,
            input 				reset,
			input 				stall_i,

                        input [`SIZE_RMT_LOG:0] 	src0logical1_i,
                        input [`SIZE_RMT_LOG:0] 	src0logical2_i,
                        input [`SIZE_RMT_LOG:0] 	inst0Dest_i,
                        input [`SIZE_RMT_LOG:0] 	src1logical1_i,
                        input [`SIZE_RMT_LOG:0] 	src1logical2_i,
                        input [`SIZE_RMT_LOG:0] 	inst1Dest_i,
                        input [`SIZE_RMT_LOG:0] 	src2logical1_i,
                        input [`SIZE_RMT_LOG:0] 	src2logical2_i,
                        input [`SIZE_RMT_LOG:0] 	inst2Dest_i,
                        input [`SIZE_RMT_LOG:0] 	src3logical1_i,
                        input [`SIZE_RMT_LOG:0] 	src3logical2_i,
                        input [`SIZE_RMT_LOG:0] 	inst3Dest_i,

			input 				flagRecoverEX_i,	

		        /* Four physical registers are popped from the Spec free
                           list for logical to physical register mapping.
			*/

                        input [`SIZE_PHYSICAL_LOG:0] 	dest0Physical_i,
                        input [`SIZE_PHYSICAL_LOG:0] 	dest1Physical_i,
                        input [`SIZE_PHYSICAL_LOG:0] 	dest2Physical_i,
                        input [`SIZE_PHYSICAL_LOG:0] 	dest3Physical_i,

                        /* Recover flag is high if there is any exception. Architectural
                           map table is copied to RMT in a group of four mappings.
 			*/
                        input 				recoverFlag_i,						
			input [`SIZE_RMT_LOG-1:0] 	recoverDest0_i,
			input [`SIZE_RMT_LOG-1:0] 	recoverDest1_i,
			input [`SIZE_RMT_LOG-1:0] 	recoverDest2_i,
			input [`SIZE_RMT_LOG-1:0] 	recoverDest3_i,

			input [`SIZE_PHYSICAL_LOG-1:0] 	recoverMap0_i,
			input [`SIZE_PHYSICAL_LOG-1:0] 	recoverMap1_i,
			input [`SIZE_PHYSICAL_LOG-1:0] 	recoverMap2_i,
			input [`SIZE_PHYSICAL_LOG-1:0] 	recoverMap3_i,

		    output [`SIZE_PHYSICAL_LOG:0] 	src0rmt1_o,
            output [`SIZE_PHYSICAL_LOG:0] 	src0rmt2_o,
            output [`SIZE_PHYSICAL_LOG:0] 	dest0PhyMap_o,
			output [`SIZE_PHYSICAL_LOG:0] 	old0PhyMap_o,

		    output [`SIZE_PHYSICAL_LOG:0] 	src1rmt1_o,
            output [`SIZE_PHYSICAL_LOG:0] 	src1rmt2_o,
            output [`SIZE_PHYSICAL_LOG:0] 	dest1PhyMap_o,
			output [`SIZE_PHYSICAL_LOG:0] 	old1PhyMap_o,

		    output [`SIZE_PHYSICAL_LOG:0] 	src2rmt1_o,
            output [`SIZE_PHYSICAL_LOG:0] 	src2rmt2_o,
            output [`SIZE_PHYSICAL_LOG:0] 	dest2PhyMap_o,
			output [`SIZE_PHYSICAL_LOG:0] 	old2PhyMap_o,

		    output [`SIZE_PHYSICAL_LOG:0] 	src3rmt1_o,
            output [`SIZE_PHYSICAL_LOG:0] 	src3rmt2_o,
            output [`SIZE_PHYSICAL_LOG:0] 	dest3PhyMap_o,
			output [`SIZE_PHYSICAL_LOG:0] 	old3PhyMap_o

                     );



/* Instantiating RMT register file */
reg [`SIZE_PHYSICAL_LOG-1:0] RMT [`SIZE_RMT-1:0];



/* wires and regs definition for combinational logic. */
reg  [`SIZE_PHYSICAL_LOG:0] 		dest0Physical;
reg  [`SIZE_PHYSICAL_LOG:0] 		dest1Physical;
reg  [`SIZE_PHYSICAL_LOG:0] 		dest2Physical;
reg  [`SIZE_PHYSICAL_LOG:0] 		dest3Physical;

reg 					dontWrite0RMT;
reg 					dontWrite1RMT;
reg 					dontWrite2RMT;

wire 					writeEn0;
wire 					writeEn1;
wire 					writeEn2;
wire 					writeEn3;

/* Following defines wires for checking true dependencies between 
   the source and preceding destination registers.
*/
wire [`SIZE_PHYSICAL_LOG-1:0] 		src0physical1_r;
wire [`SIZE_PHYSICAL_LOG-1:0] 		src0physical2_r;
wire [`SIZE_PHYSICAL_LOG-1:0] 		src1physical1_r;
wire [`SIZE_PHYSICAL_LOG-1:0] 		src1physical2_r;
wire [`SIZE_PHYSICAL_LOG-1:0] 		src2physical1_r;
wire [`SIZE_PHYSICAL_LOG-1:0] 		src2physical2_r;
wire [`SIZE_PHYSICAL_LOG-1:0] 		src3physical1_r;
wire [`SIZE_PHYSICAL_LOG-1:0] 		src3physical2_r;

wire [`SIZE_PHYSICAL_LOG:0] 		src0physical1;
wire [`SIZE_PHYSICAL_LOG:0] 		src0physical2;

wire [`SIZE_PHYSICAL_LOG:0] 		src1physical1;
wire [`SIZE_PHYSICAL_LOG:0] 		src1physical2;
wire [`SIZE_PHYSICAL_LOG:0] 		src1physical1F;
wire [`SIZE_PHYSICAL_LOG:0] 		src1physical2F;

wire [`SIZE_PHYSICAL_LOG:0] 		src2physical1;
wire [`SIZE_PHYSICAL_LOG:0] 		src2physical2;
wire [`SIZE_PHYSICAL_LOG:0] 		src2physical1F0;
wire [`SIZE_PHYSICAL_LOG:0] 		src2physical1F1;
wire [`SIZE_PHYSICAL_LOG:0] 		src2physical2F0;
wire [`SIZE_PHYSICAL_LOG:0] 		src2physical2F1;

wire [`SIZE_PHYSICAL_LOG:0] 		src3physical1;
wire [`SIZE_PHYSICAL_LOG:0] 		src3physical2;
wire [`SIZE_PHYSICAL_LOG:0] 		src3physical1F0;
wire [`SIZE_PHYSICAL_LOG:0] 		src3physical1F1;
wire [`SIZE_PHYSICAL_LOG:0] 		src3physical1F2;
wire [`SIZE_PHYSICAL_LOG:0] 		src3physical2F0;
wire [`SIZE_PHYSICAL_LOG:0] 		src3physical2F1;
wire [`SIZE_PHYSICAL_LOG:0] 		src3physical2F2;

/*******************************************************************************  
* Following instantiates RAM modules for Rename Map Table. The read and
* write ports depend on the commit width of the processor.
*
* An instruction updates the RMT only if it has valid destination register and 
* it does not matches with destination register of the newer instruction in the 
* same window.
*******************************************************************************/
 SRAM_8R4W_RMT #(`SIZE_RMT,`SIZE_RMT_LOG,`SIZE_PHYSICAL_LOG)
    RenameMap (
                 .addr0_i(src0logical1_i[`SIZE_RMT_LOG:1]),
                 .addr1_i(src0logical2_i[`SIZE_RMT_LOG:1]),
                 .addr2_i(src1logical1_i[`SIZE_RMT_LOG:1]),
                 .addr3_i(src1logical2_i[`SIZE_RMT_LOG:1]),
                 .addr4_i(src2logical1_i[`SIZE_RMT_LOG:1]),
                 .addr5_i(src2logical2_i[`SIZE_RMT_LOG:1]),
                 .addr6_i(src3logical1_i[`SIZE_RMT_LOG:1]),
                 .addr7_i(src3logical2_i[`SIZE_RMT_LOG:1]),
                 .we0_i(writeEn0),
                 .addr0wr_i(inst0Dest_i[`SIZE_RMT_LOG:1]),
                 .data0wr_i(dest0Physical[`SIZE_PHYSICAL_LOG:1]),
                 .we1_i(writeEn1),
                 .addr1wr_i(inst1Dest_i[`SIZE_RMT_LOG:1]),
                 .data1wr_i(dest1Physical[`SIZE_PHYSICAL_LOG:1]),
                 .we2_i(writeEn2),
                 .addr2wr_i(inst2Dest_i[`SIZE_RMT_LOG:1]),
                 .data2wr_i(dest2Physical[`SIZE_PHYSICAL_LOG:1]),
                 .we3_i(writeEn3),
                 .addr3wr_i(inst3Dest_i[`SIZE_RMT_LOG:1]),
                 .data3wr_i(dest3Physical[`SIZE_PHYSICAL_LOG:1]),
                 .clk(clk),
                 .reset(reset),
                 .data0_o(src0physical1_r),
                 .data1_o(src0physical2_r),
                 .data2_o(src1physical1_r),
                 .data3_o(src1physical2_r),
                 .data4_o(src2physical1_r),
                 .data5_o(src2physical2_r),
                 .data6_o(src3physical1_r),
                 .data7_o(src3physical2_r)
              );


/*******************************************************************************
* Following assigns physical registers (popped from the spec free list)
* to the destination registers.
*******************************************************************************/
always @(*)
begin
case({inst3Dest_i[0],inst2Dest_i[0],inst1Dest_i[0],inst0Dest_i[0]})
  4'b0000:
    begin
      dest0Physical  = 0;
      dest1Physical  = 0;
      dest2Physical  = 0;
      dest3Physical  = 0;
    end
  4'b0001:
    begin
      dest0Physical  = dest0Physical_i;
      dest1Physical  = 0;
      dest2Physical  = 0;
      dest3Physical  = 0;
    end
  4'b0010:
    begin
      dest0Physical  = 0;
      dest1Physical  = dest0Physical_i;
      dest2Physical  = 0;
      dest3Physical  = 0;
    end
  4'b0011:
    begin
      dest0Physical  = dest0Physical_i;
      dest1Physical  = dest1Physical_i;
      dest2Physical  = 0;
      dest3Physical  = 0;
    end
  4'b0100:
    begin
      dest0Physical  = 0;
      dest1Physical  = 0;
      dest2Physical  = dest0Physical_i;
      dest3Physical  = 0;
    end
  4'b0101:
    begin
      dest0Physical  = dest0Physical_i;
      dest1Physical  = 0;
      dest2Physical  = dest1Physical_i;
      dest3Physical  = 0;
    end
  4'b0110:
    begin
      dest0Physical  = 0;
      dest1Physical  = dest0Physical_i;
      dest2Physical  = dest1Physical_i;
      dest3Physical  = 0;
    end
  4'b0111:
    begin
      dest0Physical  = dest0Physical_i;
      dest1Physical  = dest1Physical_i;
      dest2Physical  = dest2Physical_i;
      dest3Physical  = 0;
    end
  4'b1000:
    begin
      dest0Physical  = 0;
      dest1Physical  = 0;
      dest2Physical  = 0;
      dest3Physical  = dest0Physical_i;
    end
  4'b1001:
    begin
      dest0Physical  = dest0Physical_i;
      dest1Physical  = 0;
      dest2Physical  = 0;
      dest3Physical  = dest1Physical_i;
    end
  4'b1010:
    begin
      dest0Physical  = 0;
      dest1Physical  = dest0Physical_i;
      dest2Physical  = 0;
      dest3Physical  = dest1Physical_i;
    end
  4'b1011:
    begin
      dest0Physical  = dest0Physical_i;
      dest1Physical  = dest1Physical_i;
      dest2Physical  = 0;
      dest3Physical  = dest2Physical_i;
    end
  4'b1100:
    begin
      dest0Physical  = 0;
      dest1Physical  = 0;
      dest2Physical  = dest0Physical_i;
      dest3Physical  = dest1Physical_i;
    end
  4'b1101:
    begin
      dest0Physical  = dest0Physical_i;
      dest1Physical  = 0;
      dest2Physical  = dest1Physical_i;
      dest3Physical  = dest2Physical_i;
    end
  4'b1110:
    begin
      dest0Physical  = 0;
      dest1Physical  = dest0Physical_i;
      dest2Physical  = dest1Physical_i;
      dest3Physical  = dest2Physical_i;
    end
  4'b1111:
    begin
      dest0Physical  = dest0Physical_i;
      dest1Physical  = dest1Physical_i;
      dest2Physical  = dest2Physical_i;
      dest3Physical  = dest3Physical_i;
    end
 endcase
end



/*  Check if destination of an instruction matches with destination of the newer
 *  instruction in the rename window. If there is a match then this instruction
 *  doesn't update the RMT.
 */
always @(*)
begin
	if(inst0Dest_i == inst1Dest_i ||
		inst0Dest_i == inst2Dest_i ||
		inst0Dest_i == inst3Dest_i) dontWrite0RMT = 1;
  else
     dontWrite0RMT = 0;

	if(inst1Dest_i == inst2Dest_i ||
		inst1Dest_i == inst3Dest_i) dontWrite1RMT = 1;
  else
     dontWrite1RMT = 0;

	if(inst2Dest_i == inst3Dest_i) dontWrite2RMT = 1;
  else
     dontWrite2RMT = 0;

end




/* Reading Physical register mapping of each valid source register
 * from RMT if valid bit is 1. 
 */
assign src0physical1 = (src0logical1_i[0]) ? {src0physical1_r,1'b1}:0;
assign src0physical2 = (src0logical2_i[0]) ? {src0physical2_r,1'b1}:0;

assign src1physical1 = (src1logical1_i[0]) ? {src1physical1_r,1'b1}:0;
assign src1physical2 = (src1logical2_i[0]) ? {src1physical2_r,1'b1}:0;

assign src2physical1 = (src2logical1_i[0]) ? {src2physical1_r,1'b1}:0;
assign src2physical2 = (src2logical2_i[0]) ? {src2physical2_r,1'b1}:0;

assign src3physical1 = (src3logical1_i[0]) ? {src3physical1_r,1'b1}:0;
assign src3physical2 = (src3logical2_i[0]) ? {src3physical2_r,1'b1}:0;

/* Checking data dependency between Instruction-1 source registers
   and preceding instructions' destination registers.  */
assign src1physical1F    = (src1logical1_i == inst0Dest_i) ? dest0Physical:src1physical1;
assign src1physical2F    = (src1logical2_i == inst0Dest_i) ? dest0Physical:src1physical2;

/* Checking data dependency between Instruction-2 source registers
   and preceding instructions' destination registers.  */
assign src2physical1F0    = (src2logical1_i == inst0Dest_i) ? dest0Physical:src2physical1;
assign src2physical1F1    = (src2logical1_i == inst1Dest_i) ? dest1Physical:src2physical1F0;
assign src2physical2F0    = (src2logical2_i == inst0Dest_i) ? dest0Physical:src2physical2;
assign src2physical2F1    = (src2logical2_i == inst1Dest_i) ? dest1Physical:src2physical2F0;

/* Checking data dependency between Instruction-3 source registers
   and preceding instructions' destination registers.  */
assign src3physical1F0    = (src3logical1_i == inst0Dest_i) ? dest0Physical:src3physical1;
assign src3physical1F1    = (src3logical1_i == inst1Dest_i) ? dest1Physical:src3physical1F0;
assign src3physical1F2    = (src3logical1_i == inst2Dest_i) ? dest2Physical:src3physical1F1;
assign src3physical2F0    = (src3logical2_i == inst0Dest_i) ? dest0Physical:src3physical2;
assign src3physical2F1    = (src3logical2_i == inst1Dest_i) ? dest1Physical:src3physical2F0;
assign src3physical2F2    = (src3logical2_i == inst2Dest_i) ? dest2Physical:src3physical2F1;


/* Assigning renamed logical source and destination registers to output. */
assign src0rmt1_o    = src0physical1;
assign src0rmt2_o    = src0physical2;
assign dest0PhyMap_o = dest0Physical; 

assign src1rmt1_o    = src1physical1F;
assign src1rmt2_o    = src1physical2F;
assign dest1PhyMap_o = dest1Physical; 

assign src2rmt1_o    = src2physical1F1;
assign src2rmt2_o    = src2physical2F1;
assign dest2PhyMap_o = dest2Physical; 

assign src3rmt1_o    = src3physical1F2;
assign src3rmt2_o    = src3physical2F2;
assign dest3PhyMap_o = dest3Physical; 


assign old0PhyMap_o   = 0;
assign old1PhyMap_o   = 0;
assign old2PhyMap_o   = 0;
assign old3PhyMap_o   = 0;

/* Updating new Logical to Physical Mappings into the RMT table. */
assign writeEn0       = ~recoverFlag_i & ~stall_i & inst0Dest_i[0]& ~dontWrite0RMT;
assign writeEn1       = ~recoverFlag_i & ~stall_i & inst1Dest_i[0]& ~dontWrite1RMT;
assign writeEn2       = ~recoverFlag_i & ~stall_i & inst2Dest_i[0]& ~dontWrite2RMT;
assign writeEn3       = ~recoverFlag_i & ~stall_i & inst3Dest_i[0];

`ifdef VERIFY
always @(posedge clk)
begin:RMT_UPDATE
 integer i;
 if(recoverFlag_i)
 begin
	for(i=0;i<`SIZE_RMT;i=i+1)
     	begin
        	simulate.fabScalar.rename.RMT.RenameMap.sram[i]  <= simulate.fabScalar.amt.AMT.sram[i];
     	end
 end
end
`endif


endmodule
