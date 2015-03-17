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
# Purpose: This block implements the Branch Target Buffer. Fetch Width is 4. 
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps


module BTB(	input [`SIZE_PC-1:0] PC_i,

		/* BTB updates from the Branch Order Buffer. */
		input updateEn_i,
		input [`SIZE_PC-1:0] updatePC_i,
		input [`SIZE_PC-1:0] updateTargetAddr_i,
		input [`BRANCH_TYPE-1:0] updateBrType_i,

		input btbFlush_i,
		input stall_i,
		input clk,
		input reset,

		output btbHit0_o,
		output [`SIZE_PC-1:0] targetAddr0_o,
		output [`BRANCH_TYPE-1:0] ctrlType0_o,

		output btbHit1_o,
		output [`SIZE_PC-1:0] targetAddr1_o,
		output [`BRANCH_TYPE-1:0] ctrlType1_o,

		output btbHit2_o,
		output [`SIZE_PC-1:0] targetAddr2_o,
		output [`BRANCH_TYPE-1:0] ctrlType2_o,

		output btbHit3_o,
		output [`SIZE_PC-1:0] targetAddr3_o,
		output [`BRANCH_TYPE-1:0] ctrlType3_o
);


integer i;

wire [`SIZE_PC-1:0] pc0;
wire [`SIZE_PC-1:0] pc1;
wire [`SIZE_PC-1:0] pc2;
wire [`SIZE_PC-1:0] pc3;

reg [`SIZE_PC-1:0] ram_pc0;
reg [`SIZE_PC-1:0] ram_pc1;
reg [`SIZE_PC-1:0] ram_pc2;
reg [`SIZE_PC-1:0] ram_pc3;

wire [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] pctag0;
wire [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] pctag1;
wire [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] pctag2;
wire [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] pctag3;

wire [`SIZE_BTB_LOG-`FETCH_BANDWIDTH_LOG-1:0] btbaddr0;
wire [`SIZE_BTB_LOG-`FETCH_BANDWIDTH_LOG-1:0] btbaddr1;
wire [`SIZE_BTB_LOG-`FETCH_BANDWIDTH_LOG-1:0] btbaddr2;
wire [`SIZE_BTB_LOG-`FETCH_BANDWIDTH_LOG-1:0] btbaddr3;

wire [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] ram_btbtag0;
wire [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] ram_btbtag1;
wire [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] ram_btbtag2;
wire [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] ram_btbtag3;

wire [`SIZE_PC+`BRANCH_TYPE:0] ram_btbdata0;
wire [`SIZE_PC+`BRANCH_TYPE:0] ram_btbdata1;
wire [`SIZE_PC+`BRANCH_TYPE:0] ram_btbdata2;
wire [`SIZE_PC+`BRANCH_TYPE:0] ram_btbdata3;

reg [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] btbtag0;
reg [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] btbtag1;
reg [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] btbtag2;
reg [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] btbtag3;

reg [`SIZE_PC+`BRANCH_TYPE:0] btbdata0;
reg [`SIZE_PC+`BRANCH_TYPE:0] btbdata1;
reg [`SIZE_PC+`BRANCH_TYPE:0] btbdata2;
reg [`SIZE_PC+`BRANCH_TYPE:0] btbdata3;

wire [`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET-1:0] pctagupdate;
wire [`SIZE_BTB_LOG-1-`FETCH_BANDWIDTH_LOG:0] btbaddrupdate;
wire we[4-1:0];


wire btbHit0Btb;
wire [`SIZE_PC-1:0] targetAddr0Btb;
wire [`BRANCH_TYPE-1:0] brType0Btb;

wire btbHit1Btb;
wire [`SIZE_PC-1:0] targetAddr1Btb;
wire [`BRANCH_TYPE-1:0] brType1Btb;

wire btbHit2Btb;
wire [`SIZE_PC-1:0] targetAddr2Btb;
wire [`BRANCH_TYPE-1:0] brType2Btb;

wire btbHit3Btb;
wire [`SIZE_PC-1:0] targetAddr3Btb;
wire [`BRANCH_TYPE-1:0] brType3Btb;



/* Initializing BTB Tag and BTB Data SRAMs. SRAM_4R1W is the Verilog model of RAM
* with required READ and WRITE ports.
*/


SRAM_1R1W #(`SIZE_BTB/4,`SIZE_BTB_LOG-`FETCH_BANDWIDTH_LOG,`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET)
	btbTag0(.addr0_i(btbaddr0),.addrWr_i(btbaddrupdate),.we_i(we[0]),.data_i(pctagupdate),
	.clk(clk),.reset(reset),.data0_o(ram_btbtag0));
SRAM_1R1W #(`SIZE_BTB/4,`SIZE_BTB_LOG-`FETCH_BANDWIDTH_LOG,`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET)
	btbTag1(.addr0_i(btbaddr1),.addrWr_i(btbaddrupdate),.we_i(we[1]),.data_i(pctagupdate),
	.clk(clk),.reset(reset),.data0_o(ram_btbtag1));
SRAM_1R1W #(`SIZE_BTB/4,`SIZE_BTB_LOG-`FETCH_BANDWIDTH_LOG,`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET)
	btbTag2(.addr0_i(btbaddr2),.addrWr_i(btbaddrupdate),.we_i(we[2]),.data_i(pctagupdate),
	.clk(clk),.reset(reset),.data0_o(ram_btbtag2));
SRAM_1R1W #(`SIZE_BTB/4,`SIZE_BTB_LOG-`FETCH_BANDWIDTH_LOG,`SIZE_PC-`SIZE_BTB_LOG-`SIZE_BYTE_OFFSET)
	btbTag3(.addr0_i(btbaddr3),.addrWr_i(btbaddrupdate),.we_i(we[3]),.data_i(pctagupdate),
	.clk(clk),.reset(reset),.data0_o(ram_btbtag3));

SRAM_1R1W #(`SIZE_BTB/4,`SIZE_BTB_LOG-`FETCH_BANDWIDTH_LOG,`SIZE_PC+`BRANCH_TYPE+1)
	btbData0(.addr0_i(btbaddr0),.addrWr_i(btbaddrupdate),.we_i(we[0]),.data_i({updateTargetAddr_i,updateBrType_i,1'b1}),
	.clk(clk),.reset(reset),.data0_o(ram_btbdata0));
SRAM_1R1W #(`SIZE_BTB/4,`SIZE_BTB_LOG-`FETCH_BANDWIDTH_LOG,`SIZE_PC+`BRANCH_TYPE+1)
	btbData1(.addr0_i(btbaddr1),.addrWr_i(btbaddrupdate),.we_i(we[1]),.data_i({updateTargetAddr_i,updateBrType_i,1'b1}),
	.clk(clk),.reset(reset),.data0_o(ram_btbdata1));
SRAM_1R1W #(`SIZE_BTB/4,`SIZE_BTB_LOG-`FETCH_BANDWIDTH_LOG,`SIZE_PC+`BRANCH_TYPE+1)
	btbData2(.addr0_i(btbaddr2),.addrWr_i(btbaddrupdate),.we_i(we[2]),.data_i({updateTargetAddr_i,updateBrType_i,1'b1}),
	.clk(clk),.reset(reset),.data0_o(ram_btbdata2));
SRAM_1R1W #(`SIZE_BTB/4,`SIZE_BTB_LOG-`FETCH_BANDWIDTH_LOG,`SIZE_PC+`BRANCH_TYPE+1)
	btbData3(.addr0_i(btbaddr3),.addrWr_i(btbaddrupdate),.we_i(we[3]),.data_i({updateTargetAddr_i,updateBrType_i,1'b1}),
	.clk(clk),.reset(reset),.data0_o(ram_btbdata3));
		
		
/* Creating addresses for the Program Counter to be used by the BTB. 
*/ 
assign pc0     = PC_i + 0;
assign pc1     = PC_i + 8;
assign pc2     = PC_i + 16;
assign pc3     = PC_i + 24;
		
		
/* Rotate the addresses to the correct SRAM
*/
always@(*)
begin
	case(PC_i[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET])
	2'd0:
	begin
		ram_pc0 = pc0;
		ram_pc1 = pc1;
		ram_pc2 = pc2;
		ram_pc3 = pc3;
	end
	2'd1:
	begin
		ram_pc0 = pc3;
		ram_pc1 = pc0;
		ram_pc2 = pc1;
		ram_pc3 = pc2;
	end
	2'd2:
	begin
		ram_pc0 = pc2;
		ram_pc1 = pc3;
		ram_pc2 = pc0;
		ram_pc3 = pc1;
	end
	2'd3:
	begin
		ram_pc0 = pc1;
		ram_pc1 = pc2;
		ram_pc2 = pc3;
		ram_pc3 = pc0;
	end
	endcase
end
		
		
/* Extracting Tag and Index bits from the Program Counter for the BTB Tag
comparision and Indexing. */ 
assign pctag0	= pc0[`SIZE_PC-1:`SIZE_BTB_LOG+`SIZE_BYTE_OFFSET];
assign btbaddr0	= ram_pc0[`SIZE_BTB_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET+`FETCH_BANDWIDTH_LOG];

assign pctag1	= pc1[`SIZE_PC-1:`SIZE_BTB_LOG+`SIZE_BYTE_OFFSET];
assign btbaddr1	= ram_pc1[`SIZE_BTB_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET+`FETCH_BANDWIDTH_LOG];

assign pctag2	= pc2[`SIZE_PC-1:`SIZE_BTB_LOG+`SIZE_BYTE_OFFSET];
assign btbaddr2	= ram_pc2[`SIZE_BTB_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET+`FETCH_BANDWIDTH_LOG];

assign pctag3	= pc3[`SIZE_PC-1:`SIZE_BTB_LOG+`SIZE_BYTE_OFFSET];
assign btbaddr3	= ram_pc3[`SIZE_BTB_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET+`FETCH_BANDWIDTH_LOG];

/* Re-Rotate the from the SRAM output to the correct order
*/
always@(*)
begin
	btbtag0		= 0;
	btbtag1		= 0;
	btbtag2		= 0;
	btbtag3		= 0;
	btbdata0	= 0;
	btbdata1	= 0;
	btbdata2	= 0;
	btbdata3	= 0;
	case(PC_i[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET])
	2'd0:
	begin
		btbtag0		= ram_btbtag0;
		btbtag1		= ram_btbtag1;
		btbtag2		= ram_btbtag2;
		btbtag3		= ram_btbtag3;
		btbdata0	= ram_btbdata0;
		btbdata1	= ram_btbdata1;
		btbdata2	= ram_btbdata2;
		btbdata3	= ram_btbdata3;
	end
	2'd1:
	begin
		btbtag0		= ram_btbtag1;
		btbtag1		= ram_btbtag2;
		btbtag2		= ram_btbtag3;
		btbtag3		= ram_btbtag0;
		btbdata0	= ram_btbdata1;
		btbdata1	= ram_btbdata2;
		btbdata2	= ram_btbdata3;
		btbdata3	= ram_btbdata0;
	end
	2'd2:
	begin
		btbtag0		= ram_btbtag2;
		btbtag1		= ram_btbtag3;
		btbtag2		= ram_btbtag0;
		btbtag3		= ram_btbtag1;
		btbdata0	= ram_btbdata2;
		btbdata1	= ram_btbdata3;
		btbdata2	= ram_btbdata0;
		btbdata3	= ram_btbdata1;
	end
	2'd3:
	begin
		btbtag0		= ram_btbtag3;
		btbtag1		= ram_btbtag0;
		btbtag2		= ram_btbtag1;
		btbtag3		= ram_btbtag2;
		btbdata0	= ram_btbdata3;
		btbdata1	= ram_btbdata0;
		btbdata2	= ram_btbdata1;
		btbdata3	= ram_btbdata2;
	end
	endcase
end
/* Following checks for BTB Hit for PC0 and if there is a hit then reads the BTB
* data for Target Address and Branch Type.
*/
assign btbHit0Btb	= (btbdata0[0] && (pctag0 == btbtag0)) ? 1'b1:0;
assign targetAddr0Btb	= btbdata0[`SIZE_PC+`BRANCH_TYPE:`BRANCH_TYPE+1];
assign brType0Btb	= btbdata0[`BRANCH_TYPE:1];

assign btbHit0_o	= btbHit0Btb;
assign targetAddr0_o	= targetAddr0Btb;
assign ctrlType0_o	= brType0Btb;


/* Following checks for BTB Hit for PC1 and if there is a hit then reads the BTB
* data for Target Address and Branch Type.
*/
assign btbHit1Btb	= (btbdata1[0] && (pctag1 == btbtag1)) ? 1'b1:0;
assign targetAddr1Btb	= btbdata1[`SIZE_PC+`BRANCH_TYPE:`BRANCH_TYPE+1];
assign brType1Btb	= btbdata1[`BRANCH_TYPE:1];

assign btbHit1_o	= btbHit1Btb;
assign targetAddr1_o	= targetAddr1Btb;
assign ctrlType1_o	= brType1Btb;


/* Following checks for BTB Hit for PC2 and if there is a hit then reads the BTB
* data for Target Address and Branch Type.
*/
assign btbHit2Btb	= (btbdata2[0] && (pctag2 == btbtag2)) ? 1'b1:0;
assign targetAddr2Btb	= btbdata2[`SIZE_PC+`BRANCH_TYPE:`BRANCH_TYPE+1];
assign brType2Btb	= btbdata2[`BRANCH_TYPE:1];

assign btbHit2_o	= btbHit2Btb;
assign targetAddr2_o	= targetAddr2Btb;
assign ctrlType2_o	= brType2Btb;


/* Following checks for BTB Hit for PC3 and if there is a hit then reads the BTB
* data for Target Address and Branch Type.
*/
assign btbHit3Btb	= (btbdata3[0] && (pctag3 == btbtag3)) ? 1'b1:0;
assign targetAddr3Btb	= btbdata3[`SIZE_PC+`BRANCH_TYPE:`BRANCH_TYPE+1];
assign brType3Btb	= btbdata3[`BRANCH_TYPE:1];

assign btbHit3_o	= btbHit3Btb;
assign targetAddr3_o	= targetAddr3Btb;
assign ctrlType3_o	= brType3Btb;


		
		
/* Following updates the BTB if the prediction made by BTB was wrong or
* if BTB never saw this Control Instruction PC in past. The update comes 
* from Ctrl Queue in the program order. 
*/
		
assign pctagupdate   	= updatePC_i[`SIZE_PC-1:`SIZE_BTB_LOG+`SIZE_BYTE_OFFSET];
assign btbaddrupdate 	= updatePC_i[`SIZE_BTB_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET+`FETCH_BANDWIDTH_LOG];
		
assign we[0] = updateEn_i && (updatePC_i[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET] == 2'd0);
assign we[1] = updateEn_i && (updatePC_i[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET] == 2'd1);
assign we[2] = updateEn_i && (updatePC_i[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET] == 2'd2);
assign we[3] = updateEn_i && (updatePC_i[`FETCH_BANDWIDTH_LOG+`SIZE_BYTE_OFFSET-1:`SIZE_BYTE_OFFSET] == 2'd3);
		
endmodule
