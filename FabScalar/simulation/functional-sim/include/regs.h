#ifndef REGS_H
#define REGS_H

#include "ss.h"

union regs_FP {
    SS_WORD_TYPE l[SS_NUM_REGS];
    SS_FLOAT_TYPE f[SS_NUM_REGS];
    SS_DOUBLE_TYPE d[SS_NUM_REGS/2];
};

#endif /* REGS_H */
