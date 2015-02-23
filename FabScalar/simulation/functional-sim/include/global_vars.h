#ifndef _GLOBAL_VARS_H
#define _GLOBAL_VARS_H

extern Thread *THREAD[MAX_THREADS];
extern unsigned int NumThreads;
extern FILE *fp_info;

// These 2 are defined in func_sim.cc                                                                                                          
extern bool USE_INSTR_LIMIT;
extern SS_TIME_TYPE INSTR_LIMIT;


extern FILE *CHECKPOINT;
extern unsigned long long SKIP_AMT;
extern unsigned long long WARMUP_AMT;

#endif
