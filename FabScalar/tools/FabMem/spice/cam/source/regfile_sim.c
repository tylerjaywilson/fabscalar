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

/***************************************************************************
# Purpose	: Fast Simulation (Only Critical Path) for multiported CAM
#	   	  Create the one ROW and one Collumn for the Memory Array
# Varieties	: 1R1W to 8R8W
#**************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "regfile_sim.h"
#include "parameters.h"

bitcell **head_array;		// Bitcell structure created which instantiates 
				// pex extracted bitcell in the instance.sp

char *OP_PATH;			// The appended output file to write output data
				// in TAB separated list

double area(int Depth,int Width,int read_p,int write_p,int buffer);
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
 int i;
 char exe_str[200] = "hspice simulate_2r1w.sp>! simulate_2r1w.lis";
				// exe_str is the string to be used in the system-calls.
 char cat_str[200];
				// To display the output in simulate_mRmW.txt on terminal.
 int j;

 if(argc != (MAX_COMMAND_ARGS+1))
 {
   fprintf(stderr,"\nERROR: Incorrect input values\n");
   fprintf(stderr,"\nUsage:\n");	
   fprintf(stderr,"\t<D> 	- Content Addressable Memory (CAM) Depth (in power of 2)\n");
   fprintf(stderr,"\t<W>   	- Width of each Word in CAM (in bits)\n"); 
   fprintf(stderr,"\t<Rp> 	- Total Broadcast Ports in CAM\n");
   fprintf(stderr,"\t<Wp> 	- Total Write Ports in CAM\n"); 
   fprintf(stderr,"\t<T>  	- Temparature (in Celsius)\n");
   fprintf(stderr,"\t<PATH>	- Output file name with path\n");
   exit(0);
 }

  //Read the command line arguments into variables
  D  = atoi(argv[1]);
  W  = atoi(argv[2]);
  Rp = atoi(argv[3]);
  Wp = atoi(argv[4]);
  temperature = atoi(argv[5]);
  T  = 45 ;
  OP_PATH = argv[6];

  // Print the CAM configuration on the console
  fprintf(stdout,"\n************* CAM  Parameters *************\n");
  fprintf(stdout,"\tCAM Depth (in the power of 2): %d\n",D);
  fprintf(stdout,"\tWidth of each Word in CAM (in bits): %d\n",W);
  fprintf(stdout,"\tTotal Broadcast Ports in CAM: %d\n",Rp);
  fprintf(stdout,"\tTotal Write Ports in CAM: %d\n",Wp);
  fprintf(stdout,"\tTemperature: %d\n",temperature);
  fprintf(stdout,"\tProcess Technology: %d\n\n\n",T);


  // Generate the name of top level spice simulation file
  strcat(strcat(strcat(strcpy(suffix,argv[3]),"r"),argv[4]),"w");
  strcat(strcat(strcat(strcat(simulation_file,argv[3]),"r"),argv[4]),"w.sp");

  // To compensate for the set-up time for the address-line to the input of
  // dynamic row-decoder before the clock-edge.

  if(D>=128) clk_setup = 150 + Wp*15;
  else if(D>=64) clk_setup = 100 + Wp*15;
  else clk_setup = 50 + Wp * 15;

  fprintf(stdout,"\nTop Level Simulation File Name: %s\n", simulation_file);

  // start with the instance # as 1
  instance_no = 1;

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
  i= system(exe_str);
  if(i != 0)  printf("\nSIMULATION FAILED.... :-( \n");
  result();
  system(cat_str);
  // If simulation files are need to be removed then 
  // uncomment following 2 linse
  //sprintf(cat_str,"rm -rf simulate_*",Rp,Wp);  
  //system(cat_str);

 return 0;
}



void create_array(int depth_cfg, int width_cfg, int read_p, int write_p)
{
  int i,j,k;
  int N_invs;
  int width,depth,col_trans;
  double decoder_len,WL_cint,sp,mem_h;
  double total_area;
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

  depth = depth_cfg ;
  width = width_cfg ;

  // Instantiate one rows and one column of bitcells
  for(i=0;i<depth;i++)
  {
        for(j=0;j<width;j++)
        {       
            if((j==0) || (i==0))
	      {	
	   	fprintf(fp,"X%d ",instance_no++);
                for(k=1;k <= write_p;k++)
                {
			fprintf(fp,"w%d_%d ",k,i);               
                }
		for(k=1;k <= read_p;k++)
                {
                        fprintf(fp,"ML%d_%d ",k,i);
		}
		for(k=1;k <= write_p;k++)
                {
			fprintf(fp,"b%d_%d bb%d_%d ",k,j,k,j);
		}
		for(k=1;k <= read_p;k++)
                {
                        fprintf(fp,"SL%d_%d SLb%d_%d ",k,j,k,j);
                }

		fprintf(fp,"bitcell_%dr%dw\n",read_p,write_p);
             }
        }
  }

 // Instatiating the ML precharge circuit
 // Only the matchline corresponding to the 1st rows
 // are instantiated to correctly measure the energy 
 // consumption due to large matchline connected to 
 // all the bitcells in same row.

 // Unique matchline precharge is used for the read-port 1 
 // as compared to other ports so that energy consumption due
 // to precharging of single port is calculated accurately.
 // That can be used as the multiplication factor to consider
 // energy consumption due to multiple active ports.

 // For data-width greater than 32, PMOS width is kept 720nm
 // while data-width of 32 or lesser, PMOS width is kept 360nm
 // Similar design choices are made for the layout-generation 
 // tool.
 fprintf (fp,"\n\n******* MatchLine Precharge *******\n");
 j = 0;
  for(k=1;k<=read_p;k++)
  {
	if(W>32) 
		  if(k==1)  fprintf(fp,"X%d ML_pre ML%d_%d read_precharge_pow \n",instance_no++,k,j);
		  else fprintf(fp,"X%d ML_pre ML%d_%d read_precharge \n",instance_no++,k,j);
	else  if(k==1)  fprintf(fp,"X%d ML_pre ML%d_%d read_precharge_pow w1=360n\n",instance_no++,k,j);
	      else  fprintf(fp,"X%d ML_pre ML%d_%d read_precharge w1=360n\n",instance_no++,k,j);
  		
 }
  
 // Instatiating the write data cell
 // To measure the energy consumption in single port due to 
 // write-driver, write-port 1 is using unique write-driver 
 // as compared to other ports.
  fprintf(fp,"\n\n*Instatiating the write data cell.....\n");
  for(j=0;j<width;j++)
  {
        for(k=1;k <= write_p; k++)
        {
	if(j==0 && k==1)	
              fprintf(fp,"X%d bb%d_%d b%d_%d d_w%d<%d> CLK wr_en%d write_data_power\n",instance_no++,k,j,k,j,k,j,k,k);		
	else
              fprintf(fp,"X%d bb%d_%d b%d_%d d_w%d<%d> CLK wr_en%d write_data\n",instance_no++,k,j,k,j,k,j,k,k);
	
        }
  }

 // Instatiating the SL driver cell
 // SL driver for read-port 1 is unique as compared to other
 // ports for accurate energy consumption in single port.
  fprintf(fp,"\n\n*Instatiating the SL driver .....\n");

  for(j=0;j<(width);j++)
  {
        for(k=1;k <= read_p; k++)
        {
	if(j==0 && k==1) {	
                  fprintf(fp,"X%d CLK c_w%d<%d> SL%d_%d  SLb%d_%d SL_driver_power \n",instance_no++,k,j,k,j,k,j);
		 }
	else {
                  fprintf(fp,"X%d CLK c_w%d<%d> SL%d_%d  SLb%d_%d SL_driver\n",instance_no++,k,j,k,j,k,j);
	     }
        }
  }

        fprintf(fp,"\n\n***** Instantiating Output Buffer *******\n");
        j = 0;
        for(k=1;k <= read_p;k=k+1)
        {
	        fprintf(fp,"X%d ML%d_%d out_ML_%d_%d inverter\n",instance_no++,k,j,k,j);
        }

        //N_invs = max_couple();
        // WL driver is kept to be fixed,3, inverters to match with results
        // from layout generation tool .
   
        N_invs=3;
        total_area = area(D,W,Rp,Wp,N_invs);
        area_data  = total_area / 1e6; 
        sprintf(wpath,"simulate_%dr%dw.txt",Rp,Wp);
	result = fopen(wpath,"w");
	#if 0
	fprintf(result,"\n************* Register File Parameters *************\n");
	fprintf(result,"\tCAM Depth (in the power of 2): %d\n",D);
	fprintf(result,"\tWidth of each Word in CAM (in bits): %d\n",W);
	fprintf(result,"\tTotal Read Ports in Register File: %d\n",Rp);
	fprintf(result,"\tTotal Write Ports in Register File: %d\n",Wp);
	fprintf(result,"\tTemperature: %d\n",temperature);
	fprintf(result,"\tProcess Technology: %d\n",T);
	fprintf(result,"\tArea: \t%lf\n",total_area);
	#endif
        fflush(result);
        fclose(result);

        // WL Buffer/Driver
       
        // Instatiating the sized inver chain 
        fprintf(fp,"\n****** WL buffer chain  ******\n");
	j=0;
        for (i = 1; i <= 1 ; i++)
        {
             w_n = 90;
             w_p = 180;
             for(k = 1;k<=N_invs;k++)
             {
	         if(N_invs==1)
		    	fprintf(fp,"\nX%d w%d_%d_in w%d_%d inverter_pow w1=360n w2=720n",instance_no++,i,j,i,j); 
    		 else if((k==1) && (N_invs>1))                
	                fprintf(fp,"\nX%d w%d_%d_in w%d_%d_%d inverter_pow",instance_no++,i,j,i,j,k);                 
	         else if(k==N_invs)
	              {
        		      w_n = w_n * SIZE;
		              w_p = w_p * SIZE;
		              fprintf(fp,"\nX%d w%d_%d_%d w%d_%d inverter_pow  w1=%dn w2=%dn\n",instance_no++,i,j,k-1,i,j,w_n, w_p); 
             	      }           
	         else{
		             w_n = w_n * SIZE;
		             w_p = w_p * SIZE;
		             fprintf(fp,"\nX%d w%d_%d_%d w%d_%d_%d inverter_pow w1=%dn w2=%dn",instance_no++,i,j,k-1,i,j,k,w_n, w_p );
              	     }
              } 
         }


	// Row Decoder 
        fprintf(fp,"\n\n**** Row Decoder \n");
	row_bits = ceil( (log(depth) / log(2)));
	j=0;
        for (i = 1; i <= 1; i++)
        {
		fprintf(fp,"\nX%d CLK ",instance_no++);
		for(k=0;k<row_bits;k++)
		{
		   fprintf(fp,"A%d_%d_in ",i,k);	
 	        }
                fprintf(fp,"w%d_%d_in decoder_%d\n",i,j,row_bits);
	}	

	// Intrinsic capacitance due to the long address line is estimated
	if(read_p != write_p) col_trans = 3;
        else col_trans = pl_col_trans[write_p-1];
        decoder_len = (2*row_bits+1)*PITCH_M2 + 0.56; 
	decoder_len = decoder_len * (ceil(Wp/2) - 1 );
	sp = 0.21;
	WL_cint = WIDTH / 0.62 + 2.24 * pow((WIDTH/0.62),0.0275) * (1 - 0.85 * exp(-0.62*sp/0.62));
        WL_cint = WL_cint  + 0.32 * log(THICK/sp)*((0.15*sp/0.62)*exp(-1.62*THICK/sp) - 0.12 * exp(-0.065*sp/THICK));
	WL_cint = WL_cint * decoder_len * (2.5 * 8.85);
	if(WL_cint > 0 )
	{
	fprintf(fp,"\n***** Intrinsic Cap. due to extralength introduced due to the decoder's placement*******");
	for(i=1;i<=write_p;i++)
	{
	  fprintf(fp,"\nc_%d w%d_0_in 0 %lfa",instance_no++,i,WL_cint);
	}
	}

        // Address Bits and driver to drive address line
	fprintf(fp,"\n**** Address Bits for Row Decoder ");
	i=1;
	{
	   for(k=0;k<row_bits;k++)
              {
		fprintf(fp,"\nX%d A%d_%d A%d_%d_in1 inverter_pow",instance_no++,i,k,i,k);
                fprintf(fp,"\nX%d A%d_%d_in1 A%d_%d_buff inverter_pow w1=360n w2=720n",instance_no++,i,k,i,k);
                fprintf(fp,"\nX%d A%d_%d_buff A%d_%d_in inverter_pow w1=1440n w2=2880n",instance_no++,i,k,i,k);              
	      }
	}

 // Coupling capacitance in between address lines on same later
 // The adjacent address lines are kept on different layer M1 and M2.
 // Thus, address lines on same layer will be on alternate lins.
 // So, the spacing between them is consedered to be 3 times spacing 
 // between M2 wires.

 // The number of transistor in one column in single bitcell is kept 3.
	col_trans = 3;
        if(write_p != 1) mem_h = (Rp + Wp) * (PITCH_M2) + col_trans * (PITCH_M2 + NMOS_H + 0.08) + 2* PITCH_M1;
        else mem_h = 1.28;

          sp=0.21; 
          WL_cint = WIDTH / 0.62 + 2.24 * pow((WIDTH/0.62),0.0275) * (1 - 0.85 * exp(-0.62*sp/0.62));
          WL_cint = WL_cint  + 0.32 * log(THICK/sp)*((0.15*sp/0.62)*exp(-1.62*THICK/sp) - 0.12 * exp(-0.065*sp/THICK));
          WL_cint = WL_cint * mem_h*D  * (2.5 * 8.85);

	  i=1;
	  for(j=0;j<row_bits;j++) {
                   fprintf(fp,"\nc_%d A%d_%d_buff 0 %lfa",instance_no++,i,j,WL_cint);
                   fprintf(fp,"\nc_%d A%d_%d_in 0 %lfa",instance_no++,i,j,WL_cint);
             }

	  sp=0.07;
	  WL_cint = THICK/sp +  1.31*pow((THICK/HEIGHT),0.073) * pow((sp/HEIGHT)+1.38,-2.22);
	  WL_cint = WL_cint + 0.4*log((1+(5.46*WIDTH/sp)))*pow(sp/HEIGHT + 1.12,-0.81);
	  WL_cint = WL_cint * (2.5 * 8.85) * mem_h*D ;


	  i = 1;
          for(j=0;j<row_bits;j++) {
		   if(j==0) {
                         fprintf(fp,"\nc_%d A%d_%d_in CLK %lfa",instance_no++,i,j,WL_cint);
                         fprintf(fp,"\nc_%d A%d_%d_buff A%d_%d_in %lfa",instance_no++,i,j,i,j,WL_cint);
                         fprintf(fp,"\nc_%d A%d_%d_buff CLK %lfa",instance_no++,i,j,WL_cint);
			    }
		   else {
			 fprintf(fp,"\nc_%d A%d_%d_in A%d_%d_buff %lfa",instance_no++,i,j,i,j-1,WL_cint);
			 fprintf(fp,"\nc_%d A%d_%d_in A%d_%d_in %lfa",instance_no++,i,j,i,j-1,WL_cint);
			 fprintf(fp,"\nc_%d A%d_%d_buff A%d_%d_in %lfa",instance_no++,i,j,i,j,WL_cint);
			 fprintf(fp,"\nc_%d A%d_%d_buff A%d_%d_buff %lfa",instance_no++,i,j,i,j-1,WL_cint);
			}
          }
  fprintf(fp,"\n\n");

  fflush(fp);
  fclose(fp);

 return;
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

       CL = CL * W; // Total capacitance seen by the wordline of any port

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
   
double area(int Depth,int Width,int read_p,int write_p,int buffer)
       {
	int row_trans,col_trans,total_trans,trans_oneside;
        int i,ckt_layers;
        double height,width,width1,width2,total_area,buffer_area;
        double buffer_width,precharge_h,SLdriver_h=1.21,col_h=0.94,write_h = 1.7575 , delW_col = 0.715 , inv_h = 0.9;

        if(buffer == 1) buffer_width = 1.0;
        else buffer_width = 2.5;

	// Depending upon the width of the memory precharge width varies.
	// That affects the height of the precharge circuit, which will be 
	// on right side of the memory array.
        if(W <= 32) precharge_h = 2*(0.36+0.11);
        else precharge_h = 2*(0.72+0.11);
        total_trans = 2*write_p + 2*read_p;
	
	// Total NMOS in one column in any bitcell are kept to be 3 and
	// accordingly number of NMOS in row are calculated.
	col_trans = 3;
	if(Rp>1)  row_trans = (4*read_p + 2*write_p) / col_trans;
	else row_trans = 4;
        if(write_p != 1) height = (read_p + write_p) * (PITCH_M2) + col_trans * (PITCH_M2 + NMOS_H + 0.08) + 2* PITCH_M1;
        else height = 1.28;

	if( row_trans%4 ==0)
        width = (row_trans/2 + 1) * 0.56;
	else
	width = (row_trans/2) * 0.56 + 2*NMOS_W;

        printf("\nBIT height: %lf \twidth: %lf",height,width);
        height = height * Depth;
        width = width * Width;
        total_area = height * width;
        printf("\nArray AREA = %lf ",total_area);

        height = height + SLdriver_h + 2*Rp*PITCH_M2;
        
	height = height + write_h + Wp*PITCH_M2;

        height = height + (Wp+Rp)*PITCH_M2 + inv_h;
        width = width + (((2*row_bits) + 1) * PITCH_M2 + 0.56  + buffer_width) * Wp + precharge_h ;
        total_area = (height * width);

        printf("\nTotal AREA = %lf \nHeight: %lf\t Width: %lf\n",total_area,height , width);
	height_cam = height;
	width_cam  = width;
        return total_area;
	
       }

void result()
	{
        FILE *fp,*result, *result_ptr;
        int i;
	char ch;
        char str[400];
	char rpath[200],wpath[200];
        double read_time,write_time,se_time;
	double q_rbit, q_wbit, q_inv, q_inv_st, q_decode, q_decode_st,q_sl, q_sl_st, q_pre, q_pre_st, q_wckt,q_wckt_st;
        double p_rbit, p_wbit, p_inv, p_inv_st, p_decode, p_decode_st,p_sl, p_sl_st, p_pre, p_pre_st,p_bit_st;
	double p_wckt, p_wckt_st;
	double read_energy, write_energy, bit_energy;
        double bit_static[8] = {0.01748, 0.028405, 0.0491025, 0.0632849, 0.0937484, 0.111187, 0.128625, 0.146064};

	se_time = 500; //Default Value

	// Measurement file, generated by the HSPICE tool, to be read
        sprintf(rpath,"simulate_%dr%dw.mt0",Rp,Wp);

	// Output file, to write the results
        sprintf(wpath,"simulate_%dr%dw.txt",Rp,Wp);
        fp = fopen(rpath,"r");
	if(fp==NULL) printf("\nError opening the file");
        result = fopen(wpath,"a+");
        result_ptr = fopen(OP_PATH,"w");
	if(result_ptr == NULL) printf("\nError: Could not open %s for writing...", OP_PATH);

	// Initial lines in the "Measurement File" to skip
	// Skip amount depends on the number of measuremnts 
	// performed by the HSPICE simulation file
	for(i=0; i <= 24; i++)
            {
	        fgets(str,400,fp);
	    }

	// Static Power per bitcell is pre-computed 
	// and stored in the array bit_static
        p_bit_st = bit_static[Wp-1];

	// Read access time, Write time, Bitcell writing energy, Bitcell read energy
	sscanf(str,"%lf    %lf	 %lf %lf ", &read_time,&write_time, &q_wbit, &q_rbit);
	fgets(str,400,fp);

	// Decoder energy, Decoder static energy, WL driver energy, WL driver static energy
	sscanf(str,"%lf    %lf	  %lf %lf", &q_decode, &q_decode_st, &q_inv, &q_inv_st);
        fgets(str,400,fp);

	// SL driver energy, SL driver static energy, Write ckt energy
	sscanf(str,"%lf  %lf    %lf %lf ", &q_sl, &q_pre, &q_pre_st, &q_wckt);
        fgets(str,400,fp);
	
	// Write ckt static energy
        sscanf(str,"%lf ",&q_wckt_st);

        read_time = read_time * 1e9  + clk_setup*1e-3;
        write_time = write_time * 1e9 + clk_setup*1e-3;

	// energy =   Q X V
	// Read is performed on two rows
	// These are the per bit per port measurements (expcept for q_rbit and q_wbit)
	// which should be multiplied by number of bits or 
	// number of entries according to their tyepe to calculate
	// total energy per port
 
	p_rbit = - q_rbit * voltage * 1e12/ 2 ;
	p_wbit = - q_wbit * voltage * 1e12/ 2 ;
        p_decode = - q_decode * voltage * 1e12 / 2 ;
        p_decode_st = - q_decode_st * voltage / 2 ;
        p_inv = - q_inv * voltage * 1e12 / 2 ;
        p_inv_st = - q_inv_st * voltage * 1e12 / 2  ;
	p_sl = - q_sl * voltage * 1e12 / 4 ;
	p_pre = - q_pre * voltage * 1e12 ;
        p_pre_st = - q_pre_st * voltage * 1e12 ;
	p_wckt =  - q_wckt * voltage * 1e12 / 2 ;
	p_wckt_st = -q_wckt_st * voltage * 1e12 / 2;

	read_energy = (p_rbit + p_sl*W + p_pre*D)/1000.0 ;
	write_energy = (p_wbit + p_decode + p_decode_st * D + p_inv + p_inv_st * D + p_wckt*W)/1000.0 ;
        bit_energy = (p_bit_st * W *D * read_time * 1e-3)/1000.0;

	fprintf (result,"\tRead Time   \t: %lf ns\n",read_time);
        fprintf (result,"\tRead Energy : %lf pJ \n",(read_energy*1e3));
        fprintf (result,"\tWrite Energy : %lf pJ \n",(write_energy*1e3));
        fprintf (result,"\tBit Energy : %lf pJ \n",(bit_energy*1e3));

	// Results are also appended in the output log file 
	// specified in the Makefile


	fprintf(stdout, "***\n");
	fprintf(stdout, "***\n");
	fprintf(stdout, "***\n");
	fprintf(stdout, "***  SEE \"%s\" FOR FINAL RESULTS.\n", OP_PATH);
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
	fprintf(result_ptr,"Area: %lf (um^2)\n", (area_data*1e6));
	fprintf(result_ptr,"Height: %lf (um)\n", height_cam);
	fprintf(result_ptr,"Width: %lf (um)\n", width_cam);

	fprintf(result_ptr,"\n");
	fprintf(result_ptr,"RESULTS: PERFORMANCE\n");
	fprintf(result_ptr,"Read Time: %lf (ns)\n", read_time);
	fprintf(result_ptr,"Read Energy: %lf (pJ)\n", (read_energy*1e3));
	fprintf(result_ptr,"Write Energy: %lf (pJ)\n", (write_energy*1e3));
	fprintf(result_ptr,"Bit-Cell Energy: %lf (pJ)\n", (bit_energy*1e3));

	fprintf(result_ptr,"\n");
	fprintf(result_ptr,"The information above is repeated below in a single line and in the same order.\n");
	fprintf(result_ptr,"\n");

	fprintf(result_ptr,"%d\t%d\t%dR\t%dW\t%lf\t%lf\t%lf\t%lf\t%lf\t%lf\t%lf\n",
        D, W, Rp, Wp, (area_data*1e6), height_cam, width_cam, read_time, (read_energy*1e3), (write_energy*1e3), (bit_energy*1e3));
	
	fflush(result);
	fflush(result_ptr);
	fclose(result);
	fclose(result_ptr);
        return;
     }
                  
