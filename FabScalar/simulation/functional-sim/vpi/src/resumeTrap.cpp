#include <stdio.h>
#include <stdlib.h>
#include "vpi_user.h"

#include "Thread.h"
#include "veri_memory_macros.h"
#include "veri_memory.h"
#include "global_vars.h"
#include "VPI_global_vars.h"


int resumeTrap_calltf(char *user_data)
{

  /* Func. sim. is waiting to resume after the trap.
   * Signal it to resume.
   */
  THREAD[0]->trap_resume();

  return(0);
}




// Associate C Function with a New System Function
void resumeTrap_register() {
  s_vpi_systf_data task_data_s;

  task_data_s.type      = vpiSysTask;
  task_data_s.tfname    = "$resumeTrap";
  task_data_s.calltf    = resumeTrap_calltf;
  task_data_s.compiletf = 0;
  //task_data_s.sizetf    = readInst_sizetf;

  vpi_register_systf(&task_data_s);
}
