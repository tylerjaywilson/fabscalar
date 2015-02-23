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
# Purpose: Generates top level simulation file for the fast simulation.
*******************************************************************************/

#include <stdio.h>
#include <string.h>
#include "parameters.h"

#define MAX_CHAR_LENGTH 50


extern char suffix[50];
extern bitcell **head_array;

// To create top-level simulation file for critical-path simulation
void print_file()
{
  int i = 0;
  int j = 0;
  int k = 0;
  int btl_no = 1;
  unsigned int inst_no = 1;
  unsigned int read_ports  = Rp;
  unsigned int write_ports = Wp;
  unsigned int total_p = Rp + Wp;
  FILE * INVEC;
 
  INVEC = fopen("invec.dat","w");
  fprintf(SIM_OUT,"*       This is the top level file to simulate %d read and %d write ports bitcell. \n",read_ports,write_ports ); 
  fprintf(SIM_OUT,"*       Timestamp: Date =     Time =\n");
  fprintf(SIM_OUT,"*\n");
  fprintf(SIM_OUT,"**************************************************************************************\n\n\n");

  // Defining global variable for all unique voltage sources 
  fprintf(SIM_OUT,".GLOBAL vdd!\n");
  fprintf(SIM_OUT,".GLOBAL gnd!\n\n");
  fprintf(SIM_OUT,".GLOBAL VDD_prec\n");
  fprintf(SIM_OUT,".GLOBAL VDD_prec_p\n");
  fprintf(SIM_OUT,".GLOBAL VDD_wckt\n");
  fprintf(SIM_OUT,".GLOBAL VDD_wckt_P\n");
  fprintf(SIM_OUT,".GLOBAL VDD_SL\n");
  fprintf(SIM_OUT,".GLOBAL VDD_SL_P\n");
  fprintf(SIM_OUT,".GLOBAL VDD_inv\n");
  fprintf(SIM_OUT,".GLOBAL VDD_inv_p\n");
  fprintf(SIM_OUT,".GLOBAL VDD_decode\n");
 
  // Setting-up simulation file  
  fprintf(SIM_OUT,"\n");
  fprintf(SIM_OUT,".TEMP %d\n",temperature);
  fprintf(SIM_OUT,".OPTION\n");
  fprintf(SIM_OUT,"+    ARTIST=2\n");
  fprintf(SIM_OUT,"+    INGOLD=2\n");
  fprintf(SIM_OUT,"+    PARHIER=LOCAL\n");
  fprintf(SIM_OUT,"+    PSF=2\n");
  fprintf(SIM_OUT,"+    POST\n");
 
  fprintf(SIM_OUT,"\n\n");
 
  // Include: NMOS PMOS models
  // fprintf(SIM_OUT,".include '$PDK_DIR/ncsu_basekit/models/hspice/hspice_nom.include'\n");
  fprintf(SIM_OUT,".include '../library/models_nom/models_nom/NMOS_VTL.in'\n");
  fprintf(SIM_OUT,".include '../library/models_nom/models_nom/PMOS_VTL.in'\n");
  fprintf(SIM_OUT,".include '../library/pex_lib/bitcell_%s.sp'\n", suffix, suffix);
  fprintf(SIM_OUT,".include '../library/general_lib/misc.sp'\n", suffix, suffix);
  fprintf(SIM_OUT,".include '../library/general_lib/decoder.sp'\n", suffix, suffix);
  fprintf(SIM_OUT,".include 'instance.sp'\n");
  fprintf(SIM_OUT,"\n\n");
 
  fprintf(SIM_OUT,".param clkperiod=%dp clkrise=%dp\n", CLK_PERIOD ,clk_rise);
  fprintf(SIM_OUT,".param setup_time =%dp	setup_time1=%dp\n",clk_setup,SA_TIME);
  fprintf(SIM_OUT,"\n");

  // Voltage supply distribution
  fprintf(SIM_OUT,"Vdd VDD! 0 %f\n",voltage);
  fprintf(SIM_OUT,"Vdd_prec VDD_prec VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_prec_p VDD_prec_p VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_SL VDD_SL VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_SL_P VDD_SL_P VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_wckt VDD_wckt VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_wckt_P VDD_wckt_P VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_decode VDD_decode VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_inv VDD_inv VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_inv_p VDD_inv_p VDD! 0\n",voltage);
 
  fprintf(SIM_OUT,"Vgnd GND! 0 0\n");
  
  fprintf(SIM_OUT,"\n");
 
  // CLK Signal
  fprintf(SIM_OUT,"Vclk CLK 0 PULSE 0 %f 'setup_time' 'clkrise' 'clkrise' 'clkperiod/2-clkrise' 'clkperiod'\n\n",voltage);
  fprintf(SIM_OUT,"Vml ML_pre 0 PULSE 0 %f 'setup_time' 'clkrise' 'clkrise' 'clkperiod/2-clkrise' 'clkperiod'\n\n",voltage);
 
  // Write Operation: 
  // All Write port except write port-1 is disabled for whole simulation
  // Cycle1: Write the bit pattern 101010... into address 0 (row-0)
  // Cycle2: Write the bit pattern 010101... into address 0 
  // Cycle3: Write port is disabled
  // Cycle4: Write port is disabled

  // Write Address Bits
  fprintf(SIM_OUT,"\n****** Write Address Bits ********\n");
  for(i=1 ; i<= write_ports;i++)
	 for(k=0;k<row_bits;k++)
         {
	      if(i>1)
		fprintf(SIM_OUT, "VA%d_%d A%d_%d 0 %f \n",i,k,i,k,voltage);
	      else
		fprintf(SIM_OUT, "VA%d_%d A%d_%d 0  PULSE 0 %f '2*clkperiod' 'clkrise' 'clkrise' '2*clkperiod-clkrise' 'clkperiod*4'\n",i,k,i,k,voltage); 
         }

  // Write word line
  fprintf(SIM_OUT,"\n****** Write Word Line ********\n");
  for(j=0;j<D;j++)
  {
	for (i = 1; i <= write_ports ; i++)
   	{
       		if( j>=1 || i>1)	
		       fprintf(SIM_OUT, "Vw%d_%d w%d_%d 0 0\n",i,j,i,j,voltage);   
   	}
  }

  // Write Enable Signal
  for(i=1;i<=write_ports;i++)
  {
     if(i==1) 
     fprintf(SIM_OUT,"Vw_en%d wr_en%d 0 PULSE %f 0 '2*clkperiod' 'clkrise' 'clkrise' 'clkperiod-clkrise' 'clkperiod*4'\n",i,i,voltage);
     else
     fprintf(SIM_OUT,"Vw_en%d wr_en%d 0 0 \n",i,i);
  }
	
  // data in bit 0 & 2
  for(j=1;j<=write_ports;j++)
  {
	for(i=1;i<=W; i=i+2)
	{
	     if(j==1)
		fprintf(SIM_OUT,"Vdw%d_%d d_w%d<%d> 0 PULSE 0 %f 0 'clkrise' 'clkrise' 'clkperiod-clkrise' 'clkperiod*4'\n",j,i-1,j,i-1,voltage);
	     else
		fprintf(SIM_OUT,"Vdw%d_%d d_w%d<%d> 0 0 \n",j,i-1,j,i-1);
 	}
  }

  // data in bit 1 & 3
  for(j=1;j<=write_ports;j++)
  {
	for(i=2;i<=W; i=i+2)
	{
	     if(j==1)
		fprintf(SIM_OUT,"Vdw%d_%d d_w%d<%d> 0 PULSE %f 0 0 'clkrise' 'clkrise' 'clkperiod-clkrise' 'clkperiod*4'\n",j,i-1,j,i-1,voltage);
	     else
		fprintf(SIM_OUT,"Vdw%d_%d d_w%d<%d> 0 0 \n",j,i-1,j,i-1);
 	}
  }

  // Read Operation:
  // Cycle 1: On all the read ports, data 111... is broadcasted(don't care case)
  // Cycle 2: On all the read ports, data 111... is broadcasted(don't care case)
  // Cycle 3: Broadcast the bit pattern 0101... on all ports
  // Cycle 4: Broadcast the bit pattern 110101... on port-1 and 0101... on other ports

  // Compare Word Input
  // compare data  bit 0, 2, 4,... 
  for(j=1;j<=read_ports;j++)
  {
	for(i=1;i<=W; i=i+2)
	{
		if(j==1 && i==1)
		fprintf(SIM_OUT,"Vcw%d_%d c_w%d<%d> 0 PULSE %f 0 '2*clkperiod' 'clkrise' 'clkrise' 'clkperiod-clkrise' 'clkperiod*2'\n",j,i-1,j,i-1,voltage);
		else
	        fprintf(SIM_OUT,"Vcw%d_%d c_w%d<%d> 0 PULSE %f 0 '2*clkperiod' 'clkrise' 'clkrise' '2*clkperiod-clkrise' 'clkperiod*4'\n",j,i-1,j,i-1,voltage);
 	}
  }

  // compare data  bit 1, 3, 5,... 
  for(j=1;j<=read_ports;j++)
  {
 	for(i=2;i<=W; i=i+2)
 	{
          fprintf(SIM_OUT,"Vcw%d_%d c_w%d<%d> 0 %f \n",j,i-1,j,i-1,voltage);
	}
  }

  fprintf(SIM_OUT,"\n");
  fprintf(SIM_OUT,".tran 50p 'clkperiod*4.5'\n");
  fprintf(SIM_OUT,".meas tran tp1 TRIG v(clk) VAL=0.55 TD=%dp RISE=1 TARG v(out_ml_1_0) VAL=0.55 RISE=1\n",3*CLK_PERIOD);
  fprintf(SIM_OUT,".meas retime PARAM='tp1+setup_time'\n");

  // Decoder energy consumption 
  fprintf(SIM_OUT,".meas tran q_decode1b INTEGRAL i(vdd_decode) FROM='setup_time+0.5*clkperiod' TO='setup_time+0.5*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_decode2b INTEGRAL i(vdd_decode) FROM='setup_time+1.5*clkperiod' TO='setup_time+1.5*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_decode3b INTEGRAL i(vdd_decode) FROM='setup_time+2.5*clkperiod' TO='setup_time+2.5*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_decode4b INTEGRAL i(vdd_decode) FROM='setup_time+3.5*clkperiod' TO='setup_time+3.5*clkperiod+retime'\n");

  // WL driver energy consumption 
  fprintf(SIM_OUT,".meas tran q_inv1a INTEGRAL i(vdd_inv_p) FROM='setup_time' TO='setup_time+retime'\n");
  fprintf(SIM_OUT,".meas tran q_inv1b INTEGRAL i(vdd_inv_p) FROM='setup_time+0.5*clkperiod' TO='setup_time+0.5*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_inv2a INTEGRAL i(vdd_inv_p) FROM='setup_time+clkperiod' TO='setup_time+clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_inv2b INTEGRAL i(vdd_inv_p) FROM='setup_time+1.5*clkperiod' TO='setup_time+1.5*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_inv3a INTEGRAL i(vdd_inv_p) FROM='setup_time+2*clkperiod' TO='setup_time+2*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_inv3b INTEGRAL i(vdd_inv_p) FROM='setup_time+2.5*clkperiod' TO='setup_time+2.5*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_inv4a INTEGRAL i(vdd_inv_p) FROM='setup_time+3*clkperiod' TO='setup_time+3*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_inv4b INTEGRAL i(vdd_inv_p) FROM='setup_time+3.5*clkperiod' TO='setup_time+3.5*clkperiod+retime'\n");

  // Write bitcell energy consumption
  fprintf(SIM_OUT,".meas tran q_bit1a INTEGRAL i(vdd) FROM='setup_time' TO='setup_time+retime'\n");
  fprintf(SIM_OUT,".meas tran q_bit1b INTEGRAL i(vdd) FROM='setup_time+0.5*clkperiod' TO='setup_time+0.5*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_bit2a INTEGRAL i(vdd) FROM='setup_time+clkperiod' TO='setup_time+clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_bit2b INTEGRAL i(vdd) FROM='setup_time+1.5*clkperiod' TO='setup_time+1.5*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_bit3a INTEGRAL i(vdd) FROM='setup_time+2*clkperiod' TO='setup_time+2*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_bit3b INTEGRAL i(vdd) FROM='setup_time+2.5*clkperiod' TO='setup_time+2.5*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_bit4a INTEGRAL i(vdd) FROM='setup_time+3*clkperiod' TO='setup_time+3*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_bit4b INTEGRAL i(vdd) FROM='setup_time+3.5*clkperiod' TO='setup_time+3.5*clkperiod+retime'\n");

  // Write ckt energy consumption
  fprintf(SIM_OUT,".meas tran q_wckt1b INTEGRAL i(vdd_wckt_p) FROM='setup_time+0.5*clkperiod' TO='setup_time+0.5*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_wckt2b INTEGRAL i(vdd_wckt_p) FROM='setup_time+1.5*clkperiod' TO='setup_time+1.5*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_wckt3b INTEGRAL i(vdd_wckt_p) FROM='setup_time+2.5*clkperiod' TO='setup_time+2.5*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_wckt4b INTEGRAL i(vdd_wckt_p) FROM='setup_time+3.5*clkperiod' TO='setup_time+3.5*clkperiod+retime'\n");

  // ML precharte energy consumption
  fprintf(SIM_OUT,".meas tran q_pre1b INTEGRAL i(vdd_prec_p) FROM='setup_time+2.5*clkperiod' TO='setup_time+2.5*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_pre2b INTEGRAL i(vdd_prec_p) FROM='setup_time+3.5*clkperiod' TO='setup_time+3.5*clkperiod+retime'\n");

  // SL driver energy consumption
  fprintf(SIM_OUT,".meas tran q_SL1a INTEGRAL i(vdd_sl_p) FROM='setup_time' TO='setup_time+retime'\n");
  fprintf(SIM_OUT,".meas tran q_SL1b INTEGRAL i(vdd_sl_p) FROM='setup_time+0.5*clkperiod' TO='setup_time+0.5*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_SL2a INTEGRAL i(vdd_sl_p) FROM='setup_time+clkperiod' TO='setup_time+clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_SL2b INTEGRAL i(vdd_sl_p) FROM='setup_time+1.5*clkperiod' TO='setup_time+1.5*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_SL3a INTEGRAL i(vdd_sl_p) FROM='setup_time+2*clkperiod' TO='setup_time+2*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_SL3b INTEGRAL i(vdd_sl_p) FROM='setup_time+2.5*clkperiod' TO='setup_time+2.5*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_SL4a INTEGRAL i(vdd_sl_p) FROM='setup_time+3*clkperiod' TO='setup_time+3*clkperiod+retime'\n");
  fprintf(SIM_OUT,".meas tran q_SL4b INTEGRAL i(vdd_sl_p) FROM='setup_time+3.5*clkperiod' TO='setup_time+3.5*clkperiod+retime'\n");

  // Read access time, write time, energy consumption in diff. ckts
  fprintf(SIM_OUT,".meas tran ratime TRIG v(clk) VAL=0.55 TD=%dp RISE=1 TARG v(out_ml_1_0) VAL=0.55 RISE=1\n",3*CLK_PERIOD); 
  fprintf(SIM_OUT,".meas tran wtime TRIG v(clk) VAL=0.55 TD=%dp RISE=1 TARG v(X1.d) VAL=0.55 FALL=1\n",CLK_PERIOD);
  fprintf(SIM_OUT,".meas qwbit PARAM='q_bit1a+q_bit1b+q_bit2a+q_bit2b'\n");
  fprintf(SIM_OUT,".meas qrbit PARAM='q_bit3a+q_bit3b+q_bit4a+q_bit4b'\n");
  fprintf(SIM_OUT,".meas q_decode PARAM='q_decode1b +q_decode2b '\n");
  fprintf(SIM_OUT,".meas q_decode_st PARAM='q_decode3b+q_decode4b'\n");
  fprintf(SIM_OUT,".meas q_inv PARAM='q_inv1a +q_inv1b +q_inv2a +q_inv2b '\n");
  fprintf(SIM_OUT,".meas q_inv_st PARAM='q_inv3a+q_inv3b+q_inv4a+q_inv4b'\n");
  fprintf(SIM_OUT,".meas q_sl PARAM='q_SL1a + q_SL1b + q_SL2a + q_SL2b + q_SL3a+ q_SL3b + q_SL4a+ q_SL4b'\n");
  fprintf(SIM_OUT,".meas q_pre PARAM='q_pre2b'\n");
  fprintf(SIM_OUT,".meas q_pre_st PARAM='q_pre1b'\n");
  fprintf(SIM_OUT,".meas q_wckt PARAM='q_wckt1b+q_wckt2b'\n");
  fprintf(SIM_OUT,".meas q_wckt_st PARAM='q_wckt3b+q_wckt4b'\n");
 
  fprintf(SIM_OUT,"\n");
  fprintf(SIM_OUT,".END");
  fflush(SIM_OUT);
  fclose(SIM_OUT);
 
  return;
}


