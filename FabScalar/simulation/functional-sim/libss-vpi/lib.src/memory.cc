#include <stdio.h>
#include <stdlib.h>
#include "misc.h"
#include "ss.h"
#include "loader.h"
#include "regs.h"
#include "memory.h"
#include "sim.h"
#include "Thread.h"

/* generic memory access function, its safe because alignments and permissions
   are checks, handles any resonable transfer size; note, bombs if nbytes
   is larger then MEM_BLOCK_SIZE */
void
Thread::mem_access(enum mem_cmd cmd, SS_ADDR_TYPE addr, void *vp, int nbytes)
{
  char *p = (char*)vp;

  /* check alignments */
  if ((nbytes & (nbytes-1)) != 0 || (addr & (nbytes-1)) != 0)
    fatal("access error: bad size or alignment, addr 0x%08x", addr);

  /* check permissions */
  if (!((addr >= ld_text_base && addr < (ld_text_base+ld_text_size)
	 && cmd == Read)
	|| (addr >= ld_data_base && addr < ld_stack_base)))
    fatal("access error: segmentation violation, addr 0x%08x", addr);

  /* track the minimum SP */
  if (addr > mem_brk_point && addr < mem_stack_min)
    mem_stack_min = addr;

  switch (nbytes) {
  case 1:
    if (cmd == Read)
      *((unsigned char *)p) = MEM_BYTE(addr);
    else
      MEM_BYTE(addr) = *((unsigned char *)p);
    break;
  case 2:
    if (cmd == Read)
      *((unsigned short *)p) = MEM_HALF(addr);
    else
      MEM_HALF(addr) = *((unsigned short *)p);
    break;
  case 4:
    if (cmd == Read)
      *((unsigned long *)p) = MEM_WORD(addr);
    else
      MEM_WORD(addr) = *((unsigned long *)p);
    break;
  default:
    {
      /* nbytes >= 8 and power of two */
      int words = nbytes >> 2;
      if (cmd == Read)
	{
	  while (words-- > 0)
	    {
	      *((unsigned long *)p) = MEM_WORD(addr);
	      p += 4;
	      addr += 4;
	    }
	}
      else
	{
	  while (words-- > 0)
	    {
	      MEM_WORD(addr) = *((unsigned long *)p);
	      p += 4;
	      addr += 4;
	    }
	}
    }
    break;
  }
}

/* allocate a memory block */
char *
Thread::mem_newblock(void)
{
  return (char*)getcore(MEM_BLOCK_SIZE);
}

/* copy a string through a memory access function, returns the
   number of bytes copied */
int
Thread::mem_strcpy(mem_access_fn mem_fn, enum mem_cmd cmd,
	           SS_ADDR_TYPE addr, char *s)
{
  int n = 0;
  char c;

  switch (cmd) {
  case Read:
    do {
      (this->*mem_fn)(Read, addr++, &c, 1);
      *s++ = c;
      n++;
    } while (c);
    break;
  case Write:
    do {
      c = *s++;
      (this->*mem_fn)(Write, addr++, &c, 1);
      n++;
    } while (c);
    break;
  default:
    panic("bogus memory command");
  }
  return n;
}

/* copy NBYTES through a memory access function */
void
Thread::mem_bcopy(mem_access_fn mem_fn, enum mem_cmd cmd, SS_ADDR_TYPE addr,
	          void *vp, int nbytes)
{
  char *p = (char*)vp;
  while (nbytes-- > 0)
    (this->*mem_fn)(cmd, addr++, p++, 1);
}

/* copy NBYTES through a memory access function, NBYTES is a multiple
   of 4 bytes */
void
Thread::mem_bcopy4(mem_access_fn mem_fn, enum mem_cmd cmd, SS_ADDR_TYPE addr,
	           void *vp, int nbytes)
{
  char *p = (char*)vp;
  int words = nbytes >> 2;
  while (words-- > 0)
    (this->*mem_fn)(cmd, addr += 4, p += 4, 4);
}

/* zero out NBYTES through a memory access function */
void
Thread::mem_bzero(mem_access_fn mem_fn, SS_ADDR_TYPE addr, int nbytes)
{
  char c = 0;
  while (nbytes-- > 0)
    (this->*mem_fn)(Write, addr++, &c, 1);
}

/* memory system-specific options */
char *mem_optstring = "";

/* initialize memory system */
void
Thread::mem_init(void)
{
  mem_brk_point = ROUND_UP(ld_data_base + ld_data_size, SS_PAGE_SIZE);
  mem_stack_min = regs_R[SS_STACK_REGNO];
}

/* parse memory system-specific options */
void
mem_options(int argc, char **argv)
{
  char c;

  /* parse options */
  getopt_init();
  while ((c = getopt_next(argc, argv, mem_optstring)) != EOF)
    {
      switch (c) {
      }
    }
}

/* print out memory system configuration */
void
mem_config(FILE *stream)
{
}

/* dump memory system stats */
#define IN_K(N)         (((N)+1023) / 1024)
void
Thread::mem_stats(FILE *stream)
{
  long sum = 0;

  fprintf(stream, "mem: total stack:  %8ldk\n",
	  IN_K(SS_STACK_BASE-mem_stack_min));
  sum += IN_K(SS_STACK_BASE-mem_stack_min);
  fprintf(stream, "mem: total heap:   %8ldk\n",
	  IN_K(mem_brk_point-(ld_data_base+ld_data_size)));
  sum += IN_K(mem_brk_point-(ld_data_base+ld_data_size));
  fprintf(stream, "mem: total data:   %8ldk\n",
	  IN_K((ld_data_base+ld_data_size)-SS_DATA_BASE));
  sum += IN_K((ld_data_base+ld_data_size)-SS_DATA_BASE);
  fprintf(stream, "mem: total memory: %8ldk\n", sum);
}
#undef IN_K

/* dump the contents of LEN words of memory at ADDR to file stream STREAM */
void
Thread::mem_dump(mem_access_fn mem_fn, SS_ADDR_TYPE addr, int len, FILE *stream)
{
  long data;

  if (!stream)
    stream = stderr;

  addr &= sizeof(long);
  len = (len+(sizeof(long)-1)) & sizeof(long);
  while (len-- > 0)
    {
      (this->*mem_fn)(Read, addr, &data, sizeof(long));
      fprintf(stream, "0x%08lx: %08lx\n", addr, data);
      addr += sizeof(long);
    }
}


/* 12/25/99 ER: Shared memory. */
char *shmem_table[MEM_TABLE_SIZE];
