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
# Purpose: 32:1 select tree made out of 8:1 select blocks.
# Author:  FabGen
*******************************************************************************/

`timescale 1ns/100ps


module Select(input wire clk,
	input wire reset,
	input wire [`SIZE_ISSUEQ-1:0] requestVector_i,
	input wire grant_i,									/* Enable signal for the select tree */

	output wire grantedValid_o,
	output wire [`SIZE_ISSUEQ_LOG-1:0] grantedEntry_o,	/* Encoded form of grantedVector_o */
	output wire [`SIZE_ISSUEQ-1:0] grantedVector_o	 	/* One-hot grant vector */
);

/* Wires and regs for the combinational logic */
/* Wires for outputs */
wire [`SIZE_ISSUEQ-1:0] grantedVector;
wire [`SIZE_ISSUEQ_LOG-1:0] grantedEntry;

/* reqOut signals propagating forwards from the back of the select tree to the front */
wire reqOut_u0_0;
wire reqOut_u0_1;
wire reqOut_u0_2;
wire reqOut_u0_3;

wire reqOut_u1_0;

/* grantIn signals propagating backwards from the front of the select tree */
wire grantIn_u0_0;
wire grantIn_u0_1;
wire grantIn_u0_2;
wire grantIn_u0_3;

wire grantIn_u1_0;

/* Assign enable signal */
assign grantIn_u1_0 = grant_i | 1'b1; // <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< TEMPORARY FIX 

/* Assign outputs */
assign grantedValid_o = reqOut_u1_0;
assign grantedVector_o = grantedVector;
assign grantedEntry_o = grantedEntry;

integer i;

/* Instantiate the encoder */
Encoder #(`SIZE_ISSUEQ, `SIZE_ISSUEQ_LOG) grantEncoder(.vector_i(grantedVector),
	.encoded_o(grantedEntry)
);

/******************************************
* Stage 0 (deals with 32 -> 4 conversion) *
******************************************/

/* Stage 0, select block 0 */
selectBlock_8 U0_0(.req0_i(requestVector_i[0]),
	.req1_i(requestVector_i[1]),
	.req2_i(requestVector_i[2]),
	.req3_i(requestVector_i[3]),
	.req4_i(requestVector_i[4]),
	.req5_i(requestVector_i[5]),
	.req6_i(requestVector_i[6]),
	.req7_i(requestVector_i[7]),
	.grant_i(grantIn_u0_0),
	.grant0_o(grantedVector[0]),
	.grant1_o(grantedVector[1]),
	.grant2_o(grantedVector[2]),
	.grant3_o(grantedVector[3]),
	.grant4_o(grantedVector[4]),
	.grant5_o(grantedVector[5]),
	.grant6_o(grantedVector[6]),
	.grant7_o(grantedVector[7]),
	.req_o(reqOut_u0_0)
);

/* Stage 0, select block 1 */
selectBlock_8 U0_1(.req0_i(requestVector_i[8]),
	.req1_i(requestVector_i[9]),
	.req2_i(requestVector_i[10]),
	.req3_i(requestVector_i[11]),
	.req4_i(requestVector_i[12]),
	.req5_i(requestVector_i[13]),
	.req6_i(requestVector_i[14]),
	.req7_i(requestVector_i[15]),
	.grant_i(grantIn_u0_1),
	.grant0_o(grantedVector[8]),
	.grant1_o(grantedVector[9]),
	.grant2_o(grantedVector[10]),
	.grant3_o(grantedVector[11]),
	.grant4_o(grantedVector[12]),
	.grant5_o(grantedVector[13]),
	.grant6_o(grantedVector[14]),
	.grant7_o(grantedVector[15]),
	.req_o(reqOut_u0_1)
);

/* Stage 0, select block 2 */
selectBlock_8 U0_2(.req0_i(requestVector_i[16]),
	.req1_i(requestVector_i[17]),
	.req2_i(requestVector_i[18]),
	.req3_i(requestVector_i[19]),
	.req4_i(requestVector_i[20]),
	.req5_i(requestVector_i[21]),
	.req6_i(requestVector_i[22]),
	.req7_i(requestVector_i[23]),
	.grant_i(grantIn_u0_2),
	.grant0_o(grantedVector[16]),
	.grant1_o(grantedVector[17]),
	.grant2_o(grantedVector[18]),
	.grant3_o(grantedVector[19]),
	.grant4_o(grantedVector[20]),
	.grant5_o(grantedVector[21]),
	.grant6_o(grantedVector[22]),
	.grant7_o(grantedVector[23]),
	.req_o(reqOut_u0_2)
);

/* Stage 0, select block 3 */
selectBlock_8 U0_3(.req0_i(requestVector_i[24]),
	.req1_i(requestVector_i[25]),
	.req2_i(requestVector_i[26]),
	.req3_i(requestVector_i[27]),
	.req4_i(requestVector_i[28]),
	.req5_i(requestVector_i[29]),
	.req6_i(requestVector_i[30]),
	.req7_i(requestVector_i[31]),
	.grant_i(grantIn_u0_3),
	.grant0_o(grantedVector[24]),
	.grant1_o(grantedVector[25]),
	.grant2_o(grantedVector[26]),
	.grant3_o(grantedVector[27]),
	.grant4_o(grantedVector[28]),
	.grant5_o(grantedVector[29]),
	.grant6_o(grantedVector[30]),
	.grant7_o(grantedVector[31]),
	.req_o(reqOut_u0_3)
);


/******************************************
* Stage 1 (deals with 4 -> 1 conversion) *
******************************************/

/* Stage 1, select block 0 */
selectBlock_4 U1_0(.req0_i(reqOut_u0_0),
	.req1_i(reqOut_u0_1),
	.req2_i(reqOut_u0_2),
	.req3_i(reqOut_u0_3),
	.grant_i(grantIn_u1_0),
	.grant0_o(grantIn_u0_0),
	.grant1_o(grantIn_u0_1),
	.grant2_o(grantIn_u0_2),
	.grant3_o(grantIn_u0_3),
	.req_o(reqOut_u1_0)
);

endmodule


module selectBlock_8(
	input wire req0_i,
	input wire req1_i,
	input wire req2_i,
	input wire req3_i,
	input wire req4_i,
	input wire req5_i,
	input wire req6_i,
	input wire req7_i,

	/* The grant signal coming in from the next stage of the select tree */
	input wire grant_i,

	output wire grant0_o,
	output wire grant1_o,
	output wire grant2_o,
	output wire grant3_o,
	output wire grant4_o,
	output wire grant5_o,
	output wire grant6_o,
	output wire grant7_o,

	/* OR of the request signals, used as req_i for next stage of the select tree */
	output wire req_o
);

/* Wires and registers for combinatinal logic */
wire [7:0] req;
wire [7:0] grant;

/* Code to deal with vectors instead of individual wires */
assign req = {req7_i, req6_i, req5_i, req4_i, req3_i, req2_i, req1_i, req0_i};

/* Gate the current grant output with the grant_i from the next stage of the select tree */
assign grant0_o = grant[0] & grant_i;
assign grant1_o = grant[1] & grant_i;
assign grant2_o = grant[2] & grant_i;
assign grant3_o = grant[3] & grant_i;
assign grant4_o = grant[4] & grant_i;
assign grant5_o = grant[5] & grant_i;
assign grant6_o = grant[6] & grant_i;
assign grant7_o = grant[7] & grant_i;

/* Create the OR gate */
assign req_o = |req;

/* Create the priority logic */
PriorityEncoder #(8) selectBlockPEncoder(
	.vector_i(req),
	.vector_o(grant)
);

endmodule


module selectBlock_4(
	input wire req0_i,
	input wire req1_i,
	input wire req2_i,
	input wire req3_i,

	/* The grant signal coming in from the next stage of the select tree */
	input wire grant_i,

	output wire grant0_o,
	output wire grant1_o,
	output wire grant2_o,
	output wire grant3_o,

	/* OR of the request signals, used as req_i for next stage of the select tree */
	output wire req_o
);

/* Wires and registers for combinatinal logic */
wire [3:0] req;
wire [3:0] grant;

/* Code to deal with vectors instead of individual wires */
assign req = {req3_i, req2_i, req1_i, req0_i};

/* Gate the current grant output with the grant_i from the next stage of the select tree */
assign grant0_o = grant[0] & grant_i;
assign grant1_o = grant[1] & grant_i;
assign grant2_o = grant[2] & grant_i;
assign grant3_o = grant[3] & grant_i;

/* Create the OR gate */
assign req_o = |req;

/* Create the priority logic */
PriorityEncoder #(4) selectBlockPEncoder(
	.vector_i(req),
	.vector_o(grant)
);

endmodule


module Encoder(vector_i,
	encoded_o
);

parameter ENCODER_WIDTH = 32;
parameter ENCODER_WIDTH_LOG = 5;

/* I/O definitions */
input wire [ENCODER_WIDTH-1:0] vector_i;
output wire [ENCODER_WIDTH_LOG-1:0] encoded_o;

/* Temporary regs and wires */
reg [ENCODER_WIDTH_LOG-1:0] s [ENCODER_WIDTH-1:0]; // Stores number itself. 
reg [ENCODER_WIDTH_LOG-1:0] t [ENCODER_WIDTH-1:0]; // Stores (s[i] if vector[i]==1'b1 else stores 0)
reg [ENCODER_WIDTH-1:0] u [ENCODER_WIDTH_LOG-1:0]; // Stores transpose of t (to use the | operator)

/* Wires and regs for combinational logic */
reg [ENCODER_WIDTH-1:0] compareVector;

/* Wires for outputs */
reg [ENCODER_WIDTH_LOG-1:0] encoded;

/* Assign outputs */
assign encoded_o = encoded;

integer i;
integer j;

always @(*)
begin: ENCODER_CONSTRUCT
	for(i=0; i<ENCODER_WIDTH; i=i+1)
	begin
		s[i] = i;
	end

	for(i=0; i<ENCODER_WIDTH; i=i+1)
	begin
		if(vector_i[i] == 1'b1)
			t[i] = s[i];
		else
			t[i] = 0;
	end

	for(i=0; i<ENCODER_WIDTH; i=i+1)
	begin
		for(j=0; j<ENCODER_WIDTH_LOG; j=j+1)
		begin
			u[j][i] = t[i][j];
		end
	end

	for(j=0; j<ENCODER_WIDTH_LOG; j=j+1)
	begin
		encoded[j] = |u[j];
	end
end

endmodule


module PriorityEncoder(vector_i,
	vector_o
);

parameter ENCODER_WIDTH = 32;

/* I/O definitions */
input wire [ENCODER_WIDTH-1:0] vector_i;
output wire [ENCODER_WIDTH-1:0] vector_o;

/* Wires and regs for combinational logic */

/* Mask to reset all other bits except the first */
reg [ENCODER_WIDTH-1:0] mask;

/* Wires for outputs */
wire [ENCODER_WIDTH-1:0] vector;

/* Assign outputs */
assign vector_o = vector;

/* Mask the input vector so that only the first 1'b1 is seen */
assign vector = vector_i & mask;

integer j;

always @(*)
begin: ENCODER_CONSTRUCT
	mask[0] = 1'b1;

	for(j=1; j<ENCODER_WIDTH; j=j+1)
	begin
		if(vector_i[j-1] == 1'b1)
			mask[j] = 0;
		else
			mask[j] = mask[j-1];
	end
end

endmodule


