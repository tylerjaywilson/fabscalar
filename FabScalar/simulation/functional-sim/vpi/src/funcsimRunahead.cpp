#include <stdio.h>
#include <stdlib.h>
#include "vpi_user.h"

#include "Thread.h"
#include "global_vars.h"

int funcsimRunahead_calltf(char *user_data) {
  unsigned int i;

  vpi_printf("Functional Simulator running ahead\n");
  ///////////////////////////////////////////
  // Fill debug buffers
  ///////////////////////////////////////////
  THREAD[0]->run_ahead();

} // funcsimRunahead_register


void funcsimRunahead_register() {
  s_vpi_systf_data task_init;

  task_init.type      = vpiSysTask;
  task_init.tfname    = "$funcsimRunahead";
  task_init.calltf    = funcsimRunahead_calltf;
  task_init.compiletf = 0;

  vpi_register_systf(&task_init);
} // funcsim_register()
