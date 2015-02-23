#include <stdio.h>
#include <stdlib.h>
#include "vpi_user.h"

#include "Thread.h"
#include "veri_memory_macros.h"
#include "veri_memory.h"
#include "VPI_global_vars.h"

int writeHalf_calltf(char *user_data)
{
  unsigned short src;
  vpiHandle systf_handle, arg_iterator, arg_handle, reg_handle;
  s_vpi_value current_value1;
  s_vpi_value current_value2;
  //unsigned long long instruction;


  /* obtain a handle to the system task instance. */
  systf_handle  = vpi_handle(vpiSysTfCall, 0);

  /* obtain handle to system task argument. */
  arg_iterator  = vpi_iterate(vpiArgument, systf_handle);
  reg_handle    = vpi_scan(arg_iterator);

  /* read current value */
  current_value1.format = vpiIntVal;  /* read value as a integer (Value to be writen) */
  vpi_get_value(reg_handle, &current_value1);
  src = (unsigned short) current_value1.value.integer;

  reg_handle    = vpi_scan(arg_iterator);
  current_value2.format = vpiIntVal;  /* read value as a integer (Address in the memory) */
  vpi_get_value(reg_handle, &current_value2);

  /* free iterator memory */
  vpi_free_object(arg_iterator);
 
  //vpi_printf("Data writen \t%x\n",current_value2.value.integer);
  VMEM[0]->write_half(src,current_value2.value.integer);

  return(0);    
}




// Associate C Function with a New System Function
void writeHalf_register() {
  s_vpi_systf_data task_data_s;

  task_data_s.type      = vpiSysTask;
  //task_data_s.sysfunctype = vpiSysFuncSized;
  task_data_s.tfname    = "$writeHalf";
  task_data_s.calltf    = writeHalf_calltf;
  task_data_s.compiletf = 0;
  //task_data_s.sizetf    = readInst_sizetf;

  vpi_register_systf(&task_data_s);
}
