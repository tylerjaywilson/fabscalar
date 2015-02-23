#!/usr/bin/perl
use strict;
use warnings;

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
# Purpose: This script generates the Makefile to run simulation.
################################################################################

require "../path.pl";

my $version = "1.0";

my $core_name = &returnCoreName();

my $scriptName;
my $moduleName;
my $outputFileName;
my $minEssentialCLIArgs = 3;

my $dispatchWidth = 4;
my $typesOfFUs = 4; # HARDWIRED!
my @fuNo;   # Number of execute ways of each instruction type (they are always adjacent)
my @whereFU;  # A two dimensional array with 4 rows (for each instruction type), telling which ways support that type.
my $issueWidth;
my $retireWidth;

my $printHeader = 0;
my $supportBA = 0;

my $i;
my $j;
my $temp;
my $temp2;
my $tempCount;
my $tempStr;
my @tempArr;

sub fatalUsage
{
	print "\n";
	print "Usage: perl $scriptName -d <dispatch_width> -i <issue_width> -r <retire_width> [-ba] [-m] [-v] [-h]\n";
	print "\t-ba: Supports Block Ahead Fetch Unit\n";
	print "\t-m: Add header\n";
	print "\t-v: Print version and exit\n";
	print "\t-h: Show usage help and exit\n";
	exit;
}

sub log2 
{
	my $n = shift;
	return(log($n)/log(2));
}

### START HERE ###

$scriptName = $0;

my $essentialCLIArgs = 0;
while(@ARGV)
{
	$_ = shift;
	if(/^-d$/) 
	{
		$dispatchWidth = shift;
		$essentialCLIArgs++;
	}
	elsif(/^-r$/) 
	{
		$retireWidth = shift;
		$essentialCLIArgs++;
	}
	elsif(/^-i$/) 
	{
		$issueWidth = shift;
		$essentialCLIArgs++;
	}	
	elsif(/^-m$/)
	{
		$printHeader = 1;
	}	
	elsif(/^-ba$/)
	{
		$supportBA = 1;
	}	
	elsif(/^-h$/)
	{
		&fatalUsage();
	}
	elsif(/^-v$/)
	{
		print "$scriptName version $version\n";
		exit;
	}
	else
	{
		print "\nError: Unrecognized argument $_.\n";
		&fatalUsage();
	}
}

if($essentialCLIArgs < $minEssentialCLIArgs)
{
	print "\nError: Too few inputs\n";
	&fatalUsage();
}

	print <<LABEL;
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
# Purpose: This is a Makefile for running simulation!!
################################################################################

LABEL

print <<LABEL;
CURRENT    = ../..
CORE_NAME  = $core_name

FETCH    = \$(CURRENT)/../cores/\$(CORE_NAME)/fetch/*.v

LABEL

print<<LABEL;

DECODE   = \$(CURRENT)/../cores/\$(CORE_NAME)/decode/*.v


RENAME   = \$(CURRENT)/../cores/\$(CORE_NAME)/rename/*.v


DISPATCH = \$(CURRENT)/../cores/\$(CORE_NAME)/dispatch/*.v

LABEL
my $max;
my $PRFWidth = 2*$issueWidth;
my $RMT_rd = 2*$dispatchWidth;

if($retireWidth>$dispatchWidth)
{
        $max = $retireWidth;
}
else
{
        $max = $dispatchWidth;
}


print <<LABEL;
ISSUEQ	 = \$(CURRENT)/../cores/\$(CORE_NAME)/issue/*.v

EXECUTE	 = \$(CURRENT)/../cores/\$(CORE_NAME)/execute/*.v

WRITEBK  = \$(CURRENT)/../cores/\$(CORE_NAME)/writeback/*.v

LSQ	 = \$(CURRENT)/../cores/\$(CORE_NAME)/memory/*.v


RETIRE   = 	   \$(CURRENT)/../cores/\$(CORE_NAME)/retire/*.v


MISC     = \$(CURRENT)/../cores/\$(CORE_NAME)/FabScalarParam.v \\
	   \$(CURRENT)/../cores/\$(CORE_NAME)/ISA/SimpleScalar_ISA.v


PMEM	 = \$(CURRENT)/../cores/\$(CORE_NAME)/pmems/*.v

TOP      = \$(CURRENT)/../cores/\$(CORE_NAME)/fabscalar/*.v


# Combines all the files
#
FILES    = \$(MISC) \$(PMEM) \$(FETCH) \$(DECODE) \$(RENAME) \$(DISPATCH) \\
	   \$(ISSUEQ) \$(EXECUTE) \$(WRITEBK) \$(RETIRE) \$(TOP) \$(LSQ)

# SIMFILES = loader.cc memory.cc misc.cc endian.cc regs.cc global_vars.cc 
# SIMFILES = \$(CURRENT)/func_sim.cc \$(CURRENT)/loader.cc \$(CURRENT)/memory.cc \$(CURRENT)/misc.cc \\
# 	   \$(CURRENT)/endian.cc \$(CURRENT)/regs.cc \$(CURRENT)/global_vars.cc \$(CURRENT)/arch.cc \\
# 	   \$(CURRENT)/info.cc \$(CURRENT)/ss.cc \$(CURRENT)/syscall.cc \$(CURRENT)/main_misc.cc
# SIMFILES = 

VPI_DIR = \$(CURRENT)/functional-sim/vpi
VPI_INCDIR = \$(VPI_DIR)/include
VPI_SRCDIR = \$(VPI_DIR)/src
VPI_FILES = \$(VPI_SRCDIR)/initializeSim.cpp \$(VPI_SRCDIR)/readOpcode.cpp \$(VPI_SRCDIR)/readOperand.cpp  \\
	    \$(VPI_SRCDIR)/readUnsignedByte.cpp \$(VPI_SRCDIR)/readSignedByte.cpp \$(VPI_SRCDIR)/readUnsignedHalf.cpp \$(VPI_SRCDIR)/readSignedHalf.cpp \\
	    \$(VPI_SRCDIR)/readWord.cpp \$(VPI_SRCDIR)/writeByte.cpp \$(VPI_SRCDIR)/writeHalf.cpp \$(VPI_SRCDIR)/writeWord.cpp \\
	    \$(VPI_SRCDIR)/getArchRegValue.cpp \$(VPI_SRCDIR)/copyMemory.cpp \$(VPI_SRCDIR)/getRetireInstPC.cpp \$(VPI_SRCDIR)/getArchPC.cpp \\
	    \$(VPI_SRCDIR)/global_vars.cc \$(VPI_SRCDIR)/VPI_global_vars.cc \$(VPI_SRCDIR)/veri_memory.cc \\
	    \$(VPI_SRCDIR)/read_config.cc \\
	    \$(VPI_SRCDIR)/getPerfectNPC.cpp \\
	    \$(VPI_SRCDIR)/funcsimRunahead.cpp \\
	    \$(VPI_SRCDIR)/handleTrap.cpp \\
	    \$(VPI_SRCDIR)/resumeTrap.cpp \\
	    \$(VPI_SRCDIR)/register_systf.cpp
# VPIFILES = register_systf.cpp

#NCSC_RUNARGS = -ncsc_runargs "-I/usr/include -I/usr/local/include -I. -DSIM_LINUX -DBYTES_LITTLE_ENDIAN -DWORDS_LITTLE_ENDIAN -L. -lSS_forVlog" 
NCSC_RUNARGS = -ncsc_runargs "-DSIM_LINUX -I/usr/include -I/usr/local/include -I\$(CURRENT)/functional-sim/include -I\$(VPI_INCDIR) -L\$(CURRENT) -L\$(CURRENT)/functional-sim/libss-vpi/lib -lSS_VPI" 

NCSC_DEBUG_RUNARGS = -ncsc_runargs "-DVPI_DEBUG -DSIM_LINUX -I/usr/include -I/usr/local/include -I\$(CURRENT)/include -I\$(VPI_INCDIR) -L\$(CURRENT) -L\$(CURRENT)/functional-sim/libss-vpi/lib -lSS_VPI" 

compile:
	ncvlog -message \$(FILES)


run_nc: 
	clear
	rm -rf *.o libvpi.so INCA_libs *.log *.sl work irun.* results     
	mkdir results
	irun -access rwc -l run.log -top worklib.simulate:v \$(NCSC_RUNARGS) \$(FILES) \$(VPI_FILES) -loadvpi :initializeSim.initializeSim,readOpcode_calltf.readOpcode_calltf,readOperand_calltf.readOperand_calltf

run_nc_g: 
	rm -rf *.o libvpi.so INCA_libs *.log *.sl work irun.*      
	irun -access rwc -gui -l run.log -top worklib.simulate:v \$(NCSC_RUNARGS) \$(FILES) \$(VPI_FILES) -loadvpi :initializeSim.initializeSim,readOpcode_calltf.readOpcode_calltf,readOperand_calltf.readOperand_calltf


clean:
	rm -rf *.o libvpi.so INCA_libs *.log *.sl work irun.* results/* waves.shm* top outfile .simvision out.*
LABEL

