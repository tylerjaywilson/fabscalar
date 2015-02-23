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

module RAS (	input clk,
						input reset,
						input stall_i,
						input flush_RAS_i,
						input [`SIZE_PC-1:0]push_addr_i,
						input recover_ID_i,
						input push_i,
						input pop_i,
						input [`SIZE_PC-1:0]ras_top_addr_i,
						input update_ras_top_i,
						input [`SIZE_PC-1:0]CP_push_addr_i,
						input CP_push_i,
						input CP_pop_i,
						
						output [`SIZE_PC-1:0]pop_addr_o,
						output is_empty_o,
						output [`SIZE_PC-1:0]CP_pop_addr_o,
						output CP_is_empty_o
					);

/* Instantiating memory for RAS and Checkpointed RAS. The memory works 
   as LIFO.  
*/
reg [`SIZE_PC-1:0] stack [`SIZE_RAS-1:0];
reg [`SIZE_RAS_LOG-1:0] tos;

reg [`SIZE_PC-1:0] CP_stack [`SIZE_RAS-1:0];
reg [`SIZE_RAS_LOG-1:0] CP_tos;

reg [`SIZE_RAS_LOG-1:0]new_tos;
reg [`SIZE_RAS_LOG-1:0]new_CP_tos;
reg [`SIZE_RAS_LOG-1:0]recover_tos;
wire [`SIZE_PC-1:0]to_write;
wire [`SIZE_PC-1:0]CP_to_write;
wire [`SIZE_PC-1:0]recover_to_write;
integer i;

assign to_write = update_ras_top_i ? ras_top_addr_i : push_i ? push_addr_i + 4'd8 : 0;
assign CP_to_write = CP_push_i ? CP_push_addr_i + 4'd8 : 0;
assign recover_to_write = push_i ? push_addr_i + 4'd8 : CP_stack[recover_tos-1'b1];
assign pop_addr_o = stack[tos-1'b1];
assign CP_pop_addr_o = CP_stack[CP_tos-1'b1];
assign is_empty_o = 1'b0;
assign CP_is_empty_o = 1'b0;

always@(*)
begin
	case({push_i,pop_i})
	2'b00:	begin
				new_tos = tos;
			end
	2'b01:	begin
			//	if(tos!=0)
					new_tos = tos - 1'b1;
			//	else
			//		new_tos = tos;
			end
	2'b10: begin
			//	if(tos!=`SIZE_RAS)
					new_tos = tos + 1'b1;
			//	else
			//		new_tos = tos;
			end
	2'b11: begin
				new_tos = tos;
			end
	endcase
end

always@(*)
begin
	case({CP_push_i,CP_pop_i})
	2'b00:	begin
				new_CP_tos = CP_tos;
			end
	2'b01:	begin
		//		if(CP_tos!=0)
					new_CP_tos = CP_tos - 1'b1;
		//		else
		//			new_CP_tos = CP_tos;
			end
	2'b10: begin
		//		if(CP_tos!=`SIZE_RAS)
					new_CP_tos = CP_tos + 1'b1;
		//		else
		//			new_CP_tos = CP_tos;
			end
	2'b11: begin
				new_CP_tos = CP_tos;
			end
	endcase
end

always@(*)
begin
		case({push_i,pop_i})
	2'b00:	begin
				recover_tos = CP_tos;
			end
	2'b01:	begin
		//		if(CP_tos!=0)
					recover_tos = CP_tos - 1'b1;
		//		else
		//			recover_tos = CP_tos;
			end
	2'b10: begin
		//		if(CP_tos!=`SIZE_RAS)
					recover_tos = CP_tos + 1'b1;
		//		else
		//			recover_tos = CP_tos;
			end
	2'b11: begin
				recover_tos = CP_tos;
			end
	endcase
end

always@(posedge clk)
begin
	if(reset || flush_RAS_i)
	begin
		tos		<= 0;
		CP_tos	<= 0;
	end
	else if(~stall_i)
	begin
		tos		<= recover_ID_i ? recover_tos : new_tos;
		CP_tos	<= new_CP_tos;
	end
end

always@(posedge clk)
begin
	if(reset || flush_RAS_i)
	begin
		for(i=0;i<`SIZE_RAS;i=i+1)
		begin
			stack[i]    <= 0;
			CP_stack[i] <= 0;
		end	
	end
	else if(~stall_i)
	begin
		for(i=0;i<`SIZE_RAS;i=i+1)
		begin
			if(recover_ID_i)
				stack[i] <= (i==recover_tos-1'b1) ? recover_to_write : CP_stack[i];
			else
				stack[i] <= (i==tos) && push_i ? to_write : stack[i];
			CP_stack[i] <= (i==CP_tos) && CP_push_i? CP_to_write : CP_stack[i];
		end	
	end
end

endmodule



