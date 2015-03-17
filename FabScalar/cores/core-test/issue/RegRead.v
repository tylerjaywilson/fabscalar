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
# Purpose: This module implements Register-Read stage.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps


  module RegRead ( 
                 input [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket0_i,
                 input fuPacketValid0_i,
		 input [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket0_i,
                 input bypassValid0_i,
                 input [`SIZE_PHYSICAL_LOG:0] unmapDest0_i,
                 input [`SIZE_PHYSICAL_LOG-1:0] rsr0Tag_i,
                 input                          rsr0TagValid_i,
                 input [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket1_i,
                 input fuPacketValid1_i,
		 input [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket1_i,
                 input bypassValid1_i,
                 input [`SIZE_PHYSICAL_LOG:0] unmapDest1_i,
                 input [`SIZE_PHYSICAL_LOG-1:0] rsr1Tag_i,
                 input                          rsr1TagValid_i,
                 input [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket2_i,
                 input fuPacketValid2_i,
		 input [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket2_i,
                 input bypassValid2_i,
                 input [`SIZE_PHYSICAL_LOG:0] unmapDest2_i,
                 input [`SIZE_PHYSICAL_LOG-1:0] rsr2Tag_i,
                 input                          rsr2TagValid_i,
                 input [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket3_i,
                 input fuPacketValid3_i,
		 input [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket3_i,
                 input bypassValid3_i,
                 input [`SIZE_PHYSICAL_LOG:0] unmapDest3_i,
                 input [`SIZE_PHYSICAL_LOG-1:0] rsr3Tag_i,
                 input                          rsr3TagValid_i,
                 input ctrlVerified_i,                          // control execution flags from the bypass path
                 input ctrlMispredict_i,                        // if 1, there has been a mis-predict previous cycle
                 input [`CHECKPOINTS_LOG-1:0] ctrlSMTid_i,      // SMT id of the mispredicted branch

                 output [`SIZE_PHYSICAL_TABLE-1:0] phyRegRdy_o,

                 output [2*`SIZE_DATA+`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                         `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                         `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket0_o,
                 output fuPacketValid0_o,
                 output [2*`SIZE_DATA+`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                         `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                         `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket1_o,
                 output fuPacketValid1_o,
                 output [2*`SIZE_DATA+`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                         `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                         `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket2_o,
                 output fuPacketValid2_o,
                 output [2*`SIZE_DATA+`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                         `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                         `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket3_o,
                 output fuPacketValid3_o,
 input clk,
                 input reset,
                 input recoverFlag_i,
                 input exceptionFlag_i
              );

 reg [`SIZE_PHYSICAL_TABLE-1:0] PHY_REG_VALID; 
`define SRAM_DATA_WIDTH 32

 reg [`SIZE_PHYSICAL_LOG-1:0]           inst0Source1; 
 reg [`SIZE_PHYSICAL_LOG-1:0]           inst0Source2; 
 reg [`SIZE_PHYSICAL_LOG-1:0]           inst1Source1; 
 reg [`SIZE_PHYSICAL_LOG-1:0]           inst1Source2; 
 reg [`SIZE_PHYSICAL_LOG-1:0]           inst2Source1; 
 reg [`SIZE_PHYSICAL_LOG-1:0]           inst2Source2; 
 reg [`SIZE_PHYSICAL_LOG-1:0]           inst3Source1; 
 reg [`SIZE_PHYSICAL_LOG-1:0]           inst3Source2; 


 reg [`SIZE_DATA-1:0]           bypass0Data; 
 reg [`SIZE_DATA-1:0]           bypass1Data; 
 reg [`SIZE_DATA-1:0]           bypass2Data; 
 reg [`SIZE_DATA-1:0]           bypass3Data; 

 reg [`SIZE_PHYSICAL_LOG-1:0]           bypass0Dest; 
 reg [`SIZE_PHYSICAL_LOG-1:0]           bypass1Dest; 
 reg [`SIZE_PHYSICAL_LOG-1:0]           bypass2Dest; 
 reg [`SIZE_PHYSICAL_LOG-1:0]           bypass3Dest; 


 reg                                    mispredictEvent;
 reg [`CHECKPOINTS_LOG-1:0]             mispredictSMTid;

 reg [`CHECKPOINTS-1:0]                  inst0Mask_l1;
 reg [`CHECKPOINTS-1:0]                  inst1Mask_l1;
 reg [`CHECKPOINTS-1:0]                  inst2Mask_l1;
 reg [`CHECKPOINTS-1:0]                  inst3Mask_l1;
 reg [`SIZE_DATA-1:0]           inst0Data1; 
 reg [`SIZE_DATA-1:0]           inst0Data2; 
 reg [`SIZE_DATA-1:0]           inst1Data1; 
 reg [`SIZE_DATA-1:0]           inst1Data2; 
 reg [`SIZE_DATA-1:0]           inst2Data1; 
 reg [`SIZE_DATA-1:0]           inst2Data2; 
 reg [`SIZE_DATA-1:0]           inst3Data1; 
 reg [`SIZE_DATA-1:0]           inst3Data2; 

 reg [`SRAM_DATA_WIDTH-1:0]           inst0Data1_11; 
 reg [`SRAM_DATA_WIDTH-1:0]           inst0Data2_11; 
 reg [`SRAM_DATA_WIDTH-1:0]           inst1Data1_11; 
 reg [`SRAM_DATA_WIDTH-1:0]           inst1Data2_11; 
 reg [`SRAM_DATA_WIDTH-1:0]           inst2Data1_11; 
 reg [`SRAM_DATA_WIDTH-1:0]           inst2Data2_11; 
 reg [`SRAM_DATA_WIDTH-1:0]           inst3Data1_11; 
 reg [`SRAM_DATA_WIDTH-1:0]           inst3Data2_11; 



 reg                  		fuPacketValid0_l1; 
 reg                  		fuPacketValid1_l1; 
 reg                  		fuPacketValid2_l1; 
 reg                  		fuPacketValid3_l1; 


 reg [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket0_i_l1; 
 reg [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket1_i_l1; 
 reg [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket2_i_l1; 
 reg [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket3_i_l1; 


 wire [`SIZE_PHYSICAL_TABLE-1:0] decoded_addr0_stage1_o; 
 wire [`SIZE_PHYSICAL_TABLE-1:0] decoded_addr1_stage1_o; 
 wire [`SIZE_PHYSICAL_TABLE-1:0] decoded_addr2_stage1_o; 
 wire [`SIZE_PHYSICAL_TABLE-1:0] decoded_addr3_stage1_o; 
 wire [`SIZE_PHYSICAL_TABLE-1:0] decoded_addr4_stage1_o; 
 wire [`SIZE_PHYSICAL_TABLE-1:0] decoded_addr5_stage1_o; 
 wire [`SIZE_PHYSICAL_TABLE-1:0] decoded_addr6_stage1_o; 
 wire [`SIZE_PHYSICAL_TABLE-1:0] decoded_addr7_stage1_o; 


 wire [`SIZE_PHYSICAL_TABLE-1:0] decoded_addr0wr_stage1_o; 
 wire [`SIZE_PHYSICAL_TABLE-1:0] decoded_addr1wr_stage1_o; 
 wire [`SIZE_PHYSICAL_TABLE-1:0] decoded_addr2wr_stage1_o; 
 wire [`SIZE_PHYSICAL_TABLE-1:0] decoded_addr3wr_stage1_o; 



 wire we0_stage1_o, we1_stage1_o, we2_stage1_o, we3_stage1_o; 

 wire [`SRAM_DATA_WIDTH-1:0]                     data0_stage1; 
 wire [`SRAM_DATA_WIDTH-1:0]                     data1_stage1; 
 wire [`SRAM_DATA_WIDTH-1:0]                     data2_stage1; 
 wire [`SRAM_DATA_WIDTH-1:0]                     data3_stage1; 
 wire [`SRAM_DATA_WIDTH-1:0]                     data4_stage1; 
 wire [`SRAM_DATA_WIDTH-1:0]                     data5_stage1; 
 wire [`SRAM_DATA_WIDTH-1:0]                     data6_stage1; 
 wire [`SRAM_DATA_WIDTH-1:0]                     data7_stage1; 


 reg [`SRAM_DATA_WIDTH-1:0]                     bypass0Data_stage1i; 
 reg [`SRAM_DATA_WIDTH-1:0]                     bypass1Data_stage1i; 
 reg [`SRAM_DATA_WIDTH-1:0]                     bypass2Data_stage1i; 
 reg [`SRAM_DATA_WIDTH-1:0]                     bypass3Data_stage1i; 


 reg [`SRAM_DATA_WIDTH-1:0]                     bypass0Data_1; 
 reg [`SRAM_DATA_WIDTH-1:0]                     bypass1Data_1; 
 reg [`SRAM_DATA_WIDTH-1:0]                     bypass2Data_1; 
 reg [`SRAM_DATA_WIDTH-1:0]                     bypass3Data_1; 

 wire   inst0Src1_mch0, inst0Src2_mch0; 
 wire   inst0Src1_mch1, inst0Src2_mch1; 
 wire   inst0Src1_mch2, inst0Src2_mch2; 
 wire   inst0Src1_mch3, inst0Src2_mch3; 
 wire   inst1Src1_mch0, inst1Src2_mch0; 
 wire   inst1Src1_mch1, inst1Src2_mch1; 
 wire   inst1Src1_mch2, inst1Src2_mch2; 
 wire   inst1Src1_mch3, inst1Src2_mch3; 
 wire   inst2Src1_mch0, inst2Src2_mch0; 
 wire   inst2Src1_mch1, inst2Src2_mch1; 
 wire   inst2Src1_mch2, inst2Src2_mch2; 
 wire   inst2Src1_mch3, inst2Src2_mch3; 
 wire   inst3Src1_mch0, inst3Src2_mch0; 
 wire   inst3Src1_mch1, inst3Src2_mch1; 
 wire   inst3Src1_mch2, inst3Src2_mch2; 
 wire   inst3Src1_mch3, inst3Src2_mch3; 
 wire [3:0] inst0Src1_11_mVector, inst0Src2_11_mVector; 
 wire [3:0] inst1Src1_11_mVector, inst1Src2_11_mVector; 
 wire [3:0] inst2Src1_11_mVector, inst2Src2_11_mVector; 
 wire [3:0] inst3Src1_11_mVector, inst3Src2_11_mVector; 




 always@(*) 
 begin 
	bypass0Data_stage1i 	= bypass0Data[`SRAM_DATA_WIDTH-1:0]; 
	bypass0Data_1 		= bypass0Data[1*`SRAM_DATA_WIDTH-1:0*`SRAM_DATA_WIDTH]; 

	bypass1Data_stage1i 	= bypass1Data[`SRAM_DATA_WIDTH-1:0]; 
	bypass1Data_1 		= bypass1Data[1*`SRAM_DATA_WIDTH-1:0*`SRAM_DATA_WIDTH]; 

	bypass2Data_stage1i 	= bypass2Data[`SRAM_DATA_WIDTH-1:0]; 
	bypass2Data_1 		= bypass2Data[1*`SRAM_DATA_WIDTH-1:0*`SRAM_DATA_WIDTH]; 

	bypass3Data_stage1i 	= bypass3Data[`SRAM_DATA_WIDTH-1:0]; 
	bypass3Data_1 		= bypass3Data[1*`SRAM_DATA_WIDTH-1:0*`SRAM_DATA_WIDTH]; 

 end 
 SRAM_8R4W_PIPE #(`SIZE_PHYSICAL_TABLE,`SIZE_PHYSICAL_LOG,`SRAM_DATA_WIDTH) 
		 PhyRegFile1( 
			 .addr0_i(inst0Source1), 
			 .addr1_i(inst0Source2), 
			 .we0_i(bypassValid0_i & ~recoverFlag_i), 
			 .addr0wr_i(bypass0Dest), 
			 .data0wr_i(bypass0Data_stage1i), 
			 .decoded_addr0wr_o(decoded_addr0wr_stage1_o), 
			 .we0_o(we0_stage1_o), 
			 .addr2_i(inst1Source1), 
			 .addr3_i(inst1Source2), 
			 .we1_i(bypassValid1_i & ~recoverFlag_i), 
			 .addr1wr_i(bypass1Dest), 
			 .data1wr_i(bypass1Data_stage1i), 
			 .decoded_addr1wr_o(decoded_addr1wr_stage1_o), 
			 .we1_o(we1_stage1_o), 
			 .addr4_i(inst2Source1), 
			 .addr5_i(inst2Source2), 
			 .we2_i(bypassValid2_i & ~recoverFlag_i), 
			 .addr2wr_i(bypass2Dest), 
			 .data2wr_i(bypass2Data_stage1i), 
			 .decoded_addr2wr_o(decoded_addr2wr_stage1_o), 
			 .we2_o(we2_stage1_o), 
			 .addr6_i(inst3Source1), 
			 .addr7_i(inst3Source2), 
			 .we3_i(bypassValid3_i & ~recoverFlag_i), 
			 .addr3wr_i(bypass3Dest), 
			 .data3wr_i(bypass3Data_stage1i), 
			 .decoded_addr3wr_o(decoded_addr3wr_stage1_o), 
			 .we3_o(we3_stage1_o), 
			 .data0_o(data0_stage1), 
			 .decoded_addr0_o(decoded_addr0_stage1_o), 
			 .data1_o(data1_stage1), 
			 .decoded_addr1_o(decoded_addr1_stage1_o), 
			 .data2_o(data2_stage1), 
			 .decoded_addr2_o(decoded_addr2_stage1_o), 
			 .data3_o(data3_stage1), 
			 .decoded_addr3_o(decoded_addr3_stage1_o), 
			 .data4_o(data4_stage1), 
			 .decoded_addr4_o(decoded_addr4_stage1_o), 
			 .data5_o(data5_stage1), 
			 .decoded_addr5_o(decoded_addr5_stage1_o), 
			 .data6_o(data6_stage1), 
			 .decoded_addr6_o(decoded_addr6_stage1_o), 
			 .data7_o(data7_stage1), 
			 .decoded_addr7_o(decoded_addr7_stage1_o), 
			 .clk(clk), 
			 .reset(reset) 
		);
always @(*)
begin
 inst0Source1 = fuPacket0_i[`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                            `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                            `SIZE_PC+`SIZE_CTI_LOG:`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                            `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                            `SIZE_PC+`SIZE_CTI_LOG+1]; 

 inst0Source2 = fuPacket0_i[2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                            `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                            `SIZE_PC+`SIZE_CTI_LOG:`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+
                            `CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+
                            `SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1]; 

 inst1Source1 = fuPacket1_i[`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                            `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                            `SIZE_PC+`SIZE_CTI_LOG:`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                            `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                            `SIZE_PC+`SIZE_CTI_LOG+1]; 

 inst1Source2 = fuPacket1_i[2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                            `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                            `SIZE_PC+`SIZE_CTI_LOG:`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+
                            `CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+
                            `SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1]; 

 inst2Source1 = fuPacket2_i[`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                            `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                            `SIZE_PC+`SIZE_CTI_LOG:`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                            `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                            `SIZE_PC+`SIZE_CTI_LOG+1]; 

 inst2Source2 = fuPacket2_i[2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                            `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                            `SIZE_PC+`SIZE_CTI_LOG:`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+
                            `CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+
                            `SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1]; 

 inst3Source1 = fuPacket3_i[`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                            `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                            `SIZE_PC+`SIZE_CTI_LOG:`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                            `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                            `SIZE_PC+`SIZE_CTI_LOG+1]; 

 inst3Source2 = fuPacket3_i[2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                            `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                            `SIZE_PC+`SIZE_CTI_LOG:`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+
                            `CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+
                            `SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1]; 

end


always @(*)
begin
 mispredictEvent = ctrlVerified_i & ctrlMispredict_i; 
 mispredictSMTid = ctrlSMTid_i; 

 bypass0Data = bypassPacket0_i[`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1]; 
 bypass0Dest = bypassPacket0_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:`SIZE_DATA+`CHECKPOINTS_LOG+1]; 

 bypass1Data = bypassPacket1_i[`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1]; 
 bypass1Dest = bypassPacket1_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:`SIZE_DATA+`CHECKPOINTS_LOG+1]; 

 bypass2Data = bypassPacket2_i[`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1]; 
 bypass2Dest = bypassPacket2_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:`SIZE_DATA+`CHECKPOINTS_LOG+1]; 

 bypass3Data = bypassPacket3_i[`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1]; 
 bypass3Dest = bypassPacket3_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:`SIZE_DATA+`CHECKPOINTS_LOG+1]; 

 inst0Mask_l1 	= fuPacket0_i[`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                            `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                            `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:
                            `SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                            `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                            `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1]; 

 inst1Mask_l1 	= fuPacket1_i[`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                            `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                            `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:
                            `SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                            `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                            `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1]; 

 inst2Mask_l1 	= fuPacket2_i[`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                            `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                            `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:
                            `SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                            `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                            `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1]; 

 inst3Mask_l1 	= fuPacket3_i[`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                            `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                            `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:
                            `SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                            `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                            `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1]; 

end

 assign inst0Src1_mch0 = ((inst0Source1 == bypass0Dest) && bypassValid0_i); 
 assign inst0Src2_mch0 = ((inst0Source2 == bypass0Dest) && bypassValid0_i); 
 assign inst0Src1_mch1 = ((inst0Source1 == bypass1Dest) && bypassValid1_i); 
 assign inst0Src2_mch1 = ((inst0Source2 == bypass1Dest) && bypassValid1_i); 
 assign inst0Src1_mch2 = ((inst0Source1 == bypass2Dest) && bypassValid2_i); 
 assign inst0Src2_mch2 = ((inst0Source2 == bypass2Dest) && bypassValid2_i); 
 assign inst0Src1_mch3 = ((inst0Source1 == bypass3Dest) && bypassValid3_i); 
 assign inst0Src2_mch3 = ((inst0Source2 == bypass3Dest) && bypassValid3_i); 


 assign inst1Src1_mch0 = ((inst1Source1 == bypass0Dest) && bypassValid0_i); 
 assign inst1Src2_mch0 = ((inst1Source2 == bypass0Dest) && bypassValid0_i); 
 assign inst1Src1_mch1 = ((inst1Source1 == bypass1Dest) && bypassValid1_i); 
 assign inst1Src2_mch1 = ((inst1Source2 == bypass1Dest) && bypassValid1_i); 
 assign inst1Src1_mch2 = ((inst1Source1 == bypass2Dest) && bypassValid2_i); 
 assign inst1Src2_mch2 = ((inst1Source2 == bypass2Dest) && bypassValid2_i); 
 assign inst1Src1_mch3 = ((inst1Source1 == bypass3Dest) && bypassValid3_i); 
 assign inst1Src2_mch3 = ((inst1Source2 == bypass3Dest) && bypassValid3_i); 


 assign inst2Src1_mch0 = ((inst2Source1 == bypass0Dest) && bypassValid0_i); 
 assign inst2Src2_mch0 = ((inst2Source2 == bypass0Dest) && bypassValid0_i); 
 assign inst2Src1_mch1 = ((inst2Source1 == bypass1Dest) && bypassValid1_i); 
 assign inst2Src2_mch1 = ((inst2Source2 == bypass1Dest) && bypassValid1_i); 
 assign inst2Src1_mch2 = ((inst2Source1 == bypass2Dest) && bypassValid2_i); 
 assign inst2Src2_mch2 = ((inst2Source2 == bypass2Dest) && bypassValid2_i); 
 assign inst2Src1_mch3 = ((inst2Source1 == bypass3Dest) && bypassValid3_i); 
 assign inst2Src2_mch3 = ((inst2Source2 == bypass3Dest) && bypassValid3_i); 


 assign inst3Src1_mch0 = ((inst3Source1 == bypass0Dest) && bypassValid0_i); 
 assign inst3Src2_mch0 = ((inst3Source2 == bypass0Dest) && bypassValid0_i); 
 assign inst3Src1_mch1 = ((inst3Source1 == bypass1Dest) && bypassValid1_i); 
 assign inst3Src2_mch1 = ((inst3Source2 == bypass1Dest) && bypassValid1_i); 
 assign inst3Src1_mch2 = ((inst3Source1 == bypass2Dest) && bypassValid2_i); 
 assign inst3Src2_mch2 = ((inst3Source2 == bypass2Dest) && bypassValid2_i); 
 assign inst3Src1_mch3 = ((inst3Source1 == bypass3Dest) && bypassValid3_i); 
 assign inst3Src2_mch3 = ((inst3Source2 == bypass3Dest) && bypassValid3_i); 




 assign inst0Src1_11_mVector = { inst0Src1_mch3, inst0Src1_mch2, inst0Src1_mch1, inst0Src1_mch0} ;

 assign inst0Src2_11_mVector = { inst0Src2_mch3, inst0Src2_mch2, inst0Src2_mch1, inst0Src2_mch0} ;
 assign inst1Src1_11_mVector = { inst1Src1_mch3, inst1Src1_mch2, inst1Src1_mch1, inst1Src1_mch0} ;

 assign inst1Src2_11_mVector = { inst1Src2_mch3, inst1Src2_mch2, inst1Src2_mch1, inst1Src2_mch0} ;
 assign inst2Src1_11_mVector = { inst2Src1_mch3, inst2Src1_mch2, inst2Src1_mch1, inst2Src1_mch0} ;

 assign inst2Src2_11_mVector = { inst2Src2_mch3, inst2Src2_mch2, inst2Src2_mch1, inst2Src2_mch0} ;
 assign inst3Src1_11_mVector = { inst3Src1_mch3, inst3Src1_mch2, inst3Src1_mch1, inst3Src1_mch0} ;

 assign inst3Src2_11_mVector = { inst3Src2_mch3, inst3Src2_mch2, inst3Src2_mch1, inst3Src2_mch0} ;




 always @(*)
	begin
		case (inst0Src1_11_mVector)
		4'd1	:	inst0Data1_11 = bypass0Data_1; 
		4'd2	:	inst0Data1_11 = bypass1Data_1; 
		4'd4	:	inst0Data1_11 = bypass2Data_1; 
		4'd8	:	inst0Data1_11 = bypass3Data_1; 
		default	:	inst0Data1_11 = data0_stage1; 
		endcase
	end

 always @(*)
	begin
		case (inst0Src2_11_mVector)
		4'd1	:	inst0Data2_11 = bypass0Data_1; 
		4'd2	:	inst0Data2_11 = bypass1Data_1; 
		4'd4	:	inst0Data2_11 = bypass2Data_1; 
		4'd8	:	inst0Data2_11 = bypass3Data_1; 
		default	:	inst0Data2_11 = data1_stage1; 
		endcase
	end

 always @(*)
	begin
		case (inst1Src1_11_mVector)
		4'd1	:	inst1Data1_11 = bypass0Data_1; 
		4'd2	:	inst1Data1_11 = bypass1Data_1; 
		4'd4	:	inst1Data1_11 = bypass2Data_1; 
		4'd8	:	inst1Data1_11 = bypass3Data_1; 
		default	:	inst1Data1_11 = data2_stage1; 
		endcase
	end

 always @(*)
	begin
		case (inst1Src2_11_mVector)
		4'd1	:	inst1Data2_11 = bypass0Data_1; 
		4'd2	:	inst1Data2_11 = bypass1Data_1; 
		4'd4	:	inst1Data2_11 = bypass2Data_1; 
		4'd8	:	inst1Data2_11 = bypass3Data_1; 
		default	:	inst1Data2_11 = data3_stage1; 
		endcase
	end

 always @(*)
	begin
		case (inst2Src1_11_mVector)
		4'd1	:	inst2Data1_11 = bypass0Data_1; 
		4'd2	:	inst2Data1_11 = bypass1Data_1; 
		4'd4	:	inst2Data1_11 = bypass2Data_1; 
		4'd8	:	inst2Data1_11 = bypass3Data_1; 
		default	:	inst2Data1_11 = data4_stage1; 
		endcase
	end

 always @(*)
	begin
		case (inst2Src2_11_mVector)
		4'd1	:	inst2Data2_11 = bypass0Data_1; 
		4'd2	:	inst2Data2_11 = bypass1Data_1; 
		4'd4	:	inst2Data2_11 = bypass2Data_1; 
		4'd8	:	inst2Data2_11 = bypass3Data_1; 
		default	:	inst2Data2_11 = data5_stage1; 
		endcase
	end

 always @(*)
	begin
		case (inst3Src1_11_mVector)
		4'd1	:	inst3Data1_11 = bypass0Data_1; 
		4'd2	:	inst3Data1_11 = bypass1Data_1; 
		4'd4	:	inst3Data1_11 = bypass2Data_1; 
		4'd8	:	inst3Data1_11 = bypass3Data_1; 
		default	:	inst3Data1_11 = data6_stage1; 
		endcase
	end

 always @(*)
	begin
		case (inst3Src2_11_mVector)
		4'd1	:	inst3Data2_11 = bypass0Data_1; 
		4'd2	:	inst3Data2_11 = bypass1Data_1; 
		4'd4	:	inst3Data2_11 = bypass2Data_1; 
		4'd8	:	inst3Data2_11 = bypass3Data_1; 
		default	:	inst3Data2_11 = data7_stage1; 
		endcase
	end




 always@(*)
 begin 
	inst0Data1 = { inst0Data1_11}; 
	inst0Data2 = { inst0Data2_11}; 
	inst1Data1 = { inst1Data1_11}; 
	inst1Data2 = { inst1Data2_11}; 
	inst2Data1 = { inst2Data1_11}; 
	inst2Data2 = { inst2Data2_11}; 
	inst3Data1 = { inst3Data1_11}; 
	inst3Data2 = { inst3Data2_11}; 
end

 always@(*)
 begin 
	if(mispredictEvent && inst0Mask_l1[mispredictSMTid])
		fuPacketValid0_l1 = 1'b0; 
	else
		fuPacketValid0_l1 = fuPacketValid0_i;
	if(mispredictEvent && inst1Mask_l1[mispredictSMTid])
		fuPacketValid1_l1 = 1'b0; 
	else
		fuPacketValid1_l1 = fuPacketValid1_i;
	if(mispredictEvent && inst2Mask_l1[mispredictSMTid])
		fuPacketValid2_l1 = 1'b0; 
	else
		fuPacketValid2_l1 = fuPacketValid2_i;
	if(mispredictEvent && inst3Mask_l1[mispredictSMTid])
		fuPacketValid3_l1 = 1'b0; 
	else
		fuPacketValid3_l1 = fuPacketValid3_i;
end

 assign phyRegRdy_o      = PHY_REG_VALID;
 assign fuPacketValid0_o = fuPacketValid0_l1;
 assign fuPacket0_o = {inst0Data2, inst0Data1, fuPacket0_i};
 assign fuPacketValid1_o = fuPacketValid1_l1;
 assign fuPacket1_o = {inst1Data2, inst1Data1, fuPacket1_i};
 assign fuPacketValid2_o = fuPacketValid2_l1;
 assign fuPacket2_o = {inst2Data2, inst2Data1, fuPacket2_i};
 assign fuPacketValid3_o = fuPacketValid3_l1;
 assign fuPacket3_o = {inst3Data2, inst3Data1, fuPacket3_i};


 always @(posedge clk)
 begin:UPDATE_PHY_REG
   integer i, j, k;

   if(reset | exceptionFlag_i)
   begin
        for(i=0;i<`SIZE_RMT;i=i+1)
        begin
                PHY_REG_VALID[i] <= 1'b1;
        end

        for(j=`SIZE_RMT;j<`SIZE_PHYSICAL_TABLE;j=j+1)
        begin
                PHY_REG_VALID[j] <= 1'b0;
        end
   end
   else
   begin

	if(unmapDest0_i[0]) PHY_REG_VALID[unmapDest0_i[`SIZE_PHYSICAL_LOG:1]] <= 1'b0;
	if(unmapDest1_i[0]) PHY_REG_VALID[unmapDest1_i[`SIZE_PHYSICAL_LOG:1]] <= 1'b0;
	if(unmapDest2_i[0]) PHY_REG_VALID[unmapDest2_i[`SIZE_PHYSICAL_LOG:1]] <= 1'b0;
	if(unmapDest3_i[0]) PHY_REG_VALID[unmapDest3_i[`SIZE_PHYSICAL_LOG:1]] <= 1'b0;

	if(rsr0TagValid_i) PHY_REG_VALID[rsr0Tag_i]    <= 1'b1;
	if(rsr1TagValid_i) PHY_REG_VALID[rsr1Tag_i]    <= 1'b1;
	if(rsr2TagValid_i) PHY_REG_VALID[rsr2Tag_i]    <= 1'b1;
	if(bypassValid3_i) PHY_REG_VALID[bypass3Dest]  <= 1'b1;
	end
 end

endmodule

