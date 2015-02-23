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
# Purpose: This block implements Control Instruction Queue. It can insert 1 
#          control instruction per cycle and retire 1 control istruction per 
#          cycle. 
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps


module CtrlQueue(	input clk,
				input reset,
				input stall_i,
				input flush_i,
				/*	Entries in the CTIQ
					1. Valid bit 
					2. PC
					3. pred_dir 
					4. br_type
					5. target_valid
					6. target
					7. next_br_type
					8. tag_pc
					9. target_dir
					10. is_call_updated
					11. ras_top
					12. hit_l
					13. hit_b
					14. is_jalr_jr
					15. btb_hit
					16. actual dir
					17. executed
				*/
				input [1+`SIZE_PC+1+`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1+1+1-1:0] new_entry_i,
				input is_ctrl_resolved,
				input [`SIZE_CTI_LOG-1:0] resolved_tag_i,
				input write_actual_dir_i,
				input recover_EX_i,
				input [`RETIRE_WIDTH-1:0] commitCti_i,				
				output [1+`SIZE_PC+1+`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1:0]resolved_entry_o,
				output [1+`SIZE_PC+1+`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1+1+1-1:0]head_entry_o,
				output [`SIZE_CTI_LOG-1:0]ctiq_entry_o,
				output is_CTIQ_full_o
		);
		
/* The CTIQ is split into 3 segments, 1. Read on resolve 2. Read on resolve and retire 3. Write on resolve and Read on retire */
/* Segement 1*/
reg [1+`SIZE_PC+1+`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1:0] ctiqInfo0[`SIZE_CTI_QUEUE-1:0];

/* Segment 2*/

/* Segment 3*/
reg [1+1-1:0] ctiqInfo2[`SIZE_CTI_QUEUE-1:0];

reg [`SIZE_CTI_LOG-1:0]head;
reg [`SIZE_CTI_LOG-1:0]tail;
reg [`SIZE_CTI_LOG:0]ctrl_count;
reg [`SIZE_CTI_LOG-1:0]commitptr;

wire new_entry_is_valid = new_entry_i[1+`SIZE_PC+1+`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1+1+1-1:`SIZE_PC+1+`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1+1+1];
reg [`SIZE_CTI_LOG-1:0]new_tail;
reg [`SIZE_CTI_LOG-1:0]new_head;
reg [`SIZE_CTI_LOG:0]new_ctrl_count;
wire is_CTIQ_empty;
integer i;
wire [`SIZE_CTI_LOG-1:0]commitCnt;

wire [`SIZE_CTI_LOG-1:0]commitPtr_t0;
wire [`SIZE_CTI_LOG-1:0]commitPtr_t1;
wire [`SIZE_CTI_LOG-1:0]commitPtr_t2;
wire [`SIZE_CTI_LOG-1:0]commitPtr_t3;
wire [`SIZE_CTI_LOG-1:0]new_commitptr;
wire [`SIZE_CTI_LOG-1:0]last_commitptr;

reg [1+`SIZE_PC+1+`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1:0] last_committed;

assign commitCnt = commitCti_i[3]+commitCti_i[2]+commitCti_i[1]+commitCti_i[0];
assign resolved_entry_o = last_committed;
assign head_entry_o = (ctrl_count==0) ? 0 : {ctiqInfo0[head],ctiqInfo2[head]};
assign is_CTIQ_full_o = (ctrl_count==`SIZE_CTI_QUEUE) ? 1'b1 : 1'b0;
assign is_CTIQ_empty = (ctrl_count==0) ? 1'b1 : 1'b0;
assign ctiq_entry_o = tail;

always@(*)
begin
	if(~is_CTIQ_full_o && new_entry_is_valid)
		new_tail = tail+1'b1;
	else
		new_tail = tail;
end

always@(*)
begin
	if(~is_CTIQ_empty && ctiqInfo2[head][0])
		new_head = head + 1'b1;
	else
		new_head = head;
end

always@(*)
begin
	case({~is_CTIQ_full_o && new_entry_is_valid && ~stall_i,~is_CTIQ_empty && ctiqInfo2[head][0]})
	2'b00:	begin
				new_ctrl_count = ctrl_count;
			end
	2'b01:	begin
				new_ctrl_count = ctrl_count - 1'b1;
			end
	2'b10:	begin
				new_ctrl_count = ctrl_count + 1'b1;
			end
	2'b11:	begin
				new_ctrl_count = ctrl_count;
			end
	endcase
end

always@(posedge clk)
begin
	if(reset)
	begin
		head <= 0;
	end
	else
	begin
		head <= new_head;
	end
end

always@(posedge clk)
begin
	if(reset)
	begin
		tail <= 0;
	end
	else if(flush_i)
	begin
		tail <= commitptr;
	end
	else if(~stall_i)
	begin
		tail <= new_tail;
	end
end

always@(posedge clk)
begin
	if(reset)
	begin
		ctrl_count <= 0;
	end
	else if(flush_i)
	begin
		if(new_head>commitptr)
			ctrl_count <= `SIZE_CTI_QUEUE-(new_head-commitptr);
		else
			ctrl_count <= commitptr-new_head;
	end
	else
	begin
		ctrl_count <= new_ctrl_count;
	end
end

assign new_commitptr = commitptr + commitCnt;
assign last_commitptr = commitptr + commitCnt - 1'b1;

always@(posedge clk)
begin
	if(reset)
	begin
		commitptr <= 0;
	end
	else
	begin
		commitptr <= new_commitptr;
	end
end

/* ctiqInfo0 has 1 write port and 2 read ports*/
always@(posedge clk)
begin
	if(reset)
	begin
		for(i=0;i<`SIZE_CTI_QUEUE;i=i+1)
		begin
			ctiqInfo0[i] <= 0;
		end
	end
	else if(~stall_i)
	begin
		if(~is_CTIQ_full_o && new_entry_is_valid)
			ctiqInfo0[tail] <= new_entry_i[1+`SIZE_PC+1+`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1+1+1-1:1+1];
	end
end

assign commitPtr_t0 = commitptr;
assign commitPtr_t1 = commitptr+1;
assign commitPtr_t2 = commitptr+2;
assign commitPtr_t3 = commitptr+3;

/* ctiqInfo2 has 2 write ports and 1 read port*/
always@(posedge clk)
begin
	
	if(reset)
	begin
		for(i=0;i<`SIZE_CTI_QUEUE;i=i+1)
		begin
			ctiqInfo2[i] <= 0;
		end
	end
	else
	begin
		if(~is_CTIQ_full_o && new_entry_is_valid && ~stall_i)
		begin
			ctiqInfo2[tail] <= new_entry_i[1+1-1:0];
		end
				
		if(is_ctrl_resolved)
		begin
			ctiqInfo2[resolved_tag_i][1] <= write_actual_dir_i;
		end

		case(commitCnt)
			4'd1:	
			begin
				ctiqInfo2[commitPtr_t0][0] <= 1;
			end
			4'd2:
			begin
				ctiqInfo2[commitPtr_t0][0] <= 1;
				ctiqInfo2[commitPtr_t1][0] <= 1;
			end
			4'd3:
			begin
				ctiqInfo2[commitPtr_t0][0] <= 1;
				ctiqInfo2[commitPtr_t1][0] <= 1;
				ctiqInfo2[commitPtr_t2][0] <= 1;
			end
			4'd4:
			begin
				ctiqInfo2[commitPtr_t0][0] <= 1;
				ctiqInfo2[commitPtr_t1][0] <= 1;
				ctiqInfo2[commitPtr_t2][0] <= 1;
				ctiqInfo2[commitPtr_t3][0] <= 1;
			end
		endcase
	end

	if(reset)
	begin
		last_committed <= 0;
	end
	else if(~is_CTIQ_empty && commitCnt>0)
	begin
		last_committed <= ctiqInfo0[last_commitptr];	
	end
	else if(~is_CTIQ_empty)
	begin
		last_committed[1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1] <= 0;
		last_committed[1+`FETCH_BANDWIDTH_LOG+1+1-1] <= 0;
		last_committed[`FETCH_BANDWIDTH_LOG+1+1-1:1+1] <= `FETCH_BANDWIDTH-1'b1;
		last_committed[`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1:`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1] <= 0;
		last_committed[`SIZE_PC+1+`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1-1:1+`BRANCH_TYPE+1+`SIZE_PC+`BRANCH_TYPE+`SIZE_PC+1+1+`SIZE_PC+1+`FETCH_BANDWIDTH_LOG+1+1] <= 0;
	end
end

endmodule
