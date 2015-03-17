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

/***************************************************************************

  Assumption:  4-instructions can be issued and 
  4(?)-instructions will retire in one cycle from Active List.
	
There are 4 ways and upto 4 issue queue entries
can be freed in a clock cycle.

***************************************************************************/

module IssueQFreeList(
	input clk,
	input reset,

	/* control execution flags from the Writeback Stage. If 
	* ctrlMispredict_i is 1, there has been a mis-predict. */
	input ctrlVerified_i,                    
	input ctrlMispredict_i,
	input [`SIZE_ISSUEQ-1:0] mispredictVector_i,

	input backEndReady_i,

	/* 4 entries being freed once they have been issued. */
	input [`SIZE_ISSUEQ_LOG-1:0] grantedEntry0_i,
	input [`SIZE_ISSUEQ_LOG-1:0] grantedEntry1_i,
	input [`SIZE_ISSUEQ_LOG-1:0] grantedEntry2_i,
	input [`SIZE_ISSUEQ_LOG-1:0] grantedEntry3_i,

	input grantedValid0_i,
	input grantedValid1_i,
	input grantedValid2_i,
	input grantedValid3_i,

	output [`SIZE_ISSUEQ_LOG-1:0] freedEntry0_o,
	output [`SIZE_ISSUEQ_LOG-1:0] freedEntry1_o,
	output [`SIZE_ISSUEQ_LOG-1:0] freedEntry2_o,
	output [`SIZE_ISSUEQ_LOG-1:0] freedEntry3_o,

	output freedValid0_o,
	output freedValid1_o,
	output freedValid2_o,
	output freedValid3_o,

	/* 4 free Issue Queue entries for the new coming 
	* instructions. */
	output [`SIZE_ISSUEQ_LOG-1:0] freeEntry0_o,
	output [`SIZE_ISSUEQ_LOG-1:0] freeEntry1_o,
	output [`SIZE_ISSUEQ_LOG-1:0] freeEntry2_o,
	output [`SIZE_ISSUEQ_LOG-1:0] freeEntry3_o,

/* Count of Valid Issue Q Entries goes to Dispatch */
	output [`SIZE_ISSUEQ_LOG:0] cntInstIssueQ_o
);

/***************************************************************************/
/* Instantiating SPEC FREE LIST Table & head/tail pointers */
reg [`SIZE_ISSUEQ_LOG-1:0] ISSUEQ_FREELIST [`SIZE_ISSUEQ-1:0];
reg [`SIZE_ISSUEQ_LOG-1:0] headPtr;
reg [`SIZE_ISSUEQ_LOG-1:0] tailPtr;

reg [`SIZE_ISSUEQ_LOG:0] issueQCount;	

/* Declaring wires and regs for Combinational Logic */
reg [`SIZE_ISSUEQ_LOG:0] issueQCount_f;
reg [`SIZE_ISSUEQ_LOG-1:0] headptr_f;
reg [`SIZE_ISSUEQ_LOG-1:0] tailptr_f;

integer i;

wire [`SIZE_ISSUEQ_LOG-1:0] freedEntry0;
wire [`SIZE_ISSUEQ_LOG-1:0] freedEntry1;
wire [`SIZE_ISSUEQ_LOG-1:0] freedEntry2;
wire [`SIZE_ISSUEQ_LOG-1:0] freedEntry3;

wire freedValid0;
wire freedValid1;
wire freedValid2;
wire freedValid3;

wire [`SIZE_ISSUEQ_LOG-1:0] wr_index0;
wire [`SIZE_ISSUEQ_LOG-1:0] wr_index1;
wire [`SIZE_ISSUEQ_LOG-1:0] wr_index2;
wire [`SIZE_ISSUEQ_LOG-1:0] wr_index3;

reg [`SIZE_ISSUEQ_LOG-1:0] rd_index0;
reg [`SIZE_ISSUEQ_LOG-1:0] rd_index1;
reg [`SIZE_ISSUEQ_LOG-1:0] rd_index2;
reg [`SIZE_ISSUEQ_LOG-1:0] rd_index3;


assign freedValid0_o = freedValid0;
assign freedValid1_o = freedValid1;
assign freedValid2_o = freedValid2;
assign freedValid3_o = freedValid3;

assign freedEntry0_o = freedEntry0;
assign freedEntry1_o = freedEntry1;
assign freedEntry2_o = freedEntry2;
assign freedEntry3_o = freedEntry3;

/* Sending Issue Queue occupied entries to Dispatch. */
assign cntInstIssueQ_o 	= issueQCount;

/* Pops 4 free Issue Queue entries from the FREE LIST for the new coming
* instructions. */
assign freeEntry0_o = ISSUEQ_FREELIST[rd_index0];
assign freeEntry1_o = ISSUEQ_FREELIST[rd_index1];
assign freeEntry2_o = ISSUEQ_FREELIST[rd_index2];
assign freeEntry3_o = ISSUEQ_FREELIST[rd_index3];

/* Generates read addresses for the FREELIST FIFO, using head pointer. */
always @(*)
begin
	rd_index0 = headPtr + 0;
	rd_index1 = headPtr + 1;
	rd_index2 = headPtr + 2;
	rd_index3 = headPtr + 3;
end
always @(*)
begin: ISSUEQ_COUNT
	reg isWrap1;
	reg [`SIZE_ISSUEQ_LOG:0] diff1;
	reg [`SIZE_ISSUEQ_LOG:0] diff2;
	reg [`ISSUE_WIDTH-1:0] totalFreed;

	headptr_f = (backEndReady_i) ? (headPtr+`DISPATCH_WIDTH) : headPtr;
	tailptr_f = (tailPtr + (freedValid3 + freedValid2 + freedValid1 + freedValid0));
	totalFreed = (freedValid3 + freedValid2 + freedValid1 + freedValid0);
	issueQCount_f = (issueQCount+ ((backEndReady_i) ? `DISPATCH_WIDTH:0)) - totalFreed;
end

/* Following updates the Free List Head Pointer, only if there is no control
* mispredict. */
always @(posedge clk)
begin
	if(reset)
	begin
		headPtr <= 0;
	end
	else
	begin
		if(~ctrlMispredict_i)
			headPtr <= headptr_f;
	end
end


/* Follwoing maintains the issue queue occupancy count each cycle. */
always @(posedge clk)
begin
	if(reset)
	begin
		issueQCount <= 0;
	end
	else
	begin
		issueQCount <= issueQCount_f;
	end
end

/* Following updates the FREE LIST counter and pushes the freed Issue 
*  Queue entry into the FREE LIST. */
assign wr_index0 = tailPtr + 0;
assign wr_index1 = tailPtr + 1;
assign wr_index2 = tailPtr + 2;
assign wr_index3 = tailPtr + 3;

always @(posedge clk)
begin: WRITE_FREELIST
	if(reset)
	begin
		for (i=0;i<`SIZE_ISSUEQ;i=i+1)
			ISSUEQ_FREELIST[i] <= i;

		tailPtr <= 0;
	end
	else
	begin
		tailPtr	<= tailptr_f;		

		case({freedValid3, freedValid2, freedValid1, freedValid0})
			4'b0001:
			begin
				ISSUEQ_FREELIST[wr_index0] <= freedEntry0;
			end
			4'b0010:
			begin
				ISSUEQ_FREELIST[wr_index0] <= freedEntry1;
			end
			4'b0011:
			begin
				ISSUEQ_FREELIST[wr_index0] <= freedEntry0;
				ISSUEQ_FREELIST[wr_index1] <= freedEntry1;
			end
			4'b0100:
			begin
				ISSUEQ_FREELIST[wr_index0] <= freedEntry2;
			end
			4'b0101:
			begin
				ISSUEQ_FREELIST[wr_index0] <= freedEntry0;
				ISSUEQ_FREELIST[wr_index1] <= freedEntry2;
			end
			4'b0110:
			begin
				ISSUEQ_FREELIST[wr_index0] <= freedEntry1;
				ISSUEQ_FREELIST[wr_index1] <= freedEntry2;
			end
			4'b0111:
			begin
				ISSUEQ_FREELIST[wr_index0] <= freedEntry0;
				ISSUEQ_FREELIST[wr_index1] <= freedEntry1;
				ISSUEQ_FREELIST[wr_index2] <= freedEntry2;
			end
			4'b1000:
			begin
				ISSUEQ_FREELIST[wr_index0] <= freedEntry3;
			end
			4'b1001:
			begin
				ISSUEQ_FREELIST[wr_index0] <= freedEntry0;
				ISSUEQ_FREELIST[wr_index1] <= freedEntry3;
			end
			4'b1010:
			begin
				ISSUEQ_FREELIST[wr_index0] <= freedEntry1;
				ISSUEQ_FREELIST[wr_index1] <= freedEntry3;
			end
			4'b1011:
			begin
				ISSUEQ_FREELIST[wr_index0] <= freedEntry0;
				ISSUEQ_FREELIST[wr_index1] <= freedEntry1;
				ISSUEQ_FREELIST[wr_index2] <= freedEntry3;
			end
			4'b1100:
			begin
				ISSUEQ_FREELIST[wr_index0] <= freedEntry2;
				ISSUEQ_FREELIST[wr_index1] <= freedEntry3;
			end
			4'b1101:
			begin
				ISSUEQ_FREELIST[wr_index0] <= freedEntry0;
				ISSUEQ_FREELIST[wr_index1] <= freedEntry2;
				ISSUEQ_FREELIST[wr_index2] <= freedEntry3;
			end
			4'b1110:
			begin
				ISSUEQ_FREELIST[wr_index0] <= freedEntry1;
				ISSUEQ_FREELIST[wr_index1] <= freedEntry2;
				ISSUEQ_FREELIST[wr_index2] <= freedEntry3;
			end
			4'b1111:
			begin
				ISSUEQ_FREELIST[wr_index0] <= freedEntry0;
				ISSUEQ_FREELIST[wr_index1] <= freedEntry1;
				ISSUEQ_FREELIST[wr_index2] <= freedEntry2;
				ISSUEQ_FREELIST[wr_index3] <= freedEntry3;
			end
		endcase
	end
end

FreeIssueq freeIq (.clk(clk),
	.reset(reset),
	.ctrlVerified_i(ctrlVerified_i),
	.ctrlMispredict_i(ctrlMispredict_i),
	.mispredictVector_i(mispredictVector_i),
	.grantedEntry0_i(grantedEntry0_i),
	.grantedEntry1_i(grantedEntry1_i),
	.grantedEntry2_i(grantedEntry2_i),
	.grantedEntry3_i(grantedEntry3_i),

	.grantedValid0_i(grantedValid0_i),
	.grantedValid1_i(grantedValid1_i),
	.grantedValid2_i(grantedValid2_i),
	.grantedValid3_i(grantedValid3_i),

	.freedEntry0_o(freedEntry0),
	.freedEntry1_o(freedEntry1),
	.freedEntry2_o(freedEntry2),
	.freedEntry3_o(freedEntry3),

	.freedValid0_o(freedValid0),
	.freedValid1_o(freedValid1),
	.freedValid2_o(freedValid2),
	.freedValid3_o(freedValid3)
);

endmodule

module FreeIssueq (
	input clk,
	input reset,
		    
	/* control execution flags from the Writeback Stage. if
	* ctrlMispredict_i is 1, there has been a mis-predict. */
	input ctrlVerified_i,
	input ctrlMispredict_i,
	
	/* mispredicted vector is set of issue queue entries 
	* invalidated due to branch misprediction. These entries
	* should be inserted into issue queue free list. */
	input [`SIZE_ISSUEQ-1:0] mispredictVector_i,

	/* 4 entries being freed once they have been issued. */
	input [`SIZE_ISSUEQ_LOG-1:0] grantedEntry0_i,
	input [`SIZE_ISSUEQ_LOG-1:0] grantedEntry1_i,
	input [`SIZE_ISSUEQ_LOG-1:0] grantedEntry2_i,
	input [`SIZE_ISSUEQ_LOG-1:0] grantedEntry3_i,

	input grantedValid0_i,
	input grantedValid1_i,
	input grantedValid2_i,
	input grantedValid3_i,

	output [`SIZE_ISSUEQ_LOG-1:0] freedEntry0_o,
	output [`SIZE_ISSUEQ_LOG-1:0] freedEntry1_o,
	output [`SIZE_ISSUEQ_LOG-1:0] freedEntry2_o,
	output [`SIZE_ISSUEQ_LOG-1:0] freedEntry3_o,

	output freedValid0_o,
	output freedValid1_o,
	output freedValid2_o,
	output freedValid3_o
);

reg [`SIZE_ISSUEQ-1:0] freedVector;

/* wires and regs declaration for combinational logic. */
reg [`SIZE_ISSUEQ-1:0] freedVector_t;

wire freeingScalar00;
wire freeingScalar01;
wire freeingScalar02;
wire freeingScalar03;

wire [`SIZE_ISSUEQ_LOG-1:0] freeingCandidate00;
wire [`SIZE_ISSUEQ_LOG-1:0] freeingCandidate01;
wire [`SIZE_ISSUEQ_LOG-1:0] freeingCandidate02;
wire [`SIZE_ISSUEQ_LOG-1:0] freeingCandidate03;

reg [`SIZE_ISSUEQ_LOG-1:0] freedEntry0;
reg [`SIZE_ISSUEQ_LOG-1:0] freedEntry1;
reg [`SIZE_ISSUEQ_LOG-1:0] freedEntry2;
reg [`SIZE_ISSUEQ_LOG-1:0] freedEntry3;

reg freedValid0;
reg freedValid1;
reg freedValid2;
reg freedValid3;

reg [`SIZE_ISSUEQ-1:0] freedVector_t1;

assign freedValid0_o = freedValid0;
assign freedValid1_o = freedValid1;
assign freedValid2_o = freedValid2;
assign freedValid3_o = freedValid3;

assign freedEntry0_o = freedEntry0;
assign freedEntry1_o = freedEntry1;
assign freedEntry2_o = freedEntry2;
assign freedEntry3_o = freedEntry3;

/* Following combinational logic updates the freedValid vector based on:
 *	1. if there are instructions issued this cycle from issue queue 
 *	  (they need to be freed)
 *      2. if there is a branch mispredict this cycle, freedVector need to
 *	   be updated with mispredictVector.
 *	3. if a issue queue entry has been freed this cycle, its corresponding
 *	   bit in the freedVector should be set to 0. */

always @(*)
begin: UPDATE_FREED_VECTOR
	integer i;

	freedValid0 = freeingScalar00;
	freedValid1 = freeingScalar01;
	freedValid2 = freeingScalar02;
	freedValid3 = freeingScalar03;

	if(freeingScalar00)
		freedEntry0 = 5'd0 + freeingCandidate00;
	else
		freedEntry0 = 5'd0;

	if(freeingScalar01)
		freedEntry1 = 5'd8 + freeingCandidate01;
	else
		freedEntry1 = 5'd0;

	if(freeingScalar02)
		freedEntry2 = 5'd16 + freeingCandidate02;
	else
		freedEntry2 = 5'd0;

	if(freeingScalar03)
		freedEntry3 = 5'd24 + freeingCandidate03;
	else
		freedEntry3 = 5'd0;

	if(ctrlMispredict_i)
		freedVector_t1 = freedVector | mispredictVector_i;
	else
		freedVector_t1 = freedVector;
		
	for(i=0;i<`SIZE_ISSUEQ;i=i+1)	
	begin
		if((grantedValid0_i && (i == grantedEntry0_i)) ||
		(grantedValid1_i && (i == grantedEntry1_i)) ||
		(grantedValid2_i && (i == grantedEntry2_i)) ||
		(grantedValid3_i && (i == grantedEntry3_i)))
			freedVector_t[i] = 1'b1;
		else if((freedValid0 && (i == freedEntry0)) ||
		(freedValid1 && (i == freedEntry1)) ||
		(freedValid2 && (i == freedEntry2)) ||
		(freedValid3 && (i == freedEntry3)))
			freedVector_t[i] = 1'b0;
		else
			freedVector_t[i] = freedVector_t1[i];
	end
end

/* Following writes newly computed freed vector to freedVector register every cycle. */
always @(posedge clk)
begin
	if(reset)
	begin
		freedVector <= 0;
	end
	else
	begin
		freedVector <= freedVector_t;
	end	 	
end

/* Following instantiate "selectFromBlock" module to get upto 4 freed issue queue
 * entries this cycle. */
selectFromBlock_0 selectFromBlock00_l1(.blockVector_i(freedVector[7:0]),
	.freeingScalar_o(freeingScalar00),
	.freeingCandidate_o(freeingCandidate00)
);

selectFromBlock_0 selectFromBlock01_l1(.blockVector_i(freedVector[15:8]),
	.freeingScalar_o(freeingScalar01),
	.freeingCandidate_o(freeingCandidate01)
);

selectFromBlock_0 selectFromBlock02_l1(.blockVector_i(freedVector[23:16]),
	.freeingScalar_o(freeingScalar02),
	.freeingCandidate_o(freeingCandidate02)
);

selectFromBlock_0 selectFromBlock03_l1(.blockVector_i(freedVector[31:24]),
	.freeingScalar_o(freeingScalar03),
	.freeingCandidate_o(freeingCandidate03)
);

endmodule


module selectFromBlock_0(input [7:0] blockVector_i,
	output freeingScalar_o,
	output [`SIZE_ISSUEQ_LOG-1:0] freeingCandidate_o   			
);

reg freeingScalar;
reg [`SIZE_ISSUEQ_LOG-1:0] freeingCandidate;

assign freeingCandidate_o = freeingCandidate;
assign freeingScalar_o = freeingScalar;

always @(*)
begin:FIND_FREEING_CANDIDATE_0
	casex({blockVector_i[7], blockVector_i[6], blockVector_i[5], blockVector_i[4], blockVector_i[3], blockVector_i[2], blockVector_i[1], blockVector_i[0]})
		8'bxxxxxxx1:
		begin
			freeingCandidate = 5'b00000;
			freeingScalar = 1'b1;
		end
		8'bxxxxxx10:
		begin
			freeingCandidate = 5'b00001;
			freeingScalar = 1'b1;
		end
		8'bxxxxx100:
		begin
			freeingCandidate = 5'b00010;
			freeingScalar = 1'b1;
		end
		8'bxxxx1000:
		begin
			freeingCandidate = 5'b00011;
			freeingScalar = 1'b1;
		end
		8'bxxx10000:
		begin
			freeingCandidate = 5'b00100;
			freeingScalar = 1'b1;
		end
		8'bxx100000:
		begin
			freeingCandidate = 5'b00101;
			freeingScalar = 1'b1;
		end
		8'bx1000000:
		begin
			freeingCandidate = 5'b00110;
			freeingScalar = 1'b1;
		end
		8'b10000000:
		begin
			freeingCandidate = 5'b00111;
			freeingScalar = 1'b1;
		end
 		default:
 		begin
  			freeingCandidate = 0;
  			freeingScalar = 0;
  		end
	endcase
end

endmodule

