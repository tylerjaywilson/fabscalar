#ifndef _THREAD_H_
#define _THREAD_H_


#include "ss.h"
#include "regs.h"
#include "memory.h"
#include "loader.h"
#include "sim.h"
#include "syscall.h"
#include "info.h"
#include "mt.h"
#include "operand.h"
#include "debug.h"
#include "hw_counters.h"


class Thread {

private:

typedef void
(Thread::*mem_access_fn)(enum mem_cmd cmd,      /* Read or Write */
			 unsigned long addr,    /* address to access */
			 void *p,               /* where to copy to/from */
			 int nbytes);           /* xfer length */


///////////
// LOADER
///////////
SS_ADDR_TYPE ld_text_base;
SS_ADDR_TYPE ld_text_size;
SS_ADDR_TYPE ld_data_base;
SS_ADDR_TYPE ld_data_size;
SS_ADDR_TYPE ld_stack_base;
SS_ADDR_TYPE ld_stack_size;
SS_ADDR_TYPE ld_prog_entry;
SS_ADDR_TYPE ld_environ_base;


void mem_access(enum mem_cmd cmd, SS_ADDR_TYPE addr, void *p, int nbytes);

void
ld_load_prog(mem_access_fn mem_fn,
             int argc, char **argv, char **envp,
             int zero_bss_segs);


//AA::for new loader
char *ld_prog_fname;

///////////
// MEMORY
///////////
SS_ADDR_TYPE mem_brk_point;	// top of the data segment
SS_ADDR_TYPE mem_stack_min;	// lowest address accessed on the stack
char *mem_table[MEM_TABLE_SIZE];

//void mem_access(enum mem_cmd cmd, SS_ADDR_TYPE addr, void *p, int nbytes);
char *mem_newblock(void);
int mem_strcpy(mem_access_fn mem_fn, enum mem_cmd cmd, SS_ADDR_TYPE addr,
	       char *s);
void mem_bcopy(mem_access_fn mem_fn, enum mem_cmd cmd, SS_ADDR_TYPE addr,
               void *p, int nbytes);
void mem_bcopy4(mem_access_fn mem_fn, enum mem_cmd cmd, SS_ADDR_TYPE addr,
                void *p, int nbytes);
void mem_bzero(mem_access_fn mem_fn, SS_ADDR_TYPE addr, int nbytes);
void mem_init(void);

// 12/25/99 ER: Added bogus shared memory support (postgres).
unsigned int ShmemBase;
unsigned int ShmemEnd;

// 12/28/99 ER:
// This state is set when a lock fails; the unlock-syscall will reset 'blocked'
// if unlocking the same lock pointed to by lockaddr.
// The user must consult IsBlocked() -- if true, get_instr() must not
// be called.
bool blocked;
SS_ADDR_TYPE lockaddr;	// address of lock

//////////////////////////////////
// SimpleScalar processor state.
//////////////////////////////////
SS_WORD_TYPE regs_R[SS_NUM_REGS];	// (signed) integer regs
union regs_FP regs_F;			// floating point regs
SS_WORD_TYPE regs_HI;		// (signed) hi register, hold mul/div results
SS_WORD_TYPE regs_LO;		// (signed) lo register, hold mul/div results
int regs_FCC;			// floating point condition codes
SS_ADDR_TYPE regs_PC;	// PC of last complete instruction w/r/t precise state
SS_ADDR_TYPE next_PC;	// not really part of ISA...

void regs_init(void);
void regs_dump(FILE *stream);

//#ifdef sparc
#if 0
register SS_WORD_TYPE *local_regs_R asm("g5");
#else
SS_WORD_TYPE *local_regs_R;
#endif

///////////
// SYSCALL
///////////
void ss_syscall(mem_access_fn mem_fn, SS_INST_TYPE inst);

/////////////////
// Debug buffer
/////////////////
//#define DB_SIZE 8192
//#define DB_SIZE 8192*128
#define DB_SIZE 8192*2
debug_buffer *DB;
unsigned int arch_PC;

//////////
// STATS
//////////
unsigned int n_shared_tas;	    // test&set's to shared mem lock
unsigned int n_shared_tas_succeed;  // num that succeeded...
unsigned int n_private_tas;	    // test&set's to private mem lock
unsigned int n_private_tas_succeed; // num that succeeded...
unsigned int n_shared_acc;	    // number of shared memory accesses
unsigned int n_shared_new;	    // number of mem_newblock's to shmem_table
unsigned int n_private_acc;	    // number of private memory accesses
unsigned int n_private_new;	    // number of mem_newblock's to mem_table

///////////////////////////////////
// The functional simulator core!
///////////////////////////////////
void func_sim();
void InstSRA(SS_INST_TYPE inst);
void InstSRAV(SS_INST_TYPE inst);
void InstMULT(SS_INST_TYPE inst);
void InstMULTU(SS_INST_TYPE inst);

// some temp state
unsigned int real_upper, real_lower;
unsigned int store_addr;
SS_INST_TYPE trap_inst;         // 06/09/01 ER

// 06/09/01 ER:  Added support for "hardware profiling counters".
//		 First use: real-time embedded systems research.
#define NUM_HW_COUNTERS	8
unsigned int hardware_counters[NUM_HW_COUNTERS];


public:

//////////
// STATS
//////////
SS_COUNTER_TYPE num_insn;
SS_COUNTER_TYPE num_refs;

Thread(int argc, char **argv, char **envp) {
	// initialize loader state
	unsigned int i;
        ld_text_base = 0;
	ld_text_size = 0;
	ld_data_base = 0;
	ld_data_size = 0;
	ld_stack_base = SS_STACK_BASE;
	ld_stack_size = 0;
	ld_prog_entry = 0;
	ld_environ_base = 0;

	// initialize address spaces
	for (i=0; i<MEM_TABLE_SIZE; i++) {
	   mem_table[i] = NULL;
	   shmem_table[i] = NULL;	// Oh well, each thread does it...
	}

	// 12/25/99 ER: Added bogus shared memory support (postgres).
	ShmemBase = 0;
	ShmemEnd = 0;

	// load the program text and data, set up environment, memory, and regs
	ld_load_prog(&Thread::mem_access, argc, argv, envp, TRUE);
	regs_init();
	regs_R[SS_STACK_REGNO] = ld_environ_base;
	regs_PC = ld_prog_entry;
	mem_init();

	// Print out the thread args.
	printf("Thread:\t");
	for (i = 0; i < argc; i++)
	   printf(" %s", argv[i]);
	printf("\n");

	// Create the debug buffer.
	DB = NULL;
	DB = new debug_buffer(DB_SIZE);
	if (DB == NULL)
	  printf("Cannot allocate debug buffer!!!\n");

	// Initialize stats.
	n_shared_tas = 0;
	n_shared_tas_succeed = 0;
	n_private_tas = 0;
	n_private_tas_succeed = 0;
	n_shared_acc = 0;
	n_shared_new = 0;
	n_private_acc = 0;
	n_private_new = 0;

	blocked = false;

	checkpoint_fp = NULL;
}

// fork-created thread
Thread(Thread *master, SS_ADDR_TYPE ThreadIdPtr, unsigned int id) {
	// Print out that a thread has been forked.
	printf("Thread forked\n");

	// Copy memory state from the master thread.
	char **master_mem_table = master->get_mem_table();
	for (unsigned int i = 0; i < MEM_TABLE_SIZE; i++) {
	   if (master_mem_table[i]) {
	      mem_table[i] = mem_newblock();
	      for (unsigned int j = 0; j < MEM_BLOCK_SIZE; j++)
		 mem_table[i][j] = master_mem_table[i][j];
	   }
	   else {
	      mem_table[i] = (char *)NULL;
	   }
	}

	// Copy all other state from the master thread.
	master->copy(ld_text_base, ld_text_size, ld_data_base, ld_data_size,
		     ld_stack_base, ld_stack_size, ld_prog_entry,
		     ld_environ_base, mem_brk_point, mem_stack_min,
		     regs_R, regs_F, regs_HI, regs_LO, regs_FCC, regs_PC,
		     next_PC, ShmemBase, ShmemEnd);

	// Change the statically declared, private memory location
	// corresponding to the thread id.
	MEM_WORD(ThreadIdPtr) = id;

	/////////////////////////////////////////////////

	num_insn = 0;
	num_refs = 0;
	local_regs_R = regs_R;
	arch_PC = regs_PC;

	// Create the debug buffer.
	DB = new debug_buffer(DB_SIZE);

	// Initialize stats.
	n_shared_tas = 0;
	n_shared_tas_succeed = 0;
	n_private_tas = 0;
	n_private_tas_succeed = 0;
	n_shared_acc = 0;
	n_shared_new = 0;
	n_private_acc = 0;
	n_private_new = 0;

	blocked = false;
}

~Thread() {
}

 SS_ADDR_TYPE get_ld_text_base(void) {
   return ld_text_base;
 }
 SS_ADDR_TYPE get_ld_text_size(void) {
   return ld_text_size;
 }
 SS_ADDR_TYPE get_ld_data_base(void) {
   return ld_data_base;
 }
 SS_ADDR_TYPE get_ld_data_size(void) {
   return ld_data_size;
 }
 SS_ADDR_TYPE get_ld_stack_base(void) {
   return ld_stack_base;
 }
 SS_ADDR_TYPE get_ld_stack_size(void) {
   return ld_stack_size;
 }
 SS_ADDR_TYPE get_ld_prog_entry(void) {
   return ld_prog_entry;
 }
 SS_ADDR_TYPE get_ld_envion_base(void) {
   return ld_environ_base;
 }


void decode() {
  register SS_INST_TYPE inst;

  INFO("starting *fast* functional simulation");

  /* must have natural byte/word ordering */
  if (sim_swap_bytes || sim_swap_words)
    fatal("*fast* functional simulation cannot swap bytes or words");

  num_insn = 0;
  num_refs = 0;
  local_regs_R = regs_R;

  regs_PC = ld_prog_entry - SS_INST_SIZE;
  next_PC = ld_prog_entry;

  /* decode all instructions */
  {
    SS_ADDR_TYPE addr;

    if (OP_MAX > 255)
      fatal("cannot do fast decoding, too many opcodes");

    fprintf(stderr, "decoding text segment...");
    for (addr=ld_text_base;
         addr < (ld_text_base+ld_text_size);
         addr += SS_INST_SIZE)
      {
        inst = __UNCHK_MEM_ACCESS(SS_INST_TYPE, addr);
        inst.a = (inst.a & ~0xff) | (unsigned long)SS_OP_ENUM(SS_OPCODE(inst));
        __UNCHK_MEM_ACCESS(SS_INST_TYPE, addr) = inst;
      }
    fprintf(stderr, "done.\n");
  }

  /* execute next instruction */
  regs_PC = next_PC;
  next_PC += 8;

  arch_PC = regs_PC;
}

db_t *get_instr() {
	debug_index db_index;
	db_t *db_ptr;

	while (!blocked && DB->hungry())
	   func_sim();

	db_index = DB->first(arch_PC);
	db_ptr = DB->pop(db_index);
	arch_PC = db_ptr->a_next_pc;

	return(db_ptr);
} 

void stats() {
  INFO("---------");

  INFO("sim: executed %.0f instructions", (double)num_insn);
  //INFO("sim: simulation time: %s (%f insts/sec)",
  //     elapsed_time(elapsed), (double)num_insn/(double)elapsed);

  INFO("--> Lock information:");
  INFO("\tshared locks:\taccesses = %d\tfails = %d (%.1f%%)",
	n_shared_tas,
	(n_shared_tas - n_shared_tas_succeed),
	100.0*(double)(n_shared_tas - n_shared_tas_succeed)/
	      (double)(n_shared_tas));
  INFO("\tprivate locks:\taccesses = %d\tfails = %d (%.1f%%)",
	n_private_tas,
	(n_private_tas - n_private_tas_succeed),
	100.0*(double)(n_private_tas - n_private_tas_succeed)/
	      (double)(n_private_tas));
  INFO("--> Shared/Private memory information:");
  INFO("\tshared accesses = %d (%.1f%%)",
	n_shared_acc,
	100.0*(double)(n_shared_acc)/(double)(n_shared_acc + n_private_acc));
  INFO("\tprivate accesses = %d (%.1f%%)",
	n_private_acc,
	100.0*(double)(n_private_acc)/(double)(n_shared_acc + n_private_acc));
  INFO("\tshared mem_newblock's = %d", n_shared_new);
  INFO("\tprivate mem_newblock's = %d", n_private_new);
  INFO("---------");
}

void mem_stats(FILE *stream);
void mem_dump(mem_access_fn mem_fn, SS_ADDR_TYPE addr, int len, FILE *stream);

// 12/25/99 ER: Check for shared memory accesses.
inline
bool IsShared(unsigned int addr) {
	return(addr < ShmemEnd && addr >= ShmemBase);
}

// 12/26/99 ER: Support for forking a thread (copying state).
inline
char **get_mem_table() {
	return(mem_table);
}

void copy(SS_ADDR_TYPE& ld_text_base,
	  SS_ADDR_TYPE& ld_text_size,
	  SS_ADDR_TYPE& ld_data_base,
	  SS_ADDR_TYPE& ld_data_size,
	  SS_ADDR_TYPE& ld_stack_base,
	  SS_ADDR_TYPE& ld_stack_size,
	  SS_ADDR_TYPE& ld_prog_entry,
	  SS_ADDR_TYPE& ld_environ_base,
	  SS_ADDR_TYPE& mem_brk_point,
	  SS_ADDR_TYPE& mem_stack_min,
	  SS_WORD_TYPE *regs_R,
	  union regs_FP& regs_F,
	  SS_WORD_TYPE& regs_HI,
	  SS_WORD_TYPE& regs_LO,
	  int& regs_FCC,
	  SS_ADDR_TYPE& regs_PC,
	  SS_ADDR_TYPE& next_PC,
	  unsigned int& ShmemBase,
	  unsigned int& ShmemEnd) {
	ld_text_base = this->ld_text_base;
	ld_text_size = this->ld_text_size;
	ld_data_base = this->ld_data_base;
	ld_data_size = this->ld_data_size;
	ld_stack_base = this->ld_stack_base;
	ld_stack_size = this->ld_stack_size;
	ld_prog_entry = this->ld_prog_entry;
	ld_environ_base = this->ld_environ_base;
	mem_brk_point = this->mem_brk_point;
	mem_stack_min = this->mem_stack_min;

	for (unsigned int i = 0; i < SS_NUM_REGS; i++) {
	   regs_R[i] = this->regs_R[i];
	   regs_F.l[i] = this->regs_F.l[i];
	}

	regs_HI = this->regs_HI;
	regs_LO = this->regs_LO;
	regs_FCC = this->regs_FCC;
	ShmemBase = this->ShmemBase;
	ShmemEnd = this->ShmemEnd;

	// Careful: we don't want to syscall (trap) again!
	// The master thread is currently executing a syscall (ss_fork);
	// therefore, set the slave thread to point to the very next
	// instruction.
	regs_PC = this->regs_PC + SS_INST_SIZE;
	next_PC = regs_PC + SS_INST_SIZE;
}

void wakeup(SS_ADDR_TYPE lockaddr) {
	if (blocked && this->lockaddr == lockaddr) {
	   //////////////////
	   // RESET STATE
	   //////////////////
	   blocked = false;

	   //////////////////
	   // RETRY Test&Set
	   //////////////////
	   // we wrote the lock value into r2 ; set r2 back to the syscall code
	   regs_R[2] = (SS_WORD_TYPE) SS_SYS_test_and_set;

	   // r4 should still contain the original lock address
	   assert((SS_ADDR_TYPE)regs_R[4] == this->lockaddr);

	   // retry
	   SS_INST_TYPE dummy; dummy.a = 0; dummy.b = 0;
	   ss_syscall(&Thread::mem_access, dummy);
	}
}

inline
bool IsBlocked() {
	return(blocked && DB->empty());
}

///////////////////////
// DEBUG INTERFACE
///////////////////////
db_t *pop(debug_index i) {
	db_t *db_ptr;

	while (!blocked && DB->hungry())
	   func_sim();

	db_ptr = DB->pop(i);
	arch_PC = db_ptr->a_next_pc;

	return(db_ptr);
} 

inline
db_t *peek(debug_index i) {
	return(DB->peek(i));
}

inline
debug_index first(unsigned int pc) {
	return(DB->first(pc));
}

inline
debug_index check_next(debug_index i, unsigned int pc) {
	return(DB->check_next(i, pc));
}

inline
unsigned int pop_pc() {
	return(DB->pop_pc());
}

///////////////////////
// Run func. sim. ahead
///////////////////////
inline
void run_ahead() {
	while (!blocked && DB->hungry())
	   func_sim();
}

///////////////////////
// access arch_PC
///////////////////////
inline
unsigned int get_arch_PC() {
	return(arch_PC);
}

///////////////////////
// instruction fetch
///////////////////////
void fetch(unsigned int pc, SS_INST_TYPE& inst) {
	// Fetch instruction from the binary.
	if ((pc < ld_text_base) || (pc > ld_text_base + ld_text_size)) {
	   inst.a = (unsigned int)NOP;
	   inst.b = 0;
	}
	else {
	   inst = __UNCHK_MEM_ACCESS(SS_INST_TYPE, (pc & ~7));
	}
}

//////////////////////////////////////////////////////
// Clear out the debug buffer after program is done.
//////////////////////////////////////////////////////
inline
void cleanup_init() {
	DB->finish_syscall_exit();
}

inline
db_t *cleanup_get_instr() {
	debug_index db_index;
	db_t *db_ptr;

	if (!DB->empty()) {
	   db_index = DB->first(arch_PC);
	   db_ptr = DB->pop(db_index);
	   arch_PC = db_ptr->a_next_pc;

	   return(db_ptr);
	}
	else {
	   return((db_t *)NULL);
	}
 }

 inline
  SS_ADDR_TYPE get_ld_environ_base(void) {
   return(ld_environ_base);
 }

// 06/09/01 ER:  Added support for "hardware profiling counters".
//		 First use: real-time embedded systems research.
void reset_hw_counter(unsigned int ctr) {
   assert(ctr < NUM_HW_COUNTERS);
   hardware_counters[ctr] = 0;
}
unsigned int read_hw_counter(unsigned int ctr) {
   assert(ctr < NUM_HW_COUNTERS);
   return( hardware_counters[ctr] );
}
void increment_hw_counter(unsigned int ctr) {
   assert(ctr < NUM_HW_COUNTERS);
   hardware_counters[ctr]++;
}

//////////////////
// 06/09/01 ER
//////////////////
void trap_stop(SS_INST_TYPE inst);
//void trap_now(SS_INST_TYPE inst);
void trap_now();
void trap_resume();

///////////////////////
// ASZL 4/24/05 SKIP func. sim. ahead
///////////////////////
void skip(SS_TIME_TYPE n_insn_skip);
void func_sim_fast();

unsigned int get_arch_reg_value(unsigned int n);
void get_arch_mem_value(unsigned int n,
			unsigned int *upper,
			unsigned int *lower);

////////////////////
// MJD Checkpointing
////////////////////
FILE *checkpoint_fp;
bool create_checkpoint;
//char *start_memory[MEM_TABLE_SIZE];

// The next two functions are used to restore from a checkpoint
// The simulator only calls the first one . . . 
void restore_checkpoint(FILE *fp);
void restore_trap();

// The next three functions are used to create a checkpoint
// The simulator should call only the first . . .  
void save_checkpoint(FILE *fp);
void save_trap();
void stop_checkpoint();

};	// Thread class

#define MAX_THREADS	4

// extern Thread *THREAD[MAX_THREADS];
// extern unsigned int NumThreads;


#endif
