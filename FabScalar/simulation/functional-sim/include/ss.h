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

#ifndef SS_H
#define SS_H

#include <stdio.h>

/* basic type mapping */
typedef double SS_DOUBLE_TYPE;
typedef float SS_FLOAT_TYPE;
typedef long SS_WORD_TYPE;
typedef short SS_HALF_TYPE;
typedef char SS_BYTE_TYPE;
typedef void *SS_PTR_TYPE;

/* statistical counter types */
typedef long long SS_COUNTER_TYPE;
typedef long long SS_TIME_TYPE;

/* instruction/address formats */
typedef unsigned long SS_ADDR_TYPE;
typedef struct {
  unsigned long a;		/* simplescalar opcode */
  unsigned long b;		/* simplescalar immediate fields */
} SS_INST_TYPE;
#define SS_INST_SIZE		sizeof(SS_INST_TYPE)

/* VM limits */
#define SS_TEXT_BASE		0x00400000
#define SS_DATA_BASE		0x10000000
#define SS_STACK_BASE 		0x7fffc000

/* VM page size, this should be user configurable */
#define SS_PAGE_SIZE		4096

/* maximum size of argc+argv+envp environment */
#define SS_MAX_ENVIRON		4096

/* well known registers */
#define SS_GP_REGNO		28
#define SS_STACK_REGNO		29

/* total number of registers in each register file */
#define SS_NUM_REGS		32

/* total number of register in processor 32I+32F+HI+LO+FC+TMP+MEM+CTRL */
#define SS_TOTAL_REGS						\
  (SS_NUM_REGS+SS_NUM_REGS+/*HI*/1+/*LO*/1+/*FC*/1+/*TMP*/1+/*MEM*/1+/*CTRL*/1)

/* decoder bootstraps */
#define SS_OPCODE(INST)		(INST.a & 0xff)

/* pre- or post-inc/dec completer specifier */
#define SS_COMP_OP		((inst.a & 0xff00) >> 8)
/* completer specifier values */
#define SS_COMP_NOP		0x00
#define SS_COMP_POST_INC	0x01
#define SS_COMP_POST_DEC	0x02
#define SS_COMP_PRE_INC		0x03
#define SS_COMP_PRE_DEC		0x04
#define SS_COMP_POST_DBL_INC	0x05
#define SS_COMP_POST_DBL_DEC	0x06
#define SS_COMP_PRE_DBL_INC	0x07
#define SS_COMP_PRE_DBL_DEC	0x08

/* the completer expression is rather contorted to reduce chance of
   code explosion, the key here is to only emit (EXPR) once */

extern int ss_fore_tab[8][5];
extern int ss_aft_tab[8][5];

#define INC_DEC(EXPR, REG, SIZE)					\
  (SET_GPR((REG), GPR(REG) + ss_fore_tab[(SIZE)-1][SS_COMP_OP]),	\
   (EXPR),								\
   SET_GPR((REG), GPR(REG) + ss_aft_tab[(SIZE)-1][SS_COMP_OP]))

/* not applicable/available, usable in all contexts */
#define NA		0

/* 10/5/96 ERIC_CHANGE: added this for null statements. */
#define NADA		;
#define UNIMP		assert(0);

/* SimpleScalar opcode format */
#if defined(hpux)
#include <sys/syscall.h>		/* QES: what the hell. */
#undef RS	/* defined in /usr/include/sys/syscall.h */
#endif
#define RS		(inst.b >> 24)
#define RT		((inst.b >> 16) & 0xff)
#define RD		((inst.b >> 8) & 0xff)

/* pre-defined registers */
#define Rgp		28
#define Rsp		29

#define SHAMT		(inst.b & 0xff)

#define FS		RS
#define FT		RT
#define FD		RD

#define IMM		((/* signed */ long)((/* signed */short)(inst.b & 0xffff)))

#define UIMM		(inst.b & 0xffff)

#define TARG		(inst.b & 0x3ffffff)

/* break code */
#define BCODE		(inst.b & 0xfffff)

#define OFS		IMM		/* alias to IMM */
#define BS		RS		/* alias to rs */


/************************************************/
/* ER 09-14-04: Updated lwl/lwr/swl/swr code.   */
/* VKR: This version is similar to SS 3.0.      */
/************************************************/

#ifdef BYTES_LITTLE_ENDIAN

/* lwl/swl defs */
#define WL_SIZE(ADDR)   (4-((ADDR) & 0x03))
#define WL_BASE(ADDR)   ((ADDR) & ~0x03)
#define WL_PROT_MASK(ADDR)  (ss_lr_masks[4-WL_SIZE(ADDR)])
#define WL_PROT_MASK1(ADDR) (ss_lr_masks[WL_SIZE(ADDR)])
#define WL_PROT_MASK2(ADDR) (ss_lr_masks[4-WL_SIZE(ADDR)])
/* lwr/swr defs */
#define WR_SIZE(ADDR)   (((ADDR) & 0x03)+1)
#define WR_BASE(ADDR)   ((ADDR) & ~0x03)
#define WR_PROT_MASK(ADDR)  (~(ss_lr_masks[WR_SIZE(ADDR)]))
#define WR_PROT_MASK1(ADDR) ((ss_lr_masks[WR_SIZE(ADDR)]))
#define WR_PROT_MASK2(ADDR) (ss_lr_masks[4-WR_SIZE(ADDR)])

#else /* BIG ENDIAN */

/* lwl/swl defs */
#define WL_SIZE(ADDR)   ((ADDR) & 0x03)
#define WL_BASE(ADDR)   ((ADDR) & ~0x03)
#define WL_PROT_MASK(ADDR)  (ss_lr_masks[4-WL_SIZE(ADDR)])
#define WL_PROT_MASK1(ADDR) (ss_lr_masks[WL_SIZE(ADDR)])
#define WL_PROT_MASK2(ADDR) (ss_lr_masks[4-WL_SIZE(ADDR)])
/* lwr/swr defs */
#define WR_SIZE(ADDR)   (((ADDR) & 0x03)+1)
#define WR_BASE(ADDR)   ((ADDR) & ~0x03)
#define WR_PROT_MASK(ADDR)  (~(ss_lr_masks[WR_SIZE(ADDR)]))
#define WR_PROT_MASK1(ADDR) ((ss_lr_masks[WR_SIZE(ADDR)]))
#define WR_PROT_MASK2(ADDR) (ss_lr_masks[4-WR_SIZE(ADDR)])

#endif

#include "I_hate_these_instructions.h"



/* used to speed up LWL/LWR implementation */
extern unsigned long ss_lr_masks[];

/* LWL/LWR implementation workspace */
extern SS_ADDR_TYPE ss_lr_temp;

/* temporary variables */
extern SS_ADDR_TYPE temp_bs, temp_rd;

#ifndef NO_ICHECKS
#define MAXINT		0x7fffffff
#define OVER(X,Y)	(((((X) > 0) && ((Y) > 0) &&			\
			   (MAXINT - (X) < (Y))) ? (fatal("+ overflow"),0) : 0), \
			 ((((X) < 0) && ((Y) < 0) &&			\
			   (-MAXINT - (X) > (Y))) ? (fatal("+ underflow"),0) : 0))
#define UNDER(X,Y)	(((((X) > 0) && ((Y) < 0) &&			\
			   (MAXINT + (Y) < (X))) ? (fatal("- overflow"),0) : 0), \
			 ((((X) < 0) && ((Y) > 0) &&			\
			   (-MAXINT + (Y) > (X))) ? (fatal("- underflow"),0) : 0))
#define DIV0(N)		(((N) == 0) ? (fatal("divide by 0"),0) : 0)
#define INTALIGN(N)	(((N) & 01) ? (fatal("bad INT register alignment"),0) : 0)
#define FPALIGN(N)	(((N) & 01) ? (fatal("bad FP register alignment"),0) : 0)
#define TALIGN(TARG)	(((TARG) & 0x7) ? (fatal("bad jump alignment"),0) : 0)
#else /* NO_ICHECKS */
#define OVER(X,Y)	(0)
#define UNDER(X,Y)	(0)
#define DIV0(N)		(0)
#define INTALIGN(N)	(0)
#define FPALIGN(N)	(0)
#define TALIGN(TARG)	(0)
#endif /* NO_ICHECKS */

/* instruction flags */
#define F_ICOMP		0x00000001	/* integer computation */
#define F_FCOMP		0x00000002	/* FP computation */
#define F_CTRL		0x00000004	/* control inst */
#define F_UNCOND	0x00000008	/*   unconditional change */
#define F_COND		0x00000010	/*   conditional change */
#define F_MEM		0x00000020	/* memory access inst */
#define F_LOAD		0x00000040	/*   load inst */
#define F_STORE		0x00000080	/*   store inst */
#define F_DISP		0x00000100	/*   displaced (R+C) addressing mode */
#define F_RR		0x00000200	/*   R+R addressing mode */
#define F_DIRECT	0x00000400	/*   direct addressing mode */
#define F_TRAP		0x00000800	/* traping inst */
#define F_LONGLAT	0x00001000	/* long latency inst (for sched) */

/* nop definition */
#define SS_NOP_INST	((SS_INST_TYPE){ NOP, 0 })

/* global opcode names */
enum ss_opcode {
  OP_NA = 0,	/* NA */
#define DEFFU(FU,DESC)
#define DEFINST(OP,MSK,NAME,OPFORM,RES,FLAGS,O1,O2,I1,I2,I3,EXPR,L,TEXPR1,TEXPR2) OP,
#define DEFLINK(OP,MSK,NAME,MASK,SHIFT) OP,
#define CONNECT(OP)
/* #ifdef BYTES_LITTLE_ENDIAN
#include "NT_ss.def"
#else */
#include "ss.def"
/* #endif */
#undef DEFFU
#undef DEFINST
#undef DEFLDST
#undef DEFLINK
#undef CONNECT
  OP_MAX	/* number of opcodes + NA */
};

/* function unit classes */
enum ss_fu_class {
  FUClass_NA = 0,	/* inst does not use a FU */
#define DEFFU(FU,DESC) FU,
#define DEFINST(OP,MSK,NAME,OPFORM,RES,FLAGS,O1,O2,I1,I2,I3,EXPR,L,TEXPR1,TEXPR2)
#define DEFLINK(OP,MSK,NAME,MASK,SHIFT)
#define CONNECT(OP)
/* #ifdef BYTES_LITTLE_ENDIAN
#include "NT_ss.def"
#else */
#include "ss.def"
/* #endif */
#undef DEFFU
#undef DEFINST
#undef DEFLDST
#undef DEFLINK
#undef CONNECT
  NUM_FU_CLASSES	/* total functional unit classes */
};

/* largest mask value */
#define SS_MAX_MASK		255

/* inst -> enum ss_opcode */
#define SS_OP_ENUM(MSK)		(ss_mask2op[MSK])
extern enum ss_opcode ss_mask2op[];

/* enum ss_opcode -> description string */
#define SS_OP_NAME(OP)		(ss_op2name[OP])
extern char *ss_op2name[];

/* enum ss_opcode -> opcode operand format */
#define SS_OP_FORMAT(OP)	(ss_op2format[OP])
extern char *ss_op2format[];

/* enum ss_opcode -> enum ss_fu_class */
#define SS_OP_FUCLASS(OP)	(ss_op2fu[OP])
extern enum ss_fu_class ss_op2fu[];

/* enum ss_opcode -> opcode flags */
#define SS_OP_FLAGS(OP)		(ss_op2flags[OP])
extern unsigned long ss_op2flags[];

/* enum ss_fu_class -> description string */
#define SS_FU_NAME(FU)		(ss_fu2name[FU])
extern char *ss_fu2name[];

void ss_init_decoder(void);

void ss_print_insn(SS_INST_TYPE inst, SS_ADDR_TYPE pc, FILE *stream);

#endif /* SS_H */
