// This function reads the simulation parameters from a config file, opens the job file, loads the ckeckpoint,
// performs the skip.

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "Thread.h"
// #include "veri_memory.h"
#include "global_vars.h"
// #include "VPI_global_vars.h"

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

/* if error message should be printed */
extern int	getopt_error;
/* index into parent argv vector */
extern int	getopt_index;
/* argument associated with option */
extern char *getopt_arg;

extern void getopt_init(void);
extern char getopt_next(int nargc, char **nargv, char *ostr);

extern char *verilog_optstring;
// extern FILE* CHECKPOINT;
#define MAX_ARGS 64


void read_config_from_file(int& nargs, char ***args, FILE **fp_job) {

  FILE *fp_config;
  char buf[256];
  int num, exec_index;
  char c;
  int i;

  num = 0;
  fp_config = fopen("config","r"); 

  if (fp_config == NULL) {
    fprintf(stderr, "Cannot open config file\n");
    exit(0);
  }

  fprintf(stderr, "Reading from config file\n");

  if ((*args) == NULL) {
    (*args) = (char **) malloc (MAX_ARGS*sizeof(char*));
  }
  while (!feof(fp_config)) {
    fscanf(fp_config, "%s", buf);
    if (strcmp(buf,"\n")) {
      //if ((*args)[num] == NULL)
	(*args)[num] = (char *) malloc(strlen(buf) * sizeof(char));
      strcpy((*args)[num], buf);
      // fprintf(stderr, "%d %s\n", num, (*args)[num]);
      num++;
    }
    strcpy(buf , "");
  }
  nargs = num - 1;
  if (nargs == 0)
    fprintf(stderr, "No parameters or job file specified in config!!\n");

  fprintf(stderr, "Finished reading from config file. nargs = %d\n", nargs);
  for (i = 0; i < nargs; i++)
    fprintf(stderr, "%d %s\n", i, (*args)[i]);

  getopt_init();
  while ((c = getopt_next(nargs, (*args), verilog_optstring)) != EOF);
  exec_index = getopt_index;
//   if (exec_index == nargs)
//     exec_index--;
  fprintf(stderr, "exec_index = %d\n", exec_index);

  // Must do getopt_init()
  getopt_init();
  while ((c = getopt_next(nargs, (*args), verilog_optstring)) != EOF) {
    fprintf(stderr, "Option: %c\n", c);
    switch(c) {

    case 'Y': // Load Checkpoint File                                                                                                        
      fprintf(stderr, "Checkpoint file: %s\n",getopt_arg);
      CHECKPOINT = fopen(getopt_arg, "r");
      if (CHECKPOINT == NULL)
	fprintf(stderr, "Cannot load checkpoint %s\n",getopt_arg);
      break;

    case 'z':
      USE_INSTR_LIMIT = true;
      INSTR_LIMIT = atoll(getopt_arg);
      break;

    case 'Z':
      SKIP_AMT = atoll(getopt_arg);
      break;

    default:
      break;

    } // switch
  } // while

  if (USE_INSTR_LIMIT)
    INSTR_LIMIT = (SKIP_AMT + INSTR_LIMIT);
 
  fprintf(stderr, "jobfile = %s\n", (*args)[exec_index]);
  // Open the job file
  (*fp_job) = fopen((*args)[exec_index], "r");
  if ((*fp_job) == NULL) {
    fprintf(stderr,"Cannot open job file\nexec_index = %d\n", exec_index);
    exit(0);
  }


} // read_config_from_file
