#*******************************************************************************
#                        NORTH CAROLINA STATE UNIVERSITY
#
#                               FabScalar Project
#
# FabScalar Copyright (c) 2007-2011 by Niket K. Choudhary, Salil Wadhavkar,
# and Eric Rotenberg.  All Rights Reserved.
#
# This is a beta-release version.  It must not be redistributed at this time.
#
# Purpose: This script is used to read RTL design in the Design-Compiler. 
#*******************************************************************************

# set verilog search path. "base_dir" is set in the "synthesis.tcl".
set verilog_search_path        "$base_dir/ \
				$base_dir/fetch \
				$base_dir/decode \
				$base_dir/rename \
				$base_dir/dispatch \ 
				$base_dir/issue \
				$base_dir/execute \ 
				$base_dir/writeback \ 
				$base_dir/memory \
				$base_dir/retire \
				$base_dir/pmems \
				$base_dir/ISA \
				$base_dir/fabscalar" 

set search_path [concat  $search_path $verilog_search_path]
			 	

set fetch 	"FabScalarParam.v SimpleScalar_ISA.v RAS.v BTB.v SelectInst.v \
		 BranchPrediction_2-bit.v FetchStage1.v Fetch1Fetch2.v FetchStage2.v \
		 Fetch2Decode.v CtrlQueue.v"

set decode	"FabScalarParam.v SimpleScalar_ISA.v Decode.v Decode_PISA.v PreDecode_PISA.v \
		 InstructionBuffer.v InstBufRename.v"

set rename      "FabScalarParam.v SimpleScalar_ISA.v SpecFreeList.v RenameMapTable.v Rename.v \
		 RenameDispatch.v"

set dispatch    "FabScalarParam.v SimpleScalar_ISA.v Dispatch.v"


set issueq      "FabScalarParam.v SimpleScalar_ISA.v IssueQFreeList.v IssueQSelect.v \
                 IssueQueue.v issueqRegRead.v RSR.v RegRead.v RegReadExecute.v"
	     

set execute     "FabScalarParam.v SimpleScalar_ISA.v fu0.v fu1.v fu2.v fu3.v \
 		 ForwardCheck.v Simple_ALU.v Ctrl_ALU.v \
	         Complex_ALU.v AGEN.v AgenLsu.v Execute.v"

set lsq         "FabScalarParam.v SimpleScalar_ISA.v DispatchedLoad.v DispatchedStore.v CommitLoad.v \
		 CommitStore.v LoadStoreUnit.v"

set writebk     "FabScalarParam.v SimpleScalar_ISA.v WriteBack.v"

set retire      "FabScalarParam.v SimpleScalar_ISA.v ActiveList.v ArchMapTable.v"

set misc        "FabScalarParam.v SimpleScalar_ISA.v"

set pmem	"FabScalarParam.v SimpleScalar_ISA.v CAM_4R4W.v SRAM.v SRAM_4R4W_AMT.v \
		 SRAM_4R4W_FREELIST.v SRAM_4R8W.v SRAM_8R4W_PIPE.v SRAM_8R4W_PIPE_NEXT.v \
		 SRAM_8R4W_RMT.v"

set top         "FabScalarParam.v SimpleScalar_ISA.v Interface.v FABSCALAR.v"

# start reading RTL files.
read_verilog -rtl $misc
read_verilog -rtl $fetch
read_verilog -rtl $decode
read_verilog -rtl $rename
read_verilog -rtl $dispatch
read_verilog -rtl $issueq
read_verilog -rtl $execute
read_verilog -rtl $lsq
read_verilog -rtl $writebk
read_verilog -rtl $retire
#read_verilog -rtl $pmem
read_verilog -rtl $top
