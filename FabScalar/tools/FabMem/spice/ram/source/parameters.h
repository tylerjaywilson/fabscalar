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

#define SIZE 4
#define cin 0.987
#define HEIGHT 0.88
#define THICK 0.14
#define WIDTH 0.07
#define SENSE_FACTOR 0.2272
#define CLK_PERIOD  6000

#define NMOS_H 0.2
#define NMOS_W 0.37
#define PITCH_M2 0.14
#define WIDTH4T 0.56
#define WIDTH_FINGER2 0.56
#define PC_HEIGHT 0.34 //Precharge CKT height = NMOS height + pitch of metal 2 = 0.2 + 0.14
#define W_channel 0.09


#ifndef _PARAMETERS_H
#define _PARAMETERS_H

/*********************************************************************
 * variables defined for reading command line arguments.
 ********************************************************************/
extern unsigned int FIFO;
extern unsigned int D;
extern unsigned int W;
extern unsigned int Rp;
extern unsigned int Wp;
extern unsigned int T;
extern unsigned int DC;
extern unsigned int SA_TIME;

/*********************************************************************
 * file pointer defined for writing top level simulation file.
 ********************************************************************/
extern FILE *SIM_OUT;
extern char simulation_file[];

/*********************************************************************
 * define the unit for time, temperature and voltage used for the 
 * spice simulation.
 ********************************************************************/
extern char unit_time;
extern char unit_teperature;
extern char unit_voltage;
extern char unit_cap;



extern unsigned int clk_rise;
extern unsigned int clk_setup;
extern char clk_name[];

extern int temperature;
extern float voltage;

extern char sense_en[];

extern unsigned int bitline_cap;
extern unsigned int wordline_cap;
extern unsigned int output_cap;

extern unsigned int sim_time;

extern unsigned int row_bits ;
extern unsigned int RUN_NO;

typedef struct{
 int valid;
 unsigned int *wl_map;
 unsigned int *btl_map;
} bitcell;



extern unsigned int instance_no;
extern int no_of_stack;
extern double cint;
extern int STACK_LEN;
extern float BIT_HEIGHT;
extern float BIT_HEIGHT_DATA[8];
extern int col_array[8];
extern int pl_col_trans[8];

//Final Result is stored in following arrays
extern int result_index;	
extern double area_data[3];
extern double rtime_data[3];
extern double wtime_data[3];
extern double renergy_data[3];
extern double wenergy_data[3];
extern double bitenergy_data[3];
extern double EDP_data[3];
extern double dec_time;
extern double height_ram[3];
extern double width_ram[3];
extern int    dc_final;	
#endif

