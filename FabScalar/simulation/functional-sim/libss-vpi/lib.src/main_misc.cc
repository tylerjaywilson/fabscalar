#include <stdio.h>
#include <stdlib.h>
#include <setjmp.h>
#include <signal.h>
#include <sys/types.h>
#ifdef SIM_LINUX	/* 11/5/04 ERIC_CHANGE */
#include <time.h>
#else
#include <sys/time.h>
#endif
#include <string.h>	/* 10/5/96 ERIC_CHANGE */

#include "Thread.h"

/* PRT: added per email from Todd Austin */
#ifdef linux
#ifdef SIM_LINUX
#include <fpu_control.h>
#else
#include <i386/fpu_control.h>
#endif /* linux */
#endif

#include "misc.h"
#include "regs.h"
#include "memory.h"
#include "loader.h"
#include "ss.h"
#include "_endian.h"
#include "version.h"
#include "sim.h"

#include "global_vars.h"

#define JOB_ARGS	64
/* exit when this becomes non-zero */
int sim_exit_now = FALSE;

/* longjmp here when simulation is completed */
jmp_buf sim_exit_buf;

/* instruction jump table */
#ifdef sparc
register void **local_op_jump asm("g7");
#else
void **local_op_jump;
#endif

void tokenize(char *job, int& argc, char **argv) {
  char delimit[4] = " \t\n";	// tokenize based on "space", "tab", eol

  argc = 0;
  while ((argc < JOB_ARGS) &&
         (argv[argc] = strtok((argc ? (char *)NULL : job), delimit))) {
     argc++;
  }

  if (argc == 0)
     fatal("No thread specified.");
}


// 12/26/99 ER: add fork capability.
void ss_fork(Thread *master, SS_ADDR_TYPE ThreadIdPtr, unsigned int id) {
  if (NumThreads == MAX_THREADS)
     fatal("SS_SYS_fork: no more threads available.");

  // Create a (slave) thread.
  THREAD[NumThreads] = new Thread(master, ThreadIdPtr, id);
  NumThreads++;
}

// 12/28/99 ER: wakeup threads blocked on a lock.
void ss_unlock(SS_ADDR_TYPE lockaddr) {
  for (unsigned int i = 0; i < NumThreads; i++)
     THREAD[i]->wakeup(lockaddr);
}

void
sim_config(FILE *stream)
{
}
