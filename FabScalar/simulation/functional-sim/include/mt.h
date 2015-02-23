// Total number of architected registers.
// R0-R31, F0-F31, HI, LO, FCC
#define TOTAL_ARCH_REGS         67

#define FPR_BASE        32
#define HI_ID           64
#define LO_ID           65
#define FCC_ID          66


// Total frontend latency (fetch/dispatch/issue).
#define FDI		(SS_TIME_TYPE)3	

// latency for computing load/store addresses
#define AGEN_LATENCY	(SS_TIME_TYPE)1

// data cache access latency
// This is now handled by real data cache - set to 0 !!!
#define ACCESS_LATENCY	(SS_TIME_TYPE)0
