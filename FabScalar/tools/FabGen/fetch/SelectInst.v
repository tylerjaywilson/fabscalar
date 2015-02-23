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


module SelectInst( input [`SIZE_PC-1:0] pc_i,
                   output startBlock_o,       // Select signal for inst read from Even/Odd banks
                   output [1:0] firstInst_o   // First instruction from the cache blocks read
                 );


assign startBlock_o = pc_i[4];
assign firstInst_o  = pc_i[3:2];



endmodule
