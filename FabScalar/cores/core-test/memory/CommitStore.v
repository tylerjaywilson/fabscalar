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


module CommitStore ( 	input commitStore0_i,
			input commitStore1_i,
			input commitStore2_i,
			input commitStore3_i, 
			
			input [`SIZE_LSQ_LOG-1:0]  stqCommitPtr_i,

			output [`SIZE_LSQ_LOG-1:0] cntStCom_o,
			
			output [`SIZE_LSQ_LOG-1:0] index0StCom_o,
			output [`SIZE_LSQ_LOG-1:0] index1StCom_o,
			output [`SIZE_LSQ_LOG-1:0] index2StCom_o,
			output [`SIZE_LSQ_LOG-1:0] index3StCom_o
		  );


reg [2:0] 			cntStCom;
reg [`SIZE_LSQ_LOG-1:0] 	index0StCom;
reg [`SIZE_LSQ_LOG-1:0] 	index1StCom;
reg [`SIZE_LSQ_LOG-1:0] 	index2StCom;
reg [`SIZE_LSQ_LOG-1:0] 	index3StCom;



assign cntStCom_o 	= cntStCom;

assign index0StCom_o	= index0StCom;
assign index1StCom_o	= index1StCom;
assign index2StCom_o	= index2StCom;
assign index3StCom_o	= index3StCom;


always @(*)
begin
  cntStCom    = 0;
  index0StCom = 0;
  index1StCom = 0;
  index2StCom = 0;
  index3StCom = 0;


    /* Following combinational logic counts the number of LD commitructions in the
       incoming retiring commitructions. */
    case({commitStore3_i,commitStore2_i,commitStore1_i,commitStore0_i})
          4'b0001:
          begin
                cntStCom    		  = 3'b001;
                index0StCom 		  = stqCommitPtr_i;
          end
          4'b0010:
          begin
                cntStCom    		  = 3'b001;
                index0StCom 		  = stqCommitPtr_i;
          end
          4'b0011:
          begin
                cntStCom    		  = 3'b010;
                index0StCom 		  = stqCommitPtr_i;
                index1StCom 		  = stqCommitPtr_i + 1;
          end
          4'b0100:
          begin
                cntStCom    		  = 3'b001;
                index0StCom 		  = stqCommitPtr_i;
          end
          4'b0101:
          begin
                cntStCom    		  = 3'b010;
                index0StCom 		  = stqCommitPtr_i;
                index1StCom 		  = stqCommitPtr_i + 1;
          end
          4'b0110:
          begin
                cntStCom    		  = 3'b010;
                index0StCom 		  = stqCommitPtr_i;
                index1StCom 		  = stqCommitPtr_i + 1;
          end
          4'b0111:
          begin
                cntStCom    		  = 3'b011;
                index0StCom 		  = stqCommitPtr_i;
                index1StCom 		  = stqCommitPtr_i + 1;
                index2StCom 		  = stqCommitPtr_i + 2;
          end
          4'b1000:
          begin
                cntStCom    		  = 3'b001;
                index0StCom 		  = stqCommitPtr_i;
          end
 	  4'b1001:
          begin
                cntStCom   	 	  = 3'b010;
                index0StCom 		  = stqCommitPtr_i;
                index1StCom 		  = stqCommitPtr_i + 1;
          end
          4'b1010:
          begin
                cntStCom    		  = 3'b010;
                index0StCom 		  = stqCommitPtr_i;
                index1StCom 		  = stqCommitPtr_i + 1;
          end
          4'b1011:
          begin
                cntStCom    		  = 3'b011;
                index0StCom 		  = stqCommitPtr_i;
                index1StCom 		  = stqCommitPtr_i + 1;
                index2StCom 		  = stqCommitPtr_i + 2;
          end
          4'b1100:
          begin
                cntStCom    		  = 3'b010;
                index0StCom 		  = stqCommitPtr_i;
                index1StCom 		  = stqCommitPtr_i + 1;
          end
          4'b1101:
          begin
                cntStCom    		  = 3'b011;
                index0StCom 		  = stqCommitPtr_i;
                index1StCom 		  = stqCommitPtr_i + 1;
                index2StCom 		  = stqCommitPtr_i + 2;
          end
          4'b1110:
          begin
                cntStCom    		  = 3'b011;
                index0StCom 		  = stqCommitPtr_i;
                index1StCom 		  = stqCommitPtr_i + 1;
                index2StCom 		  = stqCommitPtr_i + 2;
          end
	  4'b1111:
          begin
                cntStCom    		  = 3'b100;
                index0StCom 		  = stqCommitPtr_i;
                index1StCom 		  = stqCommitPtr_i + 1;
                index2StCom 		  = stqCommitPtr_i + 2;
                index3StCom 		  = stqCommitPtr_i + 3;
          end
    endcase 
end

endmodule
