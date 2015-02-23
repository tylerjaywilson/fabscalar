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

/* Algorithm

   1. Receives 4 new instructions from Instruction Buffer with "instBufferReady_i"
      signal ready.

   2. Instruction packet contains following information:
	(a.) instruction      "bits-`SIZE_INSTRUCTION+`2*`SIZE_PC+`SIZE_CTI_LOG:`2*SIZE_PC+`SIZE_CTI_LOG+1"
        (b.) Program Counter  "bits-2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1"
        (c.) Target Address   "bits-`SIZE_PC+`SIZE_CTI_LOG:`SIZE_CTI_LOG+1"
        (d.) Ctiq Tag         "bits-`SIZE_CTI_LOG:1"
        (e.) Branch Direction "bit-0"
   
   3. If "instBufferReady_i" signal is 1 then all the 4 instruction are valid.

   4. Instruction is decoded to generate all the required information for the rest
      of the stage.   

   5. decodedPacket contains following information:
	(a.) Dest HI/LO       "bits-2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1"
	(b.) Source HI/LO     "bits-`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1"
	(c.) Branch Inst      "bits-3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG"
	(d.) Store Inst       "bits-2+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG"
	(e.) Load Inst        "bits-1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG" 
	(f.) LD/ST Data Size  "bits-`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1"
	(g.) FU Type	      "bits-`INST_TYPES_LOG+`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1" 
	(h.) Immediate Data   "bits-`SIZE_IMMEDIATE+1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1"
 	(i.) Destination Reg  "bits-3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:2*`SIZE_RMT_LOG+2+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1"
	(j.) Source Reg1      "bits-2*`SIZE_RMT_LOG+2+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_RMT_LOG+1+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1"
	(k.) Source Reg0      "bits-`SIZE_RMT_LOG+1+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG+1"
	(l.) Opcode           "bits-`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:2*`SIZE_PC+`SIZE_CTI_LOG+1"
	(m.) Program Counter  "bits-2*`SIZE_PC+`SIZE_CTI_LOG:`SIZE_PC+`SIZE_CTI_LOG+1"
	(n.) Target Address   "bits-`SIZE_PC+`SIZE_CTI_LOG:`SIZE_CTI_LOG+1"
	(o.) Ctiq Tag         "bits-`SIZE_CTI_LOG:1"
	(p.) Branch Direction "bit-0"

*/


module Decode(	input reset,
                input clk,

		input fs2Ready_i,
		input inst0PacketValid_i,
                input [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst0Packet_i,
		input inst1PacketValid_i,
                input [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst1Packet_i,
		input inst2PacketValid_i,
                input [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst2Packet_i,
		input inst3PacketValid_i,
                input [`SIZE_INSTRUCTION+2*`SIZE_PC+`SIZE_CTI_LOG:0] inst3Packet_i,
                

		output decodeReady_o,	
		output [2*`FETCH_BANDWIDTH-1:0] decodedVector_o,
                output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
			1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket0_o,
                output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
			1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket1_o,
                output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
			1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket2_o,
                output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
			1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket3_o,
		output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                        1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket4_o,
                output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                        1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket5_o,
                output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                        1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket6_o,
                output [2*`SIZE_SPECIAL_REG+3+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_IMMEDIATE+
                        1+3*`SIZE_RMT_LOG+3+`SIZE_OPCODE_I+2*`SIZE_PC+`SIZE_CTI_LOG:0] decodedPacket7_o

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
assign decodedPacket2_o    = decodedPacket_f[2];	
assign decodedPacket3_o    = decodedPacket_f[3];	
assign decodedPacket4_o    = decodedPacket_f[4];	
assign decodedPacket5_o    = decodedPacket_f[5];	
assign decodedPacket6_o    = decodedPacket_f[6];	
assign decodedPacket7_o    = decodedPacket_f[7];
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


 Decode_PISA decode2_PISA ( .instPacketValid_i(inst2PacketValid_i),
			    .instPacket_i(inst2Packet_i),
			    .decodedPacket0Valid_o(decodedPacketValid[4]),
			    .decodedPacket0_o(decodedPacket[4]),	
			    .decodedPacket1Valid_o(decodedPacketValid[5]),
			    .decodedPacket1_o(decodedPacket[5])
                   	  );


 Decode_PISA decode3_PISA ( .instPacketValid_i(inst3PacketValid_i),
			    .instPacket_i(inst3Packet_i),
			    .decodedPacket0Valid_o(decodedPacketValid[6]),
			    .decodedPacket0_o(decodedPacket[6]),	
			    .decodedPacket1Valid_o(decodedPacketValid[7]),
			    .decodedPacket1_o(decodedPacket[7])
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

