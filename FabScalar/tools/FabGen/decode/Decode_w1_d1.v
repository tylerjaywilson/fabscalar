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

		input fs2Ready_i,
		input inst0PacketValid_i,
                input [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst0Packet_i,
                

		output decodeReady_o,	
		output [2*`FETCH_BANDWIDTH-1:0] decodedVector_o,
                output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
			1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket0_o,
                output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
			1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket1_o
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



/* Following assigns decoded packets to the output ports.
 */
assign decodedPacket0_o    = decodedPacket_f[0];	
assign decodedPacket1_o    = decodedPacket_f[1];	
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

