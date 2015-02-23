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
*******************************************************************************/

#include <stdio.h>
//#include "parameters.h"

/*********************************************************************
 * variables defined for reading command line arguments.
 ********************************************************************/

unsigned int FIFO;
unsigned int D;
unsigned int W;
unsigned int Rp;
unsigned int Wp;
unsigned int T;
unsigned int DC;
unsigned int SA_TIME;

/*********************************************************************
 * file pointer defined for writing top level simulation file.
 ********************************************************************/
FILE *SIM_OUT;
char simulation_file[] = "simulate_";


/*********************************************************************
 * define the unit for time, temperature and voltage used for the 
 * spice simulation.
 ********************************************************************/
char unit_time = 'p';       // in pico-seconds
char unit_temperature = 'c'; // in degree celcius
char unit_voltage = 'v';    // in volt
char unit_cap  = 'f';       // in femto-farad



unsigned int clk_pd = 1000;
unsigned int clk_rise   = 20;
unsigned int clk_setup  = 50;
char clk_name[] = "i_clk";

int temperature = 25;
float voltage = 1.1;

char sense_en[] = "n_se";

unsigned int bitline_cap  = 20;
unsigned int wordline_cap = 5;
unsigned int output_cap   = 5;

unsigned int sim_cycle = 3;
unsigned int row_bits = 1;
unsigned int RUN_NO ;
/* Technology related parameters are defined here.
 */




unsigned int instance_no = 1;
/*  Total No. of Stacks of bitcell in array */
//LAYOUT SPECIFIC DATA
int no_of_stack;
double cint;
int STACK_LEN;
float BIT_HEIGHT;
float BIT_HEIGHT_DATA[8] = {1.28,1.6475,1.83,2.4625,3.0975,3.2,3.73,4.1325};
int col_array[8]={2,4,3,4,5,3,4,4};
int pl_col_trans[8] ={2,2,3,4,3,3,3,4};

//Final Result is stored in following arrays
int result_index=0;	
double area_data[3];
double rtime_data[3]= {1e10, 1e10, 1e10};
double wtime_data[3];
double renergy_data[3];
double wenergy_data[3];
double bitenergy_data[3];
double EDP_data[3] = {1e10, 1e10, 1e10};
double height_ram[3];
double width_ram[3];
int    dc_final;

// For FIFO decoded time should be removed
double dec_time = 0;
