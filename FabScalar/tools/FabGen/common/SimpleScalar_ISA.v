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
# Purpose: Defining the instruction set for the design. The instructions
#          are from SimpleScalar.
# Author:  FabGen
*******************************************************************************/

`define NOP		        16'h00        	
`define JUMP			16'h01		
`define JAL			16'h02		
`define JR 			16'h03		
`define JALR	 		16'h04		
`define BEQ			16'h05		
`define BNE			16'h06		
`define BLEZ			16'h07		
`define BGTZ			16'h08            
`define BLTZ	 		16'h09		
`define BGEZ 			16'h0a		
`define BC1F 			16'h0b		
`define BC1T 			16'h0c		
`define LB			16'h20		
`define LBU 			16'h22 		
`define LH 			16'h24		
`define LHU 			16'h26 		
`define LW			16'h28		
`define DLW			16'h29		
`define L_S 			16'h2a		
`define L_D			16'h2b		
`define LWL                     16'h2c		
`define LWR                     16'h2d		
`define SB 			16'h30 		
`define SH 			16'h32 		
`define SW 			16'h34 		
`define DSW			16'h35		
`define DSZ			16'h38		
`define S_S 			16'h36 		
`define S_D			16'h37		
`define SWL                     16'h39		
`define SWR                     16'h3a		
`define LB_RR			16'hc0		
`define LBU_RR			16'hc1 		
`define LH_RR	 		16'hc2		
`define LHU_RR			16'hc3 		
`define LW_RR			16'hc4		
`define DLW_RR			16'hce		
`define L_S_RR			16'hc5		
`define L_D_RR			16'hcf		
`define SB_RR 			16'hc6 		
`define SH_RR	 		16'hc7 		
`define SW_RR	 		16'hc8 		
`define DSW_RR			16'hd0		
`define DSZ_RR			16'hd1		
`define S_S_RR			16'hc9 		
`define S_D_RR			16'hd2		
`define L_S_RR_R2		16'hca		
`define S_S_RR_R2		16'hcb		
`define LW_RR_R2		16'hcc		
`define SW_RR_R2		16'hcd 		
`define ADD	 		16'h40		
`define ADDI			16'h41		
`define ADDU 			16'h42		
`define ADDIU			16'h43		
`define SUB 			16'h44		
`define SUBU 			16'h45		
`define MULT 			16'h46		
`define MULTU 			16'h47		
`define DIV 			16'h48		
`define DIVU 			16'h49		
`define MFHI 			16'h4a		
`define MTHI 			16'h4b		
`define MFLO 			16'h4c		
`define MTLO 			16'h4d		
`define AND_ 			16'h4e		
`define ANDI			16'h4f		
`define OR 			16'h50		
`define ORI 			16'h51		
`define XOR 			16'h52		
`define XORI 			16'h53		
`define NOR 			16'h54		
`define SLL 			16'h55		
`define SLLV 			16'h56		
`define SRL 			16'h57		
`define SRLV 			16'h58		
`define SRA 			16'h59		
`define SRAV 			16'h5a		
`define SLT			16'h5b		
`define SLTI 			16'h5c		
`define SLTU 			16'h5d		
`define SLTIU			16'h5e		
`define FADD_S			16'h70		
`define FADD_D			16'h71		
`define FSUB_S			16'h72		
`define FSUB_D			16'h73		
`define FMUL_S			16'h74		
`define FMUL_D 		        16'h75		
`define FDIV_S			16'h76		
`define FDIV_D			16'h77		
`define FABS_S			16'h78		
`define FABS_D			16'h79		
`define FMOV_S			16'h7a		
`define FMOV_D			16'h7b		
`define FNEG_S			16'h7c		
`define FNEG_D			16'h7d		
`define CVT_S_D		        16'h80 		
`define CVT_S_W		        16'h81		
`define CVT_D_S		        16'h82		
`define CVT_D_W		        16'h83		
`define CVT_W_S		        16'h84		
`define CVT_W_D		        16'h85		
`define C_EQ_S			16'h90		
`define C_EQ_D			16'h91		
`define C_LT_S			16'h92		
`define C_LT_D                  16'h93		
`define C_LE_S			16'h94		
`define C_LE_D			16'h95		
`define FSQRT_S		        16'h96		
`define FSQRT_D		        16'h97		
`define SYSCALL 		16'ha0		
`define BREAK			16'ha1		
`define LUI 			16'ha2		
`define MFC1	 		16'ha3		
`define DMFC1 			16'ha7		
`define CFC1 			16'ha4		
`define MTC1 			16'ha5		
`define DMTC1	 		16'ha8		
`define CTC1 			16'ha6		

/* Intruction-fission added to support instruction having multiple destinations
 */
`define MULT_H			16'hff
`define MULT_L			16'hfe
`define MULTU_H                 16'hfd
`define MULTU_L                 16'hfc
`define DIV_H			16'hfb
`define DIV_L			16'hfa
`define DIVU_H			16'hf9
`define DIVU_L			16'hf8
`define DLW_H			16'hf7
`define DLW_L                   16'hf6
`define DSW_H			16'hf5
`define DSW_L                   16'hf4


/* PISA instruction format
*/
`define SIZE_OPCODE_P           32       // opcode size from original PISA i.e. 32bits
`define SIZE_OPCODE_I           8       // opcode size used for implementation
`define SIZE_IMMEDIATE          16
`define SIZE_TARGET             26
`define SIZE_RS                 8
`define SIZE_RT                 8
`define SIZE_RD                 8
`define SIZE_RU                 8
`define SIZE_SPECIAL_REG        2         // In case of SimpleScalar HI and LO
                                         // are special registers, which stores
                                         // Multiply and Divide result.
