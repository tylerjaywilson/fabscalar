#!/usr/bin/perl
use POSIX qw(ceil floor);

################################################################################
#                       NORTH CAROLINA STATE UNIVERSITY
#
#                              FabScalar Project
#
# FabScalar Copyright (c) 2007-2011 by Niket K. Choudhary, Salil Wadhavkar,
# and Eric Rotenberg.  All Rights Reserved.
#
# This is a beta-release version.  It must not be redistributed at this time.
#
# Purpose: To gerate the RegRead Module for the input configrations.
################################################################################

  sub error_ussage{
	print "Usage: perl ./generate_RR.pl -w <issue_width> -p <pipe depth> -dw <datawidth>\n";
        exit;
  }
  #Read command line arguments
  $no_of_args = 0;
  while(@ARGV){
	$_ = shift;
	if(/^-w$/){
		$widthPipe = shift;
		$no_of_args++;
	}
	elsif(/^-p$/){
		$depthPipe = shift;
	#	$iqSizeLog = log2($iqSize);
		$no_of_args++;
	}
	elsif(/^-dw$/){
		$data_width = shift;
		$no_of_args++;
        }
	else{
		print "Error: Unrecognized argument $_.\n";
		&error_ussage();
	}
  }  

  if($no_of_args != 3){
	print "Too few arguments... \n";
	&error_ussage();
  }

  $outfile="RegRead.v";

print <<LABEL;
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

LABEL


  print <<LABEL;

  module RegRead ( 
LABEL
  for($i=0; $i<$widthPipe; $i++){
  print <<LABEL;
                 input [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                        `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                        `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket${i}_i,
                 input fuPacketValid${i}_i,
		 input [`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:0] bypassPacket${i}_i,
                 input bypassValid${i}_i,
                 input [`SIZE_PHYSICAL_LOG:0] unmapDest${i}_i,
                 input [`SIZE_PHYSICAL_LOG-1:0] rsr${i}Tag_i,
                 input                          rsr${i}TagValid_i,
LABEL
  }

  print <<LABEL;
                 input ctrlVerified_i,                          // control execution flags from the bypass path
                 input ctrlMispredict_i,                        // if 1, there has been a mis-predict previous cycle
                 input [`CHECKPOINTS_LOG-1:0] ctrlSMTid_i,      // SMT id of the mispredicted branch

                 output [`SIZE_PHYSICAL_TABLE-1:0] phyRegRdy_o,

LABEL

  for($i=0; $i<$widthPipe; $i++){
	  print <<LABEL;
                 output [2*`SIZE_DATA+`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                         `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                         `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket${i}_o,
                 output fuPacketValid${i}_o,
LABEL
  }

  print " input clk,
                 input reset,
                 input recoverFlag_i,
                 input exceptionFlag_i
              );\n\n reg [`SIZE_PHYSICAL_TABLE-1:0] PHY_REG_VALID; \n";
  # SRAM Width division for pipelined register file
  $stage_width = ceil($data_width / ($depthPipe));

  print "`define SRAM_DATA_WIDTH $stage_width\n\n"; 
  ###  Instruction Source operands
  for($i=0; $i<$widthPipe ; $i++){
	print " reg [`SIZE_PHYSICAL_LOG-1:0]           inst${i}Source1; \n";
	print " reg [`SIZE_PHYSICAL_LOG-1:0]           inst${i}Source2; \n";
  } 
  print "\n";

  ### Piplined Instruction Source operands
  for($j=1; $j<$depthPipe ; $j++){
	for($i=0; $i<$widthPipe ; $i++){
		print " reg [`SIZE_PHYSICAL_LOG-1:0]           inst${i}Source1_${j}; \n";
		print " reg [`SIZE_PHYSICAL_LOG-1:0]           inst${i}Source2_${j}; \n";
  	} 
	print "\n";
  }
  print "\n";

   ###  Bypass Data
  for($i=0; $i<$widthPipe ; $i++){
	print " reg [`SIZE_DATA-1:0]           bypass${i}Data; \n";
  } 
  print "\n";
 
  ###  Bypass Tags
  for($i=0; $i<$widthPipe ; $i++){
	print " reg [`SIZE_PHYSICAL_LOG-1:0]           bypass${i}Dest; \n";
  } 
  print "\n";
  
  ### Piplined  Bypass Tags
  for($j=1; $j<$depthPipe ; $j++){
	for($i=0; $i<$widthPipe ; $i++){
		print " reg [`SIZE_PHYSICAL_LOG-1:0]           bypass${i}Dest_${j}; \n";
		print " reg 					bypassValid${i}_${j}; \n";
  	} 
	print "\n";
  }
  print "\n";

  ### Match Vector and signals 
  

  print " reg                                    mispredictEvent;\n reg [`CHECKPOINTS_LOG-1:0]             mispredictSMTid;\n\n"; 
  
  ### Instruction Mask
  for($i=0 ; $i<$widthPipe ; $i++){
	print " reg [`CHECKPOINTS-1:0]                 ";
	for($j=1;$j<=$depthPipe ; $j++){
		print " inst${i}Mask_l${j}";
		if($j!=$depthPipe){
		   print ",";
		}
	}
	print ";\n";
  }

### Instruction Data
  for($i=0; $i<$widthPipe ; $i++){
	print " reg [`SIZE_DATA-1:0]           inst${i}Data1; \n";
	print " reg [`SIZE_DATA-1:0]           inst${i}Data2; \n";
  } 
  print "\n";

### Pipelined latches for Instruction Data	 
   $latches = $depthPipe;
   for($j=1;$j<=$depthPipe;$j++){
       for($k=1;$k<=$latches;$k++){
	  for($i=0; $i<$widthPipe ; $i++){
	        print " reg [`SRAM_DATA_WIDTH-1:0]           inst${i}Data1_${j}${k}; \n";
	        print " reg [`SRAM_DATA_WIDTH-1:0]           inst${i}Data2_${j}${k}; \n";
  	  }
  	  print "\n";
	}
  	print "\n";
	$latches--;
   }
  print "\n";

 ### Pipelined latches for fuPacketValid

 for($j=1;$j<=$depthPipe;$j++){
	for($i=0; $i<$widthPipe ; $i++){
		print " reg                  		fuPacketValid${i}_l${j}; \n";
	}
  	print "\n";
 }
 print "\n";

 ### Pipelined latches for fuPacket
 for($j=1;$j<=$depthPipe;$j++){
	for($i=0; $i<$widthPipe ; $i++){
		print " reg [`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
      `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
      `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:0] fuPacket${i}_i_l${j}; \n";
	}
  	print "\n";
 }
 print "\n";

 ### Decoded address output at each stage of pipeline stage
 for($j=1;$j<=$depthPipe;$j++){
        for($i=0; $i<2*$widthPipe ; $i++){
		print " wire [`SIZE_PHYSICAL_TABLE-1:0] decoded_addr${i}_stage${j}_o; \n" ;
	}
  	print "\n";
 }
 print "\n";

 for($j=1;$j<=$depthPipe;$j++){
        for($i=0; $i<$widthPipe ; $i++){
                print " wire [`SIZE_PHYSICAL_TABLE-1:0] decoded_addr${i}wr_stage${j}_o; \n" ;
        }
        print "\n";
 }
 print "\n";

 ### Decoded address input at each stage of pipeline stage
 if($depthPipe>1){
  for($j=2;$j<=$depthPipe;$j++){
        for($i=0; $i<2*$widthPipe ; $i++){
                print " reg [`SIZE_PHYSICAL_TABLE-1:0] decoded_addr${i}_stage${j}_i; \n" ;
        }
        print "\n";
 }
 print "\n";
 }

 if($depthPipe>1){
  for($j=2;$j<=$depthPipe;$j++){
        for($i=0; $i<$widthPipe ; $i++){
                print " reg [`SIZE_PHYSICAL_TABLE-1:0] decoded_addr${i}wr_stage${j}_i; \n" ;
        }
        print "\n";
 }
 print "\n";
 }

 ### Write Enable input of each pipelined stage  
  if($depthPipe>1){
  for($j=2;$j<=$depthPipe;$j++){
	print " reg ";
        for($i=0; $i<$widthPipe ; $i++){
		if($i==$widthPipe-1){
		   print "we${i}_stage${j}_i; \n";
		}
		else {
                   print "we${i}_stage${j}_i, ";
		}
	}
  }
  }
  print "\n";

  ### Write Enable output of each pipelined stage
  for($j=1;$j<=$depthPipe;$j++){
        print " wire ";
        for($i=0; $i<$widthPipe ; $i++){
                if($i==$widthPipe-1){
                   print "we${i}_stage${j}_o; \n";
                }
                else {
                   print "we${i}_stage${j}_o, ";
                }
        }
  }
  print "\n";
  
 ### Read data output from the all the piplined stages
 for($j=1;$j<=$depthPipe;$j++){
        for($i=0; $i<2*$widthPipe ; $i++){
                print " wire [`SRAM_DATA_WIDTH-1:0]                     data${i}_stage${j}; \n" ;
        }
        print "\n";
 }
 print "\n";

 ### Bypass data at each pipiline stage
  for($j=1;$j<=$depthPipe;$j++){
        for($i=0; $i<$widthPipe ; $i++){
                print " reg [`SRAM_DATA_WIDTH-1:0]                     bypass${i}Data_stage${j}i; \n" ;
        }
        print "\n";
 }

 for($j=1;$j<=$depthPipe;$j++){
    for($k=$j-2;$k>=1;$k--){
        for($i=0; $i<$widthPipe ; $i++){
                print " reg [`SRAM_DATA_WIDTH-1:0]                     bypass${i}Data_stage${j}${k}i; \n" ;
        }
        print "\n";
    }
 }
 print "\n";
 ### Bypass data from the write back stage for each sink at pipelined RR
  for($j=1;$j<=$depthPipe;$j++){
        for($i=0; $i<$widthPipe ; $i++){
                print " reg [`SRAM_DATA_WIDTH-1:0]                     bypass${i}Data_${j}; \n" ;
        }
        print "\n";
 }
 ### Match signals for bypass selection
 for($i=0; $i<$widthPipe ; $i++){
	for($j=0;$j<$widthPipe ; $j++){
		print " wire   inst${i}Src1_mch${j}, inst${i}Src2_mch${j}; \n";
	}
 }

 if($depthPipe>1){
  for($k=1;$k<$depthPipe;$k++){
     for($i=0; $i<$widthPipe ; $i++){
     $mch_cnt=0;
	for($l=0;$l<=$i;$l++){	
        	for($j=0;$j<$widthPipe ; $j++){
                	print " wire   inst${i}Src1_${k}_mch${mch_cnt}, inst${i}Src2_${k}_mch${mch_cnt}; \n";
                        $mch_cnt++;
		}
	       print "\n";
	}
     }
     print "\n";
   }
 }

 ### MatchVector for bypass selection
  $latches = $depthPipe;
  for($k=1;$k<=$depthPipe;$k++){
      for($j=1;$j<=$latches;$j++){
	 for($i=0;$i<$widthPipe;$i++){
		if($j==1){
		  $bit_width = $widthPipe*$k-1;
	 	  print " wire [${bit_width}:0] inst${i}Src1_${k}${j}_mVector, inst${i}Src2_${k}${j}_mVector; \n";
		}
		else{		  
		  $bit_width = $widthPipe-1;			
	 	  print " wire [${bit_width}:0] inst${i}Src1_${k}${j}_mVector, inst${i}Src2_${k}${j}_mVector; \n";
		}
	 }
       print "\n";
      }
     print "\n";
  $latches--;
  } 
  print "\n";

 ############################################################
 ##################	RTL for RR 	#####################
 ############################################################
 
 ###	Bypass data divided among pipeline stages
 print  "\n always@(*) \n begin \n";
   for($i=0;$i<$widthPipe;$i++){
	 print "\tbypass${i}Data_stage1i \t= bypass${i}Data[`SRAM_DATA_WIDTH-1:0]; \n";
   	 for($k=1;$k<=$depthPipe;$k++){
		$k_dec = $k-1;
		print "\tbypass${i}Data_${k} \t\t= bypass${i}Data[${k}*`SRAM_DATA_WIDTH-1:${k_dec}*`SRAM_DATA_WIDTH]; \n";
	 }
         print "\n";
   }
   print " end \n";
 
 ###	PhyRegFile first segment placement
 $width2 = 2 * $widthPipe;
  print " SRAM_${width2}R${widthPipe}W_PIPE #(`SIZE_PHYSICAL_TABLE,`SIZE_PHYSICAL_LOG,`SRAM_DATA_WIDTH) \n\t\t PhyRegFile1( \n";
 for($i=0;$i<$widthPipe;$i++){
	$temp = 2*$i;
	print "\t\t\t .addr${temp}_i(inst${i}Source1), \n";
	$temp++;
	print "\t\t\t .addr${temp}_i(inst${i}Source2), \n";
	print "\t\t\t .we${i}_i(bypassValid${i}_i & ~recoverFlag_i), \n";
	print "\t\t\t .addr${i}wr_i(bypass${i}Dest), \n";
	print "\t\t\t .data${i}wr_i(bypass${i}Data_stage1i), \n";
	print "\t\t\t .decoded_addr${i}wr_o(decoded_addr${i}wr_stage1_o), \n";
	print "\t\t\t .we${i}_o(we${i}_stage1_o), \n";
 }

 for($i=0;$i<2*$widthPipe;$i++){
	print "\t\t\t .data${i}_o(data${i}_stage1), \n";
	print "\t\t\t .decoded_addr${i}_o(decoded_addr${i}_stage1_o), \n";
 }
 print "\t\t\t .clk(clk), \n\t\t\t .reset(reset) \n\t\t);\n" ;
 if($depthPipe>1)
 {
    for($j=2;$j<=$depthPipe; $j++){
 	print " SRAM_${width2}R${widthPipe}W_PIPE_NEXT #(`SIZE_PHYSICAL_TABLE,`SIZE_PHYSICAL_LOG,`SRAM_DATA_WIDTH) \n\t\t PhyRegFile${j}( \n";
	 for($i=0;$i<$widthPipe;$i++){
	        print "\t\t\t .we${i}_i(we${i}_stage${j}_i & ~recoverFlag_i), \n";
        	print "\t\t\t .decoded_addr${i}wr_i(decoded_addr${i}wr_stage${j}_i), \n";
	        print "\t\t\t .data${i}wr_i(bypass${i}Data_stage${j}i), \n";
        	print "\t\t\t .decoded_addr${i}wr_o(decoded_addr${i}wr_stage${j}_o), \n";
	        print "\t\t\t .we${i}_o(we${i}_stage${j}_o), \n";
 	}
	 for($i=0;$i<2*$widthPipe;$i++){
 		print "\t\t\t .decoded_addr${i}_i(decoded_addr${i}_stage${j}_i), \n";
       		print "\t\t\t .data${i}_o(data${i}_stage${j}), \n";
		print "\t\t\t .decoded_addr${i}_o(decoded_addr${i}_stage${j}_o), \n";
	 }
     print "\t\t\t .clk(clk), \n\t\t\t .reset(reset) \n\t\t);\n\n" ;
   }
 }
 
 ### Pipeline reg. file input at each stage of the reg. gile
 if($depthPipe>1){
    for($j=2;$j<=$depthPipe; $j++){
	$j_dec = $j - 1;
	print "always @(posedge clk) \nbegin \n\tif(reset | recoverFlag_i)\n\tbegin\n" ; 
	for($i=0;$i<2*$widthPipe;$i++){
		print "\t\tdecoded_addr${i}_stage${j}_i \t\t<= 0; \n";
	} 
	for($i=0;$i<$widthPipe;$i++){
		print "\t\tdecoded_addr${i}wr_stage${j}_i \t<= 0; \n";
		print "\t\twe${i}_stage${j}_i \t\t\t<= 0; \n";
	} 
	print "\tend\n\telse\n\tbegin\n";
	for($i=0;$i<2*$widthPipe;$i++){
		print "\t\tdecoded_addr${i}_stage${j}_i \t\t<= decoded_addr${i}_stage${j_dec}_o; \n";
	} 
	for($i=0;$i<$widthPipe;$i++){
		print "\t\tdecoded_addr${i}wr_stage${j}_i \t<= decoded_addr${i}wr_stage${j_dec}_o; \n";
		print "\t\twe${i}_stage${j}_i \t\t\t<= we${i}_stage${j_dec}_o; \n";
	}
	print "\tend\nend\n\n"; 
    }
 }

 ### Bypass data sink at each stage of input to the PRF pipe
 if($depthPipe>1){
 print "always @(posedge clk)\nbegin\n\tif(reset | recoverFlag_i)\n\tbegin\n";
     for($k=2;$k<=$depthPipe;$k++){
	for($j=$k-2;$j>=0;$j--){
		for($i=0;$i<$widthPipe;$i++){
			if($j==0){
				print "\t\tbypass${i}Data_stage${k}i \t<= 0; \n";
			}
			else{
				print "\t\tbypass${i}Data_stage${k}${j}i \t<= 0; \n";
			}
		}
	 print "\n"; 
	}
     }
 print "\tend\n\telse\n\tbegin\n";
     for($k=2;$k<=$depthPipe;$k++){
        for($j=$k-2;$j>=0;$j--){
		$j_inc = $j+1;
                for($i=0;$i<$widthPipe;$i++){
                        if($j==$k-2){
			    if($j==0){
                                print "\t\tbypass${i}Data_stage${k}i \t<= bypass${i}Data_${k}; \n";
			    }
			    else{
                                print "\t\tbypass${i}Data_stage${k}${j}i \t<= bypass${i}Data_${k}; \n";
			    }
                        }
                        else{
                            if($j==0){
                                print "\t\tbypass${i}Data_stage${k}i \t<= bypass${i}Data_stage${k}${j_inc}i; \n";
			    }
                            else{
                                print "\t\tbypass${i}Data_stage${k}${j}i \t<= bypass${i}Data_stage${k}${j_inc}i; \n";
			    }	
                        }
                }
         print "\n";
        }
     }
 print "\tend\nend\n";
 }

 ### Instruction Source operatnd extraction
 print "always @(*)\nbegin\n";
 for($i=0;$i<$widthPipe;$i++){
	print " inst${i}Source1 = fuPacket${i}_i[`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                            `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                            `SIZE_PC+`SIZE_CTI_LOG:`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                            `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                            `SIZE_PC+`SIZE_CTI_LOG+1]; \n\n";
	print " inst${i}Source2 = fuPacket${i}_i[2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+
                            `SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+
                            `SIZE_PC+`SIZE_CTI_LOG:`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+`SIZE_ACTIVELIST_LOG+
                            `CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+`LDST_TYPES_LOG+
                            `SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1]; \n\n";
 }
 print "end\n\n";

 ### Pipline latched Instruction Source operatnd for each stage 
 if($depthPipe>1){
 print "always @(posedge clk)\nbegin\n\tif(reset | recoverFlag_i)\n\tbegin\n";
 for($i=0;$i<$widthPipe;$i++){
    for($j=1;$j<$depthPipe;$j++){
	print "\t\tinst${i}Source1_${j} <= 0; \n";
	print "\t\tinst${i}Source2_${j} <= 0; \n";
	print "\t\tbypass${i}Dest_${j}  <= 0; \n";
	print "\t\tbypassValid${i}_${j} <= 0; \n";
    }
    print "\n";
 }
 print "\tend\n\telse\n\tbegin\n";
  for($i=0;$i<$widthPipe;$i++){
    for($j=1;$j<$depthPipe;$j++){
	$j_dec = $j - 1;
	if($j>1){
	print "\t\tinst${i}Source1_${j} <= inst${i}Source1_${j_dec}; \n";
	print "\t\tinst${i}Source2_${j} <= inst${i}Source2_${j_dec}; \n";
	print "\t\tbypass${i}Dest_${j}  <= bypass${i}Dest_${j_dec}; \n";
	print "\t\tbypassValid${i}_${j} <= bypassValid${i}_${j_dec}; \n";
	}
	else{
	print "\t\tinst${i}Source1_${j} <= inst${i}Source1; \n";
	print "\t\tinst${i}Source2_${j} <= inst${i}Source2; \n"; 
	print "\t\tbypass${i}Dest_${j}  <= bypass${i}Dest; \n";
	print "\t\tbypassValid${i}_${j} <= bypassValid${i}_i; \n";

	}
    }
    print "\n";
 }
 print "\tend\nend\n";
 }
 ### Extract bypass data and bypass physical destination and mask

 print "\nalways @(*)\nbegin\n";
 print " mispredictEvent = ctrlVerified_i & ctrlMispredict_i; \n";
 print " mispredictSMTid = ctrlSMTid_i; \n\n";
 for($i=0;$i<$widthPipe;$i++){
	print " bypass${i}Data = bypassPacket${i}_i[`SIZE_DATA+`CHECKPOINTS_LOG:`CHECKPOINTS_LOG+1]; \n";
	print " bypass${i}Dest = bypassPacket${i}_i[`SIZE_PHYSICAL_LOG+`SIZE_DATA+`CHECKPOINTS_LOG:`SIZE_DATA+`CHECKPOINTS_LOG+1]; \n\n";
 }
 for($j=1;$j<=$depthPipe;$j++){
	$j_dec = $j - 1;
	for($i=0;$i<$widthPipe;$i++){
	    if($j==1){
		print " inst${i}Mask_l${j} \t= fuPacket${i}_i[`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                            `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                            `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:
                            `SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                            `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                            `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1]; \n\n";
	    }
	    else{
		print " inst${i}Mask_l${j} \t= fuPacket${i}_i_l${j_dec}[`CHECKPOINTS+`SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                            `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                            `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG:
                            `SIZE_ISSUEQ_LOG+2*`SIZE_PHYSICAL_LOG+`SIZE_LSQ_LOG+
                            `SIZE_ACTIVELIST_LOG+`CHECKPOINTS_LOG+`SIZE_PHYSICAL_LOG+`SIZE_IMMEDIATE+
                            `LDST_TYPES_LOG+`SIZE_OPCODE_I+`SIZE_PC+`SIZE_PC+`SIZE_CTI_LOG+1]; \n\n";
	    }	
	}
 }
 print "end\n\n";

 ### Match Signals
for($i=0;$i<$depthPipe;$i++){
	for($k=0;$k<$widthPipe;$k++){
		$mch_cnt=0;
		for($l=0;$l<=$i;$l++){
			for($j=0;$j<$widthPipe;$j++){
			    if($i==0){
				print " assign inst${k}Src1_mch${mch_cnt} = ((inst${k}Source1 == bypass${j}Dest) && bypassValid${j}_i); \n";
				print " assign inst${k}Src2_mch${mch_cnt} = ((inst${k}Source2 == bypass${j}Dest) && bypassValid${j}_i); \n";
			    }
			    else{
				if($l==0){
				print " assign inst${k}Src1_${i}_mch${mch_cnt} = ((inst${k}Source1_${i} == bypass${j}Dest) && bypassValid${j}_i); \n";
				print " assign inst${k}Src2_${i}_mch${mch_cnt} = ((inst${k}Source2_${i} == bypass${j}Dest) && bypassValid${j}_i); \n";
				}
				else{
				print " assign inst${k}Src1_${i}_mch${mch_cnt} = ((inst${k}Source1_${i} == bypass${j}Dest_${l}) && bypassValid${j}_${l}); \n";
				print " assign inst${k}Src2_${i}_mch${mch_cnt} = ((inst${k}Source2_${i} == bypass${j}Dest_${l}) && bypassValid${j}_${l}); \n";
				}
			    }
			$mch_cnt++;
			}
		        print "\n";
		    }
		    print "\n";
		}
		print "\n";
	}
	print "\n";

 ### Match Vector Signals

  $latches = $depthPipe;
  for($k=1;$k<=$depthPipe;$k++){
      for($j=1;$j<=$latches;$j++){
	 $kPlusjMin2 = $k + $j - 2;
	 for($i=0;$i<$widthPipe;$i++){
	 	  print " assign inst${i}Src1_${k}${j}_mVector = { ";
		  if($j==1){ $mch_max = ($k*$widthPipe) -1 ;}
		  else{ $mch_max = $widthPipe -1 ;}
		  if($kPlusjMin2 !=0){
			  $string = "inst${i}Src1_${kPlusjMin2}_mch";
		  }
		  else{
			  $string = "inst${i}Src1_mch";
		  }
		  for($l=$mch_max ; $l>=0 ; $l--){
			if($l>0){
			     #print "${string}${l}, \n\t\t\t\t";
			     print "${string}${l}, ";
			}
			else{
			     print "${string}${l}} ;\n";
			}
		  }
                  print "\n assign inst${i}Src2_${k}${j}_mVector = { ";
		  if($j==1){ $mch_max = ($k*$widthPipe) -1 ;}
		  else{ $mch_max = $widthPipe -1 ;}
		  if($kPlusjMin2 !=0){
			  $string = "inst${i}Src2_${kPlusjMin2}_mch";
		  }
		  else{
			  $string = "inst${i}Src2_mch";
		  }
		  for($l=$mch_max ; $l>=0 ; $l--){
			if($l>0){
			     #print "${string}${l}, \n\t\t\t\t";
			     print "${string}${l}, ";
			}
			else{
			     print "${string}${l}} ;\n";
			}
		  }

	 }
       print "\n";
      }
     print "\n";
  $latches--;
  } 
  print "\n";

 ### Bypass Logic for each stage
  $latches = $depthPipe;
  for($k=1;$k<=$depthPipe;$k++){
  # $k=1;
      for($j=1;$j<=$latches;$j++){
	 for($i=0;$i<$widthPipe;$i++){
	    for($data=1;$data<3;$data++){
		if($j==$latches){
		     print "\n always @(*)\n";
		     $assignment = " = ";
		}
		else{
		     print "\n always @(posedge clk)\n begin\n\tif(reset | recoverFlag_i)\n\tbegin\n";
                     print "\t\t inst${i}Data${data}_${k}${j} <= 0;\n\tend\n\telse\n";
		     $assignment = " <= ";
		}
		if($j==1){ $mch_max = ($k*$widthPipe);}
		else{ $mch_max = $widthPipe ;}
		print "\tbegin\n\t\tcase (inst${i}Src${data}_${k}${j}_mVector)\n";
		$l_power = 1;
		$width_cnt = 0;
		$bypass_cnt = $k-1;
		for($l=0;$l<$mch_max;$l++){
		     if($width_cnt==$widthPipe){ $width_cnt = 0; $bypass_cnt--; }
		     if($bypass_cnt ==  $k-1){
			$RHS = "bypass${width_cnt}Data_${k}" ;
		     }
		     elsif($bypass_cnt == 0){
			$RHS = "bypass${width_cnt}Data_stage${k}i" ;
		     }
		     else{
                        $RHS = "bypass${width_cnt}Data_stage${k}${bypass_cnt}i" ;
		     }
		     print "\t\t${mch_max}'d${l_power}\t:\tinst${i}Data${data}_${k}${j}${assignment}${RHS}; \n";
		     $l_power *= 2;
		     $width_cnt++;
		}

		$j_dec = $j-1;
		if($j==1){
			$temp = $i*2+$data-1;
			$RHS = "data${temp}_stage${k}" ;
		}
		else{
			$RHS = "inst${i}Data${data}_${k}${j_dec}";
		}
	        print "\t\tdefault\t:\tinst${i}Data${data}_${k}${j}${assignment}${RHS}; \n";
	        print "\t\tendcase\n\tend\n";
		if($j!=$latches){ print " end\n"; }
		#print " end\n"; 
	     }
	 }
       print "\n";
      }
     print "\n";
  $latches--;
  } 
  print "\n";

 ### Output packet concatenation from all the stages
 print "\n always@(*)\n begin \n";
 for($i=0;$i<$widthPipe;$i++){
	for($data=1;$data<3;$data++){
		print "\tinst${i}Data${data} = { ";
		$k=1;
		for($j=$depthPipe;$j>0;$j--){
			if($j==1){
	                        print "inst${i}Data${data}_${j}${k}}; \n";
			}
			else {
				print "inst${i}Data${data}_${j}${k}, ";
			}
			$k++;
		}
	}
 } 
 print "end\n";

 ### Ouput fuPacketValid
 print "\n always@(*)\n begin \n";
 $depth_dec = $depthPipe - 1;
 for($i=0;$i<$widthPipe;$i++){
	print "\tif(mispredictEvent && inst${i}Mask_l${depthPipe}[mispredictSMTid])\n" ;
	print "\t\tfuPacketValid${i}_l${depthPipe} = 1'b0; \n";
	if($depth_dec!=0){
		print "\telse\n\t\tfuPacketValid${i}_l${depthPipe} = fuPacketValid${i}_l${depth_dec};\n";
	}
	else{
		print "\telse\n\t\tfuPacketValid${i}_l${depthPipe} = fuPacketValid${i}_i;\n";
	}
 }
 print "end\n";

 ### fuPacketValid for each stage of pipeline
 if($depthPipe>1){
 print "\n always@(posedge clk)\n begin\n\tif(reset |recoverFlag_i)\n\tbegin\n"; 
 for($k=1;$k<$depthPipe;$k++){
	for($j=0;$j<$widthPipe;$j++){
		print "\t\tfuPacketValid${j}_l${k} <= 0;\n";
		print "\t\tfuPacket${j}_i_l${k} <= 0;\n";
	}
 }
 print "\tend\n\telse\n\tbegin\n"; 
 for($k=1;$k<$depthPipe;$k++){
	$k_dec = $k-1;
        for($j=0;$j<$widthPipe;$j++){
		if($k_dec != 0){
	            print "\tfuPacket${j}_i_l${k} <= fuPacket${j}_i_l${k_dec};\n";
		}
		else{
                    print "\tfuPacket${j}_i_l${k} <= fuPacket${j}_i;\n";		
		}
		$if_cond = "mispredictEvent && inst${j}Mask_l${k}[mispredictSMTid]";
		$fu = "fuPacketValid${j}_l${k}";
		if($k==1){
			$fu_rhs = "fuPacketValid${j}_i";
		}
		else {
                        $fu_rhs = "fuPacketValid${j}_l${k_dec}";
		}
		print "\n\tif(${if_cond})\n\t\t${fu} <= 0;\n\telse\n";
		print "\t\t${fu} <= ${fu_rhs}; \n";
	}
 }

 print "\tend\n end\n";
 }
 print "\n assign phyRegRdy_o      = PHY_REG_VALID;\n";

 for($i=0;$i<$widthPipe;$i++){
	print " assign fuPacketValid${i}_o = fuPacketValid${i}_l${depthPipe};\n";
	if($depth_dec!=0){
		print " assign fuPacket${i}_o = {inst${i}Data2, inst${i}Data1, fuPacket${i}_i_l${depth_dec}};\n";
	}
	else{
		print " assign fuPacket${i}_o = {inst${i}Data2, inst${i}Data1, fuPacket${i}_i};\n";
	}
 }

 print "\n\n";
 print <<LABEL;
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

LABEL

 for($i=0;$i<$widthPipe;$i++){
	print "\tif(unmapDest${i}_i[0]) PHY_REG_VALID[unmapDest${i}_i[`SIZE_PHYSICAL_LOG:1]] <= 1'b0;\n";
 }

 $width_dec = $widthPipe -1 ;
 print "\n";
 for($i=0;$i<$width_dec;$i++){
	print "\tif(rsr${i}TagValid_i) PHY_REG_VALID[rsr${i}Tag_i]    <= 1'b1;\n";
 }
 print "\tif(bypassValid${width_dec}_i) PHY_REG_VALID[bypass${width_dec}Dest]  <= 1'b1;\n";
 print "\tend\n end\n\nendmodule\n\n";





