#include <stdio.h>
#include <stdlib.h>
#include "vpi_user.h"

#include "Thread.h"
#include "veri_memory_macros.h"
#include "veri_memory.h"
#include "global_vars.h"
#include "VPI_global_vars.h"

int checkRetireInst_calltf(char *user_data)
{
  db_t * db_ptr;
  unsigned int FS_PC;
  unsigned int V_PC;
  SS_WORD_TYPE FS_rdst_value;
  SS_WORD_TYPE V_rdst_value;
  vpiHandle systf_handle, arg_iterator, arg_handle, reg_handle;
  s_vpi_value arg1;
  s_vpi_value arg2;
  // s_vpi_value value_s;
  //unsigned long long instruction;

  /* obtain a handle to the system task instance. */
  systf_handle  = vpi_handle(vpiSysTfCall, 0);

  /* obtain handle to system task argument. */
  arg_iterator  = vpi_iterate(vpiArgument, systf_handle);
  reg_handle    = vpi_scan(arg_iterator);


  /* read current value */
  arg1.format = vpiIntVal;  /* read value as a integer */
  vpi_get_value(reg_handle, &arg1);
  V_PC = (unsigned int) arg1.value.integer;

  // Next value
  reg_handle    = vpi_scan(arg_iterator);
  arg2.format = vpiIntVal;  /* read value as a integer */
  vpi_get_value(reg_handle, &arg2);
  V_rdst_value = (SS_WORD_TYPE) arg2.value.integer;

  // Pop from DB (head) 
  db_ptr = THREAD[0]->get_instr();
  FS_PC = (unsigned int) db_ptr->a_pc;
  if (db_ptr->a_num_rdst > 1) {
    vpi_printf("Double Word destination!!\n");
    vpi_printf("Bye !!\n");
    assert(0);
  }
  if (db_ptr->a_num_rdst == 1)
    FS_rdst_value = db_ptr->a_rdst[0].value;

  // Do the check
  if (V_PC != FS_PC) {
    vpi_printf("Retire PC Error!! ");
    vpi_printf("PC:%x Actual:%x\n",V_PC, FS_PC);
    assert(0);
  }

  if (db_ptr->a_num_rdst == 1) {
    if (V_rdst_value != FS_rdst_value) {
      vpi_printf("Rdst Value Error!! ");
      vpi_printf("Rdst:%x Actual:%x\n",V_rdst_value, FS_rdst_value);
      assert(0);
    }
  }

  /* free iterator memory */
  vpi_free_object(arg_iterator);

  return(0);

}




// Associate C Function with a New System Function
void checkRetireInst_register() {
  s_vpi_systf_data task_data_s;

  task_data_s.type      = vpiSysTask;
  //task_data_s.sysfunctype = vpiSysFuncSized;
  task_data_s.tfname    = "$checkRetireInst";
  task_data_s.calltf    = checkRetireInst_calltf;
  task_data_s.compiletf = 0;
  //task_data_s.sizetf    = readInst_sizetf;

  vpi_register_systf(&task_data_s);
}
