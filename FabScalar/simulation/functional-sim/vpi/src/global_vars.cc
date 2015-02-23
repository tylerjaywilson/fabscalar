#include "Thread.h"
#include "veri_memory_macros.h"
#include "veri_memory.h"

Thread *THREAD[MAX_THREADS];
unsigned int NumThreads = 1;
FILE *fp_info;

FILE *CHECKPOINT=NULL;
unsigned long long SKIP_AMT = 0;
unsigned long long WARMUP_AMT = 0;
