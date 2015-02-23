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

module CommitLoad ( 	input commitLoad0_i,
			input commitLoad1_i,
			input commitLoad2_i,
			input commitLoad3_i, 
			input [`SIZE_LSQ_LOG-1:0] ldqHead_i,
			
			output [`SIZE_LSQ_LOG-1:0] cntLdCom_o,
			
			output [`SIZE_LSQ_LOG-1:0] index0LdCom_o,
			output [`SIZE_LSQ_LOG-1:0] index1LdCom_o,
			output [`SIZE_LSQ_LOG-1:0] index2LdCom_o,
			output [`SIZE_LSQ_LOG-1:0] index3LdCom_o
		  );


reg [2:0] 			cntLdCom;
reg [`SIZE_LSQ_LOG-1:0] 	index0LdCom;
reg [`SIZE_LSQ_LOG-1:0] 	index1LdCom;
reg [`SIZE_LSQ_LOG-1:0] 	index2LdCom;
reg [`SIZE_LSQ_LOG-1:0] 	index3LdCom;



assign cntLdCom_o 	= cntLdCom;

assign index0LdCom_o	= index0LdCom;
assign index1LdCom_o	= index1LdCom;
assign index2LdCom_o	= index2LdCom;
assign index3LdCom_o	= index3LdCom;


always @(*)
begin
  cntLdCom    = 0;
  index0LdCom = 0;
  index1LdCom = 0;
  index2LdCom = 0;
  index3LdCom = 0;


    /* Following combinational logic counts the number of LD commitructions in the
       incoming retiring commitructions. */
    case({commitLoad3_i,commitLoad2_i,commitLoad1_i,commitLoad0_i})
          4'b0001:
          begin
                cntLdCom    = 3'b001;
                index0LdCom = ldqHead_i;
          end
          4'b0010:
          begin
                cntLdCom    = 3'b001;
                index0LdCom = ldqHead_i;
          end
          4'b0011:
          begin
                cntLdCom    = 3'b010;
                index0LdCom = ldqHead_i;
                index1LdCom = ldqHead_i + 1;
          end
          4'b0100:
          begin
                cntLdCom    = 3'b001;
                index0LdCom = ldqHead_i;
          end
          4'b0101:
          begin
                cntLdCom    = 3'b010;
                index0LdCom = ldqHead_i;
                index1LdCom = ldqHead_i + 1;
          end
          4'b0110:
          begin
                cntLdCom    = 3'b010;
                index0LdCom = ldqHead_i;
                index1LdCom = ldqHead_i + 1;
          end
          4'b0111:
          begin
                cntLdCom    = 3'b011;
                index0LdCom = ldqHead_i;
                index1LdCom = ldqHead_i + 1;
                index2LdCom = ldqHead_i + 2;
          end
          4'b1000:
          begin
                cntLdCom    = 3'b001;
                index0LdCom = ldqHead_i;
          end
 	  4'b1001:
          begin
                cntLdCom    = 3'b010;
                index0LdCom = ldqHead_i;
                index1LdCom = ldqHead_i + 1;
          end
          4'b1010:
          begin
                cntLdCom    = 3'b010;
                index0LdCom = ldqHead_i;
                index1LdCom = ldqHead_i + 1;
          end
          4'b1011:
          begin
                cntLdCom    = 3'b011;
                index0LdCom = ldqHead_i;
                index1LdCom = ldqHead_i + 1;
                index2LdCom = ldqHead_i + 2;
          end
          4'b1100:
          begin
                cntLdCom    = 3'b010;
                index0LdCom = ldqHead_i;
                index1LdCom = ldqHead_i + 1;
          end
          4'b1101:
          begin
                cntLdCom    = 3'b011;
                index0LdCom = ldqHead_i;
                index1LdCom = ldqHead_i + 1;
                index2LdCom = ldqHead_i + 2;
          end
          4'b1110:
          begin
                cntLdCom    = 3'b011;
                index0LdCom = ldqHead_i;
                index1LdCom = ldqHead_i + 1;
                index2LdCom = ldqHead_i + 2;
          end
	  4'b1111:
          begin
                cntLdCom    = 3'b100;
                index0LdCom = ldqHead_i;
                index1LdCom = ldqHead_i + 1;
                index2LdCom = ldqHead_i + 2;
                index3LdCom = ldqHead_i + 3;
          end
    endcase 
end

endmodule
