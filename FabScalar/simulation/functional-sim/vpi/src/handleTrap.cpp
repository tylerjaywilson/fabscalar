#include <stdio.h>
#include <stdlib.h>
#include "vpi_user.h"

#include "Thread.h"
#include "veri_memory_macros.h"
#include "veri_memory.h"
#include "global_vars.h"
#include "VPI_global_vars.h"


int handleTrap_calltf(char *user_data)
{

  /* Func. sim. is stalled waiting to execute the trap.
   * Signal it to proceed with the trap.
   */
  THREAD[0]->trap_now();

  return(0);
}




// Associate C Function with a New System Function
void handleTrap_register() {
  s_vpi_systf_data task_data_s;

  task_data_s.type      = vpiSysTask;
  task_data_s.tfname    = "$handleTrap";
  task_data_s.calltf    = handleTrap_calltf;
  task_data_s.compiletf = 0;
  //task_data_s.sizetf    = readInst_sizetf;

  vpi_register_systf(&task_data_s);
}
