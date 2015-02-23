/* This file is a part of the SimpleScalar tool suite written by
 * Todd M. Austin, University of Wisconsin - Madison, Computer Sciences
 * Department as a part of the Multiscalar Research Project.
 *  
 * The SimpleScalar x86 port was written by Steve Bennett.
 * 
 * The tool suite is currently maintained by Doug Burger.
 * 
 * Copyright (C) 1994, 1995, 1996 by Todd M. Austin
 *
 * This source file is distributed in the hope that it will be useful,
 * but without any warranty.  No author or distributor accepts
 * any responsibility for the consequences of its use.
 *
 * Everyone is granted permission to copy, modify and redistribute
 * this source file under the following conditions:
 *
 *    Permission is granted to anyone to make or distribute copies
 *    of this source code, either as received or modified, in any
 *    medium, provided that all copyright notices, permission and
 *    nonwarranty notices are preserved, and that the distributor
 *    grants the recipient permission for further redistribution as
 *    permitted by this document.
 *
 *    Permission is granted to distribute this file in compiled
 *    or executable form under the same conditions that apply for
 *    source code, provided that either:
 *
 *    A. it is accompanied by the corresponding machine-readable
 *       source code,
 *    B. it is accompanied by a written offer, with no time limit,
 *       to give anyone a machine-readable copy of the corresponding
 *       source code in return for reimbursement of the cost of
 *       distribution.  This written offer must permit verbatim
 *       duplication by anyone, or
 *    C. it is distributed by someone who received only the
 *       executable form, and is accompanied by a copy of the
 *       written offer of source code that they received concurrently.
 *
 * In other words, you are welcome to use, share and improve this
 * source file.  You are forbidden to forbid anyone else to use, share
 * and improve what you give them.
 *
 * INTERNET: dburger@cs.wisc.edu
 * US Mail:  1210 W. Dayton Street, Madison, WI 53706
 */

#include "misc.h"
#include "ss.h"

/* tables for speeding up completer accesses */

/* force a nasty address */
#define XX		0xabababab

int ss_fore_tab[8][5] = {
             /* NOP   POSTI POSTD  PREI   PRED */
/* byte */    {  0,    0,    0,     1,     -1,  },
/* half */    {  0,    0,    0,     2,     -2,  },
/* invalid */ {  XX,   XX,   XX,    XX,    XX,  },
/* word */    {  0,    0,    0,     4,     -4,  },
/* invalid */ {  XX,   XX,   XX,    XX,    XX,  },
/* invalid */ {  XX,   XX,   XX,    XX,    XX,  },
/* invalid */ {  XX,   XX,   XX,    XX,    XX,  },
/* dword */   {  0,    0,    0,     8,     -8,  },
};
int ss_aft_tab[8][5] = {
             /* NOP   POSTI POSTD  PREI   PRED */
/* byte */    {  0,    1,    -1,    0,     0,   },
/* half */    {  0,    2,    -2,    0,     0,   },
/* invalid */ {  XX,   XX,   XX,    XX,    XX,  },
/* word */    {  0,    4,    -4,    0,     0,   },
/* invalid */ {  XX,   XX,   XX,    XX,    XX,  },
/* invalid */ {  XX,   XX,   XX,    XX,    XX,  },
/* invalid */ {  XX,   XX,   XX,    XX,    XX,  },
/* dword */   {  0,    8,    -8,    0,     0,   },
};

/* lwl/lwr/swl/swr masks */
unsigned long ss_lr_masks[] = {
#ifdef BYTES_BIG_ENDIAN
  0x00000000,
  0x000000ff,
  0x0000ffff,
  0x00ffffff,
  0xffffffff,
#else
  0xffffffff,
  0x00ffffff,
  0x0000ffff,
  0x000000ff,
  0x00000000,
#endif
};

/* LWL/LWR implementation workspace */
SS_ADDR_TYPE ss_lr_temp;

/* temporary variables */
SS_ADDR_TYPE temp_bs, temp_rd;

/* opcode mask -> enum ss_opcode */
enum ss_opcode ss_mask2op[SS_MAX_MASK+1];

void
ss_init_decoder(void)
{
#define DEFFU(FU,DESC)
#define DEFINST(OP,MSK,NAME,OPFORM,RES,FLAGS,O1,O2,I1,I2,I3,EXPR,L,TEXPR1,TEXPR2) \
  if (ss_mask2op[(MSK)]) fatal("doubly defined mask value");		\
  if ((MSK) > SS_MAX_MASK) fatal("mask value is too large");		\
  ss_mask2op[(MSK)]=(OP);

#include "ss.def"
#undef DEFFU
#undef DEFINST
}

/* enum ss_opcode -> description string */
char *ss_op2name[OP_MAX] = {
  NULL, /* NA */
#define DEFFU(FU,DESC)
#define DEFINST(OP,MSK,NAME,OPFORM,RES,FLAGS,O1,O2,I1,I2,I3,EXPR,L,TEXPR1,TEXPR2) NAME,
#define DEFLINK(OP,MSK,NAME,MASK,SHIFT) NAME,
#define CONNECT(OP)

#include "ss.def"
#undef DEFFU
#undef DEFINST
#undef DEFLINK
#undef CONNECT
};

/* enum ss_opcode -> opcode operand format */
char *ss_op2format[OP_MAX] = {
  NULL, /* NA */
#define DEFFU(FU,DESC)
#define DEFINST(OP,MSK,NAME,OPFORM,RES,FLAGS,O1,O2,I1,I2,I3,EXPR,L,TEXPR1,TEXPR2) OPFORM,
#define DEFLINK(OP,MSK,NAME,MASK,SHIFT) NULL,
#define CONNECT(OP)

#include "ss.def"
#undef DEFFU
#undef DEFINST
#undef DEFLINK
#undef CONNECT
};

/* enum ss_opcode -> enum ss_fu_class */
enum ss_fu_class ss_op2fu[OP_MAX] = {
  (enum ss_fu_class)FUClass_NA, /* NA */
#define DEFFU(FU,DESC)
#define DEFINST(OP,MSK,NAME,OPFORM,RES,FLAGS,O1,O2,I1,I2,I3,EXPR,L,TEXPR1,TEXPR2) (enum ss_fu_class)RES,
#define DEFLINK(OP,MSK,NAME,MASK,SHIFT) (enum ss_fu_class)FUClass_NA,
#define CONNECT(OP)
#include "ss.def"
#undef DEFFU
#undef DEFINST
#undef DEFLINK
#undef CONNECT
};

/* enum ss_opcode -> opcode flags */
unsigned long ss_op2flags[OP_MAX] = {
  NA, /* NA */
#define DEFFU(FU,DESC)
#define DEFINST(OP,MSK,NAME,OPFORM,RES,FLAGS,O1,O2,I1,I2,I3,EXPR,L,TEXPR1,TEXPR2) FLAGS,
#define DEFLINK(OP,MSK,NAME,MASK,SHIFT) NA,
#define CONNECT(OP)
#include "ss.def"
#undef DEFFU
#undef DEFINST
#undef DEFLINK
#undef CONNECT
};

/* enum ss_opcode -> description string */
char *ss_fu2name[NUM_FU_CLASSES] = {
  NULL, /* NA */
#define DEFFU(FU,DESC) DESC,
#define DEFINST(OP,MSK,NAME,OPFORM,RES,FLAGS,O1,O2,I1,I2,I3,EXPR,L,TEXPR1,TEXPR2)
#define DEFLINK(OP,MSK,NAME,MASK,SHIFT)
#define CONNECT(OP)
#include "ss.def"
#undef DEFFU
#undef DEFINST
#undef DEFLINK
#undef CONNECT
};

void
ss_print_insn(SS_INST_TYPE inst, SS_ADDR_TYPE pc, FILE *stream)
{
  enum ss_opcode op = (enum ss_opcode)SS_OPCODE(inst); /* SS_OP_ENUM(SS_OPCODE(inst)); */
  char *s = SS_OP_FORMAT(op);

  if (!stream)
    stream = stderr;

  fprintf(stream, "%-10s", SS_OP_NAME(op));
  while (*s) {
    switch (*s) {
    case 'd':
      fprintf(stream, "r%ld", RD);
      break;
    case 's':
      fprintf(stream, "r%ld", RS);
      break;
    case 't':
      fprintf(stream, "r%ld", RT);
      break;
    case 'b':
      fprintf(stream, "r%ld", BS);
      break;
    case 'D':
      fprintf(stream, "f%ld", FD);
      break;
    case 'S':
      fprintf(stream, "f%ld", FS);
      break;
    case 'T':
      fprintf(stream, "f%ld", FT);
      break;
    case 'j':
      fprintf(stream, "0x%lx", (pc + 8 + (OFS << 2)));
      break;
    case 'o':
    case 'i':
      fprintf(stream, "%ld", IMM);
      break;
    case 'H':
      fprintf(stream, "%ld", SHAMT);
      break;
    case 'u':
      fprintf(stream, "%lu", UIMM);
      break;
    case 'U':
      fprintf(stream, "0x%lx", UIMM);
      break;
    case 'J':
      fprintf(stream, "0x%lx", ((pc & 036000000000) | (TARG << 2)));
      break;
    case 'B':
      fprintf(stream, "0x%lx", BCODE);
      break;
    case ')':
      /* handle pre- or post-inc/dec */
      if (SS_COMP_OP == SS_COMP_NOP)
	fprintf(stream, ")");
      else if (SS_COMP_OP == SS_COMP_POST_INC)
	fprintf(stream, ")+");
      else if (SS_COMP_OP == SS_COMP_POST_DEC)
	fprintf(stream, ")-");
      else if (SS_COMP_OP == SS_COMP_PRE_INC)
	fprintf(stream, ")^+");
      else if (SS_COMP_OP == SS_COMP_PRE_DEC)
	fprintf(stream, ")^-");
      else if (SS_COMP_OP == SS_COMP_POST_DBL_INC)
	fprintf(stream, ")++");
      else if (SS_COMP_OP == SS_COMP_POST_DBL_DEC)
	fprintf(stream, ")--");
      else if (SS_COMP_OP == SS_COMP_PRE_DBL_INC)
	fprintf(stream, ")^++");
      else if (SS_COMP_OP == SS_COMP_PRE_DBL_DEC)
	fprintf(stream, ")^--");
      else
	panic("bogus SS_COMP_OP");
      break;
    default:
      fputc(*s, stream);
    }
    s++;
  }
}
