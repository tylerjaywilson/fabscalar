#!/usr/bin/bash
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
# Purpose:
# This file is used to specify the FabScalar installation directory and the
# name of the core being generated.
################################################################################


my $FABSCALAR_INSTALLATION_DIR = "/root/Desktop/archProj";
my $core_name = "core-test";

sub returnPath()
{
        my $PATH = "$FABSCALAR_INSTALLATION_DIR/FabScalar/cores/$core_name";
        return $PATH;
}

sub returnCoreName()
{
  	return $core_name;
}

1;
