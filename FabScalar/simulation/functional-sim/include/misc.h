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

#ifndef MISC_H
#define MISC_H

extern "C" {

#include <stdio.h>
#include <sys/types.h>

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

/* miss external decls */
#if defined(sparc) && defined(__unix__)
FILE *fopen(const char *__filename, const char *__type);
char *fgets(char *__s, int __n, FILE *__stream);
int fprintf(FILE *__stream, const char *__format, ...);
int fclose(FILE *__stream);
int fgetc(FILE *__stream);
int fputc(int __c, FILE *__stream);
int fputs(const char *__s, FILE *__stream);
size_t fread(void *__ptr, size_t __size,
	     size_t __nitems, FILE *__stream);
#if !defined(__svr4__)
void fflush(FILE *stream);
#endif
int fscanf(FILE *__stream, const char *__format, ...);
char *gets(char *__s);
int printf(const char *__format, ...);
int puts(const char *__s);
int scanf(const char *__format, ...);
int sscanf(const char *__s, const char *__format, ...);
#if !defined(__svr4__)
int vfprintf(FILE *__stream, const char *__format, ...);
int vprintf(const char *__format, ...);
int vsprintf(char *__s, const char *__format, ...);
#endif
void *malloc(size_t size);
void *calloc(size_t nelt, size_t el_size);
void *realloc(void *ptr, size_t size);
void free(void *ptr);
time_t time(time_t *);
void bzero(char *, int);
#if !defined(__svr4__)
char *sbrk(int incr);
#endif
int getpagesize(void);
#if !defined(__svr4__)
int ioctl(int fd, int req, caddr_t arg);
#endif
int getdtablesize(void);
int getdirentries(int fd, char *buf, int nbytes, long *basep);
char *getwd(char *path);
gid_t getgid(void);
gid_t getegid(void);
uid_t getuid(void);
uid_t geteuid(void);
#endif /* __unix__ */


/* various useful macros */
#ifndef MAX
#define MAX(a, b)    (((a) < (b)) ? (b) : (a))
#endif
#ifndef MIN
#define MIN(a, b)    (((a) < (b)) ? (a) : (b))
#endif

/* for printing out "long long" vars */
#define LLHIGH(L)		((long)(((L)>>32) & 0xffffffff))
#define LLLOW(L)		((long)((L) & 0xffffffff))

/* bind together two symbols, at proprocess time */
#define SYMCAT(X,Y)	X##Y

/* size of an array, in elements */
#define N_ELT(ARR)   (sizeof(ARR)/sizeof((ARR)[0]))

/* rounding macros, assumes ALIGN is a power of two */
#define ROUND_UP(N,ALIGN)	(((N) + ((ALIGN)-1)) & ~((ALIGN)-1))
#define ROUND_DOWN(N,ALIGN)	((N) & ~((ALIGN)-1))

/* verbose output flag */
extern int verbose;

/* register a function to be called when an error is detected */
void fatal_hook(void (*hook_fn)(FILE *stream));

/* declare a fatal run-time error, calls fatal hook function */
#define fatal(fmt, args...)	\
  _fatal(__FILE__, __FUNCTION__, __LINE__, fmt, ## args)

void
_fatal(char *file, const char *func, int line, char *fmt, ...)
__attribute__ ((noreturn));

/* declare a panic situation, dumps core */
#define panic(fmt, args...)	\
  _panic(__FILE__, __FUNCTION__, __LINE__, fmt, ## args)

void
_panic(char *file, const char *func, int line, char *fmt, ...)
__attribute__ ((noreturn));

/* declare a warning */
#define warn(fmt, args...)	\
  _warn(__FILE__, __FUNCTION__, __LINE__, fmt, ## args)

void
_warn(char *file, const char *func, int line, char *fmt, ...);

/* print general information */
#define info(fmt, args...)	\
  _info(__FILE__, __FUNCTION__, __LINE__, fmt, ## args)

void
_info(char *file, const char *func, int line, char *fmt, ...);

#ifdef DEBUG
/* active debug flag */
extern int debugging;

/* print a debugging message */
#define debug(fmt, args...)	\
    do {                        \
        if (debugging)         	\
            _debug(__FILE__, __FUNCTION__, __LINE__, fmt, ## args); \
    } while(0)

void
_debug(char *file, const char *func, int line, char *fmt, ...);
#else /* !DEBUG */
#define debug(fmt, args...)
#endif /* !DEBUG */

/* copy a string to a new storage allocation */
#ifdef SIM_LINUX	/* 11/5/04 ERIC_CHANGE */
#else
/*char *strdup(const char *s);*/
#endif

/* allocate some core, this memory has overhead no larger than a page
   in size and it cannot be released. the storage is returned cleared */
void *getcore(int nbytes);

/* return log of a number to the base 2 */
int log_base2(int n);

/* return string describing elapsed time, passed in SEC in seconds */
char *elapsed_time(long sec);

/* reentrant getopt() interfaces */
extern int getopt_index, getopt_error;
extern char *getopt_arg;
void getopt_init(void);
char getopt_next(int argc, char **argv, char *fmt);
char *getopt_combine_options(char *opt1, char *opt2);

/* FIXME: soon to be blown away */
/*
 * Assume bit positions numbered 31 to 0 (31 high order bit).
 * Extract num bits from word starting at position pos (with
 * pos as the high order bit of those to be extracted). Result
 * is right justified and zero filled to high order bit.
 *
 * Example:
 *
 * call extractl(word, 6, 3);
 * 8 bit word = 01101011
 *               ^^^
 * returns 00000110
 */
static inline unsigned long
extractl(long word,     /* the word from which to extract */
         long pos,      /* bit positions 31 to 0 */
         long num)      /* number of bits to extract */
{
    return(((unsigned long) word >> (pos + 1 - num)) & ~(~0 << num));
}

}	// extern "C"

#endif /* MISC_H */
