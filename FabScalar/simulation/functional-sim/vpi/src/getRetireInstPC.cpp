#include <stdio.h>
#include <stdlib.h>
#include "vpi_user.h"

#include "Thread.h"
#include "veri_memory_macros.h"
#include "veri_memory.h"
#include "global_vars.h"
#include "VPI_global_vars.h"

#define V_ENABLE_INDEX           0
#define V_CYCLE_INDEX            (V_ENABLE_INDEX + 1)
#define V_PC_INDEX               (V_CYCLE_INDEX + 1)
#define V_RDST_INDEX             (V_PC_INDEX + 1)
#define V_RDST_VALUE_INDEX       (V_RDST_INDEX + 1)
#define V_FISSION_INDEX       	 (V_RDST_VALUE_INDEX + 1)
#define V_MAX_INDEX              (V_FISSION_INDEX + 1)

int getRetireInstPC_calltf(char *user_data)
{
  db_t * db_ptr;
  unsigned int V_CHECK_ENABLE;
  unsigned int V_CHECK_FISSION;
  unsigned int V_CYCLE, V_PC, V_RDST, V_RDST_VALUE;
  unsigned int FS_PC, FS_RDST, FS_RDST_VALUE;
  vpiHandle systf_handle, arg_iterator, arg_handle, reg_handle;
  s_vpi_value current_value;
  s_vpi_value arg[V_MAX_INDEX];

  //unsigned long long instruction;

  /* obtain a handle to the system task instance. */
  systf_handle  = vpi_handle(vpiSysTfCall, 0);

  /* obtain handle to system task argument. */
  arg_iterator  = vpi_iterate(vpiArgument, systf_handle);

  // First Argument
  reg_handle    = vpi_scan(arg_iterator);
  // Read CHECK_ENABLE
  arg[V_ENABLE_INDEX].format = vpiIntVal;
  vpi_get_value(reg_handle, &arg[V_ENABLE_INDEX]);
  V_CHECK_ENABLE = (unsigned int) arg[V_ENABLE_INDEX].value.integer;

  // Next argument
  reg_handle    = vpi_scan(arg_iterator);
  // Read CYCLE
  arg[V_CYCLE_INDEX].format = vpiIntVal;
  vpi_get_value(reg_handle, &arg[V_CYCLE_INDEX]);
  V_CYCLE = (unsigned int) arg[V_CYCLE_INDEX].value.integer;

  // Next argument
  reg_handle    = vpi_scan(arg_iterator);
  // READ RETIRED_PC
  arg[V_PC_INDEX].format = vpiIntVal;
  vpi_get_value(reg_handle, &arg[V_PC_INDEX]);
  V_PC = (unsigned int) arg[V_PC_INDEX].value.integer;

  // Next argument
  reg_handle    = vpi_scan(arg_iterator);
  // READ RDST
  arg[V_RDST_INDEX].format = vpiIntVal;
  vpi_get_value(reg_handle, &arg[V_RDST_INDEX]);
  V_RDST = (unsigned int) arg[V_RDST_INDEX].value.integer;

  // Next argument
  reg_handle    = vpi_scan(arg_iterator);
  // READ RDST_VALUE
  arg[V_RDST_VALUE_INDEX].format = vpiIntVal;
  vpi_get_value(reg_handle, &arg[V_RDST_VALUE_INDEX]);
  V_RDST_VALUE = (unsigned int) arg[V_RDST_VALUE_INDEX].value.integer;

  // Next argument
  reg_handle    = vpi_scan(arg_iterator);
  // READ FISSION FLAG
  arg[V_FISSION_INDEX].format = vpiIntVal;
  vpi_get_value(reg_handle, &arg[V_FISSION_INDEX]);
  V_CHECK_FISSION = (unsigned int) arg[V_FISSION_INDEX].value.integer;





  // PERFORM THE CHECK
  if (V_CHECK_ENABLE) {
    //vpi_printf(" V_PC=%08x  ",V_PC);		

    // NOW READ FROM FUNCTIONAL SIMULATOR
    db_ptr = THREAD[0]->get_instr();
    FS_PC = (unsigned int) db_ptr->a_pc;
    if (db_ptr->a_num_rdst > 0) {
      FS_RDST = (unsigned int) db_ptr->a_rdst[0].n;
      FS_RDST_VALUE = (unsigned int) db_ptr->a_rdst[0].value;
    }

    // CHECK PC
    if (V_PC != FS_PC) {
      vpi_printf("PC MISMATCH!!\n");
      vpi_printf(" CYCLE: %u ", V_CYCLE);
      vpi_printf(" V_PC=%08x  ",V_PC);
      vpi_printf(" FS_PC=%08x\n", FS_PC);
      exit(0);
    }
    else if ((db_ptr->a_num_rdst > 0) && (V_CHECK_FISSION == 0)) {
      // INSTRUCTION HAS A DESTINATION
      if (V_RDST != FS_RDST) {
	vpi_printf("RDST MISMATCH!!\n");
	vpi_printf(" CYCLE: %u ", V_CYCLE);
	vpi_printf(" V_PC=%08x V_RDST=%2u V_RDST_VALUE=%8x V_FISSION=%2u ",V_PC, V_RDST, V_RDST_VALUE, V_CHECK_FISSION);
	vpi_printf(" FS_PC=%08x FS_RDST=%2u FS_RDST_VALUE=%8x\n", FS_PC, FS_RDST, FS_RDST_VALUE);
	exit(0);
      }
      else if (V_RDST_VALUE != FS_RDST_VALUE) {
	vpi_printf("RDST_VALUE MISMATCH!!\n");
	vpi_printf(" CYCLE: %u ", V_CYCLE);
	vpi_printf(" V_PC=%08x V_RDST=%2u V_RDST_VALUE=%8x ",V_PC, V_RDST, V_RDST_VALUE);
	vpi_printf(" FS_PC=%08x FS_RDST=%2u FS_RDST_VALUE=%8x\n", FS_PC, FS_RDST, FS_RDST_VALUE);
	exit(0);
      }
    } // HAS DESTINAITON
  } // V_CHECK_ENABLE

  /* free iterator memory */
  vpi_free_object(arg_iterator);

  return(0);
}




// Associate C Function with a New System Function
void getRetireInstPC_register() {
  s_vpi_systf_data task_data_s;

  task_data_s.type      = vpiSysTask;
  //task_data_s.sysfunctype = vpiSysFuncSized;
  task_data_s.tfname    = "$getRetireInstPC";
  task_data_s.calltf    = getRetireInstPC_calltf;
  task_data_s.compiletf = 0;
  //task_data_s.sizetf    = readInst_sizetf;

  vpi_register_systf(&task_data_s);
}
