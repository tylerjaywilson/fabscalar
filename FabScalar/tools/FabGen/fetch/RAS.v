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


module RAS(input clk,
           input reset,
           input stall_i,
           input flushRas_i,
	   input [`SIZE_PC-1:0] pc_i,
           input flagRecoverID_i,
           input flagCallID_i,
           input [`SIZE_PC-1:0] callPCID_i,
           input flagRtrID_i,
           input flagRecoverEX_i,
           input pop_i,
           input push_i,
           input  [`SIZE_PC-1:0] pushAddr_i,
           output [`SIZE_PC-1:0] addrRAS_o,
           output [`SIZE_PC-1:0] addrRAS_CP_o
          );


/* Instantiating memory for RAS and Checkpointed RAS. The memory works 
   as circular LIFO.  
*/
reg [`SIZE_PC-1:0] stack [`SIZE_RAS-1:0];
reg [`SIZE_RAS_LOG-1:0] tos;
reg [`SIZE_RAS_LOG-1:0] tos_CP;


/* wire and register definition for combinational logic */
wire 				push;
wire 				pop;
wire [`SIZE_RAS_LOG-1:0] 	tos_n;
reg  [`SIZE_RAS_LOG-1:0] 	tos_c;


/* Output the target address in case of return instruction.
 */
assign tos_n	    = (flagRecoverID_i) ? tos_CP:tos;
assign addrRAS_o    =  stack[tos_n];
assign addrRAS_CP_o =  stack[tos_n];


/* Following combinational logic calculates the next tos and the address to be
 * pushed on stack in case of call instruction.
 */
assign push  = (push_i&~flagRecoverID_i) | (flagRecoverID_i & flagCallID_i);
assign pop   = (pop_i&~flagRecoverID_i)  | (flagRecoverID_i & flagRtrID_i);

always @(*)
begin:NEW_TOS
   tos_c = (flagRecoverID_i) ? tos_CP:tos;
	case({push,pop})
	2'b01: 
	begin
		tos_c = tos-1'b1;
		`ifdef VERIFY
                	//$display("BTB hit for Rtr instr, Pop Addr:%x",stack[tos]);
                `endif
	end

	2'b10:
	begin
		tos_c = tos+1'b1;
		`ifdef VERIFY
                	//$display("BTB hit for CALL instr, Push Addr:%x",pushAddr_i);
                `endif
	end
	endcase	
end



/* Following updates tos and stack at every clock cycle.
 */ 
always @(posedge clk)
begin:UPDATE_RAS
 integer i;
 //if(reset || flagRecoverEX_i || flushRas_i)
 if(reset)
 begin
	for(i=0;i<`SIZE_RAS;i=i+1)
	begin
		stack[i] <= 0;
	end
	tos	 <= 0;
	tos_CP	 <= 0;
	`ifdef VERIFY
        	//$display("RAS getting flushed");
        `endif
 end
 else
 begin
	tos 	<= tos_c;

	if(flagRecoverID_i && flagCallID_i)
	begin
		//$display("cycle:%d   tos_c:%d should peform write.....\n",simulate.sim_count,tos_c);
		stack[tos_c]  <= (callPCID_i+8);
	end
	else if(push_i && ~flagRecoverID_i)
	begin
		stack[tos_c]  <= pushAddr_i;
	end

	if(flagRecoverID_i)
		tos_CP  <= tos_c;
	else
		tos_CP  <= tos;
 end
end

endmodule
