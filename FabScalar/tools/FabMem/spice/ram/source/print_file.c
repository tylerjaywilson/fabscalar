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
  fprintf(SIM_OUT,".GLOBAL gnd!\n");
  fprintf(SIM_OUT,".GLOBAL vdd_prec\n");
  fprintf(SIM_OUT,".GLOBAL vdd_prec_p\n");
  fprintf(SIM_OUT,".GLOBAL vdd_sense\n");
  fprintf(SIM_OUT,".GLOBAL vdd_sense_p\n");
  fprintf(SIM_OUT,".GLOBAL vdd_wckt\n");
  fprintf(SIM_OUT,".GLOBAL vdd_wckt_p\n");
  fprintf(SIM_OUT,".GLOBAL vdd_decode\n");
  fprintf(SIM_OUT,".GLOBAL vdd_inv\n");
  fprintf(SIM_OUT,".GLOBAL vdd_rinv\n");
  fprintf(SIM_OUT,".GLOBAL vdd_rinv_p\n");
  fprintf(SIM_OUT,".GLOBAL VDD_op\n");
  fprintf(SIM_OUT,".GLOBAL vdd_rdecode\n");
  fprintf(SIM_OUT,".GLOBAL vdd_col\n");
 
  fprintf(SIM_OUT,"\n");
 
  // Setting-up simulation file  
  fprintf(SIM_OUT,".TEMP %d\n",temperature);
  fprintf(SIM_OUT,".OPTION\n");
  fprintf(SIM_OUT,"+    ARTIST=2\n");
  fprintf(SIM_OUT,"+    INGOLD=2\n");
  fprintf(SIM_OUT,"+    PARHIER=LOCAL\n");
  fprintf(SIM_OUT,"+    PSF=2\n");
  fprintf(SIM_OUT,"+    POST\n");
 
  fprintf(SIM_OUT,"\n\n");

  // Include: NMOS PMOS models
  fprintf(SIM_OUT,".include '../library/models_nom/models_nom/NMOS_VTL.in'\n");
  fprintf(SIM_OUT,".include '../library/models_nom/models_nom/PMOS_VTL.in'\n");
  fprintf(SIM_OUT,".include '../library/pex_lib/bitcell_%s.sp'\n", suffix, suffix);
  fprintf(SIM_OUT,".include '../library/general_lib/dual_sense.sp'\n", suffix, suffix);
  fprintf(SIM_OUT,".include '../library/general_lib/misc.sp'\n", suffix, suffix);
  fprintf(SIM_OUT,".include '../library/general_lib/misc_read.sp'\n", suffix, suffix);
  fprintf(SIM_OUT,".include '../library/general_lib/decoder.sp'\n", suffix, suffix);
  fprintf(SIM_OUT,".include 'instance.sp'\n");
  fprintf(SIM_OUT,"\n\n");
 
  fprintf(SIM_OUT,".param clkperiod=%dp clkrise=%dp\n", CLK_PERIOD ,clk_rise);
  fprintf(SIM_OUT,".param setup_time =%dp	setup_time1=%dp\n",clk_setup,SA_TIME);
  fprintf(SIM_OUT,"\n");

  // Voltage supply distribution
  fprintf(SIM_OUT,"Vdd VDD! 0 %f\n",voltage);
  fprintf(SIM_OUT,"Vgnd GND! 0 0\n");
  fprintf(SIM_OUT,"Vdd_prec VDD_prec VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_prec_p VDD_prec_p VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_sense VDD_sense VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_sense_p VDD_sense_p VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_wckt VDD_wckt VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_wckt_p VDD_wckt_p VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_decode VDD_decode VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_inv VDD_inv VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_rinv VDD_rinv VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_rinv_p VDD_rinv_p VDD! 0\n",voltage);
  fprintf(SIM_OUT,"Vdd_rdecode VDD_rdecode VDD! 0\n",voltage);
  fprintf(SIM_OUT,"VDD_op VDD_op VDD! 0 \n",voltage);
  fprintf(SIM_OUT,"VDD_col VDD_col VDD! 0 \n",voltage);
  fprintf(SIM_OUT,"\n");
 
  // -------------------------------------------------------------------------------------------------------------------
  fprintf(SIM_OUT,"*       test vector\n");
  // CLK Signal
  fprintf(SIM_OUT,"Vclk CLK 0 PULSE 0 %f 'setup_time' 'clkrise' 'clkrise' 'clkperiod/2-clkrise' 'clkperiod'\n\n",voltage);

  // Write Operation: 
  // Cycle 1: Data = '1' is written into bitcell 0 in Row 0.
  // Cycle 2: Data = '1' is written into bitcell 0 in Row 1.
  // Cycle 3: Data = '0' is written into bitcell 0 in Row 1.
  // Cycle 4: Write operation is disabled

  // Read Operation: 
  // Cycle1: Dont care
  // Cycle2: Dont care
  // Cycle3: Simultaneous read on all ports on address 0
  // Cycle4: All ports read on address 0, except for the
  //	     port adjacent to the port-1

  // Address bit signals for row decoder
  for(i=1 ; i<= read_ports;i++)
  {
      for(k=0;k<row_bits;k++)
      {
          if(k>=2)
		fprintf(SIM_OUT, "VA%d_%d A%d_%d 0 0\n",i,k,i,k);
          else if(k==1)
		fprintf(SIM_OUT, "VA%d_%d A%d_%d 0 PULSE %f 0 '2*clkperiod' 'clkrise' 'clkrise' '2*clkperiod-clkrise' 'clkperiod*4'\n",i,k,i,k,voltage);
	  else if(i==1 || i>2)
	      	fprintf(SIM_OUT, "VA%d_%d A%d_%d 0 PULSE %f 0 '2*clkperiod' 'clkrise' 'clkrise' '2*clkperiod-clkrise' 'clkperiod*4'\n",i,k,i,k,voltage);
	  else
           	fprintf(SIM_OUT, "VA%d_%d A%d_%d 0 PULSE %f 0 '2*clkperiod' 'clkrise' 'clkrise' 'clkperiod-clkrise' 'clkperiod*4'\n",i,k,i,k,voltage);
      }
  }

  // Sense enable
  for(j=2;j<D/DC;j++)
  {
      for (i = 1; i <= read_ports ; i++)
      {
	if(j==2 ) 
        {
	   if(RUN_NO==2)
	   {
	     fprintf(SIM_OUT,"Vse%d SE%d 0 PULSE 0 %f '2*clkperiod+setup_time1' 'clkrise' 'clkrise' 'clkperiod/2+setup_time-clkrise-setup_time1' 'clkperiod'\n",i,i,voltage);
	   }
           else 
	     fprintf(SIM_OUT,"Vse%d SE%d 0 0 \n",i,i);
	}
        fprintf(SIM_OUT, "Vw%d_%d w%d_%d 0 0\n",i,j,i,j,voltage);   
     }
  }

  // Column Selection
  if(DC==2)
  {
    fprintf(SIM_OUT,"Vc0 COL_SEL 0 PULSE 0 %f '2*clkperiod' 'clkrise' 'clkrise' '2*clkperiod-clkrise' 'clkperiod*4'\n",voltage);
  }
  else if(DC==4)
  {
    fprintf(SIM_OUT,"Vc0 COL_SELa 0 PULSE 0 %f '2*clkperiod' 'clkrise' 'clkrise' '2*clkperiod-clkrise' 'clkperiod*4'\n",voltage);
    fprintf(SIM_OUT,"Vc1 COL_SELb 0 PULSE 0 %f '2*clkperiod' 'clkrise' 'clkrise' '2*clkperiod-clkrise' 'clkperiod*4'\n",voltage);
  }

  fprintf(SIM_OUT,"Vwc%d w%dCOL_SEL 0 PULSE %f 0 '3*clkperiod' 'clkrise' 'clkrise' 'clkperiod-clkrise' 'clkperiod*4'\n",read_ports+1,read_ports+1,voltage);
  for(i=read_ports+2;i<=total_p;i++)
      fprintf(SIM_OUT,"Vwc%d w%dCOL_SEL 0 0 \n",i,i,voltage);

  // Write address bits
  fprintf(SIM_OUT,"\n****** Write Word Line ********\n");
  i=read_ports+1 ; 
  for(k=0;k<row_bits;k++)
  {
      if(k>=2 | (i>read_ports+1))
	fprintf(SIM_OUT, "VA%d_%d A%d_%d 0 0\n",i,k,i,k);
      else if(k==0)
	fprintf(SIM_OUT, "VA%d_%d A%d_%d 0 PULSE 0 %f 'clkperiod' 'clkrise' 'clkrise' '2*clkperiod-clkrise' 'clkperiod*4'\n",i,k,i,k,voltage);
      else
	fprintf(SIM_OUT, "VA%d_%d A%d_%d 0 PULSE 0 %f '3*clkperiod' 'clkrise' 'clkrise' 'clkperiod-clkrise' 'clkperiod*4'\n",i,k,i,k,voltage);
  }

  // Write WL 
  fprintf(SIM_OUT,"\n****** Write Word Line ********\n");
  for(j=0;j<D/DC;j++)
  {
     for (i = read_ports+1; i <= total_p ; i++)
     {
        if((i>read_ports+1) || (j>1))
	fprintf(SIM_OUT, "Vw%d_%d w%d_%d 0 0\n",i,j,i,j,voltage);   
     }
  }

  // Write Enable Signal
  for(i=1;i<=write_ports;i++)
  {
     if(i==1) 
     fprintf(SIM_OUT,"Vw_en%d wr_en%d 0 PULSE %f 0 '3*clkperiod' 'clkrise' 'clkrise' 'clkperiod-clkrise' 'clkperiod*4'\n",i+read_ports,i+read_ports,voltage);
     else
     fprintf(SIM_OUT,"Vw_en%d wr_en%d 0 0 \n",i+read_ports,i+read_ports);
  }
	
  // data in bit 0 & 2
  for(j=1;j<=write_ports;j++)
  {
      for(i=1;i<=W; i=i+2)
      {
        if(j==1)
	fprintf(SIM_OUT,"Vdw%d_%d d_w%d<%d> 0 PULSE 0 %f 0 'clkrise' 'clkrise' '2*clkperiod-clkrise' 'clkperiod*4'\n",j+read_ports,i-1,j+read_ports,i-1,voltage);
        else
	fprintf(SIM_OUT,"Vdw%d_%d d_w%d<%d> 0 0 \n",j+read_ports,i-1,j+read_ports,i-1);
      }
  }

  // data in bit 1 & 3
  for(j=1;j<=write_ports;j++)
  {
     for(i=2;i<=W; i=i+2)
     {
        if(j==1)
        {
	    fprintf(SIM_OUT,"Vdw%d_%d d_w%d<%d> 0 0\n",j+read_ports,i-1,j+read_ports,i-1,voltage);
        }   
         else
	     fprintf(SIM_OUT,"Vdw%d_%d d_w%d<%d> 0 0 \n",j+read_ports,i-1,j+read_ports,i-1);
      }
  }

  fprintf(SIM_OUT,"\n");
  // Measure the sense amp. enable setup time in the run no 1 
  // Due to the decoupled transistor, need to decide between 
  // btl and btlb to measure the 0.9V.
  if(RUN_NO==1)
  {
      fprintf(SIM_OUT,".tran 50p 'clkperiod*4'\n");
      if((Rp==2*Wp && Rp>=4) || (Rp==Wp && Rp>=5))
      {	 
	 if(DC==1) 
	 {  
	     fprintf(SIM_OUT,".meas tran SAtime1 TRIG v(CLK) VAL=0.55 TD=%dp RISE=1 TARG v(b%d_0) VAL=0.9 FALL=1\n",2*CLK_PERIOD,1);
	     fprintf(SIM_OUT,".meas tran SAtime2 TRIG v(CLK) VAL=0.55 TD=%dp RISE=1 TARG v(b%d_0) VAL=0.9 FALL=1\n",3*CLK_PERIOD,1);
	 }
	 else 
         {
	      fprintf(SIM_OUT,".meas tran SAtime1 TRIG v(CLK) VAL=0.55 TD=%dp RISE=1 TARG v(out_rbtl_%d_0) VAL=0.9 FALL=1\n",2*CLK_PERIOD,1);
              fprintf(SIM_OUT,".meas tran SAtime2 TRIG v(CLK) VAL=0.55 TD=%dp RISE=1 TARG v(out_rbtl_%d_0) VAL=0.9 FALL=1\n",3*CLK_PERIOD,1);
	  }
        }
	else
	{
	   if(DC==1)
           {
	        fprintf(SIM_OUT,".meas tran SAtime1 TRIG v(CLK) VAL=0.55 TD=%dp RISE=1 TARG v(bb%d_0) VAL=0.9 FALL=1\n",2*CLK_PERIOD,1);
	        fprintf(SIM_OUT,".meas tran SAtime2 TRIG v(CLK) VAL=0.55 TD=%dp RISE=1 TARG v(bb%d_0) VAL=0.9 FALL=1\n",3*CLK_PERIOD,1);
	   }
	   else 
	   {
		 fprintf(SIM_OUT,".meas tran SAtime1 TRIG v(CLK) VAL=0.55 TD=%dp RISE=1 TARG v(out_rbtlb_%d_0) VAL=0.9 FALL=1\n",2*CLK_PERIOD,1);
                 fprintf(SIM_OUT,".meas tran SAtime2 TRIG v(CLK) VAL=0.55 TD=%dp RISE=1 TARG v(out_rbtlb_%d_0) VAL=0.9 FALL=1\n",3*CLK_PERIOD,1);
	    }
	 }
	 fprintf(SIM_OUT,".meas SAmax PARAM='max(SAtime1,SAtime2)'\n");
	 fprintf(SIM_OUT,".meas tran qtot INTEGRAL i(vdd) FROM=0 TO='4*clkperiod'\n");

	 fprintf(SIM_OUT,".meas tran decode_time TRIG v(CLK) VAL=0.55 TD=%dp RISE=1 TARG v(w1_0_in) VAL=0.55 FALL=1\n",2*CLK_PERIOD,1);
  }
  else
  {	
       fprintf(SIM_OUT,".tran 50p 'clkperiod*4.5'\n");
       fprintf(SIM_OUT,".meas tran tpHL1 TRIG v(CLK) VAL=0.55 TD=%dp RISE=1 TARG v(opdata_%d_0) VAL=0.55 RISE=1\n",2*CLK_PERIOD,1);
       fprintf(SIM_OUT,".meas tran tpHL2 TRIG v(CLK) VAL=0.55 TD=%dp RISE=1 TARG v(opdata_%d_0) VAL=0.55 RISE=1\n",3*CLK_PERIOD,1);
       fprintf(SIM_OUT,".meas retime PARAM='max(tpHL1,tpHL2)+setup_time'\n");

       // Precharge energy consumption
       fprintf(SIM_OUT,".meas tran q_pre1 INTEGRAL i(vdd_prec_p) FROM='setup_time+2.5*clkperiod' TO='setup_time+2.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_pre2 INTEGRAL i(vdd_prec_p) FROM='setup_time+3.5*clkperiod' TO='setup_time+3.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_col1 INTEGRAL i(vdd_col) FROM='setup_time+2*clkperiod' TO='setup_time+2*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_col2 INTEGRAL i(vdd_col) FROM='setup_time+2.5*clkperiod' TO='setup_time+2.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_col3 INTEGRAL i(vdd_col) FROM='setup_time+3*clkperiod' TO='setup_time+3*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_col4 INTEGRAL i(vdd_col) FROM='setup_time+3.5*clkperiod' TO='setup_time+3.5*clkperiod+retime'\n");

       // Sense amplifier energy consumption
       fprintf(SIM_OUT,".meas tran q_sense1 INTEGRAL i(vdd_sense_p) FROM='setup_time+2*clkperiod' TO='setup_time+2*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_sense2 INTEGRAL i(vdd_sense_p) FROM='setup_time+2.5*clkperiod' TO='setup_time+2.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_sense3 INTEGRAL i(vdd_sense_p) FROM='setup_time+3*clkperiod' TO='setup_time+3*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_sense4 INTEGRAL i(vdd_sense_p) FROM='setup_time+3.5*clkperiod' TO='setup_time+3.5*clkperiod+retime'\n");

       // Output buffer energy consumption
       fprintf(SIM_OUT,".meas tran q_op1 INTEGRAL i(vdd_op) FROM='setup_time+2*clkperiod' TO='setup_time+2*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_op2 INTEGRAL i(vdd_op) FROM='setup_time+2.5*clkperiod' TO='setup_time+2.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_op3 INTEGRAL i(vdd_op) FROM='setup_time+3*clkperiod' TO='setup_time+3*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_op4 INTEGRAL i(vdd_op) FROM='setup_time+3.5*clkperiod' TO='setup_time+3.5*clkperiod+retime'\n");

       // Write port Row Decoder energy consumption
       fprintf(SIM_OUT,".meas tran q_decode1b INTEGRAL i(vdd_decode) FROM='setup_time+0.5*clkperiod' TO='setup_time+0.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_decode2b INTEGRAL i(vdd_decode) FROM='setup_time+1.5*clkperiod' TO='setup_time+1.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_decode3b INTEGRAL i(vdd_decode) FROM='setup_time+2.5*clkperiod' TO='setup_time+2.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_decode4b INTEGRAL i(vdd_decode) FROM='setup_time+3.5*clkperiod' TO='setup_time+3.5*clkperiod+retime'\n");

       // Read Row Decoder energy consumption
       fprintf(SIM_OUT,".meas tran q_rdecode1b INTEGRAL i(vdd_rdecode) FROM='setup_time+0.5*clkperiod' TO='setup_time+0.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_rdecode2b INTEGRAL i(vdd_rdecode) FROM='setup_time+1.5*clkperiod' TO='setup_time+1.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_rdecode3b INTEGRAL i(vdd_rdecode) FROM='setup_time+2.5*clkperiod' TO='setup_time+2.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_rdecode4b INTEGRAL i(vdd_rdecode) FROM='setup_time+3.5*clkperiod' TO='setup_time+3.5*clkperiod+retime'\n");

       // Write WL driver energy consumption
       fprintf(SIM_OUT,".meas tran q_inv1a INTEGRAL i(vdd_inv) FROM='setup_time' TO='setup_time+retime'\n");
       fprintf(SIM_OUT,".meas tran q_inv1b INTEGRAL i(vdd_inv) FROM='setup_time+0.5*clkperiod' TO='setup_time+0.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_inv2a INTEGRAL i(vdd_inv) FROM='setup_time+clkperiod' TO='setup_time+clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_inv2b INTEGRAL i(vdd_inv) FROM='setup_time+1.5*clkperiod' TO='setup_time+1.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_inv3a INTEGRAL i(vdd_inv) FROM='setup_time+2*clkperiod' TO='setup_time+2*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_inv3b INTEGRAL i(vdd_inv) FROM='setup_time+2.5*clkperiod' TO='setup_time+2.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_inv4a INTEGRAL i(vdd_inv) FROM='setup_time+3*clkperiod' TO='setup_time+3*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_inv4b INTEGRAL i(vdd_inv) FROM='setup_time+3.5*clkperiod' TO='setup_time+3.5*clkperiod+retime'\n");

       // Read WL driver energy consumption
       fprintf(SIM_OUT,".meas tran q_rinv1a INTEGRAL i(vdd_rinv_p) FROM='setup_time' TO='setup_time+retime'\n");
       fprintf(SIM_OUT,".meas tran q_rinv1b INTEGRAL i(vdd_rinv_p) FROM='setup_time+0.5*clkperiod' TO='setup_time+0.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_rinv2a INTEGRAL i(vdd_rinv_p) FROM='setup_time+clkperiod' TO='setup_time+clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_rinv2b INTEGRAL i(vdd_rinv_p) FROM='setup_time+1.5*clkperiod' TO='setup_time+1.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_rinv3a INTEGRAL i(vdd_rinv_p) FROM='setup_time+2*clkperiod' TO='setup_time+2*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_rinv3b INTEGRAL i(vdd_rinv_p) FROM='setup_time+2.5*clkperiod' TO='setup_time+2.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_rinv4a INTEGRAL i(vdd_rinv_p) FROM='setup_time+3*clkperiod' TO='setup_time+3*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_rinv4b INTEGRAL i(vdd_rinv_p) FROM='setup_time+3.5*clkperiod' TO='setup_time+3.5*clkperiod+retime'\n");

       // Bitcell write energy consumption
       fprintf(SIM_OUT,".meas tran q_bit1a INTEGRAL i(vdd) FROM='setup_time' TO='setup_time+retime'\n");
       fprintf(SIM_OUT,".meas tran q_bit1b INTEGRAL i(vdd) FROM='setup_time+0.5*clkperiod' TO='setup_time+0.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_bit2a INTEGRAL i(vdd) FROM='setup_time+clkperiod' TO='setup_time+clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_bit2b INTEGRAL i(vdd) FROM='setup_time+1.5*clkperiod' TO='setup_time+1.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_bit4a INTEGRAL i(vdd) FROM='setup_time+3*clkperiod' TO='setup_time+3*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_bit4b INTEGRAL i(vdd) FROM='setup_time+3.5*clkperiod' TO='setup_time+3.5*clkperiod+retime'\n");

       // Bitcell read energy consumption
       fprintf(SIM_OUT,".meas tran q_wckt1a INTEGRAL i(vdd_wckt_p) FROM='setup_time' TO='setup_time+retime'\n");
       fprintf(SIM_OUT,".meas tran q_wckt1b INTEGRAL i(vdd_wckt_p) FROM='setup_time+0.5*clkperiod' TO='setup_time+0.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_wckt2a INTEGRAL i(vdd_wckt_p) FROM='setup_time+clkperiod' TO='setup_time+clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_wckt2b INTEGRAL i(vdd_wckt_p) FROM='setup_time+1.5*clkperiod' TO='setup_time+1.5*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_wckt4a INTEGRAL i(vdd_wckt_p) FROM='setup_time+3*clkperiod' TO='setup_time+3*clkperiod+retime'\n");
       fprintf(SIM_OUT,".meas tran q_wckt4b INTEGRAL i(vdd_wckt_p) FROM='setup_time+3.5*clkperiod' TO='setup_time+3.5*clkperiod+retime'\n");

       // Read access time, write time, energy consumption in diff. ckts
       fprintf(SIM_OUT,".meas rtime PARAM='retime'\n");
       fprintf(SIM_OUT,".meas tran wtime TRIG v(CLK) VAL=0.55 TD=%dp RISE=1 TARG v(X%d.q) VAL=0.55 FALL=1\n",2*CLK_PERIOD,1+W*DC);
       fprintf(SIM_OUT,".meas q_pre PARAM='q_pre1+q_pre2'\n");

       fprintf(SIM_OUT,".meas q_col PARAM='q_col1+q_col2+q_col3+q_col4'\n");
       fprintf(SIM_OUT,".meas q_sense PARAM='q_sense1+q_sense2+q_sense3+q_sense4'\n");
       fprintf(SIM_OUT,".meas q_op PARAM='q_op1+q_op2+q_op3+q_op4'\n");
       fprintf(SIM_OUT,".meas q_wdecode PARAM='q_decode1b+q_decode2b'\n");
       fprintf(SIM_OUT,".meas q_wdecode_st PARAM='q_decode4b'\n");
       fprintf(SIM_OUT,".meas q_rdecode PARAM='q_rdecode3b+q_rdecode4b'\n");
       fprintf(SIM_OUT,".meas q_rdecode_st PARAM='q_rdecode1b+q_rdecode2b'\n");

       fprintf(SIM_OUT,".meas q_inv PARAM='q_inv1a+q_inv1b+q_inv2a+q_inv2b'\n");
       fprintf(SIM_OUT,".meas q_inv_st PARAM='q_inv4a+q_inv4b'\n");
       fprintf(SIM_OUT,".meas q_rinv PARAM='q_rinv3a+q_rinv3b+q_rinv4a+q_rinv4b'\n");
       fprintf(SIM_OUT,".meas q_rinv_st PARAM='q_rinv1a+q_rinv1b+q_rinv2a+q_rinv2b'\n");

       fprintf(SIM_OUT,".meas q_rbit PARAM='q_bit4a+q_bit4b'\n");
       fprintf(SIM_OUT,".meas q_wbit PARAM='q_bit1a+q_bit1b+q_bit2a+q_bit2b'\n");

       fprintf(SIM_OUT,".meas q_ckt PARAM='q_wckt1a+q_wckt1b+q_wckt2a+q_wckt2b'\n");
       fprintf(SIM_OUT,".meas q_ckt_st PARAM='q_wckt4a+q_wckt4b'\n");


 }
 fprintf(SIM_OUT,"\n\n");
 
 fprintf(SIM_OUT,".END");

 fflush(SIM_OUT);
 fclose(SIM_OUT);

 return;
}

