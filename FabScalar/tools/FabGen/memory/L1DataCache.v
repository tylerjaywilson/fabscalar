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


module L1DataCache( input 	clk,
		    input 	reset,
                    input 	rdEn_i,
                    input 	[`SIZE_DCACHE_ADDR-1:0] rdAddr_i,
		    input 	[`LDST_TYPES_LOG-1:0] 	ldSize_i,
		    input	ldSign_i,	
		    `ifdef VERIFY
		    input 	[`SIZE_ACTIVELIST_LOG-1:0] agenALid_i,
		    `endif		

                    input 	wrEn_i,
                    input 	[`SIZE_DCACHE_ADDR-1:0] wrAddr_i,
                    input 	[`SIZE_DATA-1:0] 	wrData_i,
		    input 	[`LDST_TYPES_LOG-1:0] 	stSize_i,

                    output 	rdHit_o,
                    output 	[`SIZE_DATA-1:0] rdData_o,
                    output 	wrHit_o
                  );



/* Following defines wires and regs for combinational logic
 */
reg [`SIZE_DATA-1:0] rdData; 


 assign rdHit_o   = 1'b1;
 assign rdData_o  = rdData;	
 assign wrHit_o   = 1'b1;


/*  Following calls VPI related to load and store interfaces with functional
 *  simulator. 
 */
always @(*)
begin:MEM_ACCESS
 reg [`SIZE_PC-1:0] rdAddr;
 reg [`SIZE_PC-1:0] wrAddr;

 if(rdEn_i)
 begin
   case(ldSize_i)
	`LDST_BYTE:     
	 begin
 				rdAddr = rdAddr_i;
				//$display("read byte at addr:%h\n",rdAddr); 	
		if(rdAddr[31])
                                rdData = 32'hdeadbeef;
                else
		begin
			if(ldSign_i) 	
				rdData = $readSignedByte(rdAddr);
			else
				rdData = ($readUnsignedByte(rdAddr) & 32'h0000_00FF);
		end
	 end
	`LDST_HALF_WORD:
	 begin
 				rdAddr = {rdAddr_i[31:1],1'b0};
				//$display("read half word at addr:%h\n",rdAddr); 	
		if(rdAddr[31])
                                rdData = 32'hdeadbeef;
		else
		begin
			if(ldSign_i)	
				rdData = $readSignedHalf(rdAddr);
			else		
				rdData = ($readUnsignedHalf(rdAddr) & 32'h0000_FFFF);
		end
	 end
	`LDST_WORD:
	 begin 	
 				rdAddr = {rdAddr_i[31:2],2'b0};
				//$display("read word at addr:%h, ALid=%d\n",rdAddr,agenALid_i); 	
		if(rdAddr[31])	
				rdData = 32'hdeadbeef;
		else	
				rdData = $readWord(rdAddr);
	 end
   endcase
 end
 else
 begin
	rdData = 0; 
 end

 if(wrEn_i)
 begin
  case(stSize_i)
	`LDST_BYTE:
	 begin
 		wrAddr = wrAddr_i;
		//$display("store byte at addr:%h\n",wrAddr);
		//if(simulate.sim_count < 148429)
 		$writeByte(wrData_i,wrAddr);
	 end
	`LDST_HALF_WORD:
	 begin
 		wrAddr = {wrAddr_i[31:1],1'b0};
		//$display("store half word at addr:%h\n",wrAddr);
		//if(simulate.sim_count < 148429)
		$writeHalf(wrData_i,wrAddr);
	 end
	`LDST_WORD:
	 begin
 		wrAddr = {wrAddr_i[31:2],2'b0};
		//$display("store word at addr:%h\n",wrAddr);
		//if(simulate.sim_count < 148429)
		$writeWord(wrData_i,wrAddr);
	 end
  endcase		
 end
end

endmodule
