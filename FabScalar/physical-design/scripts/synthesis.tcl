#*******************************************************************************
#                        NORTH CAROLINA STATE UNIVERSITY
#
#                               FabScalar Project
#
# FabScalar Copyright (c) 2007-2011 by Niket K. Choudhary, Salil Wadhavkar,
# and Eric Rotenberg.  All Rights Reserved.
#
# This is a pre-release version.  It must not be redistributed at this time.
#
# Purpose: This is a sample Design-Compiler script to synthesize a FabScalar
#	   generated core.
#*******************************************************************************

date
set base_dir "../cores/core-t"

# setup name of the clock in your design.
set clkname clock

# set variable "modname" to the name of topmost module in design
set modname FABSCALAR


#set the number of digits to be used for delay results
set report_default_significant_digits 4

set filename_log_file ganga.log

source scripts/read_design.tcl

current_design $modname

#-------------------------------------------------------------------------------
# Set the synthetic library variable to enable use of desigware blocks.
#-------------------------------------------------------------------------------
 set synthetic_library [list dw_foundation.sldb]
 
 set target_library NangateOpenCellLibrary_typical_conditional_nldm_nowl.db
 set link_library   [concat  $target_library $synthetic_library]

#-------------------------------------------------------------------------------
# Specify a 2000ps clock period with 50% duty cycle and a skew of 10ps. 
#-------------------------------------------------------------------------------
 set CLK_PER  2
 set REDUCE   0.01
 set CLK_SKEW 0.01
 create_clock -name $clkname -period $CLK_PER -waveform "0 [expr $CLK_PER / 2]" $clkname
 set_clock_uncertainty $CLK_SKEW $clkname

 set DFF_CKQ 0.010
 #set IP_DELAY [expr 0.1 + $DFF_CKQ]
 set IP_DELAY $DFF_CKQ
 set_input_delay $IP_DELAY -clock $clkname [remove_from_collection [all_inputs] $clkname]

 set DFF_SETUP 0.015
 set OP_DELAY $DFF_SETUP
 set_output_delay $OP_DELAY -clock $clkname [all_outputs]

 set_max_area 0
#-------------------------------------------------------------------------------
# This command prevents feedthroughs from input to output and avoids assign 
# statements.                 
#------------------------------------------------------------------------------- 
 set_fix_multiple_port_nets -all -buffer_constants [get_designs]


#-------------------------------------------------------------------------------
# "set_max_delay" is a Design-Compiler command to constrain timing paths in the 
# design. This command can be used to virtually specify timing slack on paths
# from or to a blackbox.
# For memory structures in the design, we extract their timing numbers from
# FabMem and use them to constrain timing path going to or coming from a memory
# interface. 
# Alternatively, a memory structure can be synthesized using flip-flops but it 
# would not be cycle-time friendly.
#-------------------------------------------------------------------------------
 set path_delay1 0.5
 set path_delay2 0.4
 
 set_max_delay [expr $CLK_PER-$path_delay1] -from [find pin -hierarchy "btbTag/*_o*"]
 set_max_delay [expr $CLK_PER-$path_delay2] -to   [find pin -hierarchy "btbTag/*_i*"]
 set_max_delay [expr $CLK_PER-$path_delay1] -from [find pin -hierarchy "btbData/*_o*"]
 set_max_delay [expr $CLK_PER-$path_delay2] -to   [find pin -hierarchy "btbData/*_i*"]

 set path_delay3 0.5
 set path_delay4 0.4 
 set_max_delay [expr $CLK_PER-$path_delay3] -from [find pin -hierarchy "CounterTable/*_o*"]
 set_max_delay [expr $CLK_PER-$path_delay4] -to   [find pin -hierarchy "CounterTable/*_i*"]


 set path_delay5 0.45
 set path_delay6 0.49
 set_max_delay [expr $CLK_PER-$path_delay5] -from [find pin -hierarchy "instBuffer/*_o*"]
 set_max_delay [expr $CLK_PER-$path_delay6] -to   [find pin -hierarchy "instBuffer/*_i*"]

 set path_delay11 0.81
 set path_delay12 0.6
 set_max_delay [expr $CLK_PER-$path_delay11] -from [find pin -hierarchy "PhyRegFile/*_o*"]
 set_max_delay [expr $CLK_PER-$path_delay12] -to   [find pin -hierarchy "PhyRegFile/*_i*"]

 
 set path_delay13 0.409
 set path_delay14 0.305
 set_max_delay [expr $CLK_PER-$path_delay13] -from [find pin -hierarchy "activeList/*_o*"]
 set_max_delay [expr $CLK_PER-$path_delay14] -to   [find pin -hierarchy "activeList/*_i*"]
 set_max_delay [expr $CLK_PER-$path_delay13] -from [find pin -hierarchy "ctrlActiveList/*_o*"]
 set_max_delay [expr $CLK_PER-$path_delay14] -to   [find pin -hierarchy "ctrlActiveList/*_i*"]
 set_max_delay [expr $CLK_PER-$path_delay13] -from [find pin -hierarchy "ldViolateVector/*_o*"]
 set_max_delay [expr $CLK_PER-$path_delay14] -to   [find pin -hierarchy "ldViolateVector/*_i*"]

 set path_delay15 0.53
 set path_delay16 0.53
 set_max_delay [expr $CLK_PER-$path_delay15] -from [find pin -hierarchy "AMT/*_o*"]
 set_max_delay [expr $CLK_PER-$path_delay16] -to   [find pin -hierarchy "AMT/*_i*"]


#-------------------------------------------------------------------------------
# currently instruction retiring is non-pipeline i.e. reading from ActiveList + 
# reading from AMT + writing in SpecFreeList happen in one cycle. 
# This makes it timing critical path although microarchitecturally it is 
# non-critical.
#-------------------------------------------------------------------------------
 set_false_path -through [find pin -hierarchy "writebk/ctrl*_o*"]
 set_false_path -through [find pin -hierarchy "activeList/commit*_o*"]
 set_false_path -through [find pin -hierarchy "activeList/recover*_o*"]
 set_false_path -through [find pin -hierarchy "execute/fuPacket*1_i*"]
 set_false_path -through [find pin -hierarchy "rename/branchCount_i*"]
 set_false_path -through [find pin -hierarchy "fu1/*"]


 replace_synthetic -ungroup

 uniquify

 check_design > ./data/check_design.rpt

 link 

#-------------------------------------------------------------------------------
# Following synthesizes the design.
#-------------------------------------------------------------------------------
 compile -map_effort low
 date

#-------------------------------------------------------------------------------
# Following generates synthesized design netlist and constraint file for 
# place&route.
#-------------------------------------------------------------------------------
 report_area > ./data/area.rpt
 report_power 
 write -hierarchy -f verilog -o ./data/FABSCALAR.v
 write_sdc ./data/FABSCALAR.sdc
 
