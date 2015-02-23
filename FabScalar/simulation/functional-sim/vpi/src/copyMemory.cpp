#include <stdio.h>
#include <stdlib.h>
#include "vpi_user.h"

#include "Thread.h"
#include "veri_memory_macros.h"
#include "veri_memory.h"
#include "global_vars.h"
#include "VPI_global_vars.h"

int copyMemory_calltf(char *user_data)
{
  vpiHandle systf_handle, arg_iterator, arg_handle, reg_handle;
  s_vpi_value current_value;
  s_vpi_value value_s;

  /* obtain a handle to the system task instance. */
  systf_handle  = vpi_handle(vpiSysTfCall, 0);

  /* obtain handle to system task argument. */
  //arg_iterator  = vpi_iterate(vpiArgument, systf_handle);
  //reg_handle    = vpi_scan(arg_iterator);

  /* free iterator memory */
  //vpi_free_object(arg_iterator);


  VMEM[0]->copy_mem(THREAD[0]->get_mem_table());
  vpi_printf("Memory table copied from functional simulator\n");

  return(0);

}




// Associate C Function with a New System Function
void copyMemory_register() {
  s_vpi_systf_data task_data_s;

  task_data_s.type      = vpiSysTask;
  //task_data_s.sysfunctype = vpiSysFuncSized;
  task_data_s.tfname    = "$copyMemory";
  task_data_s.calltf    = copyMemory_calltf;
  task_data_s.compiletf = 0;
  //task_data_s.sizetf    = readInst_sizetf;

  vpi_register_systf(&task_data_s);
}
