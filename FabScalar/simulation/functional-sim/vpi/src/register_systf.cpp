#include "vpi_user.h"
#include "Thread.h"
#include "global_vars.h"
#include "vpi_routines.h"

// Register the new system task here
void (*vlog_startup_routines[ ] ) () = {
   initializeSim_register,
   readOpcode_register,
   readOperand_register,
   readUnsignedByte_register,
   readSignedByte_register,
   readUnsignedHalf_register,
   readSignedHalf_register,
   readWord_register,
   writeByte_register,
   writeHalf_register,
   writeWord_register,
   getArchRegValue_register,
   copyMemory_register,
   getRetireInstPC_register,
   getArchPC_register,
   handleTrap_register,	
   resumeTrap_register,	
   // Added "getPerfectNPC_register" and "funcsimRunahead_register" for
   // perfect branch prediction and perfect cache.
   getPerfectNPC_register,
   funcsimRunahead_register,
   0  // last entry must be 0 
}; 

