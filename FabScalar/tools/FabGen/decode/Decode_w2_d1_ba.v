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


module Decode(	input reset,
                input clk,
				input stall_i,
		input fs2Ready_i,
		input inst0PacketValid_i,
                input [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst0Packet_i,
		input inst1PacketValid_i,
                input [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst1Packet_i,
                
				input valid_pc_i,
				input [`SIZE_PC-1:0]last_pc_i,
				input btb_hit_i,
				input [`BRANCH_TYPE-1:0]br_type_i,
				input br_dir_i,
				input hit_last_i,
				input [`BRANCH_TYPE-1:0]hit_type_i,
				input [`SIZE_PC-1:0]hit_target_i,
				input [`FETCH_BANDWIDTH_LOG-1:0]hit_position_b_i,
				input is_jalr_jr_i,
				input is_ctrl_i,
				input [`FIFO_SIZE-1:0]fifo_even_i,
				input [`FIFO_SIZE-1:0]fifo_odd_i,
				input old_br_dir_i,
				
				output reg dec_valid_o,
				output reg [`SIZE_PC-1:0] dec_tag_pc_o,
				output reg [`BRANCH_TYPE-1:0]dec_br_type_o,
				output reg dec_btb_hit_o,
				output reg dec_br_dir_o,
				output reg dec_hit_l_o,
				output reg [`BRANCH_TYPE-1:0]dec_hit_t_o,
				output reg [`SIZE_PC-1:0]dec_hit_target_o,
				output reg [`FETCH_BANDWIDTH_LOG-1:0]dec_hit_b_o,
				output reg dec_old_br_dir_o,
				output reg dec_is_jalr_jr_o,
				output reg dec_is_ctrl_o,
				output reg [`FIFO_SIZE-1:0]dec_fifo_even_o,
				output reg [`FIFO_SIZE-1:0]dec_fifo_odd_o,					

		output decodeReady_o,	
		output [2*`FETCH_BANDWIDTH-1:0] decodedVector_o,
                output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
			1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket0_o,
                output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
			1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket1_o,
                output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
			1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket2_o,
                output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
			1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket3_o
             );


/********************************** I/O Declaration ************************************/


wire [2*`FETCH_BANDWIDTH-1:0]		decodedPacketValid;
wire [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
     1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] 
					decodedPacket [2*`FETCH_BANDWIDTH-1:0];
reg [2*`FETCH_BANDWIDTH-1:0] 		decodedVector;
reg [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
     1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] 
					decodedPacket_f [2*`FETCH_BANDWIDTH-1:0];

reg [`SIZE_PC-1:0]tag_pc;
reg btb_hit;
reg [`BRANCH_TYPE-1:0]br_type;
reg br_dir;
reg valid;
reg old_br_dir;
reg hit_last;
reg [`BRANCH_TYPE-1:0]hit_type;
reg [`SIZE_PC-1:0]hit_target;
reg [`FETCH_BANDWIDTH_LOG-1:0]hit_position_b;
reg is_jalr_jr;
reg is_ctrl;

always@(*)
begin
	casex({valid_pc_i,valid})
	2'b1x:	begin
				dec_valid_o = valid_pc_i;
				dec_tag_pc_o = last_pc_i;
				dec_br_type_o = br_type_i;
				dec_btb_hit_o = btb_hit_i;
				dec_br_dir_o = br_dir_i;
				dec_hit_l_o = hit_last_i;
				dec_hit_t_o = hit_type_i;
				dec_hit_target_o = hit_target_i;
				dec_hit_b_o = hit_position_b_i;
				dec_old_br_dir_o = old_br_dir_i;
				dec_is_jalr_jr_o = is_jalr_jr_i;
				dec_is_ctrl_o = is_ctrl_i;
				dec_fifo_even_o = fifo_even_i;
				dec_fifo_odd_o = fifo_odd_i;
			end
	2'b01:	begin
				dec_valid_o = valid;
				dec_tag_pc_o = tag_pc;
				dec_br_type_o = br_type;
				dec_btb_hit_o = btb_hit;
				dec_br_dir_o = br_dir;
				dec_hit_l_o = hit_last;
				dec_hit_t_o = hit_type;
				dec_hit_target_o = hit_target;
				dec_hit_b_o = hit_position_b;
				dec_old_br_dir_o = old_br_dir;
				dec_is_jalr_jr_o = is_jalr_jr;
				dec_is_ctrl_o = is_ctrl;
				dec_fifo_even_o = fifo_even_i;
				dec_fifo_odd_o = fifo_odd_i;
			end
	2'b00:	begin
				dec_valid_o = 0;
				dec_tag_pc_o = 0;
				dec_br_type_o = 0;
				dec_btb_hit_o = 0;
				dec_br_dir_o = 0;
				dec_hit_l_o = 0;
				dec_hit_t_o = 0;
				dec_hit_target_o = 0;
				dec_hit_b_o = `FETCH_BANDWIDTH-1;
				dec_old_br_dir_o = 0;
				dec_is_jalr_jr_o = 0;
				dec_is_ctrl_o = 0;
				dec_fifo_even_o = 0;
				dec_fifo_odd_o = 0;
			end
	endcase
end

always@(posedge clk)
begin
	if(reset)
	begin
		valid <= 0;
		tag_pc <= 0;
		br_type <= 0;
		btb_hit <= 0;
		br_dir <= 1;
		hit_last <= 0;
		hit_type <= 0;
		hit_target <= 0;
		hit_position_b <= `FETCH_BANDWIDTH-1;
		old_br_dir <= 0;
		is_jalr_jr <= 0;
		is_ctrl <= 0;
	end
	else if(valid_pc_i & ~stall_i)
	begin
		valid <= 1;
		tag_pc <= last_pc_i;
		br_type <= br_type_i;
		btb_hit <= btb_hit_i;
		br_dir <= br_dir_i;
		hit_last <= hit_last_i;
		hit_type <= hit_type_i;
		hit_target <= hit_target_i;
		hit_position_b <= hit_position_b_i;
		old_br_dir <= old_br_dir_i;
		is_jalr_jr <= is_jalr_jr_i;
		is_ctrl <= is_ctrl_i;
	end
end


/* Following assigns decoded packets to the output ports.
 */
assign decodedPacket0_o    = decodedPacket_f[0];	
assign decodedPacket1_o    = decodedPacket_f[1];	
assign decodedPacket2_o    = decodedPacket_f[2];	
assign decodedPacket3_o    = decodedPacket_f[3];	
assign decodedVector_o	   = decodedVector;	

assign decodeReady_o	   = fs2Ready_i;


/* Following instantiates PISA decode blocks for at most FETCH BANDWIDTH instructions.
 */

 Decode_PISA decode0_PISA ( .instPacketValid_i(inst0PacketValid_i),
			    .instPacket_i(inst0Packet_i),
			    .decodedPacket0Valid_o(decodedPacketValid[0]),
			    .decodedPacket0_o(decodedPacket[0]),	
			    .decodedPacket1Valid_o(decodedPacketValid[1]),
			    .decodedPacket1_o(decodedPacket[1])
                   	  );


 Decode_PISA decode1_PISA ( .instPacketValid_i(inst1PacketValid_i),
			    .instPacket_i(inst1Packet_i),
			    .decodedPacket0Valid_o(decodedPacketValid[2]),
			    .decodedPacket0_o(decodedPacket[2]),	
			    .decodedPacket1Valid_o(decodedPacketValid[3]),
			    .decodedPacket1_o(decodedPacket[3])
                   	  );


/* Following counts number of Branch instructions in the current set
 * of instructions. 
 * Only those control instructions are considered, which have not been
 * resolved in Fetch-2 stage.
 */
always @(*)
begin:SHIFTING_DECODED_INST
  integer index;
  integer i;
  index = 0;
  decodedVector   = 0;
  for(i=0;i<2*`FETCH_BANDWIDTH;i=i+1)
  begin
	if(decodedPacketValid[i])
	begin
		decodedVector[index]   = 1'b1;
		decodedPacket_f[index] = decodedPacket[i];
		index 		       = index + 1; 		
	end			
  end 
end

endmodule

