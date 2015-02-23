/*
 * syscall.c - proxy system call handler routines
 *
 * This file is a part of the SimpleScalar tool suite written by
 * Todd M. Austin as a part of the Multiscalar Research Project.
 *  
 * The tool suite is currently maintained by Doug Burger and Todd M. Austin.
 * 
 * Copyright (C) 1994, 1995, 1996, 1997 by Todd M. Austin
 *
 * This source file is distributed "as is" in the hope that it will be
 * useful.  The tool set comes with no warranty, and no author or
 * distributor accepts any responsibility for the consequences of its
 * use. 
 * 
 * Everyone is granted permission to copy, modify and redistribute
 * this tool set under the following conditions:
 * 
 *    This source code is distributed for non-commercial use only. 
 *    Please contact the maintainer for restrictions applying to 
 *    commercial use.
 *
 *    Permission is granted to anyone to make or distribute copies
 *    of this source code, either as received or modified, in any
 *    medium, provided that all copyright notices, permission and
 *    nonwarranty notices are preserved, and that the distributor
 *    grants the recipient permission for further redistribution as
 *    permitted by this document.
 *
 *    Permission is granted to distribute this file in compiled
 *    or executable form under the same conditions that apply for
 *    source code, provided that either:
 *
 *    A. it is accompanied by the corresponding machine-readable
 *       source code,
 *    B. it is accompanied by a written offer, with no time limit,
 *       to give anyone a machine-readable copy of the corresponding
 *       source code in return for reimbursement of the cost of
 *       distribution.  This written offer must permit verbatim
 *       duplication by anyone, or
 *    C. it is distributed by someone who received only the
 *       executable form, and is accompanied by a copy of the
 *       written offer of source code that they received concurrently.
 *
 * In other words, you are welcome to use, share and improve this
 * source file.  You are forbidden to forbid anyone else to use, share
 * and improve what you give them.
 *
 * INTERNET: dburger@cs.wisc.edu
 * US Mail:  1210 W. Dayton Street, Madison, WI 53706
 *
 * $Id: syscall.cc,v 1.1 2010/02/06 21:33:18 nkchoudh Exp $
 *
 * $Log: syscall.cc,v $
 * Revision 1.1  2010/02/06 21:33:18  nkchoudh
 * added
 *
 * Revision 1.1.1.1  2009/03/19 18:17:51  nkchoudh
 * Initial checkin
 *
 * Revision 1.1.1.1  2009/03/19 16:52:01  nkchoudh
 * Initial checkin
 *
 * Revision 1.1.1.1  2007/08/20 15:09:11  mjdechen
 * Initial Import Memoryflow Simulator
 *
 * Revision 1.1  2007/08/07 17:34:15  mjdechen
 * Reorganization.  Created unified Makefile.  Deleted Unit Makefiles.
 *
 * Revision 1.1.1.1  2007/07/27 15:08:16  mjdechen
 * Imported Sources
 *
 * Revision 1.3  2000/05/31 19:41:09  ericro
 * New system call: added SS_SYS_rename for the spec2000 benchmark "twolf".
 *
 * Revision 1.2  2000/03/11 17:37:10  ksundar
 *
 * The following features have been added
 * 	Value Prediction
 * 	   Real and Perfect Value Prediction are available. (-V<x>)
 * 	Delay Buffer
 * 	   In SMT mode when 2 identical threads are instantiated the
 * 	   Delay Buffer provides value and control values to the second
 * 	   redundant thread. (-d<buffer size>,<ply threshold>)
 *
 * Revision 1.1.1.1  2000/02/04 22:34:51  ericro
 * Shit, we hit an ICEBERG!
 *
 * Revision 1.5  1997/04/16  22:12:17  taustin
 * added Ultrix host support
 *
 * Revision 1.4  1997/03/11  01:37:37  taustin
 * updated copyright
 * long/int tweaks made for ALPHA target support
 * syscall structures are now more portable across platforms
 * various target supports added
 *
 * Revision 1.3  1996/12/27  15:56:09  taustin
 * updated comments
 * removed system prototypes
 *
 * Revision 1.1  1996/12/05  18:52:32  taustin
 * Initial revision
 *
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/param.h>
#include <errno.h>
#include <time.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <signal.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/uio.h>
#include <setjmp.h>
#include <sys/times.h>
#include <limits.h>
#include <sys/ioctl.h>
#if defined(__svr4__)
#include <string.h>
#include <utime.h>
#include <sys/time.h>
#else
#include <strings.h>
#endif

#if !defined(linux) && !defined(sparc) && !defined(hpux) && !defined(__hpux) && !defined(__CYGWIN32__) && !defined(ultrix)
#include <sys/select.h>
#endif
#ifdef linux
#ifdef SIM_LINUX	/* 11/5/04 ERIC_CHANGE */
#include <sgtty.h>
#include <utime.h>
#else
#include <bsd/sgtty.h>
#endif
#endif /* linux */

#ifdef __CYGWIN32__
/*#include <sgtty.h>*/
#include <sys/termios.h>
#include <sys/utime.h>
#endif /* __CYGWIN32__ */

#if defined(sparc) && defined(__unix__)
#if defined(__svr4__) || defined(__USLC__)
#include <dirent.h>
#else
#include <sys/dir.h>
#endif

/* dorks */
#undef NL0
#undef NL1
#undef CR0
#undef CR1
#undef CR2
#undef CR3
#undef TAB0
#undef TAB1
#undef TAB2
#undef XTABS
#undef BS0
#undef BS1
#undef FF0
#undef FF1
#undef ECHO
#undef NOFLSH
#undef TOSTOP
#undef FLUSHO
#undef PENDIN
#endif

#if defined(hpux) || defined(__hpux)
#undef CR0
#endif

#ifdef __FreeBSD__
#include <sys/ioctl_compat.h>
#else
/*#include <sys/int_types.h>*/
#include <sys/types.h>
#include <termio.h>
#endif

#if defined(hpux) || defined(__hpux)
/* et tu, dorks! */
#undef HUPCL
#undef ECHO
#undef B50
#undef B75
#undef B110
#undef B134
#undef B150
#undef B200
#undef B300
#undef B600
#undef B1200
#undef B1800
#undef B2400
#undef B4800
#undef B9600
#undef B19200
#undef B38400
#undef NL0
#undef NL1
#undef CR0
#undef CR1
#undef CR2
#undef CR3
#undef TAB0
#undef TAB1
#undef BS0
#undef BS1
#undef FF0
#undef FF1
#undef EXTA
#undef EXTB
#undef B900
#undef B3600
#undef B7200
#undef XTABS
#include <sgtty.h>
#include <utime.h>
#endif

#include "misc.h"
#include "ss.h"
#include "regs.h"
#include "memory.h"
#include "loader.h"
#include "sim.h"
#include "_endian.h"
#include "syscall.h"

/* open(2) flags translation table for SimpleScalar target */
struct
{
  int ss_flag;
  int local_flag;
} ss_flag_table[] = {
  /* target flag */ /* host flag */
  { SS_O_RDONLY,  O_RDONLY},
  { SS_O_WRONLY,  O_WRONLY},
  { SS_O_RDWR,    O_RDWR},
  { SS_O_APPEND,  O_APPEND},
  { SS_O_CREAT,   O_CREAT},
  { SS_O_TRUNC,   O_TRUNC},
  { SS_O_EXCL,    O_EXCL},
  { SS_O_NONBLOCK,  O_NONBLOCK},
  { SS_O_NOCTTY,  O_NOCTTY},
#ifdef O_SYNC
  { SS_O_SYNC,    O_SYNC},
#endif
};
#define SS_NFLAGS	(sizeof(ss_flag_table)/sizeof(ss_flag_table[0]))

/* syscall proxy handler, architect registers and memory are assumed to be
   precise when this function is called, register and memory are updated with
   the results of the sustem call */

#include "Thread.h"
void ss_fork(Thread *master, SS_ADDR_TYPE ThreadIdPtr, unsigned int id);
void ss_unlock(SS_ADDR_TYPE lockaddr);

//////////////////
// 06/09/01 ER
//////////////////
void Thread::trap_stop(SS_INST_TYPE inst)
{
  trap_inst.a = inst.a;
  trap_inst.b = inst.b;
  blocked = true;
}

//void Thread::trap_now(SS_INST_TYPE inst)
void Thread::trap_now()
{
  //assert(trap_inst.a == inst.a);
  //assert(trap_inst.b == inst.b);
  assert(blocked);
  if (checkpoint_fp == NULL)  // No checkpoint
    ss_syscall(&Thread::mem_access, trap_inst);
  else if (create_checkpoint) // Save to a checkpoint
    save_trap();
  else // We're restoring from the checkpoint
    restore_trap();
}

void Thread::trap_resume()
{
  blocked = false;
  run_ahead();
}

void Thread::save_trap()
{
  assert(checkpoint_fp != NULL);
  assert(create_checkpoint);

  fprintf(stderr,"\nCheckpointing Trap");

  unsigned int row;
  unsigned int i;
  unsigned int memory_differences;
  char *backup_mem_table[MEM_TABLE_SIZE];

  // The strategy for saving a trap is:
  //  (1) Save the trap info & pre-trap regs
  //  (2) Temporarily save the memory table
  //  (3) Handle the trap
  //  (4) Save the post-trap regs
  //  (5) Compare the memory tables, count the differences, and save them
  
  // 1a. Save trap information
  fwrite(&num_insn, 1, sizeof(num_insn), checkpoint_fp);
  fwrite(&trap_inst.a, 1, sizeof(trap_inst.a), checkpoint_fp);
  fwrite(&trap_inst.b, 1, sizeof(trap_inst.b), checkpoint_fp);

  // 1b. Save pre-trap regs
  fwrite(&regs_R[2], 1, sizeof(regs_R[2]), checkpoint_fp);
  fwrite(&regs_R[3], 1, sizeof(regs_R[3]), checkpoint_fp);
  fwrite(&regs_R[4], 1, sizeof(regs_R[4]), checkpoint_fp);
  fwrite(&regs_R[5], 1, sizeof(regs_R[5]), checkpoint_fp);
  fwrite(&regs_R[6], 1, sizeof(regs_R[6]), checkpoint_fp);
  fwrite(&regs_R[7], 1, sizeof(regs_R[7]), checkpoint_fp);
  fwrite(&regs_R[31], 1, sizeof(regs_R[31]), checkpoint_fp);

  // 2. Save the memory table
  for (row = 0; row < MEM_TABLE_SIZE; row++)
  {
    backup_mem_table[row] = (char *)NULL;
    if (mem_table[row])
    {
      backup_mem_table[row] = mem_newblock();
      for (i = 0; i < MEM_BLOCK_SIZE; i++)
        backup_mem_table[row][i] = mem_table[row][i];
    }
  }

  // 3. Handle the trap
  ss_syscall(&Thread::mem_access, trap_inst);

  // 4. Save the post-trap regs
  fwrite(&regs_R[2], 1, sizeof(regs_R[2]), checkpoint_fp);
  fwrite(&regs_R[3], 1, sizeof(regs_R[3]), checkpoint_fp);
  fwrite(&regs_R[4], 1, sizeof(regs_R[4]), checkpoint_fp);
  fwrite(&regs_R[5], 1, sizeof(regs_R[5]), checkpoint_fp);
  fwrite(&regs_R[6], 1, sizeof(regs_R[6]), checkpoint_fp);
  fwrite(&regs_R[7], 1, sizeof(regs_R[7]), checkpoint_fp);
  fwrite(&regs_R[31], 1, sizeof(regs_R[31]), checkpoint_fp);

  // 5a. and 5b. Compare the memory table and count the differences
  memory_differences = 0;
  for (row = 0; row < MEM_TABLE_SIZE; row++)
  {
    if (mem_table[row])
    {
      assert(backup_mem_table[row]);
      for (i = 0; i < MEM_BLOCK_SIZE; i++)
        if (mem_table[row][i] != backup_mem_table[row][i])
          memory_differences++;
    }
  }

  // 5c. Save the differences
  fwrite(&memory_differences, 1, sizeof(memory_differences), checkpoint_fp);
  for (row = 0; row < MEM_TABLE_SIZE; row++)
  {
    if (mem_table[row])
    {
      for (i = 0; i < MEM_BLOCK_SIZE; i++)
        if (mem_table[row][i] != backup_mem_table[row][i])
        {
          // Write the location in the memtable and the data to the checkpoint
          fwrite(&row, 1, sizeof(row), checkpoint_fp);
          fwrite(&i, 1, sizeof(i), checkpoint_fp);
          fwrite(&mem_table[row][i], 
                 1, 
                 sizeof(mem_table[row][i]),
                 checkpoint_fp);
          fprintf(stderr, ".");
        }
    }
  }

  // 6. Cleanup our Memory Usage
  for (row = 0; row < MEM_TABLE_SIZE; row++)
  {
    if (backup_mem_table[row])
    {
      delete[] backup_mem_table[row];
      backup_mem_table[row] = NULL;
    }
  }

  fprintf(stderr, "\n");
}

void Thread::restore_trap()
{
  assert(checkpoint_fp != NULL);
  assert(!create_checkpoint);

  unsigned int row, col;
  unsigned int i;
  unsigned int memory_differences;
  char *backup_mem_table[MEM_TABLE_SIZE];

  SS_COUNTER_TYPE check_num_insn;
  unsigned long check_inst_a;
  unsigned long check_inst_b;

  SS_WORD_TYPE check_regs_R[SS_NUM_REGS];

  // 1. Load and check trap information
  fread(&check_num_insn, 1, sizeof(check_num_insn), checkpoint_fp);
  fread(&check_inst_a, 1, sizeof(check_inst_a), checkpoint_fp);
  fread(&check_inst_b, 1, sizeof(check_inst_b), checkpoint_fp);
  if ((check_num_insn != num_insn) || 
      (check_inst_a != trap_inst.a) ||
      (check_inst_b != trap_inst.b))
  {
    panic("Incorrect or Missing Trap Data\n");
  }

  // 2. Load and check pre-trap regs
  fread(&check_regs_R[2], 1, sizeof(check_regs_R[2]), checkpoint_fp);
  fread(&check_regs_R[3], 1, sizeof(check_regs_R[3]), checkpoint_fp);
  fread(&check_regs_R[4], 1, sizeof(check_regs_R[4]), checkpoint_fp);
  fread(&check_regs_R[5], 1, sizeof(check_regs_R[5]), checkpoint_fp);
  fread(&check_regs_R[6], 1, sizeof(check_regs_R[6]), checkpoint_fp);
  fread(&check_regs_R[7], 1, sizeof(check_regs_R[7]), checkpoint_fp);
  fread(&check_regs_R[31], 1, sizeof(check_regs_R[31]), checkpoint_fp);
  if ((check_regs_R[2] != regs_R[2]) ||
      (check_regs_R[3] != regs_R[3]) ||
      (check_regs_R[4] != regs_R[4]) ||
      (check_regs_R[5] != regs_R[5]) ||
      (check_regs_R[6] != regs_R[6]) ||
      (check_regs_R[7] != regs_R[7]) ||
      (check_regs_R[31] != regs_R[31]))
  {
    panic("Trap input registers do not match register file\n");
  }

  // 3. Load the post-trap regs
  fread(&regs_R[2], 1, sizeof(regs_R[2]), checkpoint_fp);
  fread(&regs_R[3], 1, sizeof(regs_R[3]), checkpoint_fp);
  fread(&regs_R[4], 1, sizeof(regs_R[4]), checkpoint_fp);
  fread(&regs_R[5], 1, sizeof(regs_R[5]), checkpoint_fp);
  fread(&regs_R[6], 1, sizeof(regs_R[6]), checkpoint_fp);
  fread(&regs_R[7], 1, sizeof(regs_R[7]), checkpoint_fp);
  fread(&regs_R[31], 1, sizeof(regs_R[31]), checkpoint_fp);

  // 4. Update the Memory Table with trap changes
  fread(&memory_differences, 1, sizeof(memory_differences), checkpoint_fp);
  for (i = 0; i < memory_differences; i++)
  {
    fread(&row, 1, sizeof(row), checkpoint_fp);
    fread(&col, 1, sizeof(col), checkpoint_fp);
    fread(&mem_table[row][col], 1, sizeof(mem_table[row][col]), checkpoint_fp);
  }
}

void Thread::ss_syscall(mem_access_fn mem_fn, SS_INST_TYPE inst)
{
  SS_WORD_TYPE syscode = regs_R[2];

#if REAL_TIME
  unsigned int ctr; // 06/09/01 ER: Support for "hardware profile counters".
  unsigned int ctr_value;
  unsigned int task;
  extern void process_counter(unsigned int task,
                              unsigned int ctr,
                              unsigned int ctr_value);
  extern void cache_switch(bool on);
  extern void mem_lat(unsigned int lat);
#endif

  switch (syscode)
  {
  case SS_SYS_exit:
    /* exit jumps to the target set in main() */
    longjmp(sim_exit_buf, /* exitcode + fudge */regs_R[4]+1);
    break;

#if 0
  case SS_SYS_fork:
    /* FIXME: this is broken... */
    regs_R[2] = fork();
    if (regs_R[2] != -1)
    {
      regs_R[7] = 0;
      /* parent process */
      if (regs_R[2] != 0)
        regs_R[3] = 0;
    }
    else
      fatal("SYS_fork failed");
    break;
#endif

#if 0
  case SS_SYS_vfork:
    /* FIXME: this is broken... */
    int r31_parent = regs_R[31];
    /* pid */regs_R[2] = vfork();
    if (regs_R[2] != -1)
      regs_R[7] = 0;
    else
      fatal("vfork() in SYS_vfork failed");
    if (regs_R[2] != 0)
    {
      regs_R[3] = 0;
      regs_R[7] = 0;
      regs_R[31] = r31_parent;
    }
    break;
#endif

  case SS_SYS_read:
    {
      char *buf;

      /* allocate same-sized input buffer in host memory */
      if (!(buf = (char *)calloc(/*nbytes*/regs_R[6], sizeof(char))))
        fatal("out of memory in SYS_read");

      /* read data from file */
      /*nread*/regs_R[2] = read(/*fd*/regs_R[4], buf, /*nbytes*/regs_R[6]);

      /* check for error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, return details */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }

      /* copy results back into host memory */
      mem_bcopy(mem_fn, Write, /*buf*/regs_R[5], buf, /*nread*/regs_R[2]);

      /* done with input buffer */
      free(buf);
    }
    break;

  case SS_SYS_write:
    {
      char *buf;

      /* allocate same-sized output buffer in host memory */
      if (!(buf = (char *)calloc(/*nbytes*/regs_R[6], sizeof(char))))
        fatal("out of memory in SYS_write");

      /* copy inputs into host memory */
      mem_bcopy(mem_fn, Read, /*buf*/regs_R[5], buf, /*nbytes*/regs_R[6]);

      /* write data to file */
      /*nwritten*/regs_R[2] = write(/*fd*/regs_R[4],
                                    buf, /*nbytes*/regs_R[6]);

      /* check for an error condition */
      if (regs_R[2] == regs_R[6])
        /*result*/regs_R[7] = 0;
      else
      {
        /* got an error, return details */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }

      /* done with output buffer */
      free(buf);
    }
    break;

  case SS_SYS_open:
    {
      char buf[MAXBUFSIZE];
      unsigned int i;
      int ss_flags = regs_R[5], local_flags = 0;

      /* translate open(2) flags */
      for (i=0; i<SS_NFLAGS; i++)
      {
        if (ss_flags & ss_flag_table[i].ss_flag)
        {
          ss_flags &= ~ss_flag_table[i].ss_flag;
          local_flags |= ss_flag_table[i].local_flag;
        }
      }
      /* any target flags left? */
      if (ss_flags != 0)
        fatal("syscall: open: cannot decode flags: 0x%08x", ss_flags);

      /* copy filename to host memory */
      mem_strcpy(mem_fn, Read, /*fname*/regs_R[4], buf);

      /* open the file */
      /*fd*/regs_R[2] = open(buf, local_flags, /*mode*/regs_R[6]);

      /* check for an error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, return details */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }
    }
    break;

  case SS_SYS_close:
    /* don't close stdin, stdout, or stderr as this messes up sim logs */
    if (/*fd*/regs_R[4] == 0 || /*fd*/regs_R[4] == 1 || /*fd*/regs_R[4] == 2)
    {
      regs_R[7] = 0;
      break;
    }

    /* close the file */
    regs_R[2] = close(/*fd*/regs_R[4]);

    /* check for an error condition */
    if (regs_R[2] != -1)
      regs_R[7] = 0;
    else
    {
      /* got an error, return details */
      regs_R[2] = errno;
      regs_R[7] = 1;
    }
    break;

  case SS_SYS_creat:
    {
      char buf[MAXBUFSIZE];

      /* copy filename to host memory */
      mem_strcpy(mem_fn, Read, /*fname*/regs_R[4], buf);

      /* create the file */
      /*fd*/regs_R[2] = creat(buf, /*mode*/regs_R[5]);

      /* check for an error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, return details */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }
    }
    break;

  case SS_SYS_unlink:
    {
      char buf[MAXBUFSIZE];

      /* copy filename to host memory */
      mem_strcpy(mem_fn, Read, /*fname*/regs_R[4], buf);

      /* delete the file */
      /*result*/regs_R[2] = unlink(buf);

      /* check for an error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, return details */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }
    }
    break;

    // ERIC_CHANGE
    // Added SS_SYS_rename for the spec2000 benchmark "twolf".
  case SS_SYS_rename:
    {
      char buf1[MAXBUFSIZE];
      char buf2[MAXBUFSIZE];

      /* copy filenames to host memory */
      mem_strcpy(mem_fn, Read, /*fname1*/regs_R[4], buf1);
      mem_strcpy(mem_fn, Read, /*fname2*/regs_R[5], buf2);

      /* rename the file */
      /*result*/regs_R[2] = rename(buf1,buf2);

      /* check for an error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, return details */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }
    }
    break;

  case SS_SYS_chdir:
    {
      char buf[MAXBUFSIZE];

      /* copy filename to host memory */
      mem_strcpy(mem_fn, Read, /*fname*/regs_R[4], buf);

      /* change the working directory */
      /*result*/regs_R[2] = chdir(buf);

      /* check for an error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, return details */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }
    }
    break;

  case SS_SYS_chmod:
    {
      char buf[MAXBUFSIZE];

      /* copy filename to host memory */
      mem_strcpy(mem_fn, Read, /*fname*/regs_R[4], buf);

      /* chmod the file */
      /*result*/regs_R[2] = chmod(buf, /*mode*/regs_R[5]);

      /* check for an error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, return details */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }
    }
    break;

  case SS_SYS_chown:
    {
      char buf[MAXBUFSIZE];

      /* copy filename to host memory */
      mem_strcpy(mem_fn, Read, /*fname*/regs_R[4], buf);

      /* chown the file */
      /*result*/regs_R[2] = chown(buf, /*owner*/regs_R[5],
                                  /*group*/regs_R[6]);

      /* check for an error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, return details */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }
    }
    break;

  case SS_SYS_brk:
    {
      SS_ADDR_TYPE addr;

      /* round the new heap pointer to the its page boundary */
      addr = ROUND_UP(/*base*/regs_R[4], SS_PAGE_SIZE);

      /* check whether heap area has merged with stack area */
      if (addr >= mem_brk_point && addr < (unsigned int)regs_R[29])
      {
        regs_R[2] = 0;
        regs_R[7] = 0;
        mem_brk_point = addr;
      }
      else
      {
        /* out of address space, indicate error */
        regs_R[2] = ENOMEM;
        regs_R[7] = 1;
      }
    }
    break;

  case SS_SYS_lseek:
    /* seek into file */
    regs_R[2] = lseek(/*fd*/regs_R[4], /*off*/regs_R[5], /*dir*/regs_R[6]);

    /* check for an error condition */
    if (regs_R[2] != -1)
      regs_R[7] = 0;
    else
    {
      /* got an error, return details */
      regs_R[2] = errno;
      regs_R[7] = 1;
    }
    break;

  case SS_SYS_getpid:
    /* get the simulator process id */
    /*result*/regs_R[2] = getpid();

    /* check for an error condition */
    if (regs_R[2] != -1)
      regs_R[7] = 0;
    else
    {
      /* got an error, return details */
      regs_R[2] = errno;
      regs_R[7] = 1;
    }
    break;

  case SS_SYS_getuid:
    /* get current user id */
    /*first result*/regs_R[2] = getuid();

    /* get effective user id */
    /*second result*/regs_R[3] = geteuid();

    /* check for an error condition */
    if (regs_R[2] != -1)
      regs_R[7] = 0;
    else
    {
      /* got an error, return details */
      regs_R[2] = errno;
      regs_R[7] = 1;
    }
    break;

  case SS_SYS_access:
    {
      char buf[MAXBUFSIZE];

      /* copy filename to host memory */
      mem_strcpy(mem_fn, Read, /*fName*/regs_R[4], buf);

      /* check access on the file */
      /*result*/regs_R[2] = access(buf, /*mode*/regs_R[5]);

      /* check for an error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, return details */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }
    }
    break;

  case SS_SYS_stat:
  case SS_SYS_lstat:
    {
      char buf[MAXBUFSIZE];
      struct ss_statbuf ss_sbuf;
      struct stat sbuf;

      /* copy filename to host memory */
      mem_strcpy(mem_fn, Read, /*fName*/regs_R[4], buf);

      /* stat() the file */
      if (syscode == SS_SYS_stat)
        /*result*/regs_R[2] = stat(buf, &sbuf);
      else /* syscode == SS_SYS_lstat */
        /*result*/regs_R[2] = lstat(buf, &sbuf);

      /* check for an error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, return details */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }

      /* translate from host stat structure to target format */
      ss_sbuf.ss_st_dev = SWAP_HALF(sbuf.st_dev);
      ss_sbuf.ss_st_ino = SWAP_WORD(sbuf.st_ino);
      ss_sbuf.ss_st_mode = SWAP_HALF(sbuf.st_mode);
      ss_sbuf.ss_st_nlink = SWAP_HALF(sbuf.st_nlink);
      ss_sbuf.ss_st_uid = SWAP_HALF(sbuf.st_uid);
      ss_sbuf.ss_st_gid = SWAP_HALF(sbuf.st_gid);
      ss_sbuf.ss_st_rdev = SWAP_HALF(sbuf.st_rdev);
      ss_sbuf.ss_st_size = SWAP_WORD(sbuf.st_size);
      ss_sbuf.ss_st_atime = SWAP_WORD(sbuf.st_atime);
      ss_sbuf.ss_st_mtime = SWAP_WORD(sbuf.st_mtime);
      ss_sbuf.ss_st_ctime = SWAP_WORD(sbuf.st_ctime);
      ss_sbuf.ss_st_blksize = SWAP_WORD(sbuf.st_blksize);
      ss_sbuf.ss_st_blocks = SWAP_WORD(sbuf.st_blocks);

      /* copy stat() results to simulator memory */
      mem_bcopy(mem_fn, Write, /*sbuf*/regs_R[5],
                &ss_sbuf, sizeof(struct ss_statbuf));
    }
    break;

  case SS_SYS_dup:
    /* dup() the file descriptor */
    /*fd*/regs_R[2] = dup(/*fd*/regs_R[4]);

    /* check for an error condition */
    if (regs_R[2] != -1)
      regs_R[7] = 0;
    else
    {
      /* got an error, return details */
      regs_R[2] = errno;
      regs_R[7] = 1;
    }
    break;

  case SS_SYS_pipe:
    {
      int fd[2];

      /* copy pipe descriptors to host memory */;
      mem_bcopy(mem_fn, Read, /*fd's*/regs_R[4], fd, sizeof(fd));

      /* create a pipe */
      /*result*/regs_R[7] = pipe(fd);

      /* copy descriptor results to result registers */
      /*pipe1*/regs_R[2] = fd[0];
      /*pipe 2*/regs_R[3] = fd[1];

      /* check for an error condition */
      if (regs_R[7] == -1)
      {
        regs_R[2] = errno;
        regs_R[7] = 1;
      }
    }
    break;

  case SS_SYS_getgid:
    /* get current group id */
    /*first result*/regs_R[2] = getgid();

    /* get current effective group id */
    /*second result*/regs_R[3] = getegid();

    /* check for an error condition */
    if (regs_R[2] != -1)
      regs_R[7] = 0;
    else
    {
      /* got an error, return details */
      regs_R[2] = errno;
      regs_R[7] = 1;
    }
    break;

  case SS_SYS_ioctl:
    {
      char buf[NUM_IOCTL_BYTES];
      int local_req = 0;

      /* convert target ioctl() request to host ioctl() request values */
      switch (/*req*/regs_R[5])
      {
 #if !defined(__CYGWIN32__) && !defined(SIM_LINUX)    /* 11/5/04 ERIC_CHANGE */
      case SS_IOCTL_TIOCGETP:
        local_req = TIOCGETP;
        break;
      case SS_IOCTL_TIOCSETP:
        local_req = TIOCSETP;
        break;
      case SS_IOCTL_TCGETP:
        local_req = TIOCGETP;
        break;
 #endif 
#ifdef TCGETA
      case SS_IOCTL_TCGETA:
        local_req = TCGETA;
        break;
#endif
#ifdef TIOCGLTC
      case SS_IOCTL_TIOCGLTC:
        local_req = TIOCGLTC;
        break;
#endif
#ifdef TIOCSLTC
      case SS_IOCTL_TIOCSLTC:
        local_req = TIOCSLTC;
        break;
#endif
      case SS_IOCTL_TIOCGWINSZ:
        local_req = TIOCGWINSZ;
        break;
#ifdef TCSETAW
      case SS_IOCTL_TCSETAW:
        local_req = TCSETAW;
        break;
#endif
#ifdef TIOCGETC
      case SS_IOCTL_TIOCGETC:
        local_req = TIOCGETC;
        break;
#endif
#ifdef TIOCSETC
      case SS_IOCTL_TIOCSETC:
        local_req = TIOCSETC;
        break;
#endif
#ifdef TIOCLBIC
      case SS_IOCTL_TIOCLBIC:
        local_req = TIOCLBIC;
        break;
#endif
#ifdef TIOCLBIS
      case SS_IOCTL_TIOCLBIS:
        local_req = TIOCLBIS;
        break;
#endif
#ifdef TIOCLGET
      case SS_IOCTL_TIOCLGET:
        local_req = TIOCLGET;
        break;
#endif
#ifdef TIOCLSET
      case SS_IOCTL_TIOCLSET:
        local_req = TIOCLSET;
        break;
#endif
      }

      if (!local_req)
      {
        /* FIXME: could not translate the ioctl() request, just warn user
           and ignore the request */
        warn("syscall: ioctl: ioctl code not supported d=%d, req=%d",
             regs_R[4], regs_R[5]);
        regs_R[2] = 0;
        regs_R[7] = 0;
      }
      else
      {
        /* ioctl() code was successfully translated to a host code */

        /* if arg ptr exists, copy NUM_IOCTL_BYTES bytes to host mem */
        if (/*argp*/regs_R[6] != 0)
          mem_bcopy(mem_fn, Read, /*argp*/regs_R[6], buf, NUM_IOCTL_BYTES);

        /* perform the ioctl() call */
        /*result*/regs_R[2] = ioctl(/*fd*/regs_R[4], local_req, buf);

        /* if arg ptr exists, copy NUM_IOCTL_BYTES bytes from host mem */
        if (/*argp*/regs_R[6] != 0)
          mem_bcopy(mem_fn, Write, regs_R[6], buf, NUM_IOCTL_BYTES);

        /* check for an error condition */
        if (regs_R[2] != -1)
          regs_R[7] = 0;
        else
        {
          /* got an error, return details */
          regs_R[2] = errno;
          regs_R[7] = 1;
        }
      }
    }
    break;

  case SS_SYS_fstat:
    {
      struct ss_statbuf ss_sbuf;
      struct stat sbuf;

      /* fstat() the file */
      /*result*/regs_R[2] = fstat(/*fd*/regs_R[4], &sbuf);

      /* check for an error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, return details */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }

      /* translate the stat structure to host format */
      ss_sbuf.ss_st_dev = SWAP_HALF(sbuf.st_dev);
      ss_sbuf.ss_st_ino = SWAP_WORD(sbuf.st_ino);
      ss_sbuf.ss_st_mode = SWAP_HALF(sbuf.st_mode);
      ss_sbuf.ss_st_nlink = SWAP_HALF(sbuf.st_nlink);
      ss_sbuf.ss_st_uid = SWAP_HALF(sbuf.st_uid);
      ss_sbuf.ss_st_gid = SWAP_HALF(sbuf.st_gid);
      ss_sbuf.ss_st_rdev = SWAP_HALF(sbuf.st_rdev);
      ss_sbuf.ss_st_size = SWAP_WORD(sbuf.st_size);
      ss_sbuf.ss_st_atime = SWAP_WORD(sbuf.st_atime);
      ss_sbuf.ss_st_mtime = SWAP_WORD(sbuf.st_mtime);
      ss_sbuf.ss_st_ctime = SWAP_WORD(sbuf.st_ctime);
      ss_sbuf.ss_st_blksize = SWAP_WORD(sbuf.st_blksize);
      ss_sbuf.ss_st_blocks = SWAP_WORD(sbuf.st_blocks);

      /* copy fstat() results to simulator memory */
      mem_bcopy(mem_fn, Write, /*sbuf*/regs_R[5],
                &ss_sbuf, sizeof(struct ss_statbuf));
    }
    break;

  case SS_SYS_getpagesize:
    /* get target pagesize */
    regs_R[2] = /* was: getpagesize() */SS_PAGE_SIZE;

    /* check for an error condition */
    if (regs_R[2] != -1)
      regs_R[7] = 0;
    else
    {
      /* got an error, return details */
      regs_R[2] = errno;
      regs_R[7] = 1;
    }
    break;

  case SS_SYS_setitimer:
    /* FIXME: the sigvec system call is ignored */
    regs_R[2] = regs_R[7] = 0;
    warn("syscall: setitimer ignored");
    break;

  case SS_SYS_getdtablesize:
#if defined(_AIX)
    /* get descriptor table size */
    regs_R[2] = getdtablesize();

    /* check for an error condition */
    if (regs_R[2] != -1)
      regs_R[7] = 0;
    else
    {
      /* got an error, return details */
      regs_R[2] = errno;
      regs_R[7] = 1;
    }
#elif defined(__CYGWIN32__)
    {
      /* no comparable system call found, try some reasonable defaults */
      warn("syscall: called getdtablesize\n");
      regs_R[2] = 16;
      regs_R[7] = 0;
    }
#elif defined(ultrix)
    {
      /* no comparable system call found, try some reasonable defaults */
      warn("syscall: called getdtablesize\n");
      regs_R[2] = 16;
      regs_R[7] = 0;
    }
#else
    {
      struct rlimit rl;

      /* get descriptor table size in rlimit structure */
      if (getrlimit(RLIMIT_NOFILE, &rl) != -1)
      {
        regs_R[2] = rl.rlim_cur;
        regs_R[7] = 0;
      }
      else
      {
        /* got an error, return details */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }
    }
#endif
    break;

  case SS_SYS_dup2:
    /* dup2() the file descriptor */
    regs_R[2] = dup2(/* fd1 */regs_R[4], /* fd2 */regs_R[5]);

    /* check for an error condition */
    if (regs_R[2] != -1)
      regs_R[7] = 0;
    else
    {
      /* got an error, return details */
      regs_R[2] = errno;
      regs_R[7] = 1;
    }
    break;

  case SS_SYS_fcntl:
    /* get fcntl() information on the file */
    regs_R[2] = fcntl(/*fd*/regs_R[4], /*cmd*/regs_R[5], /*arg*/regs_R[6]);

    /* check for an error condition */
    if (regs_R[2] != -1)
      regs_R[7] = 0;
    else
    {
      /* got an error, return details */
      regs_R[2] = errno;
      regs_R[7] = 1;
    }
    break;

  case SS_SYS_select:
    {
      fd_set readfd, writefd, exceptfd;
      fd_set *readfdp, *writefdp, *exceptfdp;
      struct timeval timeout, *timeoutp;
      SS_WORD_TYPE param5;

      /* FIXME: swap words? */

      /* read the 5th parameter (timeout) from the stack */
      mem_bcopy(mem_fn, Read, regs_R[29]+16, &param5, sizeof(SS_WORD_TYPE));

      /* copy read file descriptor set into host memory */
      if (/*readfd*/regs_R[5] != 0)
      {
        mem_bcopy(mem_fn, Read, /*readfd*/regs_R[5],
                  &readfd, sizeof(fd_set));
        readfdp = &readfd;
      }
      else
        readfdp = NULL;

      /* copy write file descriptor set into host memory */
      if (/*writefd*/regs_R[6] != 0)
      {
        mem_bcopy(mem_fn, Read, /*writefd*/regs_R[6],
                  &writefd, sizeof(fd_set));
        writefdp = &writefd;
      }
      else
        writefdp = NULL;

      /* copy exception file descriptor set into host memory */
      if (/*exceptfd*/regs_R[7] != 0)
      {
        mem_bcopy(mem_fn, Read, /*exceptfd*/regs_R[7],
                  &exceptfd, sizeof(fd_set));
        exceptfdp = &exceptfd;
      }
      else
        exceptfdp = NULL;

      /* copy timeout value into host memory */
      if (/*timeout*/param5 != 0)
      {
        mem_bcopy(mem_fn, Read, /*timeout*/param5,
                  &timeout, sizeof(struct timeval));
        timeoutp = &timeout;
      }
      else
        timeoutp = NULL;

#if defined(hpux) || defined(__hpux)
      /* select() on the specified file descriptors */
      /*result*/regs_R[2] =
      select(/*nfd*/regs_R[4],
             (int *)readfdp, (int *)writefdp, (int *)exceptfdp, timeoutp);
#else
      /* select() on the specified file descriptors */
      /*result*/regs_R[2] =
      select(/*nfd*/regs_R[4], readfdp, writefdp, exceptfdp, timeoutp);
#endif

      /* check for an error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, return details */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }

      /* copy read file descriptor set to target memory */
      if (/*readfd*/regs_R[5] != 0)
        mem_bcopy(mem_fn, Write, /*readfd*/regs_R[5],
                  &readfd, sizeof(fd_set));

      /* copy write file descriptor set to target memory */
      if (/*writefd*/regs_R[6] != 0)
        mem_bcopy(mem_fn, Write, /*writefd*/regs_R[6],
                  &writefd, sizeof(fd_set));

      /* copy exception file descriptor set to target memory */
      if (/*exceptfd*/regs_R[7] != 0)
        mem_bcopy(mem_fn, Write, /*exceptfd*/regs_R[7],
                  &exceptfd, sizeof(fd_set));

      /* copy timeout value result to target memory */
      if (/* timeout */param5 != 0)
        mem_bcopy(mem_fn, Write, /*timeout*/param5,
                  &timeout, sizeof(struct timeval));
    }
    break;

  case SS_SYS_fsync:
    regs_R[2] = fsync(regs_R[4]);
    /* check for error condition */
    if (regs_R[2] != -1)
      regs_R[7] = 0;
    else
    {
      /* got an error, return details */
      regs_R[2] = errno;
      regs_R[7] = 1;
    }
    break;

  case SS_SYS_sigvec:
    /* FIXME: the sigvec system call is ignored */
    regs_R[2] = regs_R[7] = 0;
    warn("syscall: sigvec ignored");
    break;

  case SS_SYS_sigblock:
    /* FIXME: the sigblock system call is ignored */
    regs_R[2] = regs_R[7] = 0;
    warn("syscall: sigblock ignored");
    break;

  case SS_SYS_sigsetmask:
    /* FIXME: the sigsetmask system call is ignored */
    regs_R[2] = regs_R[7] = 0;
    warn("syscall: sigsetmask ignored");
    break;

  case SS_SYS_ftruncate:
    /* FOR POSTGRES */
    regs_R[2] = ftruncate(/*fd*/regs_R[4], /*off*/regs_R[5]);

    /* check for an error condition */
    if (regs_R[2] != -1)
      regs_R[7] = 0;
    else
    {
      /* got an error, return details */
      regs_R[2] = errno;
      regs_R[7] = 1;
    }
    break;

#if 0
  case SS_SYS_sigstack:
    /* FIXME: this is broken... */
    /* do not make the system call; instead, modify (the stack
 portion of) the simulator's main memory, ignore the 1st
 argument (regs_R[4]), as it relates to signal handling */
    if (regs_R[5] != 0)
    {
      (*maf)(Read, regs_R[29]+28, (unsigned char *)&temp, 4);
      (*maf)(Write, regs_R[5], (unsigned char *)&temp, 4);
    }
    regs_R[2] = regs_R[7] = 0;
    break;
#endif

  case SS_SYS_gettimeofday:
    {
      struct ss_timeval ss_tv;
      struct timeval tv, *tvp;
      struct ss_timezone ss_tz;
      struct timezone tz, *tzp;

      if (/*timeval*/regs_R[4] != 0)
      {
        /* copy timeval into host memory */
        mem_bcopy(mem_fn, Read, /*timeval*/regs_R[4],
                  &ss_tv, sizeof(struct ss_timeval));

        /* convert target timeval structure to host format */
        tv.tv_sec = SWAP_WORD(ss_tv.ss_tv_sec);
        tv.tv_usec = SWAP_WORD(ss_tv.ss_tv_usec);
        tvp = &tv;
      }
      else
        tvp = NULL;

      if (/*timezone*/regs_R[5] != 0)
      {
        /* copy timezone into host memory */
        mem_bcopy(mem_fn, Read, /*timezone*/regs_R[5],
                  &ss_tz, sizeof(struct ss_timezone));

        /* convert target timezone structure to host format */
        tz.tz_minuteswest = SWAP_WORD(ss_tz.ss_tz_minuteswest);
        tz.tz_dsttime = SWAP_WORD(ss_tz.ss_tz_dsttime);
        tzp = &tz;
      }
      else
        tzp = NULL;

      /* get time of day */
      /*result*/regs_R[2] = gettimeofday(tvp, tzp);

      /* check for an error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, indicate result */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }

      if (/*timeval*/regs_R[4] != 0)
      {
        /* convert host timeval structure to target format */
        ss_tv.ss_tv_sec = SWAP_WORD(tv.tv_sec);
        ss_tv.ss_tv_usec = SWAP_WORD(tv.tv_usec);

        /* copy timeval to target memory */
        mem_bcopy(mem_fn, Write, /*timeval*/regs_R[4],
                  &ss_tv, sizeof(struct ss_timeval));
      }

      if (/*timezone*/regs_R[5] != 0)
      {
        /* convert host timezone structure to target format */
        ss_tz.ss_tz_minuteswest = SWAP_WORD(tz.tz_minuteswest);
        ss_tz.ss_tz_dsttime = SWAP_WORD(tz.tz_dsttime);

        /* copy timezone to target memory */
        mem_bcopy(mem_fn, Write, /*timezone*/regs_R[5],
                  &ss_tz, sizeof(struct ss_timezone));
      }
    }
    break;

  case SS_SYS_getrusage:
#if defined(__svr4__) || defined(__USLC__) || defined(hpux) || defined(__hpux) || defined(_AIX)
    {
      struct tms tms_buf;
      struct ss_rusage rusage;

      /* get user and system times */
      if (times(&tms_buf) != -1)
      {
        /* no error */
        regs_R[2] = 0;
        regs_R[7] = 0;
      }
      else
      {
        /* got an error, indicate result */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }

      /* initialize target rusage result structure */
#if defined(__svr4__)
      memset(&rusage, '\0', sizeof(struct ss_rusage));
#else /* !defined(__svr4__) */
      bzero(&rusage, sizeof(struct ss_rusage));
#endif

      /* convert from host rusage structure to target format */
      rusage.ss_ru_utime.ss_tv_sec = tms_buf.tms_utime/CLK_TCK;
      rusage.ss_ru_utime.ss_tv_sec = SWAP_WORD(rusage.ss_ru_utime.ss_tv_sec);
      rusage.ss_ru_utime.ss_tv_usec = 0;
      rusage.ss_ru_stime.ss_tv_sec = tms_buf.tms_stime/CLK_TCK;
      rusage.ss_ru_stime.ss_tv_sec = SWAP_WORD(rusage.ss_ru_stime.ss_tv_sec);
      rusage.ss_ru_stime.ss_tv_usec = 0;

      /* copy rusage results into target memory */
      mem_bcopy(mem_fn, Write, /*rusage*/regs_R[5],
                &rusage, sizeof(struct ss_rusage));
    }
#elif defined(__unix__)
    {
      struct rusage local_rusage;
      struct ss_rusage rusage;

      /* get rusage information */
      /*result*/regs_R[2] = getrusage(/*who*/regs_R[4], &local_rusage);

      /* check for an error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, indicate result */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }

      /* convert from host rusage structure to target format */
      rusage.ss_ru_utime.ss_tv_sec = local_rusage.ru_utime.tv_sec;
      rusage.ss_ru_utime.ss_tv_usec = local_rusage.ru_utime.tv_usec;
      rusage.ss_ru_utime.ss_tv_sec = SWAP_WORD(local_rusage.ru_utime.tv_sec);
      rusage.ss_ru_utime.ss_tv_usec = SWAP_WORD(local_rusage.ru_utime.tv_usec);
      rusage.ss_ru_stime.ss_tv_sec = local_rusage.ru_stime.tv_sec;
      rusage.ss_ru_stime.ss_tv_usec = local_rusage.ru_stime.tv_usec;
      rusage.ss_ru_stime.ss_tv_sec = SWAP_WORD(local_rusage.ru_stime.tv_sec);
      rusage.ss_ru_stime.ss_tv_usec = SWAP_WORD(local_rusage.ru_stime.tv_usec);
      rusage.ss_ru_maxrss = SWAP_WORD(local_rusage.ru_maxrss);
      rusage.ss_ru_ixrss = SWAP_WORD(local_rusage.ru_ixrss);
      rusage.ss_ru_idrss = SWAP_WORD(local_rusage.ru_idrss);
      rusage.ss_ru_isrss = SWAP_WORD(local_rusage.ru_isrss);
      rusage.ss_ru_minflt = SWAP_WORD(local_rusage.ru_minflt);
      rusage.ss_ru_majflt = SWAP_WORD(local_rusage.ru_majflt);
      rusage.ss_ru_nswap = SWAP_WORD(local_rusage.ru_nswap);
      rusage.ss_ru_inblock = SWAP_WORD(local_rusage.ru_inblock);
      rusage.ss_ru_oublock = SWAP_WORD(local_rusage.ru_oublock);
      rusage.ss_ru_msgsnd = SWAP_WORD(local_rusage.ru_msgsnd);
      rusage.ss_ru_msgrcv = SWAP_WORD(local_rusage.ru_msgrcv);
      rusage.ss_ru_nsignals = SWAP_WORD(local_rusage.ru_nsignals);
      rusage.ss_ru_nvcsw = SWAP_WORD(local_rusage.ru_nvcsw);
      rusage.ss_ru_nivcsw = SWAP_WORD(local_rusage.ru_nivcsw);

      /* copy rusage results into target memory */
      mem_bcopy(mem_fn, Write, /*rusage*/regs_R[5],
                &rusage, sizeof(struct ss_rusage));
    }
#elif defined(__CYGWIN32__)
    warn("syscall: called getrusage\n");
    regs_R[7] = 0;
#else
#error No getrusage() implementation!
#endif
    break;

  case SS_SYS_writev:
    {
      int i;
      char *buf;
      struct iovec *iov;

      /* allocate host side I/O vectors */
      iov =
      (struct iovec *)malloc(/*iovcnt*/regs_R[6] * sizeof(struct iovec));
      if (!iov)
        fatal("out of virtual memory in SYS_writev");

      /* copy target side pointer data into host side vector */
      mem_bcopy(mem_fn, Read, /*iov*/regs_R[5],
                iov, /*iovcnt*/regs_R[6] * sizeof(struct iovec));

      /* copy target side I/O vector buffers to host memory */
      for (i=0; i < /*iovcnt*/regs_R[6]; i++)
      {
        iov[i].iov_base = (char *)SWAP_WORD((unsigned)iov[i].iov_base);
        iov[i].iov_len = SWAP_WORD(iov[i].iov_len);
        if (iov[i].iov_base != NULL)
        {
          buf = (char *)calloc(iov[i].iov_len, sizeof(char));
          if (!buf)
            fatal("out of virtual memory in SYS_writev");
          mem_bcopy(mem_fn, Read, (SS_ADDR_TYPE)iov[i].iov_base,
                    buf, iov[i].iov_len);
          iov[i].iov_base = buf;
        }
      }

      /* perform the vector'ed write */
      /*result*/regs_R[2] =
      writev(/*fd*/regs_R[4], iov, /*iovcnt*/regs_R[6]);

      /* check for an error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, indicate results */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }

      /* free all the allocated memory */
      for (i=0; i < /*iovcnt*/regs_R[6]; i++)
      {
        if (iov[i].iov_base)
        {
          free(iov[i].iov_base);
          iov[i].iov_base = NULL;
        }
      }
      free(iov);
    }
    break;

  case SS_SYS_utimes:
    {
      char buf[MAXBUFSIZE];

      /* copy filename to host memory */
      mem_strcpy(mem_fn, Read, /*fname*/regs_R[4], buf);

      if (/*timeval*/regs_R[5] == 0)
      {
#if defined(hpux) || defined(__hpux) || defined(__i386__)
        /* no utimes() in hpux, use utime() instead */
        /*result*/
        regs_R[2] = utime(buf, NULL);
#elif defined(__svr4__) || defined(__USLC__) || defined(unix) || defined(_AIX)
        /*result*/regs_R[2] = utime(buf, NULL);
#elif defined(__CYGWIN32__)
        warn("syscall: called utimes\n");
#else
#error No utimes() implementation!
#endif
      }
      else
      {
        struct ss_timeval ss_tval[2];
        struct timeval tval[2];

        /* copy timeval structure to host memory */
        mem_bcopy(mem_fn, Read, /*timeout*/regs_R[5],
                  ss_tval, 2*sizeof(struct ss_timeval));

        /* convert timeval structure to host format */
        tval[0].tv_sec = SWAP_WORD(ss_tval[0].ss_tv_sec);
        tval[0].tv_usec = SWAP_WORD(ss_tval[0].ss_tv_usec);
        tval[1].tv_sec = SWAP_WORD(ss_tval[1].ss_tv_sec);
        tval[1].tv_usec = SWAP_WORD(ss_tval[1].ss_tv_usec);

#if defined(hpux) || defined(__hpux)
        /* no utimes() in hpux, use utime() instead */
        {
          struct utimbuf ubuf;

          ubuf.actime = tval[0].tv_sec;
          ubuf.modtime = tval[1].tv_sec;

          /* result */regs_R[2] = utime(buf, &ubuf);
        }
#elif defined(__svr4__) || defined(__USLC__) || defined(unix) || defined(_AIX)
        /* KS/ER: no utimes() in Suns using gcc295, use utime() instead */
        {
          struct utimbuf ubuf;

          ubuf.actime = tval[0].tv_sec;
          ubuf.modtime = tval[1].tv_sec;

          /* result */regs_R[2] = utime(buf, &ubuf);
        }
#elif defined(__CYGWIN32__)
        warn("syscall: called utimes\n");
#else
#error No utimes() implementation!
#endif
      }

      /* check for an error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, indicate results */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }
    }
    break;

  case SS_SYS_getrlimit:
  case SS_SYS_setrlimit:
#if defined(__CYGWIN32__)
    {
      warn("syscall: called get/setrlimit\n");
      regs_R[7] = 0;
    }
#else
    {
      struct rlimit ss_rl;
      struct rlimit rl;

      /* copy rlimit structure to host memory */
      mem_bcopy(mem_fn, Read, /*rlimit*/regs_R[5],
                &ss_rl, sizeof(struct ss_rlimit));

      /* convert rlimit structure to host format */
      rl.rlim_cur = SWAP_WORD(ss_rl.rlim_cur);
      rl.rlim_max = SWAP_WORD(ss_rl.rlim_max);

      /* get rlimit information */
      if (syscode == SS_SYS_getrlimit)
        /*result*/regs_R[2] = getrlimit(regs_R[4], &rl);
      else /* syscode == SS_SYS_setrlimit */
        /*result*/regs_R[2] = setrlimit(regs_R[4], &rl);

      /* check for an error condition */
      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        /* got an error, indicate results */
        regs_R[2] = errno;
        regs_R[7] = 1;
      }

      /* convert rlimit structure to target format */
      ss_rl.rlim_cur = SWAP_WORD(rl.rlim_cur);
      ss_rl.rlim_max = SWAP_WORD(rl.rlim_max);

      /* copy rlimit structure to target memory */
      mem_bcopy(mem_fn, Write, /*rlimit*/regs_R[5],
                &ss_rl, sizeof(struct ss_rlimit));
    }
#endif
    break;

#if 0
  case SS_SYS_getdirentries:
    /* FIXME: this is currently broken due to incompatabilities in
 disk directory formats */
    {
      unsigned int i;
      char *buf;
      int base;

      buf = (char *)calloc(/* nbytes */regs_R[6] + 1, sizeof(char));
      if (!buf)
        fatal("out of memory in SYS_getdirentries");

      /* copy in */
      for (i=0; i</* nbytes */regs_R[6]; i++)
        (*maf)(Read, /* buf */regs_R[5]+i, (unsigned char *)&buf[i], 1);
      (*maf)(Read, /* basep */regs_R[7], (unsigned char *)&base, 4);

      /*cc*/regs_R[2] =
      getdirentries(/*fd*/regs_R[4], buf, /*nbytes*/regs_R[6], &base);

      if (regs_R[2] != -1)
        regs_R[7] = 0;
      else
      {
        regs_R[2] = errno;
        regs_R[7] = 1;
      }

      /* copy out */
      for (i=0; i</* nbytes */regs_R[6]; i++)
        (*maf)(Write, /* buf */regs_R[5]+i, (unsigned char *)&buf[i], 1);
      (*maf)(Write, /* basep */regs_R[7], (unsigned char *)&base, 4);

      free(buf);
    }
    break;
#endif

    ///////////////////////////////////////////////////////////////////////
    // 12/25/99 ER:
    // Added new syscalls for bogus shared memory support (postgres).
    ///////////////////////////////////////////////////////////////////////
  case SS_SYS_test_and_set:
    {
      //fprintf(stderr, "SS_SYS_test_and_set: %x\n", (unsigned int) regs_R[4]);

      //
      // regs_R[4] = pointer to lock = (slock_t *) = (unsigned char *)
      //
      SS_ADDR_TYPE addr = (SS_ADDR_TYPE) regs_R[4];
      unsigned char lock = (unsigned char) MEM_BYTE(addr);

      regs_R[2] = (SS_WORD_TYPE) lock;  // return value = lock value
      if (!lock)      // TEST
        MEM_BYTE(addr) = 1;    // SET
      else
      {
        // block the thread if lock failed
        blocked = true;
        lockaddr = addr;
      }

      // STATS
      if (IsShared(addr))
      {
        n_shared_tas++;
        if (!lock) n_shared_tas_succeed++;
      }
      else
      {
        n_private_tas++;
        if (!lock) n_private_tas_succeed++;
      }
    }
    break;

  case SS_SYS_unlock:
    // reset the lock
    MEM_BYTE((SS_ADDR_TYPE)regs_R[4]) = 0;

    // wakeup threads that are blocked on this lock
    ss_unlock((SS_ADDR_TYPE)regs_R[4]);
    break;

  case SS_SYS_declare_shmem:
    ShmemBase = (unsigned int) regs_R[4];
    ShmemEnd  = (unsigned int) regs_R[5];
    fprintf(stderr, "SS_SYS_declare_shmem: %x -> %x\n", ShmemBase, ShmemEnd);
    break;

  case SS_SYS_fork:
    ss_fork(this, (SS_ADDR_TYPE)regs_R[4], (unsigned int)regs_R[5]);
    break;

#if REAL_TIME
    ///////////////////////////////////////////////////////////////////////
    // 06/09/01 ER:  Added support for "hardware profiling counters".
    //               First use: real-time embedded systems research.    
    ///////////////////////////////////////////////////////////////////////
  case SS_SYS_reset_counter:
    ctr = (unsigned int) regs_R[4];
    reset_hw_counter(ctr);
    break;

  case SS_SYS_read_counter:
    ctr = (unsigned int) regs_R[4];
    ctr_value = read_hw_counter(ctr);

    task = (unsigned int) regs_R[5];

    process_counter(task, ctr, ctr_value);

    regs_R[2] = (SS_WORD_TYPE) ctr_value; // return value = counter value
    break;

  case SS_SYS_cache_switch:
    cache_switch((bool) regs_R[4]);
    break;

  case SS_SYS_mem_lat:
    mem_lat((unsigned int) regs_R[4]);
    break;
#endif

  default:
    panic("invalid/unimplemented system call encountered, code %d", syscode);
  }
}
