#include <stdio.h>
#include <string.h>
#include <math.h>
#include <assert.h>

#include "mt.h"
#include "mt_trace_consume.h"
#include "info.h"
#include "common.h"
#include "macros.h"
#include "Thread.h"
//#include "parameters.h" // 08/27/04: ER


// LibSS
#define NO_ICHECKS
#include "misc.h"
#include "ss.h"
#include "regs.h"
#define mem_table local_mem_table
#include "memory.h"
#include "loader.h"
#include "syscall.h"
#include "sim.h"

#include "checkpoint.h"

#include "global_vars.h"


// 08/27/04: ER
bool USE_INSTR_LIMIT = false;
SS_TIME_TYPE INSTR_LIMIT = 100000000;


/////////////////////////////////////////////////////////////////////

/* configure the execution engine */
#define SET_NPC(EXPR)		(next_PC = (EXPR))
#define CPC			(regs_PC)

#define GPR(N)			(local_regs_R[N])
#define GPR_D(N)		(local_regs_R[N >> 1])
#define SET_GPR(N,EXPR)		(local_regs_R[N] = (EXPR))

#define FPR_L(N)		(regs_F.l[(N)])
#define SET_FPR_L(N,EXPR)	(regs_F.l[(N)] = (EXPR))
#define FPR_F(N)		(regs_F.f[(N)])
#define SET_FPR_F(N,EXPR)	(regs_F.f[(N)] = (EXPR))
#define FPR_D(N)		(regs_F.d[(N) >> 1])
#define SET_FPR_D(N,EXPR)	(regs_F.d[(N) >> 1] = (EXPR))

#define SET_HI(EXPR)		(regs_HI = (EXPR))
#define HI			(regs_HI)
#define SET_LO(EXPR)		(regs_LO = (EXPR))
#define LO			(regs_LO)
#define FCC			(regs_FCC)
#define SET_FCC(EXPR)		(regs_FCC = (EXPR))

#define READ_WORD(SRC)							\
  (/* num_refs++, */MEM_WORD(SRC))
#define READ_UNSIGNED_HALF(SRC)						\
  (/* num_refs++, */(unsigned long)((unsigned short)MEM_HALF(SRC)))
#define READ_SIGNED_HALF(SRC)						\
  (/* num_refs++, */(signed long)((signed short)MEM_HALF(SRC)))
#define READ_UNSIGNED_BYTE(SRC)						\
  (/* num_refs++, */(unsigned long)((unsigned char)MEM_BYTE(SRC)))
#define READ_SIGNED_BYTE(SRC)						\
  (/* num_refs++, */(unsigned long)((signed long)((signed char)MEM_BYTE(SRC))))

#define WRITE_WORD(SRC, DST)						\
  (/* num_refs++, */MEM_WORD(DST) = (unsigned long)(SRC))
#define WRITE_HALF(SRC, DST)						\
  (/* num_refs++, */MEM_HALF(DST) = (unsigned short)((unsigned long)(SRC)))
#define WRITE_BYTE(SRC, DST)						\
  (/* num_refs++, */MEM_BYTE(DST) = (unsigned char)((unsigned long)(SRC)))

// 06/09/01 ER
#if 0
  #define SYSCALL(INST)		(ss_syscall(mem_access, INST))
#else
  #define SYSCALL(INST)		(trap_stop(INST))
#endif


#define DEFFU(FU,DESC)
#define DEFICLASS(ICLASS,DESC)
#define DEFINST(OP,MSK,NAME,OPFORM,RES,CLASS,O1,O2,I1,I2,I3,EXPR,L,TEXPR1,TEXPR2)
#define DEFLDST(OP,MSK,NAME,OPFORM,RES,CLASS,O1,O2,I1,I2,I3,EXPR,DIRECT)
#define DEFLINK(OP,MSK,NAME,MASK,SHIFT)
#define CONNECT(OP)
#define IMPL
#include "ss.def"
#undef DEFFU
#undef DEFICLASS
#undef DEFINST
#undef DEFLDST
#undef DEFLINK
#undef CONNECT
#undef IMPL


void Thread::func_sim()
{
  register SS_INST_TYPE inst;
#undef mem_table
  register char **local_mem_table = mem_table;
#define mem_table local_mem_table

  /////////////////////////////
  // SIMULATE ONE INSTRUCTION
  /////////////////////////////

  /* maintain $r0 semantics */
  local_regs_R[0] = 0;

  /* keep an instruction count */
  num_insn++;

  inst = __UNCHK_MEM_ACCESS(SS_INST_TYPE, regs_PC);


  // Start a new debug entry.
  DB->start();

  switch (SS_OPCODE(inst))
  {
#define DEFFU(FU,DESC)
#define DEFINST(OP,MSK,NAME,OPFORM,RES,FLAGS,O1,O2,I1,I2,I3,EXPR,L,TEXPR1,TEXPR2) \
        case OP:							\
	  TEXPR1;							\
	  EXPR;								\
	  TEXPR2;							\
	  /**** Pass instruction to the debug buffer. ****/		\
	  if (FLAGS & F_STORE)						\
	     get_arch_mem_value(store_addr, &real_upper, &real_lower);	\
	  DB->push_instr_actual(inst, FLAGS, L, regs_PC, next_PC,	\
				real_upper, real_lower);		\
	  break;
#define DEFLINK(OP,MSK,NAME,MASK,SHIFT)					\
        case OP:							\
	  panic("attempted to execute a linking opcode");
#define CONNECT(OP)
#include "ss.def"
#undef DEFFU
#undef DEFINST
#undef DEFLINK
#undef CONNECT
  }

  /////////////////////////////////////////////////////////////////////

  /* execute next instruction */
  regs_PC = next_PC;
  next_PC += 8;

  /////////////////////////////////////////////////////////
  // Exit simulator if we exceeded instruction limit.
  /////////////////////////////////////////////////////////
//   if (USE_INSTR_LIMIT && num_insn > INSTR_LIMIT)
//     longjmp(sim_exit_buf, 0);

}   // func_sim()

//func_sim.cc

//ASZ: 4/24/05 removed debug_buffer code

void Thread::func_sim_fast()
{
  register SS_INST_TYPE inst;
#undef mem_table
  register char **local_mem_table = mem_table;
#define mem_table local_mem_table

  /////////////////////////////
  // SIMULATE ONE INSTRUCTION
  /////////////////////////////

  /* maintain $r0 semantics */
  local_regs_R[0] = 0;

  /* keep an instruction count */
  num_insn++;

  inst = __UNCHK_MEM_ACCESS(SS_INST_TYPE, regs_PC);

  switch (SS_OPCODE(inst))
  {
#define DEFFU(FU,DESC)
#define DEFINST(OP,MSK,NAME,OPFORM,RES,FLAGS,O1,O2,I1,I2,I3,EXPR,L,TEXPR1,TEXPR2) \
      case OP:                                                          \
	EXPR;                                                           \
        break;
#define DEFLINK(OP,MSK,NAME,MASK,SHIFT)                                 \
      case OP:                                                          \
	panic("attempted to execute a linking opcode");
#define CONNECT(OP)
#include "ss.def"
#undef DEFFU
#undef DEFINST
#undef DEFLINK
#undef CONNECT
  }

  /////////////////////////////////////////////////////////////////////
  if (SS_OPCODE(inst) == SYSCALL)
  {
    //ASZ: 4/24/05 eric changed the SYSCALL(INST) defintion in 2001 so we have to service traps here
    //trap_now(inst);
    trap_now();
    blocked = false;
  }
  /////////////////////////////////////////////////////////////////////

  /* execute next instruction */
  regs_PC = next_PC;
  next_PC += 8;
}   // func_sim_fast()

///////////////////////
// ASZL 4/24/05 SKIP func. sim. ahead
///////////////////////

void Thread::skip(SS_TIME_TYPE n_insn_skip)
{
  if (USE_INSTR_LIMIT)
    assert(n_insn_skip < INSTR_LIMIT);

  while (n_insn_skip > num_insn)
  {
    func_sim_fast();
  }  
  arch_PC = regs_PC;
}


// MJD Functional Checkpointing
///////////////////////////////

void Thread::restore_checkpoint(FILE *fp)
{
  struct a_checkpoint theCheckpoint;

  unsigned int blocks_loaded = 0;
  assert (checkpoint_fp == NULL);
  checkpoint_fp = fp;
  create_checkpoint = false;

#undef mem_table
  register char **local_mem_table = mem_table;
#define mem_table local_mem_table

  unsigned int row_index = 0;

  fread(&theCheckpoint, 1, sizeof(struct a_checkpoint), checkpoint_fp);

  // build checkpoint from segment specifiers, misc ... 
  num_insn = theCheckpoint.num_insn;
  num_refs = theCheckpoint.num_refs;
  arch_PC = theCheckpoint.arch_PC;
  blocked = theCheckpoint.blocked;

  ld_text_base = theCheckpoint.ld_text_base;     
  ld_text_size = theCheckpoint.ld_text_size;
  ld_data_base = theCheckpoint.ld_data_base;
  ld_data_size = theCheckpoint.ld_data_size;
  ld_stack_base = theCheckpoint.ld_stack_base;
  ld_stack_size = theCheckpoint.ld_stack_size;
  ld_prog_entry = theCheckpoint.ld_prog_entry;
  ld_environ_base = theCheckpoint.ld_environ_base;
  mem_brk_point = theCheckpoint.mem_brk_point;
  mem_stack_min = theCheckpoint.mem_stack_min;

  regs_HI = theCheckpoint.regs_HI;
  regs_LO = theCheckpoint.regs_LO;
  regs_FCC = theCheckpoint.regs_FCC;
  ShmemBase = theCheckpoint.ShmemBase;
  ShmemEnd = theCheckpoint.ShmemEnd;

  regs_PC = theCheckpoint.regs_PC;
  next_PC = theCheckpoint.next_PC; 

  lockaddr = theCheckpoint.lockaddr;
  n_shared_tas = theCheckpoint.n_shared_tas;     
  n_shared_tas_succeed = theCheckpoint.n_shared_tas_succeed;
  n_private_tas = theCheckpoint.n_private_tas;
  n_private_tas_succeed = theCheckpoint.n_private_tas_succeed;
  n_shared_acc = theCheckpoint.n_shared_acc;
  n_shared_new = theCheckpoint.n_shared_new;
  n_private_acc = theCheckpoint.n_private_acc;
  n_private_new = theCheckpoint.n_private_new;

  real_upper = theCheckpoint.real_upper;
  real_lower = theCheckpoint.real_lower;
  store_addr = theCheckpoint.store_addr;
  trap_inst.a = theCheckpoint.trap_inst_a;
  trap_inst.b = theCheckpoint.trap_inst_b;

  // add registers to checkpoint
  for (unsigned int i = 0; i < SS_NUM_REGS; i++)
    regs_R[i] = theCheckpoint.regs_R[i];

  for (unsigned int i = 0; i < SS_NUM_REGS; i++)
    regs_F.l[i] = theCheckpoint.regs_F_l[i];

  // prepare memory table for loading (clear it)
  for (unsigned int i = 0; i < MEM_TABLE_SIZE; i++)
  {
    if (mem_table[i])
    {
      delete[] mem_table[i];
      mem_table[i] = (char *)NULL;
    }
  }

  // load memory
  // determine number of blocks to load
  fread(&blocks_loaded, 1, sizeof(blocks_loaded), checkpoint_fp);

  // load the blocks
  for (unsigned int i = 0; i < blocks_loaded; i++)
  {
    // load the row number
    fread(&row_index, 1, sizeof(row_index), checkpoint_fp);
    // verify that this is a possible row
    assert(row_index < MEM_TABLE_SIZE);
    // verify that this row is empty
    assert(mem_table[row_index] == NULL);
    // allocate the row
    mem_table[row_index] = mem_newblock();
    // load the actual row
    fread(mem_table[row_index],sizeof (char), MEM_BLOCK_SIZE, checkpoint_fp);
    // tell the user we did something
    fprintf(stderr, ".");
  }

  fprintf(stderr,"\n%d blocks loaded of %d bytes each = %d bytes\n",
          blocks_loaded, MEM_BLOCK_SIZE, blocks_loaded*MEM_BLOCK_SIZE);
  fflush(stderr);
}

void Thread::save_checkpoint(FILE *fp)
{
  struct a_checkpoint theCheckpoint;

  unsigned int blocks_saved = 0;
  assert (checkpoint_fp == NULL);
  checkpoint_fp = fp;
  create_checkpoint = true;

#undef mem_table
  register char **local_mem_table = mem_table;
#define mem_table local_mem_table

  unsigned int row_index, i, word;

  // build checkpoint from segment specifiers, misc ... 
  theCheckpoint.num_insn = num_insn;
  theCheckpoint.num_refs = num_refs;
  theCheckpoint.arch_PC = arch_PC;
  theCheckpoint.blocked = blocked;

  theCheckpoint.ld_text_base = ld_text_base;     
  theCheckpoint.ld_text_size = ld_text_size;
  theCheckpoint.ld_data_base = ld_data_base;
  theCheckpoint.ld_data_size = ld_data_size;
  theCheckpoint.ld_stack_base = ld_stack_base;
  theCheckpoint.ld_stack_size = ld_stack_size;
  theCheckpoint.ld_prog_entry = ld_prog_entry;
  theCheckpoint.ld_environ_base = ld_environ_base;
  theCheckpoint.mem_brk_point = mem_brk_point;
  theCheckpoint.mem_stack_min = mem_stack_min;

  theCheckpoint.regs_HI = regs_HI;
  theCheckpoint.regs_LO = regs_LO;
  theCheckpoint.regs_FCC = regs_FCC;
  theCheckpoint.ShmemBase = ShmemBase;
  theCheckpoint.ShmemEnd = ShmemEnd;

  theCheckpoint.regs_PC = regs_PC;
  theCheckpoint.next_PC = next_PC; 

  theCheckpoint.lockaddr = lockaddr;
  theCheckpoint.n_shared_tas = n_shared_tas;     
  theCheckpoint.n_shared_tas_succeed = n_shared_tas_succeed;
  theCheckpoint.n_private_tas = n_private_tas;
  theCheckpoint.n_private_tas_succeed = n_private_tas_succeed;
  theCheckpoint.n_shared_acc = n_shared_acc;
  theCheckpoint.n_shared_new = n_shared_new;
  theCheckpoint.n_private_acc = n_private_acc;
  theCheckpoint.n_private_new = n_private_new;

  theCheckpoint.real_upper = real_upper;
  theCheckpoint.real_lower = real_lower;
  theCheckpoint.store_addr = store_addr;
  theCheckpoint.trap_inst_a = trap_inst.a;
  theCheckpoint.trap_inst_b = trap_inst.b;

  // add registers to checkpoint
  for (unsigned int i = 0; i < SS_NUM_REGS; i++)
    theCheckpoint.regs_R[i] = regs_R[i];

  for (unsigned int i = 0; i < SS_NUM_REGS; i++)
    theCheckpoint.regs_F_l[i] = regs_F.l[i];

  fwrite(&theCheckpoint, 1, sizeof(struct a_checkpoint), checkpoint_fp);

  // save memory

  // count blocks to save
  for (row_index = 0; row_index < MEM_TABLE_SIZE; row_index++)
    if (mem_table[row_index])
      blocks_saved++;

  // write number of blocks that we will save
  fwrite(&blocks_saved, 1, sizeof(blocks_saved), checkpoint_fp);

  // store the blocks
  for (row_index = 0; row_index < MEM_TABLE_SIZE; row_index++)
  {
    if (mem_table[row_index])
    {
      // store the row number first
      fwrite(&row_index, 1, sizeof(row_index), checkpoint_fp);
      // then store the actual row
      fwrite(mem_table[row_index],sizeof(char), MEM_BLOCK_SIZE, checkpoint_fp);
      fprintf(stderr, ".");
    }
  }
  fprintf(stderr, "Done.\n");

  fprintf(stderr,"\n%d blocks saved of %d bytes each = %d bytes\n",
          blocks_saved, MEM_BLOCK_SIZE, blocks_saved*MEM_BLOCK_SIZE);
  fflush(stderr);
}
