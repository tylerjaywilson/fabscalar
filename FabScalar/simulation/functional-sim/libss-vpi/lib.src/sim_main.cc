#include <stdio.h>
#include <string.h>
#include <math.h>
#include <assert.h>

#include "misc.h"
#include "mt_trace_consume.h"
#include "Thread.h"
#include "global_vars.h"
/////////////////////////////////////////////////////////////////////

void
sim_config(FILE *stream)
{
}

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


void
sim_main(void)
{

  ///////////////////////////////////////
  // Decode the binaries of each thread.
  ///////////////////////////////////////
  for (unsigned int i = 0; i < NumThreads; i++)
     THREAD[i]->decode();

  ///////////////////////////////////////
  // Initialize trace consumer.
  ///////////////////////////////////////
  trace_consume_init();

  ////////////////////////////////
  // Simulator Loop.
  ////////////////////////////////
  trace_consume();

}	// sim_main()
