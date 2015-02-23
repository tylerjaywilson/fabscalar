#include <assert.h>
#include "Thread.h"


//
// Get the architectural value for a register from the functional simulator.
// We assume the functional simulator is in *sync* with the timing simulator
// in terms of architectural (committed) state.
// (I.e. the functional simulator can't "run ahead" of the timing simulator.)
//
unsigned int Thread::get_arch_reg_value(unsigned int n) {
	if (n < FPR_BASE)
	   return(regs_R[n]);
	else if (n < HI_ID)
	   return(regs_F.l[n-FPR_BASE]);
	else if (n == HI_ID)
	   return(regs_HI);
	else if (n == LO_ID)
	   return(regs_LO);
	else if (n == FCC_ID)
	   return(regs_FCC);
	else
	   assert(0);
}


//
// Ditto above, except get architectural values from
// the functional simulator's memory.
//
void Thread::get_arch_mem_value(unsigned int n,
				unsigned int *upper,
				unsigned int *lower) {
   unsigned int addr_dw;	// doubleword-aligned address

   addr_dw = (n & ~7);

   if ((addr_dw >= ld_text_base && addr_dw < (ld_text_base+ld_text_size)) ||
       (addr_dw >= ld_data_base && addr_dw < ld_stack_base)) {
#ifdef BYTES_LITTLE_ENDIAN
      *upper = MEM_WORD(addr_dw + 4);
      *lower = MEM_WORD(addr_dw);
#else
      *upper = MEM_WORD(addr_dw);
      *lower = MEM_WORD(addr_dw + 4);
#endif
   }
   else {
      // Address is out of range (i.e. bad address) -
      // should be able to return junk.
      *upper = 0;
      *lower = 0;
   }
}
