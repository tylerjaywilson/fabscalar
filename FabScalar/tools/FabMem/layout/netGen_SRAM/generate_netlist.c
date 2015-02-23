/***************************************************************************
#                        NORTH CAROLINA STATE UNIVERSITY
#
#                               FabScalar Project
#
# Purpose:    SRAM full netlist file generation
#
# Author:     Tanmay Shah
#
#**************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#define MAX_COMMAND_ARGS 5

int D,W,Rp,Wp,DC;
int bit_array[8];
void create_SRAM(int ,int ,int ,int ,int );
void d2b(int ,int );

int main(int argc, char *argv[])
{

    if(argc != (MAX_COMMAND_ARGS+1))
     {
	fprintf(stderr,"\nERROR: Incorrect input values\n");
	fprintf(stderr,"\nUsage:\n");	
	fprintf(stderr,"\t<D>  - Register File Depth (in power of 2)\n");
	fprintf(stderr,"\t<W>  - Width of each Word in Register File (in bits)\n"); 
	fprintf(stderr,"\t<Rp> - Total Read Ports in Register File\n");
	fprintf(stderr,"\t<Wp> - Total Write Ports in Register File\n"); 
	fprintf(stderr,"\t<DC> - Degree of Column Mux(1-2-4)\n");
	exit(0);
    }

      /* Read the command line arguments into variables. */
      D  = atoi(argv[1]);
      W  = atoi(argv[2]);
      Rp = atoi(argv[3]);
      Wp = atoi(argv[4]);
      DC = atoi(argv[5]);

      create_SRAM(D,W,Rp,Wp,DC);
      return 0;
}


void create_SRAM(int D,int W,int Rp,int Wp,int DC)
	{
	     int depth,width;   
	     int instance_no,row_bits;
	     int i,j,k;  
             char str[50];
	     FILE *fp_src;
	     depth=D;
	     width=W;
             sprintf(str,"mem_%d_%d_%d_%d.src.net",D,W,Rp,Wp);	
             fp_src=fopen(str,"w");
	     instance_no = 0;
      	     row_bits = ceil( (log(depth) / log(2)));

         //    fprintf(fp_src,"\n*.EQUATION \n*.SCALE METER \n*.MEGA \n.PARAM\n");
	     fprintf(fp_src,"\n*.GLOBAL vdd! \n+        gnd! \n\n*.PIN vdd! \n*+    gnd!\n");
             sprintf(str,"mem_%d_%d_%d_%d",D,W,Rp,Wp);	
             fprintf(fp_src,"\n\n.include ../netGen_SRAM/buff.src.net");
             fprintf(fp_src,"\n\n.include ../netGen_SRAM/precharge.src.net");
             fprintf(fp_src,"\n\n.include ../netGen_SRAM/sense_amp.src.net");
             fprintf(fp_src,"\n\n.include ../netGen_SRAM/wdata_nodc.src.net");
             fprintf(fp_src,"\n\n.include ../netGen_SRAM/%dr%dw_new.src.net",Rp,Wp);
             fprintf(fp_src,"\n\n.include ../netGen_SRAM/decoder.src.net",row_bits);

             fprintf(fp_src,"\n\n\n.SUBCKT %s clk\n\t+",str);

/************************* PORT LIST *********************/
             for(i=1;i<=Rp+Wp;i++)
		{
		   for(j=0;j<row_bits;j++)
			{
			   if(i<=Rp) fprintf(fp_src,"AR%d<%d> ",i,j);  //For address line
			   else fprintf(fp_src,"AW%d<%d> ",i-Rp,j);  //For address line
			}                    
			   fprintf(fp_src,"\n\t+");			
		}
             for(i=1;i<=Rp;i++)
		{
	             fprintf(fp_src,"SE%d\t",i);   //For Sense Enable
		}
             fprintf(fp_src,"\n+");
             for(j=1;j<=Wp;j++)
		{
	             fprintf(fp_src,"\tWREN%d",j); // For Write Enable
		}
             fprintf(fp_src,"\n\t+");
            
             for(i=0;i<width;i++)
		{
		   for(j=1;j<=Wp;j++)
		      {
			fprintf(fp_src," D%d<%d> ",j,i,j,i);   //For Input data
		      }
             	   fprintf(fp_src,"\n\t+");
		}
             fprintf(fp_src,"\n\t+");
            
             for(i=0;i<width;i++)
		{
		   for(j=1;j<=Rp;j++)
		      {
			fprintf(fp_src," op_%d<%d> ",j,i,j,i);   //For Input data
		      }
             	   fprintf(fp_src,"\n\t+");
		}

             fprintf(fp_src,"\n");

/************************* PIN INFO ********************/
             fprintf(fp_src,"\n*.PININFO clk:I ");
             for(i=1;i<=Rp+Wp;i++)
		{
                  fprintf(fp_src,"\n\t*.PININFO");
		   for(j=0;j<row_bits;j++)
			{
			   if(i<=Rp) fprintf(fp_src,"AR%d<%d>:I ",i,j);  //For address line
			   else fprintf(fp_src,"AW%d<%d>:I ",i-Rp,j);  //For address line
//			   fprintf(fp_src," A%d<%d>:I ",i,j);  //For address line
			}                    
		}

   	     fprintf(fp_src,"\n\t*.PININFO ");			
             for(i=1;i<=Rp;i++)
		{
	             fprintf(fp_src,"SE%d:I\t",i);   //For Sense Enable
		}

             fprintf(fp_src,"\n\t*.PININFO ");
             for(j=1;j<=Wp;j++)
		{
	             fprintf(fp_src,"WREN%d:I\t",j); // For Write Enable
		}
            
             for(i=0;i<width;i++)
		{
                   fprintf(fp_src,"\n\t*.PININFO ");
		   for(j=1;j<=Wp;j++)
		      {
			fprintf(fp_src," D%d<%d>:I ",j,i);   //For Input data
		      }
		}

             for(i=0;i<width;i++)
		{
                   fprintf(fp_src,"\n\t*.PININFO ");
		   for(j=1;j<=Rp;j++)
		      {
			fprintf(fp_src," op_%d<%d>:O ",j,i);   //For Input data
		      }
		}


                fprintf(fp_src,"\n");

/*************** bitcell placement *******************/
	     for(i=0;i<depth/DC;i++)
	     {
                for(j=0;j<width*DC;j++)
	        {       
                  //  if(i<=1 || j==0) {
		   	fprintf(fp_src,"XI%d ",instance_no++);
	                for(k=1;k <= Rp+Wp;k++)
	                {
	  		   fprintf(fp_src,"w%d_%d ",k,i);               
	                }
			for(k=1;k <= Rp+Wp;k++)
	                {
	       		    fprintf(fp_src,"b%d_%d bb%d_%d ",k,j,k,j);
			}
		     fprintf(fp_src,"/ %dr%dw_new\n",Rp,Wp);
                  //  }
                }
             }

/***************** Precharge Unit ************************/
             for(i=0;i<width*DC;i++)
		{
		   for(j=1;j<=Rp;j++)
			{
			   if(depth/DC>32)
			   {
			      fprintf(fp_src,"\nXI%d clk b%d_%d / precharge72",instance_no++,j,i);	
			      fprintf(fp_src,"\nXI%d clk bb%d_%d / precharge72",instance_no++,j,i);	
			   }
			   else
			   {
			      fprintf(fp_src,"\nXI%d clk b%d_%d / precharge",instance_no++,j,i);	
			      fprintf(fp_src,"\nXI%d clk bb%d_%d / precharge",instance_no++,j,i);	  
			   }
			}
		}

/***********************Column Decoder and Sense Amplifier ********************/
             if(DC==2)
 		{
             for(i=0;i<width*DC;i=i+2)
		{
		   for(j=1;j<=Rp;j++)
			{
	  	         fprintf(fp_src,"\nXI%d AR%d_%d b%d_%d b%d_%d outb%d_%d / colmux_2",instance_no++,j,row_bits-1,j,i,j,i+1,j,i/2);		
	  	         fprintf(fp_src,"\nXI%d AR%d_%d bb%d_%d bb%d_%d outbb%d_%d / colmux_2",instance_no++,j,row_bits-1,j,i,j,i+1,j,i/2);	
			}
		}
		}
	     else if(DC==4)
		{
                for(i=0;i<width*DC;i=i+4)
		 {
		    for(j=1;j<=Rp;j++)
			{
	  	         fprintf(fp_src,"\nXI%d AR%d_%d b%d_%d b%d_%d outr1_b%d_%d / colmux_2",instance_no++,j,row_bits-2,j,i,j,i+1,j,i/DC);			
	  	         fprintf(fp_src,"\nXI%d AR%d_%d b%d_%d b%d_%d outr2_b%d_%d / colmux_2",instance_no++,j,row_bits-2,j,i+2,j,i+3,j,i/DC);			
	  	         fprintf(fp_src,"\nXI%d AR%d_%d outr1_b%d_%d outr2_b%d_%d outb%d_%d / colmux_2",instance_no++,j,row_bits-1,j,i/DC,j,i/DC,j,i/DC);			

	  	         fprintf(fp_src,"\nXI%d AR%d_%d bb%d_%d bb%d_%d outr1_bb%d_%d / colmux_2",instance_no++,j,row_bits-2,j,i,j,i+1,j,i/DC);			
	  	         fprintf(fp_src,"\nXI%d AR%d_%d bb%d_%d bb%d_%d outr2_bb%d_%d / colmux_2",instance_no++,j,row_bits-2,j,i+2,j,i+3,j,i/DC);			
	  	         fprintf(fp_src,"\nXI%d AR%d_%d outr1_bb%d_%d outr2_bb%d_%d outbb%d_%d / colmux_2",instance_no++,j,row_bits-1,j,i/DC,j,i/DC,j,i/DC);			
			}
		 }
		}

             for(i=0;i<width;i++)
		{
		   for(j=1;j<=Rp;j++)
			{
	             if(DC==1){	             
   		      fprintf(fp_src,"\nXI%d b%d_%d bb%d_%d SE%d / sense_amp",instance_no++,j,i,j,i,j);	
		      fprintf(fp_src,"\nXI%d b%d_%d op_%d<%d> / inverter",instance_no++,j,i,j,i);
			}
		     else{	
   		      fprintf(fp_src,"\nXI%d outb%d_%d outbb%d_%d SE%d / sense_amp",instance_no++,j,i,j,i,j);			     
		      fprintf(fp_src,"\nXI%d outb%d_%d op_%d<%d> / inverter",instance_no++,j,i,j,i);
			 }
		}
             }

/*********************** Write CKT ********************/
             if(DC==1)
	     {
             for(i=0;i<width*DC;i++)
		{
		   for(j=Rp+1;j<=Rp+Wp;j++)
			{
			   fprintf(fp_src,"\nXI%d D%d<%d> Db%d_%d / inverter",instance_no++,j-Rp,i,j-Rp,i); 	
			   fprintf(fp_src,"\nXI%d b%d_%d  clk Db%d_%d WREN%d / wdata_nodc",instance_no++,j,i,j-Rp,i,j-Rp);
			   fprintf(fp_src,"\nXI%d bb%d_%d  clk D%d<%d> WREN%d / wdata_nodc",instance_no++,j,i,j-Rp,i,j-Rp);	
			}
		}
	    }
	    else if(DC==2)
	    {
             for(i=0;i<width*DC;i=i+2)
		{
		   for(j=Rp+1;j<=Rp+Wp;j++)
			{
			   fprintf(fp_src,"\nXI%d D%d<%d> Db%d_%d / inverter",instance_no++,j-Rp,i/2,j-Rp,i);
			   fprintf(fp_src,"\nXI%d D%d<%d> Db%d_%d / inverter",instance_no++,j-Rp,i/2,j-Rp,i+1); 	 	
			   fprintf(fp_src,"\nXI%d b%d_%d  clk Db%d_%d WREN%d AW%d_%d / wdata_dc",instance_no++,j,i,j-Rp,i,j-Rp,j-Rp,row_bits-1);
			   fprintf(fp_src,"\nXI%d bb%d_%d  clk D%d<%d> WREN%d AW%d_%d / wdata_dc",instance_no++,j,i,j-Rp,i/2,j-Rp,j-Rp,row_bits-1);	
			   fprintf(fp_src,"\nXI%d b%d_%d  clk Db%d_%d WREN%d AWb%d_%d / wdata_dc",instance_no++,j,i+1,j-Rp,i+1,j-Rp,j-Rp,row_bits-1);
			   fprintf(fp_src,"\nXI%d bb%d_%d clk D%d<%d> WREN%d AWb%d_%d / wdata_dc",instance_no++,j,i+1,j-Rp,i/2,j-Rp,j-Rp,row_bits-1);	
			}		 
		}
	    }	
	   else if(DC==4)
	    {
             for(i=0;i<width*DC;i=i+4)
		{
		   for(j=Rp+1;j<=Rp+Wp;j++)
			{
			   fprintf(fp_src,"\nXI%d D%d<%d> Db%d_%d / inverter",instance_no++,j-Rp,i/DC,j-Rp,i/DC);
			   fprintf(fp_src,"\nXI%d b%d_%d  clk Db%d_%d WREN%d AW%d_%d AW%d_%d / wdata_dc4",instance_no++,j,i,j-Rp,i/DC,j-Rp,j-Rp,row_bits-2,j-Rp,row_bits-1);
			   fprintf(fp_src,"\nXI%d bb%d_%d  clk D%d<%d> WREN%d AW%d_%d AW%d_%d / wdata_dc4",instance_no++,j,i,j-Rp,i/DC,j-Rp,j-Rp,row_bits-2,j-Rp,row_bits-1);	
			   fprintf(fp_src,"\nXI%d b%d_%d  clk Db%d_%d WREN%d AWb%d_%d AW%d_%d / wdata_dc4",instance_no++,j,i+1,j-Rp,i/DC,j-Rp,j-Rp,row_bits-2,j-Rp,row_bits-1);
			   fprintf(fp_src,"\nXI%d bb%d_%d clk D%d<%d> WREN%d AWb%d_%d AW%d_%d / wdata_dc4",instance_no++,j,i+1,j-Rp,i/DC,j-Rp,j-Rp,row_bits-2,j-Rp,row_bits-1);	
			   fprintf(fp_src,"\nXI%d b%d_%d  clk Db%d_%d WREN%d AW%d_%d AWb%d_%d / wdata_dc4",instance_no++,j,i+2,j-Rp,i/DC,j-Rp,j-Rp,row_bits-2,j-Rp,row_bits-1);
			   fprintf(fp_src,"\nXI%d bb%d_%d clk D%d<%d> WREN%d AW%d_%d AWb%d_%d / wdata_dc4",instance_no++,j,i+2,j-Rp,i/DC,j-Rp,j-Rp,row_bits-2,j-Rp,row_bits-1);	
			   fprintf(fp_src,"\nXI%d b%d_%d  clk Db%d_%d WREN%d AWb%d_%d AWb%d_%d / wdata_dc4",instance_no++,j,i+3,j-Rp,i/DC,j-Rp,j-Rp,row_bits-2,j-Rp,row_bits-1);
			   fprintf(fp_src,"\nXI%d bb%d_%d clk D%d<%d> WREN%d AWb%d_%d AWb%d_%d / wdata_dc4",instance_no++,j,i+3,j-Rp,i/DC,j-Rp,j-Rp,row_bits-2,j-Rp,row_bits-1);	
			}		 
		}
	    }	

/************************* Input Buffer for the Address lines ***************************/
            if(DC==2){
 	    for(j=1;j<=Rp+Wp;j++)
	     {
                for(i=0;i<row_bits-1;i++)
		  {
		  if(j<=Rp) fprintf(fp_src,"\nXI%d AR%d<%d> AR%d_%d ARb%d_%d / buff3",instance_no++,j,i,j,i,j,i);
		  else fprintf(fp_src,"\nXI%d AW%d<%d> AW%d_%d AWb%d_%d / buff3",instance_no++,j-Rp,i,j-Rp,i,j-Rp,i);
		  }
	     }	
	    }
	    else if(DC==4){
 	    for(j=1;j<=Rp+Wp;j++)
	     {
                for(i=0;i<row_bits-2;i++)
		  {
		  if(j<=Rp) fprintf(fp_src,"\nXI%d AR%d<%d> AR%d_%d ARb%d_%d / buff3",instance_no++,j,i,j,i,j,i);
		  else fprintf(fp_src,"\nXI%d AW%d<%d> AW%d_%d AWb%d_%d / buff3",instance_no++,j-Rp,i,j-Rp,i,j-Rp,i);
		  }
	     }	
	    }
	    else{
 	    for(j=1;j<=Rp+Wp;j++)
	     {
                for(i=0;i<row_bits;i++)
		  {
		  if(j<=Rp) fprintf(fp_src,"\nXI%d AR%d<%d> AR%d_%d ARb%d_%d / buff3",instance_no++,j,i,j,i,j,i);
		  else fprintf(fp_src,"\nXI%d AW%d<%d> AW%d_%d AWb%d_%d / buff3",instance_no++,j-Rp,i,j-Rp,i,j-Rp,i);
		  }
	     }	
	    }
/************************ Input Buffer for the column decoder Address lines *********************/
            if(DC==2) {
 	    for(j=1;j<=Rp;j++)
	     {
		  fprintf(fp_src,"\nXI%d AR%d<%d> AR%d_%d / buff2",instance_no++,j,row_bits-1,j,row_bits-1);
	     }
	    }	
	    else if(DC==4){
 	    for(j=1;j<=Rp;j++)
	     {
		  fprintf(fp_src,"\nXI%d AR%d<%d> AR%d_%d / buff2",instance_no++,j,row_bits-1,j,row_bits-1);
		  fprintf(fp_src,"\nXI%d AR%d<%d> AR%d_%d / buff2",instance_no++,j,row_bits-2,j,row_bits-2);
	     }
	    }	

/********************* Input Buffer for the column decoder address line for write ckt *********/
	    if(DC==2) {
 	    for(j=Rp+1;j<=Rp+Wp;j++)
	     {
		  fprintf(fp_src,"\nXI%d AW%d<%d> AW%d_%d AWb%d_%d / buff3",instance_no++,j-Rp,row_bits-1,j-Rp,row_bits-1,j-Rp,row_bits-1);
	     }
	    }
            else if(DC==4) {
 	    for(j=Rp+1;j<=Rp+Wp;j++)
	     {
		  fprintf(fp_src,"\nXI%d AW%d<%d> AW%d_%d AWb%d_%d / buff3",instance_no++,j-Rp,row_bits-1,j-Rp,row_bits-1,j-Rp,row_bits-1);
		  fprintf(fp_src,"\nXI%d AW%d<%d> AW%d_%d AWb%d_%d / buff3",instance_no++,j-Rp,row_bits-2,j-Rp,row_bits-2,j-Rp,row_bits-2);
	     }
	    }

/*********************** WL driver (buffer) ***********************/
             for(i=0;i<depth/DC;i++)
		{
		   for(j=1;j<=Rp+Wp;j++)
			{
			   fprintf(fp_src,"\nXI%d w%d_%d w%d_%d_in / buff",instance_no++,j,i,j,i);	
			}
		}
	   for(k=1;k<=Rp+Wp;k++)
		{
		   for(i=0;i<depth/DC;i++)
			{
                         d2b(i,row_bits);
			 fprintf(fp_src,"\nXI%d clk ",instance_no++);
                         if(DC==1){
			 for(j=row_bits-1;j>=0;j--)
			    {
			      if(bit_array[j]==1) if(k<=Rp) fprintf(fp_src,"AR%d_%d ",k,j);			 
						  else  fprintf(fp_src,"AW%d_%d ",k-Rp,j);
			      else if(k<=Rp) fprintf(fp_src,"ARb%d_%d ",k,j);			 
				   else  fprintf(fp_src,"AWb%d_%d ",k-Rp,j);
			    }
			  fprintf(fp_src," w%d_%d_in / decode%d",k,i,row_bits);
			  }	
                         else if(DC==2){
			 for(j=row_bits-2;j>=0;j--)
			    {
			      if(bit_array[j]==1) if(k<=Rp) fprintf(fp_src,"AR%d_%d ",k,j);			 
						  else  fprintf(fp_src,"AW%d_%d ",k-Rp,j);
			      else if(k<=Rp) fprintf(fp_src,"ARb%d_%d ",k,j);			 
				   else  fprintf(fp_src,"AWb%d_%d ",k-Rp,j);
			    }
			  fprintf(fp_src," w%d_%d_in / decode%d",k,i,row_bits-1);
			 }
			else if(DC==4)
			{
			 for(j=row_bits-3;j>=0;j--)
			    {
			      if(bit_array[j]==1) if(k<=Rp) fprintf(fp_src,"AR%d_%d ",k,j);			 
						  else  fprintf(fp_src,"AW%d_%d ",k-Rp,j);
			      else if(k<=Rp) fprintf(fp_src,"ARb%d_%d ",k,j);			 
				   else  fprintf(fp_src,"AWb%d_%d ",k-Rp,j);
			    }
			  fprintf(fp_src," w%d_%d_in / decode%d",k,i,row_bits-2);
			 }
			}
		}
	  fprintf(fp_src,"\n\n.ENDS\n\n");
      }//create_SRAM

void d2b(int value,int bits)
	{
	  int i,j;
          for(i=0;i<bits;i++)
	     {
		bit_array[i] = value % 2;
		value = value /2;
	     }
	}
