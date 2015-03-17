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

   It is assumed there are 4 functional units with functions described 
   below:
	FU0 -> Simple ALU
	FU1 -> Complex ALU (for MULTIPLY & DIVIDE)
	FU2 -> ALU for CONTROL Instructions
	FU3 -> LOAD/STORE Address Generator
 
   fuPacket0 corresponds to FU0
   fuPacket1 corresponds to FU1
   fuPacket2 corresponds to FU2
   fuPacket3 corresponds to FU3
   
   1. Receive new packet to execute each cycle, if there are ready instructions 
      in the Issue Queue.
	
   2. Execute packet contains following information:
       (.) Opcode
       (.) Source Data-1
       (.) Source Register-1
       (.) Source Data-2
       (.) Source Register-2 
       (.) Destination Register
       (.) Active List ID
       (.) Issue Queue ID
       (.) Load-Store Queue ID
       (.) Branch Mask
       (.) Shadow Map Table (SMT) ID
       (.) Ctiq Tag
       (.) Predicted Target Address (for control inst)
       (.) Predicted Direction      (for branch inst)
       (.) Packet Valid bit

   3. Receive bypass inputs from the previous cycle from all functional units. 
      Instruction entering into the Execute should compare its source registers
      to bypassed destination registers.
        If, comparision result is true pick the bypassed value.

   4. Bypassed data should contain following information:
       (.) Destination Register
       (.) Output Data
       (.) Shadow Map Table ID
       (.) Control Mispredict
       (.) ***Disambig Stall***********	

   5. [ For current implementation Load instruction's RSR latency is same as Load execution 
        latency plus register file read latency. This means load dependent instructions will not 
        have back to back execution in best case.
      ]
      For Load dependent instructions, source tag should be compared against the load destination.
      If there is a match and the disambi stall signal is high, the instruction should be terminated.
      And the corresponding scheduled bit for the load dependent instruction in the issue queue 
      should be set to 0. 

   6. Output of a global Functional unit would be:
       (12) Destination Valid	
       (11) Executed
       (10) Exception
       (9)  Mispredict	
       (8)  Destination Register
       (7)  Active List ID
       (6)  Output Data
       (5)  Issue Queue ID
       (4)  Load-Store Queue ID
       (3)  Shadow Map Table ID  
       (2)  Ctiq Tag
       (1)  Computed Target Address
       (0)  Computed Direction

   
   Note: It is assumed that there are 4 functional units in the execute 
         stage.

***************************************************************************/

module Execute(
	input clk,
	input reset,

	/* Simple and complex ALU instructions contain following:
		    (9) Immediate Data  : bits-`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+
                       		         `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+
					 `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS	
		    (8) Opcode          : bits-`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (7) Source Data-1   : bits-`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS 
		    (6) Source Reg-1    : bits-`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (5) Source Data-2   : bits-`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
                    (4) Source Reg-2    : bits-`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (3) Destination Reg : bits-`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (2) Active List ID  : bits-`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (1) Issue Queue ID  : bits-`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`CHECKPOINTS
		    (0) Branch Mask     : bits-`CHECKPOINTS-1:0 
		*/
	input [`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+
		`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:0] fuPacket0_i,
	input fuPacketValid0_i,

	input [`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+
		`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:0] fuPacket1_i,
	input fuPacketValid1_i,

	/* Branch instructions contains following:
		     (14) PC                    : bits-
		     (13) Immediate Data        : bits-
                     (12) Opcode                : bits-`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
		     (11) Source Data-1         : bits-2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_PHYSICAL_LOG+`SIZE_DATA+2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
                     (10) Source Reg-1          : bits-`SIZE_PHYSICAL_LOG+`SIZE_DATA+2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_DATA+2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
                     (9)  Source Data-2         : bits-`SIZE_DATA+2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
                     (8)  Source Reg-2          : bits-2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
                     (7)  Destination Reg       : bits-`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
                     (6)  Active List ID        : bits-`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
                     (5)  Issue Queue ID        : bits-`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
                     (4)  Branch Mask           : bits-`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1
		     (3) SMT ID                : bits-`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:`SIZE_CTI_LOG+`SIZE_PC+1
		     (2) Ctiq Tag              : bits-`SIZE_CTI_LOG+`SIZE_PC:`SIZE_PC+1
		     (1) Predicted Target Addr : bits-`SIZE_PC:1
		     (0) Predicted Direction   : bits-0
                */
	input [`SIZE_PC+`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+
		`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] fuPacket2_i, 
	input fuPacketValid2_i,  

/* LD/ST instructions contains following:
		    (10)Immediate Data  : bits-	
		    (9) Opcode          : bits-`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (8) Source Data-1   : bits-`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS 
		    (7) Source Reg-1    : bits-`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (6) Source Data-2   : bits-`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
                    (5) Source Reg-2    : bits-`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (4) Destination Reg : bits-`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (3) LD-ST Queue ID  : bits-`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (2) Active List ID  : bits-`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_ISSUEQ_LOG+`CHECKPOINTS
		    (1) Issue Queue ID  : bits-`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`CHECKPOINTS
		    (0) Branch Mask     : bits-`CHECKPOINTS-1:0 
		*/ 
	input  [`SIZE_IMMEDIATE+`SIZE_OPCODE_I+2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+
		`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:0] fuPacket3_i, 
	input  fuPacketValid3_i,    

	/* Bypass Packet contains following:
		     (3)  Destination Register  : bits-`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:`SIZE_DATA+`CHECKPOINTS_LOG+1
		     (2)  Output Data           : bits-`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1
 		     (1)  Shadow Map Table ID   : bits-`CHECKPOINTS_LOG:1
                     (0)  Control Mispredict    : bits-0
                */
	input  [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket0_i,
	input  bypassValid0_i,
	input  [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket1_i,
	input  bypassValid1_i,
	input  [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket2_i,
	input  bypassValid2_i,
	input  [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket3_i,
	input  bypassValid3_i,

	input  ctrlVerified_i,
	input  ctrlMispredict_i,
	input  [`CHECKPOINTS_LOG-1:0] ctrlSMTid_i,

	output [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
		`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket0_o,
	output exePacketValid0_o,
	output [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
		`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket1_o,
	output exePacketValid1_o,
	output [`CHECKPOINTS+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_DATA+
		`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket2_o,
	output exePacketValid2_o,
	output [`CHECKPOINTS+`LDST_TYPES_LOG+`EXECUTION_FLAGS+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
		`SIZE_DATA+`SIZE_ISSUEQ_LOG+`SIZE_LSQ_LOG+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:0] exePacket3_o,
	output exePacketValid3_o
);

/* Defining wire and regs for combinational logic. */
reg [`SIZE_PHYSICAL_LOG-1:0] fu0reg1;
reg [`SIZE_DATA-1:0] fu0data1;
reg [`SIZE_PHYSICAL_LOG-1:0] fu0reg2;
reg [`SIZE_DATA-1:0] fu0data2;
reg [`SIZE_PHYSICAL_LOG-1:0] fu1reg1;
reg [`SIZE_DATA-1:0] fu1data1;
reg [`SIZE_PHYSICAL_LOG-1:0] fu1reg2;
reg [`SIZE_DATA-1:0] fu1data2;
reg [`SIZE_PHYSICAL_LOG-1:0] fu2reg1;
reg [`SIZE_DATA-1:0] fu2data1;
reg [`SIZE_PHYSICAL_LOG-1:0] fu2reg2;
reg [`SIZE_DATA-1:0] fu2data2;
reg [`SIZE_PHYSICAL_LOG-1:0] fu3reg1;
reg [`SIZE_DATA-1:0] fu3data1;
reg [`SIZE_PHYSICAL_LOG-1:0] fu3reg2;
reg [`SIZE_DATA-1:0] fu3data2;

wire [`SIZE_PHYSICAL_LOG-1:0] bypassTag0;
wire [`SIZE_DATA-1:0] bypassData0;
wire [`SIZE_PHYSICAL_LOG-1:0] bypassTag1;
wire [`SIZE_DATA-1:0] bypassData1;
wire [`SIZE_PHYSICAL_LOG-1:0] bypassTag2;
wire [`SIZE_DATA-1:0] bypassData2;
wire [`SIZE_PHYSICAL_LOG-1:0] bypassTag3;
wire [`SIZE_DATA-1:0] bypassData3;

wire [`SIZE_DATA-1:0] fu0FinalData1;
wire [`SIZE_DATA-1:0] fu0FinalData2;
wire [`SIZE_DATA-1:0] fu1FinalData1;
wire [`SIZE_DATA-1:0] fu1FinalData2;
wire [`SIZE_DATA-1:0] fu2FinalData1;
wire [`SIZE_DATA-1:0] fu2FinalData2;
wire [`SIZE_DATA-1:0] fu3FinalData1;
wire [`SIZE_DATA-1:0] fu3FinalData2;

/* Following instantiates FU0: simple ALU 
*/
 FU0 fu0( .clk(clk),
          .reset(reset),

          .inPacket_i(fuPacket0_i),
	  .fuFinalData1_i(fu0FinalData1),
	  .fuFinalData2_i(fu0FinalData2),
          .inValid_i(fuPacketValid0_i),

          .ctrlVerified_i(ctrlVerified_i),
          .ctrlMispredict_i(ctrlMispredict_i),
          .ctrlSMTid_i(ctrlSMTid_i),

          .outPacket_o(exePacket0_o),
          .outValid_o(exePacketValid0_o)
	);

/* Following instantiates FU1: complex ALU
*/
 FU1 fu1( .clk(clk),
          .reset(reset),

          .inPacket_i(fuPacket1_i),
	  .fuFinalData1_i(fu1FinalData1),
	  .fuFinalData2_i(fu1FinalData2),
          .inValid_i(fuPacketValid1_i),

          .ctrlVerified_i(ctrlVerified_i),
          .ctrlMispredict_i(ctrlMispredict_i),
          .ctrlSMTid_i(ctrlSMTid_i),

          .outPacket_o(exePacket1_o),
          .outValid_o(exePacketValid1_o)
	);

/* Following instantiates FU2: control unit 
*/
 FU2 fu2( .clk(clk),
          .reset(reset),

          .inPacket_i(fuPacket2_i),
	  .fuFinalData1_i(fu2FinalData1),
	  .fuFinalData2_i(fu2FinalData2),
          .inValid_i(fuPacketValid2_i),

          .ctrlVerified_i(ctrlVerified_i),
          .ctrlMispredict_i(ctrlMispredict_i),
          .ctrlSMTid_i(ctrlSMTid_i),

          .outPacket_o(exePacket2_o),
          .outValid_o(exePacketValid2_o)
	);

/* Following instantiates FU3: address generation unit
*/
 FU3 fu3( .clk(clk),
          .reset(reset),

          .inPacket_i(fuPacket3_i),
	  .fuFinalData1_i(fu3FinalData1),
	  .fuFinalData2_i(fu3FinalData2),
          .inValid_i(fuPacketValid3_i),

          .ctrlVerified_i(ctrlVerified_i),
          .ctrlMispredict_i(ctrlMispredict_i),
          .ctrlSMTid_i(ctrlSMTid_i),

          .outPacket_o(exePacket3_o),
          .outValid_o(exePacketValid3_o)
	);

/* Following checks for any data forwarding required for the incoming 
   functional unit packet.
   Destination register of each bypassed packet is compared with source
   registers of each FU packet. If there is a match then bypassed
   data is forwarded to the corresponding functional unit.
*/

/* Extracts tag and data from bypass path for forward checking logic. */
assign bypassTag0  = bypassPacket0_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:`SIZE_DATA+`CHECKPOINTS_LOG+1];
assign bypassData0 = bypassPacket0_i[`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1];
assign bypassTag1  = bypassPacket1_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:`SIZE_DATA+`CHECKPOINTS_LOG+1];
assign bypassData1 = bypassPacket1_i[`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1];
assign bypassTag2  = bypassPacket2_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:`SIZE_DATA+`CHECKPOINTS_LOG+1];
assign bypassData2 = bypassPacket2_i[`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1];
assign bypassTag3  = bypassPacket3_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:`SIZE_DATA+`CHECKPOINTS_LOG+1];
assign bypassData3 = bypassPacket3_i[`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1];

always @(*)
begin:FORWARD_CHECK_FU0
 fu0reg1   = fuPacket0_i[`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:
			 `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];
 fu0data1  = fuPacket0_i[`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+
			 `CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];

 fu0reg2   = fuPacket0_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+
			 `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_DATA+
			 `SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];
 fu0data2  = fuPacket0_i[2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+
			 `CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+
			 `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];
end

 ForwardCheck fu0_srcReg1 (.srcReg_i(fu0reg1),
                           .srcData_i(fu0data1),
                           .bypassValid0_i(bypassValid0_i),
                           .bypassTag0_i(bypassTag0),
                           .bypassData0_i(bypassData0),
                           .bypassValid1_i(bypassValid1_i),
                           .bypassTag1_i(bypassTag1),
                           .bypassData1_i(bypassData1),
                           .bypassValid2_i(bypassValid2_i),
                           .bypassTag2_i(bypassTag2),
                           .bypassData2_i(bypassData2),
                           .bypassValid3_i(bypassValid3_i),
                           .bypassTag3_i(bypassTag3),
                           .bypassData3_i(bypassData3),
                           .dataOut_o(fu0FinalData1)
                          );

 ForwardCheck fu0_srcReg2 (.srcReg_i(fu0reg2),
                           .srcData_i(fu0data2),
                           .bypassValid0_i(bypassValid0_i),
                           .bypassTag0_i(bypassTag0),
                           .bypassData0_i(bypassData0),
                           .bypassValid1_i(bypassValid1_i),
                           .bypassTag1_i(bypassTag1),
                           .bypassData1_i(bypassData1),
                           .bypassValid2_i(bypassValid2_i),
                           .bypassTag2_i(bypassTag2),
                           .bypassData2_i(bypassData2),
                           .bypassValid3_i(bypassValid3_i),
                           .bypassTag3_i(bypassTag3),
                           .bypassData3_i(bypassData3),

                           .dataOut_o(fu0FinalData2)
                          );

always @(*)
begin:FORWARD_CHECK_FU1
 fu1reg1   = fuPacket1_i[`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:
			 `SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];
 fu1data1  = fuPacket1_i[`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+
			 `CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];

 fu1reg2   = fuPacket1_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+
			 `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_DATA+
			 `SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];
 fu1data2  = fuPacket1_i[2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+
                         `CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+
                         `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];
end

 ForwardCheck fu1_srcReg1 (.srcReg_i(fu1reg1),
                           .srcData_i(fu1data1),
                           .bypassValid0_i(bypassValid0_i),
                           .bypassTag0_i(bypassTag0),
                           .bypassData0_i(bypassData0),
                           .bypassValid1_i(bypassValid1_i),
                           .bypassTag1_i(bypassTag1),
                           .bypassData1_i(bypassData1),
                           .bypassValid2_i(bypassValid2_i),
                           .bypassTag2_i(bypassTag2),
                           .bypassData2_i(bypassData2),
                           .bypassValid3_i(bypassValid3_i),
                           .bypassTag3_i(bypassTag3),
                           .bypassData3_i(bypassData3),
                           .dataOut_o(fu1FinalData1)
                          );

 ForwardCheck fu1_srcReg2 (.srcReg_i(fu1reg2),
                           .srcData_i(fu1data2),
                           .bypassValid0_i(bypassValid0_i),
                           .bypassTag0_i(bypassTag0),
                           .bypassData0_i(bypassData0),
                           .bypassValid1_i(bypassValid1_i),
                           .bypassTag1_i(bypassTag1),
                           .bypassData1_i(bypassData1),
                           .bypassValid2_i(bypassValid2_i),
                           .bypassTag2_i(bypassTag2),
                           .bypassData2_i(bypassData2),
                           .bypassValid3_i(bypassValid3_i),
                           .bypassTag3_i(bypassTag3),
                           .bypassData3_i(bypassData3),
                           .dataOut_o(fu1FinalData2)
                          );

always @(*)
begin:FORWARD_CHECK_FU2
 fu2reg1   = fuPacket2_i[2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+
			 `SIZE_CTI_LOG+`SIZE_PC:`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+
			 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
 fu2data1  = fuPacket2_i[`SIZE_DATA+2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+
			 `SIZE_CTI_LOG+`SIZE_PC:2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS+
			 `CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];

 fu2reg2   = fuPacket2_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
			 `SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
			 `SIZE_DATA+2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+
			 `CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
 fu2data2  = fuPacket2_i[2*(`SIZE_DATA+`SIZE_PHYSICAL_LOG)+`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
			 `SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC:
			 `SIZE_PHYSICAL_LOG+`SIZE_DATA+2*`SIZE_PHYSICAL_LOG+`SIZE_ACTIVELIST_LOG+
			 `SIZE_ISSUEQ_LOG+`CHECKPOINTS+`CHECKPOINTS_LOG+`SIZE_CTI_LOG+`SIZE_PC+1];
end


 ForwardCheck fu2_srcReg1 (.srcReg_i(fu2reg1),
                           .srcData_i(fu2data1),
                           .bypassValid0_i(bypassValid0_i),
                           .bypassTag0_i(bypassTag0),
                           .bypassData0_i(bypassData0),
                           .bypassValid1_i(bypassValid1_i),
                           .bypassTag1_i(bypassTag1),
                           .bypassData1_i(bypassData1),
                           .bypassValid2_i(bypassValid2_i),
                           .bypassTag2_i(bypassTag2),
                           .bypassData2_i(bypassData2),
                           .bypassValid3_i(bypassValid3_i),
                           .bypassTag3_i(bypassTag3),
                           .bypassData3_i(bypassData3),
                           .dataOut_o(fu2FinalData1)
                          );

 ForwardCheck fu2_srcReg2 (.srcReg_i(fu2reg2),
                           .srcData_i(fu2data2),
                           .bypassValid0_i(bypassValid0_i),
                           .bypassTag0_i(bypassTag0),
                           .bypassData0_i(bypassData0),
                           .bypassValid1_i(bypassValid1_i),
                           .bypassTag1_i(bypassTag1),
                           .bypassData1_i(bypassData1),
                           .bypassValid2_i(bypassValid2_i),
                           .bypassTag2_i(bypassTag2),
                           .bypassData2_i(bypassData2),
                           .bypassValid3_i(bypassValid3_i),
                           .bypassTag3_i(bypassTag3),
                           .bypassData3_i(bypassData3),
                           .dataOut_o(fu2FinalData2)
                          );

always @(*)
begin:FORWARD_CHECK_FU3
 fu3reg1   = fuPacket3_i[`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+
			 `CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];
 fu3data1  = fuPacket3_i[`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+
			 `CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];

 fu3reg2   = fuPacket3_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+
			 `SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:
			 `SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
			 `SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS];
 fu3data2  = fuPacket3_i[`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+
			 `SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`SIZE_ISSUEQ_LOG+`CHECKPOINTS-1:`SIZE_PHYSICAL_LOG+
			 `SIZE_DATA+`SIZE_PHYSICAL_LOG+`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+
			 `SIZE_ISSUEQ_LOG+`CHECKPOINTS];
end

 ForwardCheck fu3_srcReg1 (.srcReg_i(fu3reg1),
                           .srcData_i(fu3data1),
                           .bypassValid0_i(bypassValid0_i),
                           .bypassTag0_i(bypassTag0),
                           .bypassData0_i(bypassData0),
                           .bypassValid1_i(bypassValid1_i),
                           .bypassTag1_i(bypassTag1),
                           .bypassData1_i(bypassData1),
                           .bypassValid2_i(bypassValid2_i),
                           .bypassTag2_i(bypassTag2),
                           .bypassData2_i(bypassData2),
                           .bypassValid3_i(bypassValid3_i),
                           .bypassTag3_i(bypassTag3),
                           .bypassData3_i(bypassData3),
                           .dataOut_o(fu3FinalData1)
                          );

 ForwardCheck fu3_srcReg2 (.srcReg_i(fu3reg2),
                           .srcData_i(fu3data2),
                           .bypassValid0_i(bypassValid0_i),
                           .bypassTag0_i(bypassTag0),
                           .bypassData0_i(bypassData0),
                           .bypassValid1_i(bypassValid1_i),
                           .bypassTag1_i(bypassTag1),
                           .bypassData1_i(bypassData1),
                           .bypassValid2_i(bypassValid2_i),
                           .bypassTag2_i(bypassTag2),
                           .bypassData2_i(bypassData2),
                           .bypassValid3_i(bypassValid3_i),
                           .bypassTag3_i(bypassTag3),
                           .bypassData3_i(bypassData3),
                           .dataOut_o(fu3FinalData2)
                          );

endmodule
