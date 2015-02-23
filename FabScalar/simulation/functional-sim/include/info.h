#include <stdio.h>


#define INFO(fmt, args...)	\
	(fprintf(fp_info, fmt, ## args),	\
	 fprintf(fp_info, "\n"))

extern FILE *fp_info;
