/***************************************************************************
#                        NORTH CAROLINA STATE UNIVERSITY
#
#                               FabScalar Project
#
# Purpose:    CAM full netlist  file generation
#
# Author:     Tanmay Shah
#
#**************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#define MAX_COMMAND_ARGS 4

int D,W,Rp,Wp;
int bit_array[8];
void create_CAM(int ,int ,int ,int );
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
	exit(0);
    }

      /* Read the command line arguments into variables. */
      D  = atoi(argv[1]);
      W  = atoi(argv[2]);
      Rp = atoi(argv[3]);
      Wp = atoi(argv[4]);

      create_CAM(D,W,Rp,Wp);
      return 0;

}


void create_CAM(int D,int W,int Rp,int Wp)
	{
	     int depth,width;   
	     int instance_no,row_bits;
	     int i,j,k;  
             char str[50];
	     FILE *fp_src;
	     depth=D;
	     width=W;
             sprintf(str,"cam_%d_%d_%d_%d.src.net",D,W,Rp,Wp);	
             fp_src=fopen(str,"w");
	     instance_no = 0;
      	     row_bits = ceil( (log(depth) / log(2)));

         //    fprintf(fp_src,"\n*.EQUATION \n*.SCALE METER \n*.MEGA \n.PARAM\n");
	     fprintf(fp_src,"\n*.GLOBAL vdd! \n+        gnd! \n\n*.PIN vdd! \n*+    gnd!\n");
             sprintf(str,"cam_%d_%d_%d_%d",D,W,Rp,Wp);	
             fprintf(fp_src,"\n\n.include ../netGen_CAM/buff.src.net");
             fprintf(fp_src,"\n\n.include ../netGen_CAM/precharge.src.net");
             fprintf(fp_src,"\n\n.include ../netGen_CAM/wdata_nodc.src.net");
             fprintf(fp_src,"\n\n.include ../netGen_CAM/%dr%dw_new.src.net",Rp,Wp);
             fprintf(fp_src,"\n\n.include ../netGen_CAM/decoder.src.net",row_bits);
             fprintf(fp_src,"\n\n.include ../netGen_CAM/nand2.src.net",row_bits);

             fprintf(fp_src,"\n\n\n.SUBCKT %s clk\n\t+",str);

/************************* PORT LIST *********************/
             for(i=1;i<=Wp;i++)
		{
		   for(j=0;j<row_bits;j++)
			{
			   fprintf(fp_src,"AW%d<%d> ",i,j);  //For address line
			}                    
			   fprintf(fp_src,"\n\t+");			
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
			fprintf(fp_src," D%d<%d> ",j,i);   //For Input data to be written
		      }
             	   fprintf(fp_src,"\n\t+");
		}
             fprintf(fp_src,"\n\t+");
            
             for(i=0;i<depth;i++)
		{
		   for(j=1;j<=Rp;j++)
		      {
			fprintf(fp_src," ML_%d<%d> ",j,i);   //For output Match Lines
		      }
             	   fprintf(fp_src,"\n\t+");
		}

             fprintf(fp_src,"\n\t+");
             for(i=0;i<width;i++)
                {
                   for(j=1;j<=Rp;j++)
                      {
                        fprintf(fp_src," CW_%d<%d> ",j,i);   //For output Match Lines
                      }
                   fprintf(fp_src,"\n\t+");
                }


             fprintf(fp_src,"\n");

/************************* PIN INFO ********************/
             fprintf(fp_src,"\n*.PININFO clk:I ");
             for(i=1;i<=Wp;i++)
		{
                  fprintf(fp_src,"\n\t*.PININFO");
		   for(j=0;j<row_bits;j++)
			{
			   fprintf(fp_src,"AW%d<%d>:I ",i,j);  //For address line
//			   fprintf(fp_src," A%d<%d>:I ",i,j);  //For address line
			}                    
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
			fprintf(fp_src," ML_%d<%d>:O ",j,i);   //For Input data
		      }
		}

             for(i=0;i<width;i++)
                {
                   fprintf(fp_src,"\n\t*.PININFO ");
                   for(j=1;j<=Rp;j++)
                      {
                        fprintf(fp_src," CW_%d<%d>:I ",j,i);   //For output Match Lines
                      }
                }

                fprintf(fp_src,"\n");

/*************** bitcell placement *******************/
	     for(i=0;i<depth;i++)
	     {
                for(j=0;j<width;j++)
	        {       
                  //  if(i<=1 || j==0) {
		   	fprintf(fp_src,"XI%d ",instance_no++);
	                for(k=1;k <= Wp;k++)
	                {
	  		   fprintf(fp_src,"w%d_%d ",k,i);               
	                }
                        for(k=1;k <= Rp;k++)
                        {
                           fprintf(fp_src,"ML_%d<%d> ",k,i);
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
             for(i=0;i<depth;i++)
		{
		   for(j=1;j<=Wp;j++)
			{
			   if(width>32)
			   {
			      fprintf(fp_src,"\nXI%d clk ML_%d<%d> / precharge72",instance_no++,j,i);	
			   }
			   else
			   {
			      fprintf(fp_src,"\nXI%d clk ML_%d<%d> / precharge",instance_no++,j,i);	
			   }
			}
		}

/*********************** Write CKT ********************/
             for(i=0;i<width;i++)
		{
		   for(j=1;j<=Wp;j++)
			{
			   fprintf(fp_src,"\nXI%d D%d<%d> Db%d_%d / inverter",instance_no++,j,i,j,i); 	
			   fprintf(fp_src,"\nXI%d b%d_%d  clk Db%d_%d WREN%d / wdata_nodc",instance_no++,j,i,j,i,j);
			   fprintf(fp_src,"\nXI%d bb%d_%d  clk D%d<%d> WREN%d / wdata_nodc",instance_no++,j,i,j,i,j);	
			}
		}

/************************* Input Buffer for the Address lines ***************************/
 	    for(j=1;j<=Wp;j++)
	     {
                for(i=0;i<row_bits;i++)
		  {
		  fprintf(fp_src,"\nXI%d AW%d<%d> AW%d_%d AWb%d_%d / buff3",instance_no++,j,i,j,i,j,i);
		  }
	     }	
/*********************** WL driver (buffer) ***********************/
             for(i=0;i<depth;i++)
		{
		   for(j=1;j<=Wp;j++)
			{
			   fprintf(fp_src,"\nXI%d w%d_%d w%d_%d_in / buff",instance_no++,j,i,j,i);	
			}
		}
	   for(k=1;k<=Wp;k++)
		{
		   for(i=0;i<depth;i++)
			{
                         d2b(i,row_bits);
			 fprintf(fp_src,"\nXI%d clk ",instance_no++);

			 for(j=row_bits-1;j>=0;j--)
			    {
			      if(bit_array[j]==1) fprintf(fp_src,"AW%d_%d ",k,j);
			      else fprintf(fp_src,"AWb%d_%d ",k,j);
			    }
			  fprintf(fp_src," w%d_%d_in / decode%d",k,i,row_bits);
			  	
			}
		}
/************************* SL driver **************************/
	for(i=0; i<width ; i++)
	{
		for(j=Wp+1;j<=Wp+Rp;j++)
		{
			fprintf(fp_src,"\nXI%d dslb%d_%d b%d_%d / inverter_4",instance_no++,j-Wp,i,j,i);
			fprintf(fp_src,"\nXI%d dsl%d_%d bb%d_%d / inverter_4",instance_no++,j-Wp,i,j,i);
		}
	}

        for(i=0; i<width ; i++)
        {
                for(j=1;j<=Rp;j++)
                {
			fprintf(fp_src,"\nXI%d CW_%d<%d> CWi_%d_%d / inverter",instance_no++,j,i,j,i);
		}
	}

/************************ SL NAND2 ******************************/
	for(i=0; i<width ; i++)
        {
                for(j=1;j<=Rp;j++)
                {
			fprintf(fp_src,"\nXI%d CW_%d<%d> clk dsl%d_%d / nand2",instance_no++,j,i,j,i);
			fprintf(fp_src,"\nXI%d CWi_%d_%d clk dslb%d_%d / nand2",instance_no++,j,i,j,i);
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
