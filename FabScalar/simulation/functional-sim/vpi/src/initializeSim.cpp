#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
// SW:20090402: Copied from main.cc
#include <signal.h>
/* PRT: added per email from Todd Austin */
#ifdef linux
#ifdef SIM_LINUX
#include <fpu_control.h>
#else
#include <i386/fpu_control.h>
#endif /* linux */
#endif


//#include <unistd.h>
#include "vpi_user.h"
#include "Thread.h"
//#include "memory.h"
//#include "_endian.h"
//#include "sim.h"
#include "veri_memory_macros.h"
#include "veri_memory.h"
#include "VPI_global_vars.h"
#include "global_vars.h"

// #define JOB_ARGS	64

extern void tokenize(char *job, int& argc, char **argv);
extern void read_config_from_file(int& nargs, char ***args, FILE **fp_job);

/* byte/word swapping required to execute target executable on this host */
int sim_swap_bytes;
int sim_swap_words;


// void tokenize(char *job, int& argc, char **argv) {
//   char delimit[4] = " \t\n";	// tokenize based on "space", "tab", eol

//   argc = 0;
//   while ((argc < JOB_ARGS) &&
//          (argv[argc] = strtok((argc ? (char *)NULL : job), delimit))) {
//      argc++;
//   }

//   if (argc == 0)
//      printf("No thread specified.\n");
// }


int initializeSim(char *user_data)
{
  char *binary[] = {"nc.exe", NULL};
  char **ptr_binary = binary;
  char *env[] = {NULL};
  char **ptr_env = env;
  FILE *fp_job;
  char job[256];
  int i;
  int argc;
  char **argv;
  unsigned long long skip_dist;
//   THREAD = new Thread(); 

  /* opening banner */

  /* 8/20/05 ER: Add banner for 721 simulator.
  fprintf(stderr,
          "\n\n721 Simulator Copyright (c) 1999-2005 by Eric Rotenberg.  All Rights Reserved.\n");
  fprintf(stderr,
          "Welcome to the ECE 721 Simulator.  This is a custom simulator\n");
  fprintf(stderr,
          "developed at North Carolina State University by Eric Rotenberg\n");
  fprintf(stderr,
          "and his students.  It uses the Simplescalar ISA and only those\n");
  fprintf(stderr,
          "files from the Simplescalar toolset needed to functionally\n");
  fprintf(stderr,
          "simulate a Simplescalar binary, copyright below:\n");

  fprintf(stderr,
          "Copyright (c) 1994-1995 by Todd M. Austin.  All Rights Reserved.\n\n");*/

  /* PRT: added per email from Todd Austin */
  #ifdef linux
  /* get linux to perform 64-bit FP (not IA 80-bit) for compatibility */
  {
    int cw = (_FPU_DEFAULT & ~(3 << 8)) | _FPU_DOUBLE;
#ifdef SIM_LINUX
    _FPU_SETCW(cw);
#else
    __setfpucw(cw);
#endif
  }
#endif /* linux */

  /* PRT: added per email from Todd Austin */
  /* FIXME: should ignore FP faults only in speculative mode */
  signal(SIGFPE, SIG_IGN);

  /* initialize the instruction decoder */
  ss_init_decoder();


  fp_info = fopen("outfile","w");
  if (fp_info == NULL) {
    fprintf(stderr,"Cannot open output file\n");
    exit(0);
  }

//   argv = (char **) malloc (256 * sizeof(char *));
//   for (i = 0; i < 256; i++) {
//     argv[i] = (char *) malloc (256 * sizeof(char));
//     strcpy(argv[i],"");
//   }

//   // Configure job  
//   fp_job = fopen("job", "r");
//   if (fp_job == NULL) {
//     fprintf(stderr,"Cannot open job file\n");
//     exit(0);
//   }

  read_config_from_file(argc, &argv, &fp_job);
  assert(fp_job);
  fgets(job, 256, fp_job);
  fprintf(stderr, "job = %s\n", job);
  tokenize(job, argc, argv);

  // Create Thread and Verilog memory instances
  THREAD[0] = new Thread(argc,argv,ptr_env); 
  VMEM[0] = new veri_memory(0, 
			    THREAD[0]->get_ld_text_base(),
			    THREAD[0]->get_ld_text_size());
  // Copy memory from Thread's undecoded mem_table to a separate text(code) mem_table for Verilog
  // This function should only be called ONCE ever. If the text_mem_table is overwritten, 
  // the Verilog simulator will fail
  VMEM[0]->copy_text_mem(THREAD[0]->get_mem_table());

  // Now pre-decode the binary for the functional simulator
  THREAD[0]->decode();

  ///////////////////////
  // Load Checkpoint File
  ///////////////////////
  if (CHECKPOINT != NULL)
    {
      vpi_printf("\nRestoring functional checkpoint\n");
      THREAD[0]->restore_checkpoint(CHECKPOINT);

//       if (SKIP_AMT < THREAD[0]->num_insn)
// 	{
// 	  vpi_printf("Invalid Skip Amount for this Checkpoint.\n");
// 	  vpi_printf("Skip Amount: %lld\n", SKIP_AMT);
// 	  vpi_printf("Checkpointed Skip Amount: %lld\n",
// 		 THREAD[0]->num_insn);
// 	  exit(0);
// 	}

//       vpi_printf("\nFunctional simulation restored to ");
//       skip_dist = THREAD[0]->num_insn;
//       if (skip_dist < 1000) vpi_printf("%u", skip_dist);
//       else if (skip_dist < 1000000) vpi_printf("%.2f K",
// 					   ((double)skip_dist)/1000);
//       else if (skip_dist < 1000000000) vpi_printf("%.2f M",
// 					      ((double)skip_dist)/1000000);
//       else vpi_printf("%.2f B", ((double)skip_dist)/1000000000);
//       vpi_printf(" instructions\n");
    }

  ///////////////////////////                                                                                                                
  // Perform Instruction Skip                                                                                                                
  ///////////////////////////                                                                                                                

  if (SKIP_AMT)
    {
//       skip_dist = SKIP_AMT - THREAD[0]->num_insn;
//       vpi_printf("Fast skipping ");
//       if (skip_dist < 1000) vpi_printf("%u", skip_dist);
//       else if (skip_dist < 1000000) vpi_printf("%.2f K",
// 					   ((double)skip_dist)/1000);
//       else if (skip_dist < 1000000000) vpi_printf("%.2f M",
// 					      ((double)skip_dist)/1000000);
//       else vpi_printf("%.2f B", ((double)skip_dist)/1000000000);

      vpi_printf("Fast skipping instructions.....\n");
      THREAD[0]->skip(SKIP_AMT);
    }

  return(0);    
} // initializeSim


void initializeSim_register() {
  s_vpi_systf_data task_init;

  task_init.type      = vpiSysTask;
  task_init.tfname    = "$initialize_sim";
  task_init.calltf    = initializeSim;
  task_init.compiletf = 0;

  vpi_register_systf(&task_init);
} // initializeSim_register()
