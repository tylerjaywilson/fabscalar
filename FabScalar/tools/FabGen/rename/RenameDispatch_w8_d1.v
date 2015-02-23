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


module RenameDispatch(
 input clk,
 input reset,
 input flush_i,
 input stall_i,
 input ctrlVerified_i,

 input renameReady_i,
 input [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
        `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
        `SIZE_CTI_LOG:0] renamedPacket0_i,
 input [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
        `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
        `SIZE_CTI_LOG:0] renamedPacket1_i,
 input [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
        `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
        `SIZE_CTI_LOG:0] renamedPacket2_i,
 input [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
        `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
        `SIZE_CTI_LOG:0] renamedPacket3_i,
 input [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
        `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
        `SIZE_CTI_LOG:0] renamedPacket4_i,
 input [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
        `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
        `SIZE_CTI_LOG:0] renamedPacket5_i,
 input [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
        `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
        `SIZE_CTI_LOG:0] renamedPacket6_i,
 input [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
        `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
        `SIZE_CTI_LOG:0] renamedPacket7_i,

 input [`CHECKPOINTS-1:0] updatedBranchMask0_i,
 input [`CHECKPOINTS-1:0] updatedBranchMask1_i,
 input [`CHECKPOINTS-1:0] updatedBranchMask2_i,
 input [`CHECKPOINTS-1:0] updatedBranchMask3_i,
 input [`CHECKPOINTS-1:0] updatedBranchMask4_i,
 input [`CHECKPOINTS-1:0] updatedBranchMask5_i,
 input [`CHECKPOINTS-1:0] updatedBranchMask6_i,
 input [`CHECKPOINTS-1:0] updatedBranchMask7_i,

 output reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
             `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
             `SIZE_CTI_LOG:0] renamedPacket0_o,
 output reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
             `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
             `SIZE_CTI_LOG:0] renamedPacket1_o,
 output reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
             `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
             `SIZE_CTI_LOG:0] renamedPacket2_o,
 output reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
             `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
             `SIZE_CTI_LOG:0] renamedPacket3_o,
 output reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
             `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
             `SIZE_CTI_LOG:0] renamedPacket4_o,
 output reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
             `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
             `SIZE_CTI_LOG:0] renamedPacket5_o,
 output reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
             `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
             `SIZE_CTI_LOG:0] renamedPacket6_o,
 output reg [`SIZE_RMT_LOG+3+`CHECKPOINTS+`CHECKPOINTS_LOG+4*`SIZE_PHYSICAL_LOG+4+
             `SIZE_IMMEDIATE+1+`LDST_TYPES_LOG+`INST_TYPES_LOG+`SIZE_OPCODE_I+2*`SIZE_PC+
             `SIZE_CTI_LOG:0] renamedPacket7_o,
 output reg renameReady_o
);


always @(posedge clk)
begin
 if(reset || flush_i)
 begin
        renameReady_o    <= 0;
        renamedPacket0_o  <=  0;
        renamedPacket1_o  <=  0;
        renamedPacket2_o  <=  0;
        renamedPacket3_o  <=  0;
        renamedPacket4_o  <=  0;
        renamedPacket5_o  <=  0;
        renamedPacket6_o  <=  0;
        renamedPacket7_o  <=  0;
 end
 else if(~stall_i)
 begin
        renameReady_o    <= renameReady_i;
        renamedPacket0_o  <=  renamedPacket0_i;
        renamedPacket1_o  <=  renamedPacket1_i;
        renamedPacket2_o  <=  renamedPacket2_i;
        renamedPacket3_o  <=  renamedPacket3_i;
        renamedPacket4_o  <=  renamedPacket4_i;
        renamedPacket5_o  <=  renamedPacket5_i;
        renamedPacket6_o  <=  renamedPacket6_i;
        renamedPacket7_o  <=  renamedPacket7_i;
 end
end


endmodule
