#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "misc.h"
#include "ss.h"
#include "regs.h"
#include "Thread.h"

/* initialize register state to power-up state */
void
Thread::regs_init(void)
{
  int i;

  for (i=0; i<SS_NUM_REGS; i++)
    regs_F.l[i] = regs_R[i] = 0;
  regs_HI = 0;
  regs_LO = 0;
  regs_FCC = 0;
  regs_PC = 0;
}

/* dump the processor (register) state */
void
Thread::regs_dump(FILE *stream)
{
  int i;

  if (!stream)
    stream = stderr;

  fprintf(stream, "Processor state:\n");
  fprintf(stream, "    PC: 0x%08lx\n", regs_PC);
  for (i=0; i<SS_NUM_REGS; i += 2)
    {
      fprintf(stream, "    R[%2d]: %12ld/0x%08lx",
	      i, regs_R[i], regs_R[i]);
      fprintf(stream, "  R[%2d]: %12ld/0x%08lx\n",
	      i+1, regs_R[i+1], regs_R[i+1]);
    }
  fprintf(stream, "    HI:      %10ld/0x%08lx  LO:      %10ld/0x%08lx\n",
	  regs_HI, regs_HI, regs_LO, regs_LO);
  for (i=0; i<SS_NUM_REGS; i += 2)
    {
      fprintf(stream, "    F[%2d]: %12ld/0x%08lx",
	      i, regs_F.l[i], regs_F.l[i]);
      fprintf(stream, "  F[%2d]: %12ld/0x%08lx\n",
	      i+1, regs_F.l[i+1], regs_F.l[i+1]);
    }
  fprintf(stream, "    FCC:                0x%08x\n", regs_FCC);
}
