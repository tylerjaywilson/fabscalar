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
# Purpose	: Generate the required LEF file for SRAM	   
# Objective	: To be used as a black-box in the place and route tool
#		  for SRAM instatnces
# Usage		: ./SRAM_lef <total entries> <data width> <read ports>
#			     <write ports> <width(um)> <height(um)> <site name>
#**************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

int main(int argc, char * argv[])
    {
       int Rp, Wp, size_width, size_depth,i,a_bits,j,k,d_bits;
       double height, width,h,w;
       FILE *lef_fp;
       char wpath[200]="SRAM_8R4W_PRF";
       char site_name[200] ;

       size_depth = atoi(argv[1]);
       size_width = atoi(argv[2]);
       Rp = atoi(argv[3]);
       Wp = atoi(argv[4]);
       width = atof(argv[5]);
       height = atof(argv[6]);

       height = floor(height);
       width = floor(width);
       sprintf(wpath,"SRAM_%s.lef",argv[7]);
       sprintf(site_name,"SRAM_%s",argv[7]);


       lef_fp = fopen(wpath,"w");

       if(lef_fp == NULL)
          {
                printf("File couldn't open for write\n");
                exit(0);
          }
          else
                {
		  fprintf(lef_fp,"VERSION 5.6 ;");
                  fprintf(lef_fp,"\nBUSBITCHARS \"[]\" ;\nDIVIDERCHAR \"/\" ;\n");
		  fprintf(lef_fp,"\nUNITS\n  DATABASE MICRONS 2000 ;\nEND UNITS\n");
		  fprintf(lef_fp,"\nMANUFACTURINGGRID 0.0005 ;\n");
		  fprintf(lef_fp,"\nSITE SITE_%s",site_name);
		  fprintf(lef_fp,"\n  CLASS CORE ;\n  SIZE %f BY %f ;\n",width,height);
		  fprintf(lef_fp,"  SYMMETRY X Y R90 ;\n");
		  fprintf(lef_fp,"END SITE_%s\n",site_name);
		  fprintf(lef_fp,"\nMACRO %s\n",site_name);
		  fprintf(lef_fp,"  CLASS BLOCK ;\n  FOREIGN %s 0 0 ;\n  ORIGIN 0 0 ;",site_name);
		  fprintf(lef_fp,"\n  SIZE %f BY %f ;\n",width,height);
		  fprintf(lef_fp,"  SYMMETRY X Y R90 ;\n");
		  fprintf(lef_fp,"\nSITE SITE_%s ;\n",site_name);
                  a_bits = round(log(size_depth) / log(2));

                  // h = round(height) - 1.00000;
		  // Address pins for first quarter read ports
		  // starting from upper left corner 
		  w = 1.0 ;
                  for(j=0;j<Rp/4;j++){
			  for(i=0;i<a_bits;i++) {
				  fprintf(lef_fp,"\n  PIN addr%d_i[%d]",j,i);
				  fprintf(lef_fp,"\n\tDIRECTION INPUT ;\n\tUSE SIGNAL ;\n\tPORT\n\t\tLAYER M2 ;");
				  fprintf(lef_fp,"\n\t\tRECT ( %f %f ) ( %f %f ) ;",w,height-0.3,w+0.07, height-0.2) ;
				  fprintf(lef_fp,"\n\tEND\n  END addr%d_i[%d]",j,i);
	                	  w = w + 0.14;
			  }
                  }
		  // Address pins and write enable pins for half write ports
		  w = w + 0.5;
		  for(j=0;j<Wp/2;j++){
                	  for(i=0;i<a_bits;i++) {
		                  fprintf(lef_fp,"\n  PIN addr%dwr_i[%d]",j,i);
		                  fprintf(lef_fp,"\n\tDIRECTION INPUT ;\n\tUSE SIGNAL ;\n\tPORT\n\t\tLAYER M2 ;");
		                  fprintf(lef_fp,"\n\t\tRECT ( %f %f ) ( %f %f ) ;",w,height-0.3,w+0.07, height-0.2) ;
		                  fprintf(lef_fp,"\n\tEND\n  END addr%dwr_i[%d]",j,i);
		                  w = w + 0.14;
                  	}
			  fprintf(lef_fp,"\n  PIN we%d_i",j);
			  fprintf(lef_fp,"\n\tDIRECTION INPUT ;\n\tUSE SIGNAL ;\n\tPORT\n\t\tLAYER M2 ;");
			  fprintf(lef_fp,"\n\t\tRECT ( %f %f ) ( %f %f ) ;", w,height-0.3,w+0.07, height-0.2) ;
			  fprintf(lef_fp,"\n\tEND\n  END we%d_i",j);
			  w = w+0.14;
		  }
		 
		  // Data out pins for the half read ports
		  w = w + 0.5 ;
		  for(j=0;j<Rp/2;j++){
	                  for(k=0;k<size_width;k++){
				  fprintf(lef_fp,"\n  PIN data%d_o[%d]",j,k);
				  fprintf(lef_fp,"\n\tDIRECTION INPUT ;\n\tUSE SIGNAL ;\n\tPORT\n\t\tLAYER M2 ;");
				  fprintf(lef_fp,"\n\t\tRECT ( %f %f ) ( %f %f ) ;",w,height-0.3,w+0.07, height-0.2) ;
				  fprintf(lef_fp,"\n\tEND\n  END data%d_o[%d]",j,k);
		                  w = w + 0.14;
			  }
                  }
		  
		  // Data in pins for write ports
		  w = w + 0.5;
		  for(j=0;j<Wp;j++){
	                  for(k=0;k<size_width;k++){
				  fprintf(lef_fp,"\n  PIN data%dwr_i[%d]",j,k);
				  fprintf(lef_fp,"\n\tDIRECTION INPUT ;\n\tUSE SIGNAL ;\n\tPORT\n\t\tLAYER M2 ;");
				  fprintf(lef_fp,"\n\t\tRECT ( %f %f ) ( %f %f ) ;",w,height-0.3, w + 0.07 ,height-0.2) ;
				  fprintf(lef_fp,"\n\tEND\n  END data%dwr_i[%d]",j,k);
        		          w = w + 0.14;
			  }
		  }

		  // Addres pins for 2nd quarter of read ports
		  w = width-0.14 ;
                  for(j=Rp/4;j<Rp/2;j++){
	                  for(i=0;i<a_bits;i++) {
		                  fprintf(lef_fp,"\n  PIN addr%d_i[%d]",j,i);
		                  fprintf(lef_fp,"\n\tDIRECTION INPUT ;\n\tUSE SIGNAL ;\n\tPORT\n\t\tLAYER M2 ;");
		                  fprintf(lef_fp,"\n\t\tRECT ( %f %f ) ( %f %f ) ;",w,height-0.3,w+0.07, height-0.2) ;
		                  fprintf(lef_fp,"\n\tEND\n  END addr%d_i[%d]",j,i);
		                  w = w - 0.14;
        	          }
                  }

		  // Address pins and write enable pins for other half write ports
		  w = w - 0.2;
                  for(j=Wp/2;j<Wp;j++){
	                  for(i=0;i<a_bits;i++) {
		                  fprintf(lef_fp,"\n  PIN addr%dwr_i[%d]",j,i);
		                  fprintf(lef_fp,"\n\tDIRECTION INPUT ;\n\tUSE SIGNAL ;\n\tPORT\n\t\tLAYER M2 ;");
		                  fprintf(lef_fp,"\n\t\tRECT ( %f %f ) ( %f %f ) ;",w,height-0.3,w+0.07, height-0.2) ;
		                  fprintf(lef_fp,"\n\tEND\n  END addr%dwr_i[%d]",j,i);
		                  w = w - 0.14;
                  	}
	                  fprintf(lef_fp,"\n  PIN we%d_i",j);
	                  fprintf(lef_fp,"\n\tDIRECTION INPUT ;\n\tUSE SIGNAL ;\n\tPORT\n\t\tLAYER M2 ;");
	                  fprintf(lef_fp,"\n\t\tRECT ( %f %f ) ( %f %f ) ;", w,height-0.3,w+0.07, height-0.2) ;
	                  fprintf(lef_fp,"\n\tEND\n  END we%d_i",j);
	                  w = w - 0.14;
                  }

		  h = 1.0;
		  w = 4.0;

		  // Address pins for 3rd quarter of read ports
                  for(j=Rp/2;j<3*Rp/4;j++){
	                  for(i=0;i<a_bits;i++) {
		                  fprintf(lef_fp,"\n  PIN addr%d_i[%d]",j,i);
		                  fprintf(lef_fp,"\n\tDIRECTION INPUT ;\n\tUSE SIGNAL ;\n\tPORT\n\t\tLAYER M2 ;");
		                  fprintf(lef_fp,"\n\t\tRECT ( %f %f ) ( %f %f ) ;",w,h,w+0.07, h+0.1) ;
		                  fprintf(lef_fp,"\n\tEND\n  END addr%d_i[%d]",j,i);
		                  w = w + 0.14;
                  	}
                  }

		  // Data out pins for other half read ports
		  w = w + 1.0;
		  for(j=Rp/2;j<Rp;j++){
	                  for(k=0;k<size_width;k++){
		                  fprintf(lef_fp,"\n  PIN data%d_o[%d]",j,k);
		                  fprintf(lef_fp,"\n\tDIRECTION INPUT ;\n\tUSE SIGNAL ;\n\tPORT\n\t\tLAYER M2 ;");
		                  fprintf(lef_fp,"\n\t\tRECT ( %f %f ) ( %f %f ) ;",w,h,w+0.07, h+0.1) ;
		                  fprintf(lef_fp,"\n\tEND\n  END data%d_o[%d]",j,k);
		                  w = w + 0.14;
                  	}
                  }

		  // Address pins for 4th quarter read ports
		  w = width - 1.0;
                  for(j=3*Rp/4;j<Rp;j++){
	                  for(i=0;i<a_bits;i++) {
	                  fprintf(lef_fp,"\n  PIN addr%d_i[%d]",j,i);
	                  fprintf(lef_fp,"\n\tDIRECTION INPUT ;\n\tUSE SIGNAL ;\n\tPORT\n\t\tLAYER M2 ;");
	                  fprintf(lef_fp,"\n\t\tRECT ( %f %f ) ( %f %f ) ;",w,h,w+0.07, h+0.1) ;
	                  fprintf(lef_fp,"\n\tEND\n  END addr%d_i[%d]",j,i);
	                  w = w - 0.14;
                  	}
                  }

  		fprintf(lef_fp,"\n\n  OBS\n\t LAYER M1 ;\n\tRECT ( 0 0 ) ( %lf %lf ) ;",width , height);
	 	fprintf(lef_fp,"\n  END");
	 	fprintf(lef_fp,"\n  END %s",site_name); 
     		}    
       return 0;
    }



