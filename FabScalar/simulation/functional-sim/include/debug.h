#include <assert.h>
#include "common.h"
#include "misc.h"
#include "ss.h"
#include "stdio.h"

///////////////
// DEFINES
///////////////

#define	D_MAX_RDST	2
#define	D_MAX_RSRC	4

#define DEBUG_INDEX_INVALID	0xBADBEEF

///////////////
// TYPES
///////////////

typedef
struct {
	unsigned int n;		// arch register
	unsigned int value;	// destination value
} db_reg_t;

typedef
union {
	unsigned int words[2];
	unsigned char bytes[8];
} store_data_t;

typedef
struct {
	// state from functional simulator
	unsigned int	a_pc;
	unsigned int	a_next_pc;
	SS_INST_TYPE	a_inst;
	unsigned int	a_flags;
	unsigned int	a_lat;
	unsigned int	a_num_rdst;
	db_reg_t	a_rdst[D_MAX_RDST];
	unsigned int	a_num_rsrc;
	db_reg_t	a_rsrc[D_MAX_RSRC];
	unsigned int	a_num_rsrcA;
	db_reg_t	a_rsrcA[D_MAX_RSRC];
	unsigned int	a_addr;

	// aligned doubleword of memory data
	unsigned int	real_upper;
	unsigned int	real_lower;

	// ER: 11/6/99
	// For stores, real_upper/real_lower is the doubleword of memory
	// before the store is performed.  The following data structure
	// contains the doubleword *after* the store is performed,
	// and can be accessed either as words or individual bytes.
	store_data_t    store_data;

	// STATS
	unsigned int why_vector;
} db_t;

typedef unsigned int	debug_index;



class debug_buffer {

private:
	///////////////////////////////////////////////////
	// DEBUG BUFFER
	///////////////////////////////////////////////////

	unsigned int DEBUG_SIZE;
	unsigned int ACTIVE_SIZE;

	db_t *db;
	unsigned int head;
	unsigned int tail;
	int length;

	unsigned int pc_ptr;	// used by pop_pc()

        ///////////////////////
        // PRIVATE FUNCTIONS
        ///////////////////////
 
        // Checks to see if index 'e' lies between 'head' and 'tail'.
        bool is_active(unsigned int e) {
           if (length > 0) {
              if (head <= tail)
                 return((e >= head) && (e <= tail));
              else
                 return((e >= head) || (e <= tail));
           }
           else {
              return(false);
           }
        }


public:
	///////////////
	// INTERFACE
	///////////////

	debug_buffer(unsigned int window_size) {
	   // Set the full size and active size of the debug buffer.
	   // Both had better be a power of two.
	   // DEBUG_SIZE = 4*window_size;
	   // ACTIVE_SIZE = 2*window_size;
	   DEBUG_SIZE = ACTIVE_SIZE = window_size;
	   assert(IsPow2(DEBUG_SIZE) && IsPow2(ACTIVE_SIZE));

	   // Allocate debug buffer.
	   db = new db_t[DEBUG_SIZE];

	   // Initialize debug buffer.
	   head = 0;
	   tail = (DEBUG_SIZE - 1);
	   length = 0;

	   pc_ptr = 0;
	}

	~debug_buffer() {
	}


	//////////////////////////////////////////////////////////////
	// Interface for collecting functional simulator state. 
	//////////////////////////////////////////////////////////////

	inline
	bool hungry() {
	   return(length < ACTIVE_SIZE);
	}

	void start() {
	   // Check for overflow and maintain 'length'.
	   assert(length < ACTIVE_SIZE);
	   length += 1;

	   // Initialize a new debug entry.
	   tail = MOD((tail + 1), DEBUG_SIZE);
	   db[tail].a_num_rdst = 0;
	   db[tail].a_num_rsrc = 0;
	   db[tail].a_num_rsrcA = 0;
	}

	void push_operand_actual(unsigned int n,
				 operand_t t,
				 unsigned int value,
				 unsigned int pc) {
	   unsigned int i;

	   switch (t) {
	      case RDST_OPERAND:
		 i = db[tail].a_num_rdst;
		 assert(i < D_MAX_RDST);
		 db[tail].a_rdst[i].n = n;
		 db[tail].a_rdst[i].value = value;
		 db[tail].a_num_rdst += 1;
		 break;
	      case RSRC_OPERAND:
		 i = db[tail].a_num_rsrc;
		 assert(i < D_MAX_RSRC);
		 db[tail].a_rsrc[i].n = n;
		 db[tail].a_rsrc[i].value = value;
		 db[tail].a_num_rsrc += 1;
		 break;
	      case RSRC_A_OPERAND:
		 i = db[tail].a_num_rsrcA;
		 assert(i < D_MAX_RSRC);
		 db[tail].a_rsrcA[i].n = n;
		 db[tail].a_rsrcA[i].value = value;
		 db[tail].a_num_rsrcA += 1;
	         break;
	      default:
		 assert(0);
		 break;
	   }
	}

	void push_address_actual(unsigned int addr,
				 operand_t t,
				 unsigned int pc,
				 unsigned int real_upper,
				 unsigned int real_lower) {
	   assert(t == MSRC_OPERAND || t == MDST_OPERAND);
	   db[tail].a_addr = addr;

	   db[tail].real_upper = real_upper;
	   db[tail].real_lower = real_lower;
	}

	void push_instr_actual(SS_INST_TYPE inst,
			       unsigned int flags,
			       unsigned int latency,
			       unsigned int pc,
			       unsigned int next_pc,
			       unsigned int real_upper,
			       unsigned int real_lower) {
	   db[tail].a_inst.a = inst.a;
	   db[tail].a_inst.b = inst.b;
	   db[tail].a_flags = flags;
	   db[tail].a_lat = latency;
	   db[tail].a_pc = pc;
	   db[tail].a_next_pc = next_pc;

	   // ER: 11/6/99
           if (flags & F_STORE) {
	      db[tail].store_data.words[0] = real_upper;
	      db[tail].store_data.words[1] = real_lower;
           }
	}


	//////////////////////////////////////////////////////////////
	// Interface for mapping ROB entries to debug buffer entries.
	//////////////////////////////////////////////////////////////

	// Assert that the head debug buffer entry has a program counter
	// value equal to 'pc'.
	// Then return the index of the head entry.
	debug_index first(unsigned int pc) {
	  if (pc != db[head].a_pc)
	   printf("\npc:%X functional pc: %X\n", pc, db[head].a_pc);
	  assert(pc == db[head].a_pc);
	   return(head);
	}

	// Check if the entry following 'i' has the same
	// program counter value as 'pc'.
	// If yes, then return the index of the entry following 'i',
	// else return DEBUG_INDEX_INVALID.
	debug_index check_next(debug_index i, unsigned int pc) {
	   unsigned int e;

	   // get the next entry
	   e = MOD((i + 1), DEBUG_SIZE);

	   if (is_active(e) && (pc == db[e].a_pc))
	      return(e);
	   else
	      return(DEBUG_INDEX_INVALID);
	}

	// Search for the first occurrence of 'pc' in the debug buffer,
	// starting with the entry _after_ 'i'.
	// If found, return that entry's index, else return DEBUG_INDEX_INVALID.
	debug_index find(debug_index i, unsigned int pc) {
	   unsigned int e;

	   // Get the next entry.
	   e = MOD((i + 1), DEBUG_SIZE);

	   // While within the active region of debug buffer,
	   // search for 'pc'.
	   while (is_active(e)) {
	      if (pc == db[e].a_pc)
	         return(e);			// FOUND IT!
	      else
		 e = MOD((e + 1), DEBUG_SIZE);
	   }

	   // Must not have found it if loop takes normal exit.
	   return(DEBUG_INDEX_INVALID);
	}


	//////////////////////////////////////////////////////////////
	// Interface for viewing debug buffer state.
	//////////////////////////////////////////////////////////////

	// Return a pointer to the contents of an arbitrary debug buffer entry.
	// The debug buffer entry must be in the 'active window' of the buffer.
	inline
	db_t *peek(debug_index i) {
	   assert(is_active(i));
	   return( &(db[i]) );
	}

	// Assert that the index of the head debug buffer entry equals 'i'.
	// Then pop the head entry, returning a pointer to the contents of
	// that entry.
	inline
	db_t *pop(debug_index i) {
	   assert(i == head);

	   // Check for underflow and maintain 'length'.
	   assert(length > 0);
	   length -= 1;

	   // Pop the head entry by advancing head pointer.
	   head = MOD((head + 1), DEBUG_SIZE);

	   // Return a pointer to (what was) the head entry.
	   return( &(db[i]) );
	}

	inline
	bool empty() {
	   return(length == 0);
	}


	//////////////////////////////////////////////////////////////
	// Interface for facilitating perfect branch prediction.
	//////////////////////////////////////////////////////////////

	inline
	unsigned int pop_pc() {
	  unsigned npc;
	   // Return PC of *next* instruction.
	  // pc_ptr = MOD((pc_ptr + 1), DEBUG_SIZE);
	  npc = db[pc_ptr].a_pc;
	   pc_ptr = MOD((pc_ptr + 1), DEBUG_SIZE);
	   return(npc);
	}


	///////////////////////////////////////////////////////////////////////
	// Pushing of the last instruction (syscall-exit) onto the debug buffer
	// did not complete, because we appropriately exited func_sim() upon
	// executing the syscall!  So, complete the process.
	///////////////////////////////////////////////////////////////////////

	inline
	void finish_syscall_exit() {
	   unsigned int x;
	   SS_INST_TYPE inst;
 
	   x = MOD((tail + DEBUG_SIZE - 1), DEBUG_SIZE);
	   inst.a = 0x6f;
	   inst.b = 0x0;
 
	   push_instr_actual(inst, F_TRAP, 1, db[x].a_next_pc, 0, 0, 0);
	}
};
