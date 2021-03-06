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

/*******************************************************************************
# Purpose       : Fast Simulation (Only Critical Path) for multiported SRAM
#                 Create the one ROW and one Collumn for the Memory Array
# Varieties     : 1R1W to 8R8W
#		: 2R1W to 16R8W
#
*******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "regfile_sim.h"
#include "parameters.h"

bitcell **head_array;		// Bitcell structure created which instantiates
                                // pex extracted bitcell in the instance.sp

double coup_cap_cal(double spacing,double len);
				// Coupling cap. calculation for the bitline 
double intrinsic_cap(double gap,double len);
				// Intrinsic cap. calculation for the bitline 
double area(int Depth,int Width,int read_p,int write_p,int DC,int buffer);
				// area() calculates the area to be cosumed by
				// the intended CAM considering all the peripheral
				// and their routing, too.

int max_couple ();		// max_couple() considers the wors-case capacitance can 
				// be present on the word-line and accourding to this value
				// it decides number of inverters in a chain ( WL driver).
				// max_couple() is not called in this version and WL driver
				// is kept to be fixed,3, inverters to match with results
				// from layout generation tool .

void result();			// result() extracts the measuremets from the .mt0 file
				// and perform some calculation to calculate total
				// dynamic and static energy consumption and then writes
				// results in to the file specified in command-line argument
				// inputs.

/**********************************************************************
 * Function: main
 * Description: Main function for spice level Register File simulator.
 *********************************************************************/
int main(int argc, char *argv[])
{

 char exe_str[200] = "hspice simulate_2r1w.sp>! simulate_2r1w.lis";
				// exe_str is the string to be used in the system-calls.
 char cat_str[200];
				// To display the output in simulate_mRmW.txt on terminal.
 char *PATH;
 int i, j, min;
 double min_time=2e10;
 FILE * result_ptr;
 if(argc != (MAX_COMMAND_ARGS+1))
 {
   fprintf(stderr,"\nERROR: Incorrect input values\n");
   fprintf(stderr,"\nUsage:\n");	
   fprintf(stderr,"\t<F>  - 1=FIFO or 0=SRAM (in nano-meter)\n");
   fprintf(stderr,"\t<D>  - Register File Depth (in power of 2)\n");
   fprintf(stderr,"\t<W>  - Width of each Word in Register File (in bits)\n"); 
   fprintf(stderr,"\t<Rp> - Total Read Ports in Register File\n");
   fprintf(stderr,"\t<Wp> - Total Write Ports in Register File\n"); 
   fprintf(stderr,"\t<T>  - Temparature (in Celsius) \n");
   fprintf(stderr,"\t<FILENAME>  - FILENAME with the full path\n");
   exit(0);
 }

  // Read the command line arguments into variables. 
  FIFO  = atoi(argv[1]);
  D  = atoi(argv[2]);
  W  = atoi(argv[3]);
  Rp = atoi(argv[4]);
  Wp = atoi(argv[5]);
  DC = 1;
  T  = 45 ;
  temperature = atoi(argv[6]);
  PATH = argv[7];
  result_ptr = fopen(PATH,"w");
  if(result_ptr == NULL){
	printf("\n Result file in <PATH> can not be opened for writing... !!!\n");
	exit(0);
  }

  // Print the Register File configuration on the console. 
  fprintf(stdout,"\n************* Register File Parameters *************\n");
  fprintf(stdout,"\tRegister File Depth (in the power of 2): %d\n",D);
  fprintf(stdout,"\tWidth of each Word in Register File (in bits): %d\n",W);
  fprintf(stdout,"\tTotal Read Ports in Register File: %d\n",Rp);
  fprintf(stdout,"\tTotal Write Ports in Register File: %d\n",Wp);
  fprintf(stdout,"\tDegree of Column Muxing: %d\n",DC);
  fprintf(stdout,"\tProcess Technology: %d\n",T);
  fprintf(stdout,"\tTemparature (C) : %d\n",temperature);

  // Generate the name of top level spice simulation file. 
  strcat(strcat(strcat(strcpy(suffix,argv[4]),"r"),argv[5]),"w");
  strcat(strcat(strcat(strcat(simulation_file,argv[4]),"r"),argv[5]),"w.sp");

  fprintf(stdout,"\nTop Level Simulation File Name: %s\n", simulation_file);

  // start with degree of column muxing of 1
  DC=1;
  for(j=1;j<=3;j++)
  {
	// Initial sense amp. enable time is kept 500ps
	// Then according to first run measurement, in which time taken
	// by read bitline to reach 0.9V is measured that will be
	// sense amp. enable time
	SA_TIME=500;

	// To compensate for the set-up time for the address-line to the input of
	// dynamic row-decoder before the clock-edge.
	if(D/DC>=128) clk_setup = 150 + Wp*15;
	else if(D/DC>=64) clk_setup = 100 + Wp*15;
	else clk_setup = 50 + Wp * 15;
  
	// start with the instance # as 1
	instance_no = 1;

	// First run to decide sense amp. enable time
	RUN_NO=1;
	fprintf(stdout,"\nSimulating for the Column Mux. Degree = %d \n",DC);
	
	// To create critical simulation netlist in instance.sp
	create_array(D,W,Rp,Wp);  
	if((SIM_OUT = fopen(simulation_file,"w")) == NULL)
	{
	    fprintf(stderr,"\nERROR: Opening file %s:\n", simulation_file);
	    exit(0);	 	
	}  

	// To create top-level simulation file for critical-path simulation
	print_file();
	sprintf(exe_str,"hspice simulate_%dr%dw.sp > simulate_%dr%dw.lis",Rp,Wp,Rp,Wp);
	sprintf(cat_str,"cat simulate_%dr%dw.txt",Rp,Wp);
	i=  system(exe_str);
	if (i != 0)  printf("\nSIMULATION FAILED.... :-( \n");
	// Take measurements from HSPICE .ms0 file
	result();
	sprintf(cat_str,"rm -rf simulate_*.ic0 simulate_*.tr0 simulate_*.lis",Rp,Wp);
	system(cat_str);
	
	// Second run with actual sense. amp. enable time
	RUN_NO=2;
	// start with the instance # as 1
	instance_no = 1;
	create_array(D,W,Rp,Wp);
	if((SIM_OUT = fopen(simulation_file,"w")) == NULL)
	{
	  fprintf(stderr,"\nERROR: Opening file %s:\n", simulation_file);
	  exit(0);	 	
	}  
	
	print_file();
	i=  system(exe_str);
	if (i != 0)  printf("\nSIMULATION FAILED.... :-( \n");
	result();
	DC = DC * 2;
	sprintf(cat_str,"rm -rf simulate_*.ic0 simulate_*.tr0 simulate_*.lis",Rp,Wp);
	system(cat_str);
  }

   // Search for minimum time among all degree of column mux.
   for(j=0;j<3;j++){
	if(min_time>rtime_data[j]){
		 min = j;
		 min_time = rtime_data[j];
	}
   }
  if(min == 0) 		dc_final = 1;
  else if(min == 1) 	dc_final = 2;
  else  		dc_final = 4;
 // system(cat_str);
 // Results are also appended in the output log file 
 // specified in the Makefile

  fprintf(stdout, "***\n");
  fprintf(stdout, "***\n");
  fprintf(stdout, "***\n");
  fprintf(stdout, "***  SEE \"%s\" FOR FINAL RESULTS.\n", PATH);
  fprintf(stdout, "***\n");
  fprintf(stdout, "***\n");
  fprintf(stdout, "***\n");

  fprintf(result_ptr,"INPUT CONFIGURATION\n");
  fprintf(result_ptr,"Depth: %d words\n", D);
  fprintf(result_ptr,"Word Width: %d bits\n", W);
  fprintf(result_ptr,"Read Ports: %d\n", Rp);
  fprintf(result_ptr,"Write Ports: %d\n", Wp);

  fprintf(result_ptr,"\n");
  fprintf(result_ptr,"RESULTS: GEOMETRY\n");
  fprintf(result_ptr,"Degree Column Muxing: %d\n", dc_final);
  fprintf(result_ptr,"Area: %lf (um^2)\n", (area_data[min]*1e6));
  fprintf(result_ptr,"Height: %lf (um)\n", height_ram[min]);
  fprintf(result_ptr,"Width: %lf (um)\n", width_ram[min]);

  fprintf(result_ptr,"\n");
  fprintf(result_ptr,"RESULTS: PERFORMANCE\n");
  fprintf(result_ptr,"Read Time: %lf (ns)\n", rtime_data[min]);
  fprintf(result_ptr,"Read Energy: %lf (pJ)\n", (renergy_data[min]*1e3));
  fprintf(result_ptr,"Write Energy: %lf (pJ)\n", (wenergy_data[min]*1e3));
  fprintf(result_ptr,"Bit-Cell Energy: %lf (pJ)\n", (bitenergy_data[min]*1e3));

  fprintf(result_ptr,"\n");
  fprintf(result_ptr,"The information above is repeated below in a single line and in the same order.\n");
  fprintf(result_ptr,"\n");
  fprintf(result_ptr,"%d\t%d\t%dR\t%dW\t%d\t%lf\t%lf\t%lf\t%lf\t%lf\t%lf\t%lf\n",
	 D, W, Rp, Wp, dc_final, (area_data[min]*1e6), height_ram[min], width_ram[min], rtime_data[min], 
	 (renergy_data[min]*1e3), (wenergy_data[min]*1e3), (bitenergy_data[min]*1e3));
   
  fflush(result_ptr);
  fclose(result_ptr);
  return 0;
}



void create_array(int depth_cfg, int width_cfg, int read_p, int write_p)
{
  int i, j, k;
  int total_p;
  int total_btl,N_invs;
  int width,depth,col_trans;
  int ckt_layers;
  double c_couple,btl_len,decoder_len,WL_cint,sp,cint;
  double total_area,mem_h;
  double precharge_h,sense_amp_h=1.21,col_h=0.94,write_h = 1.7575 , delW_col = 0.715 , inv_h = 0.9;
  char wpath[200];
  FILE *fp;
  FILE *result;
  int w_n=90,w_p=180;

  fp = fopen("instance.sp","w");

  if(fp == NULL) 
  {
	printf("instance.sp file couldn't open for write\n");
	exit(0);
  }

  depth = depth_cfg / DC;
  width = width_cfg * DC;
  total_p   = read_p + write_p;
  total_btl = (2*write_p) + (2*read_p);

  
  // Instantiate two rows and one column of bitcells
  for(i=0;i<depth;i++)
  {
        for(j=0;j<width;j++)
        {       
            if((j==0) || (i<=1))
	      {	
	   	fprintf(fp,"X%d ",instance_no++);
                for(k=1;k <= total_p;k++)
                {
			fprintf(fp,"w%d_%d ",k,i);               
                }
		for(k=1;k <= total_p;k++)
                {
			fprintf(fp,"b%d_%d bb%d_%d ",k,j,k,j);
		}
		fprintf(fp,"bitcell_%dr%dw\n",read_p,write_p);
              }
        }
  }

  // Instatiating the precharge circuit
  // Only the bitline corresponding to the 1st column
  // are instantiated to correctly measure the energy 
  // consumption due to large matchline connected to 
  // all the bitcells in same row.
 
  // Unique bitline precharge is used for the read-port 1 
  // as compared to other ports so that energy consumption due
  // to precharging of single port is calculated accurately.
  // That can be used as the multiplication factor to consider
  // energy consumption due to multiple active ports.
 
  // For rows(depth) greater than 32, PMOS width is kept 720nm
  // while data-width of 32 or lesser, PMOS width is kept 360nm
  // Similar design choices are made for the layout-generation 
  // tool.

  j=0 ; 
  for(k=1;k<=read_p;k++)
  {
	if(depth/DC > 32) 
	      if(k==1) fprintf(fp,"X%d CLK b%d_%d bb%d_%d read_precharge_power\n",instance_no++,k,j,k,j);
	      else fprintf(fp,"X%d CLK b%d_%d bb%d_%d read_precharge\n",instance_no++,k,j,k,j);
	else 
	      if(k==1) fprintf(fp,"X%d CLK b%d_%d bb%d_%d read_precharge_power w1=360n \n",instance_no++,k,j,k,j);
	      else fprintf(fp,"X%d CLK b%d_%d bb%d_%d read_precharge w1=360n \n",instance_no++,k,j,k,j);
  }
 
  // Instatiating the write data cell
  // To measure the energy consumption in single port due to 
  // write-driver, write-port 1 is using unique write-driver 
  // as compared to other ports.
  fprintf(fp,"\n\n*Instatiating the write data cell.....\n");
  j=0;
  for(j=0;j<W*DC;j++){
        for(k=read_p+1;k <= total_p; k++)
        {
	      if(j==0 && k==read_p+1)
              fprintf(fp,"X%d bb%d_%d b%d_%d d_w%d<%d> w%dCOL_SEL CLK wr_en%d write_data_power\n",instance_no++,k,j,k,j,k,j,k,k);		
	      else
              fprintf(fp,"X%d bb%d_%d b%d_%d d_w%d<%d> w%dCOL_SEL CLK wr_en%d write_data\n",instance_no++,k,j,k,j,k,j,k,k);		
        }
  }

  // Instantiating the Column Decoder
  fprintf(fp,"\n\n*Instatiating the COLUMN DECODER.....\n");
  if(DC==2)
 	 fprintf(fp,"\nX%d COL_SEL COL_SELb rd_inverter w1=180n w2=360n\n",instance_no++);
  else if(DC==4)
  {
  	fprintf(fp,"\nX%d COL_SELa COL_SELab rd_inverter w1=180n w2=360n\n",instance_no++);	
	fprintf(fp,"X%d COL_SELb COL_SELbb rd_inverter w1=180n w2=360n\n",instance_no++);
  }  

  for(k=1;k <= read_p;k=k+1)
  {
   j=0;
   {
       if(DC==2)
	{
         fprintf(fp,"X%d COL_SEL COL_SELb b%d_%d b%d_%d out_rbtl_%d_%d r_columnmux_2x1\n",instance_no++,k,j,k,j+1,k,j/DC);
         fprintf(fp,"X%d COL_SEL COL_SELb bb%d_%d bb%d_%d out_rbtlb_%d_%d r_columnmux_2x1\n",instance_no++,k,j,k,j+1,k,j/DC);
	}
       else if(DC==4)
	{
         fprintf(fp,"X%d COL_SELa COL_SELab b%d_%d b%d_%d out_col_%d%d_%d r_columnmux_2x1\n",instance_no++,k,j,k,j+1,j,j+1,k);
	 fprintf(fp,"X%d COL_SELa COL_SELab b%d_%d b%d_%d out_col_%d%d_%d r_columnmux_2x1\n",instance_no++,k,j+2,k,j+3,j+2,j+3,k );
	 fprintf(fp,"X%d COL_SELb COL_SELbb out_col_%d%d_%d out_col_%d%d_%d out_rbtl_%d_%d r_columnmux_2x1\n",instance_no++,j,j+1,k,j+2,j+3,k,k,j/DC );

         fprintf(fp,"X%d COL_SELa COL_SELab bb%d_%d bb%d_%d out_bcol_%d%d_%d r_columnmux_2x1\n",instance_no++,k,j,k,j+1,j,j+1,k);
	 fprintf(fp,"X%d COL_SELa COL_SELab bb%d_%d bb%d_%d out_bcol_%d%d_%d r_columnmux_2x1\n",instance_no++,k,j+2,k,j+3,j+2,j+3,k );
	 fprintf(fp,"X%d COL_SELb COL_SELbb out_bcol_%d%d_%d out_bcol_%d%d_%d out_rbtlb_%d_%d r_columnmux_2x1\n",instance_no++,j,j+1,k,j+2,j+3,k,k,j/DC );

	}
   }
  } 

  // Instantiating the Sense-Amplifier
  // SA for read-port 1 is unique as compared to other
  // posts for accurate energy consumption in single port.

  fprintf(fp,"\n\n*Instatiating the sense_amp.....\n");
  j = 0;
        for(k=1;k <= read_p;k=k+1)
        {
		if(DC != 1){
			if(k==1)
	        	fprintf(fp,"X%d out_rbtlb_%d_%d out_rbtl_%d_%d SE%d dual_sense_power \n",instance_no++,k,j,k,j,k);
			else
	        	fprintf(fp,"X%d out_rbtlb_%d_%d out_rbtl_%d_%d SE%d dual_sense \n",instance_no++,k,j,k,j,k);
		}
		else{
                	if(k==1)
			fprintf(fp,"X%d bb%d_%d  b%d_%d SE%d dual_sense_power \n",instance_no++,k,j,k,j,k);
			else
			fprintf(fp,"X%d bb%d_%d  b%d_%d SE%d dual_sense \n",instance_no++,k,j,k,j,k);

		}
        }
 

  //Instantiating Output Buffer
  // Output buffer for read-port 1 is unique as compared to 
  // other ports for accurate energy consumption in single port.
  // Due to extra transistor in the bitcell (decoupling transistor)
  // the read value has to be inverted for the bitcell in which 
  // decoupling is accomodated. For 2mR1mW bitcell, it is in the bitcell
  // with number of ports >= 4. For 1mR1mW bitcell, it is in the bitcell
  // with number of ports >= 5.
  j = 0;
        for(k=1;k <= read_p;k=k+1)
        {
		if(DC != 1)
		{
		if((Rp==2*Wp && Rp>=4) || (Rp==Wp && Rp>=5))
	        fprintf(fp,"X%d out_rbtl_%d_%d opdata_%d_%d op_inverter\n",instance_no++,k,j,k,j);
		else
                fprintf(fp,"X%d out_rbtlb_%d_%d opdata_%d_%d op_inverter\n",instance_no++,k,j,k,j);
		}
		else
		{
		 if((Rp==2*Wp && Rp>=4) || (Rp==Wp && Rp>=5))
                     fprintf(fp,"X%d b%d_%d  opdata_%d_%d op_inverter\n",instance_no++,k,j,k,j);
		 else
                     fprintf(fp,"X%d bb%d_%d  opdata_%d_%d op_inverter\n",instance_no++,k,j,k,j);
		}

        }
 

  //N_invs = max_couple();
  // WL driver is kept to be fixed,3, inverters to match with results
  // from layout generation tool .
  N_invs = 3;

  // Number of address bits required for decoder
  row_bits = ceil( (log(depth) / log(2)));

  if(RUN_NO==2)
  {
	 total_area		 = area(D,W,Rp,Wp,DC,N_invs); 
	 area_data[result_index] = total_area/(1e6);
  }
  sprintf(wpath,"simulate_%dr%dw.txt",Rp,Wp);
  if(DC==1) 
  {
	result = fopen(wpath,"w");
	fprintf(result,"\n************* Register File Parameters *************\n");
	fprintf(result,"\tRegister File Depth (in the power of 2): %d\n",D);
	fprintf(result,"\tWidth of each Word in Register File (in bits): %d\n",W);
	fprintf(result,"\tTotal Read Ports in Register File: %d\n",Rp);
	fprintf(result,"\tTotal Write Ports in Register File: %d\n",Wp);
	fprintf(result,"\tProcess Technology: %d\n",T);
	fprintf(result,"\tTemperature : %d \n",temperature);
  }	
  else result = fopen(wpath,"a+");
  if(RUN_NO ==2)
  {
     fprintf(result,"\n\n**********    Simulation Result for %dR%dW COLUMN MUX:%d  ***********    \n\n",Rp,Wp,DC);
     fprintf(result,"\tArea\t\t : %lf um2 \n",total_area);
  }	
  fflush(result);
  fclose(result);

  // WL Buffer/Driver

  // Instatiating the sized inverter chain
  fprintf(fp,"\n****** WL buffer chain  ******\n");
  for(j=0;j<2;j++)
  {
     for (i = 1; i <= Rp+1 ; i++)
     {
	w_n = 90;
        w_p = 180;
        for(k = 1;k<=N_invs;k++)
        {
	    if(N_invs==1)
		    if(i==Rp+1) fprintf(fp,"\nX%d w%d_%d_in w%d_%d inverter w1=360n w2=720n",instance_no++,i,j,i,j);
        	    else if(i==1)  fprintf(fp,"\nX%d w%d_%d_in w%d_%d rd_inverter_power w1=360n w2=720n",instance_no++,i,j,i,j);
      	    	    else  fprintf(fp,"\nX%d w%d_%d_in w%d_%d rd_inverter w1=360n w2=720n",instance_no++,i,j,i,j);
            else if((k==1) && (N_invs>1))
            	    if(i==Rp+1) fprintf(fp,"\nX%d w%d_%d_in w%d_%d_%d inverter",instance_no++,i,j,i,j,k);
            	    else if(i==1) fprintf(fp,"\nX%d w%d_%d_in w%d_%d_%d rd_inverter_power",instance_no++,i,j,i,j,k);
            	    else fprintf(fp,"\nX%d w%d_%d_in w%d_%d_%d rd_inverter",instance_no++,i,j,i,j,k);
            else if(k==N_invs)
            {
                    w_n = w_n * SIZE;
                    w_p = w_p * SIZE;
		    if(i==Rp+1) fprintf(fp,"\nX%d w%d_%d_%d w%d_%d inverter  w1=%dn w2=%dn\n",instance_no++,i,j,k-1,i,j,w_n, w_p);
		    else if(i==1) fprintf(fp,"\nX%d w%d_%d_%d w%d_%d rd_inverter_power  w1=%dn w2=%dn\n",instance_no++,i,j,k-1,i,j,w_n, w_p);
		    else  fprintf(fp,"\nX%d w%d_%d_%d w%d_%d rd_inverter  w1=%dn w2=%dn\n",instance_no++,i,j,k-1,i,j,w_n, w_p);
            }
            else
            {
	            w_n = w_n * SIZE;
        	    w_p = w_p * SIZE;
		    if(i==Rp+1) fprintf(fp,"\nX%d w%d_%d_%d w%d_%d_%d inverter w1=%dn w2=%dn",instance_no++,i,j,k-1,i,j,k,w_n, w_p );
		    else if(i==1) fprintf(fp,"\nX%d w%d_%d_%d w%d_%d_%d rd_inverter_power w1=%dn w2=%dn",instance_no++,i,j,k-1,i,j,k,w_n, w_p );
		    else  fprintf(fp,"\nX%d w%d_%d_%d w%d_%d_%d rd_inverter w1=%dn w2=%dn",instance_no++,i,j,k-1,i,j,k,w_n, w_p );
            }
        }
     }
  }


  fprintf(fp,"\n**** Row Decoder ");
  // Row Decoder for the first two rows
  row_bits = ceil( (log(depth) / log(2)));
  for(j=0;j<2;j++)
  {
     for (i = 1; i <= Rp+1 ; i++)
     {
	fprintf(fp,"\nX%d CLK ",instance_no++);
	for(k=0;k<row_bits;k++)
	{
	   if(j==1 && k==0)
	   fprintf(fp,"A%d_%d_buff ",i,k);
	   else 
	   fprintf(fp,"A%d_%d_in ",i,k);	
        }		
        if(i==Rp+1) fprintf(fp,"w%d_%d_in decoder_%d\n",i,j,row_bits);
	else  fprintf(fp,"w%d_%d_in Rdecoder_%d\n",i,j,row_bits);
    }	
  }

  // Intrinsic capacitance due to the long address line is estimated
  if(read_p != write_p) col_trans = 3;
  else col_trans = pl_col_trans[write_p-1];
  decoder_len = (2*row_bits+1)*PITCH_M2 + 0.56; 
  decoder_len = (decoder_len + 2.0) *ceil((Rp+Wp)/2); //2.0 for buffer length incase of the 3 inverters
  sp = 0.21;
  WL_cint = WIDTH / 0.62 + 2.24 * pow((WIDTH/0.62),0.0275) * (1 - 0.85 * exp(-0.62*sp/0.62));
  WL_cint = WL_cint  + 0.32 * log(THICK/sp)*((0.15*sp/0.62)*exp(-1.62*THICK/sp) - 0.12 * exp(-0.065*sp/THICK));
  WL_cint = WL_cint * decoder_len * (2.5 * 8.85);
  if(WL_cint > 0 )
  {
  fprintf(fp,"\n***** Intrinsic Cap. due to extralength introduced due to the decoder's placement*******");
  for(i=1;i<=total_p;i++)
  {
    fprintf(fp,"\nc_%d w%d_0_in 0 %lfa",instance_no++,i,WL_cint);
    fprintf(fp,"\nc_%d w%d_1_in 0 %lfa",instance_no++,i,WL_cint);
  }
  }

  fprintf(fp,"\n**** Address Bits for Row Decoder ");
  // Address Bits and driver to drive address line
  for (i = 1; i <= Rp+1 ; i++)
  {
      for(k=0;k<row_bits;k++)
      {
 	 if(i==Rp+1) 
	 {
		fprintf(fp,"\nX%d A%d_%d A%d_%d_in1 inverter",instance_no++,i,k,i,k);		
		fprintf(fp,"\nX%d A%d_%d_in1 A%d_%d_buff inverter w1=360n w2=720n",instance_no++,i,k,i,k);		
		fprintf(fp,"\nX%d A%d_%d_buff A%d_%d_in inverter w1=1440n w2=2880n",instance_no++,i,k,i,k);		
	 }
	 else if(i==1)
	 {
                fprintf(fp,"\nX%d A%d_%d A%d_%d_in1 rd_inverter_power",instance_no++,i,k,i,k);
                fprintf(fp,"\nX%d A%d_%d_in1 A%d_%d_buff rd_inverter_power w1=360n w2=720n",instance_no++,i,k,i,k);
                fprintf(fp,"\nX%d A%d_%d_buff A%d_%d_in rd_inverter_power w1=1440n w2=2880n",instance_no++,i,k,i,k);
	 }
	 else 
 	 {
		fprintf(fp,"\nX%d A%d_%d A%d_%d_in1 rd_inverter",instance_no++,i,k,i,k);
                fprintf(fp,"\nX%d A%d_%d_in1 A%d_%d_buff rd_inverter w1=360n w2=720n",instance_no++,i,k,i,k);
                fprintf(fp,"\nX%d A%d_%d_buff A%d_%d_in rd_inverter w1=1440n w2=2880n",instance_no++,i,k,i,k);
	 }
     }
  }
  // Coupling capacitance in between address lines on same later
  // The adjacent address lines are kept on different layer M1 and M2.
  // Thus, address lines on same layer will be on alternate lins.
  // So, the spacing between them is consedered to be 3 times spacing 
  // between M2 wires.
 
  // The number of transistor in one column in single bitcell is kept 3.
  if(Wp != 1) mem_h = (Rp + Wp) * (PITCH_M2) + (col_trans * NMOS_H );
  else mem_h = 1.28;

  sp=0.21; 
  WL_cint = WIDTH / 0.62 + 2.24 * pow((WIDTH/0.62),0.0275) * (1 - 0.85 * exp(-0.62*sp/0.62));
  WL_cint = WL_cint  + 0.32 * log(THICK/sp)*((0.15*sp/0.62)*exp(-1.62*THICK/sp) - 0.12 * exp(-0.065*sp/THICK));
  WL_cint = WL_cint * (mem_h*D/DC + 1.5*row_bits + decoder_len) * (2.5 * 8.85);

  for(i=1;i<=total_p;i++) 
  {
    for(j=0;j<row_bits;j++) 
    {
             fprintf(fp,"\nc_%d A%d_%d_buff 0 %lfa",instance_no++,i,j,WL_cint);
             fprintf(fp,"\nc_%d A%d_%d_in 0 %lfa",instance_no++,i,j,WL_cint);
    }
  } 

  sp=0.07;

  WL_cint = THICK/sp +  1.31*pow((THICK/HEIGHT),0.073) * pow((sp/HEIGHT)+1.38,-2.22);
  WL_cint = WL_cint + 0.4*log((1+(5.46*WIDTH/sp)))*pow(sp/HEIGHT + 1.12,-0.81);
  WL_cint = WL_cint * (2.5 * 8.85) * (mem_h*D/DC + 1.5*row_bits + decoder_len);


  for(i=1;i<=total_p;i++) 
  {
      for(j=0;j<row_bits;j++) 
      {
	   if(j==0) 
	   {
               fprintf(fp,"\nc_%d A%d_%d_in CLK %lfa",instance_no++,i,j,WL_cint);
               fprintf(fp,"\nc_%d A%d_%d_buff A%d_%d_in %lfa",instance_no++,i,j,i,j,WL_cint);
               fprintf(fp,"\nc_%d A%d_%d_buff CLK %lfa",instance_no++,i,j,WL_cint);
	   }
	   else 
           {
		 fprintf(fp,"\nc_%d A%d_%d_in A%d_%d_buff %lfa",instance_no++,i,j,i,j-1,WL_cint);
		 fprintf(fp,"\nc_%d A%d_%d_in A%d_%d_in %lfa",instance_no++,i,j,i,j-1,WL_cint);
		 fprintf(fp,"\nc_%d A%d_%d_buff A%d_%d_in %lfa",instance_no++,i,j,i,j,WL_cint);
		 fprintf(fp,"\nc_%d A%d_%d_buff A%d_%d_buff %lfa",instance_no++,i,j,i,j-1,WL_cint);
	   } 
       }
  }

  // Bitline length increase due to the precharge, sense-amp, 
  // write ckt columnd decoder and interconnected wires 
  if(D/DC <= 32) precharge_h = 2*(0.36+0.11);
  else precharge_h = 2*(0.72+0.11);
  btl_len = 0.0;

  if(DC==1) 
  {
      if( floor((Rp+Wp)/2)==Rp) ckt_layers= 1;
      else ckt_layers = 2;
      btl_len = btl_len + sense_amp_h * ckt_layers + 2*Rp*PITCH_M2 ;
  }
  else if (DC==2)
  {
     if(Rp == floor(2*PITCH_M2*(Rp+Wp)/delW_col)) ckt_layers= 1;
     else ckt_layers=2;
     btl_len = btl_len + ckt_layers * (sense_amp_h + col_h + 2*Rp*PITCH_M2) + 2*Rp*PITCH_M2;
  }
  else 
  {
     if(Rp == floor(2*PITCH_M2*(Rp+Wp)/delW_col)) ckt_layers= 1;
     else ckt_layers=2;
     btl_len = btl_len + ckt_layers * (sense_amp_h + 2*col_h + 4*Rp*PITCH_M2) + 2*Rp*PITCH_M2;
  }

  if(DC==4) btl_len = btl_len + 4*write_h+5*Wp*PITCH_M2;
  else if(DC==2) btl_len = btl_len + 2*write_h + 3*Wp*PITCH_M2;
  else btl_len = btl_len + 2*write_h + Wp*PITCH_M2;

  btl_len = btl_len +  precharge_h + Rp*PITCH_M2 + inv_h;
  sp = 0.07;
  cint = intrinsic_cap(sp,btl_len);
  c_couple = coup_cap_cal(sp,btl_len);
  for(i=0;i<width;i++) 
  {
      for(j=1;j<=total_p;j++) 
      {
  	  fprintf(fp,"\nc_%d b%d_%d 0 %lfa",instance_no++,j,i,cint);
          fprintf(fp,"\nc_%d bb%d_%d 0 %lfa",instance_no++,j,i,cint);
      }
  
      for(j=1;j<Rp;j++) 
      {
  	  fprintf(fp,"\nc_%d b%d_%d b%d_%d %lfa",instance_no++,j,i,j+1,i,c_couple);
          fprintf(fp,"\nc_%d b%d_%d bb%d_%d %lfa",instance_no++,j,i,j+1,i,c_couple);
      }
      for(j=Rp+1;j<Rp+Wp;j++) 
      {
          fprintf(fp,"\nc_%d b%d_%d b%d_%d %lfa",instance_no++,j,i,j+1,i,c_couple);
          fprintf(fp,"\nc_%d b%d_%d bb%d_%d %lfa",instance_no++,j,i,j+1,i,c_couple);
      }  
  }     
  
  fprintf(fp,"\n\n");

  fflush(fp);
  fclose(fp);

 return;
}


// Coupling cap. calculation for the bitline 
double coup_cap_cal(double spacing,double len)
   {
     double c12,cfinal;
     c12 = THICK/spacing +  1.31*pow((THICK/HEIGHT),0.073) * pow((spacing/HEIGHT)+1.38,-2.22);	
     c12 = c12 + 0.4*log((1+(5.46*WIDTH/spacing)))*pow(spacing/HEIGHT + 1.12,-0.81);
     cfinal = c12 * (2.5 * 8.85) *len;         
     return cfinal;
   }

// Intrinsic cap. calculation for the bitline 
double intrinsic_cap(double sp,double len)
	{
          double cint;
	  cint = WIDTH / HEIGHT + 2.24 * pow((WIDTH/HEIGHT),0.0275) * (1 - 0.85 * exp(-0.62*sp/HEIGHT));
          cint = cint  + 0.32 * log(THICK/sp)*((0.15*sp/HEIGHT)*exp(-1.62*THICK/sp) - 0.12 * exp(-0.065*sp/THICK));
	  cint = cint * len * (2.5 * 8.85);
          return cint;
	}

int max_couple ()
    {
        double C_int, C_couple , CL ;
        double height_gnd;
	int row_trans,col_trans,total_trans,trans_oneside;      
	int i;
        double height,width,width1,width2,total_area,buffer_area;
	double length;
	double spacing = WIDTH;
	double F,N;
	int N_stages, N_desired;
	int w1=90;
        total_trans = 2*Wp + 2*Rp;
        if(Rp != Wp) col_trans = 3;
        else col_trans = pl_col_trans[Wp-1];
        if(Rp != Wp)
        {
	 row_trans = (2*Rp + 2*Wp) / col_trans;
	}
	else
	{
          if((total_trans % 2) !=0) total_trans++;
          trans_oneside = total_trans/2;
          if((trans_oneside %2) !=0) trans_oneside++;
          row_trans = 2*trans_oneside/col_trans;
	}
	if(Wp != 1) height = (Rp + Wp) * (PITCH_M2) + (col_trans * NMOS_H );
        else height = 1.28;

        width1 = (2*Rp + 2*Wp)*(PITCH_M2);
        width2 = row_trans * NMOS_W + WIDTH4T ;

        if(width1 > width2) width = width1;
        else width = width2;


       length = width;
       height = 0.62;
       C_int = WIDTH / height + 2.24 * pow((WIDTH/height),0.0275) * (1 - 0.85 * exp(-0.62*spacing/height));
       C_int = C_int  + 0.32 * log(THICK/spacing)*((0.15*spacing/height)*exp(-1.62*THICK/spacing) - 0.12 * exp(-0.065*spacing/THICK));
       C_int = C_int * length * (2.5 * 8.85);

       C_couple = THICK/spacing +  1.31*pow((THICK/height),0.073) * pow((spacing/height)+1.38,-2.22);	
       C_couple = C_couple + 0.4*log((1+(5.46*WIDTH/spacing)))*pow(spacing/height+ 1.12,-0.81);
       C_couple = C_couple * (2.5 * 8.85) *length;   
      
       CL = (2*C_couple + C_int)/1000;
       CL = CL * (W*DC);

       // Depending upon inverter sizing (SIZE) the optimal number of inverters
       // in a chain are calulated.

       F = CL / cin;
       N = (log(F)/log(SIZE));
       N_stages = round(N);
       if(N_stages ==0)
         N_desired = 1;
       else if((N_stages%2)==1)
            N_desired = N_stages;
       else if(N_stages > N) N_desired = N_stages - 1 ;
            else N_desired = N_stages + 1 ;

       return N_desired;

  }
   
double area(int Depth,int Width,int read_p,int write_p,int DC,int buffer)
       {
	int row_trans,col_trans,total_trans,trans_oneside;      
	int i,ckt_layers;
        double height,width,width1,width2,total_area,buffer_area;
	double buffer_width,precharge_h,sense_amp_h=1.21,col_h=0.94,write_h = 1.7575 , delW_col = 0.715 , inv_h = 0.9;

	if(buffer == 1) buffer_width = 1.0;
	else buffer_width = 2.5;

	// Depending upon the depth of the memory precharge width varies.
	// That affects the height of the precharge circuit, which will be 
	// on right side of the memory array.

	if(D/DC <= 32) precharge_h = 2*(0.36+0.11);
	else precharge_h = 2*(0.72+0.11);

	// Total NMOS in one column in any bitcell are kept to be 3 
	// for 2mR1mW, while for payload RAM it is stored in pl_col_trans
	// accordingly number of NMOS in row are calculated.
        total_trans = 2*write_p + 2*read_p;
        if(read_p != write_p) col_trans = 3;
        else col_trans = pl_col_trans[write_p-1];
        if(read_p != write_p)
        {
 	    row_trans = (2*read_p + 2*write_p) / col_trans;
	}
	else
	{
            if((total_trans % 2) !=0) total_trans++;
            trans_oneside = total_trans/2;
            if((trans_oneside %2) !=0) trans_oneside++;
            row_trans = 2*trans_oneside/col_trans;
	}
	if(write_p != 1) height = (read_p + write_p) * (PITCH_M2) + (col_trans * NMOS_H );
        else height = 1.28;

        width1 = (2*read_p + 2*write_p)*(PITCH_M2);
	width2 = row_trans * NMOS_W + WIDTH4T ;

	if(width1>width2) width = width1;
	else width = width2;
        printf("\nBIT height: %lf \twidth: %lf",height,width);
        height = height * (Depth/DC);
        width = width * (Width*DC);
	total_area = height * width;
	printf("\nArray AREA = %lf ",total_area);

	if(DC==1) {
	 	   if( floor((Rp+Wp)/2)==Rp) ckt_layers= 1;
		   else ckt_layers = 2;
		   height = height + sense_amp_h * ckt_layers + 2*Rp*PITCH_M2 ;
		  }
	else if (DC==2){
		if(Rp == floor(2*PITCH_M2*(Rp+Wp)/delW_col)) ckt_layers= 1;
		else ckt_layers=2;
		height = height + ckt_layers * (sense_amp_h + col_h + 2*Rp*PITCH_M2) + 2*Rp*PITCH_M2;
	     }
	else { 
		if(Rp == floor(2*PITCH_M2*(Rp+Wp)/delW_col)) ckt_layers= 1;
                else ckt_layers=2;
                height = height + ckt_layers * (sense_amp_h + 2*col_h + 4*Rp*PITCH_M2) + 2*Rp*PITCH_M2;
             }
	
	if(DC==4) height = height + 4*write_h+5*Wp*PITCH_M2;
	else if(DC==2) height = height + 2*write_h + 3*Wp*PITCH_M2;
	else height = height + 2*write_h + Wp*PITCH_M2;

        height = height +  precharge_h + Rp*PITCH_M2 + inv_h;
	width = width + (((2*row_bits) + 1) * PITCH_M2 + 0.56  + buffer_width) * (Rp+Wp);
        total_area = (height * width);

        printf("\nTotal AREA = %lf \nHeight: %lf\t Width: %lf\n",total_area,height , width);
	if(DC == 1) {
		height_ram[0] = height;
		width_ram[0]  = width;
	}
	else if(DC == 2) {
		height_ram[1] = height;
		width_ram[1]  = width;
	}
	else if(DC == 4) {
		height_ram[2] = height;
		width_ram[2]  = width;
	}
	return total_area;
       }

void result()
   {
        FILE *fp,*result;
        int i;
	char ch;
        char str[400];
	char rpath[200],wpath[200];
        double temp1,temp2,temp3 , se_time; //,etot,qtot,tphl,
	double read_time,write_time;
	double q_winv, q_wdecode, q_pre, q_pre_st, q_sense, q_wckt;
	double q_winv_st, q_wdecode_st, q_rinv, q_rinv_st , q_wckt_st;
	double q_rdecode , q_rdecode_st, q_col, q_op, q_rbit , q_wbit;
	double p_bit_st,p_winv, p_wdecode, p_pre, p_sense, p_wckt , p_wckt_st;
	double p_wdecode_st , p_rdecode,p_rdecode_st;
	double p_winv_st, p_rinv, p_rinv_st, p_col, p_op, p_rbit,p_wbit;
	double p_pre_st, p_sense_st;
	double read_power, read_stpower;
	double write_power,  write_stpower;
	double read_energy, write_energy, bit_energy;
	int setuptime;

       // Bitcell Static power Generated by manual simulation for particular bitcell
	double bit_static[8] 	= { 0.0208653, 0.035175, 0.060743, 0.077908, 0.089363, 0.106528, 0.134951, 0.149261 };
	double bit_pl_static[8] = { 0.016095, 0.025635, 0.035175, 0.044715, 0.0626571, 0.072197, 0.081737, 0.091277 };

	se_time = 500; //Default Value

	// Measurement file, generated by the HSPICE tool, to be read
        sprintf(rpath,"simulate_%dr%dw.mt0",Rp,Wp);

	// Output file, to write the results
        sprintf(wpath,"simulate_%dr%dw.txt",Rp,Wp);
        fp = fopen(rpath,"r");
	if(fp==NULL) printf("\nError opening the file");
        result = fopen(wpath,"a+");

	if(RUN_NO==1)
	{
	// Initial lines in the "Measurement File" to skip
	// Skip amount depends on the number of measuremnts 
	// performed by the HSPICE simulation file
            for(i=0; i <= 4; i++)
            {
	        fgets(str,400,fp);
	    }
	    // Sense amp. enable time
            sscanf(str,"%lf    %lf	  %lf",&temp1,&temp2,&se_time);
    	    fgets(str,400,fp);
            sscanf(str,"%lf",&dec_time);
            se_time 	= se_time * 1e12;
            dec_time 	= dec_time * 1e12;
            setuptime 	= ceil(se_time) + clk_setup;
            dec_time	= (dec_time + clk_setup)/1000.0;
            SA_TIME=setuptime;
            fflush(result);
            fclose(result);
        }
        else
	{
	    for(i=0; i <= 34; i++)
            {
	        fgets(str,400,fp);
	    }
	    // Read access time,  write time, prechare energy
  	    sscanf(str,"%lf    %lf	  %lf  %lf ",&temp1, &read_time, &write_time , &q_pre);
	    fgets(str,400,fp);

	    // column mux, sense amp., o/p buffer, write row-decoder energy 
	    sscanf(str,"%lf    %lf	  %lf  %lf ", &q_col , &q_sense, &q_op ,&q_wdecode); 
	    fgets(str,400,fp);

	    // write row-decoder static, read row-decoder, read row-decoder static, write WL driver energy
	    sscanf(str,"%lf    %lf	  %lf  %lf ", &q_wdecode_st, &q_rdecode , &q_rdecode_st, &q_winv);
	    fgets(str,400,fp);

	    // Write WL driver static, read WL driver, read WL driver static, read bitcell energy
	    sscanf(str,"%lf    %lf	  %lf  %lf ", &q_winv_st, &q_rinv , &q_rinv_st, &q_rbit);
            fgets(str,400,fp);

	    // Write bitcell, Write btl driver, Write btl static energy
            sscanf(str,"%lf %lf %lf", &q_wbit, &q_wckt, &q_wckt_st);

            read_time = read_time * 1e9;
            write_time = write_time * 1e9;
            write_time = write_time + clk_setup*1e-3;

            // energy =   Q X V
            // Read is performed on two rows
            // These are the per bit per port measurements (expcept for q_rbit and q_wbit)
            // which should be multiplied by number of bits or 
            // number of entries according to their tyepe to calculate
            // total energy per port

            p_pre = - q_pre * voltage * 1e12 / 2  ;
            p_sense = - q_sense * voltage * 1e12 / (2) ;
            p_col = - q_col * voltage * 1e12 / (2*Rp) ;
            p_op = - q_op * voltage * 1e12 / (2*Rp) ;

            p_wbit = - q_wbit * voltage * 1e12/2 ;
            p_rbit = - q_rbit * voltage * 1e12 ;

            if(Rp != Wp)
            	p_bit_st = bit_static[Wp-1];
            else
            	p_bit_st = bit_pl_static[Wp-1];
            
            p_wdecode = - q_wdecode * voltage * 1e12 / (2*2) ;
            p_wdecode_st = - q_wdecode_st * voltage * 1e12 / (2) ;
            
            p_rdecode = - q_rdecode * voltage * 1e12 / (2*2*Rp) ;
            p_rdecode_st = - q_rdecode_st * voltage * 1e12 / (2*2*Rp) ;
            
            p_winv = - q_winv * voltage * 1e12 /(2*(2+row_bits)) ;
            p_winv_st = - q_winv_st * voltage * 1e12 /(2+row_bits)  ;
            
            p_rinv = - q_rinv * voltage * 1e12 / (2*(2+row_bits)) ;
            p_rinv_st = - q_rinv_st * voltage * 1e12 / (2*(2+row_bits)) ;
            
            p_wckt = - q_wckt * voltage * 1e12 / 2;
            p_wckt_st = - (q_wckt_st * voltage * 1e12 )  ;

            read_energy = p_rbit + p_op*W*DC + p_col*W*DC + p_pre*W*DC + p_rdecode + p_rinv + (p_rdecode_st+p_rinv_st)*(D/DC) + p_sense*W ;
            write_energy = p_wbit + p_wckt*W + p_wckt_st*(W*(DC-1)) + p_wdecode + p_winv + (p_wdecode_st+p_winv_st)*(D/DC) ;
            bit_energy = p_bit_st * W *D * read_time * 1e-3; // p_bit_st is in uW & read_time is in nS so total e-15 * e-12 = e-3 is pJ.
            
            fprintf (result,"\tRead Time   \t: %lf ns\n",read_time);
            fprintf (result,"\tFIFO time : %lf ns \n",read_time-dec_time);
            fprintf (result,"\tRead Energy : %lf pJ \n",read_energy);
            fprintf (result,"\tWrite Energy : %lf pJ \n",write_energy);
            fprintf(result,"\tRead EDP: %lf e-21 \n",read_energy*read_time);
            fprintf(result,"\tBit Energy : %lf pJ \n",bit_energy);

	    // It is assumed that the FIFO access time will be 
            // read access time of SRAM - decoder time
            if(FIFO)
            	rtime_data[result_index] 	= read_time - dec_time;  
            else
            	rtime_data[result_index] 	= read_time;  
            if(rtime_data[result_index] < 0)
            	rtime_data[result_index] 	= 2e10;  
            
            wtime_data[result_index] 	= write_time;
            renergy_data[result_index]	= read_energy/1000;
            wenergy_data[result_index]	= write_energy/1000;
            bitenergy_data[result_index]	= bit_energy/1000;
            EDP_data[result_index] 		= read_energy*read_time/1000;
            
            fflush(result);
            fclose(result);
            result_index++;
	}
        return;
  }
                  
